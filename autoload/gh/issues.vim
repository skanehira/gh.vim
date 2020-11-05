" gh
" Author: skanehira
" License: MIT

function! s:issue_open_browser() abort
  call gh#gh#open_url(s:issues[line('.') -1].url)
endfunction

function! s:issue_url_yank() abort
  let url = s:issues[line('.') -1].url
  call gh#gh#yank(url)
  echom 'copied' url
endfunction

function! s:edit_issue() abort
  let number = s:issues[line('.')-1].number
  call execute(printf('belowright vnew gh://%s/%s/issues/%s',
        \ s:issue_list.repo.owner, s:issue_list.repo.name, number))
endfunction

function! s:issue_list(resp) abort
  nnoremap <buffer> <silent> <Plug>(gh_issue_list_next) :<C-u>call <SID>issue_list_change_page('+')<CR>
  nnoremap <buffer> <silent> <Plug>(gh_issue_list_prev) :<C-u>call <SID>issue_list_change_page('-')<CR>
  nmap <buffer> <silent> <C-l> <Plug>(gh_issue_list_next)
  nmap <buffer> <silent> <C-h> <Plug>(gh_issue_list_prev)

  " NOTE: issue may contain pull request
  call filter(a:resp.body, '!has_key(v:val, "pull_request")')

  if empty(a:resp.body)
    call gh#gh#set_message_buf('not found issues')
    return
  endif

  let s:issues = []
  let lines = []
  let url = printf('https://github.com/%s/%s/issues/', s:issue_list.repo.owner, s:issue_list.repo.name)

  let dict = map(copy(a:resp.body), {_, v -> #{
        \ number: printf('#%d', v.number),
        \ state: v.state,
        \ user: printf('@%s', v.user.login),
        \ title: v.title,
        \ }})
  let format = gh#gh#dict_format(dict, ['number', 'state', 'user', 'title'])

  for issue in a:resp.body
    call add(lines, printf(format,
          \ printf('#%d', issue.number), issue.state, printf('@%s', issue.user.login), issue.title))
    call add(s:issues, #{
          \ number: issue.number,
          \ body: split(issue.body, '\r\?\n'),
          \ url: url . issue.number,
          \ })
  endfor

  call setbufline(s:gh_issues_list_bufid, 1, lines)

  nnoremap <buffer> <silent> <Plug>(gh_issue_open_browser) :<C-u>call <SID>issue_open_browser()<CR>
  nnoremap <buffer> <silent> <Plug>(gh_issue_edit) :<C-u>call <SID>edit_issue()<CR>
  nnoremap <buffer> <silent> <Plug>(gh_issue_close) :<C-u>call <SID>issue_close()<CR>
  nnoremap <buffer> <silent> <Plug>(gh_issue_open) :<C-u>call <SID>issue_open()<CR>
  nnoremap <buffer> <silent> <Plug>(gh_issue_open_comment) :<C-u>call <SID>issue_open_comment()<CR>
  nnoremap <buffer> <silent> <Plug>(gh_issue_url_yank) :<C-u>call <SID>issue_url_yank()<CR>

  nmap <buffer> <silent> <C-o> <Plug>(gh_issue_open_browser)
  nmap <buffer> <silent> ghe   <Plug>(gh_issue_edit)
  nmap <buffer> <silent> ghc   <Plug>(gh_issue_close)
  nmap <buffer> <silent> gho   <Plug>(gh_issue_open)
  nmap <buffer> <silent> ghm   <Plug>(gh_issue_open_comment)
  nmap <buffer> <silent> ghy   <Plug>(gh_issue_url_yank)

endfunction

function! s:issue_open_comment() abort
  let number = s:issues[line('.')-1].number
  call execute(printf('new gh://%s/%s/issues/%d/comments',
        \ s:issue_list.repo.owner, s:issue_list.repo.name, number))
endfunction

function! s:issue_close() abort
  let number = s:issues[line('.')-1].number
  call gh#gh#message("closing issue")
  call gh#github#issues#update_state(s:issue_list.repo.owner, s:issue_list.repo.name, number, 'close')
        \.then(function('s:issue_close_success'))
        \.catch({err -> execute('call gh#gh#error_message(err.body)', '')})
endfunction

