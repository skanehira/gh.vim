" github
" Author: skanehira
" License: MIT

function! gh#github#pulls(owner, repo) abort
  return gh#http#get(printf('https://api.github.com/repos/%s/%s/pulls', a:owner, a:repo))
endfunction

function! gh#github#pulls_diff(owner, repo, number) abort
  let settings = #{
        \ url: printf('https://api.github.com/repos/%s/%s/pulls/%s', a:owner, a:repo, a:number),
        \ headers: #{
        \   accept: 'application/vnd.github.v3.diff',
        \ }
        \ }
  return gh#http#request(settings)
endfunction

function! gh#github#issues(owner, repo) abort
  return gh#http#get(printf('https://api.github.com/repos/%s/%s/issues', a:owner, a:repo))
endfunction

function! gh#github#repos(owner) abort
  return gh#http#get(printf('https://api.github.com/users/%s/repos', a:owner))
endfunction

function! gh#github#repo_readme(owner, repo) abort
  return gh#http#get(printf('https://raw.githubusercontent.com/%s/%s/master/README.md', a:owner, a:repo))
endfunction
