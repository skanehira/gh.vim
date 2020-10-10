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
      \ 'gh_issues_comment_new_bufid',
      \ ]
  let t:[var] = ''
endfor

augroup gh
  au!
  au BufReadCmd gh://* call gh#gh#init()
  au ColorScheme * call gh#gh#def_highlight()
augroup END

call gh#gh#def_highlight()
call gh#map#init()
