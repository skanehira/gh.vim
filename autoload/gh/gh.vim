" gh
" Author: skanehira
" License: MIT

function! gh#gh#error(msg) abort
  call setline(1, printf('-- %s --', a:msg))

function! gh#gh#set_response_to_buf(bufid, resp) abort
  if has_key(a:resp, 'exception')
    call setbufline(a:bufid, 1, a:resp.exception)
    return
  endif
  call setbufline(a:bufid, 1, split(a:resp.body, '\r'))
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
  if has_key(t:, a:name) && bufexists(t:[a:name])
    call execute('bw '. t:[a:name])
  endif
endfunction
