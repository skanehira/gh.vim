let s:suite = themis#suite('gh')
let s:assert = themis#helper('assert')

function! s:suite.test_get_gh_token()
  let gh_token = gh#gh#get_token()
  call s:assert.false(empty(gh_token))
endfunction
