# dotfiles

CLI-driven dotfiles manager. Bun + TypeScript, no framework.

## Quick Start

```bash
bun install

# check what's managed
dotfiles status

# deploy all modules to $HOME
dotfiles deploy

# import existing config into management
dotfiles import git ~/.gitconfig
```

Shell registration (add to `~/.zshrc.local`):

```bash
function dotfiles() { bun run ~/toy/dotfiles/src/cli.ts "$@"; }
eval "$(dotfiles _completion zsh)"
```

## Commands

| Command | Description |
|---|---|
| `status` | Show sync status of all modules |
| `diff [name]` | Show diff for one or all modules |
| `deploy [name] [--dry-run]` | Deploy modules to `$HOME` (auto-backups overwritten files) |
| `pull [name]` | Pull changes from `$HOME` back into mods (tracked files only) |
| `import <mod> <file> [file...]` | Import existing file(s) into a module |
| `uninstall <name>` | Remove deployed files from `$HOME` (with backup) |
| `backup` | Backup all local files to `~/backups/dotfiles/` |
| `restore [file]` | List backups or restore from a backup |

## Project Structure

```
dotfiles/
├── src/cli.ts              # CLI entry point (single file)
├── mods/                   # Module directory
│   ├── zsh/
│   │   ├── .zshrc          # → ~/.zshrc (git tracked)
│   │   └── .zshrc.local    # → ~/.zshrc.local (gitignored)
│   ├── ssh/
│   │   └── .ssh/
│   │       ├── config          # → ~/.ssh/config (git tracked, Include config.local)
│   │       └── config.local    # → ~/.ssh/config.local (gitignored)
│   ├── fish/
│   │   └── .config/fish/config.fish
│   ├── starship/
│   │   └── .config/starship.toml
│   └── hammerspoon/
│       ├── mod.yaml        # Module config (optional)
│       └── .hammerspoon/init.lua
├── package.json
└── tsconfig.json
```

## Conventions

### Module Layout

Each subdirectory under `mods/` is a module. The file tree inside mirrors `$HOME`:

```
mods/zsh/.zshrc                       → ~/.zshrc
mods/starship/.config/starship.toml   → ~/.config/starship.toml
```

No configuration needed for the common case.

### Deploy Modes

| Mode | Description | When |
|---|---|---|
| **copy** (default) | Diff-check then copy to `$HOME` | Most configs |
| **custom** | Run `deploy.sh` in module dir | Special handling needed |

### mod.yaml

Optional per-module configuration:

```yaml
mode: copy              # copy | custom
pre: "brew list foo"    # Run before deploy, skip module on failure
post: "open -g hammerspoon://reload"  # Run after deploy on change
depends:                # Deploy order dependencies (topo-sorted)
  - starship            # this module is deployed after `starship`
ignore:                 # Exclude paths matching JS regex (against path relative to module root, NOT glob)
  - "\\.bak$"           # any *.bak file
  - "^cache/"           # the cache/ subdirectory
```

### Local / Private Files

Machine-specific configs live alongside tracked files but are gitignored:

| Pattern | Example |
|---|---|
| `*.local` | `.zshrc.local` |
| `*.local.*` | `config.local.yaml` |
| `*.custom` | `env.custom` |
| `*.custom.*` | `secrets.custom.toml` |

These files are deployed normally but not committed. The tracked config loads them at runtime:

```bash
# .zshrc — source at end
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# .ssh/config — Include at top
Include ~/.ssh/config.local

# config.fish — source at end
test -f ~/.config/fish/config.fish.local && source ~/.config/fish/config.fish.local
```

File permissions are preserved across deploy/pull/import (important for `.ssh`).

### Data Flow

| Operation | Direction | Scope |
|---|---|---|
| **deploy** | mods → `$HOME` | All files (tracked + local) |
| **pull** | `$HOME` → mods | Tracked files only |
| **import** | `$HOME` → mods | Explicitly specified files |
| **backup/restore** | mods ↔ `~/backups/` | Local files only |

New machine workflow:
1. Clone repo, `bun install`
2. `dotfiles deploy` — deploy tracked configs
3. Create `~/.zshrc.local` with machine-specific content
4. `dotfiles import zsh ~/.zshrc.local` — bring it under management
5. `dotfiles backup` — save local files

### Backup Types

| Prefix | Created by | Restores to |
|---|---|---|
| `local-*` | `backup` | `mods/` |
| `pre-deploy-*` | `deploy` (auto) | `$HOME` |
| `uninstall-*` | `uninstall` (auto) | `$HOME` |

## Current Modules

| Module | Contents |
|---|---|
| **zsh** | zinit + plugins + starship + zoxide, `.zshrc.local` for machine-specific config |
| **ssh** | SSH client config, `config.local` for private Host entries |
| **fish** | Minimal config + starship |
| **starship** | Two-line prompt, lambda character |
| **hammerspoon** | Window management (copy mode + reload hook) |

## Requirements

- [Bun](https://bun.sh)
- [Starship](https://starship.rs) — `brew install starship`
- [zoxide](https://github.com/ajeetdsouza/zoxide) — `brew install zoxide`
