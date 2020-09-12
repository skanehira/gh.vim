" github
" Author: skanehira
" License: MIT

function! gh#github#issues#list(owner, repo) abort
  return gh#http#get(printf('https://api.github.com/repos/%s/%s/issues', a:owner, a:repo))
endfunction
