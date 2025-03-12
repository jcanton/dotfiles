"++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
"++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
"
" Sections:
"    -> Vim-plug
"    -> VIM user interface
"    -> Colors and Fonts
"    -> Text, tab and indent related
"    -> Moving around, tabs and buffers
"    -> Status line
"    -> The NERDTree
"    -> The NERDCommenter
"    -> Terminal
"    -> Markdown preview
"    -> CoC configuration
"    -> Project dependent options
"    -> File specific autocmds
"    -> Local vimrc
"
"    take a look at this when you have the time
"    https://github.com/nathanaelkane/vim-indent-guides
"
"++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
"++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
"
" Set location of vimDir
let vimDir = '$HOME/.vim'
if stridx(&runtimepath, expand(vimDir)) == -1
  " vimDir is not on runtimepath, add it
  let &runtimepath.=','.vimDir
endif

"------------------------------------------------------------------------------
" => Vim-plug
"------------------------------------------------------------------------------
" Install vim-plug if not found
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
endif

call plug#begin()
Plug 'chriskempson/base16-vim' " Base16 for Vim
Plug 'christoomey/vim-tmux-navigator' " vim-tmux navigation integration
Plug 'roxma/vim-tmux-clipboard' " copy to clipboard working well (depends on vim-tmux-focus-events)
Plug 'tmux-plugins/vim-tmux-focus-events' " needs `set -g focus-events on` in tmux.conf
"
"Plug 'tpope/vim-obsession' " Continuously updated session files
Plug 'tpope/vim-repeat' " enable repeating supported plugin maps with .
"Plug 'tpope/vim-endwise' " wisely add end in ruby, endfunction/endif/more in vim script, etc (BREAKS CoC)
Plug 'tpope/vim-surround' " surround.vim: Delete/change/add parentheses/quotes/XML-tags/much more with ease
Plug 'gcmt/taboo.vim' " Few utilities for pretty tabs (including rename)
Plug 'vim-airline/vim-airline' " Lean & mean status/tabline for vim that's light as air
Plug 'vim-airline/vim-airline-themes' " This is the official theme repository for vim-airline
Plug 'reedes/vim-pencil' " Rethinking Vim as a tool for writers
"
"Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'octol/vim-cpp-enhanced-highlight' " Additional C++ syntax highlighting
Plug 'rhysd/vim-clang-format' " Vim plugin for clang-format, a formatter for C, C++, Obj-C, Java, JavaScript etc.
"Plug 'udalov/kotlin-vim' " Kotlin plugin for Vim. Featuring: syntax highlighting, basic indentation, Syntastic support
Plug 'tpope/vim-dispatch' " Asynchronous build and test dispatcher
"Plug 'tpope/vim-commentary' " Comment stuff out
Plug 'tpope/vim-fugitive' " A Git wrapper so awesome, it should be illegal
Plug 'lervag/vimtex' " VimTeX is a modern Vim and Neovim filetype and syntax plugin for LaTeX files.
Plug 'airblade/vim-gitgutter' " A Vim plugin which shows a git diff in the gutter (sign column) and stages/undoes hunks and partial hunks.
"Plug 'prettier/vim-prettier', { 'do': 'yarn install' }
Plug 'godlygeek/tabular' " table alignement
Plug 'luochen1990/rainbow' " Rainbow Parentheses Improved
Plug 'kshenoy/vim-signature' " Marks on the left side
"
Plug 'ctrlpvim/ctrlp.vim' " Full path fuzzy file, buffer, mru, tag, ... finder for Vim
Plug 'preservim/nerdtree' " The NERDTree
Plug 'Xuyuanp/nerdtree-git-plugin' " Plugin for git colors in NERDTree
Plug 'tiagofumo/vim-nerdtree-syntax-highlight' " Extra syntax and highlight for nerdtree files
"Plug 'yilin-yang/vim-markbar' " Mark-bar
"Plug 'preservim/tagbar' " Tagbar: a class outline viewer for Vim
"Plug 'simnalamburt/vim-mundo' " A Vim plugin to visualizes the Vim undo tree
"
Plug 'jpalardy/vim-slime', { 'for': 'python' }
"
Plug 'ryanoasis/vim-devicons' " ALWAYS LOAD LAST Adds file type icons to Vim plugins
Plug 'honza/vim-snippets'  " snippets for the engines (somehow disappeared from CoC - seems to be back now, but not working without this?)
"
Plug 'kmonad/kmonad-vim'
call plug#end()

