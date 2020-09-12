" github
" Author: skanehira
" License: MIT

function! gh#github#repos#list(owner) abort
  return gh#http#get(printf('https://api.github.com/users/%s/repos', a:owner))
endfunction

function! gh#github#repos#readme(owner, repo) abort
  return gh#http#get(printf('https://raw.githubusercontent.com/%s/%s/master/README.md', a:owner, a:repo))
endfunction
