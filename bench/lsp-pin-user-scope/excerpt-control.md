**Language-server pins (techstack-derived).** Run this once `docs/techstack.md` holds this run's content — after the per-doc handling above has written or checked it. Read its § Runtime and § Framework, and § Packages where the file has one. A language is named when its name in the table's first column appears there as a whole word, case-sensitive (`Java` does not match `JavaScript`, `C` does not match `C#`, `go` is not `Go`), or when § Runtime names a runtime its row lists; a framework name alone names no language. Each named language takes its pin in `.claude/settings.json` `enabledPlugins`, by the core pin's rule (§ 2a): key absent → insert it as `true` (`⊕ new`, resolving `inserted`); key present → skip (`✓ pinned`), whatever its value. The run asks nothing for these pins and removes none; a language with no row takes no pin. A section still on its `{…}` placeholder names no language — a greenfield first run pins none, and the re-run after the techstack fills pins them. These plugins live in the official marketplace, so they add no `extraKnownMarketplaces` entry.

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
