# Won't Implement

## Add/Remove match

I removed the code to add and remove matches because it wasn't practical.

The syntax to add and remove a match isn't as convenient as modifying the configuration file by hand. So I considered that users should modify it by hand.

## Writing the configuration file

Since the user is expected to modify the file by hand, we can allow comments in JSON. That means we can't write to it as we would need to preserve them.