" gh
" Author: skanehira
" License: MIT

let s:cmd = 'open'
if has('linux')
  let s:cmd = 'xdg-open'
elseif has('win64')
  let s:cmd = 'cmd /c start'
endif

let s:yank_reg = '*'
if has('linux') || has('unix')
  let s:yank_reg = '+'
endif

function! gh#gh#init() abort
  setlocal nolist
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
  elseif bufname =~# '^gh:\/\/[^/]\+\/[^/]\+\/[^/]\+\/issues\/new$'
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
  elseif bufname =~# '^gh:\/\/[^/]\+\/[^/]\+\/projects$'
        \ || bufname =~# '^gh:\/\/[^/]\+\/[^/]\+\/projects?\+'
    call gh#projects#list()
  endif
endfunction

function! gh#gh#init_buffer() abort
  setlocal buftype=nofile bufhidden=wipe
        \ noswapfile nonumber
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
  setlocal nowrap

  nnoremap <buffer> <silent> q :bw!<CR>
endfunction

function! gh#gh#open_url(url) abort
  call system(printf('%s %s', s:cmd, a:url))
endfunction

function! gh#gh#yank(url) abort
  call setreg(s:yank_reg, a:url)
endfunction

function! gh#gh#delete_buffer(s, name) abort
  if has_key(a:s, a:name) && bufexists(a:s[a:name])
    call execute('bw! '. a:s[a:name])
  endif
endfunction

function! gh#gh#def_highlight() abort
  hi! gh_blue ctermfg=110 guifg=#84a0c6
  hi! gh_green ctermfg=150 guifg=#b4be82
  hi! gh_orange ctermfg=216 guifg=#e2a478
  hi! link gh_purple Constant
  hi! link gh_red WarningMsg

  hi! link gh_issue_number gh_blue
  hi! link gh_issue_open gh_green
  hi! link gh_issue_closed gh_red
  hi! link gh_issue_user gh_purple

  hi! link gh_issue_comment_user gh_purple
  hi! link gh_issue_comment_number gh_blue

  hi! link gh_pull_number gh_blue
  hi! link gh_pull_open gh_green
  hi! link gh_pull_closed gh_red
  hi! link gh_pull_user gh_purple

  hi! link gh_repo_name gh_blue
  hi! link gh_repo_star gh_orange

  hi! link gh_project_number gh_blue
  hi! link gh_project_open gh_green
  hi! link gh_project_closed gh_red
endfunction

function! s:dict_value_len(items) abort
  if len(a:items) < 1
    return {}
  endif

  let len = map(copy(a:items[0]), {k -> 0})
  for item in a:items
    for [k, v] in items(item)
      let l = strchars(v)
      let len[k] = len[k] > l ? len[k] : l
    endfor
  endfor
  return len
endfunction

function! gh#gh#dict_format(items, keys) abort
  let dict = s:dict_value_len(a:items)
  if empty(dict)
    return ''
  endif
  let format = map(copy(a:keys), {_, k -> printf("%%-%ss", dict[k])})
  return join(format)
endfunction
