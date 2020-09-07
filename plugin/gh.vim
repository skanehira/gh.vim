" gh
" Author: skanehira
" License: MIT

if exists('loaded_gh')
  finish
endif
let g:loaded_gh = 1

augroup gh
  au!
  au BufReadCmd gh://*/*/pulls call gh#gh#pulls()
  au BufReadCmd gh://*/*/pulls/*/diff call gh#gh#pull_diff()
augroup END
