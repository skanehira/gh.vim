" gh
" Author: skanehira
" License: MIT

function! s:pull_list(resp) abort
  nnoremap <buffer> <silent> <C-l> :call <SID>pull_list_change_page('+')<CR>
  nnoremap <buffer> <silent> <C-h> :call <SID>pull_list_change_page('-')<CR>

  if empty(a:resp.body)
    call gh#gh#set_message_buf('no found pull requests')
    return
  endif

  let lines = []
  let s:pulls = []
  let url = printf('https://github.com/%s/%s/pull/', s:pull_list.repo.owner, s:pull_list.repo.name)

  for pr in a:resp.body
    call add(lines, printf("%s\t%s\t%s\t%s", pr.number, pr.state, pr.title, pr.user.login))
    call add(s:pulls, #{
          \ number: pr.number,
          \ url: url . pr.number,
          \ })
  endfor

  call setline(1, lines)
  nnoremap <buffer> <silent> o :call <SID>pull_open()<CR>
  nnoremap <buffer> <silent> dd :call <SID>open_pull_diff()<CR>
endfunction

function! s:pull_list_change_page(op) abort
  if a:op is# '+'
    let s:pull_list.param.page += 1
  else
    if s:pull_list.param.page < 2
      return
    endif
    let s:pull_list.param.page -= 1
  endif

  let cmd = printf('vnew gh://%s/%s/pulls?%s',
        \ s:pull_list.repo.owner, s:pull_list.repo.name, gh#http#encode_param(s:pull_list.param))
  call execute(cmd)
endfunction

function! s:pull_open() abort
  call gh#gh#open_url(s:pulls[line('.')-1].url)
endfunction

function! gh#pulls#list() abort
  call gh#gh#delete_tabpage_buffer('gh_pulls_list_bufid')
  call gh#gh#delete_tabpage_buffer('gh_preview_diff_bufid')

  let t:gh_pulls_list_bufid = bufnr()

  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/pulls?*\(.*\)')
  let param = gh#http#decode_param(m[3])
  if !has_key(param, 'page')
    let param['page'] = 1
  endif

  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/pulls')
  let s:pull_list = #{
        \ repo: #{
        \   owner: m[1],
        \   name: m[2],
        \ },
        \ param: param,
        \ }

  call gh#gh#init_buffer()

  call gh#gh#set_message_buf('loading')

  call gh#github#pulls#list(s:pull_list.repo.owner, s:pull_list.repo.name, s:pull_list.param)
        \.then(function('s:pull_list'))
        \.catch({err -> execute('call gh#gh#error_message(err.body)', '')})
        \.finally(function('gh#gh#global_buf_settings'))
endfunction

function! s:open_pull_diff() abort
  if bufexists(t:gh_preview_diff_bufid)
    call execute('bw ' . t:gh_preview_diff_bufid)
  endif
  let number = s:pulls[line('.')-1].number
  call execute(printf('belowright vnew gh://%s/%s/pulls/%s/diff',
        \ s:pull_list.repo.owner, s:pull_list.repo.name, number))
endfunction

function! s:set_diff_contents(resp) abort
  let t:gh_preview_diff_bufid = bufnr()
  call setline(1, split(a:resp.body, "\r"))
  setlocal buftype=nofile
  setlocal ft=diff
endfunction

function! gh#pulls#diff() abort
  call gh#gh#init_buffer()
  call gh#gh#set_message_buf('loading')

  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/pulls/\(.*\)/diff$')
  call gh#github#pulls#diff(m[1], m[2], m[3])
        \.then(function('s:set_diff_contents'))
        \.catch({err -> execute('call gh#gh#error_message(err.body)', '')})
        \.finally(function('gh#gh#global_buf_settings'))
endfunction

