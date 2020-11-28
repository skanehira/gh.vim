" bookmark
" Author: skanehira
" License: MIT

let s:bookmark_file = expand("~/.gh-bookmark")

function! gh#bookmark#list() abort
  call gh#gh#init_buffer()
  setlocal buftype=acwrite
  setlocal ft=gh-bookmarks

  nnoremap <buffer> <silent> q :bw!<CR>

  nnoremap <buffer> <silent> <Plug>(gh_bookmark_open) :<C-u>call <SID>bookmark_open()<CR>
  nmap <buffer> <silent> gho <Plug>(gh_bookmark_open)

  let s:gh_bookmark_list_bufid = bufnr()

  if filereadable(s:bookmark_file)
    let lnum = 1
    for bufname in readfile(s:bookmark_file)
      call setbufline(s:gh_bookmark_list_bufid, lnum, bufname)
      let lnum += 1
    endfor
  endif

  augroup gh-bookmark-update
    au!
    au BufWriteCmd <buffer> call s:bookmark_file_update()
  augroup END
endfunction

function! s:bookmark_open() abort
  let bufname = getbufline(s:gh_bookmark_list_bufid, line('.'))
  if empty(bufname)
    return
  endif
  exe printf('new %s', bufname[0])
endfunction

function! s:bookmark_file_update() abort
  try
    if filewritable(s:bookmark_file)
      let lines = getbufline(s:gh_bookmark_list_bufid, 1, '$')
      call writefile(lines, s:bookmark_file)
    endif
    set nomodified
  catch
    call gh#gh#message(v:exception)
    return
  endtry
endfunction
