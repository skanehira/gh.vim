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
  call execute('belowright vnew ' . printf('gh://%s/%s/issues/preview', s:repo.owner, s:repo.name))

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
  let number = split(getline('.'), "\t")[0]
  let url = printf('https://github.com/%s/%s/issues/%s', s:repo.owner, s:repo.name, number)
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
  call gh#gh#delete_tabpage_buffer('gh_issues_list_bufid')
  call gh#gh#delete_tabpage_buffer('gh_preview_bufid')

  let t:gh_issues_list_bufid = bufnr()

  setlocal buftype=nofile
  setlocal nonumber

  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/issues$')
  let s:repo = #{
        \ owner: m[1],
        \ name: m[2],
        \ }

  call setline(1, '-- loading --')

  call gh#github#issues#list(s:repo.owner, s:repo.name)
        \.then(function('s:issues'))
        \.catch(function('gh#gh#error'))
        \.finally(function('gh#gh#global_buf_settings'))
endfunction

