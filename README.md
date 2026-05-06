# homebrew-tap

Personal Homebrew tap for [Allen Bina](https://github.com/allenbina)'s projects.

## Install

```bash
brew install allenbina/tap/<formula>
```

Behind the scenes that does `brew tap allenbina/tap` once and then resolves
the formula from this repo's `Formula/` directory.

## Formulae

| Formula | Description |
|---|---|
| [`chat-bridge`](Formula/chat-bridge.rb) | macOS chat bridge: relay iMessages to Telegram, a web UI, and other integrations. Source: [allenbina/chat-bridge](https://github.com/allenbina/chat-bridge). |

## Updating a formula

Each formula's `url` and `sha256` point at a tagged release tarball of the
upstream project. To update for a new release:

1. Tag the upstream release.
2. `curl -sSL <tarball-url> | sha256sum`
3. Bump `url` and `sha256` in the formula here, commit, push.
4. End users get the update on their next `brew update && brew upgrade`.

## License

MIT.
