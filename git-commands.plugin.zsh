#!/usr/bin/env zsh
# ----------------------------------------
# Git / GHQ helper tools (fzf + preview)
# ----------------------------------------

# ==========
# 外部コマンドの絶対パスを解決
# alias / function に影響されないようにする
# ==========
_git_commands_require() {
    local name cmd_path

    for name in "$@"; do
        cmd_path=${commands[$name]}
        if [[ -z "$cmd_path" ]]; then
            print -u2 -- "zsh-git-commands: required command not found: $name"
            return 1
        fi
    done
}

_git_commands_selector_cmd() {
    local tmux_cmd

    if [[ -n "${TMUX:-}" ]] && [[ -n "${commands[fzf-tmux]}" ]]; then
        tmux_cmd=${commands[tmux]}
        if [[ -n "$tmux_cmd" ]] && "$tmux_cmd" display-message -p '#{session_id}' >/dev/null 2>&1; then
            print -r -- "${commands[fzf-tmux]}"
            return 0
        fi
    fi

    _git_commands_require fzf || return 1
    print -r -- "${commands[fzf]}"
}

# ==========
# 現在のブランチ名
# ==========
git-current-branch() {
    local git_cmd

    _git_commands_require git || return 1
    git_cmd=${commands[git]}

    "$git_cmd" symbolic-ref --short HEAD 2>/dev/null
}

# ==========
# デフォルトブランチ名
# ==========
git-default-branch() {
    local branch git_cmd

    _git_commands_require git || return 1
    git_cmd=${commands[git]}

    branch=$("$git_cmd" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)
    if [[ -n "$branch" ]]; then
        echo "${branch#origin/}"
        return 0
    fi

    for branch in main master; do
        if "$git_cmd" show-ref --verify --quiet "refs/heads/$branch" ||
            "$git_cmd" show-ref --verify --quiet "refs/remotes/origin/$branch"; then
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
    local git_cmd selector_cmd
    local -a selector_args

    _git_commands_require git || return 1
    git_cmd=${commands[git]}
    selector_cmd=$(_git_commands_selector_cmd) || return 1
    selector_args=()
    [[ "$selector_cmd" == */fzf-tmux ]] && selector_args=(-p 80%)

    "$git_cmd" log --oneline --decorate=short --color --branches |
        "$selector_cmd" "${selector_args[@]}" \
            --prompt="GIT HASH > " \
            --preview "${git_cmd} show --color=always {1}" \
            --preview-window=right:70% |
        awk '{print $1}'
}

# ==========
# 修正ファイルの選択
# ==========
git-select-modified() {
    local git_cmd selector_cmd
    local -a selector_args

    _git_commands_require git || return 1
    git_cmd=${commands[git]}
    selector_cmd=$(_git_commands_selector_cmd) || return 1
    selector_args=()
    [[ "$selector_cmd" == */fzf-tmux ]] && selector_args=(-p 80%)

    "$git_cmd" status --short |
        "$selector_cmd" "${selector_args[@]}" \
            --prompt="MODIFIED FILE > " --nth=2.. \
            --preview "path=\$(printf '%s\n' '{}' | sed -E 's/^.. //; s#^.* -> ##') && [[ -n \"\$path\" ]] && ${git_cmd} diff --color=always -- \"\$path\"" \
            --preview-window=right:70% |
        sed -E 's/^.. //; s#^.* -> ##'
}

# ==========
# デフォルトブランチから変更のあるファイルを選択
# ==========
git-select-changed() {
    local BRANCH BASE_BRANCH git_cmd selector_cmd
    local -a selector_args

    _git_commands_require git || return 1
    git_cmd=${commands[git]}
    selector_cmd=$(_git_commands_selector_cmd) || return 1
    selector_args=()
    [[ "$selector_cmd" == */fzf-tmux ]] && selector_args=(-p 80%)
    BRANCH=$(git-current-branch)
    BASE_BRANCH=$(git-default-branch) || return 1

    "$git_cmd" diff --name-only "${BASE_BRANCH}"..."${BRANCH}" |
        "$selector_cmd" "${selector_args[@]}" \
            --prompt="CHANGED FILE > " \
            --preview "${git_cmd} diff --color=always ${BASE_BRANCH}...${BRANCH} -- \"{}\"" \
            --preview-window=right:70%
}

# ==========
# ブランチ選択
# ==========
git-select-branch() {
    local git_cmd selector_cmd
    local -a selector_args

    _git_commands_require git || return 1
    git_cmd=${commands[git]}
    selector_cmd=$(_git_commands_selector_cmd) || return 1
    selector_args=()
    [[ "$selector_cmd" == */fzf-tmux ]] && selector_args=(-p 80%)

    "$git_cmd" branch |
        "$selector_cmd" "${selector_args[@]}" \
            --prompt="GIT BRANCH > " \
            --preview "branch=\$(printf '%s\n' '{}' | sed -E 's/^[*[:space:]]+//') && [[ -n \"\$branch\" ]] && { echo \"[Only in \$branch]\"; ${git_cmd} log --graph --oneline --decorate=short --color=always HEAD..\"\$branch\"; echo; echo '[Only in HEAD]'; ${git_cmd} log --graph --oneline --decorate=short --color=always \"\$branch\"..HEAD; }" \
            --preview-window=right:70% |
        sed -E 's/^[*[:space:]]+//'
}

