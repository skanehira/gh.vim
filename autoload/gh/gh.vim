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
  call system("xdg-open " . url)
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
  call execute(printf('vnew gh://%s/%s/pulls/%s/diff', m[1], m[2], number))
endfunction

function! s:set_diff_contents(resp) abort
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

function! s:issues(resp) abort
  let lines = []
  for issue in a:resp.body
    call add(lines, printf("%s\t%s\t%s\t%s", issue.number, issue.state, issue.title, issue.user.login))
  endfor

  if len(lines) is# 0
    call setline(1, '-- no data --')
  else
    call setline(1, lines)
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
