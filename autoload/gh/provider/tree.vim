" tree
" Author: skanehira
" License: MIT

func! s:flatten(nodes, parent, current) abort
  let nodes = a:nodes
  if exists('a:parent.indent')
    let indent = a:parent.indent + 1
  else
    let indent = 1
  endif

  let node = {
        \ 'path': a:current.path,
        \ 'indent': indent,
        \ 'parent': a:parent,
        \ }

  if exists('a:current.markable')
    let node['markable'] = a:current.markable
  endif

  if exists('a:current.name')
    let node['name'] = a:current.name
  endif
  let node['selected'] = exists('b:marked_nodes[a:current.path]')

  call add(nodes, node)

  if exists('a:current.children')
    let node['state'] = a:current.state
    let node['has_children'] = 1
    if node.state is# 'open'
      for child in a:current.children
        call s:flatten(nodes, node, child)
      endfor
    endif
  endif
  return nodes
endfunc

func! s:find_node(node, target) abort
  if a:node.path is# a:target.path
    return a:node
  elseif exists('a:node.children')
    for child in a:node.children
      let n = s:find_node(child, a:target)
      if empty(n)
        continue
      endif
      return n
    endfor
  endif
  return {}
endfunc

func! s:get_node_pos(node) abort
  let pos = 1
  for n in b:nodes
    if n.path is# a:node.path
      return pos
    endif
    let pos += 1
  endfor
  return pos
endfunc

func! s:open_node() abort
  let node = gh#provider#tree#current_node()
  if exists('node.state') && node.state is# 'close'
    let node.state = 'open'
  endif
  " use feedkeys send key after draw
  call feedkeys('j')
  call s:redraw()
endfunc

func! s:close_node() abort
  let current_node = gh#provider#tree#current_node()
  if exists('current_node.state') && current_node.state is# 'open'
    let current_node.state = 'close'
  else
    let paths = split(current_node.path, '/')
    let parent_path = join(paths[:-2], '/')
    let parent_node = s:find_parent_node(b:tree, parent_path)
    if !exists('parent_node.state')
      return
    endif
    let parent_node.state = 'close'
    call setpos('.', [0, s:get_node_pos(parent_node), 1])
  endif
  call s:redraw()
endfunc

func! s:find_parent_node(node, path) abort
  if a:node.path is# a:path
    return a:node
  endif
  if exists('a:node.children')
    for child in a:node.children
      let p = s:find_parent_node(child, a:path)
      if !empty(p)
        return p
      endif
    endfor
  endif
  return {}
endfunc

func! s:redraw() abort
  setlocal modifiable
  let save_cursor = getcurpos()
  silent call deletebufline(b:bufid, 1, '$')
  let b:nodes = s:flatten([], {}, b:tree)
  call s:draw(b:nodes)
  call setpos('.', save_cursor)
  setlocal nomodifiable
  redraw
endfunc

func! s:node_select_toggle() abort
  let current = s:get_current_node()
  if exists('current.markable') && !current.markable
    return
  endif
  if exists('b:marked_nodes[current.path]')
    call remove(b:marked_nodes, current.path)
  else
    let node = s:find_node(b:tree, current)
    let b:marked_nodes[current.path] = node
  endif
  call s:redraw()
endfunc

func! s:node_select_down() abort
  call s:node_select_toggle()
  normal! j
endfunc

func! s:node_select_up() abort
  normal! k
  call s:node_select_toggle()
endfunc

func! s:get_current_node() abort
  let idx = line('.') - 1
  return b:nodes[idx]
endfunc

func! s:make_prefix(node) abort
  let prefix = '|'
  if exists('a:node.state')
    if a:node.state is# 'open'
      let prefix = '-'
    else
      let prefix = '+'
    endif
  endif

  let indent = a:node.indent
  if indent is# 0
    return ''
  endif

  let i = 0
  let line = ''
  while i < indent
    let i += 1
    if i == indent
      let line .= printf('%s ', prefix)
    else
      let line .= '| '
    endif
  endwhile
  return line
endfunc

func! s:draw(nodes) abort
  let i = 1
  for node in a:nodes
    let prefix = s:make_prefix(node)
    if !exists('node.name')
      continue
    endif
    let line = prefix .. node.name
    if node.selected
      let line .= '*'
    endif
    call setbufline(b:bufid, i, line)
    let i += 1
  endfor
endfunc

func! s:remove_node(parent, target) abort
  let idx = 0
  for node in a:parent.children
    if node.path is# a:target.path
      break
    endif
    let idx += 1
  endfor
  call remove(a:parent.children, idx)
  if empty(a:parent.children)
    call remove(a:parent, 'children')
  endif
endfunc

func! s:add_node(parent, target) abort
  let has = 0
  for node in a:parent.children
    if node.path is# a:target.path
      let has = 1
    endif
  endfor
  if !has
    " update target node path
    let target = a:target
    let paths = split(target.path, '/')
    let target.path = join([a:parent.path, paths[-1]], '/')
    call add(a:parent.children, a:target)
  endif
  return !has
endfunc

func! gh#provider#tree#root() abort
  return b:tree
endfunc

func! gh#provider#tree#move_node(dest, parent, src) abort
  let dest = a:dest
  if !exists('dest.children')
    let dest['children'] = []
    let dest['state'] = 'open'
  endif
  let added = s:add_node(dest, a:src)
  if added
    call s:remove_node(a:parent, a:src)
  endif
  let b:marked_nodes = {}
  call s:redraw()
endfunc

func! gh#provider#tree#update(tree) abort
  let b:tree = a:tree
  call s:redraw()
endfunc

func! gh#provider#tree#redraw() abort
  call s:redraw()
endfunc

func! gh#provider#tree#marked_nodes() abort
  return b:marked_nodes
endfunc

func! gh#provider#tree#clean_marked_nodes() abort
  let b:marked_nodes = {}
endfunc

func! gh#provider#tree#current_node() abort
  let current = s:get_current_node()
  return s:find_node(b:tree, current)
endfunc

func! s:set_node(tree, node) abort
  let tree = a:tree
  if a:tree.path is# a:node.path
    for k in keys(a:node)
      let tree[k] = a:node[k]
    endfor
    return 1
  elseif exists('a:tree.children')
    for n in a:tree.children
      if s:set_node(n, a:node)
        return 1
      endif
    endfor
  endif
  return 0
endfunc

func! gh#provider#tree#set_node(node) abort
  return s:set_node(b:tree, a:node)
endfunc

func! gh#provider#tree#open(tree) abort
  let b:bufid = bufnr()
  let b:tree = a:tree
  let b:nodes = s:flatten([], {}, a:tree)
  let b:marked_nodes = {}

  call s:draw(b:nodes)

  nnoremap <buffer> <silent> h :<C-u>call <SID>close_node()<CR>
  nnoremap <buffer> <silent> l :<C-u>call <SID>open_node()<CR>
  nnoremap <buffer> <silent> <C-j> :<C-u>call <SID>node_select_down()<CR>
  nnoremap <buffer> <silent> <C-k> :<C-u>call <SID>node_select_up()<CR>
endfunc
