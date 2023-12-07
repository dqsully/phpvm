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

```
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

On Ubuntu 22.04, these are the commands I had to run to get PHP 8.0 compiled and working, using libraries from Ubuntu 20.04 (codename "focal"):
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
sudo apt-get install build-essential libxml2-dev libsqlite3-dev libssl-dev libcurl4-openssl-dev zlib1g-dev
```

### PHP `./configure` flags
In order to select which libraries, extensions, and features are compiled into PHP by default, PHP's build process accepts a list of command-line flags. `phpvm` reads the file at `~/.phpvm/phpopts` for the default flags to use, and you can also add one-time flags to the end of the `phpvm install` command.

The first time you run `phpvm`, it will automatically write the following contents to `~/.phpvm/phpopts`, enabling commonly-used extensions:
```
--with-openssl --with-curl --with-zlib --enable-mbstring --with-pear
```

In my particular installation, my `~/.phpvm/phpopts` file looks like this, because I wanted even more extensions (at the cost of longer compile times):
```
--with-openssl --with-pcre-jit --with-zlib --with-bz2 --with-curl --enable-gd --with-webp --with-jpeg --with-xpm --with-freetype --enable-mbstring --with-mysqli --with-pdo-mysql --with-pear --enable-soap
```

Of course, to get this to work, I had to install more dev libraries using `apt-get`. If you'd like to go down this path as well, whenever `phpvm install` errors out because of a missing library, try searching the Ubuntu repositories using `apt-get search <name> dev`, and install the appropriate dev package for the library you're missing. For example, to install the `gd` library I ran `apt-get search gd dev`, found the package called `libgd-dev`, and installed it with `sudo apt-get install libgd-dev`.

