require "test_helper"
require "open3"

# Inherited from Golden-Template, where this was fixed as 08cec77 after we
# reported it. Guard ported back so the same gap cannot reopen here.
#
# node_modules was tracked at the repository root: 131 files, ~16MB, including
# @img/sharp-darwin-arm64/lib/sharp-darwin-arm64.node and
# @img/sharp-libvips-darwin-arm64/lib/libvips-cpp.42.dylib -- macOS ARM native
# binaries, in a repository that deploys to Linux. They were confirmed physically
# present on this project's production droplet, checked out and unused.
#
# .gitignore listed vue/, expo/ and mobile/ node_modules but not the root, so a
# top-level `npm install` was committed at eb65981. A clone on any other platform
# inherits binaries it cannot load, shadowing what npm install would fetch.
class TrackedFilesTest < ActiveSupport::TestCase
  REPO_ROOT = Rails.root.join("..").expand_path

  test "no node_modules is tracked at any depth" do
    tracked = git("ls-files", "--", "node_modules", "*/node_modules")

    assert_empty tracked,
      "#{tracked.length} node_modules file(s) are tracked, e.g. #{tracked.first(3).join(', ')}. " \
      "Dependencies must be installed, not committed."
  end

  test "no compiled native binaries are tracked" do
    tracked = git("ls-files").grep(/\.(node|dylib|so|dll)\z/)

    assert_empty tracked,
      "platform-specific binaries are tracked: #{tracked.first(3).join(', ')}. " \
      "These load on one platform only and shadow what the package manager would fetch."
  end

  test "gitignore covers node_modules at the root, not only in subdirectories" do
    _stdout, _stderr, status = Open3.capture3(
      "git", "-C", REPO_ROOT.to_s, "check-ignore", "-q", "node_modules"
    )

    assert status.success?,
      "the root node_modules is not ignored; a top-level npm install can be committed again"
  end

  private

  def git(*args)
    stdout, _stderr, _status = Open3.capture3("git", "-C", REPO_ROOT.to_s, *args)
    stdout.split("\n").reject(&:empty?)
  end
end
