#!/bin/sh
# Script to initialize your dotfiles
# by Jitesh
# LICENSE: GNU GPLv3
#
# Exit codes
# 0 success
# 1 failed to create backup dir
# 2 dotfiles dir or config file does not exists

# change these variables per your use
BACKUP_DIR="${XDG_CACHE_HOME:=$HOME/.cache}/dotfiles-$(date +%y%m%d-%H%M%S)"    # path to backup dir
DOTFILES_DIR="$HOME/opt/dotfiles"                                               # path to local repo
DOTFILES_RC="$DOTFILES_DIR/initrc.csv"                                          # path to local rc file
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

error() {
    printf "%b==> ERROR%b       : %s\n" "$c_red" "$c_reset" "$1"
}

# $DOTFILES_DIR must exist
[ -d "$DOTFILES_DIR" ] || git clone "$REMOTE_REPO" "$DOTFILES_DIR" || \
    { error "Unable to clone '$REMOTE_REPO' to '$DOTFILES_DIR'"; exit 2; }

# $DOTFILES_RC must exist
[ -f "$DOTFILES_RC" ] && cp -Lf "$DOTFILES_RC" "$tmprc" || \
    { printf "%b==>%b Fetching    : %s\n" "$c_yellow" "$c_reset" "$REMOTE_RC"; curl -fsSL "$REMOTE_RC" > "$tmprc" 2>/dev/null; } || \
    { error "Unable to fetch '$REMOTE_RC'"; exit 2; }

# $BACKUP_DIR must exist
mkdir -p "$BACKUP_DIR" && printf "%b==>%b Creating    : %s\n" "$c_yellow" "$c_reset" "$BACKUP_DIR" || \
    { error "Cannot create directory '$BACKUP_DIR'"; exit 1; }

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
            cp -Lr "$link" "$BACKUP_DIR" && rm -rf "$link"
            printf "%b==>%b Backing up  : %s\n" "$c_green" "$c_reset" "$link"
        fi
        ln -s "$target" "$link" 2>/dev/null || { error "Failed to create symbolic link '$target' -> '$link'"; continue; }
        printf "%b==>%b Linked      : %s %b->%b %s\n" "$c_blue" "$c_reset" "$target" "$c_blue" "$c_reset" "$link"
        n=$((n+1))
    else
        error "No such file or directory '$target'"
    fi
done < "$tmprc"

rm -f "$tmprc"
printf "%b==>%b [%s/%s] dotfiles initialized\n" "$c_magenta" "$c_reset" "$n" "$total" && exit 0
