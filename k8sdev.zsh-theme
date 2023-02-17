# oh-my-zsh k8s-developer Theme
# FROM oh-my-zsh Bureau Theme [https://github.com/ohmyzsh/ohmyzsh/blob/master/themes/bureau.zsh-theme]

### Git [±master ▾●]

ZSH_THEME_GIT_PROMPT_PREFIX="$fg_bold[green]±$reset_color$fg_bold[white]"
ZSH_THEME_GIT_PROMPT_SUFFIX="$reset_color"
ZSH_THEME_GIT_PROMPT_CLEAN="$fg_bold[green]✓$reset_color"
ZSH_THEME_GIT_PROMPT_AHEAD="$fg[cyan]▴$reset_color"
ZSH_THEME_GIT_PROMPT_BEHIND="$fg[magenta]▾$reset_color"
ZSH_THEME_GIT_PROMPT_STAGED="$fg_bold[green]●$reset_color"
ZSH_THEME_GIT_PROMPT_UNSTAGED="$fg_bold[yellow]●$reset_color"
ZSH_THEME_GIT_PROMPT_UNTRACKED="$fg_bold[red]●$reset_color"

ZSH_THEME_GIT_PROMPT_TEAM_PREFIX="$fg_bold[blue]"
ZSH_THEME_GIT_PROMPT_K8S_CONTEXT_PREFIX="$fg_bold[red]"

function git_team_status() {
  local team=$(git team|tr \\n \ |cut -d \  -f 2-|sed 's/<.*>//g')
  if [[ $team == "git-team disabled" ]]; then
    echo ""
  else
    echo -n $ZSH_THEME_GIT_PROMPT_TEAM_PREFIX\(${team:22}\)$reset_color
  fi
}

function k8s_context() {
  echo -n $ZSH_THEME_GIT_PROMPT_K8S_CONTEXT_PREFIX$(kubectl config current-context)$reset_color
}


mhus_git_info () {
  local ref
  ref=$(command git symbolic-ref HEAD 2> /dev/null) || \
  ref=$(command git rev-parse --short HEAD 2> /dev/null) || return
  echo "${ref#refs/heads/}"
}

mhus_git_status() {
  local result gitstatus
  gitstatus="$(command git status --porcelain -b 2>/dev/null)"

  # check status of files
  local gitfiles="$(tail -n +2 <<< "$gitstatus")"
  if [[ -n "$gitfiles" ]]; then
    if [[ "$gitfiles" =~ $'(^|\n)[AMRD]. ' ]]; then
      result+="$ZSH_THEME_GIT_PROMPT_STAGED"
    fi
    if [[ "$gitfiles" =~ $'(^|\n).[MTD] ' ]]; then
      result+="$ZSH_THEME_GIT_PROMPT_UNSTAGED"
    fi
    if [[ "$gitfiles" =~ $'(^|\n)\\?\\? ' ]]; then
      result+="$ZSH_THEME_GIT_PROMPT_UNTRACKED"
    fi
    if [[ "$gitfiles" =~ $'(^|\n)UU ' ]]; then
      result+="$ZSH_THEME_GIT_PROMPT_UNMERGED"
    fi
  else
    result+="$ZSH_THEME_GIT_PROMPT_CLEAN"
  fi

  # check status of local repository
  local gitbranch="$(head -n 1 <<< "$gitstatus")"
  if [[ "$gitbranch" =~ '^## .*ahead' ]]; then
    result+="$ZSH_THEME_GIT_PROMPT_AHEAD"
  fi
  if [[ "$gitbranch" =~ '^## .*behind' ]]; then
    result+="$ZSH_THEME_GIT_PROMPT_BEHIND"
  fi
  if [[ "$gitbranch" =~ '^## .*diverged' ]]; then
    result+="$ZSH_THEME_GIT_PROMPT_DIVERGED"
  fi

  # check if there are stashed changes
  if command git rev-parse --verify refs/stash &> /dev/null; then
    result+="$ZSH_THEME_GIT_PROMPT_STASHED"
  fi

  echo $result
}

mhus_git_prompt() {
  # check git information
  local gitinfo=$(mhus_git_info)$(git_team_status)

  # quote % in git information
  local output="${gitinfo}"

  # check git status
  local gitstatus=$(mhus_git_status)
  if [[ -n "$gitstatus" ]]; then
    output+=" $gitstatus"
  fi

  echo "${ZSH_THEME_GIT_PROMPT_PREFIX}${output}${ZSH_THEME_GIT_PROMPT_SUFFIX}"
}

mhus_date() {
  date +%H:%M\ %d.%m.%Y
}

if [[ $EUID -eq 0 ]]; then
  _USERNAME="%{$fg_bold[red]%}%n"
  _LIBERTY="%{$fg[red]%}#"
else
  _USERNAME="%{$fg_bold[blue]%}%n"
  _LIBERTY="%{$fg[green]%}$"
fi
_USERNAME="$_USERNAME@%m%{$reset_color%}"
_LIBERTY="$_LIBERTY%{$reset_color%}"

mhus_precmd () {
print -rP $fg_bold[blue]┏$(printf '━%.0s' {1..$((COLUMNS-3))})┓$reset_color
if [[ "$(mhus_git_info)" ]]; then
  print -rP $fg_bold[blue]┃$reset_color GIT: $(mhus_git_prompt|cut -c-$((COLUMNS)))
fi
print -rP $fg_bold[blue]┃$reset_color K8S: $(k8s_context|cut -c-$((COLUMNS)))
print -rP $fg_bold[blue]┃ $(echo \[$(mhus_date)\] $_USERNAME $(PWD)|cut -c-$((COLUMNS+7)))
}

setopt prompt_subst
#PROMPT='> $_LIBERTY '
#RPROMPT='$(nvm_prompt_info) $(mhus_git_prompt) $(k8s_context)'
RPROMPT=""
PROMPT="$fg_bold[blue]┗$reset_color $_LIBERTY "

autoload -U add-zsh-hook
add-zsh-hook precmd mhus_precmd