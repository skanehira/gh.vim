" gh
" Author: skanehira
" License: MIT

function! gh#error(msg) abort
  echohl ErrorMsg
  echom '[gh.vim] ' . a:msg
  echohl None
endfunction

function! s:pulls(data) abort
  let lines = []
  for pr in a:data.body
    call add(lines, printf("%s\t%s\t%s\t%s", pr.number, pr.state, pr.title, pr.user.login))
  endfor
  if len(lines) is# 0
    call setline(1, '-- no data --')
  else
    call setline(1, lines)
  endif
  setlocal nomodifiable
endfunction

function! s:pull_list() abort
  setlocal buftype=nofile
  setlocal number!
  nnoremap <buffer> <silent> q :bw!<CR>

  let name = split(bufname(), '\/')
  let owner = name[3]
  let repo = name[4]

  call gh#github#pulls(owner, repo)
        \.then(function('s:pulls'))
        \.catch(function('gh#error'))
endfunction

augroup gh-pulls
  au!
  au BufReadCmd gh://pull-list/*/* call s:pull_list()
augroup END
