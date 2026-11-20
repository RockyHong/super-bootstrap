**Language-server pins (techstack-derived).** Run this once `docs/techstack.md` holds this run's content — after the per-doc handling above has written or checked it. Read its § Runtime and § Framework, and § Packages where the file has one. A language is named when its name in the table's first column appears there as a whole word, case-sensitive (`Java` does not match `JavaScript`, `C` does not match `C#`, `go` is not `Go`), or when § Runtime names a runtime its row lists; a framework name alone names no language. Each named language takes its pin in `.claude/settings.json` `enabledPlugins`, with a report row `.claude/settings.json: enabledPlugins:{pin}`. Read `enabledPlugins` in the user-scope `~/.claude/settings.json` too (a missing or unparsable file, or a missing key, is no user choice), then resolve each pin by the first case that holds:

1. Project key present → skip (`✓ pinned`), whatever its value.
2. User scope sets the pin's key `false`, or sets `true` a key other than the pin's own whose plugin name (the part before `@`) starts with the pin's plugin name, in any marketplace (`typescript-lsp-win@local` for `typescript-lsp`) → write nothing (`⊘ missing`, resolving `skipped (user scope: {that key})`). A project `true` would override the `false`, because project scope outranks user scope, or enable a second plugin beside the variant. The pin's own key set `true` at user scope is no skip — case 4 applies.
3. Project key absent and the prior receipt's `covered` holds the pin's identity (§ 2c `covered`) → the user removed the key: insert nothing (`⊘ removed`, resolving `kept (removed)`).
4. Otherwise → insert it as `true` (`⊕ new`, resolving `inserted`).

The run asks nothing for these pins, reads user scope without writing it, and removes no key; a language with no row takes no pin. A section still on its `{…}` placeholder names no language — a greenfield first run pins none, and the re-run after the techstack fills pins them. These plugins live in the official marketplace, so they add no `extraKnownMarketplaces` entry.

| Language the techstack names | Pin | Language-server binary |
|---|---|---|
| C, C++ | `clangd-lsp@claude-plugins-official` | `brew install llvm` (macOS; then add `/opt/homebrew/opt/llvm/bin` to PATH; other platforms: the plugin's README) |
| C# | `csharp-lsp@claude-plugins-official` | `dotnet tool install --global csharp-ls` |
| Go | `gopls-lsp@claude-plugins-official` | `go install golang.org/x/tools/gopls@latest` |
| Java | `jdtls-lsp@claude-plugins-official` | `brew install jdtls` (macOS; other platforms: the plugin's README) |
| Kotlin | `kotlin-lsp@claude-plugins-official` | `brew install JetBrains/utils/kotlin-lsp` (macOS; other platforms: the plugin's README) |
| Lua | `lua-lsp@claude-plugins-official` | `brew install lua-language-server` (macOS; other platforms: the plugin's README) |
| PHP | `php-lsp@claude-plugins-official` | `npm install -g intelephense` |
| Python | `pyright-lsp@claude-plugins-official` | `npm install -g pyright` |
| Ruby | `ruby-lsp@claude-plugins-official` | `gem install ruby-lsp` |
| Rust | `rust-analyzer-lsp@claude-plugins-official` | `rustup component add rust-analyzer` |
| Swift | `swift-lsp@claude-plugins-official` | SourceKit-LSP ships with the Swift toolchain (Xcode on macOS, swift.org on Linux) — no separate install |
| TypeScript, JavaScript (Node.js, Deno, Bun) | `typescript-lsp@claude-plugins-official` | `npm install -g typescript-language-server typescript` |
