" github
" Author: skanehira
" License: MIT

function! gh#github#pulls(owner, repo) abort
  let url = printf('https://api.github.com/repos/%s/%s/pulls', a:owner, a:repo)
  return gh#http#get(url)
endfunction
