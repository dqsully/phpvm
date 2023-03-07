# phpvm

A php version manager for linux that stays out of your way.

## Quick start

Clone repo somewhere

```
phpvm install php
phpvm install composer
```

## Commands

### `phpvm ls-remote <tool>`
Where `<tool>` is `php` or `composer`, lists available versions for download for the appropriate tool.

This command fetches from http://php.net/downloads.php and http://php.net/releases/ for PHP versions, and https://getcomposer.org/download/ for Composer versions.

### `phpvm install <tool> [version]`
Where `<tool>` is `php` or `composer`, installs the specified version of that tool.

If version isn't set, it defaults to `*`. If version is only partial, the remaining numbers will be filled in with `*`s. For example, `phpvm install php 8` is equivalent to `phpvm install php 8.*.*`, which will install the latest PHP 8 release.

### `phpvm ls [tool]`
Where `<tool>` may be `php`, `composer`, or unset, lists installed versions of those tools.

### `phpvm bin <tool> [version]`
Where `<tool>` is `php` or `composer`, prints the binary path for the appropriate tool and version.

See [`phpvm install`](#phpvm-install-tool-version) for more info about the version parameter.

### `phpvm remove <tool> <version>`
Where `<tool>` is `php` or `composer`, and `<version>` is an installed version, removes all of that version's files from the filesystem.

This is the only command where the version parameter must match an exact version, for example `phpvm remove php 8.0.28`. No `*`s, partial versions, or empty parameters will work.

### `phpvm path <tool> [version]`
Prints an updated `PATH` environment variable containing the requested tool version.


## Integrating into your .*rc
```bash
phpv() {
    local newpath
    if newpath=$(phpvm path php "$1"); then
        PATH="$newpath"
        echo "Using PHP from $(command -v php)"
    else
        echo $newpath
        return 1
    fi
}

composerv() {
    local newpath
    if newpath=$(phpvm path composer "$1"); then
        PATH="$newpath"
        echo "Using Composer from $(command -v composer)"
    else
        echo $newpath
        return 1
    fi
}

phpv >/dev/null # Load latest PHP version by default
composerv >/dev/null # Load latest Composer version by default
```

## Reference

### Build dependencies

A list of some php deps required for building

#### Ubuntu

```
sudo apt-get install build-essential libxml2-dev libsqlite3-dev
```
