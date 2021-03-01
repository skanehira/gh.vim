" pulls
" Author: skanehira
" License: MIT

let s:MERGE_METHOD = {'Create a merge commit': 'merge', 'Squash and merge': 'squash', 'Rebase and merge': 'rebase'}
let s:MERGE_METHODS = keys(s:MERGE_METHOD)

function! s:set_pull_list(resp) abort
  let list = {
        \ 'bufname': printf('gh://%s/%s/pulls', b:gh_pull_list.repo.owner, b:gh_pull_list.repo.name),
        \ 'param': b:gh_pull_list.param,
        \ 'data': []
        \ }

  if empty(a:resp.body)
    call gh#gh#set_message_buf('not found pull requests')
    call gh#provider#list#open(list)
    return
  endif

  let url = printf('https://github.com/%s/%s/pull/', b:gh_pull_list.repo.owner, b:gh_pull_list.repo.name)
  let data = map(copy(a:resp.body), {_, pr -> {
        \ 'id': pr.id,
        \ 'number': printf('#%s', pr.number),
        \ 'state': pr.state,
        \ 'user': printf('@%s', pr.user.login),
        \ 'title': pr.title,
        \ 'labels': len(pr.labels) > 0 ? printf('(%s)', join(map(copy(pr.labels), {_, label -> label.name}), ", ")) : '',
        \ 'url': url .. pr.number
        \ }})

  let header = [
        \ 'number',
        \ 'state',
        \ 'user',
        \ 'title',
        \ 'labels',
        \ ]

  let list['header'] = header
  let list.data = data

  call gh#provider#list#open(list)

  nnoremap <buffer> <silent> <Plug>(gh_pull_open_browser) :<C-u>call <SID>pull_open()<CR>
  nnoremap <buffer> <silent> <Plug>(gh_pull_diff) :<C-u>call <SID>pull_open_diff()<CR>
  nnoremap <buffer> <silent> <Plug>(gh_pull_url_yank) :<C-u>call <SID>pull_url_yank()<CR>
  nnoremap <buffer> <silent> <Plug>(gh_pull_merge) :<C-u>call <SID>select_merge_method()<CR>
  nmap <buffer> <silent> <C-o> <Plug>(gh_pull_open_browser)
  nmap <buffer> <silent> ghd <Plug>(gh_pull_diff)
  nmap <buffer> <silent> ghy <Plug>(gh_pull_url_yank)
  nmap <buffer> <silent> ghm <Plug>(gh_pull_merge)
endfunction

function! s:on_accept_merge(data, name) abort
  call gh#provider#quickpick#close()
  redraw!
  let method = s:MERGE_METHOD[a:data.items[0]]
  let s:gh_merge_info['method'] = method
  if method is# 'merge' || method is# 'squash'
    let s:gh_merge_info['title'] = input('commit title: ', s:gh_merge_info.title)
    if input('edit commit message?(y/n)') =~ '^y'
      exe printf('new gh://%s/%s/pulls/%s/message', s:gh_merge_info.owner, s:gh_merge_info.repo, s:gh_merge_info.number)
      setlocal buftype=acwrite
      setlocal ft=markdown
      augroup gh-create-pr-message
        au!
        au BufWriteCmd <buffer> call s:on_merge_pull()
      augroup END
    else
      call s:merge_pull()
    endif
  elseif method is# 'rebase'
    call s:merge_pull()
  endif
endfunction

function! s:on_merge_pull() abort
  bw!
  let s:gh_merge_info['message'] = join(getline(1, '$'), "\r\n")
  call s:merge_pull()
endfunction

function! s:merge_pull() abort
  let body = {
        \ 'title': s:gh_merge_info.title,
        \ 'merge_method': s:gh_merge_info.method,
        \ }
  if has_key(s:gh_merge_info, 'message') | let body['commit_message'] = s:gh_merge_info.message | endif

  call gh#gh#message('merging...')
  call gh#github#pulls#merge(s:gh_merge_info.owner, s:gh_merge_info.repo, s:gh_merge_info.number, body)
        \.then({-> execute('call gh#gh#message("merged")', '')})
        \.catch({err -> execute('call gh#gh#error_message(err.body)', '')})
