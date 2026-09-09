# shellcheck shell=bash
# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines in the history. See bash(1) for more options
# ... or force ignoredups and ignorespace
HISTCONTROL=ignoredups:ignorespace

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=2000
HISTFILESIZE=20000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features
# /usr/share/bash-completion/bash_completion works on both Fedora and Ubuntu;
# /etc/bash_completion is a Debian/Ubuntu-only shim that sources the same file.
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# git completion (sourced explicitly in case the framework skips lazy-loading)
[ -f /usr/share/bash-completion/completions/git ] && . /usr/share/bash-completion/completions/git
parse_git_branch() {
  local branch
  branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null) || \
    branch=$(git rev-parse --short HEAD 2>/dev/null) || return
  printf '(%s)' "$branch"
}
PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;35m\]\w\[\033[01;31m\]$(parse_git_branch)\[\033[00m\]\$ '

if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate bash)"
fi

if [ -x /usr/bin/mise ] && [ ! -e "$HOME/.config/mise/.first-login-shown" ]; then
    mkdir -p "$HOME/.config/mise"
    touch "$HOME/.config/mise/.first-login-shown"
    printf '\n'
    printf '%s\n' 'Welcome to the CDC WSL development environment.'
    printf '%s\n' 'mise is installed system-wide; your tools and configuration belong to your user account.'
    printf '\n'
    printf '%s\n' 'Getting started:'
    printf '%s\n' '  mise install                 Install or retry the default tools'
    printf '%s\n' '  mise list                    Show installed tools'
    printf '%s\n' '  mise upgrade                 Upgrade configured tools'
    printf '%s\n' '  $EDITOR ~/.config/mise/config.toml  Change your tool list or versions'
    printf '\n'
    if [ -t 1 ]; then
        _CDC_BOLD='\033[1m'
        _CDC_CYAN='\033[36m'
        _CDC_GREEN='\033[32m'
        _CDC_RESET='\033[0m'
    else
        _CDC_BOLD=''
        _CDC_CYAN=''
        _CDC_GREEN=''
        _CDC_RESET=''
    fi
    printf '%b\n' "${_CDC_BOLD}${_CDC_CYAN}Major tools available through mise:${_CDC_RESET}"
    printf '%b\n' "  ${_CDC_BOLD}${_CDC_GREEN}Python${_CDC_RESET}  ${_CDC_BOLD}${_CDC_GREEN}Node.js${_CDC_RESET}  ${_CDC_BOLD}${_CDC_GREEN}Go${_CDC_RESET}  ${_CDC_BOLD}${_CDC_GREEN}Java${_CDC_RESET}  ${_CDC_BOLD}${_CDC_GREEN}Rust${_CDC_RESET}"
    printf '%b\n' "  ${_CDC_BOLD}${_CDC_GREEN}AWS CLI${_CDC_RESET}  ${_CDC_BOLD}${_CDC_GREEN}Azure CLI${_CDC_RESET}  ${_CDC_BOLD}${_CDC_GREEN}kubectl${_CDC_RESET}  ${_CDC_BOLD}${_CDC_GREEN}Helm${_CDC_RESET}  ${_CDC_BOLD}${_CDC_GREEN}Terraform${_CDC_RESET}"
    printf '\n'
    printf '%s\n' 'Azure CLI extensions are installed with:'
    printf '%s\n' '  az extension add --name resource-graph'
    printf '\n'
    printf '%b\n' "${_CDC_BOLD}${_CDC_CYAN}Rootless containers:${_CDC_RESET}"
    printf '%s\n' '  podman run --rm quay.io/podman/hello'
    printf '%s\n' '  Podman is configured for your user; sudo is not required.'
    printf '\n'
    printf '%b\n' "${_CDC_BOLD}${_CDC_CYAN}GitHub SSH setup:${_CDC_RESET}"
    printf '%s\n' '  mkdir -p ~/.ssh && chmod 700 ~/.ssh'
    printf '%s\n' '  ssh-keygen -t ed25519 -o -a 100 -C "you@example.com" -f ~/.ssh/github_ed25519'
    printf '%s\n' '  eval "$(ssh-agent -s)" && ssh-add ~/.ssh/github_ed25519'
    printf '%s\n' '  clip.exe < ~/.ssh/github_ed25519.pub'
    printf '%s\n' '  Paste the copied key at https://github.com/settings/keys'
    printf '%s\n' '  ssh -T git@github.com             Test the connection'
    printf '\n'
    printf '%b\n' "${_CDC_BOLD}${_CDC_CYAN}Guides included with this image:${_CDC_RESET}"
    printf '%s\n' '  cat /usr/share/doc/cdc-wsl/first-time-setup.md'
    printf '%s\n' '  cat /usr/share/doc/cdc-wsl/wsl-tricks.md'
    printf '%s\n' '  Git and SSH: https://fartbagxp.github.io/git-and-ssh/'
    printf '\n'
    printf '%s\n' 'Before committing, configure your Git identity:'
    printf '%s\n' '  git config --global user.name "Your Name"'
    printf '%s\n' '  git config --global user.email "you@example.com"'
    printf '\n'
    unset _CDC_BOLD _CDC_CYAN _CDC_GREEN _CDC_RESET
fi
