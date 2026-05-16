class Chatwire < Formula
  desc "macOS chat bridge: relay iMessages to Telegram, a web UI, and other integrations"
  homepage "https://github.com/allenbina/chatwire"

  url "https://github.com/allenbina/chatwire-dev/archive/refs/tags/v1.14.0.tar.gz"
  sha256 "0019dfc4b32d63c1392aa264aed2253c1e0c2fb09216f8e2cc269bbfb8bb49b5"
  license "MIT"
  head "https://github.com/allenbina/chatwire.git", branch: "main"

  depends_on macos: :big_sur # macOS 11+; Monterey is the reference install
  depends_on "python@3.13"

  def install
    # Manual install: copy the project into libexec, build a venv there,
    # `pip install .` to resolve deps from pyproject.toml at install time,
    # drop a wrapper in bin that execs the venv's chatwire console script.
    #
    # Why not virtualenv_install_with_resources? That helper requires a
    # `resource` block for every transitive Python dep (~30 of them) with
    # pinned URLs and SHAs, which would need re-generating on every dep
    # bump. The manual approach keeps this formula self-contained at the
    # cost of letting pip resolve at install time.
    libexec.install Dir["*"]

    venv_path = libexec/".venv"
    python = Formula["python@3.13"].opt_bin/"python3"
    system python, "-m", "venv", venv_path
    system venv_path/"bin/pip", "install", "--quiet", "--upgrade", "pip"
    system venv_path/"bin/pip", "install", "--quiet", libexec

    (bin/"chatwire").write <<~SH
      #!/bin/bash
      exec "#{venv_path}/bin/chatwire" "$@"
    SH
    (bin/"chatwire").chmod 0755
  end

  # Deliberately no `service do ... end` block:
  # the bridge needs an interactive launch so macOS pops the Automation -> Messages
  # prompt where the user can see and approve it. `chatwire install-agents`
  # does that explicitly.
  def caveats
    homebrew_python = Formula["python@3.13"].opt_bin/"python3"
    <<~EOS
      chatwire is installed but not yet running.

      Next steps:
        1. chatwire install-agents   # render and load launchd plists
        2. chatwire init             # first-run wizard (handles + VAPID keys)
        3. chatwire doctor           # verify FDA + Automation grants

      macOS permissions:
        The bridge needs Full Disk Access (to read ~/Library/Messages/chat.db)
        and Automation -> Messages (to send replies via AppleScript). Both
        must be granted from System Settings; no installer can grant these
        for you. The setup wizard surfaces deep links for both.

      Python identity (important):
        Homebrew's Python lives at:
          #{homebrew_python}

        macOS TCC -- the system that gates Full Disk Access and Automation --
        treats Homebrew Python and python.org Python as DIFFERENT identities.
        If you previously installed chatwire using python.org Python and
        granted FDA/Automation to that binary, you will need to re-grant
        them to the Homebrew Python after this install, even though it's
        the same machine and the same project.

        If you'd rather use python.org Python (one set of grants, never
        re-prompts on a Homebrew upgrade), install via pipx instead:
          pipx install --python /Library/Frameworks/Python.framework/Versions/Current/bin/python3 chatwire

      MCP support (optional):
        To enable the MCP server (for Claude, Cursor, etc.), install the
        optional extra after brew install:
          #{libexec}/.venv/bin/pip install 'chatwire[mcp]'

      Keep-awake:
        chatwire needs your Mac awake to relay messages. We recommend
        Amphetamine (free, Mac App Store):
          https://apps.apple.com/app/amphetamine/id937984704

      Uninstalling:
        `brew uninstall chatwire` removes the binary and venv but does
        NOT touch ~/.chatwire/ (your config), launchd agents, or any
        TCC grants. Run `chatwire uninstall-agents` first to unload the
        launchd agents cleanly.
    EOS
  end

  test do
    # Sanity: the wrapper resolves and reports its version cleanly.
    assert_match "chatwire", shell_output("#{bin}/chatwire --version 2>&1", 0)
  end
end
