" gh
" Author: skanehira
" License: MIT

function! s:issue_open_on_list() abort
  call gh#gh#open_url(s:issues[line('.') -1].url)
endfunction

function! s:edit_issue() abort
  let number = s:issues[line('.')-1].number
  call execute(printf('belowright vnew gh://%s/%s/issues/%s', s:repo.owner, s:repo.name, number))
endfunction

function! s:issues(resp) abort
  if empty(a:resp.body)
    call gh#gh#error('no found issues')
    return
  endif

  let s:issues = []
  let lines = []
  for issue in a:resp.body
    if !has_key(issue, 'pull_request')
      call add(lines, printf("%s\t%s\t%s\t%s", issue.number, issue.state, issue.title, issue.user.login))
      call add(s:issues, #{
            \ number: issue.number,
            \ body: split(issue.body, '\r\?\n'),
            \ url: printf('https://github.com/%s/%s/issues/%s', s:repo.owner, s:repo.name, issue.number),
            \ })
    endif
  endfor

  call setline(1, lines)
  nnoremap <buffer> <silent> o :call <SID>issue_open_on_list()<CR>
  nnoremap <buffer> <silent> e :call <SID>edit_issue()<CR>
endfunction

function! gh#issues#list() abort
  call gh#gh#delete_tabpage_buffer('gh_issues_list_bufid')
  call gh#gh#delete_tabpage_buffer('gh_preview_bufid')

  let t:gh_issues_list_bufid = bufnr()

  setlocal buftype=nofile
  setlocal nonumber

  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/issues$')
  let s:repo = #{
        \ owner: m[1],
        \ name: m[2],
        \ }

  call setline(1, '-- loading --')

  call gh#github#issues#list(s:repo.owner, s:repo.name)
        \.then(function('s:issues'))
        \.catch(function('gh#gh#error'))
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

  setlocal buftype=nofile
  setlocal nonumber

  call setline(1, '-- loading --')

  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/issues/new$')
  let s:repo = #{
        \ owner: m[1],
        \ name: m[2],
        \ }

  call gh#github#repos#files(s:repo.owner, s:repo.name, 'master')
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

  call gh#github#issues#new(s:repo.owner, s:repo.name, data)
        \.then(function('s:create_issue_success'))
        \.catch({err -> execute('call gh#gh#error_message(err.body)', '')})
endfunction

function! s:create_issue_success(resp) abort
  bw!
  redraw!
  call gh#gh#message('create success')
endfunction

function! s:set_issue_template_buffer(resp) abort
  bw!
  call execute(printf('new gh://%s/%s/issues/%s', s:repo.owner, s:repo.name, s:issue_title))
  setlocal buftype=acwrite
  setlocal ft=markdown

  if !empty(a:resp.body)
    call setline(1, split(a:resp.body, '\r'))
  endif

  augroup gh-create-issue
    au!
    au BufWriteCmd <buffer> call s:create_issue()
  augroup END
endfunction

function! s:get_template() abort
  let url = s:files[line('.')-1].url
  call gh#github#repos#get_file(url)
        \.then(function('s:set_issue_template_buffer'))
        \.catch({err -> execute('%d_ | call setline(1, err.body)', '')})
endfunction

function! s:open_template_list(files) abort
  if empty(a:files)
    call s:set_issue_template_buffer(#{body: ''})
    return
  endif
  let s:files = a:files
  call setline(1, map(copy(a:files), {_, v -> v.file}))
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
        \ s:repo.owner, s:repo.name, v.path)}})
  return files
endfunction

function! s:update_issue_success(resp) abort
  bw!
  redraw!
  call gh#gh#message('update success')
endfunction

function! s:update_issue() abort
  if &modified is# 0
    return
  endif
  call gh#gh#message('issue updating...')
  let data = #{
        \ body: join(getline(1, '$'), "\r\n"),
        \ }

  call gh#github#issues#update(s:repo.owner, s:repo.name, s:repo.issue.number, data)
        \.then(function('s:update_issue_success'))
        \.catch({err -> execute('call gh#gh#error_message(err.body)', '')})
endfunction

function! s:open_issue() abort
  call gh#gh#open_url(s:repo.issue.url)
endfunction

function! s:set_issues_body(resp) abort
  call setline(1, split(a:resp.body.body, '\r\?\n'))
  setlocal nomodified
  setlocal buftype=acwrite bufhidden=wipe
  setlocal noswapfile nobuflisted
  setlocal ft=markdown

  nnoremap <buffer> <silent> <C-o> :call <SID>open_issue()<CR>
  nnoremap <buffer> <silent> q :bw<CR>

  augroup gh-update-issue
    au!
    au BufWriteCmd <buffer> call s:update_issue()
  augroup END
endfunction

function! gh#issues#issue() abort
  if bufexists(t:gh_issues_edit_bufid)
    call execute('bw ' . t:gh_issues_edit_bufid)
  endif
  let t:gh_issues_edit_bufid = bufnr()

  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/issues/\(.*\)$')
  let s:repo = #{
        \ owner: m[1],
        \ name: m[2],
        \ issue: #{
        \   number:  m[3],
        \   url: printf('https://github.com/%s/%s/issues/%s', m[1], m[2], m[3]),
        \ },
        \ }

  call setline(1, '-- loading --')
  call gh#github#issues#issue(s:repo.owner, s:repo.name, s:repo.issue.number)
        \.then(function('s:set_issues_body'))
        \.catch(function('gh#gh#error'))
endfunction
