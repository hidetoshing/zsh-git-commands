
#####
# get current branch
function git-current-branch()
{
    git rev-parse --abbrev-ref HEAD
}

#####
# get hash code from git log
function git-select-hash()
{
    git log --oneline --branches | fzf-tmux -p --prompt="GIT HASH > " | awk '{print $1}'
}
alias -g HASH='$(git-select-hash)'

#####
# get modified file
function git-select-modified()
{
    git status --short | fzf-tmux -p --prompt="GIT MODIFIED FILE > " | awk '{print $2}'
}
alias -g MODIFIED='$(git-select-modified)'

#####
# get file changed from master
function git-select-changed()
{
    local BRANCH=$(git-current-branch)
    git diff --name-only master...${BRANCH} | fzf-tmux -p --prompt="GIT CHANGED FILE > "
}
alias -g CHANGED='$(git-select-changed)'

#####
# get branch name
function git-select-branch()
{
    git branch | fzf-tmux -p --prompt="GIT BRANCH > " | head -n 3 | sed -e "s/^\*\s*//g"
}
alias -g BRANCH='$(git-select-branch)'

#####
# for ghq
function repos --description 'cd ghq repository'
{
    if [ $# != 1 ]; then
        cd $(ghq list --full-path | fzf-tmux -p -1 --prompt="GIT REPOSITORY > ")
    else
        cd $(ghq list --full-path | fzf-tmux -p -1 --prompt="GIT REPOSITORY > " -q"${@}")
    fi
}

#####
# for gh
function fzf_git_issue
  set -l query (commandline --current-buffer)
  if test -n $query
    set fzf_query --query "$query"
  end

  set -l base_command gh issue list --limit 100
  set -l bind_commands "ctrl-a:reload($base_command --state all)"
  set bind_commands $bind_commands "ctrl-o:reload($base_command --state open)"
  set bind_commands $bind_commands "ctrl-c:reload($base_command --state closed)"
  set -l bind_str (string join ',' $bind_commands)

  set -l out ( \
    command $base_command | \
    fzf-tmux -p $fzf_query \
        --prompt='Open issue list >' \
        --preview "gh issue view {1}" \
        --bind $bind_str \
        --header='C-a: all, C-o: open, C-c: closed' \
  )
  if test -z $out
    return
  end
  set -l issue_id (echo $out | awk '{ print $1 }')
  commandline "gh issue view -w $issue_id"
  commandline -f execute
end

function fzf_git_pull_request
  set -l query (commandline --current-buffer)
  if test -n $query
    set fzf_query --query "$query"
  end

  set -l base_command gh pr list --limit 100
  set -l bind_commands "ctrl-a:reload($base_command --state all)"
  set bind_commands $bind_commands "ctrl-o:reload($base_command --state open)"
  set bind_commands $bind_commands "ctrl-c:reload($base_command --state closed)"
  set bind_commands $bind_commands "ctrl-g:reload($base_command --state merged)"
  set bind_commands $bind_commands "ctrl-a:reload($base_command --state all)"
  set -l bind_str (string join ',' $bind_commands)

  set -l out ( \
    command $base_command | \
    fzf-tmux -p $fzf_query \
        --prompt='Select Pull Request>' \
        --preview="gh pr view {1}" \
        --expect=ctrl-k,ctrl-m \
        --header='enter: open in browser, C-k: checkout, C-a: all, C-o: open, C-c: closed, C-g: merged, C-a: all' \
  )
  if test -z $out
    return
  end
  set -l pr_id (echo $out[2] | awk '{ print $1 }')
  if test $out[1] = 'ctrl-k'
    commandline "gh pr checkout $pr_id"
    commandline -f execute
  else if test $out[1] = 'ctrl-m'
    commandline "gh pr view --web $pr_id"
    commandline -f execute
  end
end

function gst --description 'git status -s'
  if ! is_git_dir
    return
  end
  set -l base_command git status -s
  set -l bind_reload "reload($base_command)"
  set -l bind_commands "ctrl-a:execute-silent(git add {2})+$bind_reload"
  set bind_commands $bind_commands "ctrl-u:execute-silent(git restore --staged {2})+$bind_reload"
  set -l bind_str (string join ',' $bind_commands)

  set -l out (command $base_command | \
    fzf-tmux -p --preview="git diff {2}" \
        --expect=ctrl-m,ctrl-r,ctrl-v,ctrl-c \
        --bind $bind_str \
        --header='C-a: add, C-u: unstage, C-c: commit, C-m(Enter): mv, C-r: rm, C-v: edit' \
  )
  [ $status != 0 ]; and commandline -f repaint; and return

  if string length -q -- $out
    set -l key $out[1]
    set -l file (echo $out[2] | awk -F ' ' '{ print $NF }')

    if test $key = 'ctrl-m'
      commandline -f repaint
      commandline "git mv $file "
    else if test $key = 'ctrl-r'
      commandline "git rm $file "
      commandline -f execute
    else if test $key = 'ctrl-v'
      commandline "$EDITOR $file"
      commandline -f execute
    else if test $key = 'ctrl-c'
      commandline "git commit -v"
      commandline -f execute
    else
      commandline -f repaint
    end
  end
end

alias -g PR='$(gh pr list | fzf-tmux -p | head -n 1 | cut -f1)'
alias -g ISSUE='$(gh issue list | fzf-tmux -p | head -n 1 | cut -f1)'

