# Execution

Sometimes, we need to run things directly in the calling shell.

To do so, we use `bash_preexec` and add a hook that will call our executable again, and pass it the command to run.

For example, when typing this in a shell:

    $ pwd

It calls:

    bash_preexec: eval $( switchable preexec 'pwd' )
    shell:        pwd
    bash_precmd:  eval $( switchable precmd 'pwd' )

This is useful when we need to modify the environment variables before calling the user command:

    $ echo $DRI_PRIME
    bash_preexec: eval $( switchable preexec <command string> )  # modifies DRI_PRIME
    shell:        echo $DRI_PRIME  #> 1
    bash_precmd:  eval $( switchable precmd <command string> )  # restores DRI_PRIME to its previous value

## Aliases

```bash
switchable run ll
```

In addition to either intercepting it or not, we sometimes need to execute the command in the shell. This is the case for aliases.

For this to work, we need to modify env and run the actual command in preexec, make the actual command a no-op, and clean up in precmd.\
Which means that this is only possible if we are able to make the command a no-op: when we are the ones being called.

## Summary

If we don't have bash\_preexec, we'll call the supplied command with env\
If we do have bash\_preexec, we'll modify env with the preexec hook.\
And if we're the ones being called, we'll also execute the command in that hook.

To tell that preexec exists and has already ran the command, the hooks must set and then unset the `SWITCHABLE_RAN` variable.
