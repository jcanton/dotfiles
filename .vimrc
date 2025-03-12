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
Plug 'tpope/vim-repeat' " enable repeating supported plugin maps with .
Plug 'tpope/vim-surround' " surround.vim: Delete/change/add parentheses/quotes/XML-tags/much more with ease
Plug 'gcmt/taboo.vim' " Few utilities for pretty tabs (including rename)
Plug 'vim-airline/vim-airline' " Lean & mean status/tabline for vim that's light as air
Plug 'vim-airline/vim-airline-themes' " This is the official theme repository for vim-airline
Plug 'reedes/vim-pencil' " Rethinking Vim as a tool for writers
"
Plug 'tpope/vim-fugitive' " A Git wrapper so awesome, it should be illegal
Plug 'airblade/vim-gitgutter' " A Vim plugin which shows a git diff in the gutter (sign column) and stages/undoes hunks and partial hunks.
Plug 'kshenoy/vim-signature' " Marks on the left side
Plug 'ctrlpvim/ctrlp.vim' " Full path fuzzy file, buffer, mru, tag, ... finder for Vim
Plug 'preservim/nerdtree' " The NERDTree
Plug 'Xuyuanp/nerdtree-git-plugin' " Plugin for git colors in NERDTree
Plug 'tiagofumo/vim-nerdtree-syntax-highlight' " Extra syntax and highlight for nerdtree files
"
Plug 'lervag/vimtex' " VimTeX is a modern Vim and Neovim filetype and syntax plugin for LaTeX files.
Plug 'jpalardy/vim-slime', { 'for': 'python' } " Send code to a REPL
"
Plug 'christoomey/vim-tmux-navigator' " vim-tmux navigation integration
Plug 'roxma/vim-tmux-clipboard' " copy to clipboard working well (depends on vim-tmux-focus-events)
Plug 'tmux-plugins/vim-tmux-focus-events' " needs `set -g focus-events on` in tmux.conf
"
Plug 'chriskempson/base16-vim' " Base16 for Vim
Plug 'luochen1990/rainbow' " Rainbow Parentheses Improved
Plug 'ryanoasis/vim-devicons' " ALWAYS LOAD LAST Adds file type icons to Vim plugins
Plug 'honza/vim-snippets'  " snippets for the engines (somehow disappeared from CoC - seems to be back now, but not working without this?)
call plug#end()

" Run PlugInstall if there are missing plugins
autocmd VimEnter * if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  \| PlugInstall --sync | source $MYVIMRC
\| endif

"------------------------------------------------------------------------------
" General
"------------------------------------------------------------------------------

set noswapfile

" Default splits below and to the right
set splitbelow
set splitright

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

" Setup colorscheme
let term = $TERM
if term == "xterm-256color" || term == "screen-256color"
    try
        colorscheme base16-solarized-light
    catch
        colorscheme elflord
    endtry
else
    colorscheme elflord
endif

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
" send text to the ?.2 pane in the current tmux tab by default
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
" Mappings
"------------------------------------------------------------------------------

if filereadable(glob("$HOME/.vim/mappings.vim"))
   source $HOME/.vim/mappings.vim
endif

"++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
"
