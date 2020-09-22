" github
" Author: skanehira
" License: MIT

let s:Promise = vital#gh#import('Async.Promise')

function! gh#github#repos#list(owner, param) abort
  let url = printf('https://api.github.com/users/%s/repos', a:owner)
  if a:owner is# 'user'
    let url = 'https://api.github.com/user/repos'
  endif
  let settings = #{
        \ method: 'GET',
        \ url: url,
        \ param: a:param,
        \ }
  return gh#http#request(settings)
endfunction

function! gh#github#repos#files(owner, repo, branch) abort
  let settings = #{
        \ url: printf('https://api.github.com/repos/%s/%s/git/trees/%s', a:owner, a:repo, a:branch),
        \ param: #{
        \   recursive: 1,
        \ },
        \ }
  return gh#http#request(settings)
endfunction

function! gh#github#repos#get_file(url) abort
  return gh#http#get(a:url)
endfunction

function! gh#github#repos#readme(owner, repo) abort
  return gh#github#repos#files(a:owner, a:repo, 'master')
        \.then(function('s:get_readme', [a:owner, a:repo]))
endfunction

function! s:get_readme(owner, repo, resp) abort
  if !has_key(a:resp.body, 'tree')
    return s:Promise.reject(#{
        \ body: 'not found readme',
        \ })
  endif

  let files = filter(a:resp.body.tree,
        \ {_, v -> v.type is# 'blob' && (matchstr(v.path, '^README.*') is# '' ? 0 : 1)})

  if len(files) is# 0
    return s:Promise.reject(#{
        \ body: 'not found readme',
        \ })
  endif

  let url = printf('https://raw.githubusercontent.com/%s/%s/master/%s', a:owner, a:repo, files[0].path)
  return gh#http#get(url)
endfunction

function! gh#github#repos#create(data) abort
  let settings = #{
        \ method: 'POST',
        \ url: 'https://api.github.com/user/repos',
        \ data: a:data,
        \ }
  return gh#http#request(settings)
endfunction

function! gh#github#repos#delete(full_name) abort
  let settings = #{
        \ method: 'DELETE',
        \ url: printf('https://api.github.com/repos/%s', a:full_name),
        \ }
  return gh#http#request(settings)
endfunction
