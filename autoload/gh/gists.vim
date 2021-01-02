" gists
" Author: skanehira
" License: MIT

let s:Promise = vital#gh#import('Async.Promise')
let s:gh_gists_cache = {}
let s:gh_gist_new_files = []

function! gh#gists#list() abort
  setlocal ft=gh-gists
  let b:gh_gists_list_bufid = bufnr()
  let b:gh_gists_list_page_info = {
        \ 'has_next': 0,
        \ 'cursor': ''
        \ }

  call gh#gh#init_buffer()
  call gh#gh#set_message_buf('loading')

  let m = matchlist(bufname(), 'gh://\(.*\)/gists?*\(.*\)')
  let b:gh_gist_list = {
        \ 'owner': m[1],
        \ }

  let b:gh_gist_list['privacy'] = 'PUBLIC'
  if !empty(m[2])
    let p = split(m[2], '=')
    if len(p) > 1
      if p[0] is# 'privacy' && p[1] =~? '\(PUBLIC\|ALL\|SECRET\)'
        let b:gh_gist_list['privacy'] = toupper(p[1])
      endif
    endif
  endif

  call gh#github#gists#list(b:gh_gist_list.owner, b:gh_gist_list.privacy)
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

  call s:make_tree(b:gh_gist_list.owner, a:resp.gists)

  call gh#provider#tree#open(b:gh_gist_tree)
  call gh#provider#preview#open(s:get_preview_info(), function('s:preview_update'))
endfunction

function! s:set_keymap() abort
  nnoremap <buffer> <silent> <Plug>(gh_gist_list_fetch) :call <SID>fetch_gists()<CR>
  nnoremap <buffer> <silent> <Plug>(gh_gist_list_yank) :call <SID>yank_or_open_gists_url('yank')<CR>
  nnoremap <buffer> <silent> <Plug>(gh_gist_list_open_browser) :call <SID>yank_or_open_gists_url('open')<CR>
  nnoremap <buffer> <silent> <Plug>(gh_gist_edit_file) :call <SID>edit_gist_file()<CR>

  nmap <buffer> <silent> <C-o> <Plug>(gh_gist_list_open_browser)
  nmap <buffer> <silent> ghy   <Plug>(gh_gist_list_yank)
  nmap <buffer> <silent> ghf   <Plug>(gh_gist_list_fetch)
  nmap <buffer> <silent> ghe   <Plug>(gh_gist_edit_file)
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

function! s:make_tree(owner, gists) abort
  for gist in a:gists
    let name = empty(gist.description) ? gist.files[0].name : gist.description
    let node = {
          \ 'name': printf('[%s] %s', gist.isPublic ? 'PUBLIC' : 'SECRET', name),
          \ 'path': printf('%s/%s', a:owner, gist.name),
          \ 'markable': 1,
          \ 'info': gist,
          \ }

    if len(gist.files) > 1
      let node['state'] = 'open'
      let node['children'] = []
      let node['type'] = 'node'

      for f in gist.files
        let f.text = split(f.text, '\r\?\n')
        let f['url'] = node.info.url
        call add(node['children'], {
              \ 'name': f.name,
              \ 'path': printf('%s/%s', node.path, f.name),
              \ 'markable': 1,
              \ 'type': 'file',
              \ 'info': f,
              \ })
        let s:gh_gists_cache[printf('%s/%s/%s', a:owner, gist.name, f.name)] = {'text': f.text}
      endfor
    else
      let node['type'] = 'file'
      let gist.files[0].text = split(gist.files[0].text, '\r\?\n')
      let node.info = gist.files[0]
      let node.info['url'] = gist.url

      let s:gh_gists_cache[printf('%s/%s/%s', a:owner, gist.name, node.info.name)] = {'text': node.info.text}
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
  call gh#github#gists#list(b:gh_gist_list.owner, b:gh_gist_list.privacy, b:gh_gists_list_page_info.cursor)
        \.then({resp -> s:set_page_info(resp)})
        \.then({resp -> s:make_tree(b:gh_gist_list.owner, resp.gists)})
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

