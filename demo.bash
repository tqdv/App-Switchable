#!/bin/bash

# Demo file that tries to show everything that works

PS4='--> '
set -xv
# displays as
# <raw command>
# --> <expanded command>
# <command output>

./switchable --help

./switchable xrandr --help
./switchable xrandr

./switchable run --help
./switchable run echo $DRI_PRIME
./switchable run --expand echo '$DRI_PRIME'
./switchable run --driver 2 --expand echo '$DRI_PRIME'
