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
			#eval "$command"
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
	#eval "$command"
	echo ""
}

function deploy_dotfiles() {

	for item in dots/* dots/.*; do
		[[ -e "$item" ]] || continue  # Skip the directory itself
		link_item "$(pwd)/${item}" "${HOME}/${item}"
	done

	for item in conditionals/* conditionals/.*; do
		[[ -e "$item" ]] || continue  # Skip the directory itself
		while true; do
			read -r -p "Enter the name to link ${item} in the home directory (leave empty to skip): " link_name
			if [ -z "${link_name}" ]; then
				read -r -p "No name provided. Skip linking ${item}? (y/n) " -n 1
				echo ""
				if [[ $REPLY =~ ^[Yy]$ ]]; then
					break
				fi
			else
				link_item "$(pwd)/${item}" "${HOME}/${link_name}"
				break
			fi
		done
	done
}


function setup_tmux() {
	set -e
	set -u
	set -o pipefail

	is_app_installed() {
		type "$1" &>/dev/null
	}

	REPODIR="$(cd "$(dirname "$0")"; pwd -P)"
	cd "$REPODIR";

	if ! is_app_installed tmux; then
		printf "WARNING: \"tmux\" command is not found. Install it first\n"
		exit 1
	fi

	if [ ! -e "$HOME/.tmux/plugins/tpm" ]; then
		printf "WARNING: Cannot found TPM (Tmux Plugin Manager) at default location: \$HOME/.tmux/plugins/tpm.\n"
		git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
	fi

	# Install TPM plugins.
	# TPM requires running tmux server, as soon as `tmux start-server` does not work
	# create dump __noop session in detached mode, and kill it when plugins are installed
	printf "Install TPM plugins\n"
	tmux new -d -s __noop >/dev/null 2>&1 || true 
	tmux set-environment -g TMUX_PLUGIN_MANAGER_PATH "~/.tmux/plugins"
	"$HOME"/.tmux/plugins/tpm/bin/install_plugins || true
	tmux kill-session -t __noop >/dev/null 2>&1 || true

	printf "OK: Completed\n"
}

cd "$(dirname "${BASH_SOURCE[0]}")" || exit;
#git pull origin main;

echo ""
deploy_dotfiles;

#setup_tmux;


unset deploy_dotfiles;
unset link_item;
unset setup_tmux;