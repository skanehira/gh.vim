" projects
" Author: skanehira
" License: MIT

function! gh#projects#list() abort
  setlocal ft=gh-projects
  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/projects?*\(.*\)')

  let param = gh#http#decode_param(m[3])
  if !has_key(param, 'page')
    let param['page'] = 1
  endif

  if m[1] is# 'orgs'
    let type = 'org'
    let user_info = {'org': m[2]}
  else
    let type = 'user'
    let user_info = {'owner': m[1], 'repo': m[2]}
  endif

  call gh#gh#delete_buffer(s:, 'gh_project_list_bufid')
  let s:gh_project_list_bufid = bufnr()

  let s:project_list = {
        \ 'type': type,
        \ 'user_info': user_info,
        \ 'param': param,
        \ }

  call gh#gh#init_buffer()
  call gh#gh#set_message_buf('loading')

  call gh#github#projects#list(type, user_info, param)
        \.then(function('s:set_project_list_result'))
        \.then({-> execute("call gh#map#apply('gh-buffer-project-list')")})
        \.catch({err -> execute('call gh#gh#error_message(err.body)', '')})
        \.finally(function('gh#gh#global_buf_settings'))
endfunction

function! s:project_open_browser() abort
  call gh#gh#open_url(s:projects[line('.') -1].url)
endfunction

function! s:project_open() abort
  let s:project = s:projects[line('.') -1]
  call execute(printf('vnew gh://projects/%d/columns', s:project.id))
endfunction

function! s:project_url_yank() abort
  let url = s:projects[line('.') -1].url
  call gh#gh#yank(url)
  call gh#gh#message('copied ' .. url)
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
        \ }})
  let format = gh#gh#dict_format(dict, ['number', 'state', 'name'])

  for project in a:resp.body
    call add(lines, printf(format,
          \ printf('#%d', project.number), project.state, project.name))
    call add(s:projects, {
          \ 'id': project.id,
          \ 'number': project.number,
          \ 'state': project.state,
          \ 'name': project.name,
          \ 'url': project.html_url,
          \ })
  endfor

  nnoremap <buffer> <silent> <Plug>(gh_project_open_browser) :<C-u>call <SID>project_open_browser()<CR>
  nnoremap <buffer> <silent> <Plug>(gh_project_url_yank) :<C-u>call <SID>project_url_yank()<CR>
  nnoremap <buffer> <silent> <Plug>(gh_project_open) :<C-u>call <SID>project_open()<CR>

  nmap <buffer> <silent> <C-o> <Plug>(gh_project_open_browser)
  nmap <buffer> <silent> <CR> <Plug>(gh_project_open)
  nmap <buffer> <silent> ghy <Plug>(gh_project_url_yank)

  call setbufline(s:gh_project_list_bufid, 1, lines)
endfunction

function! s:set_card_info(child, resp) abort
  let child = a:child
  let child['name'] = a:resp.body.title
endfunction

function! s:add_cards(node, resp) abort
  try
  if empty(a:resp.body)
    return
  endif

  let node = a:node
  let node['children'] = []
  let node['state'] = 'close'
  for card in a:resp.body
    let child = {
          \ 'id': card.id,
          \ 'path': printf('%s/%s', node.id, card.id)
          \ }

    if card.note isnot# v:null
      let child['name'] = card.note
    else
      call gh#http#get(card.content_url)
            \.then(function('s:set_card_info', [child]))
            \.catch({err -> execute('call gh#gh#error_message(err.body)', '')})
    endif

    call add(node.children, child)
  endfor
    call gh#tree#update(s:tree)
  catch
    echom v:exception
  endtry
endfunction

function! s:make_tree(tree, columns) abort
  if empty(a:columns)
    return a:tree
  endif
  let tree = a:tree

  for c in a:columns
    let column = {
          \ 'id': c.id,
          \ 'name': c.name,
          \ 'path': printf('%s/%s', tree.id, c.id)
          \ }
    call gh#github#projects#cards(column.id)
          \.then(function('s:add_cards', [column]))
          \.catch({err -> execute('call gh#gh#error_message(err.body)', '')})

    call add(tree.children, column)
  endfor
endfunction

function! s:set_project_column_list_result(resp) abort
  try
  if empty(a:resp.body)
    call gh#gh#set_message_buf('not found project columns')
    return
  endif

  let s:tree = {
        \ 'id': s:project.id,
        \ 'name': s:project.name,
        \ 'state': 'open',
        \ 'path': s:project.name,
        \ 'children': []
        \ }

  call s:make_tree(s:tree, a:resp.body)
  catch
    echom v:exception
  endtry
  call gh#tree#open(s:tree)
endfunction

function! gh#projects#columns() abort
  setlocal ft=gh-projects-columns
  let m = matchlist(bufname(), 'gh://projects/\(.*\)/columns?*\(.*\)')
  let param = gh#http#decode_param(m[2])
  if !has_key(param, 'page')
    let param['page'] = 1
  endif

  call gh#gh#delete_buffer(s:, 'gh_project_column_list_bufid')
  let s:gh_project_column_list_bufid = bufnr()

  let s:project_column_list = {
        \ 'id': m[1],
        \ 'param': param,
        \ }

  call gh#gh#init_buffer()
  call gh#gh#set_message_buf('loading')

  call gh#github#projects#columns(s:project_column_list.id)
        \.then(function('s:set_project_column_list_result'))
        \.then({-> execute("call gh#map#apply('gh-buffer-project-column-list')")})
        \.catch({err -> execute('call gh#gh#error_message(err.body)', '')})
        \.finally(function('gh#gh#global_buf_settings'))
endfunction
