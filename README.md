# pwgen
Swift CLI tool based on Apple's "Password AutoFill" generator code.

The original JavaScript code for Apple's "Password AutoFill" generator can be found at https://developer.apple.com/password-rules/, specifically in [scripts/generator.js](https://developer.apple.com/password-rules/scripts/generator.js) or [in this repository](_appleJS/js/generator.js).  
This tool can generate passwords in the same style ("more typeable" and uniformly random passwords) but with more customization options.

## Usage

```
USAGE:  pwgen [OPTIONS ...]

PASSWORD OPTIONS:
  -l <amount>                       The minimum number of characters the password should be
                                    long. Always matches actual length if "--random" and
                                    "--no-group" flags are both set. (default: 18)
  -r, --random                      Uniformly choose a random character for each position
                                    instead of generating a "more typeable" password.
  -g, --no-group                    Don't split password into more readable groups of
                                    characters by inserting the separator character (dash by
                                    default) at equal intervals.
  -s <character>                    The separator character used for splitting the password
                                    into groups. Ignored when "--no-group" flag is set.
                                    (default: -)
  --allowed <character set>         The set of characters which are allowed to occur in the
                                    password. Specify any of (lower | upper | digits | special
                                    | ascii | alphanum | unambiguous) or a custom string of
                                    (ASCII-printable) characters surrounded by [ and ], e.g.
                                    "[abc123]". (default: unambiguous)
  --required <character set ...>    The required character sets. The generated password will
                                    contain at least one character of each specified required
                                    set. See help for the "--allowed" option on how to specify
                                    character sets. Characters not present in the allowed
                                    characters will be removed from each set. (default: lower,
                                    upper, digits)
  --repeated <amount>               The maximum allowed length for any sequence of repeated
                                    characters in the password. E.g. for "aaba" the longest
                                    sequence has a length of 2. Unlimited if not specified.
  --consecutive <amount>            The maximum allowed length for any sequence of consecutive
                                    characters in the password. E.g. both "123" or "abc" and
                                    "321" or "cba" are considered consecutive. Unlimited if not
                                    specified.

GENERAL OPTIONS:
  -n <amount>                       The number of passwords to generate. Each password will be
                                    printed in a new line. (default: 1)
  --version                         Show the version.
  -h, --help                        Show help information.
```

## Examples

```
$ pwgen -n 5
reszor-joxqar-dEbci4
jozjov-vacHyq-myzme8
gexsuj-kUxvyt-tiqte5
gyhbax-mYpsu9-jewtar
wehSez-hyknew-byxno9
```

```
$ pwgen -r
AHV-fCS-vkF-ixn-X1a
```

```
$ pwgen -r -g -l 24
5vzDKJZiNHBF93j61G7tm1ET
```

## Download compiled binaries

Instead of building the tool yourself, you can download a compiled binary for macOS and Linux from the [latest&nbsp;release](https://github.com/YourMJK/pwgen/releases/latest).

The Linux binaries are statically linked with the Swift stdlib and thus no installation of Swift is required.

## Build prerequisites

To build the package, the Swift toolchain version 5.7 or higher needs to be installed.
- For macOS either [download Xcode from the AppStore](https://apps.apple.com/us/app/xcode/id497799835) or run `xcode-select --install` to just get the Command Line Tools.  
Swift 5.7 requires at least Xcode 14 and macOS 12.5 Monterey.
- For Linux [download Swift from swift.org](https://www.swift.org/download/) for your distro and follow the installation guide further down the page.

## Build with `make`

Build the Swift Package and copy executable to `bin/`:
```
$ make
```
Automatically install executable into `/usr/local/bin/`:
```
$ make install
```

## Build with Xcode (macOS only):  
Open the Xcode project and go to *Product > Build* (⌘B).

After that, either run it directly from `bin/pwgen` or install it to your PATH location by manually copying it, e.g.:
```
$ cp build/pwgen /usr/local/bin/
```
