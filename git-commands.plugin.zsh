#!/usr/bin/env zsh

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
function git-goto-repository()
{
    local repo=$(ghq list --unique ${@} | fzf-tmux -p 80%)
    local path=$(ghq list --full-path -e ${repo})
    cd ${path}
}
alias repos='git-goto-repository'

#####
# for gh

alias -g PR='$(gh pr list | fzf-tmux -p | head -n 1 | cut -f1)'
alias -g ISSUE='$(gh issue list | fzf-tmux -p | head -n 1 | cut -f1)'

