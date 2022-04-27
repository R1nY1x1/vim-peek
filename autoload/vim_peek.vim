let s:peek_bufname = "vim-peek://result"
let s:last_popup_window = 0
let s:result = []

function! s:echoerr(msg) abort
  echohl ErrorMsg
  echo "[vim-peek]" a:msg
  echohl None
endfunction

function! vim_peek#peek(start, end, ...) abort
  let ln = "\n"
  if &ff == "dos"
    let ln = "\r\n"
  endif

  let text = s:getline(a:start, a:end, ln, a:000)
  if empty(text)
    call s:echoerr("text is emtpy")
    return
  endif

  let cmd = ["echo"] + [text]
  let s:result = []

  call job_start(cmd, {
        \ "out_cb": function("s:peek_out_cb"),
        \ "err_cb": function("s:peek_out_cb"),
        \ "exit_cb": function("s:peek_exit_cb"),
        \ })
endfunction

function! s:getline(start, end, ln, args) abort
  let text = getline(a:start, a:end)
  if !empty(a:args)
    let text = a:args
  endif
  return join(text, a:ln)
endfunction

function! s:peek_out_cb(ch, msg) abort
  call add(s:result, a:msg)
endfunction

function! s:peek_exit_cb(job, status) abort
  call s:create_window()
endfunction

function! s:filter(id, key) abort
  if a:key ==# 'y'
    call setreg(v:register, s:result)
    call popup_close(a:id)
    return 1
  endif
endfunction

function! s:create_window() abort
  echo ""
  if empty(s:result)
    call s:echoerr("no peek result")
    return
  endif

  if get(g:, "peek_popup_window", 1)
    let max_height = len(s:result)
    let max_width = 10
    for str in s:result
      let length = strdisplaywidth(str)
      if  length > max_width
        let max_width = length
      endif
    endfor

    if exists("*popup_atcursor")
      call popup_close(s:last_popup_window)

      let pos = getpos(".")

      let line = "cursor-" . printf("%d", max_height + 2)
      if pos[1] < max_height
        let line = "cursor+1"
      endif

      let wininfo = getwininfo(win_getid())[0]

      let s:last_popup_window = popup_create(s:result, {
            \ "pos":"topright",
            \ "border": [1, 1, 1, 1],
            \ "line": line,
            \ "maxwidth": max_width,
            \ "highlight":g:colors_name,
            \ 'borderchars': ['-','|','-','|','+','+','+','+'],
            \ "moved": [0, 0, 0],
            \ "filter": function("s:filter"),
            \ })
      let opt = popup_getpos(s:last_popup_window)
      let opt.col = getwininfo(win_getid())[0].width
      let opt.line = 3
      call popup_move(s:last_popup_window, opt)
      call win_execute(s:last_popup_window, 'syntax enable')
      call win_execute(s:last_popup_window, "source /usr/share/vim/vim82/syntax/".&filetype.".vim")
      redraw
    else
      call s:echoerr("this version doesn't support popup or floating window")
    endif
  else
    let current = win_getid()
    let winsize = get(g:,"peek_winsize", len(s:result) + 2)

    if !bufexists(s:peek_bufname)
      execute str2nr(winsize) . "new" s:peek_bufname
      set buftype=nofile
      set ft=vim-peek
      nnoremap <silent> <buffer> q :<C-u>bwipeout!<CR>
    else
      let peekw = bufnr(s:peek_bufname)
      let winid = win_findbuf(peekw)
      if empty(winid)
        execute str2nr(winsize) . "new | e" s:peek_bufname
      else
        call win_gotoid(winid[0])
      endif
    endif

    silent % d _
    call setline(1, s:result)

    call win_gotoid(current)
  endif
endfunction

function! vim_peek#move_start() abort
  echo "Popup Window Moving..."
  if !(s:last_popup_window)
    call s:echoerr("popup window is not exist")
    return
  endif
  let opt = popup_getpos(s:last_popup_window)
  let map_direct = {
        \ 'h':'col -= 2 *',
        \ 'j':'line +=',
        \ 'k':'line -=',
        \ 'l':'col += 2 *',
        \ }
  while 1
    let c = nr2char(getchar())
    if get(map_direct, c, 1)
      break
      echo "Popup Window Moved"
    endif
    execute 'let opt.' . map_direct[c] . get(g:, 'peek_move_span', 1)
    call popup_move(s:last_popup_window, opt)
    redraw
  endwhile
      echo "Popup Window Moved"
endfunction
