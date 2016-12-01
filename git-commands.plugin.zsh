

#####
# get hash code from git log
function git-select-hash()
{
    git log --oneline --branches | fzy --prompt "GIT HASH > " | awk '{print $1}'
}
alias -g HASH='$(git-select-hash)'

#####
# get modified file
function git-select-modified()
{
    git status --short | fzy --prompt "GIT MODIFIED FILE > " | awk '{print $2}'
}
alias -g MODIFIES='$(git-select-modified)'

#####
# get file changed from master
function git-select-changed()
{
    BRANCH=${1:-`git rev-parse --abbrev-ref HEAD`}
    git diff --name-only master...${BRANCH} | fzy --prompt "GIT CHANGED FILE > "
}
alias -g CHANGED='$(git-select-changed)'

#####
# get branch name
function git-select-branch()
{
    git branch | fzy --prompt "GIT BRANCH > " | head -n 3 | sed -e "s/^\*\s*//g"
}
alias -g BRANCH='$(git-select-branch)'

