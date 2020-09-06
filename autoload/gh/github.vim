" github
" Author: skanehira
" License: MIT

function! s:github_issues(query) abort
  let q = s:HTTP.encodeURIComponent(a:query)
  let url = 'https://api.github.com/search/issues?q=' . q
  return s:sh('curl', '-H', sprintf('Authorization: token: %s', s:token), url)
        \.then({data -> json_decode(data)})
        \.then({res -> has_key(res, 'items') ?
        \ res.items :
        \ execute('throw ' . string(res.message))})
endfunction

function! s:pulls(data) abort
  echom a:data
endfunction

function! gh#github#pulls(owner, repo) abort
  let url = printf('https://api.github.com/repos/%s/%s/pulls', a:owner, a:repo)
  call gh#http#get(url)
        \.then(function('s:pulls'))
        \.catch(function('gh#error'))
endfunction
