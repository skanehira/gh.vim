" github
" Author: skanehira
" License: MIT
" reference https://github.com/vim-jp/vital.vim/blob/master/autoload/vital/__vital__/Web/HTTP.vim

" from Vital.Async.Promise-example-job help
let s:Promise = vital#vital#import('Async.Promise')
let s:HTTP = vital#vital#import('Web.HTTP')

function! s:_readfile(file) abort
  if filereadable(a:file)
    return join(readfile(a:file, 'b'), "\n")
  endif
  return ''
endfunction

function! s:parseHeader(headers) abort
  let header = {}
  for h in a:headers
    let matched = matchlist(h, '^\([^:]\+\):\s*\(.*\)$')
    if !empty(matched)
      let [name, value] = matched[1 : 2]
      let header[name] = value
    endif
  endfor
  return header
endfunction

function! s:_tempname() abort
  return tr(tempname(), '\', '/')
endfunction

function! s:read(chan, part) abort
  let out = []
  while ch_status(a:chan, {'part' : a:part}) =~# 'open\|buffered'
    call add(out, ch_read(a:chan, {'part' : a:part}))
  endwhile
  return join(out, "\n")
endfunction

function! s:sh(...) abort
  let cmd = join(a:000, ' ')

  return s:Promise.new({resolve, reject -> job_start(cmd, {
        \   'drop' : 'never',
        \   'close_cb' : {ch -> 'do nothing'},
        \   'exit_cb' : {ch, code ->
        \     code ? reject(s:read(ch, 'err')) : resolve(s:read(ch, 'out'))
        \   },
        \ })})
endfunction

function! s:make_response(header_tmp, body) abort
  let headerstr = s:_readfile(a:header_tmp)
  call delete(a:header_tmp)
  let header_chunks = split(headerstr, "\r\n\r\n")
  let headers = map(header_chunks, 'split(v:val, "\r\n")')[0]
  let header = s:parseHeader(headers[1:])

  let body = a:body
  if header["Content-Type"] is# 'application/json; charset=utf-8'
    let body = json_decode(a:body)
  endif

  let resp = #{
        \ status: split(headers[0], " ")[1],
        \ header: header,
        \ body: body,
        \ }
  return resp
endfunction

function! gh#http#get(url, ...) abort
  let tmp = s:_tempname()
  let token = get(g:, 'gh_token', '')
  if empty(token)
    return
  endif

  let cmd = ['curl', printf('--dump-header "%s"', tmp), '-H', printf('"Authorization: token %s"', token)]

  let length = len(a:000)

  if  length > 0
    for k in keys(a:1)
      let cmd += ['-H', printf('"%s: %s"', k, a:1[k])]
    endfor
  endif

  if length > 1
    " TODO query parameter
  endif

  let cmd += [a:url]

  return call('s:sh', cmd)
        \.then(function('s:make_response', [tmp]))
        \.then({res -> res.status is# '200' ? s:Promise.resolve(res) : s:Promise.reject(res.body.message)})
endfunction
