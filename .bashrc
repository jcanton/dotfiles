[ -n "$PS1" ] && source ~/.bash_profile;

# machine specific configuration
if [ -f ~/.bashrc.local ]; then
	. ~/.bashrc.local
fi
