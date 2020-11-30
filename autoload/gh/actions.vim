" actions
" Author: skanehira
" License: MIT

function! gh#actions#list() abort
  setlocal ft=gh-actions
  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/actions?*\(.*\)')

  call gh#gh#delete_buffer(s:, 'gh_action_list_bufid')
  let s:gh_action_list_bufid = bufnr()

  let param = gh#http#decode_param(m[3])
  if !has_key(param, 'page')
    let param['page'] = 1
  endif

  let s:action_list = {
        \ 'repo': {
        \   'owner': m[1],
        \   'name': m[2],
        \ },
        \ 'param': param,
        \ }

  call gh#gh#init_buffer()
  call gh#gh#set_message_buf('loading')

  call gh#github#actions#list(s:action_list.repo.owner, s:action_list.repo.name, s:action_list.param)
        \.then(function('s:set_action_list'))
        \.then({-> gh#map#apply('gh-buffer-action-list', s:gh_action_list_bufid)})
        \.catch({err -> execute('call gh#gh#error_message(err.body)', '')})
        \.finally(function('gh#gh#global_buf_settings'))
endfunction

function! s:set_action_list(resp) abort
  if empty(a:resp.body)
    call gh#gh#set_message_buf('not found any actions')
    return
  endif

  let s:tree = {
        \ 'id': a:resp.body.total_count,
        \ 'name': s:action_list.repo.name,
        \ 'state': 'open',
        \ 'path': s:action_list.repo.name,
        \ 'children': []
        \ }

  call s:make_tree(a:resp.body.workflow_runs)
  call gh#tree#open(s:tree)

  nnoremap <buffer> <silent> <Plug>(gh_actions_open_browser) :call <SID>open_browser()<CR>
  nnoremap <buffer> <silent> <Plug>(gh_actions_yank_url) :call <SID>yank_url()<CR>
  nnoremap <buffer> <silent> <Plug>(gh_actions_open_logs) :call <SID>open_logs()<CR>

  nmap <buffer> <silent> <C-o> <Plug>(gh_actions_open_browser)
  nmap <buffer> <silent> ghy <Plug>(gh_actions_yank_url)
  nmap <buffer> <silent> gho <Plug>(gh_actions_open_logs)
endfunction

function! s:get_selected_nodes() abort
  let nodes = []
  for node in values(gh#tree#marked_nodes())
    call add(nodes, node)
  endfor
  if empty(nodes)
    let nodes = [gh#tree#current_node()]
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

  call gh#tree#clean_marked_nodes()
  call gh#tree#redraw()

  let ln = "\n"
  if &ff == "dos"
    let ln = "\r\n"
  endif

  call gh#gh#yank(join(urls, ln))
  call gh#gh#message('copied ' .. urls[0])
  for url in urls[1:]
    call gh#gh#message('       ' .. url)
  endfor
endfunction

function! s:open_browser() abort
  for url in s:get_selected_urls()
    call gh#gh#open_url(url)
  endfor
  call gh#tree#clean_marked_nodes()
  call gh#tree#redraw()
endfunction

function! s:get_status_annotation(status, conclusion) abort
  let status = '✗'
  if a:conclusion is# v:null
    if a:status is# 'in_progress'
      let status = '◉'
    elseif a:status is# 'queued'
      let status = '◎'
    endif
  endif
  if a:conclusion is# 'success'
    let status = '✓'
  elseif a:conclusion is# 'skipped'
    let status = '❢'
  elseif a:conclusion is# 'neutral'
    let status = '❑'
  endif
  return status
endfunction

function! s:make_tree(actions) abort
  let s:actions = []

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
          \ 'path': printf('%s/%s', s:tree.id, action.id),
          \ 'info': action
          \ }
    call add(s:actions, action)
    call add(s:tree.children, node)
    call gh#http#get(action.jobs_url)
          \.then(function('s:set_job_list', [node]))
          \.catch({err -> execute('call gh#gh#error_message(err.body)', '')})
          \.finally({-> gh#tree#redraw()})
  endfor
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
          \ 'path': printf('%s/%s', a:node.id, job.id),
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
              \ 'path': printf('%s/%s', job.id, step.number)
              \ }
        call add(child.children, s)
      endfor
    endif
    call add(node.children, child)
  endfor
endfunction

function! s:open_logs() abort
  let nodes = s:get_selected_nodes()
  if empty(nodes)
    return
  endif

  call gh#tree#clean_marked_nodes()
  call gh#tree#redraw()

  let token = get(g:, 'gh_token', '')
  if empty(token)
    call gh#gh#message('g:gh_token is undefined')
    return
  endif

  for node in nodes
    if exists('node.info.log_url')
      let cmd = [
            \ 'curl', '-L',
            \ '-H', 'Accept: application/vnd.github.v3+json',
            \ '-H', printf('Authorization: token %s', token),
            \ node.info.log_url
            \ ]
      let opt = {
            \ 'bufname': substitute(node.info.log_url, 'https:\/\/api\.github.com\/repos\/', 'gh:\/\/', 'g')
            \ }
      call gh#gh#termopen(cmd, opt)
      setlocal ft=gh-actions-logs
    endif
  endfor
endfunction
