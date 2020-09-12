" github
" Author: skanehira
" License: MIT

function! gh#github#pulls#list(owner, repo) abort
  return gh#http#get(printf('https://api.github.com/repos/%s/%s/pulls', a:owner, a:repo))
endfunction

function! gh#github#pulls#diff(owner, repo, number) abort
  let settings = #{
        \ url: printf('https://api.github.com/repos/%s/%s/pulls/%s', a:owner, a:repo, a:number),
        \ headers: #{
        \   accept: 'application/vnd.github.v3.diff',
        \ }
        \ }
  return gh#http#request(settings)
endfunction
