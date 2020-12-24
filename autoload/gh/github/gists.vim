" gist
" Author: skanehira
" License: MIT

let s:gist_list_query =<< trim END
{
  user (login: "%s") {
    gists(first: 50, privacy: PUBLIC, orderBy: {field: CREATED_AT, direction: DESC}) {
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
    }
  }
}
END
let s:gist_list_query = join(s:gist_list_query)

let s:gist_query =<< trim END
{
  user (login: "%s") {
    gist(name: "%s") {
      name
      description
      files {
        name
        text
      }
      url
      pushedAt
      createdAt
    }
  }
}
END
let s:gist_query = join(s:gist_query)

function! gh#github#gists#list(owner) abort
  let query = {'query': printf(s:gist_list_query, a:owner)}
  return gh#graphql#query(query).then({resp -> resp.body.data.user.gists.nodes})
endfunction

function! gh#github#gists#one(id) abort
  let query = {'query': printf(s:gist_query, a:id)}
  return gh#graphql#query(query).then({resp -> resp.body.data.user.gist})
endfunction
