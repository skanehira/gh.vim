" pulls
" Author: skanehira
" License: MIT

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
        \ 'url': url .. pr.number
        \ }})

  let header = [
        \ 'number',
        \ 'state',
        \ 'user',
        \ 'title'
        \ ]

  let list['header'] = header
  let list.data = data

  call gh#provider#list#open(list)

  nnoremap <buffer> <silent> <Plug>(gh_pull_open_browser) :<C-u>call <SID>pull_open()<CR>
  nnoremap <buffer> <silent> <Plug>(gh_pull_diff) :<C-u>call <SID>pull_open_diff()<CR>
  nnoremap <buffer> <silent> <Plug>(gh_pull_url_yank) :<C-u>call <SID>pull_url_yank()<CR>
  nmap <buffer> <silent> <C-o> <Plug>(gh_pull_open_browser)
  nmap <buffer> <silent> ghd <Plug>(gh_pull_diff)
  nmap <buffer> <silent> ghy <Plug>(gh_pull_url_yank)
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

