# gh.vim
Vim plugin for GitHub(in development)

## Features
- create/update/list issues
- list repo
- list pull request

## Installation
Please install `curl` before installtion.

```toml
[[plugin]]
repo = 'skanehira/gh.vim'
```

## Usage
Set your personal access token.

```vim
let g:gh_token = 'xxxxxxxxxxxxxxxxxxxx'
```

`gh.vim` just provide virtual buffer `gh://xxx`, no any commands.
So if you want see issue list, please open buffer like bellow

```
:new gh://:owner/:repo/issues
```

`:owner` is user name or organization name.
`:repo` is repository name.

## Buffer list
currently `gh.vim` provide buffers is bellow.

| buffer                                              | opration               |
|-----------------------------------------------------|------------------------|
| `gh://:owner/:repo/issues[?state=open&creator=xxx]` | issue list             |
| `gh://:owner/:repo/issues/:number`                  | issue edit             |
| `gh://:owner/:repo/issues/new`                      | issue create           |
| `gh://:owner/repos`                                 | repository list        |
| `gh://:owner/:repo/pulls`                           | pull request list      |
| `gh://:owner/:repo/pulls/:number/diff`              | pull request list diff |

## Keymap list
| buffer                                              | keymap                                  |
|-----------------------------------------------------|-----------------------------------------|
| `gh://:owner/:repo/issues[?state=open&creator=xxx]` | `<C-l>`: next, `<C-h>`: prev, `e`: edit |
| `gh://:owner/:repo/pulls`                           | `dd`: diff                              |

## Loadmap
- issues
  - [x] list
    - [x] paging
  - [x] create
  - [ ] close
  - [ ] reopen
  - [x] update
    - [x] update title
- pull request
  - [x] list
    - [x] paging
  - [x] diff
  - [ ] create
  - [ ] merge
- repositories
  - [x] list
    - [x] paging
  - [ ] create
  - [ ] delete
  - [ ] transfer
  - [ ] make public/private
