

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
    git log --oneline --branches | fzy -l 24 -p "GIT HASH > " | awk '{print $1}'
}
alias -g HASH='$(git-select-hash)'

#####
# get modified file
function git-select-modified()
{
    git status --short | fzy -l 24 -p "GIT MODIFIED FILE > " | awk '{print $2}'
}
alias -g MODIFIED='$(git-select-modified)'

#####
# get file changed from master
function git-select-changed()
{
    local BRANCH=$(git-current-branch)
    git diff --name-only master...${BRANCH} | fzy -l 24 -p "GIT CHANGED FILE > "
}
alias -g CHANGED='$(git-select-changed)'

#####
# get branch name
function git-select-branch()
{
    git branch | fzy -l 24 -p "GIT BRANCH > " | head -n 3 | sed -e "s/^\*\s*//g"
}
alias -g BRANCH='$(git-select-branch)'

#####
# for ghq
alias repos='cd `ghq root`/`ghq list | fzy -l 24 -p "GIT REPOSITORY > "`'