function! s:issue_close_success(resp) abort
  call gh#gh#message("closed issue")
  call s:issue_list_refresh()
endfunction

function! s:issue_open() abort
  let number = s:issues[line('.')-1].number
  call gh#gh#message("opening issue")
  call gh#github#issues#update_state(s:issue_list.repo.owner, s:issue_list.repo.name, number, 'open')
        \.then(function('s:issue_open_success'))
        \.catch({err -> execute('call gh#gh#error_message(err.body)', '')})
endfunction

function! s:issue_open_success(resp) abort
  call gh#gh#message("opend issue")
  call s:issue_list_refresh()
endfunction

function! s:issue_list_refresh() abort
  call gh#gh#delete_buffer(s:, 'gh_issues_list_bufid')
  let cmd = printf('e gh://%s/%s/issues?%s',
        \ s:issue_list.repo.owner, s:issue_list.repo.name, gh#http#encode_param(s:issue_list.param))
  call execute(cmd)
endfunction

function! s:issue_list_change_page(op) abort
  if a:op is# '+'
    let s:issue_list.param.page += 1
  else
    if s:issue_list.param.page < 2
      return
    endif
    let s:issue_list.param.page -= 1
  endif

  let cmd = printf('vnew gh://%s/%s/issues?%s',
        \ s:issue_list.repo.owner, s:issue_list.repo.name, gh#http#encode_param(s:issue_list.param))
  call execute(cmd)
endfunction

function! gh#issues#list() abort
  setlocal ft=gh-issues
  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/issues?*\(.*\)')

  call gh#gh#delete_buffer(s:, 'gh_issues_list_bufid')
  let s:gh_issues_list_bufid = bufnr()

  let param = gh#http#decode_param(m[3])
  if !has_key(param, 'page')
    let param['page'] = 1
  endif

  let s:issue_list = #{
        \ repo: #{
        \   owner: m[1],
        \   name: m[2],
        \ },
        \ param: param,
        \ }

  call gh#gh#init_buffer()
  call gh#gh#set_message_buf('loading')

  call gh#github#issues#list(s:issue_list.repo.owner, s:issue_list.repo.name, s:issue_list.param)
        \.then(function('s:issue_list'))
        \.then({-> execute("call gh#map#apply('gh-buffer-issue-list')")})
        \.catch({err -> execute('call gh#gh#error_message(err.body)', '')})
        \.finally(function('gh#gh#global_buf_settings'))
endfunction

function! gh#issues#new() abort
  let s:issue_title = input('[gh.vim] issue title ')
  echom ''
  redraw
  if s:issue_title is# ''
    call gh#gh#error_message('no issue title')
    bw!
    return
  endif

  let s:gh_issues_new_bufid = bufnr()
  call gh#gh#init_buffer()
  call gh#gh#set_message_buf('loading')

  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/issues/new$')
  let s:issue_new = #{
        \ owner: m[1],
        \ name: m[2],
        \ }

  call gh#github#repos#files(s:issue_new.owner, s:issue_new.name, 'master')
        \.then(function('s:get_template_files'))
        \.then(function('s:open_template_list'))
        \.then({-> execute("call gh#map#apply('gh-buffer-issue-new')")})
        \.catch(function('s:get_template_error'))
endfunction

function! s:get_template_error(error) abort
  if a:error.status is# 404
    call gh#gh#error_message('not found issue template')
  else
    call gh#gh#error_message('failed to get tempalte: ' . a:error.body)
  endif
  call s:open_template_list([])
endfunction

function! s:create_issue() abort
  call gh#gh#message('issue creating...')
  let data = #{
        \ title: s:issue_title,
        \ body: join(getline(1, '$'), "\r\n"),
        \ }

  call gh#github#issues#new(s:issue_new.owner, s:issue_new.name, data)
        \.then(function('s:create_issue_success'))
        \.catch({err -> execute('call gh#gh#error_message(err.body)', '')})
endfunction

function! s:create_issue_success(resp) abort
  bw!
  redraw!
  if has_key(g:, 'gh_open_issue_on_create') && g:gh_open_issue_on_create is# 1
    call gh#gh#open_url(a:resp.body.html_url)
  endif
  call gh#gh#message(printf('new issue: %s', a:resp.body.html_url))
endfunction

