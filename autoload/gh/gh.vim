" gh
" Author: skanehira
" License: MIT

function! gh#gh#error(msg) abort
  call setline(1, printf('-- %s --', a:msg))
endfunction

function! gh#gh#global_buf_settings() abort
  setlocal nomodifiable
  setlocal cursorline
  setlocal cursorlineopt=line
  setlocal nowrap

  nnoremap <buffer> <silent> q :bw!<CR>
endfunction

function! gh#gh#open_url(url) abort
  let cmd = 'open'
  if has('linux')
    let cmd = 'xdg-open'
  endif
  call system(printf('%s %s', cmd, a:url))
endfunction

function! gh#gh#delete_tabpage_buffer(name) abort
  if bufexists(t:[a:name])
    call execute('bw '. t:[a:name])
  endif
endfunction
