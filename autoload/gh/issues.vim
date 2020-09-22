" gh
" Author: skanehira
" License: MIT

function! s:issue_open_on_list() abort
  call gh#gh#open_url(s:issues[line('.') -1].url)
endfunction

function! s:edit_issue() abort
  call gh#gh#delete_tabpage_buffer('gh_issues_edit_bufid')
  let number = s:issues[line('.')-1].number
  call execute(printf('belowright vnew gh://%s/%s/issues/%s',
        \ s:issue_list.repo.owner, s:issue_list.repo.name, number))
endfunction

function! s:issue_list(resp) abort
  nnoremap <buffer> <silent> <C-l> :call <SID>issue_list_change_page('+')<CR>
  nnoremap <buffer> <silent> <C-h> :call <SID>issue_list_change_page('-')<CR>

  if empty(a:resp.body)
    call gh#gh#set_message_buf('not found issues')
    return
  endif

  let s:issues = []
  let lines = []
  let url = printf('https://github.com/%s/%s/issues/', s:issue_list.repo.owner, s:issue_list.repo.name)

  for issue in a:resp.body
    if !has_key(issue, 'pull_request')
      call add(lines, printf("%s\t%s\t%s\t%s", issue.number, issue.state, issue.title, issue.user.login))
      call add(s:issues, #{
            \ number: issue.number,
            \ body: split(issue.body, '\r\?\n'),
            \ url: url . issue.number, 
            \ })
    endif
  endfor
  call setline(1, lines)
  nnoremap <buffer> <silent> o :call <SID>issue_open_on_list()<CR>
  nnoremap <buffer> <silent> e :call <SID>edit_issue()<CR>
  nnoremap <buffer> <silent> ghc :call <SID>issue_close()<CR>
  nnoremap <buffer> <silent> gho :call <SID>issue_open()<CR>
  call setbufline(t:gh_issues_list_bufid, 1, lines)
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
  call gh#gh#delete_tabpage_buffer('gh_issues_list_bufid')
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
  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/issues?*\(.*\)')

  call gh#gh#delete_tabpage_buffer('gh_issues_list_bufid')
  let t:gh_issues_list_bufid = bufnr()

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

  let t:gh_issues_new_bufid = bufnr()
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
  call gh#gh#message(printf('create success: %s', a:resp.body.html_url))
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
  call setbufline(t:gh_issues_new_bufid, 1, map(copy(a:files), {_, v -> v.file}))
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

function! s:open_issue() abort
  call gh#gh#open_url(s:issue.url)
endfunction

function! s:set_issues_body(resp) abort
  let s:issue['title'] = a:resp.body.title
  call setbufline(t:gh_issues_edit_bufid, 1, split(a:resp.body.body, '\r\?\n'))
  setlocal nomodified buftype=acwrite ft=markdown

  nnoremap <buffer> <silent> <C-o> :call <SID>open_issue()<CR>
  nnoremap <buffer> <silent> q :bw<CR>

  augroup gh-update-issue
    au!
    au BufWriteCmd <buffer> call s:update_issue()
  augroup END
endfunction

function! gh#issues#issue() abort
  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/issues/\(.*\)$')

  call gh#gh#delete_tabpage_buffer('gh_issues_edit_bufid')
  let t:gh_issues_edit_bufid = bufnr()

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
        \.catch({err -> execute('call gh#gh#set_message_buf(err.body)', '')})
endfunction
