#!/bin/bash

export SET_VAR=1

if [ -n ${UNSET_VAR+x} ] 
then unset SET_VAR
fi
