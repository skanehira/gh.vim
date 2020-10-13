" gh
" Author: skanehira
" License: MIT

if exists('loaded_gh')
  finish
endif
let g:loaded_gh = 1

augroup gh
  au!
  au BufReadCmd gh://* call gh#gh#init()
  au ColorScheme * call gh#gh#def_highlight()
augroup END

call gh#gh#def_highlight()
call gh#map#init()
