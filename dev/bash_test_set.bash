#!/bin/bash

export SET_VAR=1

if [ -n ${SET_VAR+x} ] 
then unset SET_VAR
fi
