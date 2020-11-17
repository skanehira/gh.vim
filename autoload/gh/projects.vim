" projects
" Author: skanehira
" License: MIT


function! gh#projects#user() abort
  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/projects?*\(.*\)')
  let param = gh#http#decode_param(m[3])
  if !has_key(param, 'page')
    let param['page'] = 1
  endif

  let auth = {'owner': m[1], 'repo': m[2]}

  call s:get_project_list('user', auth, param)
endfunction

function! gh#projects#org() abort
  let m = matchlist(bufname(), 'gh://orgs/\(.*\)/projects?*\(.*\)')
  let param = gh#http#decode_param(m[2])
  if !has_key(param, 'page')
    let param['page'] = 1
  endif

  let auth = {'org': m[1]}

  call s:get_project_list('org', auth, param)
endfunction

function! s:get_project_list(type, auth, param) abort
  setlocal ft=gh-projects

  call gh#gh#delete_buffer(s:, 'gh_project_list_bufid')
  let s:gh_project_list_bufid = bufnr()

  let s:project_list = {
        \ 'type': a:type,
        \ 'auth': a:auth,
        \ 'param': a:param,
        \ }

  call gh#gh#init_buffer()
  call gh#gh#set_message_buf('loading')

  call gh#github#projects#list(a:type, a:auth, a:param)
        \.then(function('s:set_project_list_result'))
        \.then({-> execute("call gh#map#apply('gh-buffer-project-list')")})
        \.catch({err -> execute('call gh#gh#error_message(err.body)', '')})
        \.finally(function('gh#gh#global_buf_settings'))
endfunction

function! s:set_project_list_result(resp) abort
  if empty(a:resp.body)
    call gh#gh#set_message_buf('not found projects')
    return
  endif

  let s:projects = []
  let lines = []

  let dict = map(copy(a:resp.body), {_, v -> {
        \ 'number': printf('#%d', v.number),
        \ 'state': v.state,
        \ 'name': v.name,
        \ 'url': v.html_url,
        \ }})
  let format = gh#gh#dict_format(dict, ['number', 'state', 'name'])

  for project in a:resp.body
    call add(lines, printf(format,
          \ printf('#%d', project.number), project.state, project.name))
    call add(s:projects, {
          \ 'number': project.number,
          \ 'state': project.state,
          \ 'name': project.name,
          \ 'url': project.url,
          \ })
  endfor

  call setbufline(s:gh_project_list_bufid, 1, lines)
endfunction
