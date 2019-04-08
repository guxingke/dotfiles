#!/usr/bin/env bash

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"
__root="$(cd "$(dirname "${__dir}")" && pwd)" 

echo $__dir
echo $__file
echo $__base
echo $__root

echo 


# check
if [ -z $HOME ];then
	echo "HOME not exists"
else
	echo "HOME = $HOME"
fi

# ln 
# file e.g: ln -sf sync/vim/.vimrc $HOME/.vimrc
# dir e.g: ln -snf sync/vim/.vim $HOME/.vim

set -o errexit
set -o pipefail
set -o nounset

# vim config
ln -sf ${__dir}/sync/vim/.vimrc $HOME/.vimrc