function! s:set_issue_template_buffer(resp) abort
  call execute(printf('e gh://%s/%s/issues/%s', s:issue_new.owner, s:issue_new.name, s:issue_title))
  setlocal buftype=acwrite
  setlocal ft=markdown

  if !empty(a:resp.body)
    call setline(1, split(a:resp.body, '\r'))
  endif

  setlocal nomodified
  nnoremap <buffer> <silent> q :bw<CR>
  augroup gh-create-issue
    au!
    au BufWriteCmd <buffer> call s:create_issue()
  augroup END
endfunction

function! s:get_template() abort
  let url = s:files[line('.')-1].url
  call gh#github#repos#get_file(url)
        \.then(function('s:set_issue_template_buffer'))
        \.catch({err -> execute('%d_ | call gh#gh#set_message_buf(err.body)', '')})
endfunction

function! s:open_template_list(files) abort
  if empty(a:files)
    call s:set_issue_template_buffer(#{body: ''})
    return
  endif
  let s:files = a:files
  call setbufline(s:gh_issues_new_bufid, 1, map(copy(a:files), {_, v -> v.file}))
  nnoremap <buffer> <silent> <CR> :call <SID>get_template()<CR>
endfunction

function! s:file_basename(file) abort
  let p = split(a:file, '/')
  return p[len(p)-1]
endfunction

function! s:get_template_files(resp) abort
  if !has_key(a:resp.body, 'tree')
    return []
  endif

  let files = filter(a:resp.body.tree,
        \ {_, v -> v.type is# 'blob' && (matchstr(v.path, '\.github/ISSUE_TEMPLATE.*') is# '' ? 0 : 1)})

  let files = map(files, {_, v -> #{file: s:file_basename(v.path),
        \ url: printf('https://raw.githubusercontent.com/%s/%s/master/%s',
        \ s:issue_new.owner, s:issue_new.name, v.path)}})
  return files
endfunction

function! s:update_issue_success(resp) abort
  bw!
  redraw!
  call gh#gh#message('update success')
endfunction

function! s:update_issue() abort
  let title = input(printf('[title] %s -> ', s:issue.title))
  echom ''
  redraw!

  if &modified is# 0 && title is# ''
    bw!
    return
  endif

  if title is# ''
    let title = s:issue.title
  endif

  call gh#gh#message('issue updating...')
  let data = #{
        \ title: title,
        \ body: join(getline(1, '$'), "\r\n"),
        \ }

  call gh#github#issues#update(s:issue.repo.owner, s:issue.repo.name, s:issue.number, data)
        \.then(function('s:update_issue_success'))
        \.catch({err -> execute('call gh#gh#error_message(err.body)', '')})
endfunction

function! s:comments_open_on_issue() abort
  let cmd = printf('new gh://%s/%s/issues/%s/comments',
        \ s:issue.repo.owner, s:issue.repo.name, s:issue.number)
  call execute(cmd)
endfunction

function! s:set_issues_body(resp) abort
  if empty(a:resp.body.body)
    call gh#gh#set_message_buf('no description provided')
    return
  endif
  let s:issue['title'] = a:resp.body.title
  call setbufline(s:gh_issues_edit_bufid, 1, split(a:resp.body.body, '\r\?\n'))
  setlocal nomodified buftype=acwrite ft=markdown

  nnoremap <buffer> <silent> <Plug>(gh_issue_comment_open_on_issue) :<C-u>call <SID>comments_open_on_issue()<CR>

  nmap <buffer> <silent> ghm <Plug>(gh_issue_comment_open_on_issue)
  nnoremap <buffer> <silent> q :bw<CR>

  augroup gh-update-issue
    au!
    au BufWriteCmd <buffer> call s:update_issue()
  augroup END
endfunction

function! gh#issues#issue() abort
  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/issues/\(.*\)$')

  call gh#gh#delete_buffer(s:, 'gh_issues_edit_bufid')
  let s:gh_issues_edit_bufid = bufnr()

  let s:issue = #{
        \ repo: #{
        \   owner: m[1],
        \   name: m[2],
        \ },
        \ number:  m[3],
        \ url: printf('https://github.com/%s/%s/issues/%s', m[1], m[2], m[3]),
        \ }

  call gh#gh#init_buffer()
  call gh#gh#set_message_buf('loading')

  call gh#github#issues#issue(s:issue.repo.owner, s:issue.repo.name, s:issue.number)
        \.then(function('s:set_issues_body'))
        \.then({-> execute("call gh#map#apply('gh-buffer-issue-edit')")})
        \.catch({err -> execute('call gh#gh#set_message_buf(err.body)', '')})
