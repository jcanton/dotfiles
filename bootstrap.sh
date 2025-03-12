#!/usr/bin/env bash

function link_item() {
	item=$1
	target=$2
	today=$(date +%Y%m%d)
	originals_dir="$(pwd)/originals_${today}"
	mkdir -p "${originals_dir}"
	if [ -e "${target}" ]; then
		if [ ! -L "${target}" ] || [ "$(readlink "${target}")" != "${item}" ]; then
			command="mv ${target} ${originals_dir}/"
			echo "$command"
		else
			echo "$target is already linked to $item"
			echo ""
			return
		fi
	else
		echo "$target does not exist"
	fi
	command="ln -s ${item} ${target}"
	echo "    $command"
	echo ""
}

function deploy_dotfiles() {
	excludes=(".git" ".DS_Store" "bootstrap.sh" "README.md" "LICENSE-MIT.txt" "conditionals" "do_not_move")
	for item in .* *; do
		if [[ " ${excludes[@]} " =~ " ${item} " ]]; then
			continue
		fi
		link_item "$(pwd)/${item}" "${HOME}/${item}"
	done

	for item in conditionals/* conditionals/.*; do
		[[ -e "$item" ]] || continue  # Skip the directory itself
		while true; do
			read -r -p "Enter the name to link ${item} in the home directory (leave empty to skip): " link_name
			if [ -z "${link_name}" ]; then
				read -r -p "No name provided. Skip linking ${item}? (y/n) " -n 1
				if [[ $REPLY =~ ^[Yy]$ ]]; then
					break
				fi
			else
				link_item "$(pwd)/${item}" "${HOME}/${link_name}"
				break
			fi
		done
	done

	source "${HOME}/.bash_profile";
}


cd "$(dirname "${BASH_SOURCE[0]}")" || exit;
git pull origin main;

echo ""
deploy_dotfiles;

unset deploy_dotfiles;
unset link_item;
