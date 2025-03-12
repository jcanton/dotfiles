#!/usr/bin/env bash

function link_item() {
	item=$1
	target=$2
	if [ -e "${target}" ]; then
		command="mv ${target} ${target}.orig_dot"
		echo "$command"
	fi
	command="ln -s ${item} ${target}"
	echo "$command"
}

function deploy_dotfiles() {
	excludes=(".git" ".DS_Store" "bootstrap.sh" "README.md" "LICENSE-MIT.txt" "conditionals" "do_not_move")
	for item in .* *; do
		if [[ " ${excludes[@]} " =~ " ${item} " ]]; then
			continue
		fi
		link_item "$(pwd)/${item}" "${HOME}/${item}"
	done

	for item in conditionals/.* conditionals/*; do
		read -r -p "Enter the name to link ${item} in the home directory (leave empty to skip): " link_name
		if [ -z "${link_name}" ]; then
			read -r -p "No name provided. Skip linking ${item}? (y/n) " -n 1
			echo ""
			if [[ $REPLY =~ ^[Yy]$ ]]; then
				continue
			fi
		else
			link_item "$(pwd)/${item}" "${HOME}/${link_name}"
		fi
	done

	source "${HOME}/.bash_profile";
}


cd "$(dirname "${BASH_SOURCE[0]}")" || exit;
git pull origin main;

deploy_dotfiles;

unset deploy_dotfiles;
unset link_item;
