
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
    git log --oneline --branches | fzf --reverse --height=24 --select-1 --prompt="GIT HASH > " | awk '{print $1}'
}
alias -g HASH='$(git-select-hash)'

#####
# get modified file
function git-select-modified()
{
    git status --short | fzf --reverse --height=24 --select-1 --prompt="GIT MODIFIED FILE > " | awk '{print $2}'
}
alias -g MODIFIED='$(git-select-modified)'

#####
# get file changed from master
function git-select-changed()
{
    local BRANCH=$(git-current-branch)
    git diff --name-only master...${BRANCH} | fzf --reverse --height=24 --select-1 --prompt="GIT CHANGED FILE > "
}
alias -g CHANGED='$(git-select-changed)'

#####
# get branch name
function git-select-branch()
{
    git branch | fzf --reverse --height=24 --select-1 --prompt="GIT BRANCH > " | head -n 3 | sed -e "s/^\*\s*//g"
}
alias -g BRANCH='$(git-select-branch)'

#####
# for ghq
function git-goto-repository()
{
    if [ $# != 1 ]; then
        cd $(ghq list --full-path | fzf --reverse --prompt="GIT REPOSITORY > ")
    else
        cd $(ghq list --full-path | fzf --reverse --prompt="GIT REPOSITORY > " -q${1})
    fi
}
alias repos='$(git-goto-repository)'

