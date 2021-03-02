" help
" Author: skanehira
" License: MIT

let s:keymap_issues =<< trim END
normal    <C-h>   <Plug>(gh_list_prev_page)         show previous page
normal    <C-l>   <Plug>(gh_list_next_page)         show next page
normal    <C-j>   <Plug>(gh_list_mark_down)         mark item and move down
normal    <C-k>   <Plug>(gh_list_mark_up)           mark item and move up
normal    <C-o>   <Plug>(gh_issue_open_browser)     open issue on browser
normal    ghe     <Plug>(gh_issue_edit)             edit issue
normal    ghc     <Plug>(gh_issue_close)            close issue
normal    gho     <Plug>(gh_issue_open)             open issue
normal    ghm     <Plug>(gh_issue_open_comment)     open comments
normal    ghn     <Plug>(gh_issue_new)              create new issue
normal    ghy     <Plug>(gh_issue_url_yank)         yank issue url
normal    ghp     <Plug>(gh_preview_toggle)         toggle open/close previewing contents
normal    <C-n>   <Plug>(gh_preview_move_down)      move down cursorline in preview
normal    <C-p>   <Plug>(gh_preview_move_up)        move up cursorline in preview
END

let s:keymap_comments =<< trim END
normal    <C-h>   <Plug>(gh_list_prev_page)              show previous page
normal    <C-l>   <Plug>(gh_list_next_page)              show next page
normal    <C-j>   <Plug>(gh_list_mark_down)              mark item and move down
normal    <C-k>   <Plug>(gh_list_mark_up)                mark item and move up
normal    <C-o>   <Plug>(gh_issue_comment_open_browser)  open issue comment on browser
normal    ghe     <Plug>(gh_issue_comment_edit)          edit issue comment
normal    ghn     <Plug>(gh_issue_comment_new)           create new issue comment
normal    ghy     <Plug>(gh_issue_comment_url_yank)      yank issue comment url
normal    ghp     <Plug>(gh_preview_toggle)              toggle open/close previewing contents
normal    <C-n>   <Plug>(gh_preview_move_down)           move down cursorline in preview
normal    <C-p>   <Plug>(gh_preview_move_up)             move up cursorline in preview
END

let s:keymap_pulls =<< trim END
normal    <C-h>   <Plug>(gh_list_prev_page)              show previous page
normal    <C-l>   <Plug>(gh_list_next_page)              show next page
normal    <C-j>   <Plug>(gh_list_mark_down)              mark item and move down
normal    <C-k>   <Plug>(gh_list_mark_up)                mark item and move up
normal    <C-o>   <Plug>(gh_pull_open_browser)           open pull request on browser 
normal    ghd     <Plug>(gh_pull_diff)                   show diff of pull request
normal    ghy     <Plug>(gh_pull_url_yank)               yank pull request url
normal    ghm     <Plug>(gh_pull_merge)                  merge pull request
END

let s:keymap_repos =<< trim END
normal    <C-h>      <Plug>(gh_repo_list_prev)           show previous page
normal    <C-l>      <Plug>(gh_repo_list_next)           show next page
normal    <C-o>      <Plug>(gh_repo_open_browser)        open repo on browser
normal    gho        <Plug>(gh_repo_show_readme)         show readme
END

let s:keymap_projects =<< trim END
normal    <CR>      <Plug>(gh_project_open)              show project columns
normal    <C-o>     <Plug>(gh_project_open_browser)      open project on browser
normal    ghy       <Plug>(gh_project_url_yank)          yank project url
END

let s:keymap_project_columns =<< trim END
normal    <C-o>     <Plug>(gh_projects_card_open_browser)  open project card on browser
normal    ghe       <Plug>(gh_projects_card_edit)          edit project card
normal    ghm       <Plug>(gh_projects_card_move)          move project card to current column
normal    ghy       <Plug>(gh_projects_card_url_yank)      yank cards url
normal    ghc       <Plug>(gh_projects_card_close)         close card
normal    gho       <Plug>(gh_projects_card_open)          open card
END

