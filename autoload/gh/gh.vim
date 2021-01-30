" gh
" Author: skanehira
" License: MIT

let s:gh_open_cmd = 'open'
if has('linux')
  let s:gh_open_cmd = 'xdg-open'
elseif has('win64')
  let s:gh_open_cmd = 'cmd /c start'
endif

let s:gh_yank_reg = '*'
if has('linux') || has('unix')
  let s:gh_yank_reg = '+'
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
  elseif bufname =~# '^gh:\/\/[^/]\+\/[^/]\+\/.\+\/issues\/new$'
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
  elseif bufname =~# '^gh:\/\/projects\/[^/]\+\/columns$'
        \ || bufname =~# '^gh:\/\/projects\/[^/]\+\/columns?\+'
    call gh#projects#columns()
  elseif bufname =~# '^gh:\/\/[^/]\+\/[^/]\+\/actions$'
        \ || bufname =~# '^gh:\/\/[^/]\+\/[^/]\+\/actions?\+'
    call gh#actions#list()
  elseif bufname =~# '^gh:\/\/[^/]\+\/[^/]\+\/.\+\/files$'
        \ || bufname =~# '^gh:\/\/[^/]\+\/[^/]\+\/.\+\/files?\+'
    call gh#files#tree()
  elseif bufname =~# '^gh:\/\/bookmarks$'
    call gh#bookmark#list()
  elseif bufname =~# '^gh:\/\/[^/]\+\/gists$'
        \ || bufname =~# '^gh:\/\/[^/]\+\/gists?\+'
    call gh#gists#list()
  elseif bufname =~# '^gh:\/\/[^/]\+\/gists\/[^/]\+$'
    call gh#gists#gist()
  elseif bufname =~# '^gh:\/\/[^/]\+\/gists\/[^/]\+\/[^/]\+'
    call gh#gists#edit()
  elseif bufname =~# '^gh:\/\/gists\/new\/[^/]\+$'
    call gh#gists#new()
  endif
endfunction

function! gh#gh#init_buffer() abort
  setlocal buftype=nofile bufhidden=hide
        \ noswapfile nonumber nowrap
        \ cursorline
endfunction

function! gh#gh#set_message_buf(msg) abort
  setlocal modifiable
  call setline(1, printf('-- %s --', a:msg))
endfunction

function! gh#gh#error_message(msg) abort
  echohl ErrorMsg
  echo '[gh.vim] ' . a:msg
  echohl None
endfunction

function! gh#gh#message(msg) abort
  echohl Directory
  echo '[gh.vim] ' . a:msg
  echohl None
endfunction

function! gh#gh#global_buf_settings() abort
  setlocal nomodifiable

  nnoremap <buffer> <silent> q :q<CR>
endfunction

function! gh#gh#open_url(url) abort
  call system(printf('%s %s', s:gh_open_cmd, a:url))
endfunction

function! gh#gh#yank(arg) abort
  if type(a:arg) is v:t_list
    let ln = "\n"
    if &ff == "dos"
      let ln = "\r\n"
    endif

    call setreg(s:gh_yank_reg, join(a:arg, ln))
    call gh#gh#message('copied ' .. a:arg[0])
    for item in a:arg[1:]
      call gh#gh#message('       ' .. item)
    endfor
  else
    call setreg(s:gh_yank_reg, a:arg)
    call gh#gh#message('copied ' .. a:arg)
  endif
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
  hi! gh_red cterm=bold ctermfg=203
  hi! link gh_purple Constant

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
  hi! link gh_project_column gh_green
  hi! link gh_project_column_selected gh_red

  hi! link gh_actions_number gh_blue
  hi! link gh_actions_ok gh_green
  hi! link gh_actions_ng gh_red
  hi! link gh_actions_running gh_orange
  hi! link gh_actions_author gh_purple
  hi! link gh_actions_branch gh_blue
  hi! link gh_actions_selected gh_red

  hi! link gh_files_dir gh_green
  hi! link gh_files_selected gh_red

  hi! link gh_gists_selected gh_red
  hi! link gh_gists_public gh_blue
  hi! link gh_gists_secret gh_purple
endfunction

function! s:dict_value_len(items, keys) abort
  if len(a:items) < 1
    return {}
  endif

  let len_dict = {}
  for k in a:keys
    let len_dict[k] = 0
  endfor

  for item in a:items
    for k in a:keys
      let l = strchars(item[k])
      let len_dict[k] = len_dict[k] > l ? len_dict[k] : l
    endfor
  endfor
  return len_dict
endfunction

function! gh#gh#dict_format(items, keys) abort
  let dict = s:dict_value_len(a:items, a:keys)
  if empty(dict)
    return ''
  endif
  let format = map(copy(a:keys[:-2]), {_, k -> printf("%%-%ss", dict[k])})
  let format += ['%s']
  return join(format)
endfunction

function! gh#gh#termopen(cmd, opt) abort
  exe a:opt.open

  if has('nvim')
    " NOTE: Neovim can't fold when job finished
    call termopen(a:cmd)
    setlocal scrollback=50000
  else
    call term_start(a:cmd, {
          \ 'curwin': 1,
          \ 'term_name': a:opt.bufname,
          \ 'exit_cb': { -> execute('setlocal foldmethod=expr foldexpr=gh#actions#fold_logs(v:lnum)') }
          \ })
    setlocal termwinscroll=50000
    nnoremap <buffer> <silent> q :q<CR>
  endif
endfunction

function! gh#gh#decide_open() abort
  call gh#gh#message('(e)dit, (n)ew, (v)new, (t)abnew: ')
  let result = nr2char(getchar())
  if result is# 'e'
    return 'e'
  elseif result is# 'n'
    return 'new'
  elseif result is# 'v'
    return 'vnew'
  elseif result is# 't'
    return 'tabnew'
  endif
  return ''
endfunction

function! gh#gh#get_token() abort
  let token = get(g:, 'gh_token', '')
  if !empty(token)
    return token
  endif
  let s:gh_token_path = glob('~/.config/gh/hosts.yml')
  if !empty(s:gh_token_path)
    for line in readfile(s:gh_token_path, '')
      if line =~ 'oauth_token'
        return matchlist(line, 'oauth_token: \(.*\)')[1]
      endif
    endfor
  endif
endfunction
