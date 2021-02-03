let s:suite = themis#suite('gh')
let s:assert = themis#helper('assert')

function! s:suite.test_get_gh_token()
  let gh_token = gh#gh#get_token()
  if $USE_GH_CLI
    call s:assert.false(empty(gh_token))
  else
    call s:assert.true(empty(gh_token))
  endif
endfunction

function! s:suite.overwrite_gh_token()
  let g:gh_token = 'xxx'
  let token = gh#gh#get_token()
  call s:assert.equals(token, g:gh_token)
endfunction
