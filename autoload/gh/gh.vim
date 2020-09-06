" gh
" Author: skanehira
" License: MIT

function! gh#error(msg) abort
  echohl ErrorMsg
  echom '[gh.vim] ' . a:msg
  echohl None
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
  setlocal nomodifiable
endfunction

function! s:pull_open() abort
  let line = getline('.')
  let number = split(line, "\t")[0]
  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/pulls$')
  let url = printf('https://github.com/%s/%s/pull/%s', m[1], m[2], number)
  call system("xdg-open " . url)
endfunction

function! s:pull_list() abort
  setlocal buftype=nofile
  setlocal nonumber

  nnoremap <buffer> <silent> q :bw!<CR>
  nnoremap <buffer> <silent> o :call <SID>pull_open()<CR>
  nnoremap <buffer> <silent> dd :call <SID>open_pull_diff()<CR>

  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/pulls$')

  call gh#github#pulls(m[1], m[2])
        \.then(function('s:pulls'))
        \.catch(function('gh#error'))
endfunction

function! s:set_pull_diff(resp) abort
  call setline(1, split(a:resp.body, "\r"))
  setlocal nomodifiable
endfunction

function! s:open_pull_diff() abort
  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/pulls$')
  let number = split(getline('.'), "\t")[0]
  call execute(printf('vnew gh://%s/%s/pulls/%s/diff', m[1], m[2], number))
endfunction

function! s:pull_diff() abort
  setlocal buftype=nofile
  setlocal ft=diff
  setlocal nonumber

  nnoremap <buffer> <silent> q :bw!<CR>

  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/pulls/\(.*\)/diff$')

  call gh#github#pulls_diff(m[1], m[2], m[3])
        \.then(function('s:set_pull_diff'))
        \.catch(function('gh#error'))
endfunction

augroup gh-pulls
  au!
  au BufReadCmd gh://*/*/pulls call s:pull_list()
  au BufReadCmd gh://*/*/pulls/*/diff call s:pull_diff()
augroup END
