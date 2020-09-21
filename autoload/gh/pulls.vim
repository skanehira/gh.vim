" gh
" Author: skanehira
" License: MIT

function! s:pulls(resp) abort
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

function! s:pull_open() abort
  call gh#gh#open_url(s:pulls[line('.')-1].url)
endfunction

function! gh#pulls#list() abort
  call gh#gh#delete_tabpage_buffer('gh_pulls_list_bufid')
  call gh#gh#delete_tabpage_buffer('gh_preview_diff_bufid')

  let t:gh_pulls_list_bufid = bufnr()

  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/pulls')
  let s:repo = #{
        \ owner: m[1],
        \ name: m[2],
        \ }

  setlocal buftype=nofile
  setlocal nonumber

  call gh#gh#set_message_buf('loading')

  call gh#github#pulls#list(s:repo.owner, s:repo.name)
        \.then(function('s:pulls'))
        \.catch(function('gh#gh#set_message_buf'))
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
  setlocal buftype=nofile
  setlocal nonumber

  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/pulls/\(.*\)/diff$')

  call gh#gh#set_message_buf('loading')

  call gh#github#pulls#diff(m[1], m[2], m[3])
        \.then(function('s:set_diff_contents'))
        \.catch(function('gh#gh#set_message_buf'))
        \.finally(function('gh#gh#global_buf_settings'))
endfunction

