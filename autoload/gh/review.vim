" review
" Author: skanehira
" License: MIT

let s:Promise = vital#gh#import('Async.Promise')
let s:DIFF_LEFT_BUFID = -1
let s:DIFF_RIGHT_BUFID = -1
let s:diff_file_cache = {}

function! gh#review#start() abort
  setlocal ft=gh-pulls-review
  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/pulls/*\(.*\)/review')
  let s:gh_pull_review = {
        \ 'owner': m[1],
        \ 'name': m[2],
        \ 'number': m[3],
        \ }

  " TODO use this buf to display diff files?
  exe 'bw!' bufnr() | tabnew
  call gh#gh#message('loading...')
  let s:DIFF_LEFT_BUFID = bufnr()
  call s:init_diff_buf()
  " clear cache when open new buffer
  let s:diff_file_cache = {}

  call gh#github#pulls#pull(s:gh_pull_review.owner, s:gh_pull_review.name, s:gh_pull_review.number)
        \.then({resp -> s:get_base_commit(resp)})
        \.catch({err -> gh#gh#error_message(err.body)})
endfunction

function! s:get_base_commit(resp) abort
  let s:base_commit_id = a:resp.body.base.sha
  call gh#github#pulls#files(s:gh_pull_review.owner, s:gh_pull_review.name, s:gh_pull_review.number)
        \.then({resp -> s:make_diff_files(resp)})
endfunction

function! s:make_diff_files(resp) abort
  let s:diff_files = []
  for file in a:resp.body
    let base_url = file.status is# 'added' ?
          \ '' : substitute(file.contents_url, '[0-9a-z]\{40}', s:base_commit_id, 'g')
    let head_url = file.status is# 'removed' ?
          \ '' : file.contents_url
    call add(s:diff_files, {
          \ 'path': file.filename,
          \ 'additions': file.additions,
          \ 'deletions': file.deletions,
          \ 'status': file.status,
          \ 'head_url': head_url,
          \ 'base_url': base_url,
          \ })
  endfor

  let s:quickpick_files = map(copy(s:diff_files), { _, file -> file.path })
  call s:open_quickpick_files()
endfunction

function! s:open_quickpick_files() abort
  call gh#provider#quickpick#open({
        \ 'items': s:quickpick_files,
        \ 'filter': 0,
        \ 'debounce': 0,
        \ 'on_accept': function('s:on_accept_open_diff'),
        \ 'on_change': function('s:on_change_dffi_file'),
        \ })
endfunction

function! s:on_change_dffi_file(data, name) abort
  call gh#provider#quickpick#on_change(a:data, a:name, s:quickpick_files)
endfunction

function! s:on_accept_open_diff(data, name) abort
  call gh#gh#message('loading...')
  call gh#provider#quickpick#close()
  let path = a:data.items[0]
  for file in s:diff_files
    if path is# file.path
      call s:get_files_content(file)
      return
    endif
  endfor
  call gh#gh#error_message('not found file contents')
endfunction

function! s:add_diff_cache(url, resp) abort
  let s:diff_file_cache[a:url] = a:resp
  return a:resp
endfunction

function! s:get_file(url) abort
  if has_key(s:diff_file_cache, a:url)
    return s:Promise.resolve(s:diff_file_cache[a:url])
  endif
  return gh#github#repos#get_file(a:url)
        \.then({resp -> s:add_diff_cache(a:url, resp)})
endfunction

function! s:get_files_content(file) abort
  let promises = []
  if empty(a:file.base_url)
    let s:base_diff = ''
  else
    call add(promises, s:get_file(a:file.base_url).then({resp -> execute('let s:base_diff = resp', '')}))
  endif

  if empty(a:file.head_url)
    let s:head_diff = ''
  else
    call add(promises, s:get_file(a:file.head_url).then({resp -> execute('let s:head_diff = resp', '')}))
  endif

  if !empty(promises)
    call s:Promise.all(promises)
          \.then({-> s:open_review_window()})
          \.catch({err -> gh#gh#error_message(err.body)})
          \.finally({-> execute('echom ""', '')})
  endif
endfunction

" {
"   "files": [
"     {"path": "xxx", "additions": 12, "deletions": 10, "head_url": "", "base_url": "", "status": "modified"},
"     {"path": "xxx", "additions": 12, "deletions": 10, "head_url": "", "base_url": "", "status": "modified"}
"   ]
" }
function! s:open_review_window() abort
  let s:DIFF_LEFT_BUFID = s:open_diff_window(s:DIFF_LEFT_BUFID)
  let s:DIFF_RIGHT_BUFID = s:open_diff_window(s:DIFF_RIGHT_BUFID)
  call deletebufline(s:DIFF_LEFT_BUFID, 1, '$')
  call deletebufline(s:DIFF_RIGHT_BUFID, 1, '$')
  call setbufline(s:DIFF_LEFT_BUFID, 1, s:base_diff)
  call setbufline(s:DIFF_RIGHT_BUFID, 1, s:head_diff)
endfunction

function! s:open_diff_window(bufid) abort
  if !bufexists(a:bufid)
    rightbelow vnew
  elseif bufwinid(a:bufid) is# -1
    rightbelow vnew | exe 'b' a:bufid
  else
    return a:bufid
  endif
  call s:init_diff_buf()
  return bufnr()
endfunction

function! s:close_diff_window() abort
  silent exe 'bw!' s:DIFF_LEFT_BUFID s:DIFF_RIGHT_BUFID
endfunction

function! s:init_diff_buf() abort
  nnoremap <buffer><silent> ghf :call <SID>open_quickpick_files()<CR>
  nnoremap <buffer><silent> q :call <SID>close_diff_window()<CR>
  setlocal buftype=nofile bufhidden=hide noswapfile number
  diffthis
endfunction
