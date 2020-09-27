" gh
" Author: skanehira
" License: MIT

function! gh#gh#init() abort
  let bufname = bufname()
  if bufname is# 'gh://user/repos/new'
    call gh#repos#new()
  elseif bufname =~# '^gh:\/\/[^/]\+\/repos$' || bufname =~# '^gh:\/\/[^/]\+\/repos?\+'
    call gh#repos#list()
  elseif bufname =~# '^gh:\/\/[^/]\+\/[^/]\+\/readme$'
    call gh#repos#readme()
  elseif bufname =~# '^gh:\/\/[^/]\+\/[^/]\+\/issues$'
        \ || bufname =~# '^gh:\/\/[^/]\+\/[^/]\+\/issues?\+'
    call gh#issues#list()
  elseif bufname =~# '^gh:\/\/[^/]\+\/[^/]\+\/issues\/[0-9]\+$'
    call gh#issues#issue()
  elseif bufname =~# '^gh:\/\/[^/]\+\/[^/]\+\/issues\/new$'
    call gh#issues#new()
  elseif bufname =~# '^gh:\/\/[^/]\+\/[^/]\+\/issues\/\d\+\/comments$'
        \ || bufname =~# '^gh:\/\/[^/]\+\/[^/]\+\/issues\/\d\+\/comments?\+'
    call gh#issues#comments()
  elseif bufname =~# '^gh:\/\/[^/]\+\/[^/]\+\/issues\/\d\+\/comments\/new$'
    call gh#issues#comment_new()
  elseif bufname =~# '^gh:\/\/[^/]\+\/[^/]\+\/pulls$'
        \ || bufname =~# '^gh:\/\/[^/]\+\/[^/]\+\/pulls?\+'
    call gh#pulls#list()
  elseif bufname =~# '^gh:\/\/[^/]\+\/[^/]\+\/pulls\/\d\+\/diff$'
    call gh#pulls#diff()
  endif
endfunction

function! gh#gh#init_buffer() abort
  setlocal buftype=nofile bufhidden=wipe
        \ noswapfile nobuflisted nonumber
endfunction

function! gh#gh#set_message_buf(msg) abort
  call setline(1, printf('-- %s --', a:msg))
  nnoremap <buffer> <silent> q :bw<CR>
endfunction

function! gh#gh#error_message(msg) abort
  echohl ErrorMsg
  echom '[gh.vim] ' . a:msg
  echohl None
endfunction

function! gh#gh#message(msg) abort
  echohl Directory
  echom '[gh.vim] ' . a:msg
  echohl None
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
    call execute('bw! '. t:[a:name])
  endif
endfunction
