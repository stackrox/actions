#!/usr/bin/env bash

# The output appears in a dedicated emphasized GitHub step box.
# Multiple lines are not supported.
# Markdown is not supported.
gh_log() {
    local LEVEL="$1"
    shift
    if [ "$CI" = "false" ]; then
        case "$LEVEL" in
        "debug")
            printf "\e[1;90m"
            ;;
        "error")
            printf "\e[1;31m"
            ;;
        "warning")
            printf "\e[1;33m"
            ;;
        *)
            printf "\e[1;32m"
            ;;
        esac
    fi
    echo "::$LEVEL::$*"
    if [ "$CI" = "false" ]; then printf "\e[0m"; fi
}
export -f gh_log

# Sets a step output value.
# Examples:
#     gh_output name value
#     gh_output name <<EOF
#     value
#     EOF
gh_output() {
    local NAME="$1"
    if [ "$#" -eq 1 ]; then
        echo "$NAME<<END_OF_VALUE"
        cat
        echo "END_OF_VALUE"
    else
        shift
        echo "$NAME=$*"
    fi >>"$GITHUB_OUTPUT"
}
export -f gh_output

check_not_empty() {
    for V in "$@"; do
        typeset -n VAR="$V"
        if [ -z "${VAR:-}" ]; then
            gh_log error "Variable $V is not set or empty"
            exit 1
        fi
    done
}
export -f check_not_empty

check_not_empty GITHUB_STEP_SUMMARY

# The output appears in the GitHub step summary box.
# Multiple lines are supported.
# Markdown is supported.
# Examples:
#     gh_summary "Markdown summary"
#     gh_summary <<EOF
#     Markdown summary
#     EOF
gh_summary() {
    if [ "$CI" = "false" ]; then printf "\e[94m"; fi
    if [ "$#" -eq 0 ]; then
        cat # for the data passed via the pipe
    else
        echo -e "$@" # for the data passed as arguments
    fi >>"$GITHUB_STEP_SUMMARY"
    if [ "$CI" = "false" ]; then printf "\e[0m"; fi
}
export -f gh_summary

# retry() - retry a command up to a specific numer of times until it exits
# successfully, with exponential back off.
# (original source: https://gist.github.com/sj26/88e1c6584397bb7c13bd11108a579746)

retry() {
    if [[ "$#" -lt 3 ]]; then
        echo "usage: retry <try count> <delay true|false> <command> <args...>"
        exit 1
    fi

    local tries=$1
    local delay=$2
    shift; shift;

    local count=0
    until "$@"; do
        exit=$?
        wait=$((2 ** count))
        count=$((count + 1))
        if [[ $count -lt $tries ]]; then
            echo "Retry $count/$tries exited $exit"
            if $delay; then
                echo "Retrying in $wait seconds..."
                sleep $wait
            fi
            if [[ -n "${RETRY_HOOK:-}" ]]; then
                $RETRY_HOOK
            fi
        else
            echo "Retry $count/$tries exited $exit, no more retries left."
            return $exit
        fi
    done
    return 0
}
export -f retry

# bash trick to check if the script is sourced.
if ! (return 0 2>/dev/null); then # called
    SCRIPT="$1"
    check_not_empty \
        SCRIPT

    shift
    gh_log debug "Executing '$SCRIPT' with: ${*@Q}"
    "$SCRIPT" "$@"
fi
