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
# デフォルトブランチ名
# ==========
git-default-branch() {
    local branch

    branch=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)
    if [[ -n "$branch" ]]; then
        echo "${branch#origin/}"
        return 0
    fi

    for branch in main master; do
        if git show-ref --verify --quiet "refs/heads/$branch" \
            || git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
            echo "$branch"
            return 0
        fi
    done

    return 1
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
            --preview 'path=$(printf "%s\n" "{}" | sed -E "s/^.. //; s#^.* -> ##") && [[ -n "$path" ]] && git diff --color=always -- "$path"' \
            --preview-window=right:70% \
        | sed -E 's/^.. //; s#^.* -> ##'
}

# ==========
# デフォルトブランチから変更のあるファイルを選択
# ==========
git-select-changed() {
    local BRANCH BASE_BRANCH

    BRANCH=$(git-current-branch)
    BASE_BRANCH=$(git-default-branch) || return 1

    git diff --name-only "${BASE_BRANCH}"..."${BRANCH}" \
        | fzf-tmux -p 80% \
            --prompt="CHANGED FILE > " \
            --preview "git diff --color=always ${BASE_BRANCH}...${BRANCH} -- \"{}\"" \
            --preview-window=right:70%
}

# ==========
# ブランチ選択
# ==========
git-select-branch() {
    git branch \
        | fzf-tmux -p 80% \
            --prompt="GIT BRANCH > " \
            --preview 'branch=$(printf "%s\n" "{}" | sed -E "s/^[*[:space:]]+//") && [[ -n "$branch" ]] && { echo "[Only in $branch]"; git log --graph --oneline --decorate=short --color=always HEAD.."$branch"; echo; echo "[Only in HEAD]"; git log --graph --oneline --decorate=short --color=always "$branch"..HEAD; }' \
            --preview-window=right:70% \
        | sed -E 's/^[*[:space:]]+//'
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
            --preview 'root_path=$(ghq list --full-path -e {}) && [[ -n "$root_path" ]] && eza --tree --level=3 --color=always --group-directories-first "$root_path" | head -n 200' \
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
# Git リポジトリ root へ移動
# リポジトリ外では ghq 選択へフォールバック
# ==========
git-cd-root() {
    local root_path

    root_path=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ -n "$root_path" ]]; then
        echo "cd $root_path"
        cd "$root_path"
        return 0
    fi

    git-goto-repository "$@"
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
            --preview 'num=$(printf "%s\n" "{}" | cut -f1) && gh pr view "$num" --json number,title,author,isDraft,reviewDecision,mergeStateStatus,statusCheckRollup,files --template "{{printf \"PR #%v %s\nAuthor: %s\nDraft: %v\nReview: %s\nMerge: %s\nChecks: %d\nFiles:\n\" .number .title .author.login .isDraft .reviewDecision .mergeStateStatus (len .statusCheckRollup)}}{{range .files}}{{printf \"  - %s\n\" .path}}{{end}}" | head -n 40' \
            --preview-window=right:70% \
        | head -n 1 | cut -f1
}

gh-select-issue() {
    gh issue list \
        | fzf-tmux -p --prompt="ISSUE > " \
            --preview 'num=$(printf "%s\n" "{}" | cut -f1) && gh issue view "$num" --json number,title,state,author,labels,assignees,comments --template "{{printf \"Issue #%v %s\nState: %s\nAuthor: %s\nLabels: \" .number .title .state .author.login}}{{if .labels}}{{range $i, $label := .labels}}{{if $i}}, {{end}}{{printf \"%s\" $label.name}}{{end}}{{else}}-{{end}}{{printf \"\nAssignees: \"}}{{if .assignees}}{{range $i, $assignee := .assignees}}{{if $i}}, {{end}}{{printf \"%s\" $assignee.login}}{{end}}{{else}}-{{end}}{{printf \"\nComments: %d\n\" (len .comments)}}" | head -n 20' \
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
