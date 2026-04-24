export PATH=$HOME/.local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH

# --- zinit ---
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [[ ! -d "$ZINIT_HOME" ]]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "$ZINIT_HOME/zinit.zsh"

# --- plugins ---
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit snippet OMZ::lib/git.zsh
zinit snippet OMZP::git

# --- completions ---
autoload -Uz compinit
# rebuild comp dump once a day
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# --- history ---
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt share_history
setopt hist_ignore_all_dups
setopt hist_ignore_space

# --- options ---
setopt auto_cd
setopt interactive_comments

# --- aliases ---
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# --- bun ---
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# --- fnm ---
eval "$(fnm env --use-on-cd --shell zsh)"

# --- autojump ---
# eval "$(zoxide init zsh --cmd j)"   # 留底，便于回滚
zinit snippet OMZP::autojump

# --- edit command in $EDITOR ---
autoload -Uz edit-command-line
function edit-command-line-and-move-end {
  edit-command-line
  zle end-of-line
}
zle -N edit-command-line-and-move-end
bindkey '^X^K' edit-command-line-and-move-end

# --- fzf ---
export FZF_DEFAULT_COMMAND="fd --exclude={.git,.idea,.vscode,.sass-cache,node_modules,build} --type f"
export FZF_CTRL_T_OPTS="--ansi --preview-window 'right:60%' --layout=reverse --preview 'bat --color=always --style=header,grid --line-range :300 {}'"
export FZF_CTRL_R_OPTS="--layout=reverse --preview-window 'right:60%:wrap' --preview 'echo {}' --bind 'ctrl-y:execute-silent(echo -n {2..} | xargs -I {} mm cmd {})+abort' --color header:italic --header 'Press CTRL-Y to send command into memos'"
eval "$(fzf --zsh)"

# --- starship ---
export STARSHIP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml"
eval "$(starship init zsh)"

# --- local ---
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Atuin - shell history
eval "$(atuin init zsh --disable-up-arrow)"
