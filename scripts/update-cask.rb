#!/usr/bin/env ruby
# frozen_string_literal: true

# Update a single cask to the latest version published on its livecheck channel.
#
#   ruby scripts/update-cask.rb Casks/<cask>.rb
#
# The cask itself is the single source of truth: this reads the current `version`
# and the `livecheck` JSON URL straight out of the .rb file, fetches that channel
# manifest (the version.json produced by each app's build-version-file.js,
# shaped { "version", "files": { "mac": { "<arch>": "<dmg url>" } } }), and if a
# newer version is published it downloads the DMG(s), computes sha256, rewrites
# `version` + `sha256` in place, and prints the new version to stdout.
#
# Contract (so the workflow can stay dumb):
#   - prints the new version + exits 0  ........ cask was updated
#   - prints nothing + exits 0  ................ already up to date / regression
#   - exits non-zero  ......................... real error (fetch failed, or a
#                                               dual-arch cask is mid-publish with
#                                               only one architecture available)
#
# Dual-arch casks are detected by the `sha256 arm:` / `intel:` form.

require "digest"
require "json"
require "net/http"
require "rubygems/version"
require "uri"

def die(msg)
  warn "error: #{msg}"
  exit 1
end

cask_path = ARGV[0] or die "usage: update-cask.rb Casks/<cask>.rb"
die "no such file: #{cask_path}" unless File.file?(cask_path)

src = File.read(cask_path)
current_version = src[/^\s*version\s+"([^"]+)"/, 1] or die "no version stanza in #{cask_path}"
livecheck_url = src[/livecheck do\s+url\s+"([^"]+)"/m, 1] or die "no livecheck url in #{cask_path}"
dual_arch = src.match?(/^\s*sha256\s+arm:/)

# GET a URL, following redirects, yielding each body chunk (so large DMGs never
# have to be buffered whole). Returns the final response for callers that want
# the full body instead.
def http_get(url, limit: 5, &block)
  die "too many redirects for #{url}" if limit <= 0
  uri = URI(url)
  Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
    http.request(Net::HTTP::Get.new(uri)) do |res|
      case res
      when Net::HTTPSuccess
        if block
          res.read_body(&block)
        else
          return res.body
        end
      when Net::HTTPRedirection
        return http_get(res["location"], limit: limit - 1, &block)
      else
        die "GET #{url} -> #{res.code} #{res.message}"
      end
    end
  end
end

def sha256_of(url)
  digest = Digest::SHA256.new
  http_get(url) { |chunk| digest.update(chunk) }
  digest.hexdigest
end

# Gem::Version understands "2.25.0.beta.42" but not the "-" separator; normalize
# so beta builds sort below their release (2.24.7 < 2.25.0.beta.42 < 2.25.0).
def gemver(str)
  Gem::Version.new(str.tr("-", "."))
rescue ArgumentError
  nil
end

manifest = JSON.parse(http_get(livecheck_url))
new_version = manifest["version"] or die "no version in #{livecheck_url}"
mac = manifest.dig("files", "mac") or die "no files.mac in #{livecheck_url}"

cur = gemver(current_version)
nxt = gemver(new_version)
if cur && nxt
  exit 0 if nxt <= cur # up to date, or a regression we refuse to follow
elsif new_version == current_version
  exit 0
end

if dual_arch
  arm_url = mac["arm64"] or die "manifest is missing mac.arm64"
  intel_url = mac["x64"] or die "manifest is missing mac.x64 (partial publish?)"
  arm_sha = sha256_of(arm_url)
  intel_sha = sha256_of(intel_url)
  src = src.sub(/^(\s*)sha256\s+arm:\s+"[^"]+",\s*\n\s*intel:\s+"[^"]+"/m) do
    indent = Regexp.last_match(1)
    %(#{indent}sha256 arm:   "#{arm_sha}",\n#{indent}       intel: "#{intel_sha}")
  end
else
  arm_url = mac["arm64"] or die "manifest is missing mac.arm64"
  sha = sha256_of(arm_url)
  src = src.sub(/^(\s*)sha256\s+"[^"]+"/) { "#{Regexp.last_match(1)}sha256 \"#{sha}\"" }
end

src = src.sub(/^(\s*)version\s+"[^"]+"/) { "#{Regexp.last_match(1)}version \"#{new_version}\"" }
File.write(cask_path, src)
puts new_version
