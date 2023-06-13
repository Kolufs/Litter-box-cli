#!/bin/bash


set -eu

usage() {
    cat << EOF
Usage: $0 [options] <file>

Options:
  -t <time>      Set time for file to expire (default: 1h | valid: 1h|12h|24h|72h).

EOF
}

MAX_UPLOAD_SIZE=1073741824   

set_command() {
    _CURL=$(command -v curl)
    _TAR=$(command -v tar)
}

upload() {
    $_CURL -sSL https://litterbox.catbox.moe/resources/internals/api.php \
    -F "fileToUpload=@$1" \
    -F "reqtype=fileupload" \
    -F "time=$2"
}

check_and_compress() {
    if [ -d "$1" ]; then
	local compressed_file=$(mktemp)
	$_TAR czvf  "${compressed_file}" "$1" > /dev/null 
	echo "$compressed_file"
    else
	echo "$1"
    fi
}

check_size() {
    local file_size=$(stat --printf="%s" "$1")
    if ((file_size > MAX_UPLOAD_SIZE)); then
        echo "Error: The file exceeded the maximum allowed size of 1GB."
        exit 2;
    fi
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

    FILE_TO_UPLOAD=$(check_and_compress "$FILE_TO_UPLOAD")
    check_size "$FILE_TO_UPLOAD"
    UPLOAD_LINK=$(upload "$FILE_TO_UPLOAD" "$_EXPIRE_IN")
    echo "File URL: $UPLOAD_LINK"
}

main "$@"

