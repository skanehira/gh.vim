" preview
" Author: skanehira
" License: MIT

" {
"   'filename': 'gh.vim',
"   'contents': ['a', 'b'],
" }
function! gh#provider#preview#open(get_preview_info) abort
  let b:gh_preview_buf = -1
  let b:gh_preview_winid = -1
  let b:gh_preview_enable = 0
  let b:gh_preview_opts = a:get_preview_info()
  let b:gh_preview_updatefunc = a:get_preview_info
  call s:update_preview()

  nnoremap <buffer> <silent> <Plug>(gh_preview_move_down) :call <SID>scroll_popup('down')<CR>
  nnoremap <buffer> <silent> <Plug>(gh_preview_move_up) :call <SID>scroll_popup('up')<CR>
  nnoremap <buffer> <silent> <Plug>(gh_preview_toggle) :call <SID>toggle_preview()<CR>

  nmap <buffer> <silent> ghp <Plug>(gh_preview_toggle)
endfunction

function! gh#provider#preview#update(get_preview_info) abort
  let b:gh_preview_opts = a:get_preview_info()
  call s:update_preview()
endfunction

function! gh#provider#preview#close() abort
  call s:disable_preview()
endfunction

function! s:toggle_preview() abort
  if b:gh_preview_enable
    call s:disable_preview()
  else
    call s:enable_preview()
  endif
endfunction

function! s:enable_preview() abort
  exe printf('augroup gh-preview-%d', bufnr())
    au!
    au BufEnter <buffer> call s:preview()
    au BufLeave <buffer> call s:close_preview_window(b:gh_preview_winid)
    au CursorMoved <buffer> call gh#provider#preview#update(b:gh_preview_updatefunc)
  augroup END

  nmap <buffer> <silent> <C-n> <Plug>(gh_preview_move_down)
  nmap <buffer> <silent> <C-p> <Plug>(gh_preview_move_up)
  call s:open_preview()

  let b:gh_preview_enable = 1
endfunction

function! s:disable_preview() abort
  call s:close_preview_window(b:gh_preview_winid)

  exe printf('augroup gh-preview-%d', bufnr()) | au! | augroup END

  unmap <buffer> <C-n>
  unmap <buffer> <C-p>

  let b:gh_preview_enable = 0
endfunction

function! s:preview() abort
  if !s:has_preview_window(b:gh_preview_winid)
    call s:open_preview()
  endif

  call s:update_preview()
endfunction

if has('nvim')
  function! s:win_execute(id, cmd) abort
    let oldid = win_getid()
    noau call win_gotoid(a:id)
    exe a:cmd
    noau call win_gotoid(oldid)
  endfunction

  function! s:close_preview_window(id) abort
    if s:has_preview_window(a:id)
      call nvim_win_close(a:id, v:false)
    endif
  endfunction

  function! s:has_preview_window(id) abort
    let winids = nvim_list_wins()
    for winid in winids
      if winid is# a:id
        return 1
      endif
    endfor
    return 0
  endfunction

  function! s:open_preview() abort
    let b:gh_preview_buf = nvim_create_buf(v:false, v:true)
    let opts = {
          \ 'relative': 'win',
          \ 'width': &columns/2+1,
          \ 'height': &lines,
          \ 'row': 0,
          \ 'col': &columns/2,
          \ 'style': 'minimal'
          \ }

    let b:gh_preview_winid = nvim_open_win(b:gh_preview_buf, 0, opts)
    call nvim_win_set_option(b:gh_preview_winid, 'number', v:true)
    call gh#provider#preview#update(b:gh_preview_updatefunc)
  endfunction

  function! s:update_preview() abort
    if b:gh_preview_buf is# -1
      return
    endif
    let b:gh_preview_contents_maxrow = len(b:gh_preview_opts.contents)
    call nvim_buf_set_lines(b:gh_preview_buf, 0, -1, v:true, b:gh_preview_opts.contents)
    call s:win_execute(b:gh_preview_winid, printf('do <nomodeline> BufRead %s | normal zn', b:gh_preview_opts.filename))
  endfunction

  function! s:scroll_popup(op) abort
    let [row, col] = nvim_win_get_cursor(b:gh_preview_winid)
    if a:op is# 'up'
      if row ==# 1
        return
      endif
      let row -= 1
    elseif a:op is# 'down'
      if row >= b:gh_preview_contents_maxrow
        return
      endif
      let row += 1
    endif
    call nvim_win_set_cursor(b:gh_preview_winid, [row, col])
  endfunction
else
  function! s:close_preview_window(id) abort
    if s:has_preview_window(a:id)
      call popup_close(a:id)
    endif
  endfunction

  function! s:has_preview_window(id) abort
    for winid in popup_list()
      if winid is# a:id
        return 1
      endif
    endfor
    return 0
  endfunction

  function! s:open_preview() abort
    let b:gh_preview_winid = popup_create([], {
          \ 'line': 1,
          \ 'firstline': 1,
          \ 'col': &columns/2+2,
          \ 'minwidth': &columns/2,
          \ 'minheight': &lines,
          \ })

    call win_execute(b:gh_preview_winid, 'set number')
    call gh#provider#preview#update(b:gh_preview_updatefunc)
  endfunction

  function! s:update_preview() abort
    if b:gh_preview_buf is# -1
      return
    endif
    let b:gh_preview_contents_maxrow = len(b:gh_preview_opts.contents)
    call win_execute(b:gh_preview_winid, printf('do <nomodeline> BufRead %s | normal zn', b:gh_preview_opts.filename))
    call popup_setoptions(b:gh_preview_winid, {'firstline': 1})
    call popup_settext(b:gh_preview_winid, b:gh_preview_opts.contents)
  endfunction

  function! s:scroll_popup(op) abort
    let opt = popup_getoptions(b:gh_preview_winid)
    if a:op is# 'up'
      if opt.firstline ==# 1
        return
      endif
      let opt.firstline -= 1
    elseif a:op is# 'down'
      if opt.firstline >= b:gh_preview_contents_maxrow
        return
      endif
      let opt.firstline += 1
    endif
    call popup_setoptions(b:gh_preview_winid, {'firstline': opt.firstline})
  endfunction
endif


