export ZSH=/Users/gxk/.oh-my-zsh

DEFAULT_USER="gxk"
ZSH_THEME="gxk"
BULLETTRAIN_CONTEXT_DEFAULT_USER="gxk"
BULLETTRAIN_TIME_BG=105
BULLETTRAIN_DIR_BG=026
BULLETTRAIN_GIT_BG=231
BULLETTRAIN_GIT_DIRTY=" %F{red}✘%F{black}"
BULLETTRAIN_GIT_CLEAN=" %F{green}✔%F{black}"
BULLETTRAIN_GIT_UNTRACKED=" %F{208}✭"
BULLETTRAIN_PROMPT_CHAR="λ"
BULLETTRAIN_PROMPT_ADD_NEWLINE=false
BULLETTRAIN_PROMPT_ORDER=(
  status
  time
  virtualenv
  git
  dir
  cmd_exec_time
)

plugins=(me git extract fuck sh-agent autojump zsh zsh-syntax-highlighting zsh-autosuggestions zsh-completions nvm)
# zsh-completions
autoload -U compinit && compinit

source $ZSH/oh-my-zsh.sh

####
# PATH
####
export PATH=$HOME/bin:$PATH
