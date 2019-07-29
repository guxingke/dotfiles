#!/usr/bin/env bash

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"
__root="$(cd "$(dirname "${__dir}")" && pwd)" 

echo "$__dir"
echo 

# ln 
# file e.g: ln -sf sync/vim/.vimrc $HOME/.vimrc
# dir e.g: ln -snf sync/vim/.vim $HOME/.vim

set -o errexit
set -o pipefail
set -o nounset

# vim config
echo 'install plug'
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
ln -sf ${__dir}/sync/vim/.vimrc $HOME/.vimrc

# phoenix config
ln -snf ${__dir}/sync/phoenix $HOME/.config/phoenix
