" files
" Author: skanehira
" License: MIT

let s:Promise = vital#gh#import('Async.Promise')
let s:tree_cache = {}

function! gh#files#tree() abort
  " cahce to create tree structure more faster
  let b:tree_node_cache = {}
  " Cache the tree created at the first time

  setlocal ft=gh-files
  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/\(.*\)\/files')
  let b:gh_file_list_bufid = bufnr()

  let b:file_list = {
        \ 'repo': {
        \   'owner': m[1],
        \   'name': m[2],
        \   'branch': m[3],
        \ },
        \ 'cache_key': printf('%s/%s/%s', m[1], m[2], m[3])
        \ }

  call gh#gh#init_buffer()
  call gh#gh#set_message_buf('loading')

  call s:files(m[1], m[2], m[3])
        \.then({-> gh#provider#tree#open(b:tree)})
        \.then({-> s:set_keymap()})
        \.then({-> gh#map#apply('gh-buffer-file-list', b:gh_file_list_bufid)})
        \.catch({err -> execute('call gh#gh#error_message(err.body)', '')})
        \.finally(function('gh#gh#global_buf_settings'))
endfunction

function! s:files(owner, repo, branch) abort
  if has_key(s:tree_cache, b:file_list.cache_key)
    let b:tree = s:tree_cache[b:file_list.cache_key]
    return s:Promise.resolve({})
  endif
  return gh#github#repos#files(a:owner, a:repo, a:branch)
        \.then({resp -> s:make_tree(resp.body)})
endfunction

function! s:edit_file() abort
  let node = gh#provider#tree#current_node()
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
  setlocal nomodified
endfunction

function! s:set_keymap() abort
  nnoremap <buffer> <silent> <Plug>(gh_files_edit) :call <SID>edit_file()<CR>
  nmap <buffer> <silent> ghe <Plug>(gh_files_edit)
endfunction

function! s:make_tree(body) abort
  let b:tree = {
        \ 'name': b:file_list.repo.name,
        \ 'path': b:file_list.repo.name,
        \ 'state': 'open',
        \ 'children': [],
        \ 'markable': 0,
        \ }

  " add project name to root path
  " because github trees doesn't have root path
  for file in a:body.tree
    let file.path = join([b:file_list.repo.name, file.path], '/')
  endfor

  let files_len = len(a:body.tree)
  for idx in range(files_len)
    call s:make_node(b:tree, a:body.tree[idx])
    call gh#gh#message(printf('creating tree: %d/%d', idx+1, files_len))
    redraw
  endfor
  let s:tree_cache[b:file_list.cache_key] = deepcopy(b:tree, 1)
endfunction

function! s:make_node(tree, file) abort
  let paths = split(a:file.path, '/')
  let parent_path = join(paths[:-2], "/")
  let tree = a:tree
  let item = {
        \ 'name': paths[-1],
        \ 'path': a:file.path,
        \ 'info': a:file,
        \ 'markable': 1,
        \ }

  if a:file.type is# 'tree'
    let item['children'] = []
    let item['state'] = 'close'
  endif

  if has_key(b:tree_node_cache, parent_path)
    call add(b:tree_node_cache[parent_path], item)
    return
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
    let b:tree_node_cache[parent_path] = a:tree.children
  endif
endfunction
