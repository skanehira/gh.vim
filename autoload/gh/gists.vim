" gists
" Author: skanehira
" License: MIT

function! gh#gists#list() abort
  setlocal ft=gh-gists
  let b:gh_gists_list_bufid = bufnr()
  let b:gh_gists_list_page_info = {
        \ 'has_next': 0,
        \ 'cursor': ''
        \ }

  call gh#gh#init_buffer()
  call gh#gh#set_message_buf('loading')

  let m = matchlist(bufname(), 'gh://\(.*\)/gists')
  let b:gh_gist_list = {
        \ 'owner': m[1],
        \ }

  call gh#github#gists#list(b:gh_gist_list.owner)
        \.then({resp -> s:set_page_info(resp)})
        \.then({resp -> s:set_gists_list(resp)})
        \.then({-> s:set_keymap()})
        \.then({-> gh#map#apply('gh-buffer-gist-list', b:gh_gists_list_bufid)})
        \.catch({err -> execute('call gh#gh#error_message(err.body)', '')})
        \.finally(function('gh#gh#global_buf_settings'))
endfunction

function! s:set_gists_list(resp) abort
  if empty(a:resp)
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

  call s:make_tree(a:resp.gists)

  call gh#provider#tree#open(b:gh_gist_tree)
  call gh#provider#preview#open(s:get_preview_info(), function('s:preview_update'))
endfunction

function! s:set_keymap() abort
  nnoremap <buffer> <silent> <Plug>(gh_gist_list_fetch) :call <SID>fetch_gists()<CR>
  nnoremap <buffer> <silent> <Plug>(gh_gist_list_yank) :call <SID>yank_or_open_gists_url('yank')<CR>
  nnoremap <buffer> <silent> <Plug>(gh_gist_list_open_browser) :call <SID>yank_or_open_gists_url('open')<CR>

  nmap <buffer> <silent> <C-o> <Plug>(gh_gist_list_open_browser)
  nmap <buffer> <silent> ghy   <Plug>(gh_gist_list_yank)
  nmap <buffer> <silent> ghf   <Plug>(gh_gist_list_fetch)
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
              \ 'markable': 1,
              \ 'type': 'file',
              \ 'info': {
              \   'url': node.info.url
              \ },
              \ })
      endfor
    else
      let node['type'] = 'file'
      let gist.files[0].text = split(gist.files[0].text, '\r\?\n')
      let node.info = gist.files[0]
      let node.info['url'] = gist.url
    endif

    call add(b:gh_gist_tree.children, node)
  endfor
endfunction

function! s:set_page_info(resp) abort
  let b:gh_gists_list_page_info = {
        \ 'has_next': a:resp.page_info.hasNextPage,
        \ 'cursor': a:resp.page_info.endCursor,
        \ }
  return a:resp
endfunction

function! s:fetch_gists() abort
  if !b:gh_gists_list_page_info.has_next
    call gh#gh#message('there are not more gists')
    return
  endif

  call gh#gh#message('fetching gists...')
  call gh#github#gists#list(b:gh_gist_list.owner, b:gh_gists_list_page_info.cursor)
        \.then({resp -> s:set_page_info(resp)})
        \.then({resp -> s:make_tree(resp.gists)})
        \.then({-> gh#provider#tree#redraw()})
        \.then({-> execute('echom ""', '')})
        \.catch({err -> execute('call gh#gh#error_message(err.body)', '')})
endfunction

function! s:yank_or_open_gists_url(op) abort
  let urls = s:get_gists_url()
  if empty(urls)
    return
  endif

  call gh#provider#tree#clean_marked_nodes()
  call gh#provider#tree#redraw()

  if a:op is# 'yank'
    call gh#gh#yank(urls)
  else
    for url in urls
      call gh#gh#open_url(url)
    endfor
  endif
endfunction

function! s:get_gists_url() abort
  let urls = []
  for node in s:get_selected_gists()
    if exists('node.info.url')
      call add(urls, node.info.url)
    endif
  endfor
  return urls
endfunction

function! s:get_selected_gists() abort
  let nodes = []
  for node in values(gh#provider#tree#marked_nodes())
    call add(nodes, node)
  endfor
  if empty(nodes)
    let nodes = [gh#provider#tree#current_node()]
  endif
  return nodes
endfunction
