" github
" Author: skanehira
" License: MIT

let s:Base64 = vital#gh#import('Data.Base64')

let s:assignee_list_query =<< trim END
{
  repository(name: "%s", owner: "%s") {
    assignableUsers(first: 100) {
      nodes {
        login
      },
      pageInfo {
        hasNextPage,
        endCursor
      }
    }
  }
}
END
let s:assignee_list_query = join(s:assignee_list_query)

let s:assignee_list_query_with_cursor =<< trim END
{
  repository(name: "%s", owner: "%s") {
    assignableUsers(first: 100, after: "%s") {
      nodes {
        login
      },
      pageInfo {
        hasNextPage,
        endCursor
      }
    }
  }
}
END
let s:assignee_list_query_with_cursor = join(s:assignee_list_query_with_cursor)

function! gh#github#repos#list(owner, param) abort
  let url = printf('https://api.github.com/users/%s/repos', a:owner)
  if a:owner is# 'user'
    let url = 'https://api.github.com/user/repos'
  endif
  let settings = {
        \ 'method': 'GET',
        \ 'url': url,
        \ 'param': a:param,
        \ }
  return gh#http#request(settings)
endfunction

function! gh#github#repos#files(owner, repo, branch) abort
  let settings = {
        \ 'url': printf('https://api.github.com/repos/%s/%s/git/trees/%s', a:owner, a:repo, a:branch),
        \ 'param': {
        \   'recursive': 1,
        \ },
        \ }
  return gh#http#request(settings)
endfunction

function! gh#github#repos#get_file(url) abort
  return gh#http#get(a:url)
        \.then(function('s:decode_content'))
endfunction

function! gh#github#repos#readme(owner, repo) abort
  let url = printf('https://api.github.com/repos/%s/%s/readme', a:owner, a:repo)
  return gh#http#get(url)
        \.then(function('s:decode_content'))
endfunction

function! s:decode_content(resp) abort
  let body = s:Base64.decode(join(split(a:resp.body.content, "\n"), ''))
  return split(body, "\n")
endfunction

function! gh#github#repos#get_repo(owner, repo) abort
  let url = printf('https://api.github.com/repos/%s/%s', a:owner, a:repo)
  return gh#http#get(url)
endfunction

function! gh#github#repos#get_assignees(owner, repo) abort
  let s:assignable_users = { 'assignees': [] }
  let query = {'query': printf(s:assignee_list_query, a:repo, a:owner)}
  return gh#graphql#query(query).then(function('s:set_assignable_users'))
endfunction

function! s:set_assignable_users(resp) abort
  let response_users = a:resp.body.data.repository.assignableUsers
  call extend(s:assignable_users.assignees, response_users.nodes)
  if response_users.pageInfo.hasNextPage
    let query = {'query': printf(s:assignee_list_query_with_cursor
          \ , a:repo, a:owner, response_users.pageInfo.endCursor)}
    call gh#graphql#query(query).then(function('s:get_response'))
  else
    return s:assignable_users
  endif
endfunction
