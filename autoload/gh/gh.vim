" gh
" Author: skanehira
" License: MIT

" {
"   01: {
"     urls: {
"       self: 'https://github.com/gh/pulls/01',
"       diff: 'https://github.com/gh/pulls/01.diff',
"     }
"   }
"   ...
" }
let s:pr_cache = {}

function! gh#error(msg) abort
  echohl ErrorMsg
  echom '[gh.vim] ' . a:msg
  echohl None
endfunction

function! s:cache(pr) abort
  let s:pr_cache[a:pr.number] = #{
        \ urls: #{
        \   diff: a:pr.diff_url,
        \   self: a:pr.html_url,
        \ }
        \ }
endfunction

function! s:pulls(resp) abort
  let lines = []
  for pr in a:resp.body
    call add(lines, printf("%s\t%s\t%s\t%s", pr.number, pr.state, pr.title, pr.user.login))
    call s:cache(pr)
  endfor

  if len(lines) is# 0
    call setline(1, '-- no data --')
  else
    call setline(1, lines)
  endif
  setlocal nomodifiable
endfunction

function! s:open(op) abort
  let line = getline('.')
  let number = split(line, "\t")[0]

  let url = ''
  if a:op is# 'diff'
    let url = s:pr_cache[number].urls.diff
  elseif a:op is# 'self'
    let url = s:pr_cache[number].urls.self
  endif
  echom url
  call system("xdg-open " . url)
endfunction

function! s:pull_list() abort
  setlocal buftype=nofile
  setlocal number!

  nnoremap <buffer> <silent> q :bw!<CR>
  nnoremap <buffer> <silent> o :call <SID>open('self')<CR>

  let name = split(bufname(), '\/')
  let owner = name[3]
  let repo = name[4]

  call gh#github#pulls(owner, repo)
        \.then(function('s:pulls'))
        \.catch(function('gh#error'))
endfunction

augroup gh-pulls
  au!
  au BufReadCmd gh://pull-list/*/* call s:pull_list()
augroup END
