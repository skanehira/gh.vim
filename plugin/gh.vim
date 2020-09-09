" gh
" Author: skanehira
" License: MIT

if exists('loaded_gh')
  finish
endif
let g:loaded_gh = 1

augroup gh
  au!
  au BufDelete gh://*/*/issues if has_key(t:, 'gh_preview_bufid') && bufexists(t:gh_preview_bufid) |
        \ call execute('bw '. t:gh_preview_bufid) |
        \ endif
  au BufReadCmd gh://*/*/issues call gh#issues#list()
  au BufReadCmd gh://*/*/pulls call gh#pulls#list()
  au BufDelete gh://*/*/pulls if has_key(t:, 'gh_preview_diff_bufid') && bufexists(t:gh_preview_diff_bufid) |
        \ call execute('bw '. t:gh_preview_diff_bufid) |
        \ let t:gh_preview_diff_bufid = '' |
        \ endif
  au BufReadCmd gh://*/*/pulls/*/diff call gh#pulls#diff()
augroup END
