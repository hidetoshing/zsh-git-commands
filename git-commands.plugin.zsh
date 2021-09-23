
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
### cd ghq project
function ghq-fzf() {
   
    local src=$(ghq list | fzf-tmux -p --preview "bat --color=always --style=header,grid --line-range :80 $(ghq root)/{}/(README|readme).*")
    if [ -n "$src" ]; then
        BUFFER="cd $(ghq root)/$src"
        zle accept-line
    fi
    zle -R -c
}
zle -N ghq-fzf

alias repos='ghq-fzf'

#function repos()
#{
#    if [ $# != 1 ]; then
#        cd $(ghq list --full-path | fzf-tmux -p -1 --prompt="GIT REPOSITORY > ")
#    else
#        cd $(ghq list --full-path | fzf-tmux -p -1 --prompt="GIT REPOSITORY > " -q"${@}")
#    fi
#}

#####
# for gh

alias -g PR='$(gh pr list | fzf-tmux -p | head -n 1 | cut -f1)'
alias -g ISSUE='$(gh issue list | fzf-tmux -p | head -n 1 | cut -f1)'

