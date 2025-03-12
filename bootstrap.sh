#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE[0]}")" || exit;

git pull origin main;

function deployDotfiles() {
	excludes=(".git" ".DS_Store" ".osx" "bootstrap.sh" "README.md" "LICENSE-MIT.txt")
	for item in *; do
		if [[ " ${excludes[@]} " =~ " ${item} " ]]; then
			continue
		fi
		target="${HOME}/${item}"
		if [ -e "${target}" ]; then
			mv "${target}" "${target}.orig_dot"
		fi
		ln -s "$(pwd)/${item}" "${target}"
	done
	source "${HOME}/.bash_profile";
}

if [ "$1" == "--force" ] || [ "$1" == "-f" ]; then
	deployDotfiles;
else
	deployDotfiles;
fi;
unset deployDotfiles;
