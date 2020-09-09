" gh
" Author: skanehira
" License: MIT

function! s:pulls(resp) abort
  if empty(a:resp.body)
    call gh#gh#error('no found pull requests')
    return
  endif

  let lines = []
  for pr in a:resp.body
    call add(lines, printf("%s\t%s\t%s\t%s", pr.number, pr.state, pr.title, pr.user.login))
  endfor

  call setline(1, lines)

  nnoremap <buffer> <silent> o :call <SID>pull_open()<CR>
  nnoremap <buffer> <silent> dd :call <SID>open_pull_diff()<CR>
endfunction

function! s:pull_open() abort
  let line = getline('.')
  let number = split(line, "\t")[0]
  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/pulls$')
  let url = printf('https://github.com/%s/%s/pull/%s', m[1], m[2], number)
  call gh#gh#open_url(url)
endfunction

function! gh#pulls#list() abort
  call gh#gh#delete_tabpage_buffer('gh_pulls_list_bufid')
  call gh#gh#delete_tabpage_buffer('gh_preview_diff_bufid')

  let t:gh_pulls_list_bufid = bufnr()

  setlocal buftype=nofile
  setlocal nonumber

  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/pulls$')

  call setline(1, '-- loading --')

  call gh#github#pulls(m[1], m[2])
        \.then(function('s:pulls'))
        \.catch(function('gh#gh#error'))
        \.finally(function('gh#gh#global_buf_settings'))
endfunction

function! s:open_pull_diff() abort
  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/pulls$')
  let number = split(getline('.'), "\t")[0]
  if get(t:, 'gh_preview_diff_bufid', '') isnot# '' && bufexists(t:gh_preview_diff_bufid)
    call execute('bw ' . t:gh_preview_diff_bufid)
  endif
  call execute(printf('belowright vnew gh://%s/%s/pulls/%s/diff', m[1], m[2], number))
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

  call setline(1, '-- loading --')

  call gh#github#pulls_diff(m[1], m[2], m[3])
        \.then(function('s:set_diff_contents'))
        \.catch(function('gh#gh#error'))
        \.finally(function('gh#gh#global_buf_settings'))
endfunction

