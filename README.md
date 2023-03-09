# phpvm

A php version manager for linux that stays out of your way.

## Quick start

Clone repo somewhere

```
phpvm install php
phpvm install composer
```

## Commands

### `phpvm install <tool> [version]`
Where `<tool>` is `php` or `composer`, installs the specified version of that tool.

If version isn't set, it defaults to `*`. If version is only partial, the remaining numbers will be filled in with `*`s. For example, `phpvm install php 8` is equivalent to `phpvm install php 8.*.*`, which will install the latest PHP 8 release.

### `phpvm ls [tool]`
Where `<tool>` may be `php`, `composer`, or unset, lists installed versions of those tools.

### `phpvm ls-remote <tool>`
Where `<tool>` is `php` or `composer`, lists available versions for download for the appropriate tool.

This command fetches from http://php.net/downloads.php and http://php.net/releases/ for PHP versions, and https://getcomposer.org/download/ for Composer versions.

### `phpvm bin <tool> [version]`
Where `<tool>` is `php` or `composer`, prints the binary path for the appropriate tool and version.

See [`phpvm install`](#phpvm-install-tool-version) for more info about the version parameter.

### `phpvm remove <tool> <version>`
Where `<tool>` is `php` or `composer`, and `<version>` is an installed version, removes all of that version's files from the filesystem.

This is the only command where the version parameter must match an exact version, for example `phpvm remove php 8.0.28`. No `*`s, partial versions, or empty parameters will work.

### `phpvm path <tool> [version]`
Prints an updated `PATH` environment variable containing the requested tool version.

### `phpvm ld-path <tool> [version]`
Prints an updated `LD_LIBRARY_PATH` environment variable for the requested tool version (if it was built against libraries from an older Ubuntu version).

### `phpvm install-lib <codename> <package...>`
Downloads and extracts one or more packages from a specific version of Ubuntu, in case your current libraries don't match what's needed by PHP (PHP <8.1 is incompatible with OpenSSL 3 for example).


## Switching active PHP versions

### `phpswitch.sh`
In order to make switching PHP versions easy, portable, and configurable per directory, you can link this shell script to a binary dir for each PHP or Composer binary you want to swap versions.

With `phpswitch.sh`, you can create `.phpv` files in your projects like so

```bash
php=8.0
composer=2
```

and when you run `php`, it will automatically use the latest PHP 8.0.x release that you have installed. Similarly, running `composer` will use the latest installed Composer 2.x.x release.

`phpswitch.sh` will start at the current working directory (wherever `php` was called from), searching for a `.phpv` file, and then check every parent directory until it hits the root of the filesystem. It also checks `$HOME/.phpv` as a last resort, which you can use to set the default PHP and composer versions globally.

This method also currently works with Debian's alternatives system, so if you're on Ubuntu, Debian, or another Debian-based Linux distribution, and have multiple PHP versions installed, this is able to use those PHP versions as well.

#### Setting up `phpswitch.sh`
Assuming `~/bin` is a valid bin directory on your system, you can run:
```bash
PHPSWITCH_PATH="path/to/phpvm/phpswitch.sh"
BIN_PATH="$HOME/bin"

# Most common
ln -s "$PHPSWITCH_PATH" $BIN_PATH/php
ln -s "$PHPSWITCH_PATH" $BIN_PATH/phar
ln -s "$PHPSWITCH_PATH" $BIN_PATH/phar.phar
ln -s "$PHPSWITCH_PATH" $BIN_PATH/phpize
ln -s "$PHPSWITCH_PATH" $BIN_PATH/php-config
ln -s "$PHPSWITCH_PATH" $BIN_PATH/composer
ln -s "$PHPSWITCH_PATH" $BIN_PATH/composer.phar

# Additional (ideal for phpvm PHP installs)
ln -s "$PHPSWITCH_PATH" $BIN_PATH/pear
ln -s "$PHPSWITCH_PATH" $BIN_PATH/peardev
ln -s "$PHPSWITCH_PATH" $BIN_PATH/pecl
ln -s "$PHPSWITCH_PATH" $BIN_PATH/phpdbg
```

If you'd like to set up `~/bin` as a bin directory on your system, create the directory, and then add this line to your `.bashrc` or `.zshrc`:
```bash
export PATH="$HOME/bin:$PATH"
```

### Using just your `.bashrc` (or `.zshrc`, etc.)
This method only works for phpvm PHP installations, and does not support `.phpv` files, but if the previous method doesn't work for you, this will let you switch PHP versions quickly, and won't add any overhead while calling PHP or any other command.

```bash
phpv() {
    local newpath
    if newpath=$(phpvm path php "$1"); then
        export PATH="$newpath"
        echo "Using PHP from $(command -v php)"
    else
        echo $newpath
        return 1
    fi

    if newpath=$(phpvm ld-path "$1"); then
        export LD_LIBRARY_PATH="$newpath"
        echo "Using extra libraries from $(echo "$LD_LIBRARY_PATH" | awk -F: '{ print $1 }')"
    fi
}

composerv() {
    local newpath
    if newpath=$(phpvm path composer "$1"); then
        export PATH="$newpath"
        echo "Using Composer from $(command -v composer)"
    else
        echo $newpath
        return 1
    fi
}

phpv >/dev/null # Load latest PHP version by default
composerv >/dev/null # Load latest Composer version by default
```

## Installing PHP <=8.0 on Ubuntu 22.04+
PHP 8.0 and prior versions are incompatible with OpenSSL 3, which is installed in Ubuntu 22.04+ by default. To fix this, phpvm allows downloading and compiling against packages from older Ubuntu versions.

On Ubuntu 22.04 (codename "focal fossa", aka just "focal"), these are the commands I had to run to get PHP 8.0 compiled and working:
```bash
phpvm install-lib focal libcurl4-openssl-dev libssl-dev
phpvm install php 8.0 --libs-from focal
```

And then running `phpv 8.0` just works! (see the *.rc script in the previous section)

## Reference

### Build dependencies

A list of some php deps required for building

#### Ubuntu

```
sudo apt-get install build-essential libxml2-dev libsqlite3-dev libssl-dev libcurl4-openssl-dev
```
