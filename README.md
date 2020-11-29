# gh.vim
Vim/Neovim plugin for GitHub

![](https://i.imgur.com/tTTSZs6.gif)

## Features
- issues
  - create/edit/close/open/list
- issue comments
  - create/edit/list
- pull request
  - diff/list
- repository
  - list/show README
- project
  - list/card list/move card
- github actions
  - list/open job logs

## Installation
Please install `curl` before installtion.

After you have installed `curl`, you can add this repo using your favorite plugin manager.

### dein.vim

Using [dein.vim](https://github.com/Shougo/dein.vim) add this to your config:

```toml
[[plugin]]
repo = 'skanehira/gh.vim'
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

| option     | description                  |
|------------|------------------------------|
| `gh_token` | GitHub personal access token |

## Buffer list
currently `gh.vim` provides buffers is bellow.

| buffer                                           | description                            |
|--------------------------------------------------|----------------------------------------|
| `gh://:owner/:repo/issues[?state=open&..]`       | get issue list                         |
| `gh://:owner/:repo/issues/:number`               | edit issue                             |
| `gh://:owner/:repo/:branch/issues/new`           | new issue                              |
| `gh://:owner/:repo/issues/comments[?page=1&..]`  | get issue comment list                 |
| `gh://:owner/:repo/issues/comments/new`          | new issue comment                      |
| `gh://:owner/repos`                              | get repository list                    |
| `gh://user/repos`                                | get authenticated user repository list |
| `gh://user/repos/new`                            | new repository                         |
| `gh://:owner/:repo/readme`                       | get repository readme                  |
| `gh://:owner/:repo/pulls[?state=open&...]`       | get pull request list                  |
| `gh://:owner/:repo/pulls/:number/diff`           | show pull request list diff            |
| `gh://:owner/:repo/projects`                     | show project list                      |
| `gh://orgs/:org/projects`                        | show organization project list         |
| `gh://projects/:id/columns`                      | show project column list               |
| `gh://:owner/:repo/actions[?status=success&...]` | show github action's workflows/steps   |
| `gh://bookmarks`                                 | show your bookmarks                    |

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
| `<Plug>(gh_issue_comment_url_yank)`     | `ghy`   | yank issue comment            |

### pull request list

| keymap                         | default | description                  |
|--------------------------------|---------|------------------------------|
| `<Plug>(gh_pull_list_next)`    | `<C-h>` | previous page                |
| `<Plug>(gh_pull_list_prev)`    | `<C-l>` | next page                    |
| `<Plug>(gh_pull_open_browser)` | `<C-o>` | open pull request on browser |
| `<Plug>(gh_pull_diff)`         | `ghd`   | show pull request diff       |
| `<Plug>(gh_pull_url_yank)`     | `ghy`   | yank pull request url        |

### repository list

| keymap                         | default | description                                                         |
|--------------------------------|---------|---------------------------------------------------------------------|
| `<Plug>(gh_repo_list_next)`    | `<C-h>` | previous page                                                       |
| `<Plug>(gh_repo_list_prev)`    | `<C-l>` | next page                                                           |
| `<Plug>(gh_repo_open_browser)` | `<C-o>` | open repository on browser                                          |
| `<Plug>(gh_repo_show_readme)`  | `gho`   | show repository readme                                              |

### bookmark list

| keymap                     | default | description |
|----------------------------|---------|-------------|
| `<Plug>(gh_bookmark_open)` | `gho`   | open buffer |

### project column list

| keymap                                  | default | description                   |
|-----------------------------------------|---------|-------------------------------|
| `<Plug>(gh_projects_card_open_browser)` | `<C-o>` | open card on browser          |
| `<Plug>(gh_projects_card_open)`         | `gho`   | open card                     |
| `<Plug>(gh_projects_card_move)`         | `ghm`   | move card into current column |
| `<Plug>(gh_projects_card_url_yank)`     | `ghy`   | yank card url                 |

### GitHub Actions list

| keymap                            | default | description                                      |
|-----------------------------------|---------|--------------------------------------------------|
| `<Plug>(gh_actions_open_browser)` | `<C-o>` | open selected action's workflow/step on browser  |
| `<Plug>(gh_actions_yank_url)`     | `ghy`   | yank selected action's workflow/stop url         |
| `<Plug>(gh_actions_open_logs)`    | `gho`   | open selected actions's job logs in Vim terminal |

## Author
skanehira
