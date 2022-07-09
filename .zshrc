# Path
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="agnoster"
HIST_STAMPS="yyyy-mm-dd"

# Disable marking untracked files under VCS as dirty.
# This makes repository status check for large repositories much, much faster.
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Which plugins would you like to load?
plugins=(git docker)

source $ZSH/oh-my-zsh.sh

# User configuration
export DOCKER_BUILDKIT=1
export CGO_ENABLED=0

# Use bat for man
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# Alias definitions.
alias gsps="git stash && git pull && git stash pop"
alias cat="bat"

# Arch Mirrors update
distro=$(source /etc/os-release; echo $ID)
if [[ $distro == "arch" ]]; then
    alias updm-rate="sudo reflector -a 10 -c pl --sort rate --save /etc/pacman.d/mirrorlist"
    alias updm-score="sudo reflector --latest 50 --number 20 --sort score --save /etc/pacman.d/mirrorlist"
fi