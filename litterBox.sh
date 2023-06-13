#!/bin/bash

set -eu

usage() {
    cat << EOF
Usage: $0 [options] <file>

Options:
  -t <time>      Set time for file to expire (default: 1h | valid: 1h|12h|24h|72h).

EOF
}

set_command() {
	_CURL=$(command -v curl)
}

upload() {
    $_CURL -sSL https://litterbox.catbox.moe/resources/internals/api.php \
    -F "fileToUpload=@$1" \
    -F "reqtype=fileupload" \
    -F "time=$2"
}

set_args() {
    _EXPIRE_IN="1h"
    while getopts "t:n:" opt; do
        case $opt in
            t)_EXPIRE_IN="$OPTARG"
                ;;
            \?)
                echo "Invalid option: -$OPTARG" >&2
                usage;
                exit 1;
                ;;
            :)
                echo "Option -$OPTARG requires an argument." >&2
                usage;
                exit 1;
                ;;
            esac
    done;

    shift $((OPTIND-1))
    if [ $# != 1 ]; then
        usage;
        exit 1;
    fi

    FILE_TO_UPLOAD=$1
}

main() {
    set_args "$@"
    set_command

    UPLOAD_LINK=$(upload "$FILE_TO_UPLOAD" "$_EXPIRE_IN")
    echo "File URL: $UPLOAD_LINK"
}

main "$@"
