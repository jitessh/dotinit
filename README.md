# Dotinit - Dotfiles Initializer
Dotinit (`dotinit.sh`) is a simple shell script to initialize your dotfiles. It makes deploying your dotfiles as easy as `sh -c "$(curl -fsSL https://github.com/$user/dotinit/raw/master/dotinit.sh)"`. Once dotinit is set up, you can mirror your setup anywhere with this simple command.


# Getting started
To use `dotinit.sh` to bootstrap your dotfiles:
- Fork this repository.
- Copy `initrc.csv` to your dotfiles repository.

    **NOTE:** You can also use `initrc.csv` from your forked dotinit repository itself, though it is recommended to use it from your dotfiles repository, so that you can fetch new commits from this repository more easily without getting merge conflicts.
- Edit the following variables in your forked `dotinit.sh`:
    - `$BACKUP_DIR`: Path to directory where existing files (if any) will be backed up.
    - `$DOTFILES_DIR`: Path to your local dotfiles directory, from where symlinking will be done.
    - `$DOTFILES_RC`: Path to your local `initrc.csv` file, which will be read to know what files to deploy. Recommended value is `$DOTFILES_DIR/initrc.csv`
    - `$REMOTE_BRANCH`: Branch of your dotfiles repository.
    - `$REMOTE_REPO`: URL of your dotfiles repository, used when the `$DOTFILES_DIR` does not exists, e.g., in a fresh install.
    - `$REMOTE_RC`: URL to your raw `initrc.csv` file, used when the `$DOTFILES_RC` does not exists for any reasons.

You can also use dotinit in a traditional way, i.e, calling `./dotinit.sh` from your terminal (or simply `dotinit.sh` if it is in your `$PATH`).


# initrc.csv
`initrc.csv` is a "config" file for dotinit. It contains comma seperated list of two values:
- first value corresponds to `$link`, the path where the link will be created.
- second value corresponds to `$target`, which is the path of same file as from root of your dotfiles repository.

**NOTE:**
- The first line of `initrc.csv` is disregarded and will not be used while symlinking.
- Shell variables are not expanded in `initrc.csv`. Only `~` is replaced with `$HOME` and no other variables like `$XDG_CONFIG_HOME` will work.

Sample [initrc.csv](initrc.csv):
```csv
DEPLOY PATH, PATH FROM DOTFILES REPO
~/.vimrc,vimrc
~/.tmux.conf,tmux.conf
~/.config/nvim,config/nvim
```


# Usage
`dotinit.sh` has the following flags:
- `-h`: print help and exit.
- `-v`: print version and exit.
- `-b`: path to `$BACKUP_DIR`.
- `-c`: URL or path to `initrc.csv` file; sets either `$REMOTE_RC` or `$DOTFILES_RC`.
- `-d`: URL or path to dotfiles repository; sets either `$REMOTE_REPO` or `$DOTFILES_DIR`.

## Example usage
- In a fresh system install (`$DOTFILES_DIR` need not exist, `$REMOTE_REPO` will be cloned and deployed):
```bash
sh -c "$(curl -fsSL https://github.com/pixxel8/dotinit/raw/master/dotinit.sh)"
```
- When you add new file in dotfiles repository (uses all the variables set in `dotinit.sh`):
```bash
dotinit.sh
```
- Deploy and backup to specific directory:
```bash
dotinit.sh -b ~/.cache/dotfile-backup
```
- Deploy from specific remote repository:
```bash
dotinit.sh -d https://github.com/pixxel8/dotfiles -b ~/.cache/dotfile-backup
```

# License
Copyright (c) 2021 Jitesh. Released under the GPLv3 License. See [LICENSE](LICENSE) for details.
