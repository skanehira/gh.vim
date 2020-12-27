" gists
" Author: skanehira
" License: MIT

function! gh#gists#list() abort
  setlocal ft=gh-gists
  let b:gh_gists_list_bufid = bufnr()

  call gh#gh#init_buffer()
  call gh#gh#set_message_buf('loading')

  let m = matchlist(bufname(), 'gh://\(.*\)/gists')
  let b:gh_gist_list = {
        \ 'owner': m[1],
        \ }

  call gh#github#gists#list(b:gh_gist_list.owner)
        \.then({gists -> s:set_gists_list(gists)})
        \.then({-> gh#map#apply('gh-buffer-gist-list', b:gh_gists_list_bufid)})
        \.catch({err -> execute('call gh#gh#error_message(err.body)', '')})
        \.finally(function('gh#gh#global_buf_settings'))
endfunction

function! s:set_gists_list(gists) abort
  if empty(a:gists)
    call gh#gh#set_message_buf('not found any actions')
    return
  endif

  let b:gh_gist_tree = {
        \ 'id': 1,
        \ 'name': b:gh_gist_list.owner,
        \ 'state': 'open',
        \ 'path': b:gh_gist_list.owner,
        \ 'markable': 0,
        \ 'type': 'root',
        \ 'children': []
        \ }

  call s:make_tree(a:gists)

  call gh#provider#tree#open(b:gh_gist_tree)
  call gh#provider#preview#open(s:get_preview_info(), function('s:preview_update'))
endfunction

function! s:preview_update() abort
  call gh#provider#preview#update(s:get_preview_info())
endfunction

function! s:get_preview_info() abort
  let current = gh#provider#tree#current_node()
  if current.type is# 'file'
    return {
          \ 'filename': current.info.name,
          \ 'contents': current.info.text,
          \ }
  endif
  return {
        \ 'filename': '',
        \ 'contents': [],
        \ }
endfunction

function! s:make_tree(gists) abort
  for gist in a:gists
    let name = empty(gist.description) ? gist.files[0].name : gist.description

    let node = {
          \ 'name': name,
          \ 'path': printf('%s/%s', b:gh_gist_list.owner, gist.name),
          \ 'markable': 1,
          \ 'info': gist,
          \ }

    if len(gist.files) > 1
      let node['state'] = 'open'
      let node['children'] = []
      let node['type'] = 'node'

      for f in gist.files
        let f.text = split(f.text, '\r\?\n')
        call add(node['children'], {
              \ 'name': f.name,
              \ 'path': printf('%s/%s', node.path, f.name),
              \ 'markable': 0,
              \ 'type': 'file',
              \ 'info': f,
              \ })
      endfor
    else
      let node['type'] = 'file'
      let gist.files[0].text = split(gist.files[0].text, '\r\?\n')
      let node['info'] = gist.files[0]
    endif

    call add(b:gh_gist_tree.children, node)
  endfor
endfunction
