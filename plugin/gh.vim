" gh
" Author: skanehira
" License: MIT

if exists('loaded_gh')
  finish
endif
let g:loaded_gh = 1

command! -nargs=1 GhPulls call gh#gh#pulls(<f-args>)
