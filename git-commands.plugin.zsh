#!/usr/bin/env zsh
# ----------------------------------------
# Git / GHQ helper tools (fzf + preview)
# ----------------------------------------

# ==========
# 現在のブランチ名
# ==========
git-current-branch() {
    git symbolic-ref --short HEAD 2>/dev/null
}

# ==========
# Git log からハッシュ選択
# ==========
git-select-hash() {
    git log --oneline --decorate=short --color --branches \
        | fzf-tmux -p 80% \
            --prompt="GIT HASH > " \
            --preview 'git show --color=always {1}' \
            --preview-window=right:70% \
        | awk '{print $1}'
}

# ==========
# 修正ファイルの選択
# ==========
git-select-modified() {
    git status --short \
        | fzf-tmux -p 80% \
            --prompt="MODIFIED FILE > " --nth=2.. \
            --preview '[[ -f $(echo {} | awk "{print \$2}") ]] && bat --style=plain --color=always $(echo {} | awk "{print \$2}")' \
            --preview-window=right:70% \
        | awk '{print $2}'
}

# ==========
# master から変更のあるファイルを選択
# ==========
git-select-changed() {
    local BRANCH=$(git-current-branch)
    git diff --name-only master..."${BRANCH}" \
        | fzf-tmux -p 80% \
            --prompt="CHANGED FILE > " \
            --preview '[[ -f {} ]] && bat --style=plain --color=always {}' \
            --preview-window=right:70%
}

# ==========
# ブランチ選択
# ==========
git-select-branch() {
    git branch \
        | fzf-tmux -p 80% \
            --prompt="GIT BRANCH > " \
            --preview 'git log --oneline --decorate=short --color=always {1}' \
            --preview-window=right:70%
        | head -n 3 | sed -e "s/^\*\s*//g"
}

# ==========
# GHQ: リポジトリ選択 → cd まで自動
# fzf キャンセル時は安全に return
# ==========
git-goto-repository() {
    local repo root_path

    repo=$(ghq list --unique "$@" \
        | fzf-tmux -p 80% \
            --prompt="REPOSITORY > " \
            --preview 'ghq list --full-path -e {} | xargs -I{} ls -1 {} | head -n 200' \
            --preview-window=right:70%)

    # キャンセル対応
    if [[ -z "$repo" ]]; then
        echo "Canceled."
        return 1
    fi

    root_path=$(ghq list --full-path -e "$repo")
    if [[ -z "$root_path" ]]; then
        echo "Path not found: $repo"
        return 1
    fi

    echo "cd $root_path"
    cd "$root_path"
}

# ==========
# gh + repos (alias の代わりに関数で安全に)
# ==========
repos() { git-goto-repository "$@"; }


# ==========
# GH CLI PR / ISSUE 選択
# ==========
gh-select-pr() {
    gh pr list \
        | fzf-tmux -p --prompt="PR > " \
            --preview 'gh pr view $(echo {} | cut -f1) --color=always' \
            --preview-window=right:70% \
        | head -n 1 | cut -f1
}

gh-select-issue() {
    gh issue list \
        | fzf-tmux -p --prompt="ISSUE > " \
            --preview 'gh issue view $(echo {} | cut -f1) --color=always' \
            --preview-window=right:70% \
        | head -n 1 | cut -f1
}

# ==========
# 補助 alias（グローバル alias は状況に応じて）
# ==========
alias -g HASH='$(git-select-hash)'
alias -g MODIFIED='$(git-select-modified)'
alias -g CHANGED='$(git-select-changed)'
alias -g BRANCH='$(git-select-branch)'
alias -g PR='$(gh-select-pr)'
alias -g ISSUE='$(gh-select-issue)'

