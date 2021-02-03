" issues
" Author: skanehira
" License: MIT

let s:Promise = vital#gh#import('Async.Promise')

function! s:issue_open_browser() abort
  let issues = s:get_selected_issues()
  for issue in issues
    call gh#gh#open_url(issue.url)
  endfor
  call gh#provider#list#clean_marked()
  call gh#provider#list#redraw()
endfunction

function! s:issue_url_yank() abort
  let urls = []
  let issues = s:get_selected_issues()

  for issue in issues
    call add(urls, issue.url)
  endfor

  call gh#provider#list#clean_marked()
  call gh#provider#list#redraw()

  call gh#gh#yank(urls)
endfunction

function! s:edit_issue() abort
  let open = gh#gh#decide_open()
  if empty(open)
    return
  endif
  let number = gh#provider#list#current().number[1:]
  call execute(printf('belowright %s gh://%s/%s/issues/%s',
        \ open, b:gh_issue_list.repo.owner, b:gh_issue_list.repo.name, number))
endfunction

function! s:set_issue_list(resp) abort
  " NOTE: issue may contain pull request
  call filter(a:resp.body, '!has_key(v:val, "pull_request")')

  let list = {
        \ 'bufname': printf('gh://%s/%s/issues', b:gh_issue_list.repo.owner, b:gh_issue_list.repo.name),
        \ 'param': b:gh_issue_list.param
        \ }

  if empty(a:resp.body)
    let list['data'] = []
    call gh#gh#set_message_buf('not found issues')
    call gh#provider#list#open(list)
    return
  endif

  let url = printf('https://github.com/%s/%s/issues/', b:gh_issue_list.repo.owner, b:gh_issue_list.repo.name)
  let data = map(copy(a:resp.body), { _, issue -> {
        \ 'id': issue.id,
        \ 'number': printf('#%d', issue.number),
        \ 'state': issue.state,
        \ 'user': printf('@%s', issue.user.login),
        \ 'title': issue.title,
        \ 'body': split(issue.body, '\r\?\n'),
        \ 'url': url .. issue.number
        \ }})

  let header = [
        \ 'number',
        \ 'state',
        \ 'user',
        \ 'title',
        \ ]

  let list['header'] = header
  let list['data'] = data

  call gh#provider#list#open(list)

  nnoremap <buffer> <silent> <Plug>(gh_issue_open_browser) :<C-u>call <SID>issue_open_browser()<CR>
  nnoremap <buffer> <silent> <Plug>(gh_issue_edit) :<C-u>call <SID>edit_issue()<CR>
  nnoremap <buffer> <silent> <Plug>(gh_issue_close) :<C-u>call <SID>set_issue_state('close')<CR>
  nnoremap <buffer> <silent> <Plug>(gh_issue_open) :<C-u>call <SID>set_issue_state('open')<CR>
  nnoremap <buffer> <silent> <Plug>(gh_issue_open_comment) :<C-u>call <SID>issue_open_comment()<CR>
  nnoremap <buffer> <silent> <Plug>(gh_issue_url_yank) :<C-u>call <SID>issue_url_yank()<CR>

  nmap <buffer> <silent> <C-o> <Plug>(gh_issue_open_browser)
  nmap <buffer> <silent> ghe   <Plug>(gh_issue_edit)
  nmap <buffer> <silent> ghc   <Plug>(gh_issue_close)
  nmap <buffer> <silent> gho   <Plug>(gh_issue_open)
  nmap <buffer> <silent> ghm   <Plug>(gh_issue_open_comment)
  nmap <buffer> <silent> ghy   <Plug>(gh_issue_url_yank)

  call gh#provider#preview#open(function('s:get_preview_info'))
endfunction

function! s:get_preview_info() abort
  let current = gh#provider#list#current()
  if !empty(current)
    return {
          \ 'filename': 'issue.md',
          \ 'contents': current.body,
          \ }
  endif
  return {
        \ 'filename': '',
        \ 'contents': [],
        \ }
endfunction