endfunction

function! gh#issues#comments() abort
  setlocal ft=gh-issue-comments
  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/issues/\(.*\)/comments?*\(.*\)')

  call gh#gh#delete_buffer(s:, 'gh_issues_comments_bufid')
  call gh#gh#delete_buffer(s:, 'gh_issues_comment_edit_bufid')

  let s:gh_issues_comments_bufid = bufnr()

  let param = gh#http#decode_param(m[4])
  if !has_key(param, 'page')
    let param['page'] = 1
  endif

  let s:comment_list = #{
        \ repo: #{
        \   owner: m[1],
        \   name: m[2],
        \ },
        \ number:  m[3],
        \ param: param,
        \ }

  call gh#gh#init_buffer()
  call gh#gh#set_message_buf('loading')

  nnoremap <buffer> <silent> <Plug>(gh_issue_comment_new) :<C-u>call <SID>issue_comment_new()<CR>
  nmap <buffer> <silent> ghn <Plug>(gh_issue_comment_new)

  call gh#github#issues#comments(s:comment_list.repo.owner, s:comment_list.repo.name, s:comment_list.number, s:comment_list.param)
        \.then(function('s:set_issue_comments_body'))
        \.then({-> execute("call gh#map#apply('gh-buffer-issue-comment-list')")})
        \.catch({err -> execute('call gh#gh#set_message_buf(has_key(err, "body") ? err.body : err)', '')})
        \.finally(function('gh#gh#global_buf_settings'))
endfunction

function! s:set_issue_comments_body(resp) abort
  nnoremap <buffer> <silent> <Plug>(gh_issue_comment_list_next) :<C-u>call <SID>issue_comment_list_change_page('+')<CR>
  nnoremap <buffer> <silent> <Plug>(gh_issue_comment_list_prev) :<C-u>call <SID>issue_comment_list_change_page('-')<CR>
  nmap <buffer> <silent> <C-l> <Plug>(gh_issue_comment_list_next)
  nmap <buffer> <silent> <C-h> <Plug>(gh_issue_comment_list_prev)

  if empty(a:resp.body)
    call gh#gh#set_message_buf('not found issue comments')
    return
  endif

  let s:issue_comments = []
  let lines = []

  let dict = map(copy(a:resp.body), {_, v -> #{
        \ id: printf('#%s', v.id),
        \ user: printf('@%s', v.user.login),
        \ }})
  let format = gh#gh#dict_format(dict, ['id', 'user'])

  for comment in a:resp.body
    call add(lines, printf(format, printf('#%s', comment.id), printf('@%s', comment.user.login)))
    call add(s:issue_comments, #{
          \ id: comment.id,
          \ user: comment.user.login,
          \ body: split(comment.body, '\r\?\n'),
          \ url: comment.html_url,
          \ })
  endfor
  call setbufline(s:gh_issues_comments_bufid, 1, lines)

  nnoremap <buffer> <silent> <Plug>(gh_issue_comment_open_browser) :<C-u>call <SID>issue_comment_open_browser()<CR>
  nmap <buffer> <silent> <C-o> <Plug>(gh_issue_comment_open_browser)

  " open preview/edit window
  let winid = win_getid()
  call s:issue_comment_open()
  call win_gotoid(winid)

  augroup gh-issue-comment-show
    au!
    au CursorMoved <buffer> call s:issue_comment_edit()
  augroup END
endfunction

function! s:issue_comment_open() abort
  call execute(printf('belowright vnew gh://%s/%s/issues/%s/comments/edit',
        \ s:comment_list.repo.owner, s:comment_list.repo.name, s:comment_list.number))
  call gh#gh#init_buffer()
  call gh#map#apply('gh-buffer-issue-comment-edit')

  setlocal ft=markdown
  setlocal buftype=acwrite
  nnoremap <buffer> <silent> q :bw<CR>

  let s:gh_issues_comment_edit_bufid = bufnr()
  let s:gh_issues_comment_edit_winid = win_getid()

  call s:issue_comment_edit()

  augroup gh-issue-comment-update
    au!
    au BufWriteCmd <buffer> call s:update_issue_comment()
  augroup END
