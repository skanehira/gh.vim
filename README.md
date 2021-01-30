# gh.vim
Vim/Neovim plugin for GitHub

![](https://i.gyazo.com/503dfe0eba487449f19d1c93e248902c.png)

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
- file tree
  - open file
- gist
  - list/edit/create

## Requirements
- curl

## Installation
You can add this repo using your favorite plugin manager.

## Usage
Set your [personal access token](https://github.com/settings/tokens).

```vim
let g:gh_token = 'xxxxxxxxxxxxxxxxxxxx'
```

`gh.vim` just provides virtual buffers likes `gh://xxx`, no any commands.
So if you want see issue list, please open buffer likes bellow

```
:new gh://:owner/:repo/issues
```

`:owner` is user name or organization name.
`:repo` is repository name.

## Options

| option                      | description                       |
|-----------------------------|-----------------------------------|
| `g:gh_token`                | GitHub personal access token      |
| `g:gh_open_issue_on_create` | open issue url on default browser |

## Buffer list
currently `gh.vim` provides buffers is bellow.

| buffer                                                    | description                        |
|-----------------------------------------------------------|------------------------------------|
| `gh://:owner/:repo/issues[?state=open&..]`                | issue list                         |
| `gh://:owner/:repo/issues/:number`                        | edit issue                         |
| `gh://:owner/:repo/:branch/issues/new`                    | new issue                          |
| `gh://:owner/:repo/issues/:number/comments[?page=1&..]`   | issue comment list                 |
| `gh://:owner/:repo/issues/:number/comments/new`           | new issue comment                  |
| `gh://:owner/repos`                                       | repository list                    |
| `gh://user/repos`                                         | authenticated user repository list |
| `gh://:owner/:repo/readme`                                | repository readme                  |
| `gh://:owner/:repo/pulls[?state=open&...]`                | pull request list                  |
| `gh://:owner/:repo/pulls/:number/diff`                    | pull request list diff             |
| `gh://:owner/:repo/projects`                              | project list                       |
| `gh://orgs/:org/projects`                                 | organization project list          |
| `gh://projects/:id/columns`                               | project column list                |
| `gh://:owner/:repo/actions[?status=success&...]`          | github action's workflows/steps    |
| `gh://:owner/:repo/[:branch/:tree_sha]/files[?recache=1]` | repository file tree               |
| `gh://bookmarks`                                          | your bookmarks                     |
| `gh://:owner/gists[?privacy=public]`                      | gist list                          |
| `gh://:owner/gists/:id/:file`                             | edit gist file                     |
| `gh://gists/new/:filename`                                | new gist                           |

## Author
skanehira
