#!/usr/bin/env bash

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"
__root="$(cd "$(dirname "${__dir}")" && pwd)" 

echo "$__dir"
echo 


set -o errexit
set -o pipefail
set -o nounset

# vim config
rm $HOME/.vim
#ln -sf ${__dir}/sync/vim $HOME/.vim

# phoenix config
rm $HOME/.config/phoenix
#ln -snf ${__dir}/sync/phoenix $HOME/.config/phoenix
