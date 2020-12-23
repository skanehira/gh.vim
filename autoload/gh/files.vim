" files
" Author: skanehira
" License: MIT

let s:Promise = vital#gh#import('Async.Promise')
let s:gh_tree_cache = {}

function! gh#files#tree() abort
  " cahce to create tree structure more faster
  let b:gh_tree_node_cache = {}
  " Cache the tree created at the first time

  setlocal ft=gh-files
  let m = matchlist(bufname(), 'gh://\(.\{-}\)/\(.\{-}\)/\(.*\)\/files?*\(.*\)')
  let b:gh_file_list_bufid = bufnr()

  let b:gh_file_list = {
        \ 'repo': {
        \   'owner': m[1],
        \   'name': m[2],
        \   'branch': m[3],
        \ },
        \ 'cache_key': printf('%s/%s/%s', m[1], m[2], m[3])
        \ }

  if !empty(m[4])
    let kv = split(m[4], '=')
    if len(kv) > 1 && kv[0] is# 'recache' && kv[1] is# '1'
      if has_key(s:gh_tree_cache, b:gh_file_list.cache_key)
        call remove(s:gh_tree_cache, b:gh_file_list.cache_key)
      endif
    endif
  endif

  call gh#gh#init_buffer()
  call gh#gh#set_message_buf('loading')

  call s:files(m[1], m[2], m[3])
        \.then({-> gh#provider#tree#open(b:gh_file_tree)})
        \.then({-> s:set_keymap()})
        \.then({-> gh#map#apply('gh-buffer-file-list', b:gh_file_list_bufid)})
        \.catch({err -> execute('call gh#gh#error_message(err.body)', '')})
        \.finally(function('gh#gh#global_buf_settings'))
endfunction

function! s:files(owner, repo, branch) abort
  if has_key(s:gh_tree_cache, b:gh_file_list.cache_key)
    let b:gh_file_tree = s:gh_tree_cache[b:gh_file_list.cache_key]
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
          \.then({-> s:set_edit_keymap()})
          \.then({-> gh#map#apply('gh-buffer-file', b:gh_file_bufid)})
          \.finally({-> execute('echom ""', '')})
  endif
endfunction

function! s:set_file_contents(node, body) abort
  call gh#gh#init_buffer()
  exe printf('rightbelow vnew %s', a:node.path)
  call setline(1, a:body)
  setlocal nomodified
  let b:gh_file_info = a:node.info
  let b:gh_file_bufid = bufnr()
endfunction

function! s:set_keymap() abort
  nnoremap <buffer> <silent> <Plug>(gh_files_edit) :call <SID>edit_file()<CR>
  nnoremap <buffer> <silent> <Plug>(gh_files_yank_url) :call <SID>files_yank_url()<CR>
  nnoremap <buffer> <silent> <Plug>(gh_files_open_browser) :call <SID>files_open_browser()<CR>
  nmap <buffer> <silent> ghe <Plug>(gh_files_edit)
  nmap <buffer> <silent> ghy <Plug>(gh_files_yank_url)
  nmap <buffer> <silent> <C-o> <Plug>(gh_files_open_browser)
endfunction

function! s:make_tree(body) abort
  let b:gh_file_tree = {
        \ 'name': b:gh_file_list.repo.name,
        \ 'path': b:gh_file_list.repo.name,
        \ 'state': 'open',
        \ 'children': [],
        \ 'markable': 0,
        \ }

  " add project name to root path
  " because github trees doesn't have root path
  for file in a:body.tree
    let file.path = join([b:gh_file_list.repo.name, file.path], '/')
  endfor

  let files_len = len(a:body.tree)
  for idx in range(files_len)
    call s:make_node(b:gh_file_tree, a:body.tree[idx])
    echo printf('[gh.vim] creating tree: %d/%d', idx+1, files_len)
    redraw
  endfor
  let s:gh_tree_cache[b:gh_file_list.cache_key] = deepcopy(b:gh_file_tree, 1)
endfunction

function! s:make_node(tree, file) abort
  let paths = split(a:file.path, '/')
  let parent_path = join(paths[:-2], "/")
  let tree = a:tree
  let item = {
        \ 'name': a:file.type is# 'tree' ? paths[-1] .. '/' : paths[-1],
        \ 'path': a:file.path,
        \ 'info': a:file,
        \ 'markable': 1,
        \ }

  let url_format = 'https://github.com/%s/%s/blob/%s/%s'
  if a:file.type is# 'tree'
    let item['children'] = []
    let item['state'] = 'close'
    let url_format = 'https://github.com/%s/%s/tree/%s/%s'
  endif

  let item.info['html_url'] = printf(url_format,
        \ b:gh_file_list.repo.owner, b:gh_file_list.repo.name, b:gh_file_list.repo.branch, join(paths[1:], '/'))

  if has_key(b:gh_tree_node_cache, parent_path)
    call add(b:gh_tree_node_cache[parent_path], item)
    return
  endif

  if exists('tree.children')
    for node in tree.children
      call s:make_node(node, a:file)
    endfor
  endif

  if tree.path is# parent_path
    call add(a:tree.children, item)
    let b:gh_tree_node_cache[parent_path] = a:tree.children
  endif
endfunction

function! s:get_selected_urls() abort
  let urls = []
  for node in values(gh#provider#tree#marked_nodes())
    call add(urls, node.info.html_url)
  endfor
  if empty(urls)
    return [gh#provider#tree#current_node().info.html_url]
  endif
  return urls
endfunction

function! s:files_yank_url() abort
  let urls = s:get_selected_urls()

  if len(urls) > 1
    call gh#provider#tree#clean_marked_nodes()
    call gh#provider#tree#redraw()
  endif

  let ln = "\n"
  if &ff == "dos"
    let ln = "\r\n"
  endif

  call gh#gh#yank(join(urls, ln))
  call gh#gh#message('copied ' .. urls[0])
  for url in urls[1:]
    call gh#gh#message('       ' .. url)
  endfor
endfunction

function! s:files_open_browser() abort
  let urls = s:get_selected_urls()

  if len(urls) > 1
    call gh#provider#tree#clean_marked_nodes()
    call gh#provider#tree#redraw()
  endif

  for url in urls
    call gh#gh#open_url(url)
  endfor
endfunction

function! s:set_edit_keymap() abort
  if &ft isnot# 'markdown' || &ft isnot# 'asciidoc'
    vnoremap <buffer> <silent> <Plug>(gh_file_yank_url) :<C-u>call <SID>yank_or_open_file_url('yank')<CR>
    vnoremap <buffer> <silent> <Plug>(gh_file_open_browser) :<C-u>call <SID>yank_or_open_file_url('open')<CR>
    vmap <buffer> <silent> ghy <Plug>(gh_file_yank_url)
    vmap <buffer> <silent> <C-o> <Plug>(gh_file_open_browser)
  endif
endfunction

function! s:yank_or_open_file_url(op) abort
  let url = s:get_file_url()
  if !empty(url)
    if a:op is# 'open'
      call gh#gh#open_url(url)
    else
      call gh#gh#yank(url)
      call gh#gh#message('copied ' .. url)
    endif
  endif
endfunction

" yank specified lines url
function! s:get_file_url() abort
  let start = line("'<")
  let end = line("'>")

  let url = b:gh_file_info.html_url
  if start ==# end
    return printf('%s#L%d', url, start)
  endif
  return printf('%s#L%d-L%d', url, start, end)
endfunction
