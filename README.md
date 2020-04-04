# App::Switchable

A command-line tool to enable switchable graphics for certain commands.

You won't need to type `DRI_PRIME=1 steam` again.

## Usage

Write the following to the configuration file `~/.config/switchable/config.json`.

```json
{
    "match": [ "steam" ]
}
```

And then just run a command that matches.

```bash
steam
```

And it will automatically use your discrete GPU.

## Requirements

* bash
* [bash-preexec][bash-preexec]
* Perl and CPAN modules

[bash-preexec]: https://github.com/rcaloras/bash-preexec

## Installation

* Install [bash-preexec][] to `~/.bash-preexec.sh` (the default)
* Add the executable to your PATH
* Add `eval "$( switchable init )"` to your .bashrc

## Configuration

We first look at `~/.config/switchable/config.json`, and if that doesn't exist, we try `~/.switchable/config.json`.

The file is a JSON object with the following format. Note that it does allow comments. See [JSON::PP docs](https://perldoc.perl.org/JSON/PP.html#relaxed) for more details about the allowed JSON syntax.

```json5
{
    "driver": 1,   // Default value for DRI_PRIME
    "preexec": "/path/to/bash/preexec", // Path to bash-preexec
                                        // if it's not in its default location
    "match": [     // Regexes to match commands against
        "steam",
        "echo"
    ],
    "alias": [     // Commands to alias
        "glxgears"
    ]
}
```

## Caveats

Having `switchable` being called for each command adds around 140ms to each command you type. However, it isn't run when nothing is typed.

TODO add comparison video.

`switchable run` doesn't work with aliases such as `ll`.

## Contributing

Project documentation is in `docs/`, [start from the index](docs/index.md).

### Testing

Requirements:

* [Test::More][Test::More] for Perl
* [bats][bats] for Bash

[Test::More]: https://metacpan.org/pod/Test::More
[bats]: https://github.com/bats-core/bats-core

```
# In the project root
prove -l
bats -t t
```

## See also

* [Arch Wiki page about PRIME](https://wiki.archlinux.org/index.php/PRIME), used for switchable graphics
* [Wikipedia page about GPU switching](https://en.wikipedia.org/wiki/GPU_switching)

## License

This software is copyright (c) 2019 by Tilwa Qendov.

This is free software, licensed under the [Artistic License 2.0](LICENSE) (GPL Compatible)