" Run PlugInstall if there are missing plugins
autocmd VimEnter * if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  \| PlugInstall --sync | source $MYVIMRC
\| endif

"------------------------------------------------------------------------------
" Functions
"------------------------------------------------------------------------------

" Enhanced add/subtract
function! AddSubtract(char, back)
    let pattern = &nrformats =~ 'alpha' ? '[[:alpha:][:digit:]]' : '[[:digit:]]'
    call search(pattern, 'cw' . a:back)
    execute 'normal! ' . v:count1 . a:char
    silent! call repeat#set(":\<C-u>call AddSubtract('" .a:char. "', '" .a:back. "')\<CR>")
endfunction

" Delete all trailing whitespaces
function! DeleteTrailingWhitespace()
    %s/\s\+$//e
    echo "Deleted trailing whitespaces"
endfunction
command! DeleteTrailingWhitespace call DeleteTrailingWhitespace()

"------------------------------------------------------------------------------
" General
"------------------------------------------------------------------------------

set noswapfile

" Default splits below and to the right
set splitbelow
set splitright

" Do not wait after a keystroke if there is no command defined with that key
" as first
" set ttimeoutlen=0
" set timeoutlen=1000 ttimeoutlen=0


" Always autosave everything when focus is lost
:au FocusLost * :wa!

" Sets how many lines of history VIM has to remember
set history=700

" Enable filetype plugins (already enabled for vim-addon-manager)
filetype plugin on
filetype indent on

" Set to auto read when a file is changed from the outside
set autoread

" Enable extended % matching (make it work with if/elseif/else/end)
runtime macros/matchit.vim

" Turn on Rainbow parenthesis
let g:rainbow_active = 1 "set to 0 if you want to enable it later via :RainbowToggle

"------------------------------------------------------------------------------
" VIM user interface
"------------------------------------------------------------------------------

" turn on line numbers
set number

" show the command being typed
set showcmd

" do not wrap lines by default
set nowrap

" but default pencil to 'soft' if initialized
let g:pencil#wrapModeDefault = 'soft'

" use mouse everywhere
set mouse=a

" Turn on the WiLd menu
set wildmenu
" and make it behave like a shell
set wildmode=list:longest

"Always show current position
set ruler

" Configure backspace so it acts as it should act
set backspace=eol,start,indent
set whichwrap+=<,>,h,l

" When searching try to be smart about cases
set smartcase

" Highlight search results
set hlsearch

" Makes search act like search in modern browsers
set incsearch

" Don't redraw while executing macros (good performance config)
set lazyredraw

" For regular expressions turn magic on
set magic

" Show matching brackets when text indicator is over them
set showmatch
" How many tenths of a second to blink when matching brackets
set mat=2
" Stop highlighting matching parenthesis
" let loaded_matchparen = 1

" No annoying sound on errors
set noerrorbells visualbell t_vb=
autocmd GUIEnter * set visualbell t_vb=

"------------------------------------------------------------------------------
" Colors and Fonts
"------------------------------------------------------------------------------

" Enable syntax highlighting
syntax enable

" The following lines enable true color support
if exists('+termguicolors')
    let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
    let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
    set termguicolors
endif

" Use the Solarized Dark theme
set background=light
colorscheme solarized
let g:solarized_termtrans=1

" Set utf8 as standard encoding and en_US as the standard language
set encoding=UTF-8

" Use Unix as the standard file type
set ffs=unix,dos,mac

"------------------------------------------------------------------------------
" Text, tab and indent related
"------------------------------------------------------------------------------

" Use spaces instead of tabs
set expandtab

" Be smart when using tabs ;)
set smarttab

" 1 tab = 4 spaces
set shiftwidth=4
set tabstop=4

" add respace command to remove all trailing whitespaces
command! -nargs=0 Respace :let _s=@/ <Bar> :%s/\s\+$//e <Bar> :let @/=_s <Bar> :nohl <Bar> :unlet _s <CR>

" Linebreak makes vim break lines without cutting words in half
set linebreak

"------------------------------------------------------------------------------
" Moving around, tabs, windows and buffers
"------------------------------------------------------------------------------
"
" Return to last edit position when opening files (You want this!)
autocmd BufReadPost *
     \ if line("'\"") > 0 && line("'\"") <= line("$") |
     \   exe "normal! g`\"" |
     \ endif

