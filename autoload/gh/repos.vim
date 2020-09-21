" repos
" Author: skanehira
" License: MIT

function! s:repo_open() abort
  call gh#gh#open_url(s:repos[line('.') - 1].html_url)
endfunction

function! s:set_response_to_buf(repo_name, resp) abort
  call setbufline(t:gh_repo_preview_bufid, 1, split(a:resp.body, '\r'))
  let t:gh_cache_repos[a:repo_name] = a:resp
endfunction

function! s:repo_preview() abort
  call win_execute(s:gh_repo_preview_winid, '%d_')
  call setbufline(t:gh_repo_preview_bufid, 1, '-- loading --')

  let repo = s:repos[line('.') - 1]

  if has_key(t:gh_cache_repos, repo.full_name)
    let resp = t:gh_cache_repos[repo.full_name]
    call s:set_response_to_buf(repo.full_name, resp)
    return
  endif

  call gh#github#repos#readme(repo.owner.login, repo.name)
        \.then(function('s:set_response_to_buf', [repo.full_name]))
        \.catch(function('s:set_response_to_buf',[repo.full_name]))
endfunction

function! s:open_repo_preview() abort
  let winid = win_getid()
  call execute('belowright vnew ' . printf('gh://%s/repo/preview', s:repos[line('.') - 1].full_name))

  setlocal buftype=nofile
  setlocal ft=markdown

  let t:gh_repo_preview_bufid = bufnr()
  let s:gh_repo_preview_winid = win_getid()

  call win_gotoid(winid)

  augroup gh-repo-preview
    au!
    autocmd CursorMoved <buffer> call s:repo_preview()
  augroup END

  call s:repo_preview()
endfunction

function! s:repos_list(resp) abort
  if empty(a:resp.body)
    call gh#gh#set_message_buf('not found repositories')
    return
  endif

  let lines = []
  let s:repos = []
  for repo in a:resp.body
    call add(lines, printf("%s\t%s", repo.stargazers_count, repo.full_name))
    call add(s:repos, repo)
  endfor

  call setline(1, lines)
  call s:open_repo_preview()
  nnoremap <buffer> <silent> o :call <SID>repo_open()<CR>
endfunction

function! gh#repos#list() abort
  call gh#gh#delete_tabpage_buffer('gh_repo_list_bufid')
  call gh#gh#delete_tabpage_buffer('gh_repo_preview_bufid')

  let t:gh_cache_repos = {}
  let t:gh_repo_list_bufid = bufnr()

  setlocal buftype=nofile
  setlocal nonumber

  call gh#gh#set_message_buf('loading')

  let owner = matchlist(bufname(), 'gh://\(.*\)/repos$')[1]
  call gh#github#repos#list(owner)
        \.then(function('s:repos_list'))
        \.catch(function('gh#gh#set_message_buf'))
        \.finally(function('gh#gh#global_buf_settings'))
endfunction
