#!/bin/bash

# Demo file that tries to show everything that works

# displays as
# <raw command>
# --> <expanded command>
# <command output>
PS4='--> '
set -xv

./switchable --help

./switchable xrandr

./switchable run echo $DRI_PRIME
./switchable run --expand echo '$DRI_PRIME'
./switchable run --driver 2 --expand echo '$DRI_PRIME'

./switchable show-config