" Remember info about open buffers on close
set viminfo^=%

" Reduce updatetime (from airblad/vim-gitgutter's README)
set updatetime=100

" Disable tmux_navigator wrapping
let  g:tmux_navigator_no_wrap = 1

"------------------------------------------------------------------------------
" Status line
"------------------------------------------------------------------------------

" Enable/disable vim-obsession integration
let g:airline#extensions#obsession#enabled = 1

" Set obsession indicator string
let g:airline#extensions#obsession#indicator_text = '@o@'

" Configure tabline
" let g:taboo_tabline = 0 " First disable Taboo's tabline
" let g:airline#extensions#tabline#enabled = 1
" let g:airline#extensions#tabline#left_sep = ' ' " ''
" let g:airline#extensions#tabline#left_alt_sep = '' " '|'
" let g:airline#extensions#tabline#tab_nr_type = 1         " show tab numbers instead of number of buffers
" " let g:airline#extensions#tabline#show_close_button = 0 " remove 'X' at the end of the tabline
" " let g:airline#extensions#tabline#tabs_label = ''       " can put text here like BUFFERS to denote buffers (I clear it so nothing is shown)
" " let g:airline#extensions#tabline#buffers_label = ''    " can put text here like TABS to denote tabs (I clear it so nothing is shown)
" " let g:airline#extensions#tabline#fnamemod = ':t'       " disable file paths in the tab
" " let g:airline#extensions#tabline#show_tab_count = 0    " dont show tab numbers on the right
" " let g:airline#extensions#tabline#show_buffers = 1      " dont show buffers in the tabline
" " let g:airline#extensions#tabline#tab_min_count = 2     " minimum of 2 tabs needed to display the tabline
" " let g:airline#extensions#tabline#show_splits = 0       " disables the buffer name that displays on the right of the tabline
" " let g:airline#extensions#tabline#show_tab_nr = 0       " disable tab numbers
" " let g:airline#extensions#tabline#show_tab_type = 0     " disables the weird ornage arrow on the tabline

" Select vim-airline theme
let g:airline_theme='papercolor'

if !exists('g:airline_symbols')
    let g:airline_symbols = {}
endif

" powerline symbols
let g:airline_left_sep = ''
let g:airline_left_alt_sep = ''
let g:airline_right_sep = ''
let g:airline_right_alt_sep = ''
let g:airline_symbols.branch = ''
let g:airline_symbols.readonly = ''
let g:airline_symbols.linenr = '☰'
let g:airline_symbols.maxlinenr = ''

"------------------------------------------------------------------------------
" NERDtree
"------------------------------------------------------------------------------

" Hide extensions
let NERDTreeIgnore = ['\.pyc$', '\.o$', '\.mod$', '\.f90.d$']

" open NERDTree automatically
" autocmd VimEnter * NERDTree | wincmd p

" Close vim if the only window left open is a NERDTree
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

"------------------------------------------------------------------------------
" Terminal configuration
"------------------------------------------------------------------------------

" Default to insert mode when opening a new term
autocmd TermOpen term://* startinsert

" always use tmux
let g:slime_target = 'tmux'
" fix paste issues in ipython
"let g:slime_python_ipython = 1
let g:slime_bracketed_paste = 1
let g:slime_paste_file = expand("$HOME/.slime_paste")
" always send text to the top-right pane in the current tmux tab without asking
let g:slime_default_config = {
            \ 'socket_name': get(split($TMUX, ','), 0),
            \ 'target_pane': '.2' }
let g:slime_dont_ask_default = 0

"------------------------------------------------------------------------------
" Load CoC configuration
"------------------------------------------------------------------------------
if filereadable(glob("$HOME/.vim/coc-config.vim"))
   source $HOME/.vim/coc-config.vim
endif

"------------------------------------------------------------------------------
" Vimtex configuration
"------------------------------------------------------------------------------
let g:vimtex_view_method='skim'
noremap <leader>ll :VimtexCompileSS<cr>
autocmd BufRead,BufNewFile *.tex map <F2> <ESC>:w<CR><leader>ll
autocmd BufRead,BufNewFile *.tex map <F3> <ESC>:w<CR><leader>lv

"------------------------------------------------------------------------------
" All my mappings
"------------------------------------------------------------------------------

if filereadable(glob("$HOME/.vim/mappings.vim"))
   source $HOME/.vim/mappings.vim
endif

"++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
"
