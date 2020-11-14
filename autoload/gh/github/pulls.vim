" github
" Author: skanehira
" License: MIT

function! gh#github#pulls#list(owner, repo, param) abort
  let settings = {
        \ 'method': 'GET',
        \ 'url': printf('https://api.github.com/repos/%s/%s/pulls', a:owner, a:repo),
        \ 'param': a:param,
        \ }
  return gh#http#request(settings)
endfunction

function! gh#github#pulls#diff(owner, repo, number) abort
  let settings = {
        \ 'url': printf('https://api.github.com/repos/%s/%s/pulls/%s', a:owner, a:repo, a:number),
        \ 'headers': {
        \   'accept': 'application/vnd.github.v3.diff',
        \ }
        \ }
  return gh#http#request(settings)
endfunction
