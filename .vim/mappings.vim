"===============================================================================
" Vim mappings
"===============================================================================

" Open this file
noremap <M-m> :exec 'pedit $HOME/.vim/mappings.vim'<CR>

"-------------------------------------------------------------------------------
" Plugin calls
"-------------------------------------------------------------------------------

" fugitive shortcuts
command! Gic :Git commit
command! Gip :Git push

" NERDtree
noremap <C-n> :NERDTreeToggle<CR>

" Prettier
nmap <space>p :Prettier<CR>

" " Some tabs/Taboo mappings
" map <M-]> :tabnext<CR>
" map <M-[> :tabprevious<CR>
" map <M-c> :TabooOpen
" map <M-r> :TabooRename
" map <M-R> :TabooReset<CR>

"-------------------------------------------------------------------------------
" 'Normal' mappings
"-------------------------------------------------------------------------------

" Remap pasting to the blackhole register
vnoremap p "_dP

" Use `Ctrl+{h,j,k,l}` to navigate windows from any mode
tnoremap <C-h> <C-\><C-N><C-w>h
tnoremap <C-j> <C-\><C-N><C-w>j
tnoremap <C-k> <C-\><C-N><C-w>k
tnoremap <C-l> <C-\><C-N><C-w>l
inoremap <C-h> <C-\><C-N><C-w>h
inoremap <C-j> <C-\><C-N><C-w>j
inoremap <C-k> <C-\><C-N><C-w>k
inoremap <C-l> <C-\><C-N><C-w>l
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Maps for splitting
tnoremap <M-j> :sp<CR>
inoremap <M-j> :sp<CR>
nnoremap <M-j> :sp<CR>
tnoremap <M-k> :vs<CR>
inoremap <M-k> :vs<CR>
nnoremap <M-k> :vs<CR>

" Force redraw
nnoremap <M-l> :redraw!<CR>

" Disable highlight when <leader><cr> is pressed
noremap <silent> <leader><cr> :noh<cr>

" Opens a new tab with the current buffer's path
" Super useful when editing files in the same directory
" map <C-a>te :tabedit <c-r>=expand("%:p:h")<cr>/

" Switch CWD to the directory of the open buffer
map <M>cd :cd %:p:h<cr>:pwd<cr>

" Return to normal mode with Esc (in terminal)
tnoremap <Esc> <C-\><C-n>
