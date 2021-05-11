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

function! gh#github#pulls#pull(owner, repo, number) abort
  let url = printf('https://api.github.com/repos/%s/%s/pulls/%s', a:owner, a:repo, a:number)
  return gh#http#get(url)
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

function! gh#github#pulls#merge(owner, repo, number, data) abort
  let settings = {
        \ 'method': 'PUT',
        \ 'url': printf('https://api.github.com/repos/%s/%s/pulls/%s/merge', a:owner, a:repo, a:number),
        \ 'data': a:data,
        \ }
  return gh#http#request(settings)
endfunction

function! gh#github#pulls#files(owner, repo, number) abort
  let url = printf('https://api.github.com/repos/%s/%s/pulls/%s/files', a:owner, a:repo, a:number)
  return gh#http#get(url)
endfunction
