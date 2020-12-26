" graphql
" Author: skanehira
" License: MIT

function! gh#graphql#query(query) abort
  let settings = {
        \ 'method': 'POST',
        \ 'url': 'https://api.github.com/graphql',
        \ 'data': a:query,
        \ }
  return gh#http#request(settings)
endfunction
