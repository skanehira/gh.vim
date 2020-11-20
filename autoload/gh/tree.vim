" tree
" Author: skanehira
" License: MIT

let s:node_selected = {}

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

  if exists('a:current.name')
    let node['name'] = a:current.name
  endif
  let node['selected'] = exists('s:node_selected[a:current.path]')

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

func! s:change_state(state) abort
  let target = s:get_current_node()
  if empty(target)
    return 0
  endif
  let node = s:find_node(s:tree, target)
  if empty(node)
    return 0
  endif
  if exists('node.state')
    let node.state = a:state
  endif
  return 1
endfunc

func! s:re_draw() abort
  setlocal modifiable
  let save_cursor = getcurpos()
  %d_
  let s:nodes = s:flatten([], {}, s:tree)
  call s:draw(s:nodes)
  call setpos('.', save_cursor)
endfunc

func! s:node_close() abort
  let changed = s:change_state('close')
  if changed
    setlocal modifiable
    call s:re_draw()
    setlocal nomodifiable
  endif
endfunc

func! s:node_open() abort
  let changed = s:change_state('open')
  if changed
    setlocal modifiable
    call s:re_draw()
    setlocal nomodifiable
  endif
endfunc

func! s:find_node_parent() abort
  let current = s:get_current_node()
  if empty(current)
    return {}
  endif
  if exists('current.has_children')
    let target = current
  elseif exists('current.parent')
    let target = current.parent
  else
    let target = {}
  endif

  if empty(target)
    return {}
  endif
  let node = s:find_node(s:tree, target)
  return node
endfunc

func! s:node_move() abort
  if empty(s:node_selected)
    return
  endif

  let dest = s:find_node_parent()
  if empty(dest)
    return
  endif
  if !exists('s:tree_move_hook')
    echom 'not found move hook function'
    return
  endif
  let new_tree = s:tree_move_hook(dest, s:node_selected)
  let s:node_selected = {}
  call tree#update(new_tree)
endfunc

func! s:node_select_toggle() abort
  let current = s:get_current_node()
  if empty(current)
    return
  endif
  if exists('s:node_selected[current.path]')
    call remove(s:node_selected, current.path)
  else
    let node = s:find_node(s:tree, current)
    let s:node_selected[current.path] = node
  endif
  call s:re_draw()
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
  return s:nodes[idx]
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
    call setbufline(s:bufid, i, line)
    let i += 1
  endfor
endfunc

func! gh#tree#update(tree) abort
  let s:tree = a:tree
  call s:re_draw()
endfunc

func! gh#tree#open(tree) abort
  let s:bufid = bufnr()
  let s:tree = a:tree
  let s:nodes = s:flatten([], {}, a:tree)

  call s:draw(s:nodes)

  nnoremap <buffer> <silent> h :<C-u>call <SID>node_close()<CR>
  nnoremap <buffer> <silent> l :<C-u>call <SID>node_open()<CR>
  nnoremap <buffer> <silent> p :<C-u>call <SID>node_move()<CR>
  nnoremap <buffer> <silent> <C-j> :<C-u>call <SID>node_select_down()<CR>
  nnoremap <buffer> <silent> <C-k> :<C-u>call <SID>node_select_up()<CR>
endfunc

func! gh#tree#add_move_hook(f) abort
  let s:tree_move_hook = a:f
endfunc