# ==========
# GHQ: リポジトリ選択 → cd まで自動
# fzf キャンセル時は安全に return
# ==========
git-goto-repository() {
    local repo root_path ghq_cmd selector_cmd eza_cmd
    local -a selector_args

    _git_commands_require ghq eza || return 1
    ghq_cmd=${commands[ghq]}
    eza_cmd=${commands[eza]}
    selector_cmd=$(_git_commands_selector_cmd) || return 1
    selector_args=()
    [[ "$selector_cmd" == */fzf-tmux ]] && selector_args=(-p 80%)

    repo=$("$ghq_cmd" list --unique "$@" |
        "$selector_cmd" "${selector_args[@]}" \
            --prompt="REPOSITORY > " \
            --preview "root_path=\$(${ghq_cmd} list --full-path -e {}) && [[ -n \"\$root_path\" ]] && ${eza_cmd} --tree --level=3 --color=always --group-directories-first \"\$root_path\" | head -n 200" \
            --preview-window=right:70%)

    # キャンセル対応
    if [[ -z "$repo" ]]; then
        echo "Canceled."
        return 1
    fi

    root_path=$("$ghq_cmd" list --full-path -e "$repo")
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
    local root_path git_cmd

    _git_commands_require git || return 1
    git_cmd=${commands[git]}

    root_path=$("$git_cmd" rev-parse --show-toplevel 2>/dev/null)
    if [[ -n "$root_path" ]]; then
        echo "cd $root_path"
        cd "$root_path"
        return 0
    fi

    git-goto-repository "$@"
}

# ==========
# GH CLI PR / ISSUE 選択
# ==========
gh-select-pr() {
    local gh_cmd selector_cmd
    local -a selector_args

    _git_commands_require gh || return 1
    gh_cmd=${commands[gh]}
    selector_cmd=$(_git_commands_selector_cmd) || return 1
    selector_args=()
    [[ "$selector_cmd" == */fzf-tmux ]] && selector_args=(-p 80%)

    "$gh_cmd" pr list |
        "$selector_cmd" "${selector_args[@]}" --prompt="PR > " \
            --preview "num=\$(printf '%s\n' '{}' | cut -f1) && ${gh_cmd} pr view \"\$num\" --json number,title,author,isDraft,reviewDecision,mergeStateStatus,statusCheckRollup,files --template \"{{printf \\\"PR #%v %s\\nAuthor: %s\\nDraft: %v\\nReview: %s\\nMerge: %s\\nChecks: %d\\nFiles:\\n\\\" .number .title .author.login .isDraft .reviewDecision .mergeStateStatus (len .statusCheckRollup)}}{{range .files}}{{printf \\\"  - %s\\n\\\" .path}}{{end}}\" | head -n 40" \
            --preview-window=right:70% |
        head -n 1 | cut -f1
}

gh-select-issue() {
    local gh_cmd selector_cmd
    local -a selector_args

    _git_commands_require gh || return 1
    gh_cmd=${commands[gh]}
    selector_cmd=$(_git_commands_selector_cmd) || return 1
    selector_args=()
    [[ "$selector_cmd" == */fzf-tmux ]] && selector_args=(-p 80%)

    "$gh_cmd" issue list |
        "$selector_cmd" "${selector_args[@]}" --prompt="ISSUE > " \
            --preview "num=\$(printf '%s\n' '{}' | cut -f1) && ${gh_cmd} issue view \"\$num\" --json number,title,state,author,labels,assignees,comments --template \"{{printf \\\"Issue #%v %s\\nState: %s\\nAuthor: %s\\nLabels: \\\" .number .title .state .author.login}}{{if .labels}}{{range \$i, \$label := .labels}}{{if \$i}}, {{end}}{{printf \\\"%s\\\" \$label.name}}{{end}}{{else}}-{{end}}{{printf \\\"\\nAssignees: \\\"}}{{if .assignees}}{{range \$i, \$assignee := .assignees}}{{if \$i}}, {{end}}{{printf \\\"%s\\\" \$assignee.login}}{{end}}{{else}}-{{end}}{{printf \\\"\\nComments: %d\\n\\\" (len .comments)}}\" | head -n 20" \
            --preview-window=right:70% |
        head -n 1 | cut -f1
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

# ==========
# gh + repos
# ==========
repos() { git-goto-repository "$@"; }

# ==========
# goto root
# ==========
root() { git-cd-root; }
