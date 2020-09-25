" gh
" Author: skanehira
" License: MIT

if exists('loaded_gh')
  finish
endif
let g:loaded_gh = 1

for var in ['gh_preview_diff_bufid', 'gh_repo_list_bufid',
      \ 'gh_repo_readme_bufid', 'gh_issues_list_bufid',
      \ 'gh_pulls_list_bufid', 'gh_issues_edit_bufid',
      \ 'gh_repo_new_bufid', 'gh_issues_new_bufid',
      \ 'gh_issues_comments_bufid', 'gh_issues_comment_edit_bufid',
      \ ]
  let t:[var] = ''
endfor

augroup gh
  au!
  au BufReadCmd gh://user/repos/new call gh#repos#new()
  au BufReadCmd gh://*/repos call gh#repos#list()
  au BufReadCmd gh://*/repos\?* call gh#repos#list()
  au BufReadCmd gh://*/*/readme call gh#repos#readme()
  au BufReadCmd gh://*/*/issues call gh#issues#list()
  au BufReadCmd gh://*/*/issues\?* call gh#issues#list()
  au BufReadCmd gh://*/*/issues/*/comments call gh#issues#comments()
  au BufReadCmd gh://*/*/issues/*/comments\?* call gh#issues#comments()
  au BufReadCmd gh://*/*/issues/new call gh#issues#new()
  au BufReadCmd gh://*/*/issues/[0-9]*$ call gh#issues#issue()
  au BufReadCmd gh://*/*/pulls call gh#pulls#list()
  au BufReadCmd gh://*/*/pulls\?* call gh#pulls#list()
  au BufDelete gh://*/*/pulls if bufexists(t:gh_preview_diff_bufid) |
        \ call execute('bw '. t:gh_preview_diff_bufid) |
        \ let t:gh_preview_diff_bufid = '' |
        \ endif
  au BufReadCmd gh://*/*/pulls/*/diff call gh#pulls#diff()
augroup END