endfunction

function! s:on_change_merge_method(data, name) abort
  call gh#provider#quickpick#on_change(a:data, a:name, s:MERGE_METHODS)
endfunction

function! s:select_merge_method() abort
  let pr = gh#provider#list#current()
  if empty(pr)
    return
  endif

  let s:gh_merge_info = {
        \ 'owner': b:gh_pull_list.repo.owner,
        \ 'repo': b:gh_pull_list.repo.name,
        \ 'number': pr.number[1:],
        \ 'title': pr.title,
        \ }

  call gh#provider#quickpick#open({
        \ 'items': s:MERGE_METHODS,
        \ 'filter': 0,
        \ 'debounce': 0,
        \ 'on_accept': function('s:on_accept_merge'),
        \ 'on_change': function('s:on_change_merge_method'),
        \})
endfunction

function! s:pull_url_yank() abort
  let urls = []
  for pull in s:get_selected_pulls()
    call add(urls, pull.url)
  endfor

  call gh#provider#list#clean_marked()
  call gh#provider#list#redraw()

  call gh#gh#yank(urls)
endfunction

function! s:pull_open() abort
  for pull in s:get_selected_pulls()
    call gh#gh#open_url(pull.url)
  endfor
  call gh#provider#list#clean_marked()
  call gh#provider#list#redraw()
endfunction

function! s:get_selected_pulls() abort
  let pulls = gh#provider#list#get_marked()
  if empty(pulls)
    return [gh#provider#list#current()]
  endif
  return pulls
endfunction

function! gh#pulls#list() abort
  setlocal ft=gh-pulls
  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/pulls?*\(.*\)')

  let b:gh_pulls_list_bufid = bufnr()

  let param = gh#http#decode_param(m[3])
  if !has_key(param, 'page')
    let param['page'] = 1
  endif

  let b:gh_pull_list = {
        \ 'repo': {
        \   'owner': m[1],
        \   'name': m[2],
        \ },
        \ 'param': param,
        \ }

  call gh#gh#init_buffer()
  call gh#gh#set_message_buf('loading')

  call gh#github#pulls#list(b:gh_pull_list.repo.owner, b:gh_pull_list.repo.name, b:gh_pull_list.param)
        \.then(function('s:set_pull_list'))
        \.then({-> gh#map#apply('gh-buffer-pull-list', b:gh_pulls_list_bufid)})
        \.catch({err -> execute('call gh#gh#set_message_buf(err.body)', '')})
        \.finally(function('gh#gh#global_buf_settings'))
endfunction

function! s:pull_open_diff() abort
  let open = gh#gh#decide_open()
  if empty(open)
    return
  endif

  let number = gh#provider#list#current().number[1:]
  call execute(printf('belowright %s gh://%s/%s/pulls/%s/diff',
        \ open, b:gh_pull_list.repo.owner, b:gh_pull_list.repo.name, number))
endfunction

function! s:set_diff_contents(resp) abort
  call setbufline(b:gh_preview_diff_bufid, 1, split(a:resp.body, "\r"))
  setlocal buftype=nofile
  setlocal ft=diff
endfunction

function! gh#pulls#diff() abort
  let b:gh_preview_diff_bufid = bufnr()

  call gh#gh#init_buffer()
  call gh#gh#set_message_buf('loading')

  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/pulls/\(.*\)/diff$')
  call gh#github#pulls#diff(m[1], m[2], m[3])
        \.then(function('s:set_diff_contents'))
        \.then({-> gh#map#apply('gh-buffer-pull-diff', b:gh_preview_diff_bufid)})
        \.catch({err -> execute('call gh#gh#set_message_buf(err.body)', '')})
        \.finally(function('gh#gh#global_buf_settings'))
endfunction

