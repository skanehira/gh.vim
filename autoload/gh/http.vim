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
  return join(out, "\r")
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

function! s:make_response(body) abort
  let headerstr = s:_readfile(s:tmp_file.header)
  call delete(s:tmp_file.header)
  if has_key(s:tmp_file, 'body')
    call delete(s:tmp_file.body)
  endif

  let header_chunks = split(headerstr, "\r\n\r\n")
  let headers = map(header_chunks, 'split(v:val, "\r\n")')[0]
  let status = split(headers[0], " ")[1]
  let header = s:parseHeader(headers[1:])

  let body = a:body
  if header["Content-Type"] is# 'application/json; charset=utf-8'
    let body = json_decode(a:body)
    if status isnot# '200' && has_key(body, 'message')
        let body = body.message
    endif
  endif

  let resp = #{
        \ status: status,
        \ header: header,
        \ body: body,
        \ }

  if status is# '200' || status is# '201' || status is# '204'
    return s:Promise.resolve(resp)
  endif
  return s:Promise.reject(resp)
endfunction

function! gh#http#get(url) abort
  let settings = #{
        \ url: a:url,
        \ }
  return gh#http#request(settings)
endfunction

function! gh#http#request(settings) abort
  let token = get(g:, 'gh_token', '')
  if empty(token)
    return s:Promise.reject('[qh.vim] g:gh_token is undefined')
  endif

  let method = has_key(a:settings, 'method') ? a:settings.method : 'GET'

  let s:tmp_file = #{
        \ header: s:_tempname(),
        \ }

  let cmd = ['curl', '-s', '-X', method, printf('--dump-header "%s"', s:tmp_file.header),
        \ '-H', printf('"Authorization: token %s"', token)]

  if method is# 'POST' || method is# 'PUT' || method is# 'PATCH'
    let tmp = s:_tempname()
    call writefile([json_encode(a:settings.data)], tmp)
    let s:tmp_file['body'] = tmp
    let cmd += ['-H', '"Content-Type: application/json"', '-d', '@' . s:tmp_file.body]
  endif

  if has_key(a:settings, 'headers')
    for k in keys(a:settings.headers)
      let cmd += ['-H', printf('"%s: %s"', k, a:settings.headers[k])]
    endfor
  endif

  if has_key(a:settings, 'param')
    let cmd += [printf('"%s?%s"', a:settings.url, s:HTTP.encodeURI(a:settings.param))]
  else
    let cmd += [a:settings.url]
  endif

  return call('s:sh', cmd)
        \.then(function('s:make_response'))
        \.catch(function('s:make_error_responsee'))
endfunction

function! s:make_error_responsee(err) abort
  if type(a:err) is# type({})
    return s:Promise.reject(a:err)
  endif
  return s:Promise.reject(#{
        \ status: '999',
        \ body: 'unknown error',
        \ })
endfunction

function! gh#http#decode_param(arg) abort
  let param = {}
  for p in split(a:arg, '&')
    let kv = split(p, '=')
    if len(kv) is# 1
      continue
    endif
    let param[kv[0]] = kv[1]
  endfor
  return param
endfunction
