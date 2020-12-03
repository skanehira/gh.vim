" explorer
" Author: skanehira
" License: MIT

function! gh#files#tree() abort
  setlocal ft=gh-files
  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/\(.*\)\/files')

  call gh#gh#delete_buffer(s:, 'gh_file_list_bufid')
  let s:gh_file_list_bufid = bufnr()

  let s:file_list = {
        \ 'repo': {
        \   'owner': m[1],
        \   'name': m[2],
        \   'branch': m[3],
        \ }
        \ }

  call gh#gh#init_buffer()
  call gh#gh#set_message_buf('loading')

  call gh#github#repos#files(m[1], m[2], m[3])
        \.then({resp -> s:make_tree(resp.body)})
        \.then({-> gh#tree#open(s:tree)})
        \.then({-> s:set_keymap()})
        \.then({-> gh#map#apply('gh-buffer-file-list', s:gh_file_list_bufid)})
        \.catch({err -> execute('call gh#gh#error_message(err.body)', '')})
        \.finally(function('gh#gh#global_buf_settings'))
endfunction

function! s:edit_file() abort
  let node = gh#tree#current_node()
  if node.info.type isnot# 'tree'
    call gh#gh#message('opening...')
    call gh#github#repos#get_file(node.info.url)
          \.then({body -> s:set_file_contents(node, body)})
          \.finally({-> execute('echom ""', '')})
  endif
endfunction

function! s:set_file_contents(node, body) abort
  call gh#gh#init_buffer()
  exe printf('rightbelow vnew %s', a:node.path)
  call setline(1, a:body)
  set nomodified
  nnoremap <buffer> <silent> q :bw!<CR>
endfunction

function! s:set_keymap() abort
  nnoremap <buffer> <silent> <Plug>(gh_files_edit) :call <SID>edit_file()<CR>
  nmap <buffer> <silent> ghe <Plug>(gh_files_edit)
endfunction

function! s:make_tree(body) abort
  let s:tree = {
        \ 'name': s:file_list.repo.name,
        \ 'path': s:file_list.repo.name,
        \ 'state': 'open',
        \ 'children': []
        \ }

  " add project name to root path
  " because github trees doesn't have root path
  for file in a:body.tree
    let file.path = join([s:file_list.repo.name, file.path], '/')
  endfor

  let files_len = len(a:body.tree)
  for idx in range(files_len)
    call s:make_node(s:tree, a:body.tree[idx])
    echo printf('[gh.vim] creating tree: %d/%d', idx, files_len-1)
  endfor
endfunction

function! s:make_node(tree, file) abort
  let paths = split(a:file.path, '/')
  let parent_path = join(paths[:-2], "/")
  let tree = a:tree
  let item = {
        \ 'name': paths[-1],
        \ 'path': a:file.path,
        \ 'info': a:file
        \ }

  if a:file.type is# 'tree'
    let item['children'] = []
    let item['state'] = 'close'
  endif

  if exists('tree.children')
    for node in tree.children
      call s:make_node(node, a:file)
    endfor
  endif

  if tree.path is# parent_path
    if a:file.type is# 'tree'
      let item.name .= '/'
    endif
    call add(a:tree.children, item)
  endif
endfunction