function! s:get_selected_issues() abort
  let issues = gh#provider#list#get_marked()
  if empty(issues)
    return [gh#provider#list#current()]
  endif
  return issues
endfunction

function! s:issue_open_comment() abort
  let open = gh#gh#decide_open()
  if empty(open)
    return
  endif
  let number = gh#provider#list#current().number[1:]
  call execute(printf('%s gh://%s/%s/issues/%d/comments',
        \ open, b:gh_issue_list.repo.owner, b:gh_issue_list.repo.name, number))
endfunction

function! s:set_issue_state(state) abort
  if a:state is# 'close'
    call gh#gh#message('closing...')
  else
    call gh#gh#message('opening...')
  endif

  let promises = []

  let issues = s:get_selected_issues()
  for issue in issues
    let number = issue.number[1:]
    call add(promises, gh#github#issues#update_state(b:gh_issue_list.repo.owner, b:gh_issue_list.repo.name, number, a:state))
  endfor

  let state = a:state is# 'open' ? a:state : 'closed'
  call s:Promise.all(promises)
        \.then({-> s:gh_issue_state_update(issues, state)})
        \.catch({err -> gh#gh#error_message(err.body)})
        \.finally({-> execute('echom ""', '')})
endfunction

function! s:gh_issue_state_update(issues, state) abort
  for issue in a:issues
    let issue.state = a:state
  endfor
  call gh#provider#list#clean_marked()
  call gh#provider#list#redraw()
endfunction

function! gh#issues#list() abort
  setlocal ft=gh-issues
  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/issues?*\(.*\)')

  let b:gh_issues_list_bufid = bufnr()

  let param = gh#http#decode_param(m[3])
  if !has_key(param, 'page')
    let param['page'] = 1
  endif

  let b:gh_issue_list = {
        \ 'repo': {
        \   'owner': m[1],
        \   'name': m[2],
        \ },
        \ 'param': param,
        \ }

  call gh#gh#init_buffer()
  call gh#gh#set_message_buf('loading')

  call gh#github#issues#list(b:gh_issue_list.repo.owner, b:gh_issue_list.repo.name, b:gh_issue_list.param)
        \.then(function('s:set_issue_list'))
        \.then({-> gh#map#apply('gh-buffer-issue-list', b:gh_issues_list_bufid)})
        \.catch({err -> execute('call gh#gh#error_message(err.body)', '')})
        \.finally(function('gh#gh#global_buf_settings'))
endfunction

function! gh#issues#new() abort

  let s:gh_issues_new_bufid = bufnr()
  call gh#gh#init_buffer()
  call gh#gh#set_message_buf('loading')

  let m = matchlist(bufname(), 'gh://\(.\{-}\)/\(.\{-}\)/\(.*\)/issues/new$')
  let s:gh_issue_new = {
        \ 'owner': m[1],
        \ 'name': m[2],
        \ 'branch': m[3],
        \ }

  call gh#github#repos#files(s:gh_issue_new.owner, s:gh_issue_new.name, s:gh_issue_new.branch)
        \.then(function('s:get_template_files'))
        \.then(function('s:open_template_list'))
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
  let data = {
        \ 'title': s:gh_issue_title,
        \ 'body': join(getline(1, '$'), "\r\n"),
        \ }

  call gh#github#issues#new(s:gh_issue_new.owner, s:gh_issue_new.name, data)
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
  let s:gh_issue_title = input('[gh.vim] issue title ')
  echom ''
  redraw
  if s:gh_issue_title is# ''
    call gh#gh#error_message('no issue title')
    return
  endif

  call execute(printf('e gh://%s/%s/issues/%s', s:gh_issue_new.owner, s:gh_issue_new.name, s:gh_issue_title))
  call gh#map#apply('gh-buffer-issue-new', bufnr())
  setlocal buftype=acwrite
  setlocal ft=markdown

  if !empty(a:resp.body)
    call setline(1, split(a:resp.body, '\r'))
  endif

  setlocal nomodified
  nnoremap <buffer> <silent> q :q<CR>
  augroup gh-create-issue
    au!
    au BufWriteCmd <buffer> call s:create_issue()
  augroup END
endfunction

function! s:get_template() abort
  let url = s:gh_template_files[line('.')-1].url
  call gh#http#get(url)
        \.then(function('s:set_issue_template_buffer'))
        \.catch({err -> execute('%d_ | call gh#gh#set_message_buf(err.body)', '')})
endfunction

function! s:open_template_list(files) abort
  if empty(a:files)
    bw!
    call s:set_issue_template_buffer({'body': ''})
    return
  endif
  let s:gh_template_files = a:files
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

  let files = map(files, {_, v -> {'file': s:file_basename(v.path),
        \ 'url': printf('https://raw.githubusercontent.com/%s/%s/%s/%s',
        \ s:gh_issue_new.owner, s:gh_issue_new.name, s:gh_issue_new.branch, v.path)}})
  return files
endfunction

function! s:update_issue_success(resp) abort
  setlocal nomodified
  redraw!
  call gh#gh#message('update success')
endfunction

function! s:update_issue() abort
  let title = input(printf('[title] %s -> ', b:gh_issue.title))
  echom ''
  redraw!

  if &modified is# 0 && title is# ''
    bw!
    return
  endif

  if title is# ''
    let title = b:gh_issue.title
  endif

  call gh#gh#message('issue updating...')
  let data = {
        \ 'title': title,
        \ 'body': join(getline(1, '$'), "\r\n"),
        \ }

  call gh#github#issues#update(b:gh_issue.repo.owner, b:gh_issue.repo.name, b:gh_issue.number, data)
        \.then(function('s:update_issue_success'))
        \.catch({err -> execute('call gh#gh#error_message(err.body)', '')})
endfunction

function! s:comments_open_on_issue() abort
  let cmd = printf('new gh://%s/%s/issues/%s/comments',
        \ b:gh_issue.repo.owner, b:gh_issue.repo.name, b:gh_issue.number)
  call execute(cmd)
endfunction

function! s:set_issues_body(resp) abort
  if empty(a:resp.body.body)
    call gh#gh#set_message_buf('no description provided')
  else
    call setbufline(b:gh_issues_edit_bufid, 1, split(a:resp.body.body, '\r\?\n'))
  endif
  let b:gh_issue['title'] = a:resp.body.title
  setlocal nomodified buftype=acwrite ft=markdown

  nnoremap <buffer> <silent> <Plug>(gh_issue_comment_open_on_issue) :<C-u>call <SID>comments_open_on_issue()<CR>

  nmap <buffer> <silent> ghm <Plug>(gh_issue_comment_open_on_issue)
  nnoremap <buffer> <silent> q :q<CR>

  exe printf('augroup gh-update-issue-%d', bufnr())
    au!
    au BufWriteCmd <buffer> call s:update_issue()
  augroup END
endfunction

function! gh#issues#issue() abort
  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/issues/\(.*\)$')
  let b:gh_issues_edit_bufid = bufnr()

  let b:gh_issue = {
        \ 'repo': {
        \   'owner': m[1],
        \   'name': m[2],
        \ },
        \ 'number':  m[3],
        \ 'url': printf('https://github.com/%s/%s/issues/%s', m[1], m[2], m[3]),
        \ }

  call gh#gh#init_buffer()
  call gh#gh#set_message_buf('loading')

  call gh#github#issues#issue(b:gh_issue.repo.owner, b:gh_issue.repo.name, b:gh_issue.number)
        \.then(function('s:set_issues_body'))
        \.then({-> gh#map#apply('gh-buffer-issue-edit', b:gh_issues_edit_bufid)})
        \.catch({err -> execute('call gh#gh#set_message_buf(err.body)', '')})
endfunction

function! gh#issues#comments() abort
  setlocal ft=gh-issue-comments
  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/issues/\(.*\)/comments?*\(.*\)')

  let b:gh_issues_comments_bufid = bufnr()

  let param = gh#http#decode_param(m[4])
  if !has_key(param, 'page')
    let param['page'] = 1
  endif

  let b:gh_comment_list = {
        \ 'repo': {
        \   'owner': m[1],
        \   'name': m[2],
        \ },
        \ 'number':  m[3],
        \ 'param': param,
        \ }

  call gh#gh#init_buffer()
  call gh#gh#set_message_buf('loading')

  nnoremap <buffer> <silent> <Plug>(gh_issue_comment_new) :<C-u>call <SID>issue_comment_new()<CR>
  nnoremap <buffer> <silent> <Plug>(gh_issue_comment_edit) :<C-u>call <SID>issue_comment_edit()<CR>
  nmap <buffer> <silent> ghn <Plug>(gh_issue_comment_new)
  nmap <buffer> <silent> ghe <Plug>(gh_issue_comment_edit)

  call gh#github#issues#comments(b:gh_comment_list.repo.owner, b:gh_comment_list.repo.name, b:gh_comment_list.number, b:gh_comment_list.param)
        \.then(function('s:set_issue_comments_body'))
        \.then({-> gh#map#apply('gh-buffer-issue-comment-list', b:gh_issues_comments_bufid)})
        \.catch({err -> execute('call gh#gh#set_message_buf(has_key(err, "body") ? err.body : err)', '')})
        \.finally(function('gh#gh#global_buf_settings'))
endfunction

function! s:get_selected_comments() abort
  let comments = gh#provider#list#get_marked()
  if empty(comments)
    return [gh#provider#list#current()]
  endif
  return comments
endfunction

function! s:issue_comment_url_yank() abort
  let urls = []
  for comment in s:get_selected_comments()
    call add(urls, comment.url)
  endfor

  call gh#provider#list#clean_marked()
  call gh#provider#list#redraw()

  call gh#gh#yank(urls)
endfunction

function! s:issue_comment_open_browser() abort
  for comment in s:get_selected_comments()
    call gh#gh#open_url(comment.url)
  endfor
  call gh#provider#list#clean_marked()
  call gh#provider#list#redraw()
endfunction

function! s:set_issue_comments_body(resp) abort
  let list = {
        \ 'bufname': printf('gh://%s/%s/issues/%d/comments', b:gh_comment_list.repo.owner, b:gh_comment_list.repo.name, b:gh_comment_list.number),
        \ 'param': b:gh_comment_list.param
        \ }

  if empty(a:resp.body)
    let list['data'] = []
    call gh#gh#set_message_buf('not found issue comments')
    call gh#provider#list#open(list)
    return
  endif

  " cache issue comments
  let s:gh_issue_comment = []
  for comment in a:resp.body
    call add(s:gh_issue_comment, {
        \ 'id': printf('#%d', comment.id),
        \ 'user': printf('@%s', comment.user.login),
        \ 'head': split(comment.body, '\r\?\n')[0] .. '...',
        \ 'body': split(comment.body, '\r\?\n'),
        \ 'url': comment.html_url,
        \ })
  endfor

  let header = [
        \ 'id',
        \ 'user',
        \ 'head',
        \ ]

  let list['header'] = header
  let list['data'] = s:gh_issue_comment

  call gh#provider#list#open(list)

  nnoremap <buffer> <silent> <Plug>(gh_issue_comment_open_browser) :<C-u>call <SID>issue_comment_open_browser()<CR>
  nnoremap <buffer> <silent> <Plug>(gh_issue_comment_url_yank) :<C-u>call <SID>issue_comment_url_yank()<CR>
  nmap <buffer> <silent> <C-o> <Plug>(gh_issue_comment_open_browser)
  nmap <buffer> <silent> ghy <Plug>(gh_issue_comment_url_yank)

  call gh#provider#preview#open(function('s:get_comment_preview_info'))
  normal ghp
endfunction

function! s:get_comment_from_cache(id) abort
  if has_key(s:, 'gh_issue_comment')
    for comment in s:gh_issue_comment
      if comment.id[1:] is# a:id
        return comment
      endif
    endfor
  endif
  return {}
endfunction

function! s:get_comment_preview_info() abort
  let current = gh#provider#list#current()
  if !empty(current)
    return {
          \ 'filename': 'comment.md',
          \ 'contents': current.body,
          \ }
  endif
  return {
        \ 'filename': '',
        \ 'contents': [],
        \ }
endfunction

function! s:issue_comment_new() abort
  let open = gh#gh#decide_open()
  if empty(open)
    return
  endif
  call execute(printf('%s gh://%s/%s/issues/%d/comments/new',
        \ open, b:gh_comment_list.repo.owner, b:gh_comment_list.repo.name, b:gh_comment_list.number))
endfunction

let s:comment_bufid_with_comment_id = {}

function! s:issue_comment_edit() abort
  let open = gh#gh#decide_open()
  if empty(open)
    return
  endif

  let winid = win_getid()

  let comment = gh#provider#list#current()
  " remove `#`
  let id = comment.id[1:]
  call execute(printf('%s gh://%s/%s/issues/%s/comments/%d',
        \ open, b:gh_comment_list.repo.owner, b:gh_comment_list.repo.name, b:gh_comment_list.number, id))

  let s:comment_bufid_with_comment_id[bufnr()] = winid
endfunction

function! gh#issues#comment_edit() abort
  call gh#gh#init_buffer()

  setlocal ft=markdown
  setlocal buftype=acwrite

  let b:gh_issues_comment_edit_bufid = bufnr()
  call gh#map#apply('gh-buffer-issue-comment-edit', b:gh_issues_comment_edit_bufid)

  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/issues/\(.*\)/comments/\(.*\)')

  call s:get_issue_comment(m[1], m[2], m[4])
        \.then({comment -> s:set_issue_comment_body(comment)})
        \.catch({err -> execute('call gh#gh#error_message(err)', '')})
endfunction

function! s:get_issue_comment(owner, repo, comment_id) abort
  let comment = s:get_comment_from_cache(a:comment_id)
  if !empty(comment)
    return s:Promise.resolve(comment)
  endif
  return gh#github#issues#comment(a:owner, a:repo, a:comment_id)
        \.then({resp -> resp.body})
        \.then({comment -> {
        \ 'id': printf('#%d', comment.id),
        \ 'user': printf('@%s', comment.user.login),
        \ 'head': split(comment.body, '\r\?\n')[0] .. '...',
        \ 'body': split(comment.body, '\r\?\n'),
        \ 'url': comment.html_url,
        \ }})
endfunction

function! s:set_issue_comment_body(comment) abort
  call setline(1, a:comment.body)

  setlocal nomodified
  nnoremap <buffer> <silent> q :q<CR>

  augroup gh-issue-comment-update
    au!
    au BufWriteCmd <buffer> call s:update_issue_comment()
  augroup END
endfunction

function! s:update_issue_comment() abort
  let body = getline(1, '$')
  if empty(body)
    call gh#gh#error_message('required body')
    return
  endif

  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/issues/\(.*\)/comments/\(.*\)')
  let owner = m[1]
  let repo = m[2]
  let comment_id = m[4]

  let data = {
        \ 'body': join(body, "\r\n"),
        \ }

  call gh#gh#message('comment updating...')

  call gh#github#issues#comment_update(owner, repo, comment_id, data)
        \.then(function('s:update_issue_comment_success'))
        \.catch({err -> execute('call gh#gh#error_message(err.body)', '')})
endfunction

function! s:update_issue_comment_success(resp) abort
  let bufid = bufnr()
  setlocal nomodified
  " if open edit buffer from comment list
  " then s:comment_bufid_with_comment_id would have comment list's winid and bufid
  if exists('s:comment_bufid_with_comment_id[bufid]')
    let winid = s:comment_bufid_with_comment_id[bufid]
    let oldid = win_getid()
    noau call win_gotoid(winid)
    let comment = gh#provider#list#current()
    let comment.body = split(a:resp.body.body, '\r\?\n')
    noau call win_gotoid(oldid)
  endif
  redraw!
  call gh#gh#message('update success')
endfunction

function! gh#issues#comment_new() abort
  let b:gh_issues_comment_new_bufid = bufnr()

  call gh#gh#init_buffer()

  setlocal ft=markdown
  setlocal buftype=acwrite

  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/issues/\(.*\)/comments/new$')
  let s:comment_new = {
        \ 'owner': m[1],
        \ 'name': m[2],
        \ 'issue': {
        \   'number': m[3],
        \ },
        \ }

  augroup gh-issue-comment-create
    au!
    au BufWriteCmd <buffer> call s:create_issue_comment()
  augroup END
  call gh#map#apply('gh-buffer-issue-comment-new', b:gh_issues_comment_new_bufid)
endfunction

function! s:create_issue_comment() abort
  call gh#gh#message('comment creating...')
  let data = {
        \ 'body': join(getline(1, '$'), "\r\n"),
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
  call gh#gh#delete_buffer(b:, 'gh_issues_comment_new_bufid')
  call gh#gh#message(printf('new comment: %s', a:resp.body.html_url))
endfunction