function! gh#gists#gist() abort
  setlocal ft=gh-gists
  let b:gh_gists_bufid = bufnr()
  call gh#gh#init_buffer()
  call gh#gh#set_message_buf('loading')

  let m = matchlist(bufname(), 'gh://\(.*\)/gists/\(.*\)')
  let b:gh_gist = {
        \ 'owner': m[1],
        \ 'id': m[2],
        \ }
  call gh#github#gists#gist(b:gh_gist.owner, b:gh_gist.id)
        \.then({gist -> s:set_gist(gist)})
        \.then({-> gh#map#apply('gh-buffer-gist', b:gh_gists_bufid)})
        \.catch({err -> execute('call gh#gh#error_message(err.body)', '')})
        \.finally(function('gh#gh#global_buf_settings'))
endfunction

function! s:set_gist(gist) abort
  let b:gh_gist_tree = {
        \ 'id': 1,
        \ 'name': b:gh_gist.owner,
        \ 'state': 'open',
        \ 'path': b:gh_gist.owner,
        \ 'markable': 0,
        \ 'type': 'root',
        \ 'children': []
        \ }
  call s:make_tree(b:gh_gist.owner, [a:gist])
  call gh#provider#tree#open(b:gh_gist_tree)
  call gh#provider#preview#open(s:get_preview_info(), function('s:preview_update'))

  nnoremap <buffer> <silent> <Plug>(gh_gist_edit_file) :call <SID>edit_gist_file()<CR>
  nmap <buffer> <silent> ghe   <Plug>(gh_gist_edit_file)
endfunction

function! s:edit_gist_file() abort
  let current = gh#provider#tree#current_node()
  if current.type is# 'file'
    let open = gh#gh#decide_open()
    if empty(open)
      call gh#gh#message('cancelled')
      return
    endif
    let paths = split(current.path, '/')
    exe printf('%s gh://%s/gists/%s/%s', open, paths[0], paths[1], current.info.name)
  endif
endfunction

function! gh#gists#edit() abort
  let m = matchlist(bufname(), 'gh://\(.*\)/gists/\(.*\)/\(.*\)')
  let b:gh_edit_gist_bufid = bufnr()
  let owner = m[1]
  let id = m[2]
  let filename = m[3]
  let b:gh_gist_edit = {
        \ 'owner': owner,
        \ 'id': id,
        \ 'filename': filename,
        \ }

  call s:get_gist(owner, id, filename)
        \.then({contents -> s:init_edit_gist_buffer(contents)})
endfunction

function! s:get_gist(owner, id, filename) abort
  let b:gh_gist_key = printf('%s/%s/%s', a:owner, a:id, a:filename)
  if has_key(s:gh_gists_cache, b:gh_gist_key)
    return s:Promise.resolve(s:gh_gists_cache[b:gh_gist_key].text)
  endif
  return gh#github#gists#gist(a:owner, a:id)
        \.then({gist -> filter(gist.files, {_, f -> f.name is# a:filename})})
        \.then({files -> len(files) is# 0 ? [] : split(files[0].text, '\r\?\n')})
endfunction

function! s:init_edit_gist_buffer(contents) abort
  if empty(a:contents)
    call gh#gh#error_message(printf('not found %s', b:gh_gist_edit.filename))
    return
  endif

  let s:gh_gists_cache[b:gh_gist_key] = {'text': a:contents}

  call setbufline(b:gh_edit_gist_bufid, 1, a:contents)
  exe printf('do BufRead %s | normal zn', b:gh_gist_edit.filename)
  setlocal buftype=acwrite
  setlocal nomodified

  augroup gh-gist-update
    au!
    au BufWriteCmd <buffer> call s:update_gist()
  augroup END
endfunction

function! s:update_gist() abort
  let body = getline(1, '$')
  if empty(body)
    call gh#gh#error_message('contents is empty')
    return
  endif

  let data = {
        \ 'files': {
        \   b:gh_gist_edit.filename: {'content': join(body, "\r\n")}
        \ }
        \ }

  call gh#gh#message('gist updating...')

  call gh#github#gists#update(b:gh_gist_edit.id, data)
        \.then({-> s:gist_update_success(body)})
        \.catch({err -> execute('call gh#gh#error_message(err.body)', '')})
endfunction

function! s:gist_update_success(text) abort
  let file = s:gh_gists_cache[b:gh_gist_key]
  let file.text = a:text
  call gh#gh#message('gist updated')
  setlocal nomodified
endfunction

function! gh#gists#new() abort
  call s:gist_new_file()
endfunction

function! s:gist_new_file() abort
  setlocal buftype=acwrite

  let filename = split(bufname(), '/')[-1]
  exe printf('do BufRead %s', filename)

  call add(s:gh_gist_new_files, {'name': filename, 'bufid': bufnr()})

  exe printf('augroup gh-gist-create-%d', bufnr())
    au!
    au BufWriteCmd <buffer> call s:gist_create_files()
    au BufDelete <buffer> call s:gist_remove_cache_file()
  augroup END
endfunction

function! s:gist_remove_cache_file() abort
  let bufid = str2nr(expand('<abuf>'))
  for idx in range(len(s:gh_gist_new_files))
    if s:gh_gist_new_files[idx].bufid is# bufid
      call remove(s:gh_gist_new_files, idx)
    endif
  endfor
endfunction

function! s:gist_create_files() abort
  let files = {}

  for file in s:gh_gist_new_files
    let content = join(getbufline(file.bufid, 1, '$'), "\r\n")
    if empty(content)
      call gh#gh#error_message(file.name .. ' is emtpy')
      return
    endif
    let files[file.name] = {'content': content}
  endfor

  let is_public = input('make a public?(y/n)') =~ '^y' ? v:true : v:false
  let data = {'files': files, 'public': is_public}

  echo '' | redraw
  call gh#gh#message('creating...')

  call gh#github#gists#create(data)
        \.then({resp -> s:gist_create_file_success(resp)})
        \.catch({err -> execute('call gh#gh#error_message(err.body)', '')})
endfunction

function! s:gist_create_file_success(resp) abort
  for file in s:gh_gist_new_files
    exe printf('bw! %s', file.bufid)
  endfor

  call gh#gh#message(printf('new gist: %s', a:resp.body.html_url))
endfunction
