#!/bin/bash

# 1. Exit if not interactive
[[ $- == *i* ]] || return
if [ -f ~/.profile ]; then
    . ~/.profile
fi
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
make() {
  if [[ "$PWD" == "$HOME/projects"* ]]; then
    local root
    root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [ -n "$root" ]; then
      command make -C "$root" "$@"
      return
    fi
  fi
  command make "$@"
}
# 4. FZF (Auto-load if installed)
[ -f /usr/share/doc/fzf/examples/key-bindings.bash ] && . /usr/share/doc/fzf/examples/key-bindings.bash

# 5. Short, High-Contrast PS1
ps1_git() {
  local exit_code=$?
  local status_color="\[\e[32m\]✔"
  if [ $exit_code -ne 0 ]; then
    status_color="\[\e[31m\]✘"
  fi

  local git_info=""
  if [[ "$PWD" == "$HOME/projects"* ]]; then
    local unstaged=0 staged=0

    ! git diff --quiet 2>/dev/null && unstaged=1
    ! git diff --cached --quiet 2>/dev/null && staged=1

    if [ $unstaged -eq 1 ] && [ $staged -eq 1 ]; then
      git_info=" \[\e[35m\]*\[\e[0m\]"  # Magenta * (staged + unstaged)
    elif [ $unstaged -eq 1 ]; then
      git_info=" \[\e[31m\]*\[\e[0m\]"  # Red * (unstaged)
    elif [ $staged -eq 1 ]; then
      git_info=" \[\e[33m\]*\[\e[0m\]"  # Yellow * (staged)
    fi
  fi

  # Directory \w is Cyan (36m), cleanly separated from git_info
  PS1="${status_color} \[\e[36m\]\w\[\e[0m\]${git_info}\$ "
}

PROMPT_COMMAND=ps1_git
