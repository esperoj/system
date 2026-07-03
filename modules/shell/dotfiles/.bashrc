#!/bin/bash

# 1. Exit if not interactive
[[ $- == *i* ]] || return

# 2. History - Long-term logs with deduplication
export HISTCONTROL=ignoreboth:erasedups
export HISTSIZE=50000
export HISTFILESIZE=100000
shopt -s histappend checkwinsize

# 3. Clean Aliases
alias ls='ls --color=auto -v'
alias ll='ls -alF'
alias ..='cd ..'
alias q='exit'
alias copy='xclip -selection clipboard 2>/dev/null || xsel -b -i'

# 4. FZF (Auto-load if installed)
[ -f /usr/share/doc/fzf/examples/key-bindings.bash ] && . /usr/share/doc/fzf/examples/key-bindings.bash

# 5. Short, High-Contrast PS1
# Logic: Success=Green, Fail=Red | Identity=Cyan | Path=Yellow
# Cyan and Yellow are much easier to read on black than Dark Blue.
PS1='$(if [ $? -eq 0 ]; then echo "\[\e[32m\]✔"; else echo "\[\e[31m\]✘"; fi) \[\e[36m\]\u\[\e[0m\]:\[\e[33m\]\w\[\e[0m\]\$ '

# 6. Source local profile
[ -f "$HOME/.profile" ] && . "$HOME/.profile"
