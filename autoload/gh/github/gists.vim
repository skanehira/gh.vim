" gist
" Author: skanehira
" License: MIT

let s:gist_list_query =<< trim END
{
  user (login: "%s") {
    gists(first: 30, privacy: %s, %s orderBy: {field: CREATED_AT, direction: DESC}) {
      nodes {
        owner {
          login
        }
        name
        description
        isPublic
        files {
          name
          text
        }
        url
        stargazerCount
        pushedAt
        createdAt
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
}
END
let s:gist_list_query = join(s:gist_list_query)

let s:gist_query =<< trim END
{
  user (login: "%s") {
    gist(name: "%s") {
      owner {
        login
      }
      name
      description
      isPublic
      files {
        name
        text
      }
      url
      stargazerCount
      pushedAt
      createdAt
    }
  }
}
END
let s:gist_query = join(s:gist_query)

function! gh#github#gists#list(owner, privacy, ...) abort
  if a:0 is# 1
    let query = {'query': printf(s:gist_list_query, a:owner, a:privacy, printf('after: "%s", ', a:1))}
  else
    let query = {'query': printf(s:gist_list_query, a:owner, a:privacy, '')}
  endif
  return gh#graphql#query(query).then({resp -> {
        \ 'gists': resp.body.data.user.gists.nodes,
        \ 'page_info': resp.body.data.user.gists.pageInfo
        \ }})
endfunction

function! gh#github#gists#gist(owner, id) abort
  let query = {'query': printf(s:gist_query, a:owner, a:id)}
  return gh#graphql#query(query).then({resp -> resp.body.data.user.gist})
endfunction

function! gh#github#gists#update(id, data) abort
  let settings = {
        \ 'method': 'PATCH',
        \ 'url': printf('https://api.github.com/gists/%s', a:id),
        \ 'data': a:data,
        \ }

  return gh#http#request(settings)
endfunction

function! gh#github#gists#create(data) abort
  let settings = {
        \ 'method': 'POST',
        \ 'url': 'https://api.github.com/gists',
        \ 'data': a:data,
        \ }
  return gh#http#request(settings)
endfunction
