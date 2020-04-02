# Load bash_preexec

BASH_PREEXEC="$HOME/.bash-preexec.sh"
if ! [ -f "$BASH_PREEXEC" ]
then
	echo "bash_preexec couldn't be found"
	return
fi

source $BASH_PREEXEC

# Debug
printargs() {
	for arg in "$@"; do
		printf "「%s」 " "$arg"
	done
	printf "\n"
}

preexec() {
	eval "$( switchable preexec "$1" )"
}

precmd() {
	eval "$( switchable precmd "$1" )"
}


# Load the aliases if they exist
#SWITCHABLE_ALIASES=$( switchable file aliases )
# if [ -f $SWITCHABLE_ALIASES ]
# then source $SWITCHABLE_ALIASES
# fi


export SWITCHABLE_EXISTS=1
