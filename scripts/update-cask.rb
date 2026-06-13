#!/usr/bin/env ruby
# frozen_string_literal: true

# Bump a single cask to the latest build on its CDN channel, re-hosting the DMG(s)
# as a versioned GitHub Release so the cask download stays checksum-pinned.
#
#   ruby scripts/update-cask.rb Casks/<cask>.rb [--force]
#
# The cask is the source of truth for everything except the binary:
#   - current `version`            – what we ship now
#   - `livecheck` url              – the CDN version.json to poll
#   - `sha256 arm:` / `intel:`     – dual-arch (vs single-arch sha256 "…")
#   - `cask "<token>"`             – the GitHub Release tag is "<token>-<version>"
#
# The CDN version.json (build-version-file.js output) supplies the new version and
# per-arch DMG URLs: { "version", "files": { "mac": { "<arch>": "<dmg url>" } } }.
#
# When the channel is ahead (or always, with --force):
#   1. download the CDN DMG(s)
#   2. sha256 each
#   3. gh release create / upload  <token>-<version>   (idempotent)
#   4. rewrite `version` + `sha256` (the url is #{version}-interpolated, no edit)
#
# Output contract:
#   - prints the new version + exits 0  → release published, cask patched
#   - prints nothing + exits 0          → already current / version regression
#   - exits non-zero                    → fetch failed, partial multi-arch publish,
#                                         or a `gh` call failed
#
# Requires `gh` on PATH, authenticated, with GH_REPO pointing at the tap repo.

require "digest"
require "json"
require "net/http"
require "rubygems/version"
require "tmpdir"
require "uri"

def die(msg)
  warn "error: #{msg}"
  exit 1
end

force = !ARGV.delete("--force").nil?
cask_path = ARGV[0] or die "usage: update-cask.rb Casks/<cask>.rb [--force]"
die "no such file: #{cask_path}" unless File.file?(cask_path)

src = File.read(cask_path)
token = src[/cask\s+"([^"]+)"/, 1] or die "no cask token in #{cask_path}"
current_version = src[/^\s*version\s+"([^"]+)"/, 1] or die "no version stanza in #{cask_path}"
livecheck_url = src[/livecheck do\s+url\s+"([^"]+)"/m, 1] or die "no livecheck url in #{cask_path}"
dual_arch = src.match?(/^\s*sha256\s+arm:/)

def http_get(url, limit: 5)
  die "too many redirects for #{url}" if limit <= 0
  uri = URI(url)
  res = Net::HTTP.get_response(uri)
  case res
  when Net::HTTPSuccess then res.body
  when Net::HTTPRedirection then http_get(res["location"], limit: limit - 1)
  else die "GET #{url} -> #{res.code} #{res.message}"
  end
end

def download(url, dest, limit: 5)
  die "too many redirects for #{url}" if limit <= 0
  uri = URI(url)
  Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
    http.request(Net::HTTP::Get.new(uri)) do |res|
      case res
      when Net::HTTPSuccess
        File.open(dest, "wb") { |f| res.read_body { |chunk| f.write(chunk) } }
      when Net::HTTPRedirection
        return download(res["location"], dest, limit: limit - 1)
      else
        die "GET #{url} -> #{res.code} #{res.message}"
      end
    end
  end
end

# Gem::Version understands "2.25.0.beta.42" but not "-"; normalize so a beta sorts
# below its release (2.24.7 < 2.25.0.beta.42 < 2.25.0).
def gemver(str)
  Gem::Version.new(str.tr("-", "."))
rescue ArgumentError
  nil
end

manifest = JSON.parse(http_get(livecheck_url))
new_version = manifest["version"] or die "no version in #{livecheck_url}"
mac = manifest.dig("files", "mac") or die "no files.mac in #{livecheck_url}"

unless force
  cur = gemver(current_version)
  nxt = gemver(new_version)
  if cur && nxt
    exit 0 if nxt <= cur # up to date, or a regression we refuse to follow
  elsif new_version == current_version
    exit 0
  end
end

arch_urls =
  if dual_arch
    {
      "arm64" => (mac["arm64"] or die "manifest missing mac.arm64"),
      "x64" => (mac["x64"] or die "manifest missing mac.x64 (partial publish?)"),
    }
  else
    { "arm64" => (mac["arm64"] or die "manifest missing mac.arm64") }
  end

tag = "#{token}-#{new_version}"
shas = {}

Dir.mktmpdir("cask-#{token}") do |dir|
  assets = arch_urls.map do |arch, url|
    dest = File.join(dir, File.basename(URI(url).path))
    download(url, dest)
    shas[arch] = Digest::SHA256.file(dest).hexdigest
    dest
  end

  # Idempotent: create the release if it's missing, then (re)upload every asset so
  # re-runs and resumed/partial uploads converge on the full set.
  unless system("gh", "release", "view", tag, out: File::NULL, err: File::NULL)
    system("gh", "release", "create", tag, "--title", tag,
           "--notes", "Re-hosted #{token} #{new_version} DMG(s) for the Homebrew cask.",
           *assets) or die "gh release create #{tag} failed"
  end
  system("gh", "release", "upload", tag, *assets, "--clobber") or die "gh release upload #{tag} failed"
end

if dual_arch
  src = src.sub(/^(\s*)sha256\s+arm:\s+"[^"]+",\s*\n\s*intel:\s+"[^"]+"/m) do
    indent = Regexp.last_match(1)
    %(#{indent}sha256 arm:   "#{shas["arm64"]}",\n#{indent}       intel: "#{shas["x64"]}")
  end
else
  src = src.sub(/^(\s*)sha256\s+"[^"]+"/) { "#{Regexp.last_match(1)}sha256 \"#{shas["arm64"]}\"" }
end
src = src.sub(/^(\s*)version\s+"[^"]+"/) { "#{Regexp.last_match(1)}version \"#{new_version}\"" }
File.write(cask_path, src)
puts new_version
