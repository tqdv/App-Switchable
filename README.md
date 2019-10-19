# App-PRIME-Switchable

> Command-line tool to enable switchable graphics for certain commands

With it, you won't need to type `DRI_PRIME=1 steam` again.

## Usage

```
switchable add steam
# Reload shell
steam
```

## Prerequisites

* bash as the default shell
* Perl CPAN modules:
  * List::Gather
  * Path::Tiny
  * File::Which

FIXME

## Installation

* Install `bash-preexec` to `~/.bash-preexec.sh` (the default)
* Add the executable to your PATH
* Add `source $(switchable file bash)` to your .bashrc

## Configuration

Add and remove aliases by calling `switchable add <command>` and
`switchable remove <command>` respectively.

To set the regexes that are matched against by `switchable grep`, edit the
file path as returned by `switchable file regex`. One regex per line,
in Perl without the slashes (eg. `foo` instead of `/foo/`). Comments are lines
that start with a `#` hash character.

## Testing

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

## Notes

By default, switchable will try to determine where the files are installed,
and where the configuration files are based on the library path.\
You can override this by setting the `SWITCHABLE_HIER` environment variable to
either 'xdg' (for `~/.local/bin` and `~/.config/switchable`, etc…) or 'dot'
(for `~/.switchable`).


## License

This software is Copyright (c) 2019 by Tilwa Qendov.

This is free software, licensed under the Artistic License 2.0 (GPL Compatible)

