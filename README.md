# Zigfetch

-   [Description](#description)
-   [Requirements](#requirements)
-   [Installation](#installation)
-   [Usage](#usage)
    -   [Configuration](#configuration)
-   [Roadtrip](#roadtrip)
-   [Contributing](#contributing)

## Description

Zigfetch is a minimal [neofetch](https://github.com/dylanaraps/neofetch)/[fastfetch](https://github.com/fastfetch-cli/fastfetch) like system information tool

## Requirements

-   \>= [zig v0.15.1](https://ziglang.org/)

### Linux only

-   [libpci](https://github.com/pciutils/pciutils)

## Installation

```console
# Clone the repo
$ git clone https://github.com/utox39/zigfetch.git

# cd to the path
$ cd path/to/zigfetch

# Build zigfetch
$ zig build -Doptimize=ReleaseSafe

# Then move it somewhere in your $PATH. Here is an example:
$ mv ./zig-out/zigfetch ~/bin/
```

## Usage

```console
$ zigfetch
```

### Configuration

> [!IMPORTANT]
> Currently, Zig does not have a built-in library for JSON validation via JSON schema, so it is very important to follow the pattern shown in the default configuration file ([config.json](https://github.com/utox39/zigfetch/blob/main/config.json)) to avoid errors

-   Create the config folder

```console
$ mkdir -p ~/.config/zigfetch
```

-   Create the config file

```console
$ cd ~/.config/zigfetch
$ touch config.json
```

-   Or copy the default config (preferred way)

```console
$ cp /path/to/zigfetch/config.json ~/.config/zigfetch/config.json
```

## Roadtrip

-   [ ] Add ASCII art for each operating system and Linux distro
-   [x] Add GPU info for Linux
-   [ ] Add packages info for Linux
-   [x] Add user customization
-   [ ] Add support for Windows

## Contributing

If you would like to contribute to this project just create a pull request which I will try to review as soon as possible.