let s:keymap_actions =<< trim END
normal    <C-o>     <Plug>(gh_actions_open_browser)        open action's workflow/step on browser
normal    ghy       <Plug>(gh_actions_yank_url)            yank action's workflow/step url
normal    gho       <Plug>(gh_actions_open_logs)           open selected actions's job logs in Vim terminal
END

let s:keymap_files =<< trim END
normal    ghe       <Plug>(gh_files_edit)                  open selected file
normal    ghy       <Plug>(gh_files_yank_url)              yank selected files
normal    <C-o>     <Plug>(gh_files_open_browser)          open selected files in browser
END

let s:keymap_file =<< trim END
normal   <C-o>      <Plug>(gh_files_open_browser)          open selected files in browser
visual   ghy        <Plug>(gh_file_yank_url)               yank selected file's line in browser
END

let s:keymap_gists =<< trim END
normal    ghp        <Plug>(gh_preview_toggle)             toggle open/close previewing contents
normal    <C-n>      <Plug>(gh_preview_move_down)          move down cursorline in preview
normal    <C-p>      <Plug>(gh_preview_move_up)            move up cursorline in preview
normal    ghf        <Plug>(gh_gist_list_fetch)            get gists more
normal    ghy        <Plug>(gh_gist_list_yank)             yank gist url
normal    <C-o>      <Plug>(gh_gist_list_open_browser)     open gist in browser
normal    ghe        <Plug>(gh_gist_edit_file)             edit gist file
END

let s:keymap_gist =<< trim END
normal    ghy        <Plug>(gh_gist_list_yank)             yank gist url
normal    <C-o>      <Plug>(gh_gist_list_open_browser)     open gist in browser
normal    ghe        <Plug>(gh_gist_edit_file)             edit gist file
END

let s:keymap_issue_edit =<< trim END
normal    ghm       <Plug>(gh_issue_comment_open_on_issue)  open issue comments on gh-buffer-issue-edit
END

let s:keymap_bookmark =<< trim END
normal    gho       <Plug>(gh_bookmark_open)      open buffer
END

function! s:on_accept(data, name) abort
  call gh#provider#quickpick#close()
endfunction

function! s:on_change(data, name) abort
  call gh#provider#quickpick#on_change(a:data, a:name, s:maps)
endfunction

function! gh#help#keymap(type) abort
  let s:maps = ''

  if a:type is# 'issues'
    let s:maps = s:keymap_issues
  elseif a:type is# 'issue-edit'
    let s:maps = s:keymap_issue_edit
  elseif a:type is# 'issue-comments'
    let s:maps = s:keymap_comments
  elseif a:type is# 'pulls'
    let s:maps = s:keymap_pulls
  elseif a:type is# 'repos'
    let s:maps = s:keymap_repos
  elseif a:type is# 'projects'
    let s:maps = s:keymap_projects
  elseif a:type is# 'project-columns'
    let s:maps = s:keymap_project_columns
  elseif a:type is# 'actions'
    let s:maps = s:keymap_actions
  elseif a:type is# 'files'
    let s:maps = s:keymap_files
  elseif a:type is# 'file'
    let s:maps = s:keymap_file
  elseif a:type is# 'gists'
    let s:maps = s:keymap_gists
  elseif a:type is# 'gist'
    let s:maps = s:keymap_gist
  elseif a:type is# 'bookmark'
    let s:maps = s:keymap_bookmark
  endif

  if empty(s:maps)
    return
  endif

  call gh#provider#quickpick#open({
        \ 'items': s:maps,
        \ 'filter': 0,
        \ 'debounce': 0,
        \ 'on_accept': function('s:on_accept'),
        \ 'on_change': function('s:on_change'),
        \})
endfunction

function! gh#help#set_keymap(type) abort
  exe printf('noremap <buffer> <silent> <Plug>(gh-help) :<C-u>call gh#help#keymap("%s")<CR>', a:type)
  nmap <buffer> <silent> ghh <Plug>(gh-help)
endfunction
