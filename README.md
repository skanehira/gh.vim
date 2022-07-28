# gh.vim - Vim/Neovim plugin for GitHub
## Development of gh.vim has stopped, please use [denops-gh.vim](https://github.com/skanehira/denops-gh.vim) instead

gh.vim provides some featuers of GitHub use it on Vim.  
For instance, you can see issue list or create issue, and GitHub Actions status, etc.  

![](https://i.gyazo.com/503dfe0eba487449f19d1c93e248902c.png)

## Features
- issues
  - create/edit/close/open/list
- issue comments
  - create/edit/list
- pull request
  - diff/list/merge
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
- git

## Usage

If you logged in with [`gh`](https://github.com/cli/cli) command, the access token is automatically fetched.

If you want to overwrite the token or set manually, write your [personal access token](https://github.com/settings/tokens) like below.

```vim
let g:gh_token = 'xxxxxxxxxxxxxxxxxxxx'
```

`gh.vim` just provides virtual buffers likes `gh://:owner/:repo/issues`, no any commands.  
`:owner` is user name or organization name, `:repo` is repository name.

If you want see issue list, please open buffer like bellow.

```
:new gh://skanehira/gh.vim/issues
```

## Options

| option                      | description                         |
|-----------------------------|-------------------------------------|
| `g:gh_token`                | GitHub personal access token        |
| `g:gh_open_issue_on_create` | open issue on browser after created |

## Buffer list
currently `gh.vim` provides buffers is bellow.

| buffer                                                        | description                                        |
|---------------------------------------------------------------|----------------------------------------------------|
| `gh://[pulls\|issues\|readme\|projects\|actions][?key=value]` | reopen buffer as current repository's :owner/:repo |
| `gh://:owner/:repo/issues[?state=open&..]`                    | issue list                                         |
| `gh://:owner/:repo/issues/:number`                            | edit issue                                         |
| `gh://:owner/:repo/issues/new`                                | new issue                                          |
| `gh://:owner/:repo/issues/:number/comments[?page=1&..]`       | issue comment list                                 |
| `gh://:owner/:repo/issues/:number/comments/new`               | new issue comment                                  |
| `gh://:owner/:repo/issues/:number/comments/:id`               | edit issue comment                                 |
| `gh://:owner/repos`                                           | repository list                                    |
| `gh://user/repos`                                             | authenticated user repository list                 |
| `gh://:owner/:repo/readme`                                    | repository readme                                  |
| `gh://:owner/:repo/pulls[?state=open&...]`                    | pull request list                                  |
| `gh://:owner/:repo/pulls/:number/diff`                        | pull request list diff                             |
| `gh://:owner/:repo/projects`                                  | project list                                       |
| `gh://orgs/:org/projects`                                     | organization project list                          |
| `gh://projects/:id/columns`                                   | project column list                                |
| `gh://:owner/:repo/actions[?status=success&...]`              | github action's workflows/steps                    |
| `gh://:owner/:repo/[:branch/:tree_sha]/files[?recache=1]`     | repository file tree                               |
| `gh://bookmarks`                                              | your bookmarks                                     |
| `gh://:owner/gists[?privacy=public]`                          | gist list                                          |
| `gh://:owner/gists/:id/:file`                                 | edit gist file                                     |
| `gh://gists/new/:filename`                                    | new gist                                           |

## Author
skanehira

## Thanks
- [prabirshrestha/quickpick.vim](https://github.com/prabirshrestha/quickpick.vim) is embeded
