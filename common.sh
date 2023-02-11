function verbose() {
    if [ ${VERBOSE} = "YES" ]; then
        eval "$1"
    else
        eval "$1 &> /dev/null"
    fi
}

function wait_jobs_finish() {
    wait $(jobs -p)
}

function echo_blue_dot() {
	>&2 echo -n -e "\x1B[90m\x1B[39m\x1B[1m\x1B[34m.\x1B[0m\x1B[39m"
}

function echo_blue_dot_title() {
	# echo message in blue and bold
	>&2 echo -n -e "\x1B[90m= \x1B[39m\x1B[1m\x1B[34m$1\x1B[0m\x1B[39m"
}

function echo_blue_bold() {
	# echo message in blue and bold
	>&2 echo -e "\x1B[90m= \x1B[39m\x1B[1m\x1B[34m$1\x1B[0m\x1B[39m"
}

function echo_title() {
	# echo message in blue and bold
    echo_line
	echo_blue_bold "$1"
    echo_line
}

function echo_grey() {
	# echo message in light grey
	>&2 echo -e "\x1B[90m$1\x1B[39m"
}

function echo_red() {
	# echo message in red
	>&2 echo -e "\x1B[31m$1\x1B[39m"
}

function echo_red_bold() {
	# echo message in blue and bold
	>&2 echo -e "\x1B[90m= \x1B[31m\x1B[1m\x1B[31m$1\x1B[0m\x1B[39m"
}

function echo_separator() {
    echo_line
	>&2 echo
	>&2 echo
}

function echo_line() {
	echo_grey "============================================================================================================================="
}

if [ "$(uname -s)" == "Darwin" ]; then

    if [ -z "$(command -v gsed)" ]; then
        echo_red_bold "You must install gnu sed with brew (brew install gsed), this script is not compatible with the native macos sed"
        exit 1
    fi

    if [ -z "$(command -v gbase64)" ]; then
        echo_red_bold "You must install gnu base64 with brew (brew install coreutils), this script is not compatible with the native macos base64"
        exit 1
    fi

    if [ -d /opt/homebrew/opt ]; then
        if [ ! -e /opt/homebrew/opt/gnu-getopt/bin/getopt ]; then
            echo_red_bold "You must install gnu gnu-getopt with brew (brew install gnu-getopt), this script is not compatible with the native macos getopt"
            exit 1
        fi
        GETOPT=/opt/homebrew/opt/gnu-getopt/bin/getopt
    else
        if [ ! -e /usr/local/opt/gnu-getopt/bin/getopt ]; then
            echo_red_bold "You must install gnu gnu-getopt with brew (brew install gnu-getopt), this script is not compatible with the native macos getopt"
            exit 1
        fi
        GETOPT=/usr/local/opt/gnu-getopt/bin/getopt
    fi

    shopt -s expand_aliases

    alias base64=gbase64
    alias sed=gsed
    alias getopt=$GETOPT
fi
