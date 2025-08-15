# LLM Guide

## LLM instructions

- Use justfile recipes - Run `just check`, `just format`, and `just build` instead of calling tools directly.
- Keep functions short and focused - Under 16 lines, doing one clear thing. Prefer pure functions for easier testing.
- Isolate side effects - Extract side effects (API calls, file I/O, etc.) into dedicated functions that only perform that operation.
- Avoid unnecessary classes - Only create classes when you need to bundle related behavior with state. Use functions otherwise.
- Comments should explain WHY, not WHAT - Only add comments to explain non-obvious reasoning, trade-offs, or business logic. Don't describe what the code does.
- Replace unclear code with well-named functions - If code needs a comment to explain what it does, extract it into a function with a descriptive name instead.
- Prefer self-documenting code over comments - Code should be readable through clear variable names, function names, and structure rather than explanatory comments.

## Committing

- Add files explicitly using `git add <filename>`. Do NOT use `git add -A`.
- Write clear imperative commit messages - Start with a capitalized verb (Add, Fix, Improve) and describe what the change accomplishes without needing to read the code.
- Do NOT mention that commits are co-authored by Claude

## Rust projects

- add dependencies using `cargo add` to get latest version
- use `dotenvy` crate instead of `dotenv`
- Do NOT modify allowed clippy lints in `Cargo.toml`
