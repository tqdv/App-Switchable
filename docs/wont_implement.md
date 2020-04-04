# Won't Implement

The reason why I don't implement things. Generally, it's because trying to do it is a much worse solution than to instruct the user how to fix it.

## Add/Remove match

I removed the code to add and remove matches because it wasn't practical.

The syntax to add and remove a match isn't as convenient as modifying the configuration file by hand. So I considered that users should modify it by hand.

## Writing the configuration file

Since the user is expected to modify the file by hand, we can allow comments in JSON. That means we can't write to it as we would need to preserve them.

## Unaliasing

If you use `switchable reload-aliases`, you might have removed some aliases and would want them to be unaliased. We're not going to do it for you as we could unalias things you have aliased in the meantime.

Instead we're just going to tell you what to unalias if you want to. We will still reload the aliases of course, because that's expected behaviour.