#### Available `./configure` options
Here's part of a dump from running `./configure --help` from the PHP 8.2.3 sources:
```
Extensions:

  --with-EXTENSION=shared[,PATH]

    NOTE: Not all extensions can be build as 'shared'.

    Example: --with-foobar=shared,/usr/local/foobar/

      o Builds the foobar extension as shared extension.
      o foobar package install prefix is /usr/local/foobar/


  --disable-all           Disable all extensions which are enabled by default
  --without-libxml        Build without LIBXML support
  --with-openssl          Include OpenSSL support (requires OpenSSL >= 1.0.2)
  --with-kerberos         OPENSSL: Include Kerberos support
  --with-system-ciphers   OPENSSL: Use system default cipher list instead of
                          hardcoded value
  --with-external-pcre    Use external library for PCRE support
  --without-pcre-jit      Disable PCRE JIT functionality
  --without-sqlite3       Do not include SQLite3 support.
  --with-zlib             Include ZLIB support (requires zlib >= 1.2.0.4)
  --enable-bcmath         Enable bc style precision math functions
  --with-bz2[=DIR]        Include BZip2 support
  --enable-calendar       Enable support for calendar conversion
  --disable-ctype         Disable ctype functions
  --with-curl             Include cURL support
  --enable-dba            Build DBA with bundled modules. To build shared DBA
                          extension use --enable-dba=shared
  --with-qdbm[=DIR]       DBA: QDBM support
  --with-gdbm[=DIR]       DBA: GDBM support
  --with-ndbm[=DIR]       DBA: NDBM support
  --with-db4[=DIR]        DBA: Oracle Berkeley DB 4.x or 5.x support
  --with-db3[=DIR]        DBA: Oracle Berkeley DB 3.x support
  --with-db2[=DIR]        DBA: Oracle Berkeley DB 2.x support
  --with-db1[=DIR]        DBA: Oracle Berkeley DB 1.x support/emulation
  --with-dbm[=DIR]        DBA: DBM support
  --with-tcadb[=DIR]      DBA: Tokyo Cabinet abstract DB support
  --with-lmdb[=DIR]       DBA: Lightning memory-mapped database support
  --without-cdb[=DIR]     DBA: CDB support (bundled)
  --disable-inifile       DBA: INI support (bundled)
  --disable-flatfile      DBA: FlatFile support (bundled)
  --enable-dl-test        Enable dl_test extension
  --disable-dom           Disable DOM support
  --with-enchant          Include Enchant support
  --enable-exif           Enable EXIF (metadata from images) support
  --with-ffi              Include FFI support
  --disable-fileinfo      Disable fileinfo support
  --disable-filter        Disable input filter support
  --enable-ftp            Enable FTP support
  --with-openssl-dir      FTP: Whether to enable FTP SSL support without
                          ext/openssl
  --enable-gd             Include GD support
  --with-external-gd      Use external libgd
  --with-avif             GD: Enable AVIF support (only for bundled libgd)
  --with-webp             GD: Enable WEBP support (only for bundled libgd)
  --with-jpeg             GD: Enable JPEG support (only for bundled libgd)
  --with-xpm              GD: Enable XPM support (only for bundled libgd)
  --with-freetype         GD: Enable FreeType 2 support (only for bundled
                          libgd)
  --enable-gd-jis-conv    GD: Enable JIS-mapped Japanese font support (only
                          for bundled libgd)
  --with-gettext[=DIR]    Include GNU gettext support
  --with-gmp[=DIR]        Include GNU MP support
  --with-mhash            Include mhash support
  --without-iconv[=DIR]   Exclude iconv support
  --with-imap[=DIR]       Include IMAP support. DIR is the c-client install
                          prefix
  --with-kerberos         IMAP: Include Kerberos support
  --with-imap-ssl         IMAP: Include SSL support
  --enable-intl           Enable internationalization support
  --with-ldap[=DIR]       Include LDAP support
  --with-ldap-sasl        LDAP: Build with Cyrus SASL support
  --enable-mbstring       Enable multibyte string support
  --disable-mbregex       MBSTRING: Disable multibyte regex support
  --with-mysqli           Include MySQLi support. The MySQL native driver will
                          be used
  --with-mysql-sock[=SOCKPATH]
                          MySQLi/PDO_MYSQL: Location of the MySQL unix socket
                          pointer. If unspecified, the default locations are
                          searched
  --with-oci8[=DIR]       Include Oracle Database OCI8 support. DIR defaults
                          to $ORACLE_HOME. Use
                          --with-oci8=instantclient,/path/to/instant/client/lib
                          to use an Oracle Instant Client installation
  --with-odbcver[=HEX]    Force support for the passed ODBC version. A hex
                          number is expected, default 0x0350. Use the special
                          value of 0 to prevent an explicit ODBCVER to be
                          defined.
  --with-adabas[=DIR]     Include Adabas D support [/usr/local]
  --with-sapdb[=DIR]      Include SAP DB support [/usr/local]
  --with-solid[=DIR]      Include Solid support [/usr/local/solid]
  --with-ibm-db2[=DIR]    Include IBM DB2 support [/home/db2inst1/sqllib]
  --with-empress[=DIR]    Include Empress support $EMPRESSPATH (Empress
                          Version >= 8.60 required)
  --with-empress-bcs[=DIR]
                          Include Empress Local Access support $EMPRESSPATH
                          (Empress Version >= 8.60 required)
  --with-custom-odbc[=DIR]
                          Include user defined ODBC support. DIR is ODBC
                          install base directory [/usr/local]. Make sure to
                          define CUSTOM_ODBC_LIBS and have some odbc.h in your
                          include dirs. For example, you should define
                          following for Sybase SQL Anywhere 5.5.00 on QNX,
                          prior to running this configure script:
                          CPPFLAGS="-DODBC_QNX -DSQLANY_BUG" LDFLAGS=-lunix
                          CUSTOM_ODBC_LIBS="-ldblib -lodbc"
  --with-iodbc            Include iODBC support
  --with-esoob[=DIR]      Include Easysoft OOB support
                          [/usr/local/easysoft/oob/client]
  --with-unixODBC         Include unixODBC support
  --with-dbmaker[=DIR]    Include DBMaker support
  --disable-opcache       Disable Zend OPcache support
  --disable-huge-code-pages
                          Disable copying PHP CODE pages into HUGE PAGES
  --disable-opcache-jit   Disable JIT
  --enable-pcntl          Enable pcntl support (CLI/CGI only)
  --disable-pdo           Disable PHP Data Objects support
  --with-pdo-dblib[=DIR]  PDO: DBLIB-DB support. DIR is the FreeTDS home
                          directory
  --with-pdo-firebird[=DIR]
                          PDO: Firebird support. DIR is the Firebird base
                          install directory [/opt/firebird]
  --with-pdo-mysql[=DIR]  PDO: MySQL support. DIR is the MySQL base directory.
                          If no value or mysqlnd is passed as DIR, the MySQL
                          native driver will be used
  --with-zlib-dir[=DIR]   PDO_MySQL: Set the path to libz install prefix
  --with-pdo-oci[=DIR]    PDO: Oracle OCI support. DIR defaults to
                          $ORACLE_HOME. Use
                          --with-pdo-oci=instantclient,/path/to/instant/client/lib
                          for an Oracle Instant Client installation.
  --with-pdo-odbc=flavour,dir
                          PDO: Support for 'flavour' ODBC driver. The include
                          and lib dirs are looked for under 'dir'. The
                          'flavour' can be one of: ibm-db2, iODBC, unixODBC,
                          generic. If ',dir' part is omitted, default for the
                          flavour you have selected will be used. e.g.:
                          --with-pdo-odbc=unixODBC will check for unixODBC
                          under /usr/local. You may attempt to use an
                          otherwise unsupported driver using the 'generic'
                          flavour. The syntax for generic ODBC support is:
                          --with-pdo-odbc=generic,dir,libname,ldflags,cflags.
                          When built as 'shared' the extension filename is
                          always pdo_odbc.so
  --with-pdo-pgsql[=DIR]  PDO: PostgreSQL support. DIR is the PostgreSQL base
                          install directory or the path to pg_config
  --without-pdo-sqlite    PDO: sqlite 3 support.
  --with-pgsql[=DIR]      Include PostgreSQL support. DIR is the PostgreSQL
                          base install directory or the path to pg_config
  --disable-phar          Disable phar support
  --disable-posix         Disable POSIX-like functions
  --with-pspell[=DIR]     Include PSPELL support. GNU Aspell version 0.50.0 or
                          higher required
  --with-libedit          Include libedit readline replacement (CLI/CGI only)
  --with-readline[=DIR]   Include readline support (CLI/CGI only)
  --disable-session       Disable session support
  --with-mm[=DIR]         SESSION: Include mm support for session storage
  --enable-shmop          Enable shmop support
  --disable-simplexml     Disable SimpleXML support
  --with-snmp[=DIR]       Include SNMP support
  --enable-soap           Enable SOAP support
  --enable-sockets        Enable sockets support
  --with-sodium           Include sodium support
  --with-external-libcrypt
                          Use external libcrypt or libxcrypt
  --with-password-argon2  Include Argon2 support in password_*
  --enable-sysvmsg        Enable sysvmsg support
  --enable-sysvsem        Enable System V semaphore support
  --enable-sysvshm        Enable the System V shared memory support
  --with-tidy[=DIR]       Include TIDY support
  --disable-tokenizer     Disable tokenizer support
  --disable-xml           Disable XML support
  --with-expat            XML: use expat instead of libxml2
  --disable-xmlreader     Disable XMLReader support
  --disable-xmlwriter     Disable XMLWriter support
  --with-xsl              Build with XSL support
  --enable-zend-test      Enable zend_test extension
  --with-zip              Include Zip read/write support
  --enable-mysqlnd        Enable mysqlnd explicitly, will be done implicitly
                          when required by other extensions
  --disable-mysqlnd-compression-support
                          Disable support for the MySQL compressed protocol in
                          mysqlnd

PEAR:

  --with-pear[=DIR]       Install PEAR in DIR [PREFIX/lib/php]
  --disable-fiber-asm     Disable the use of boost fiber assembly files

Zend:

  --disable-zend-signals  whether to enable zend signal handling

```
