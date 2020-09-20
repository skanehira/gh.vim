" buffer
" Author: skanehira
" License: MIT

" config
" {
"   opener: 'new',
"   buffer: {
"     type: 'nofile'
"     options: [
"       'nonumber',
"       'noswapfile',
"       'nobuflisted',
"     ]
"   }
" }
function! gh#buffer#new(name, ...) abort
  " create config
  let config = #{
        \ opener: 'new',
        \ buffer: #{
        \   type: 'nofile',
        \   name: a:name,
        \   options: [
        \     'bufhidden=wipe',
        \     'nonumber',
        \     'noswapfile',
        \     'nobuflisted',
        \   ],
        \ },
        \ }

  if a:0 > 0
    if has_key(a:1, 'opener')
      let config.opener = a:1.opener
    endif

    if has_key(a:1, 'buffer')
      for [k, v] in items(a:1.buffer)
        let config.buffer[k] = v
      endfor
    endif
  endif

  call execute(printf('%s %s', config.opener, a:name))

  let config.buffer['id'] = bufnr()

  " set options
  call execute('setlocal buftype=' . config.buffer.type)
  for op in config.buffer.options
    call execute('setlocal ' . op)
  endfor

  " new manager object
  let manager = #{
        \ opener: config.opener,
        \ buffer: config.buffer,
        \ open: function('s:_open'),
        \ close: function('s:_close'),
        \ delete: function('s:_delete'),
        \ focus: function('s:_focus'),
        \ show: function('s:_show'),
        \ winid: function('s:_winid'),
        \ get_contents: function('s:_get_contents'),
        \ set_contents: function('s:_set_contents'),
        \ execute: function('s:_execute'),
        \ }

  return manager
endfunction

function! s:_open() abort dict
  if bufexists(self.buffer.id) || buflisted(self.buffer.id)
    if self.winid()
      call self.focus()
      return
    endif
    call self.show()
  endif
endfunction

function! s:_close() abort dict
  if self.winid()
    call execute('close')
  endif
endfunction

function! s:_delete() abort dict
  call execute('bw! ' . self.buffer.id)
endfunction

function! s:_focus() abort dict
  let winid = self.winid()
  if winid
    call win_gotoid(winid)
  endif
endfunction

function! s:_show() abort dict
  call execute(printf('%s | b %s', self.opener, self.buffer.id))
endfunction

function! s:_winid() abort dict
  let winid = bufwinid(self.buffer.id)
  return winid is# -1 ? 0 : winid
endfunction

" config
" {
"   all: v:true,
"   start: 1,
"   end: 10,
" }
function! s:_get_contents(...) abort dict
  if a:0 is# 0
    return getbufline(self.buffer.id, 1, '$')
  endif

  let start = 1
  let end = '$'

  if has_key(a:1, 'start')
    let start = a:1.start
  endif
  if has_key(a:1, 'end')
    let end= a:1.end
  endif
  return getbufline(self.buffer.id, start, end)
endfunction

function! s:_set_contents(contents, ...) abort dict
  let start = 1
  if a:0 > 0
    let start = a:1
  endif
  call setbufline(self.buffer.id, start, a:contents)
endfunction

function! s:_execute(cmd) abort dict
  let winid = self.winid()
  if winid isnot# -1
    call win_execute(winid, a:cmd)
  endif
endfunction