endfunction

function! s:issue_comment_new() abort
  call execute(printf('topleft new gh://%s/%s/issues/%d/comments/new',
        \ s:comment_list.repo.owner, s:comment_list.repo.name, s:comment_list.number))
endfunction

function! s:issue_comment_edit() abort
  call win_execute(s:gh_issues_comment_edit_winid, '%d_')
  call setbufline(s:gh_issues_comment_edit_bufid, 1, s:issue_comments[line('.')-1].body)
  call win_execute(s:gh_issues_comment_edit_winid, 'setlocal nomodified')
  let s:comment = s:issue_comments[line('.')-1]
endfunction

function! s:update_issue_comment() abort
  let body = getline(1, '$')
  if empty(body)
    call gh#gh#error_message('required body')
    return
  endif

  let data = #{
        \ body: join(body, "\r\n"),
        \ }

  call gh#gh#message('comment updating...')

  call gh#github#issues#comment_update(s:comment_list.repo.owner, s:comment_list.repo.name, s:comment.id, data)
        \.then(function('s:update_issue_comment_success'))
        \.catch({err -> execute('call gh#gh#error_message(err.body)', '')})
endfunction

function! s:update_issue_comment_success(resp) abort
  bw!
  call gh#gh#message('comment updated')
  call gh#gh#delete_buffer(s:, 'gh_issues_comments_bufid')
  call gh#gh#delete_buffer(s:, 'gh_issues_comment_edit_bufid')
  call execute(printf('new gh://%s/%s/issues/%s/comments',
        \ s:comment_list.repo.owner, s:comment_list.repo.name, s:comment_list.number))
endfunction

function! s:issue_comment_list_change_page(op) abort
  if a:op is# '+'
    let s:comment_list.param.page += 1
  else
    if s:comment_list.param.page < 2
      return
    endif
    let s:comment_list.param.page -= 1
  endif

  let cmd = printf('vnew gh://%s/%s/issues/%s/comments?%s',
        \ s:comment_list.repo.owner, s:comment_list.repo.name, s:comment_list.number, gh#http#encode_param(s:comment_list.param))
  call execute(cmd)
endfunction

function! s:issue_comment_open_browser() abort
  call gh#gh#open_url(s:issue_comments[line('.')-1].url)
endfunction

function! gh#issues#comment_new() abort
  call gh#gh#delete_buffer(s:, 'gh_issues_comment_new_bufid')
  let s:gh_issues_comment_new_bufid = bufnr()
  call gh#gh#init_buffer()
  setlocal ft=markdown

  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/issues/\(.*\)/comments/new$')
  let s:comment_new = #{
        \ owner: m[1],
        \ name: m[2],
        \ issue: #{
        \   number: m[3],
        \ },
        \ }

  setlocal buftype=acwrite
  nnoremap <buffer> <silent> q :bw<CR>

  augroup gh-issue-comment-create
    au!
    au BufWriteCmd <buffer> call s:create_issue_comment()
  augroup END
  call gh#map#apply('gh-buffer-issue-comment-new')
endfunction

function! s:create_issue_comment() abort
  call gh#gh#message('comment creating...')
  let data = #{
        \ body: join(getline(1, '$'), "\r\n"),
        \ }
  if empty(data.body)
    call gh#gh#error_message('required body')
    return
  endif

  call gh#github#issues#comment_new(s:comment_new.owner, s:comment_new.name, s:comment_new.issue.number, data)
        \.then(function('s:create_issue_comment_success'))
        \.catch({err -> execute('call gh#gh#error_message(err.body)', '')})
endfunction

function s:create_issue_comment_success(resp) abort
  call gh#gh#delete_buffer(s:, 'gh_issues_comment_new_bufid')
  call gh#gh#message(printf('new comment: %s', a:resp.body.html_url))
  call gh#gh#delete_buffer(s:, 'gh_issues_comments_bufid')
  call execute(printf('new gh://%s/%s/issues/%d/comments',
        \ s:comment_list.repo.owner, s:comment_list.repo.name, s:comment_list.number))
endfunction
