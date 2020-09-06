" gh
" Author: skanehira
" License: MIT

function! gh#error(msg) abort
  echohl ErrorMsg
  echom '[gh.vim] ' . a:msg
  echohl None
endfunction
