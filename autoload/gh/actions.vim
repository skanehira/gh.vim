" actions
" Author: skanehira
" License: MIT

let s:Promise = vital#gh#import('Async.Promise')

function! gh#actions#list() abort
  setlocal ft=gh-actions
  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/actions?*\(.*\)')

  let b:gh_action_list_bufid = bufnr()

  let param = gh#http#decode_param(m[3])
  if !has_key(param, 'page')
    let param['page'] = 1
  endif

  let b:gh_action_list = {
        \ 'repo': {
        \   'owner': m[1],
        \   'name': m[2],
        \ },
        \ 'param': param,
        \ }

  call gh#gh#init_buffer()
  call gh#gh#set_message_buf('loading')

  call gh#github#actions#list(b:gh_action_list.repo.owner, b:gh_action_list.repo.name, b:gh_action_list.param)
        \.then(function('s:set_action_list'))
        \.then({-> gh#map#apply('gh-buffer-action-list', b:gh_action_list_bufid)})
        \.catch({err -> execute('call gh#gh#error_message(err.body)', '')})
        \.finally(function('gh#gh#global_buf_settings'))
endfunction

function! s:set_action_list(resp) abort
  if empty(a:resp.body)
    call gh#gh#set_message_buf('not found any actions')
    return
  endif

  let b:gh_actions_tree = {
        \ 'id': a:resp.body.total_count,
        \ 'name': b:gh_action_list.repo.name,
        \ 'state': 'open',
        \ 'path': printf('%d', a:resp.body.total_count),
        \ 'markable': 0,
        \ 'children': []
        \ }

  call s:make_tree(a:resp.body.workflow_runs)
  call gh#provider#tree#open(b:gh_actions_tree)

  nnoremap <buffer> <silent> <Plug>(gh_actions_open_browser) :call <SID>open_browser()<CR>
  nnoremap <buffer> <silent> <Plug>(gh_actions_yank_url) :call <SID>yank_url()<CR>
  nnoremap <buffer> <silent> <Plug>(gh_actions_open_logs) :call <SID>open_logs()<CR>

  nmap <buffer> <silent> <C-o> <Plug>(gh_actions_open_browser)
  nmap <buffer> <silent> ghy <Plug>(gh_actions_yank_url)
  nmap <buffer> <silent> gho <Plug>(gh_actions_open_logs)
endfunction

function! s:get_selected_nodes() abort
  let nodes = []
  for node in values(gh#provider#tree#marked_nodes())
    call add(nodes, node)
  endfor
  if empty(nodes)
    let nodes = [gh#provider#tree#current_node()]
  endif
  return nodes
endfunction

function! s:get_selected_urls() abort
  let urls = []
  for node in s:get_selected_nodes()
    if exists('node.info.html_url')
      call add(urls, node.info.html_url)
    endif
  endfor
  return urls
endfunction

function! s:yank_url() abort
  let urls = s:get_selected_urls()
  if empty(urls)
    return
  endif

  call gh#provider#tree#clean_marked_nodes()
  call gh#provider#tree#redraw()

  call gh#gh#yank(urls)
endfunction

function! s:open_browser() abort
  for url in s:get_selected_urls()
    call gh#gh#open_url(url)
  endfor
  call gh#provider#tree#clean_marked_nodes()
  call gh#provider#tree#redraw()
endfunction

function! s:get_status_annotation(status, conclusion) abort
  let status = '✗ '
  if a:conclusion is# v:null
    if a:status is# 'in_progress'
      let status = '◉ '
    elseif a:status is# 'queued'
      let status = '◎ '
    endif
  endif
  if a:conclusion is# 'success'
    let status = '✓ '
  elseif a:conclusion is# 'skipped'
    let status = 'ℹ '
  elseif a:conclusion is# 'neutral'
    let status = '❑ '
  endif
  return status
endfunction

function! s:make_tree(actions) abort
  let b:gh_actions = []
  let promises = []

  for action in a:actions
    let conclusion = 'running'
    if action.conclusion isnot# v:null
      let conclusion = action.conclusion
    endif

    let status = s:get_status_annotation(action.status, action.conclusion)
    let message = split(action.head_commit.message, '\r\?\n')[0] .. '...'
    let author = '@' .. action.head_commit.author.name

    let node = {
          \ 'id': action.id,
          \ 'name': printf('%s %s %s %s', status, message, author, printf('[%s]', action.head_branch)),
          \ 'path': printf('%s/%s', b:gh_actions_tree.id, action.id),
          \ 'markable': 1,
          \ 'info': action
          \ }
    call add(b:gh_actions, action)
    call add(b:gh_actions_tree.children, node)

    call add(promises, gh#http#get(action.jobs_url)
          \.then(function('s:set_job_list', [node])))
  endfor
  call s:Promise.all(promises)
        \.catch({err -> gh#gh#error_message(err.body)})
        \.finally({-> gh#provider#tree#redraw()})
endfunction

function! s:set_job_list(node, resp) abort
  if empty(a:resp.body)
    return
  endif

  let node = a:node
  let node['children'] = []
  let node['state'] = 'close'
  for job in a:resp.body.jobs
    let status = s:get_status_annotation(job.status, job.conclusion)
    let job['log_url'] = job.url .. '/logs'
    let child = {
          \ 'id': job.id,
          \ 'name': printf('%s %s', status, job.name),
          \ 'path': printf('%s/%s', a:node.path, job.id),
          \ 'markable': 1,
          \ 'info': job
          \ }
    if !empty(job.steps)
      let child['children'] = []
      let child['state'] = 'close'
      for step in job.steps
        let status = s:get_status_annotation(step.status, step.conclusion)
        let s = {
              \ 'id': step.number,
              \ 'name': printf('%s #%d %s', status, step.number, step.name),
              \ 'path': printf('%s/%s', child.path, step.number),
              \ 'markable': 0
              \ }
        call add(child.children, s)
      endfor
    endif
    call add(node.children, child)
  endfor
endfunction

function! gh#actions#fold_logs(lnum) abort
  let line = getline(a:lnum)
  if line =~# '.*##\[group\].*' || line =~# '.*##\[section\]Starting'
    return 'a1'
  elseif line =~# '.*##\[endgroup\]' || line =~# '.*##\[section\]Finishing'
    return 's1'
  endif
  return '='
endfunction

function! s:open_logs() abort
  let nodes = s:get_selected_nodes()
  if empty(nodes)
    return
  endif

  call gh#provider#tree#clean_marked_nodes()
  call gh#provider#tree#redraw()

  let token = gh#gh#get_token()
  if empty(token)
    call gh#gh#message('g:gh_token is undefined. please set like
    \ `let g:gh_token = xxxxxxxxxxxxxxxxxxxx` or login using `gh` cli.')
    return
  endif

  for node in nodes
    if exists('node.info.log_url')
      let open = gh#gh#decide_open()
      if empty(open)
        call gh#gh#message('cancelled')
        return
      endif

      let cmd = [
            \ 'curl', '-L',
            \ '-H', 'Accept: application/vnd.github.v3+json',
            \ '-H', printf('Authorization: token %s', token),
            \ node.info.log_url
            \ ]
      let opt = {
            \ 'bufname': substitute(node.info.log_url, 'https:\/\/api\.github.com\/repos\/', 'gh:\/\/', 'g'),
            \ 'open': open,
            \ }
      call gh#gh#termopen(cmd, opt)
      setlocal ft=gh-actions-logs
    endif
  endfor
endfunction
