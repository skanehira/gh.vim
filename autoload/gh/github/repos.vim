" github
" Author: skanehira
" License: MIT

let s:Base64 = vital#gh#import('Data.Base64')

function! gh#github#repos#list(owner, param) abort
  let url = printf('https://api.github.com/users/%s/repos', a:owner)
  if a:owner is# 'user'
    let url = 'https://api.github.com/user/repos'
  endif
  let settings = {
        \ 'method': 'GET',
        \ 'url': url,
        \ 'param': a:param,
        \ }
  return gh#http#request(settings)
endfunction

function! gh#github#repos#files(owner, repo, branch) abort
  let settings = {
        \ 'url': printf('https://api.github.com/repos/%s/%s/git/trees/%s', a:owner, a:repo, a:branch),
        \ 'param': {
        \   'recursive': 1,
        \ },
        \ }
  return gh#http#request(settings)
endfunction

function! gh#github#repos#get_file(url) abort
  return gh#http#get(a:url)
        \.then(function('s:decode_content'))
endfunction

function! gh#github#repos#readme(owner, repo) abort
  let url = printf('https://api.github.com/repos/%s/%s/readme', a:owner, a:repo)
  return gh#http#get(url)
        \.then(function('s:decode_content'))
endfunction

function! s:decode_content(resp) abort
  let body = s:Base64.decode(join(split(a:resp.body.content, "\n"), ''))
  return split(body, "\n")
endfunction

function! gh#github#repos#create(data) abort
  let settings = {
        \ 'method': 'POST',
        \ 'url': 'https://api.github.com/user/repos',
        \ 'data': a:data,
        \ }
  return gh#http#request(settings)
endfunction

function! gh#github#repos#get_repo(owner, repo) abort
  let url = printf('https://api.github.com/repos/%s/%s', a:owner, a:repo)
  let settings = {
        \ 'method': 'GET',
        \ 'url': url,
        \ }
  return gh#http#request(settings)
endfunction
