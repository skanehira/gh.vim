" gh
" Author: skanehira
" License: MIT

if exists('loaded_gh')
  finish
endif
let g:loaded_gh = 1

augroup gh
  au!
  au BufDelete gh://*/*/issues call execute('bw '. t:preview_bufid)
  au BufDelete gh://*/*/pulls call execute('bw '. t:gh_preview_diff_bufid)
  au BufReadCmd gh://*/*/issues call gh#gh#issues()
  au BufReadCmd gh://*/*/pulls call gh#gh#pulls()
  au BufReadCmd gh://*/*/pulls/*/diff call gh#gh#pull_diff()
augroup END
