" repos
" Author: skanehira
" License: MIT

function! s:repo_open() abort
  call gh#gh#open_url(s:repos[line('.') - 1].html_url)
endfunction

function! s:repo_open_readme() abort
  call gh#gh#delete_tabpage_buffer('gh_repo_readme_bufid')
  let full_name = s:repos[line('.')-1].full_name
  call execute(printf('belowright vnew gh://%s/readme', full_name))
endfunction

function! s:repo_list_change_page(op) abort
  if a:op is# '+'
    let s:repo_list.param.page += 1
  else
    if s:repo_list.param.page < 2
      return
    endif
    let s:repo_list.param.page -= 1
  endif

  let cmd = printf('vnew gh://%s/repos?%s',
        \ s:repo_list.owner, gh#http#encode_param(s:repo_list.param))
  call execute(cmd)
endfunction

function! s:repo_list(resp) abort
  nnoremap <buffer> <silent> <C-l> :call <SID>repo_list_change_page('+')<CR>
  nnoremap <buffer> <silent> <C-h> :call <SID>repo_list_change_page('-')<CR>

  if empty(a:resp.body)
    call gh#gh#set_message_buf('not found repositories')
    return
  endif

  let s:repos = []
  let lines = []
  for repo in a:resp.body
    call add(lines, printf("%s\t%s", repo.stargazers_count, repo.full_name))
    call add(s:repos, repo)
  endfor

  call setline(1, lines)
  nnoremap <buffer> <silent> o :call <SID>repo_open()<CR>
  nnoremap <buffer> <silent> <C-r> :call <SID>repo_open_readme()<CR>
endfunction

function! gh#repos#list() abort
  let m = matchlist(bufname(), 'gh://\(.*\)/repos?*\(.*\)')
  let param = gh#http#decode_param(m[2])
  if !has_key(param, 'page')
    let param['page'] = 1
  endif

  let s:repo_list = #{
        \ owner: m[1],
        \ param: param,
        \ }

  call gh#gh#delete_tabpage_buffer('gh_repo_list_bufid')
  let t:gh_repo_list_bufid = bufnr()

  call gh#gh#init_buffer()
  call gh#gh#set_message_buf('loading')

  call gh#github#repos#list(s:repo_list.owner, s:repo_list.param)
        \.then(function('s:repo_list'))
        \.catch({err -> execute('call gh#gh#error_message(err.body)', '')})
        \.finally(function('gh#gh#global_buf_settings'))
endfunction

function! gh#repos#readme() abort
  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/readme')
  call gh#gh#delete_tabpage_buffer('gh_repo_readme_bufid')
  let t:gh_repo_readme_bufid = bufnr()

  call gh#gh#init_buffer()
  call gh#gh#set_message_buf('loading')

  call gh#github#repos#readme(m[1], m[2])
        \.then(function('s:set_readme_body'))
        \.catch({err -> execute('call gh#gh#set_message_buf(err.body)', '')})
        \.finally(function('gh#gh#global_buf_settings'))
endfunction

function! s:set_readme_body(resp) abort
  call setline(1, split(a:resp.body, "\r"))
  setlocal ft=markdown
endfunction
