#!/bin/sh
# Script to initialize your dotfiles
# by Jitesh
# LICENSE: GNU GPLv3
#
# Exit codes
# 0 success
# 1 invalid flag
# 2 dotfiles dir or config file does not exists
# 3 failed to create backup dir

VERSION="0.3"

# change these variables per your use
BACKUP_DIR="${XDG_CACHE_HOME:=$HOME/.cache}/dotfiles-$(date +%y%m%d-%H%M%S)"    # path to backup dir
DOTFILES_DIR="$HOME/opt/dotfiles"                                               # path to local repo
DOTFILES_RC="$DOTFILES_DIR/initrc.csv"                                          # path to local rc file
CLONE_DIR="$DOTFILES_DIR"                                                       # used when URL is passed to -d option
REMOTE_BRANCH="master"                                                          # branch of remote repo
REMOTE_REPO="https://github.com/voidstarsh/dotfiles"                            # URL of remote repo
REMOTE_RC="$REMOTE_REPO/raw/$REMOTE_BRANCH/initrc.csv"                          # URL of remote rc file
tmprc="/tmp/initrc.csv"                                                         # temp initrc.csv

# pretty output
c_reset="\033[0m"
c_red="\033[1;31m"
c_green="\033[1;32m"
c_yellow="\033[1;33m"
c_blue="\033[1;34m"
c_magenta="\033[1;35m"
c_cyan="\033[1;36m"

print_error() {
    printf "%b==> ERROR%b       : %s\n" "$c_red" "$c_reset" "$1"
}

print_help() {
    printf "Usage: dotinit.sh [OPTIONS]\n"
    printf "OPTIONS:\n"
    printf "  -h\t\t show this help and exit\n"
    printf "  -v\t\t print version and exit\n"
    printf "  -b\t\t backup directory\n"
    printf "  -c\t\t URL or path to initrc.csv file\n"
    printf "  -d\t\t URL or path to dotfiles repository\n"
}

print_version() {
    printf "dotinit-v%s\n" "$VERSION"
}

assign_value() {
    if [ "$2" == "rc" ]; then
        if echo "$1" | grep -iqE "^https://"; then
            REMOTE_RC="$1"              # $REMOTE_RC will be downloaded to $temprc
            DOTFILES_RC=""              # emptying this so that $REMOTE_RC will be fetched later
        else
            DOTFILES_RC="$(readlink -e $1)"
            [ -f "$DOTFILES_RC" ] || { print_error "$1 file does not exists"; exit 2; }
            # REMOTE_RC=""                # don't use $REMOTE_RC since $DOTFILES_RC is explicitly set
        fi
    elif [ "$2" == "df" ]; then
        if echo "$1" | grep -iqE "^https://"; then
            REMOTE_REPO="$1"            # $REMOTE_REPO will be cloned at $DOTFILES_DIR
            DOTFILES_DIR=""             # emptying this so that $REMOTE_REPO will be cloned later
        else
            DOTFILES_DIR="$(readlink -e $1)"
            [ -d "$DOTFILES_DIR" ] || { print_error "$1 directory does not exists"; exit 2; }
            # REMOTE_REPO=""              # don't use $REMOTE_REPO since $DOTFILES_DIR is explicitly set
        fi
    fi
}

while getopts "b:c:d:hv" opt; do
    case "${opt}" in
        h)  print_help; exit 0 ;;
        v)  print_version; exit 0 ;;
        b)  BACKUP_DIR="${OPTARG}" ;;
        c)  assign_value "${OPTARG}" "rc" ;;
        d)  assign_value "${OPTARG}" "df" ;;
        *)  printf "Invalid option\n" && exit 1 ;;
    esac
done

# $DOTFILES_DIR must exist
[ -d "$DOTFILES_DIR" ] || git clone "$REMOTE_REPO" "${DOTFILES_DIR:=$CLONE_DIR}" || \
    { print_error "Unable to clone '$REMOTE_REPO' to '$DOTFILES_DIR'"; exit 2; }

# $DOTFILES_RC must exist
[ -f "$DOTFILES_RC" ] && cp -Lf "$DOTFILES_RC" "$tmprc" || \
    { printf "%b==>%b Fetching    : %s\n" "$c_yellow" "$c_reset" "$REMOTE_RC"; curl -fsSL "$REMOTE_RC" > "$tmprc" 2>/dev/null; } || \
    { print_error "Unable to fetch '$REMOTE_RC'"; exit 2; }

# $BACKUP_DIR must exist
mkdir -p "$BACKUP_DIR" && printf "%b==>%b Creating    : %s\n" "$c_yellow" "$c_reset" "$BACKUP_DIR" || \
    { print_error "Cannot create directory '$BACKUP_DIR'"; exit 3; }

# remove the 1st line (header) from $tmprc
tail -n +2 "$tmprc" > "$tmprc.tmp" && mv -f "$tmprc.tmp" "$tmprc"
n=0
total="$(wc -l < $tmprc)"

while IFS=, read -r link target; do
    target="$DOTFILES_DIR/$target"
    link="$(echo "$link" | sed "s:~:$HOME:g")"

    # check if $target exists in $DOTFILES_DIR
    if [ -f "$target" ] || [ -d "$target" ]; then
        # backup existing $link file to $BACKUP_DIR
        if [ -f "$link" ] || [ -d "$link" ]; then
            printf "%b==>%b Backing up  : %s\n" "$c_green" "$c_reset" "$link"
            cp -Lr "$link" "$BACKUP_DIR"
        fi
        rm -rf "$link"
        ln -s "$target" "$link" 2>/dev/null || { print_error "Failed to create symbolic link '$target' -> '$link'"; continue; }
        printf "%b==>%b Linked      : %s %b->%b %s\n" "$c_blue" "$c_reset" "$target" "$c_blue" "$c_reset" "$link"
        n=$((n+1))
    else
        print_error "No such file or directory '$target'"
    fi
done < "$tmprc"

rm -f "$tmprc"
printf "%b==>%b [%s/%s] dotfiles initialized\n" "$c_magenta" "$c_reset" "$n" "$total" && exit 0
