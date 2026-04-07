# zsh-git-commands

Git や gh を zsh から扱いやすくする対話的な helper 関数集です。

このリポジトリが提供するのは `PATH` に入る実行ファイルではなく、`zsh` に読み込んで使う shell function / alias です。

## Features

- `git-select-hash`: `git log` からコミットハッシュを選択
- `git-select-modified`: `git status --short` から変更ファイルを選択
- `git-select-changed`: デフォルトブランチとの差分ファイルを選択
- `git-select-branch`: ローカルブランチを選択
- `gh-select-pr`: PR を選択
- `gh-select-issue`: Issue を選択
- `git-current-branch`: 現在のブランチ名を返す
- `repos`: `ghq` 管理下のリポジトリへ移動
- `root`: Git リポジトリのルートへ移動

## Requirements

### Required

- `zsh`
- `git`
- `fzf`

### Optional

- `fzf-tmux`
  - tmux セッションに接続できる場合だけ使います
  - 使えない場合は自動で `fzf` にフォールバックします
- `gh`
  - `gh-select-pr`, `gh-select-issue` で使用
- `ghq`
  - `repos` で使用
- `eza`
  - `repos` の preview で使用

## Install

`.zshrc` などから `git-commands.plugin.zsh` を source してください。

```zsh
source /path/to/zsh-git-commands/git-commands.plugin.zsh
```

plugin manager を使っている場合は、その manager の流儀でこのファイルを読み込めば十分です。

## Usage

読み込み後、関数としてそのまま呼べます。

```zsh
git-select-modified
git-select-branch
git-select-hash
```

グローバル alias も定義されます。

```zsh
git add MODIFIED
git switch BRANCH
git show HASH
gh pr checkout PR
```

利用可能な alias:

- `HASH`
- `MODIFIED`
- `CHANGED`
- `BRANCH`
- `PR`
- `ISSUE`

## Notes

- `git-select-modified` は `git status --short` の結果からファイル名を返します
- rename は `old -> new` のうち新しいパスを返します
- preview は `git diff` / `git show` / `gh` を使って表示します
- `git` や `gh` を alias / shell function で上書きしていても、プラグイン側では外部コマンドの実体を優先して使います

## Troubleshooting

### `required command not found: ...`

必要なコマンドが見つかっていません。`git`, `fzf` などが `PATH` に入っているか確認してください。

```zsh
whence -p git
whence -p fzf
```

### tmux 上で popup が開かない

`fzf-tmux` が使えない場合は自動で `fzf` にフォールバックします。tmux 上で popup を使いたい場合は、tmux セッションに正しく接続されているか確認してください。
