# gh.vim
Vim plugin for GitHub

![](https://i.imgur.com/tTTSZs6.gif)

## Features
- create/edit/close/open/list issues
- create/edit/list issue comments
- create/delete/list repo
- diff/list pull request

※currently doesn't work on Neovim

## Installation
Please install `curl` before installtion.

After you have installed `curl`, you can add this repo using your favorite plugin manager.

### dein.vim

Using [dein.vim](https://github.com/Shougo/dein.vim) add this to your config:

```toml
[[plugin]]
repo = 'skanehira/gh.vim'
```

### vim-plug

Using [vim-plug](https://github.com/junegunn/vim-plug/blob/master/README.md), add the following to your vimrc:

```vim
call plug#begin('~/.vim/plugged')
Plug 'skanehira/gh.vim'
call plug#end()
```

## Usage
Set your [personal access token](https://github.com/settings/tokens).

```vim
let g:gh_token = 'xxxxxxxxxxxxxxxxxxxx'
```

`gh.vim` just provides virtual buffer likes `gh://xxx`, no any commands.
So if you want see issue list, please open buffer likes bellow

```
:new gh://:owner/:repo/issues
```

`:owner` is user name or organization name.
`:repo` is repository name.

## Options

| option                        | default | description                        |
|-------------------------------|---------|------------------------------------|
| `gh_token`                    | ''      | GitHub personal access token       |
| `gh_enable_delete_repository` | false   | enable delete repository operation |

## Buffer list
currently `gh.vim` provides buffers is bellow.

| buffer                                          | description                            |
|-------------------------------------------------|----------------------------------------|
| `gh://:owner/:repo/issues[?state=open&..]`      | get issue list                         |
| `gh://:owner/:repo/issues/:number`              | edit issue                             |
| `gh://:owner/:repo/:branch/issues/new`          | new issue                              |
| `gh://:owner/:repo/issues/comments[?page=1&..]` | get issue comment list                 |
| `gh://:owner/:repo/issues/comments/new`         | new issue comment                      |
| `gh://:owner/repos`                             | get repository list                    |
| `gh://user/repos`                               | get authenticated user repository list |
| `gh://user/repos/new`                           | new repository                         |
| `gh://:owner/:repo/readme`                      | get repository readme                  |
| `gh://:owner/:repo/pulls[?state=open&...]`      | get pull request list                  |
| `gh://:owner/:repo/pulls/:number/diff`          | show pull request list diff            |

## Keymap list
### issue list

| keymap                          | default | description             |
|---------------------------------|---------|-------------------------|
| `<Plug>(gh_issue_list_prev)`    | `<C-h>` | previous page           |
| `<Plug>(gh_issue_list_next)`    | `<C-l>` | next page               |
| `<Plug>(gh_issue_open_browser)` | `<C-o>` | open issue on browser   |
| `<Plug>(gh_issue_edit)`         | `ghe`   | edit issue              |
| `<Plug>(gh_issue_close)`        | `ghc`   | close issue             |
| `<Plug>(gh_issue_open)`         | `gho`   | open issue              |
| `<Plug>(gh_issue_url_yank)`     | `ghy`   | yank issue url          |
| `<Plug>(gh_issue_open_comment)` | `ghm`   | open issue comment list |

### issue comment list

| keymap                                  | default | description                   |
|-----------------------------------------|---------|-------------------------------|
| `<Plug>(gh_issue_comment_list_prev)`    | `<C-h>` | previous page                 |
| `<Plug>(gh_issue_comment_list_next)`    | `<C-l>` | next page                     |
| `<Plug>(gh_issue_comment_open_browser)` | `<C-o>` | open issue comment on browser |
| `<Plug>(gh_issue_comment_new)`          | `ghn`   | new issue comment             |

### pull request list

| keymap                         | default | description                  |
|--------------------------------|---------|------------------------------|
| `<Plug>(gh_pull_list_next)`    | `<C-h>` | previous page                |
| `<Plug>(gh_pull_list_prev)`    | `<C-l>` | next page                    |
| `<Plug>(gh_pull_open_browser)` | `<C-o>` | open pull request on browser |
| `<Plug>(gh_pull_diff)`         | `ghd`   | show pull request diff       |

### repository list

| keymap                         | default | description                                                         |
|--------------------------------|---------|---------------------------------------------------------------------|
| `<Plug>(gh_repo_list_next)`    | `<C-h>` | previous page                                                       |
| `<Plug>(gh_repo_list_prev)`    | `<C-l>` | next page                                                           |
| `<Plug>(gh_repo_open_browser)` | `<C-o>` | open repository on browser                                          |
| `<Plug>(gh_repo_show_readme)`  | `gho`   | show repository readme                                              |
| `<Plug>(gh_repo_delete)`       | `ghd`   | delete repository(if `gh_enable_delete_repository` options is true) |

## Roadmap
- issues
  - [x] list
    - [x] paging
  - [x] create
  - [x] close
  - [x] reopen
  - [x] update
    - [x] update title
  - [x] comment list
    - [x] create
    - [x] update
- pull request
  - [x] list
    - [x] paging
  - [x] diff
  - [ ] create
  - [ ] merge
- repositories
  - [x] list
    - [x] paging
  - [x] create
  - [x] delete
  - [ ] transfer
  - [ ] make public/private
