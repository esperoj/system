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
m() {
  local dir="$PWD"
  while [ -n "$dir" ] && [ "$dir" != "/" ]; do
    if [ -f "$dir/Makefile" ] || [ -f "$dir/makefile" ]; then
      command make -C "$dir" "$@"
      return
    fi
    dir="${dir%/*}"
  done

  # Root directory check
  if [ -f "/Makefile" ] || [ -f "/makefile" ]; then
    command make -C "/" "$@"
    return
  fi

  # Fallback to standard command
  command make "$@"
}
# 4. FZF (Auto-load if installed)
[ -f /usr/share/doc/fzf/examples/key-bindings.bash ] && . /usr/share/doc/fzf/examples/key-bindings.bash

# 5. Fast, Native Bash Git Prompt
ps1_git() {
  local exit_code=$?
  local status_color="\[\e[32m\]✔"
  if [ $exit_code -ne 0 ]; then
    status_color="\[\e[31m\]✘"
  fi

  local git_info=""
  if [[ "$PWD" == "$HOME/projects"* ]]; then
    # Rapid status fetch (0.2s timeout protects against freezing huge monolithic repos)
    local git_status
    git_status=$(timeout 0.2 git status --porcelain 2>/dev/null)
    
    if [ -n "$git_status" ]; then
      local unstaged=0 staged=0
      
      # Process output using pure bash (zero sub-shells)
      while IFS= read -r line; do
        local x="${line:0:1}"
        local y="${line:1:1}"
        
        # Check X column for index changes, Y column for working tree
        [[ "$x" != " " && "$x" != "?" ]] && staged=1
        [[ "$y" != " " || "$x" == "?" ]] && unstaged=1
        
        # Short-circuit if both states are confirmed
        [[ $staged -eq 1 && $unstaged -eq 1 ]] && break
      done <<< "$git_status"

      if [ $unstaged -eq 1 ] && [ $staged -eq 1 ]; then
        git_info=" \[\e[35m\]*\[\e[0m\]"  # Magenta *
      elif [ $unstaged -eq 1 ]; then
        git_info=" \[\e[31m\]*\[\e[0m\]"  # Red *
      elif [ $staged -eq 1 ]; then
        git_info=" \[\e[33m\]*\[\e[0m\]"  # Yellow *
      fi
    fi
  fi

  PS1="${status_color} \[\e[36m\]\w\[\e[0m\]${git_info}\$ "
}

PROMPT_COMMAND=ps1_git
