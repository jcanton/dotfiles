"===============================================================================
" Vim mappings
"===============================================================================

" Open this file
noremap <M-m> :exec 'pedit $HOME/.vim/mappings.vim'<CR>

"-------------------------------------------------------------------------------
" Function calls
"-------------------------------------------------------------------------------

" " Enhanced add/subtract
" nnoremap <silent>         <M-]> :<C-u>call AddSubtract("\<C-a>", '')<CR>
" nnoremap <silent> <Leader><M-]> :<C-u>call AddSubtract("\<C-a>", 'b')<CR>
" nnoremap <silent>         <M-[> :<C-u>call AddSubtract("\<C-x>", '')<CR>
" nnoremap <silent> <Leader><M-[> :<C-u>call AddSubtract("\<C-x>", 'b')<CR>

" Delete all trailing whitespaces
map <M-s> :DeleteTrailingWhitespace<CR>
" autocmd BufWritePre * %s/\s\+$//e

" Delete hidden buffers
map <M-d> :DeleteHiddenBuffers<CR>

" Compile stuff
map <F2> :CompileStuff<CR>

" Sunshine
map <M-q> :call Sunshine()<CR>

"-------------------------------------------------------------------------------
" Plugin calls
"-------------------------------------------------------------------------------

" fugitive shortcuts
command! Gic :Git commit
command! Gip :Git push

" tagbar - a plugin that provides code overview, you need to install ctags for it
nmap <M-t> :TagbarToggle<CR>

" markbar
" nmap <M-m> <Plug>ToggleMarkbar " I actually don't need this: it appears when pressing '

" Undo tree with mundo
nnoremap <M-u> :MundoToggle<CR>
let g:mundo_preview_bottom = 1
let g:mundo_right = 0

" NERDtree
noremap <C-n> :NERDTreeToggle<CR>

" Convenient obsession mapping
noremap <M-o> :Obsession<CR>

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

" " Remap deleting to the blackhole register
" nnoremap x "_x
" vnoremap x "_x
" nnoremap d "_d
" vnoremap d "_d
" nnoremap D "_D
" nnoremap <leader>d ""d
" vnoremap <leader>d ""d
" nnoremap <leader>x ""x
" vnoremap <leader>x ""x
" nnoremap <leader>D ""D

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

" " Moving lines (I never use this)
" nnoremap <M-j> :m .+1<CR>==
" nnoremap <M-k> :m .-2<CR>==
" inoremap <M-j> <Esc>:m .+1<CR>==gi
" inoremap <M-k> <Esc>:m .-2<CR>==gi
" vnoremap <M-j> :m '>+1<CR>gv=gv
" vnoremap <M-k> :m '<-2<CR>gv=gv

" Force redraw
nnoremap <M-l> :redraw!<CR>

" Treat long lines as break lines (useful when moving around in them)
" map j gj
" map k gk
" substituted with Pencil

" Conflicts with other mappings
" Map <Space> to / (search) and Ctrl-<Space> to ? (backwards search)
" noremap <space> /
" noremap <c-space> ?

" Disable highlight when <leader><cr> is pressed
noremap <silent> <leader><cr> :noh<cr>
noremap <silent> <space><cr> :noh<cr>

" Close the current buffer
" map <leader>bd :Bclose<cr>

" Close all the buffers
" map <leader>ba :1,1000 bd!<cr>

" Useful mappings for managing tabs
" map <leader>tn :tabnew<cr>
" map <leader>to :tabonly<cr>
" map <leader>tc :tabclose<cr>
" map <leader>tm :tabmove

" Opens a new tab with the current buffer's path
" Super useful when editing files in the same directory
" map <C-a>te :tabedit <c-r>=expand("%:p:h")<cr>/

" Switch CWD to the directory of the open buffer
map <M>cd :cd %:p:h<cr>:pwd<cr>

" Return to normal mode with Esc (in terminal)
tnoremap <Esc> <C-\><C-n>
