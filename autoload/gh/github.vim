" github
" Author: skanehira
" License: MIT

function! gh#github#pulls(owner, repo) abort
  let url = printf('https://api.github.com/repos/%s/%s/pulls', a:owner, a:repo)
  return gh#http#get(url)
endfunction

function! gh#github#pulls_diff(owner, repo, number) abort
  let url = printf('https://api.github.com/repos/%s/%s/pulls/%s', a:owner, a:repo, a:number)
  return gh#http#get(url, #{Accept: 'application/vnd.github.v3.diff'})
endfunction

function! gh#github#issues(owner, repo) abort
  let url = printf('https://api.github.com/repos/%s/%s/issues', a:owner, a:repo)
  return gh#http#get(url)
endfunction

function! gh#github#repos(owner) abort
  let url = printf('https://api.github.com/users/%s/repos', a:owner)
  return gh#http#get(url)
endfunction

function! gh#github#repo_readme(owner, repo) abort
  let url = printf('https://raw.githubusercontent.com/%s/%s/master/README.md', a:owner, a:repo)
  return gh#http#get(url)
endfunction
