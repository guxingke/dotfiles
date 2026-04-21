# dotfiles

Dotfiles manager CLI built with Bun + TypeScript.

## Tech Stack

- Runtime: Bun
- Language: TypeScript (strict mode)
- Dependencies: yaml
- No CLI framework — switch/case command dispatch

## Architecture

- `src/cli.ts` — single-file CLI, all commands and types
- `mods/` — module directory, each subdir maps to `$HOME`
- `mod.yaml` — optional per-module config (mode, pre/post hooks, depends, ignore)

## Build & Check

```bash
bun install
bunx tsc --noEmit          # type check
bun run src/cli.ts status   # verify
```

## Key Design Decisions

- **Copy, not symlink** — deploy copies files to `$HOME`, intentional choice
- **Permissions preserved** — deploy/pull/import all retain source file mode (important for `.ssh`)
- **Local files** (`*.local`, `*.custom`) are gitignored but deployed and managed
- **pull only covers tracked files** — use `import` to bring new files under management
- **deploy auto-backups** overwritten files to `~/backups/dotfiles/`
- **Dependency ordering** via topological sort on `depends` field in mod.yaml
- Tracked configs load `.local` variants at runtime (shell: `source`, ssh: `Include`)

## Conventions

- Follow existing command patterns in cli.ts when adding new commands
- Each command is an async function named `cmd<Name>`
- Module discovery is automatic — any directory under `mods/` is a module
- Backup filenames encode their restore target: `local-*` → mods/, others → $HOME
