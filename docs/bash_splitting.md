# Bash word splitting

Bash word splitting matters when we're the ones supposed to execute a command
that is passed to us, to preserve the arguments as they were originally.

This happens for `switchable run <cmd>`

## Without preexec

```bash
switchable run echo $DRI_PRIME  #> ''
switchable run --expand echo '$DRI_PRIME'  #> 1
```

Without preexec, we receive the arguments word-splitted from the shell in
`@ARGV`.

If we want shell expansion, we could concatenate it all and quote it
appropriately. Or just directly pass it to eval and consider that
the user is responsible
of quoting their arguments correctly.

Otherwise we can just pass it to `exec PROGRAM LIST` which
forces perl to send the arguments verbatim.

Shell expansion should be enabled as a command-line flag as it can cause
unwanted behaviour, for example when passing single quoted string that could be
interpolated: `perl -e 'my $a = 1'`.
As it is unsafe, the `--expand` switch shall not be shortened.

We don't need to worry about shell piping or redirection as it is the shell
that passes the arguments to us.

## With preexec

In preexec, we get the command as it is typed in terminal through the `$1`
argument of the function. It is a single string. We would like to preserve
the word splitting, and pass it correctly to Perl.

Not quoting `$1` doesn't work: for a value of `a a` we get `a` `a`.  
Quoting it would require post processing: for `a b "a"` we get `a b "a"`
as a single string.  
We could try using arrays ([source][bash array for args]), as they do correct word splitting: `(a "spa ce")`
gives us `a` and `spa ce`. However, we can't interpolate the contents of
other variables in it: `($DATA)` doesn't work and word splits `$DATA` on spaces
as it is shell expansion
(see [Bash Manual §Word Splitting][bash word splitting]).

[bash array for args]: https://superuser.com/questions/360966/how-do-i-use-a-bash-variable-string-containing-quotes-in-a-command/360986#360986
[bash word splitting]: https://www.gnu.org/software/bash/manual/html_node/Word-Splitting.html

This circumvent this, we could make perl generate the array splitting `( ... )`
string for us, execute it in Bash, and then make it call us again.

```
shell:         switchable run <cmd>
bash_preexec:  eval "$( switchable preexec "switchable run <cmd>" )"
switchable:    print "eval '...=( ... )'; switchable preexec --split ..."
bash_preexec:  eval '...=( ... )'
eval:          SWITCHABLE_DATA=( "switchable" "run" "<cmd>" )
bash_preexec:  switchable preexec --split -- "${SWITCHABLE_DATA[@]}"
switchable:    GetOptions( ... )
switchable:    run_subcommand( ... )
```

The downside is that we still need to escape the command string properly
when printing the string to array split. This is why we use another eval
to isolate it completely.
