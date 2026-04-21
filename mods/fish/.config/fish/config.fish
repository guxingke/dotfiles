# --- no greeting ---
set -g fish_greeting

# --- aliases ---
alias ll 'ls -alF'
alias la 'ls -A'
alias l 'ls -CF'

# --- starship ---
set -gx STARSHIP_CONFIG "$HOME/.config/starship.toml"
starship init fish | source

# --- local ---
test -f ~/.config/fish/config.fish.local && source ~/.config/fish/config.fish.local
