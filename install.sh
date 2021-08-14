#!/bin/sh
# script to deploy dotfiles
# by Jitesh
# LICENSE: GNU GPLv3
#
# exit codes
# 0 success
# 1 failed to create backup dir
# 2 dotfiles dir or config file does not exists

# change these variables for your use
backupdir="${XDG_CACHE_HOME:=$HOME/.cache}/dotfiles-$(date +%y%m%d-%H%M%S)" # path to backup dir
dotfilesdir="$HOME/opt/dotfiles"                                            # path to local repo
configfile="$dotfilesdir/installrc.csv"                                     # path to local config file
remoterepo="https://github.com/voidstarsh/dotfiles"                         # URL of remote repo
remoteconf="$remoterepo/raw/main/installrc.csv"                             # URL of remote config file
tmpconf="/tmp/installrc.csv"                                                # copy of config file will be used

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

# making sure the dotfiles dir, config file, & the backup dir exists
[ -d "$dotfilesdir" ] || git clone "$remoterepo" "$dotfilesdir" || \
    { error "Unable to clone '$remoterepo' to '$dotfilesdir'"; exit 2; }
[ -f "$configfile" ] && cp -f "$configfile" "$tmpconf" || curl -fsSL "$remoteconf" > "$tmpconf" 2>/dev/null || \
    { error "Unable to fetch '$remoteconf'"; exit 2; }
mkdir -p "$backupdir" && printf "%b==>%b Creating backup directory '%s'\n" "$c_yellow" "$c_reset" "$backupdir" || \
    { error "Cannot create directory '$backupdir'"; exit 1; }

# remove the 1st line from installrc.csv
tail -n +2 "$tmpconf" > "$tmpconf.tmp" && mv -f "$tmpconf.tmp" "$tmpconf"
total="$(wc -l < $tmpconf)"

while IFS=, read -r link target; do
    target="$dotfilesdir/$target"
    link="$(echo "$link" | sed "s:~:$HOME:g")"

    # check if $target exists in $dotfilesdir
    if [ -f "$target" ] || [ -d "$target" ]; then
        # backup existing $link file to $backupdir
        if [ -f "$link" ] || [ -d "$link" ]; then
            cp -Lr "$link" "$backupdir" && rm -rf "$link"
            printf "%b==>%b Backing up  : %s\n" "$c_green" "$c_reset" "$link"
        fi
        ln -s "$target" "$link" 2>/dev/null || { error "Failed to create symbolic link '$target' -> '$link'"; continue; }
        n=$((n+1)) && printf "%b==>%b Linked      : %s %b->%b %s\n" "$c_blue" "$c_reset" "$target" "$c_blue" "$c_reset" "$link"
    else
        error "No such file or directory '$target'"
    fi
done < "$tmpconf"

rm -f "$tmpconf"
printf "%b==>%b [%s/%s] dotfiles deployed\n" "$c_magenta" "$c_reset" "$n" "$total" && exit 0
