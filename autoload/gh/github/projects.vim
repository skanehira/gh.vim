" projects
" Author: skanehira
" License: MIT

function! gh#github#projects#list(type, auth, param) abort
  let settings = {
        \ 'method': 'GET',
        \ 'param': a:param
        \ }

  if a:type is# 'org'
    let settings['url'] = printf('https://api.github.com/orgs/%s/projects', a:auth.org)
  else
    let settings['url'] = printf('https://api.github.com/repos/%s/%s/projects', a:auth.owner, a:auth.repo)
  endif

  return gh#http#request(settings)
endfunction
