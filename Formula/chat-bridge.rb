class ChatBridge < Formula
  desc "macOS chat bridge: relay iMessages to Telegram, a web UI, and other integrations"
  homepage "https://github.com/allenbina/chat-bridge"

  url "https://github.com/allenbina/chat-bridge/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "64a41e698108b155e92b5850995a9a71ecc842ba552bb9fd1aed9216e41bc843"
  license "MIT"
  head "https://github.com/allenbina/chat-bridge.git", branch: "main"

  depends_on macos: :big_sur # macOS 11+; Monterey is the reference install
  depends_on "python@3.12"

  def install
    # Manual install: copy the project into libexec, build a venv there,
    # pip install requirements at install time, drop a wrapper in bin.
    #
    # Why not virtualenv_install_with_resources? That helper requires a
    # pyproject.toml plus a `resource` block for every Python dep
    # (transitively, ~30 of them) with pinned URLs and SHAs. Adding the
    # pyproject is on the roadmap (see docs/OPEN_SOURCE_PLAN.md, Phase 4),
    # but until then the manual approach keeps this formula self-contained
    # at the cost of letting pip resolve deps at install time.
    libexec.install Dir["*"]

    venv_path = libexec/".venv"
    python = Formula["python@3.12"].opt_bin/"python3"
    system python, "-m", "venv", venv_path
    system venv_path/"bin/pip", "install", "--quiet", "--upgrade", "pip"
    system venv_path/"bin/pip", "install", "-r", libexec/"requirements.txt"

    (bin/"chat-bridge").write <<~SH
      #!/bin/bash
      exec "#{venv_path}/bin/python" "#{libexec}/chat_bridge_cli.py" "$@"
    SH
    (bin/"chat-bridge").chmod 0755
  end

  # Deliberately no `service do ... end` block:
  # the bridge needs an interactive launch so macOS pops the Automation -> Messages
  # prompt where the user can see and approve it. `chat-bridge install-agents`
  # does that explicitly.
  def caveats
    homebrew_python = Formula["python@3.12"].opt_bin/"python3"
    <<~EOS
      chat-bridge is installed but not yet running.

      Next steps:
        1. chat-bridge install-agents   # render and load launchd plists
        2. chat-bridge setup            # opens the web wizard at http://localhost:8723/setup
        3. chat-bridge doctor           # verify FDA + Automation grants

      macOS permissions:
        The bridge needs Full Disk Access (to read ~/Library/Messages/chat.db)
        and Automation -> Messages (to send replies via AppleScript). Both
        must be granted from System Settings; no installer can grant these
        for you. The setup wizard surfaces deep links for both.

      Python identity (important):
        Homebrew's Python lives at:
          #{homebrew_python}

        macOS TCC — the system that gates Full Disk Access and Automation —
        treats Homebrew Python and python.org Python as DIFFERENT identities.
        If you previously installed chat-bridge using python.org Python and
        granted FDA/Automation to that binary, you will need to re-grant
        them to the Homebrew Python after this install, even though it's
        the same machine and the same project.

        If you'd rather use python.org Python (one set of grants, never
        re-prompts on a Homebrew upgrade), use the curl install script:
          curl -fsSL https://raw.githubusercontent.com/allenbina/chat-bridge/main/scripts/install.sh | bash

      Uninstalling:
        `brew uninstall chat-bridge` removes the binary and venv but does
        NOT touch ~/.chat-bridge/ (your config), launchd agents, or any
        TCC grants. Run `chat-bridge uninstall-agents` first to unload the
        launchd agents cleanly.
    EOS
  end

  test do
    # Sanity: the wrapper resolves and reports its version cleanly. The
    # version string itself comes from _version.__version__ in the source,
    # so the assertion checks only the program name (which the formula
    # always knows).
    assert_match "chat-bridge", shell_output("#{bin}/chat-bridge --version 2>&1", 0)
  end
end
