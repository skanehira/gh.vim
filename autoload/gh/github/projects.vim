" projects
" Author: skanehira
" License: MIT

function! gh#github#projects#list(type, user_info, param) abort
  let settings = {
        \ 'method': 'GET',
        \ 'param': a:param
        \ }

  if a:type is# 'org'
    let settings['url'] = printf('https://api.github.com/orgs/%s/projects', a:user_info.org)
  else
    let settings['url'] = printf('https://api.github.com/repos/%s/%s/projects', a:user_info.owner, a:user_info.repo)
  endif

  return gh#http#request(settings)
endfunction

function! gh#github#projects#columns(id) abort
  let url = printf('https://api.github.com/projects/%s/columns', a:id)
  return gh#http#get(url)
endfunction

function! gh#github#projects#cards(id) abort
  let url = printf('https://api.github.com/projects/columns/%s/cards', a:id)
  return gh#http#get(url)
endfunction

function! gh#github#projects#card_moves(column_id, card_id) abort
  let settings = {
        \ 'url': printf('https://api.github.com/projects/columns/cards/%s/moves', a:card_id),
        \ 'method': 'POST',
        \ 'data': {
        \   'column_id': a:column_id,
        \   'position': 'top',
        \ },
        \ }
  return gh#http#request(settings)
endfunction
