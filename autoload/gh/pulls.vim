" gh
" Author: skanehira
" License: MIT

function! s:pull_list(resp) abort
  nnoremap <buffer> <silent> <Plug>(gh_pull_list_next) :<C-u>call <SID>pull_list_change_page('+')<CR>
  nnoremap <buffer> <silent> <Plug>(gh_pull_list_prev) :<C-u>call <SID>pull_list_change_page('-')<CR>
  nmap <C-l> <Plug>(gh_pull_list_next)
  nmap <C-h> <Plug>(gh_pull_list_prev)

  if empty(a:resp.body)
    call gh#gh#set_message_buf('not found pull requests')
    return
  endif

  let lines = []
  let s:pulls = []
  let url = printf('https://github.com/%s/%s/pull/', s:pull_list.repo.owner, s:pull_list.repo.name)

  for pr in a:resp.body
    call add(lines, printf("%s\t%s\t%s\t%s", pr.number, pr.state, pr.title, pr.user.login))
    call add(s:pulls, #{
          \ number: pr.number,
          \ url: url . pr.number,
          \ })
  endfor

  call setbufline(t:gh_pulls_list_bufid, 1, lines)

  nnoremap <buffer> <silent> <Plug>(gh_pull_open_browser) :<C-u>call <SID>pull_open()<CR>
  nnoremap <buffer> <silent> <Plug>(gh_pull_diff) :<C-u>call <SID>open_pull_diff()<CR>
  nmap <C-o> <Plug>(gh_pull_open_browser)
  nmap ghd <Plug>(gh_pull_diff)
endfunction

function! s:pull_list_change_page(op) abort
  if a:op is# '+'
    let s:pull_list.param.page += 1
  else
    if s:pull_list.param.page < 2
      return
    endif
    let s:pull_list.param.page -= 1
  endif

  let cmd = printf('vnew gh://%s/%s/pulls?%s',
        \ s:pull_list.repo.owner, s:pull_list.repo.name, gh#http#encode_param(s:pull_list.param))
  call execute(cmd)
endfunction

function! s:pull_open() abort
  call gh#gh#open_url(s:pulls[line('.')-1].url)
endfunction

function! gh#pulls#list() abort
  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/pulls?*\(.*\)')

  call gh#gh#delete_tabpage_buffer('gh_pulls_list_bufid')
  call gh#gh#delete_tabpage_buffer('gh_preview_diff_bufid')
  let t:gh_pulls_list_bufid = bufnr()

  let param = gh#http#decode_param(m[3])
  if !has_key(param, 'page')
    let param['page'] = 1
  endif

  let s:pull_list = #{
        \ repo: #{
        \   owner: m[1],
        \   name: m[2],
        \ },
        \ param: param,
        \ }

  call gh#gh#init_buffer()
  call gh#gh#set_message_buf('loading')

  call gh#github#pulls#list(s:pull_list.repo.owner, s:pull_list.repo.name, s:pull_list.param)
        \.then(function('s:pull_list'))
        \.catch({err -> execute('call gh#gh#set_message_buf(err.body)', '')})
        \.finally(function('gh#gh#global_buf_settings'))
endfunction

function! s:open_pull_diff() abort
  call gh#gh#delete_tabpage_buffer('gh_preview_diff_bufid')
  let number = s:pulls[line('.')-1].number
  call execute(printf('belowright vnew gh://%s/%s/pulls/%s/diff',
        \ s:pull_list.repo.owner, s:pull_list.repo.name, number))
endfunction

function! s:set_diff_contents(resp) abort
  call setbufline(t:gh_preview_diff_bufid, 1, split(a:resp.body, "\r"))
  setlocal buftype=nofile
  setlocal ft=diff
endfunction

function! gh#pulls#diff() abort
  call gh#gh#delete_tabpage_buffer('gh_preview_diff_bufid')
  let t:gh_preview_diff_bufid = bufnr()

  call gh#gh#init_buffer()
  call gh#gh#set_message_buf('loading')

  let m = matchlist(bufname(), 'gh://\(.*\)/\(.*\)/pulls/\(.*\)/diff$')
  call gh#github#pulls#diff(m[1], m[2], m[3])
        \.then(function('s:set_diff_contents'))
        \.catch({err -> execute('call gh#gh#set_message_buf(err.body)', '')})
        \.finally(function('gh#gh#global_buf_settings'))
endfunction

