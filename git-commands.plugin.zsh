

#####
# get hash code from git log
function git-hash()
{
    git log --oneline --branches | fzy --prompt "GIT HASH > " | awk '{print $1}'
}
alias -g HASH='$(git-hash)'

#####
# get modified file
function git-modified()
{
    git status --short | fzy --prompt "GIT MODIFIED FILE > " | awk '{print $2}'
}
alias -g MODIFIES='$(git-modified)'

#####
# get file changed from master
function git-changed()
{
    BRANCH=${1:-`git rev-parse --abbrev-ref HEAD`}
    git diff --name-only master...${BRANCH} | fzy --prompt "GIT CHANGED FILE > "
}
alias -g CHANGED='$(git-changed)'

#####
# get branch name
function git-branch()
{
    git branch | fzy --prompt "GIT BRANCH > " | head -n 3 | sed -e "s/^\*\s*//g"
}
alias -g BRANCH='$(git-branch)'

