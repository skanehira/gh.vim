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
  for pr in a:resp.body
    call add(lines, printf("%s\t%s\t%s\t%s", pr.number, pr.state, pr.title, pr.user.login))
    call add(s:pulls, #{
          \ number: pr.number,
          \ url: printf('https://github.com/%s/%s/pull/%s', s:repo.owner, s:repo.name, pr.number),
          \ })
  endfor

  call setline(1, lines)
  nnoremap <buffer> <silent> o :call <SID>pull_open()<CR>
  nnoremap <buffer> <silent> dd :call <SID>open_pull_diff()<CR>
endfunction

function! s:pull_list_change_page(op) abort
  if a:op is# '+'
    let s:repo.pull.param.page += 1
  else
    if s:repo.pull.param.page < 2
      return
    endif
    let s:repo.pull.param.page -= 1
  endif

  let vs = []
  for k in keys(s:repo.pull.param)
    call add(vs, printf('%s=%s', k, s:repo.pull.param[k]))
  endfor

  let cmd = printf('vnew gh://%s/%s/pulls', s:repo.owner, s:repo.name)
  if len(vs) > 0
    let cmd = printf('%s?%s', cmd, join(vs, '&'))
  endif

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
  let s:repo = #{
        \ owner: m[1],
        \ name: m[2],
        \ pull: #{
        \   param: param,
        \ },
        \ }

  call gh#gh#init_buffer()

  call gh#gh#set_message_buf('loading')

  call gh#github#pulls#list(s:repo.owner, s:repo.name, s:repo.pull.param)
        \.then(function('s:pull_list'))
        \.catch({err -> execute('call gh#gh#error_message(err.body)', '')})
        \.finally(function('gh#gh#global_buf_settings'))
endfunction

function! s:open_pull_diff() abort
  if bufexists(t:gh_preview_diff_bufid)
    call execute('bw ' . t:gh_preview_diff_bufid)
  endif
  let number = s:pulls[line('.')-1].number
  call execute(printf('belowright vnew gh://%s/%s/pulls/%s/diff', s:repo.owner, s:repo.name, number))
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

