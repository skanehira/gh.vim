" github
" Author: skanehira
" License: MIT
" reference https://github.com/vim-jp/vital.vim/blob/master/autoload/vital/__vital__/Web/HTTP.vim

" from Vital.Async.Promise-example-job help
let s:Promise = vital#gh#import('Async.Promise')
let s:HTTP = vital#gh#import('Web.HTTP')
let s:Job = vital#gh#import('System.Job')

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

function! s:on_receive(buffer, data) abort dict
  let a:buffer[-1] .= a:data[0]
  call extend(a:buffer, a:data[1:])
endfunction

function! s:sh(...) abort
  let cmd = a:000
  let stdout = ['']
  let stderr = ['']

  return s:Promise.new({
        \ rv, rj -> s:Job.start(cmd, {
        \   'on_stdout': function('s:on_receive', [stdout]),
        \   'on_stderr': function('s:on_receive', [stderr]),
        \   'on_exit': { e ->
        \     e ? rj(join(stderr, "\r")) : rv(join(stdout, "\r"))
        \   }
        \ })
        \})
endfunction

function! s:make_response(tmp_file, body) abort
  let headerstr = s:_readfile(a:tmp_file.header)
  call delete(a:tmp_file.header)
  if has_key(a:tmp_file, 'body')
    call delete(a:tmp_file.body)
  endif

  if empty(headerstr)
    return s:Promise.reject({'status': '999', 'body': 'response header is empty'})
  endif

  let header_chunks = split(headerstr, "\r\n\r\n")
  let headers = map(header_chunks, 'split(v:val, "\r\n")')[0]
  let status = split(headers[0], " ")[1]
  let header = s:parseHeader(headers[1:])
  let body = a:body

  if has_key(header, 'content-type') &&
        \ header['content-type'] is# 'application/json; charset=utf-8'
    if body isnot# ''
      let body = json_decode(a:body)
      if status isnot# '200' && has_key(body, 'message')
        let body = body.message
      endif
    endif
  endif

  let resp = {
        \ 'status': status,
        \ 'header': header,
        \ 'body': body,
        \ }

  if status is# '200' || status is# '201' || status is# '204' || status is# '100'
    return s:Promise.resolve(resp)
  endif
  return s:Promise.reject(resp)
endfunction

function! gh#http#get(url) abort
  let settings = {
        \ 'url': a:url,
        \ }
  return gh#http#request(settings)
endfunction

function! gh#http#request(settings) abort
  let token = gh#gh#get_token()
  if empty(token)
    return s:Promise.reject('[gh.vim] g:gh_token is undefined')
  endif

  let method = has_key(a:settings, 'method') ? a:settings.method : 'GET'

  let tmp_file = {
        \ 'header': s:_tempname(),
        \ }

  let cmd = ['curl', '-s', '-X', method, '--dump-header', tmp_file.header,
        \ '-H', printf('Authorization: token %s', token),
        \ '-H', 'Accept: application/vnd.github.v3+json',
        \ '-H', 'Accept: application/vnd.github.inertia-preview+json']


  if method is# 'POST' || method is# 'PUT' || method is# 'PATCH'
    let tmp = s:_tempname()
    call writefile([json_encode(a:settings.data)], tmp)
    let tmp_file['body'] = tmp
    let cmd += ['-H', 'Content-Type: application/json', '-d', '@' .. tmp_file.body]
  endif

  if has_key(a:settings, 'headers')
    for k in keys(a:settings.headers)
      let cmd += ['-H', printf('%s: %s', k, a:settings.headers[k])]
    endfor
  endif

  if has_key(a:settings, 'param')
    let cmd += [printf('%s?%s', a:settings.url, s:HTTP.encodeURI(a:settings.param))]
  else
    let cmd += [a:settings.url]
  endif

  return call('s:sh', cmd)
        \.then(function('s:make_response', [tmp_file]))
        \.catch(function('s:make_error_responsee'))
endfunction

function! s:make_error_responsee(err) abort
  if has_key(a:err, 'throwpoint')
    return s:Promise.reject({
          \ 'status': '999',
          \ 'body': printf('%s %s', a:err.throwpoint, a:err.exception),
          \ })
  elseif type(a:err) is# type({})
    return s:Promise.reject(a:err)
  endif

  return s:Promise.reject({
        \ 'status': '999',
        \ 'body': 'unknown error',
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

function! gh#http#encode_param(arg) abort
  return join(map(keys(a:arg), {_, k -> join([k, a:arg[k]], '=')}), '&')
endfunction
