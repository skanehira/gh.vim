" projects
" Author: skanehira
" License: MIT

function! gh#github#projects#list(type, user_info, param) abort
  let settings = {
        \ 'method': 'GET',
        \ 'param': a:param
        \ }

  if a:type is# 'org'
    let settings['url'] = printf('https://api.github.com/orgs/%s/projects', a:user_info.org)
  else
    let settings['url'] = printf('https://api.github.com/repos/%s/%s/projects', a:user_info.owner, a:user_info.repo)
  endif

  return gh#http#request(settings)
endfunction
