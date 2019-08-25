BASH_PREEXEC="$HOME/.bash-preexec.sh"
[ -f $BASH_PREEXEC ] || return
source $BASH_PREEXEC

preexec() {
	# Do not touch if DRI_PRIME is already set
	if [ -n ${DRI_PRIME+x} ]
	then return
	fi

	if test -n "$(switchable.pl grep "$1")"
	then
		export DRI_PRIME=1
		export SWITCHABLE_SET=1
	fi
}

precmd() {
	if [ -n ${SWITCHABLE_SET+x} ]
	then
		unset DRI_PRIME
		unset SWITCHABLE_SET
	fi
}

# Load the aliases if they exist
SWITCHABLE_ALIASES=$(switchable.pl file aliases)
if [ -f $SWITCHABLE_ALIASES ]
then source $SWITCHABLE_ALIASES
fi

export SWITCHABLE_EXISTS=1
