" actions
" Author: skanehira
" License: MIT

function! gh#github#actions#list(owner, repo, param) abort
  let settings = {
        \ 'method': 'GET',
        \ 'url': printf('https://api.github.com/repos/%s/%s/actions/runs', a:owner, a:repo),
        \ 'param': a:param,
        \ }
  return gh#http#request(settings)
endfunction
