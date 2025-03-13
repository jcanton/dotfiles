"===============================================================================
" Vim mappings
"===============================================================================

" Define the primary leader key
let mapleader = "\\"

" Define the secondary leader key
let maplocalleader = "`"

" Open this file
noremap <M-m> :exec 'pedit $HOME/.vim/mappings.vim'<CR>

"-------------------------------------------------------------------------------
" Plugin calls
"-------------------------------------------------------------------------------

" Fugitive shortcuts
command! Gic :Git commit
command! Gip :Git push

" NERDtree
noremap <C-n> :NERDTreeToggle<CR>

" Prettier
nmap <localleader>p :Prettier<CR>

" Some tabs/Taboo mappings
map <localleader>] :tabnext<CR>
map <localleader>[ :tabprevious<CR>
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
tnoremap <localleader>j :sp<CR>
inoremap <localleader>j :sp<CR>
nnoremap <localleader>j :sp<CR>
tnoremap <localleader>k :vs<CR>
inoremap <localleader>k :vs<CR>
nnoremap <localleader>k :vs<CR>

" Force redraw
nnoremap <localleader>l :redraw!<CR>

" Disable highlight
tnoremap <silent> <localleader><cr> :noh<cr>
inoremap <silent> <localleader><cr> :noh<cr>
nnoremap <silent> <localleader><cr> :noh<cr>

" Opens a new tab with the current buffer's path
" Super useful when editing files in the same directory
" map <C-a>te :tabedit <c-r>=expand("%:p:h")<cr>/

" Switch CWD to the directory of the open buffer
map <localleader>cd :cd %:p:h<cr>:pwd<cr>

" Return to normal mode with Esc (in terminal)
tnoremap <Esc> <C-\><C-n>

noremap <leader>ll :VimtexCompileSS<cr>
autocmd BufRead,BufNewFile *.tex map <F2> <ESC>:w<CR><leader>ll
autocmd BufRead,BufNewFile *.tex map <F3> <ESC>:w<CR><leader>lv