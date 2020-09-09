" gh
" Author: skanehira
" License: MIT

function! s:issue_preview() abort
  call win_execute(s:gh_preview_winid, '%d_')
  let number = split(getline('.'), "\t")[0]
  call setbufline(t:gh_preview_bufid, 1, split(s:issues[number].body, '\r\?\n'))
endfunction

function! s:open_issue_preview() abort
  let winid = win_getid()
  belowright vnew gh://issues/preview
  setlocal buftype=nofile
  setlocal ft=markdown

  let t:gh_preview_bufid = bufnr()
  let s:gh_preview_winid = win_getid()

  call win_gotoid(winid)

  augroup gh-issue-preview
    au!
    autocmd CursorMoved <buffer> call s:issue_preview()
  augroup END

  call s:issue_preview()
endfunction

function! s:issue_open() abort
  let line = getline('.')
  let number = split(line, "\t")[0]
  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/issues$')
  let url = printf('https://github.com/%s/%s/issues/%s', m[1], m[2], number)
  call gh#gh#open_url(url)
endfunction

function! s:issues(resp) abort
  if empty(a:resp.body)
    call gh#gh#error('no found issues')
    return
  endif

  let s:issues = {}
  let lines = []
  for issue in a:resp.body
    if !has_key(issue, 'pull_request')
      call add(lines, printf("%s\t%s\t%s\t%s", issue.number, issue.state, issue.title, issue.user.login))
      let s:issues[issue.number] = issue
    endif
  endfor

  call setline(1, lines)
  call s:open_issue_preview()
  nnoremap <buffer> <silent> o :call <SID>issue_open()<CR>
endfunction

function! gh#issues#list() abort
  setlocal buftype=nofile
  setlocal nonumber

  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/issues$')

  call setline(1, '-- loading --')

  call gh#github#issues(m[1], m[2])
        \.then(function('s:issues'))
        \.catch(function('gh#gh#error'))
        \.finally(function('gh#gh#global_buf_settings'))
endfunction

