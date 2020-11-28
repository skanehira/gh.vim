" tree
" Author: skanehira
" License: MIT

let s:marked_nodes = {}
let s:nodes = []
let s:tree = []
let s:bufid = -1

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
  let node['selected'] = exists('s:marked_nodes[a:current.path]')

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
  for n in s:nodes
    if n.path is# a:node.path
      return pos
    endif
    let pos += 1
  endfor
  return pos
endfunc

func! s:change_state(state) abort
  let current = s:get_current_node()
  let node = s:find_node_parent(a:state, current)
  if empty(node)
    return
  endif
  if !exists('node.state')
    return
  endif
  let node.state = a:state
  if a:state is# 'close'
    call setpos('.', [0, s:get_node_pos(node), 1])
  else
    " use feedkeys send key after draw
    call feedkeys('j')
  endif
  call s:re_draw()
endfunc

func! s:re_draw() abort
  setlocal modifiable
  let save_cursor = getcurpos()
  silent call deletebufline(s:bufid, 1, '$')
  let s:nodes = s:flatten([], {}, s:tree)
  call s:draw(s:nodes)
  call setpos('.', save_cursor)
  setlocal nomodifiable
endfunc

func! s:find_node_parent(state, target) abort
  let target = a:target
  if exists('target.parent') && a:state is 'close'
    let target = target.parent
  elseif exists('target.has_children')
    let target = target
  else
    let target = {}
  endif

  if empty(target)
    return {}
  endif
  let node = s:find_node(s:tree, target)
  return node
endfunc

func! s:node_select_toggle() abort
  " do nothing for tree root
  if line('.') is# 1
    return
  endif
  let current = s:get_current_node()
  if exists('current.has_children')
    return
  endif

  if exists('s:marked_nodes[current.path]')
    call remove(s:marked_nodes, current.path)
  else
    let node = s:find_node(s:tree, current)
    let s:marked_nodes[current.path] = node
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
    call add(a:parent.children, a:target)
  endif
  return !has
endfunc

func! gh#tree#root() abort
  return s:tree
endfunc

func! gh#tree#move_node(dest, parent, src) abort
  let dest = a:dest
  if !exists('dest.children')
    let dest['children'] = []
    let dest['state'] = 'open'
  endif
  let added = s:add_node(dest, a:src)
  if added
    call s:remove_node(a:parent, a:src)
  endif
  let s:marked_nodes = {}
  call s:re_draw()
endfunc

func! gh#tree#update(tree) abort
  let s:tree = a:tree
  call s:re_draw()
  redraw!
endfunc

func! gh#tree#redraw() abort
  call s:re_draw()
  redraw!
endfunc

func! gh#tree#marked_nodes() abort
  return s:marked_nodes
endfunc

func! gh#tree#clean_marked_nodes() abort
  let s:marked_nodes = {}
endfunc

func! gh#tree#current_node() abort
  let current = s:get_current_node()
  return s:find_node(s:tree, current)
endfunc

func! gh#tree#open(tree) abort
  let s:bufid = bufnr()
  let s:tree = a:tree
  let s:nodes = s:flatten([], {}, a:tree)
  let s:marked_nodes = {}

  call s:draw(s:nodes)

  nnoremap <buffer> <silent> h :<C-u>call <SID>change_state('close')<CR>
  nnoremap <buffer> <silent> l :<C-u>call <SID>change_state('open')<CR>
  nnoremap <buffer> <silent> <C-j> :<C-u>call <SID>node_select_down()<CR>
  nnoremap <buffer> <silent> <C-k> :<C-u>call <SID>node_select_up()<CR>
endfunc
