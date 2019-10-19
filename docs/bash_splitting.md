# Bash word splitting

Bash word splitting matters when we're the ones supposed to execute a command
that is passed to us, to preserve the arguments as they were originally.

Without preexec, we receive the arguments word-splitted from the shell in
`@ARGV`.

If we want shell expansion, the we should concatenate it all and quote it
appropriately, otherwise we can just pass it to `exec PROGRAM LIST` which
forces perl to send the arguments verbatim.

In preexec, we get the command as it is typed in terminal through the `$1`
argument of the function. It is a single string. We would like to preserve the word splitting.

This is for `switchable run <cmd>` where we need to execute the command. We
should preserve the word splitting in that case. This happens in the preexec
hooks

Not quoting doesn't work: for a value of `a a` we get `a` `a`.  
Quoting it would require post processing: for `a b "a"` we get `a b "a"`
as a single string.  
The final option is to use 

