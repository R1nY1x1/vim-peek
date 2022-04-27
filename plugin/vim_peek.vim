" Author : r1ny1x1
" License: MIT

scriptencoding utf-8

if exists('g:loaded_peek')
  finish
endif

let g:loaded_peek = 1

let s:default_toggle_key = '<C-p>'
let g:peek_toggle_key = get(g:, 'peek_toggle_key', s:default_toggle_key)
let s:default_start_key = '<C-m>'
let g:move_start_key = get(g:, 'move_start_key', s:default_start_key)

let s:default_move_span = 1
let g:peek_move_span = get(g:, 'peek_move_span', s:default_move_span)

execute 'vnoremap ' . g:peek_toggle_key . ' :Peek<CR>'
execute 'nnoremap ' . g:move_start_key . ' :MoveStart<CR>'

command! -range -nargs=? Peek call vim_peek#peek(<line1>, <line2>, <f-args>)
command! MoveStart call vim_peek#move_start()

nnoremap <silent> <Plug>(Peek) :<C-u>Peek<CR>
vnoremap <silent> <Plug>(VPeek) :Peek<CR>
