# Load bash_preexec
BASH_PREEXEC="$HOME/.bash-preexec.sh"
[ -f $BASH_PREEXEC ] || return
source $BASH_PREEXEC

printargs() { printf "「%s」 " "$@"; echo; }

preexec() {
	echo "preexec"
	printargs $1
	eval $( switchable preexec "$1" )
	export SWITCHABLE_RET=$?
}

precmd() {
	echo "precmd"
	eval $( switchable precmd "$1" )
	unset SWITCHABLE_RET
}


# Load the aliases if they exist
#SWITCHABLE_ALIASES=$( switchable file aliases )
if [ -f $SWITCHABLE_ALIASES ]
then source $SWITCHABLE_ALIASES
fi


export SWITCHABLE_EXISTS=1
