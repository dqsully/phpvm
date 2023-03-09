#!/bin/bash

phpvm_path="$HOME/.phpvm"
php_installs_path="$phpvm_path/php-installs"
composer_installs_path="$phpvm_path/composer-installs"

get_tool_version_from_file() {
    local tool="$1"
    local file="$2"

    awk -F= '$1 == "'"$tool"'" { print $2; exit }' "$file"
}

find_tool_version() {
    local tool="$1"
    local version

    case "$tool" in
        php)
            if [[ ! -z "$PHP_VERSION" ]]; then
                echo "$PHP_VERSION"
                return 0
            fi
            ;;

        composer)
            if [[ ! -z "$COMPOSER_VERSION" ]]; then
                echo "$COMPOSER_VERSION"
                return 0
            fi
            ;;
    esac

    local dir="$PWD"

    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/.phpv" ]]; then
            version="$(get_tool_version_from_file "$tool" "$dir/.phpv")"
            if [[ ! -z "$version" ]]; then
                echo "$version"
                return 0
            fi
        fi

        dir="$(dirname "$dir")"
    done

    if [[ -f "$HOME/.phpv" ]]; then
        version="$(get_tool_version_from_file "$tool" "$HOME/.phpv")"
        if [[ ! -z "$version" ]]; then
            echo "$version"
            return 0
        fi
    fi

    return 1
}

version_to_regex() {
    local version="${1:-"*"}"
    if echo "$version" | grep -q -E '^([0-9]+|\*)$'; then
        version="$version(.*(.*)?)?"
    elif echo "$version" | grep -q -E '^([0-9]+|\*)\.([0-9]+|\*)$'; then
        version="$version(.*)?"
    elif echo "$version" | grep -q -E '^([0-9]+|\*)\.([0-9]+|\*)\.([0-9]+|\*)$'; then
        : # Do nothing
    else
        echo "Not a valid version number: $version"
        return 1
    fi
    echo "$version" | sed -E -e 's/\./[.]/g' -e 's/\*/[0-9]+/g'
    return 0
}

latest_matching_version() {
    local version_regex="$1"
    sort -V | uniq | grep -E "$version_regex" | tail -n 1
    return 0
}

find_php_tool() {
    local requested_version=$(find_tool_version "php")
    requested_version=${requested_version:-"*"}

    local version_regex
    if ! version_regex=$(version_to_regex "$requested_version"); then
        echo "$version_regex"
        return 1
    fi

    local matching_phpvm_version=$(ls "$php_installs_path" | latest_matching_version "$version_regex")
    if [[ ! -z "$matching_phpvm_version" ]]; then
        export PHPVM_PHP_MODE="phpvm"
        export PHPVM_PHP_DIR="$php_installs_path/$matching_phpvm_version/bin"

        if [[ -f "$php_installs_path/$matching_phpvm_version/LD_LIBRARY_PATH" ]]; then
            export LD_LIBRARY_PATH="$(cat "$php_installs_path/$matching_phpvm_version/LD_LIBRARY_PATH"):$LD_LIBRARY_PATH"
        fi

        return 0
    fi

    # TODO: crawl all binary directories instead of just /usr/bin?
    local matching_sys_php_version=$(find "/usr/bin" -maxdepth 1 -type f -regex '^/usr/bin/php[0-9.]+$' | sed 's/^.+php//g' | latest_matching_version "$version_regex")
    if [[ ! -z "$matching_sys_php_version" ]]; then
        export PHPVM_PHP_MODE="debian-alternatives"
        export PHPVM_PHP_SUFFIX="$matching_sys_php_version"
        export PHPVM_PHP_DIR="/usr/bin"

        return 0
    fi

    echo "Could not find a suitable PHP installation matching $requested_version"
    echo "Maybe you need to install PHP first?:"
    echo
    echo "  phpvm install php"
    echo
    return 1
}

find_composer_tool() {
    local requested_version=$(find_tool_version "composer")
    requested_version=${requested_version:-"*"}

    local version_regex
    if ! version_regex=$(version_to_regex "$requested_version"); then
        echo "$version_regex"
        return 1
    fi

    local matching_phpvm_version=$(ls "$composer_installs_path" | latest_matching_version "$version_regex")
    if [[ ! -z "$matching_phpvm_version" ]]; then
        export PHPVM_COMPOSER_DIR="$composer_installs_path/$matching_phpvm_version"

        return 0
    fi

    echo "Could not find a suitable Composer installation matching $requested_version"
    echo "Maybe you need to install Composer first?:"
    echo
    echo "  phpvm install composer"
    echo
    return 1
}

call_php_tool() {
    if [[ -z "$PHPVM_PHP_DIR" ]]; then
        find_php_tool || return
    fi

    case "$PHPVM_PHP_MODE" in
        debian-alternatives)
            "$PHPVM_PHP_DIR/php$PHPVM_PHP_SUFFIX" "$@"
            ;;
        phpvm)
            "$PHPVM_PHP_DIR/php" "$@"
            ;;
        *)
            echo "Unsupported PHP mode '$PHPVM_PHP_MODE'"
            return 1
            ;;
    esac
}

call_composer_tool() {
    if [[ -z "$PHPVM_COMPOSER_DIR" ]]; then
        find_composer_tool || return
    fi

    "$PHPVM_COMPOSER_DIR/composer" "$@"
}

bin_name=$(basename "$0")

case "$bin_name" in
    pear|peardev|pecl|phar|phar.phar|php|php-cgi|php-config|phpdbg|phpize)
        call_php_tool "$@"
        ;;
    composer|composer.phar)
        call_composer_tool "$@"
        ;;
    *)
        echo "Unsupported tool for phpvm: $bin_name"
        exit 1
        ;;
esac
