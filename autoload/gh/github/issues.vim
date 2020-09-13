" github
" Author: skanehira
" License: MIT

function! gh#github#issues#list(owner, repo) abort
  return gh#http#get(printf('https://api.github.com/repos/%s/%s/issues', a:owner, a:repo))
endfunction

function! gh#github#issues#new(owner, repo, data) abort
  let settings = #{
        \ method: 'POST',
        \ url: printf('https://api.github.com/repos/%s/%s/issues', a:owner, a:repo),
        \ data: a:data,
        \ }
  return gh#http#request(settings)
endfunction
