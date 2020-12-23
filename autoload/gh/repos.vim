" repos
" Author: skanehira
" License: MIT

function! s:repo_open() abort
  call gh#gh#open_url(b:gh_repos[line('.') - 1].html_url)
endfunction

function! s:repo_open_readme() abort
  let full_name = b:gh_repos[line('.')-1].full_name
  call execute(printf('belowright vnew gh://%s/readme', full_name))
endfunction

function! s:repo_list_change_page(op) abort
  if a:op is# '+'
    let b:repo_list.param.page += 1
  else
    if b:repo_list.param.page < 2
      return
    endif
    let b:repo_list.param.page -= 1
  endif

  let cmd = printf('vnew gh://%s/repos?%s',
        \ b:repo_list.owner, gh#http#encode_param(b:repo_list.param))

  call gh#gh#delete_buffer(b:, 'gh_repo_list_bufid')
  call execute(cmd)
endfunction


function! s:repo_delete_success(timer) abort
  redraw!
  call gh#gh#message('deleted repository')
  call s:issue_list_refresh()
endfunction

function! s:issue_list_refresh() abort
  let cmd = printf('e gh://%s/repos?%s',
        \ b:repo_list.owner, gh#http#encode_param(b:repo_list.param))
  call execute(cmd)
endfunction

function! s:set_repo_list(resp) abort
  nnoremap <buffer> <silent> <Plug>(gh_repo_list_next) :<C-u>call <SID>repo_list_change_page('+')<CR>
  nnoremap <buffer> <silent> <Plug>(gh_repo_list_prev) :<C-u>call <SID>repo_list_change_page('-')<CR>
  nmap <buffer> <silent> <C-l> <Plug>(gh_repo_list_next)
  nmap <buffer> <silent> <C-h> <Plug>(gh_repo_list_prev)

  if empty(a:resp.body)
    call gh#gh#set_message_buf('not found repositories')
    return
  endif

  let b:gh_repos = []
  let lines = []

  let dict = map(copy(a:resp.body), {_, v -> {
        \ 'full_name': v.full_name,
        \ 'stargazers_count': v.stargazers_count,
        \ }})
  let format = gh#gh#dict_format(dict, ['full_name', 'stargazers_count'])

  for repo in a:resp.body
    call add(lines, printf(format, repo.full_name, repo.stargazers_count))
    call add(b:gh_repos, repo)
  endfor

  call setbufline(b:gh_repo_list_bufid, 1, lines)

  nnoremap <buffer> <silent> <Plug>(gh_repo_open_browser) :<C-u>call <SID>repo_open()<CR>
  nnoremap <buffer> <silent> <Plug>(gh_repo_show_readme) :<C-u>call <SID>repo_open_readme()<CR>
  nmap <buffer> <silent> <C-o> <Plug>(gh_repo_open_browser)
  nmap <buffer> <silent> gho <Plug>(gh_repo_show_readme)
endfunction

function! gh#repos#list() abort
  setlocal ft=gh-repos
  let m = matchlist(bufname(), 'gh://\(.*\)/repos?*\(.*\)')
  let param = gh#http#decode_param(m[2])
  if !has_key(param, 'page')
    let param['page'] = 1
  endif

  let b:repo_list = {
        \ 'owner': m[1],
        \ 'param': param,
        \ }

  let b:gh_repo_list_bufid = bufnr()

  call gh#gh#init_buffer()
  call gh#gh#set_message_buf('loading')

  call gh#github#repos#list(b:repo_list.owner, b:repo_list.param)
        \.then(function('s:set_repo_list'))
        \.then({-> gh#map#apply('gh-buffer-repo-list', b:gh_repo_list_bufid)})
        \.catch({err -> execute('call gh#gh#error_message(err.body)', '')})
        \.finally(function('gh#gh#global_buf_settings'))
endfunction

function! gh#repos#readme() abort
  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/readme')
  let b:gh_repo_readme_bufid = bufnr()

  let b:repo_readme = {
        \ 'owner': m[1],
        \ 'name': m[2],
        \ 'url': printf('https://github.com/%s/%s', m[1], m[2]),
        \ }

  call gh#gh#init_buffer()
  call gh#gh#set_message_buf('loading')

  call gh#github#repos#readme(m[1], m[2])
        \.then(function('s:set_readme_content'))
        \.then({-> gh#map#apply('gh-buffer-repo-readme', b:gh_repo_readme_bufid)})
        \.catch({err -> execute('call gh#gh#set_message_buf(err.body)', '')})
        \.finally(function('gh#gh#global_buf_settings'))
endfunction

function! s:set_readme_content(body) abort
  call setbufline(b:gh_repo_readme_bufid, 1, a:body)
  setlocal ft=markdown

  nnoremap <buffer> <silent> <Plug>(gh_repo_open_browser_on_readme) :<C-u>call <SID>repo_open_on_readme()<CR>
  nmap <buffer> <silent> <C-o> <Plug>(gh_repo_open_browser_on_readme)
endfunction

function! s:repo_open_on_readme() abort
  call gh#gh#open_url(b:repo_readme.url)
endfunction

function! gh#repos#new() abort
  let s:gh_repo_new_bufid = bufnr()
  call gh#map#apply('gh-buffer-repo-new', s:gh_repo_new_bufid)

  let lines = ['name: ', 'description: ', 'private: false', 'delete_branch_on_merge: true']
  call setbufline(s:gh_repo_new_bufid, 1, lines)

  call gh#gh#init_buffer()
  setlocal buftype=acwrite
  augroup gh-create-repo
    au!
    au BufWriteCmd <buffer> call s:repo_create()
  augroup END
endfunction

function! s:repo_create() abort
  let param = {
        \ 'name': '',
        \ 'description': '',
        \ 'private': v:false,
        \ 'delete_branch_on_merge': v:true,
        \ }

  let contents = {}
  let lines = getline(1, '$')
  for l in lines
    let kv = split(l, ':')
    if len(kv) > 1
      let contents[kv[0]] = trim(kv[1])
    endif
  endfor

  for [k, v] in items(contents)
    if v is# 'true'
      let v = v:true
    elseif v is# 'false'
      let v = v:false
    endif
    let param[k] = v
  endfor

  if param['name'] is# ''
    call gh#gh#error_message('required repository name')
    return
  endif

  call gh#gh#message('repository creating...')
  call gh#github#repos#create(param)
        \.then(function('s:repo_create_success'))
        \.catch({err -> execute('call gh#gh#error_message(err.body)', '')})
endfunction

function! s:repo_create_success(resp) abort
  bw!
  redraw!
  call gh#gh#message(printf('repository created: %s', a:resp.body.html_url))
endfunction
