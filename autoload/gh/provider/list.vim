" list
" Author: skanehira
" License: MIT

" list have to be as bellow
" {
"   'header': [
"     'number',
"     'title',
"     'author',
"     'labels',
"     ...
"   ],
"   'data': [
"     {'id': 32, 'number': '#1', 'title': 'this is a test', 'author': 'gorilla', labels: '(bug, refactor)'},
"     ...
"   ],
"   'bufname': 'gh://skanehira/gh.vim'
"   'param': {
"     'page': 1,
"     'creator': 'skanehira'
"   }
" }
function! gh#provider#list#open(list) abort
  let b:bufname = a:list.bufname
  let b:param = a:list.param

  if len(a:list.data) isnot# 0
    let b:header = a:list.header
    let b:list = a:list.data
    let b:list_marked = {}
    let b:list_bufid = bufnr()
    call s:redraw()
    syntax match gh_files_selected /.*\*$/
  endif
  call s:init_keymap()
endfunction

function! s:init_keymap() abort
  nnoremap <buffer> <silent> <C-j> :<C-u>call <SID>mark_down()<CR>
  nnoremap <buffer> <silent> <C-k> :<C-u>call <SID>mark_up()<CR>
  nnoremap <buffer> <silent> <C-h> :<C-u>call <SID>prev_page()<CR>
  nnoremap <buffer> <silent> <C-l> :<C-u>call <SID>next_page()<CR>
endfunction

function! s:next_page() abort
  let b:param.page += 1
  call s:change_page()
endfunction

function! s:prev_page() abort
  if b:param.page < 2
    return
  endif
  let b:param.page -= 1
  call s:change_page()
endfunction

function! s:change_page() abort
  let cmd = printf('%s?%s', b:bufname, gh#http#encode_param(b:param))
  call execute('e ' .. cmd)
endfunction

function! s:redraw() abort
  setlocal modifiable
  let format = gh#gh#dict_format(b:list, b:header)

  let lines = []
  for data in b:list
    let line = []
    for h in b:header
      call add(line, data[h])
    endfor

    if has_key(b:list_marked, data.id)
      let line[-1] = line[-1] .. '*'
    endif
    let args = [format] + line

    call add(lines, call(function('printf'), args))
  endfor

  call setbufline(b:list_bufid, 1, lines)
  setlocal nomodifiable
endfunction

function! gh#provider#list#redraw() abort
  call s:redraw()
endfunction

function! gh#provider#list#get_marked() abort
  return values(b:list_marked)
endfunction

function! s:toggle_mark() abort
  if len(b:list) is# 0
    return
  endif
  let current = b:list[line('.')-1]
  if has_key(b:list_marked, current.id)
    call remove(b:list_marked, current.id)
  else
    let b:list_marked[current.id] = current
  endif
  call s:redraw()
endfunction

function! s:mark_down() abort
  call s:toggle_mark()
  normal! j
endfunction

function! s:mark_up() abort
  normal! k
  call s:toggle_mark()
endfunction

function! gh#provider#list#clean_marked() abort
  let b:list_marked = {}
endfunction

function! gh#provider#list#current() abort
  return b:list[line('.')-1]
endfunction
