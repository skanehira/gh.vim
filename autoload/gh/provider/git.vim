" git
" Author: skanehira
" License: MIT

" {
"   "owner": "skanehira",
"   "name": "gh.vim",
" }
function! gh#provider#git#repo_info() abort
  if !executable('git')
    call gh#gh#error_message('not found git')
    return
  endif

  let remote = system('git remote get-url origin')
  return gh#provider#git#parse_remote(trim(remote))
endfunction

function! gh#provider#git#parse_remote(remote) abort
  let parts = split(a:remote, "://")
  let proto = parts[0]
  let path = parts[1]
  " if url is end with xxx.git
  let cut_idx = stridx(path, '.git')
  if cut_idx > 0
    let path = path[:cut_idx-1]
  endif

  " github repository url patterns
  "   ssh://git@github.com/skanehira/gh.vim
  "   git://github.com/skanehira/gh.vim
  "   https://github.com/skanehira/gh.vim
  "   https://github.com/skanehira/gh.vim.git
  if proto is# 'ssh' || proto is# 'git' || proto =~# 'https'
    let paths = split(path, '/')
    let or = paths[-2:]
    return {'owner': or[0], 'name': or[1]}
  endif
  throw 'unknown protocol: ' .. proto
endfunction
