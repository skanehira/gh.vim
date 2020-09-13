" github
" Author: skanehira
" License: MIT

function! gh#github#repos#list(owner) abort
  return gh#http#get(printf('https://api.github.com/users/%s/repos', a:owner))
endfunction

function! gh#github#repos#files(owner, repo, branch) abort
  let settings = #{
        \ url: printf('https://api.github.com/repos/%s/%s/git/trees/%s', a:owner, a:repo, a:branch),
        \ param: #{
        \   recursive: 1,
        \ },
        \ }
  return gh#http#request(settings)
endfunction

function! gh#github#repos#get_file(url) abort
  return gh#http#get(a:url)
endfunction

function! gh#github#repos#readme(owner, repo) abort
  return gh#http#get(printf('https://raw.githubusercontent.com/%s/%s/master/README.md', a:owner, a:repo))
        \.catch({res -> gh#http#get(printf('https://raw.githubusercontent.com/%s/%s/master/README', a:owner, a:repo))})
endfunction
