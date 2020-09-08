" gh
" Author: skanehira
" License: MIT

function! s:error(msg) abort
  call setline(1, printf('-- %s --', a:msg))
endfunction

function! s:do_finally() abort
  setlocal nomodifiable
  nnoremap <buffer> <silent> q :bw!<CR>
  setlocal cursorline
  setlocal cursorlineopt=line
  setlocal nowrap
endfunction

function! s:open_url(url) abort
  let cmd = 'open'
  if has('linux')
    let cmd = 'xdg-open'
  endif
  call system(printf('%s %s', cmd, a:url))
endfunction

function! s:pulls(resp) abort
  let lines = []
  for pr in a:resp.body
    call add(lines, printf("%s\t%s\t%s\t%s", pr.number, pr.state, pr.title, pr.user.login))
  endfor

  if len(lines) is# 0
    call setline(1, '-- no data --')
  else
    call setline(1, lines)
  endif

  nnoremap <buffer> <silent> o :call <SID>pull_open()<CR>
  nnoremap <buffer> <silent> dd :call <SID>open_pull_diff()<CR>
endfunction

function! s:pull_open() abort
  let line = getline('.')
  let number = split(line, "\t")[0]
  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/pulls$')
  let url = printf('https://github.com/%s/%s/pull/%s', m[1], m[2], number)
  call s:open_url(url)
endfunction

function! gh#gh#pulls() abort
  setlocal buftype=nofile
  setlocal nonumber

  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/pulls$')

  call setline(1, '-- loading --')

  call gh#github#pulls(m[1], m[2])
        \.then(function('s:pulls'))
        \.catch(function('s:error'))
        \.finally(function('s:do_finally'))
endfunction

function! s:open_pull_diff() abort
  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/pulls$')
  let number = split(getline('.'), "\t")[0]
  call execute(printf('belowright vnew gh://%s/%s/pulls/%s/diff', m[1], m[2], number))
endfunction

function! s:set_diff_contents(resp) abort
  let t:gh_preview_diff_bufid = bufnr()
  call setline(1, split(a:resp.body, "\r")) 
  setlocal ft=diff
endfunction

function! gh#gh#pull_diff() abort
  setlocal buftype=nofile
  setlocal nonumber

  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/pulls/\(.*\)/diff$')

  call setline(1, '-- loading --')

  call gh#github#pulls_diff(m[1], m[2], m[3])
        \.then(function('s:set_diff_contents'))
        \.catch(function('s:error'))
        \.finally(function('s:do_finally'))
endfunction

function! s:issue_preview() abort
  call win_execute(s:preview_winid, '%d_')
  let number = split(getline('.'), "\t")[0]
  call setbufline(t:preview_bufid, 1, split(s:issues[number].body, '\r\?\n'))
endfunction

function! s:open_issue_preview() abort
  let winid = win_getid()
  belowright vnew gh://issues/preview
  setlocal buftype=nofile

  let t:preview_bufid = bufnr()
  let s:preview_winid = win_getid()

  call win_gotoid(winid)

  augroup gh-preview
    au!
    autocmd CursorMoved <buffer> call s:issue_preview()
  augroup END

  call s:issue_preview()
endfunction

function! s:issue_open() abort
  let line = getline('.')
  let number = split(line, "\t")[0]
  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/issues$')
  let url = printf('https://github.com/%s/%s/issues/%s', m[1], m[2], number)
  call s:open_url(url)
endfunction

function! s:issues(resp) abort
  let s:issues = {}
  let lines = []
  for issue in a:resp.body
    if !has_key(issue, 'pull_request')
      call add(lines, printf("%s\t%s\t%s\t%s", issue.number, issue.state, issue.title, issue.user.login))
      let s:issues[issue.number] = issue
    endif
  endfor

  if len(lines) is# 0
    call setline(1, '-- no data --')
  else
    call setline(1, lines)
    call s:open_issue_preview()
    nnoremap <buffer> <silent> o :call <SID>issue_open()<CR>
  endif
endfunction

function! gh#gh#issues() abort
  setlocal buftype=nofile
  setlocal nonumber

  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/issues$')

  call setline(1, '-- loading --')

  call gh#github#issues(m[1], m[2])
        \.then(function('s:issues'))
        \.catch(function('s:error'))
        \.finally(function('s:do_finally'))
endfunction
