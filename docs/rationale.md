# Rationale

## Purpose

The purpose of this program is to set the `DRI_PRIME` environment variable
before executing a command as transparently as possible.

## Solution: aliases

```bash
# switchable.aliases
alias steam="DRI_PRIME=1 steam"
```

**Usage:** `steam`

**Drawback:** doesn't work with files, eg. `./MultiMC`

## Solution: shell script

### With env

```bash
# switchable.bash
#!/bin/bash
env DRI_PRIME=1 "$@" 
```

**Usage:** `switchable.bash steam`

**Drawback:** doesn't work with aliases, eg. `switchable.bash ll`

### With shell syntax

```bash
# switchable.bash
#!/bin/bash
DRI_PRIME=1 "$@"
```

**Usage:** `switchable.bash steam`

**Drawback:** `switchable.bash` is additional syntax

## Solution: preexec hook

```bash
source ~/.bash_preexec

preexec () {
	if "$(switchable.pl test "$1")"
	then
		export SWITCHABLE_DP_BAK="$DRI_PRIME";
		export DRI_PRIME=1;
		export SWITCHABLE_SET=1;
	fi
}

precmd () {
	if [-n "${SWITCHABLE_SET+x}"]
	then
		unset DRI_PRIME;
		unset SWITCHABLE_SET;
		if [-n "${SWITCHABLE_DP_BAK+x}"]
		then
			export DRI_PRIME="$SWITCHABLE_DP_BAK"
		fi
	fi
}
```

**Usage:** `steam`

**Drawback:** Needs to call perl everytime.

**Drawback:** Hard to enable/disable modifying the environment. (an environment
variable to control that isn't ideal, and would not solve the problem when we
want to one-off enable it, eg. `SWITCHABLE_ON=1 steam`)

## Solution: preexec hook + runner

As discussed before, the preexec hook works.

The only difference with this solution is that now, typing `switchable run pwd` in the terminal is a special case. We just need to not execute anything if that pattern is detected (in preexec).

Note that shell syntax can hide the call, eg. `switch"able" $(echo run) pwd` is valid, so we will assume that the user is sane and will type "switchable run" without quotes, separated by whitespace.

## What about `switchable run ll`?

We can't simply pass `ll` to `exec` as it is not a command, but an alias. Instead, we need to call it in the preexec hook, while we are still in the shell. We could parse the output of `alias` and detect when the command passed to `switchable run` is an alias, but that will increase runtime for (probably) little gain.
