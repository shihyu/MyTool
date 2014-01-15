" ==============================================================================
"  ---------------------------
" < .vimrc by Kent, by Cowsay >
"  ---------------------------
"        \   ^__^
"         \  (oo)\_______
"            (__)\       )\/\
"                ||----w |
"                oo     oo
"
" Author:        Kent Chen <chenkaie at gmail.com>
"
" Blog:          http://chenkaie.blogspot.com
"
" GitHub:        http://github.com/chenkaie/DotFiles/blob/master/.vimrc
"                http://github.com/chenkaie/DotFiles/tree/master/.vim/
"
" Last Modified: Fri Jan 03, 2014  03:30PM
" ==============================================================================

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" [ General Setting ]                                                        {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Use Vim settings, rather then Vi settings (much better!). This must be first, because it changes other options as a side effect.
set nocompatible

"has("mac") & has("macunix") just work for MacVim
if match(system('uname'),'Darwin') == 0
	let OS = "Darwin"
elseif has("unix")
	let OS = "Unix"
elseif has("win32")
	let OS = "Win32"
endif

if version >= 703
	set conceallevel=1
	set concealcursor=nc
	set colorcolumn=+1
	set cinoptions+=L0
	"set undofile
	set undodir=~/.vim/undofiles
	if !isdirectory(&undodir)
		call mkdir(&undodir, "p")
	endif
	map  <C-ScrollWheelDown> <ScrollWheelRight>
	map  <C-ScrollWheelUp>   <ScrollWheelLeft>
	imap <C-ScrollWheelDown> <ScrollWheelRight>
	imap <C-ScrollWheelUp>   <ScrollWheelLeft>
endif

set backspace=2

" Backups and swapfile
set backup
set backupdir=$HOME/.vim/backup/
silent execute '!mkdir -p $HOME/.vim/backup'

syntax on
set vb
set noswapfile

if &term == "xterm-color" || &term == "xterm-16color"
	set t_Co=16
elseif ! has("gui_running")
	set t_Co=256

	" disable Background Color Erase (BCE) so that color schemes
	" render properly when inside 256-color tmux and GNU screen.
	" see also http://snk.tuxfamily.org/log/vim-256color-bce.html
	set t_ut=
endif

" for GVim
if has("gui_running")
	set guioptions-=T
	colorscheme wombat
	set gfn=Consolas:h14
else
	"For Colorscheme
	set bg=dark
	colorscheme peaksea_new
	"colorscheme ir_black_cterm
endif

" Status Line
set laststatus=2
"set statusline=%<%f\ %m%=\ %h%r\ %-19([%p%%]\ %3l,%02c%03V%)%y
set statusline=File:\ %t\%r%h%w\ [%{&ff},%{&fileencoding},%Y]\ %m%=\ [AscII=\%03.3b]\ [Hex=\%02.2B]\ [Pos=%l,%v,%p%%]\ [LINE=%L]

set hlsearch
set showmatch
set number

set autoindent     " Auto Indent
set smartindent    " Smart Indent
set cindent        " C-style Indent

set smarttab       " Smart handling of the tab key
set shiftround     " Round indent to multiple of shiftwidth
set shiftwidth=4   " Number of spaces for each indent
set tabstop=4      " Number of spaces for tab key
set softtabstop=4  " Number of spaces for tab key while performing editing operations
"set expandtab     " Use spaces for tabs.

set history=1000   " keep 1000 lines of command line history
set ruler          " show the cursor position all the time
set showcmd        " display incomplete commands
set incsearch      " do incremental searching

set lazyredraw     " Do not redraw while running macros (much faster) (LazyRedraw)

nmap <tab> V>
nmap <s-tab> V<
xmap <tab> >gv
xmap <s-tab> <gv

set foldmethod=indent
set foldlevel=1000
set foldnestmax=5
nnoremap ,<SPACE> za

" {{{ file encoding setting
set fileencodings=utf-8,big5,euc-jp,gbk,euc-kr,utf-bom,iso8859-1
set termencoding=utf-8
set enc=utf-8
set tenc=utf8
set fenc=utf-8
" }}}

" For ambiguous characters, ex: ”, and BBS XD
set ambiwidth=single

" Favorite file types
set ffs=unix,dos,mac

" Edit your .vimrc in new tab
nmap ,s :source $MYVIMRC <CR>
nmap ,v :tabedit $MYVIMRC <CR>

" Edit your .bashrc in new tab
nmap ,b :tabedit ~/.bashrc <CR>

" Edit(e) & Generate(g) help tags
nmap ,he :tabedit $HOME/.vim/doc/MyNote.txt <CR>
nmap ,hg :helptags $HOME/.vim/doc <CR>

" Toggle on/off paste mode
map <F7> :set paste!<bar>set paste?<CR>
" For Insert Mode to function
set pastetoggle=<F7>

"Toggle on/off show line number
map <F6> :set nu!<bar>set nu?<CR>

map <F2> <ESC>:cn<CR>
map ,<F2> <ESC>:cp<CR>

"nnoremap <F8> <ESC>:w \| !make test && ./a.out
"compile a c file and execute it.
nnoremap <F9> <ESC>:w \| !gcc -Wall -ansi -pedantic -Wextra -std=c99 % && ./a.out

"replace 'SHIFT+:' with ';' COOL!
noremap ; :

"Yahoo Dictionary
map <C-D> viwy:!clear; ydict <C-R>"<CR>
vmap <C-D> y:!clear; ydict "<C-R>""<CR>

"tab function hotkey
nmap tl :tabnext<CR>
nmap th :tabprev<CR>
nmap tn :tabnew<CR>
nmap tc :tabclose<CR>

filetype plugin indent on
set completeopt=longest,menu,menuone
set wildmenu
"in ESC: (command mode), disbled auto completion next part, Cool!
set wildmode=list:longest
set wildignore+=*.o,*.a,*.so,*.obj,*.exe,*.lib,*.ncb,*.opt,*.plg,.svn,.git

" for :TOhtml
"let html_use_css=1
"let use_xhtml = 1
let html_number_lines = 1
let html_no_pre = 1
let html_ignore_folding = 1

set scrolloff=10
set sidescrolloff=10
set ignorecase
set smartcase

"show CursorLine
set cursorline

set backspace=indent,eol,start  " Allow backspacing over these

" Determining the highlight group that the word under the cursor belongs to
nmap <silent> ,h :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<' . synIDattr(synID(line("."),col("."),0),"name") . "> lo<" . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"<CR>

" Spell Check
hi SpellBad term=underline cterm=underline ctermfg=red
map <F5> :set spell!<CR><BAR>:echo "Spell check: " . strpart("OffOn", 3 * &spell, 3)<CR>

if OS == "Darwin"
	" Use custom fillchars/listchars/showbreak icons
	set fillchars=vert:│,fold:┄,diff:╱
	set listchars=tab:⋮\ ,trail:⌴,eol:·,precedes:◂,extends:▸
	set showbreak=↪
else
	"Visualize some special chars
	set fillchars=vert:│,fold:-,diff:╱
	set listchars=tab:⋮\ ,trail:⌴,eol:·,precedes:◂,extends:▸
	" Use below line if you don't have font patched.
	"set listchars=tab:»\ ,trail:·,eol:$,nbsp:%,extends:>,precedes:<
endif

"map <F8> :set list!<bar>set list?<CR>
" A powerful one than above line
map <F8> :call ToggleSpecialChar()<CR>

" Add new keyword in search under cursor (*)
map a* :exec "/\\(".getreg('/')."\\)\\\\|".expand("<cword>")<CR>

map * g*
map # g#

" Use Ctrl+hjkl to switch between Window
nmap <C-j> <C-w>j
nmap <C-k> <C-w>k
nmap <C-h> <C-w>h
nmap <C-l> <C-w>l
nmap - <C-w>-
nmap + <C-w>+

" Define different behavior in left/right window
if has("autocmd")
	autocmd BufEnter,BufLeave *
	\     if winnr() == 1 |
	\        nmap < <C-w><|
	\        nmap > <C-w>>|
	\     else            |
	\        nmap < <C-w>>|
	\        nmap > <C-w><|
	\     endif           |
endif

" this allows all window commands in insert mode and i'm not accidentally deleting words anymore :-)
imap <C-w> <C-o><C-w>

" useful ab
cabbrev vds vertical diffsplit

" Force to split right!
set splitright
cabbrev h vertical help
"cabbrev help vertical help
"cabbrev split vsplit
"cabbrev new vnew

" Remove 'recording' key mapping
nmap q <Cr>
hi Folded ctermbg=237

" Bash like keys for the command line
cnoremap <C-A>		<Home>
cnoremap <C-E>		<End>

" Command-line completion
cnoremap <C-P>		<UP>
cnoremap <C-N>		<DOWN>

" Specify the behavior when switching between buffers
try
	set switchbuf=usetab
catch
endtry

" use ,<Enter> key to insert a blank line
nnoremap <silent> ,<enter> :put =''<cr>

" a LAZY key mapping XD
imap jj <ESC>

" Maximum number of tab pages
set tabpagemax=30

" used for saving root-privilege file convenient rather than reopen with root
cmap w!! %!sudo tee > /dev/null %

" keypad fix, http://vim.wikia.com/wiki/PuTTY_numeric_keypad_mappings
inoremap <Esc>Oq 1
inoremap <Esc>Or 2
inoremap <Esc>Os 3
inoremap <Esc>Ot 4
inoremap <Esc>Ou 5
inoremap <Esc>Ov 6
inoremap <Esc>Ow 7
inoremap <Esc>Ox 8
inoremap <Esc>Oy 9
inoremap <Esc>Op 0
inoremap <Esc>On .
inoremap <Esc>OQ /
inoremap <Esc>OR *
inoremap <Esc>Ol +
inoremap <Esc>OS -

" tab goes between delimiters
nmap <tab> %
" < and > are considering as a matching pair
set matchpairs+=<:>

" ',' is more convenient than '\'
let mapleader = ","

" ':substitute' flag 'g' is default on
set gdefault

" When moving up/down in wrapped lines, move 'screen' lines instead of physical lines
nnoremap j gj
nnoremap k gk

" save on losing focus (GVim Only)
au FocusLost * :wa

" Working with split windows
nnoremap <leader>w <C-w>v<C-w>l

" Syntax coloring lines that are too long just slows down the world
" set synmaxcol=256

" make search results appear in the middle of the screen
nmap n nzz
nmap N Nzz

" STOP using the arrow keys, Dude!
" map <up> <nop>
" map <down> <nop>
" map <left> <nop>
" map <right> <nop>

" Use `R` to Remove/delete linewise text without overwriting last yank
nmap R "_dd
vmap R "_d

" Don't move the cursor after pasting (by jumping to back start of previously changed text)
noremap p p`[
noremap P P`[

" Paste without yanking selection content to unnamed register
vnoremap p "_dP

" Allow deleting selection without updating the clipboard (yank buffer)
vnoremap x "_x
vnoremap X "_X

" Reselect after indent so it can easily be repeated
vnoremap < <gv
vnoremap > >gv

" Use Q key to perform a calculation on formula like: (a + b) / 2 =
nnoremap Q 0yt=A<C-r>=<C-r>"<CR><Esc>

" }}}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" [ Mouse + gVim-Killer Related Setting ]                                    {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" This is AWESOME, INCREDIBLE! Could be used do Tab-Click, window resizing, scrolling...
"set mouse=a           " Enable use of the mouse for all modes.
set ttymouse=xterm2   " To function correctly in Screen

" Enable block-mode selection
noremap <C-LeftMouse> <LeftMouse><Esc><C-V>
noremap <C-LeftDrag> <LeftDrag>


	"""""""""""""""""""""""""""""""""""""""""""""""""
	" copy'n'paste data between separate vim sessions
	"""""""""""""""""""""""""""""""""""""""""""""""""
	" Copy to vimbuff & System-Clipboard
	if OS == "Darwin"
		vmap <C-c> :w! ~/tmp/vimbuffer<CR>:!pbcopy < ~/tmp/vimbuffer<CR><CR>
		nmap <C-c> :.w! ~/tmp/vimbuffer<CR>:!pbcopy < ~/tmp/vimbuffer<CR><CR>
	else
		vmap <C-c> :w! ~/tmp/vimbuffer<CR>:!nc 172.16.2.54 4573 < ~/tmp/vimbuffer<CR><CR>
		nmap <C-c> :.w! ~/tmp/vimbuffer<CR>:!nc 172.16.2.54 4573 < ~/tmp/vimbuffer<CR><CR>
	endif
	" Paste from buffer
	nmap <C-p> :r ~/tmp/vimbuffer<CR>
	map c <C-c>

" Select all
map a <ESC>ggVG

" }}}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" [ Tab Operation Mac-Mapping by Klaymen ]                                   {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" default 1000
set timeoutlen=500
nmap q <Esc>:qall<Enter>
nmap Q <Esc>:qall!<Enter>
nmap w <Esc>:close<Enter>
nmap W <Esc>:close!<Enter>
nmap s <Esc>:write<Enter>
nmap t <Esc>:tabnew<Enter>

nmap , <Esc>:tabprev<Enter>
"ALT+ <-
nmap OD <Esc>:tabprev<Enter>
nmap [1;9C <Esc>:tabprev<Enter>

nmap . <Esc>:tabnext<Enter>
"ALT+ ->
nmap OC <Esc>:tabnext<Enter>
nmap [1;9D <Esc>:tabnext<Enter>

nmap 1 <Esc>:tabn 1<Enter>
nmap 2 <Esc>:tabn 2<Enter>
nmap 3 <Esc>:tabn 3<Enter>
nmap 4 <Esc>:tabn 4<Enter>
nmap 5 <Esc>:tabn 5<Enter>
nmap 6 <Esc>:tabn 6<Enter>
nmap 7 <Esc>:tabn 7<Enter>
nmap 8 <Esc>:tabn 8<Enter>

"reload this file
nmap r <Esc>:edit<Enter>

"Tab Highlight color
hi TabLine	   ctermfg=fg	ctermbg=28	 cterm=underline
hi TabLineFill ctermfg=fg	ctermbg=28	 cterm=underline
hi TabLineSel  ctermfg=fg	ctermbg=NONE cterm=NONE
hi Title       ctermfg=219  ctermbg=NONE cterm=NONE

autocmd TabLeave * let g:LastUsedTabPage = tabpagenr()
function! SwitchLastUsedTab()
	if exists("g:LastUsedTabPage")
		execute "tabnext " g:LastUsedTabPage
	endif
endfunction
nmap tt :call SwitchLastUsedTab()<CR>

" }}}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" [ Diff related ]                                                           {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"force vim diff to ignore whitespace
set diffopt+=iwhite
" highlight diff color
hi diffchange ctermbg=236
hi diffadd ctermbg=4
hi DiffDelete ctermfg=69 ctermbg=234
hi difftext ctermbg=3 ctermfg=0

function! s:DiffWithSaved()
	let filetype=&ft
	diffthis
	vnew | r # | normal! 1Gdd
	diffthis
	exe "setlocal bt=nofile bh=wipe nobl noswf ro ft=" . filetype
endfunction
com! DiffSaved call s:DiffWithSaved()
nmap ,d :DiffSaved<CR>

"DirDiff
let g:DirDiffExcludes = "*.git,*.svn,.*.swp,tags,cscope.*"
let g:DirDiffWindowSize = 6
let g:DirDiffAddArgs = "-w"

" WinMerge-style (Alt + hjkl) mapping for vimdiff
nmap j ]c
nmap k [c

" non-Diff mode: Use <Alt-H> move to home, <Alt-L> move to the end
"     Diff mode: Used to do diffput and diffget
" Switch key mapping in Left/Right window under DiffMode
if has("autocmd")
	autocmd BufEnter,BufLeave *
		\ if &diff                                                 |
		\     if winnr() == 1                                      |
		\        nmap h do                                       |
		\        nmap l dp                                       |
		\     else                                                 |
		\        nmap h dp                                       |
		\        nmap l do                                       |
		\     endif                                                |
		\ else                                                     |
		\     if (g:vimgdb_debug_file == "")                       |
		\         nmap <silent> <S-H> :call ToggleHomeActionN()<CR>|
		\         map  <silent> <S-L> $|
		\     endif|
		\ endif
endif

" }}}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" [ Programming Language ]                                                   {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

	""""""""""""""""""""""""""""""
	" ctags
	""""""""""""""""""""""""""""""
	" Set tags path
	set tags=tags,../tags,../../tags

	""""""""""""""""""""""""""""""
	" cscope
	""""""""""""""""""""""""""""""
	" init cscope hotkey
	function! UseAwesomeCscope()
		let l:srcdir=(isdirectory("../src") ? '../' : './')
		try
			set tags+=$HOME/horus/apps/tags
			exe "cs add " . l:srcdir . "cscope.out " . l:srcdir
			exe "cs add $HOME/cscope_ctag/Horus/cscope.out $HOME/Project/Horus/apps"
		catch /duplicate/
			silent exe "!tag_rebuild " . l:srcdir
			silent exe "cs reset"
			exe "redraw!"
			echohl Wildmenu | echo "cscope database inuse, update and re-init all connections" | echohl None
		catch /stat/
			silent exe "!tag_rebuild " . l:srcdir
			try
				exe "cs add " . l:srcdir . "cscope.out " . l:srcdir
				exe "cs add $HOME/cscope_ctag/Horus/cscope.out $HOME/Project/Horus/apps"
				exe "redraw!"
				echohl Wildmenu | echo "cscope file not found, exec tag_rebuild" | echohl None
			catch
				exe "redraw!"
				echohl ErrorMsg | echo "You don't have enough privilege XD, just add Horus db." | echohl None
				exe "cs add $HOME/cscope_ctag/Horus/cscope.out $HOME/Project/Horus/apps"
			endtry
		endtry
	endfun
	nnoremap <F11> <ESC>:call UseAwesomeCscope()<CR>

	" [Web Dev] Gernerate tags file for *.js only!
	nnoremap <F11>w <ESC>:!tag_rebuild ..<CR><ESC>:redraw!<CR>

	" To avoid using wrong cscope(/opt/montavista/pro5.0/bin/cscope) once sourcing devel_IP8161_VVTK
	if match(system('ls ~/usr/bin/cscope'), 'cscope') != -1
		set cscopeprg=~/usr/bin/cscope
	endif

	""""""""""""""""""""""""""""""
	" For Linux Kernel
	""""""""""""""""""""""""""""""

	" Generate 'cscope index' and 'tag file' for Linux Kernel : 'make ARCH=arm CROSS_COMPILE=arm-linux- cscope tags'
	nnoremap <F11>k <ESC>:cscope add $HOME/Project/DM36x/linux-2.6.18/cscope.out $HOME/Project/DM36x/linux-2.6.18 <CR>:set tags+=$HOME/Project/DM36x/linux-2.6.18/tags<CR>

	""""""""""""""""""""""""""""""
	" Vi Man
	""""""""""""""""""""""""""""""
	" color/paged man
	runtime! ftplugin/man.vim
	nmap K <esc>:Man <cword><cr>

	""""""""""""""""""""""""""""""
	" Javascript
	""""""""""""""""""""""""""""""
	autocmd FileType javascript set dictionary=~/.vim/dict/javascript.dict

	""""""""""""""""""""""""""""""
	" C/C++
	""""""""""""""""""""""""""""""
	"if filename is test.c => make test
	"set makeprg=make
	"set errorformat=%f:%l:\ %m

	" Enables detection of some GCC extensions to C
	let c_gnu=1

	""""""""""""""""""""""""""""""
	" NeoComplCache
	""""""""""""""""""""""""""""""
	let g:neocomplcache_enable_at_startup = 0
	let g:neocomplcache_enable_smart_case = 1
	let g:neocomplcache_enable_camel_case_completion = 1

	" snippets expand key <c-e>
	imap <silent> <C-e> <Plug>(neocomplcache_snippets_expand)
	smap <silent> <C-e> <Plug>(neocomplcache_snippets_expand)

	map <F4> :NeoComplCacheEnable<CR>
	map ,<F4> :NeoComplCacheToggle<CR>

	""""""""""""""""""""""""""""""
	" Clang-Completion
	""""""""""""""""""""""""""""""
	let g:clang_complete_auto=1
	let g:clang_auto_select = 1
	let g:clang_use_library=1
	let g:clang_library_path=$HOME."/usr/lib"
	let g:clang_snippets=1
	let g:clang_conceal_snippets=1
	let g:clang_periodic_quickfix=1
	let g:clang_hl_errors=1
	let g:clang_snippets_engine='snipmate'
	"let g:clang_complete_copen=1

" }}}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" [ Hex/Binary Edit ]                                                        {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" autocmds to automatically enter hex mode and handle file writes properly
if has("autocmd")
	" vim -b : edit binary using xxd-format!
	augroup Binary
		au!
		au BufReadPre *.bin,*.hex,*.pkg,*.img,*.out setlocal binary
		au BufReadPost *
					\ if &binary | Hexmode | endif
		au BufWritePre *
					\ if exists("b:editHex") && b:editHex && &binary |
					\  let oldro=&ro | let &ro=0 |
					\  let oldma=&ma | let &ma=1 |
					\  exe "%!xxd -r" |
					\  let &ma=oldma | let &ro=oldro |
					\  unlet oldma | unlet oldro |
					\ endif
		au BufWritePost *
					\ if exists("b:editHex") && b:editHex && &binary |
					\  let oldro=&ro | let &ro=0 |
					\  let oldma=&ma | let &ma=1 |
					\  exe "%!xxd" |
					\  exe "set nomod" |
					\  let &ma=oldma | let &ro=oldro |
					\  unlet oldma | unlet oldro |
					\ endif
	augroup END
endif

" ex command for toggling hex mode - define mapping if desired
command -bar Hexmode call ToggleHex()
" helper function to toggle hex mode
function ToggleHex()
	" hex mode should be considered a read-only operation
	" save values for modified and read-only for restoration later,
	" and clear the read-only flag for now
	let l:modified=&mod
	let l:oldreadonly=&readonly
	let &readonly=0
	let l:oldmodifiable=&modifiable
	let &modifiable=1
	if !exists("b:editHex") || !b:editHex
		" save old options
		let b:oldft=&ft
		let b:oldbin=&bin
		" set new options
		"setlocal binary " make sure it overrides any textwidth, etc.
		" Kent : mark above line to distinguish between dos(CRLF) and unix(LF) format.
		let &ft="xxd"
		" set status
		let b:editHex=1
		" switch to hex editor
		%!xxd
	else
		" restore old options
		let &ft=b:oldft
		if !b:oldbin
			setlocal nobinary
		endif
		" set status
		let b:editHex=0
		" return to normal editing
		%!xxd -r
	endif
	" restore values for modified and read only state
	let &mod=l:modified
	let &readonly=l:oldreadonly
	let &modifiable=l:oldmodifiable
endfunction

nnoremap <leader>x :Hexmode<CR>

" }}}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" [ Plugin configuration ]                                                   {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

	""""""""""""""""""""""""
	" AWESOME Vundle
	""""""""""""""""""""""""
	set runtimepath+=~/.vim/vundle/
	call vundle#rc()

	Bundle 'gregsexton/gitv'
	Bundle 'majutsushi/tagbar'
	Bundle 'OmniCppComplete'
	Bundle 'Shougo/neocomplcache'
	"Bundle 'clang-complete'
	Bundle 'matrix.vim--Yang'
	Bundle 'chenkaie/DirDiff.vim'
	Bundle 'chenkaie/smarthomekey.vim'
	Bundle 'Lokaltog/vim-powerline'
	Bundle 'EasyMotion'
	Bundle 'Tabular'
	Bundle 'CSApprox'
	Bundle 'ctrlp.vim'
	Bundle 'Decho'
	Bundle 'tpope/vim-fugitive'
	Bundle 'Indent-Guides'
	Bundle 'vim-indent-object'
	Bundle 'LargeFile'
	Bundle 'matchit.zip'
	Bundle 'scrooloose/nerdtree'
	Bundle 'scrooloose/nerdcommenter'
	Bundle 'tpope/vim-surround'
	Bundle 'ervandew/supertab'
	Bundle 'vcscommand.vim'
	Bundle 'wokmarks.vim'
	Bundle 'ShowMarks7'
	Bundle 'smoothPageScroll.vim'
	Bundle 'sessionman.vim'
	Bundle 'nelstrom/vim-visual-star-search'
	Bundle 'nelstrom/vim-markdown-folding'
	Bundle 'Valloric/MatchTagAlways'
	Bundle 'bad-whitespace'
	Bundle 'airblade/vim-gitgutter'
	Bundle 'rking/ag.vim'
	Bundle "MarcWeber/vim-addon-mw-utils"
	Bundle "tomtom/tlib_vim"
	Bundle 'garbas/vim-snipmate'
	Bundle 'honza/vim-snippets'
	Bundle 'othree/javascript-libraries-syntax.vim'

	""""""""""""""""""""""""""""""
	" VCSCommand
	""""""""""""""""""""""""""""""
	nmap d <Esc>:VCSVimDiff<Enter>
	" shortcut for git diff
	nmap g <Esc>:let g:VCSCOMMAND_IDENTIFY_EXACT=-1<Enter>:VCSVimDiff<Enter>

	""""""""""""""""""""""""""""""
	" Smooth Scroll
	""""""""""""""""""""""""""""""
	"Smooth Scroll
	map <PageDown> :call SmoothPageScrollDown()<CR>
	map <PageUp>   :call SmoothPageScrollUp()<CR>

	""""""""""""""""""""""""""""""
	" Tag List
	""""""""""""""""""""""""""""""
	" nmap <F12>   :TlistToggle<CR>

	" Split to the right side of the screen
	let g:Tlist_Use_Right_Window = 1
	" Sort by the order
	let g:Tlist_Sort_Type = "order"
	" If you are the last, kill yourself
	let g:Tlist_Exit_OnlyWindow = 1
	" Do not show folding tree
	let g:Tlist_Enable_Fold_Column = 0
	" Always display one file tags
	let g:Tlist_Show_One_File = 1

	""""""""""""""""""""""""""""""
	" TagBar
	""""""""""""""""""""""""""""""
	nmap <F12>   :TagbarToggle<CR>

	""""""""""""""""""""""""""""""
	" Minibuffer
	""""""""""""""""""""""""""""""
	let g:miniBufExplModSelTarget = 1
	hi MBENormal ctermfg=7
	hi MBEVisibleNormal ctermfg=2
	hi MBEChanged ctermfg=14
	hi MBEVisibleChanged ctermfg=2

	""""""""""""""""""""""""""""""
	" SrcExplorer
	""""""""""""""""""""""""""""""
	"let s:SrcExpl_tagsPath = '/home/kent/cscope_ctag/lsp/'
	"let s:SrcExpl_workPath = '/home/kent/cscope_ctag/lsp/'
	" Let the Source Explorer update the tags file when opening
	let g:SrcExpl_updateTags = 0

	""""""""""""""""""""""""""""""
	" vimgdb
	""""""""""""""""""""""""""""""
	let g:vimgdb_debug_file = ""
	run macros/gdb_mappings.vim

	""""""""""""""""""""""""""""""
	" ShowMarks
	""""""""""""""""""""""""""""""
	let g:showmarks_include='abcdefghijklmnopqrtuvwxyz'
	let g:showmarks_ignore_type="h"
	let g:showmarks_textlower="\t"
	let g:showmarks_textupper="\t"
	let g:showmarks_textother="\t"
	let g:showmarks_auto_toggle = 0
	nnoremap <silent> mt :ShowMarksToggle<CR>

	hi ShowMarksHLl ctermfg=red   ctermbg=black
	hi ShowMarksHLu ctermfg=green ctermbg=black
	hi ShowMarksHLo ctermfg=red   ctermbg=black
	hi ShowMarksHLm ctermfg=red   ctermbg=black

	""""""""""""""""""""""""""""""
	" wokmarks
	""""""""""""""""""""""""""""""
	let g:wokmarks_do_maps = 0
	let g:wokmarks_pool = "abcdefghijklmnopqrtuvwxyz"
	map mm <Plug>ToggleMarkWok
	map mj <Plug>NextMarkWok
	map mk <Plug>PrevMarkWok
	autocmd User WokmarksChange :ShowMarksOn

	""""""""""""""""""""""""""""""
	" EasyMotion
	""""""""""""""""""""""""""""""
	noremap [emotion] <Nop>
	noremap [emotion]<Space> e
	map <leader>e [emotion]
	let g:EasyMotion_leader_key = '[emotion]'

	""""""""""""""""""""""""""""""
	" Indent Guides
	""""""""""""""""""""""""""""""
	let g:indent_guides_start_level=2
	hi IndentGuidesOdd  ctermbg=237
	hi IndentGuidesEven ctermbg=darkgrey
	let g:indent_guides_guide_size=1
	nnoremap <leader>i :IndentGuidesToggle<CR>

	""""""""""""""""""""""""""""""
	" Powerline
	""""""""""""""""""""""""""""""
	let g:Powerline_dividers_override = [ [0x2b80], [0x003e], [0x2b82], [0x003c] ]
	if OS == "Darwin"
		let g:Powerline_symbols='fancy'
	else
		let g:Powerline_symbols='fancy'
	endif
	"call Pl#Theme#InsertSegment('ws_marker', 'after', 'lineinfo')

	""""""""""""""""""""""""""""""
	" CtrlP
	""""""""""""""""""""""""""""""
	let g:ctrlp_map = 'p'  "Alt+P

	""""""""""""""""""""""""
	" ag.vim
	""""""""""""""""""""""""
	map <F3> <esc>:Ag <cword><cr>

	""""""""""""""""""""""""""""""
	" vim-snipmate
	""""""""""""""""""""""""""""""
	let g:snipMate = {}
	let g:snipMate.scope_aliases = {}
	let g:snipMate.scope_aliases['javascript'] = 'javascript,javascript-jquery'

" }}}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" [ Functions & autocmd ]                                                    {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" set vim to chdir for each file
if exists('+autochdir')
	set autochdir
else
	autocmd BufEnter * silent! lcd %:p:h:gs/ /\\ /
endif
" Automatically update 'Last Modified' field
" If buffer modified, update any 'Last modified: ' in the first 20 lines.
function! LastModified()
	if &modified
		normal ms
		let n = min([20, line("$")])
		exe '1,' . n . 's#^\(.\{,10}Last Modified: \).*#\1' .
					\ strftime('%a %b %d, %Y  %I:%M%p') . '#e'
		normal `s
	endif
endfun
autocmd BufWritePre * call LastModified()

" Remember the line number been edited last time
"if has("autocmd")
	"autocmd BufRead *.txt set tw=78
	"autocmd BufReadPost *
		"\ if line("'\"") > 0 && line ("'\"") <= line("$") |
		"\   exe "normal g'\"" |
		"\ endif
"endif

"autocmd BufWinLeave * if expand("%") != "" | mkview | endif
"autocmd BufWinEnter * if expand("%") != "" | loadview | endif
"Restore cursor to file position in previous editing session
autocmd BufReadPost * if line ("'\"") > 0 && line ("'\"") <= line("$") | exe "normal g'\"" | endif


" QUICKFIX WINDOW for :make
command -bang -nargs=? QFix call QFixToggle(<bang>0)
function! QFixToggle(forced)
	if exists("g:qfix_win") && a:forced == 0
		cclose
		unlet g:qfix_win
	else
		botright copen 10
		let g:qfix_win = bufnr("$")
	endif
endfunction
nnoremap <leader>q :QFix<CR>

" Remove unnecessary spaces in the end of line
"autocmd FileType c,cpp,perl,python,sh,html,js autocmd FileWritePre,BufWritePre <buffer> :call setline(1,map(getline(1,"$"),'substitute(v:val,"\\s\\+$","","")'))

" [Highlight column matching { } pattern], A very cool stuff(Kent)
"let s:hlflag=0
"function! ColumnHighlight()
"   let c=getline(line('.'))[col('.') - 1]
"   if c=='{' || c=='}'
"       set cuc
"       let s:hlflag=1
"   else
"       if s:hlflag==1
"           set nocuc
"           let s:hlflag=0
"       endif
"   endif
"endfunction
"
"autocmd CursorMoved * call ColumnHighlight()

" Vim Eval snippet by c9s
fun! EvalVimScriptRegion(s,e)
	let lines = getline(a:s,a:e)
	let file = tempname()
	cal writefile(lines,file)
	silent exec ':source '.file
	redraw
	cal delete(file)
	echo "Region evaluated."
	sleep 500m
	"normal gv
endf
augroup VimEval
	au!
	au filetype vim :command! -range Eval :cal EvalVimScriptRegion(<line1>,<line2>)
	au filetype vim :vnoremap <silent> e :Eval<CR>
augroup END

set foldtext=MyFoldText()
function! MyFoldText()
	let lines = 1 + v:foldend - v:foldstart
	let ind = indent(v:foldstart)

	let spaces = ''
	let i = 0
	while i < ind
		let spaces .= ' '
		let i += 1
	endwhile

	let linestxt = 'lines'
	if lines == 1
		linestxt = 'line'
	endif

	let firstline = getline(v:foldstart)
	let line = firstline[ind : ind+80]

	return spaces . '+' . v:folddashes . ' ' . lines . ' ' . linestxt . ': ' . line . ' '
endfunction

" Highlight long lines
nnoremap <silent> <Leader>l
	\ :if exists('w:long_line_match') <Bar>
	\   silent! call matchdelete(w:long_line_match) <Bar>
	\   unlet w:long_line_match <Bar>
	\ elseif &textwidth > 0 <Bar>
	\   let w:long_line_match = matchadd('ErrorMsg', '\%>'.&tw.'v.\+', -1) <Bar>
	\ else <Bar>
	\   let w:long_line_match = matchadd('ErrorMsg', '\%<81v.\%>77v', -1) <Bar>
	\ endif<CR>

" trigger by :call HtmlEscape()
function HtmlEscape()
	silent s/&/\&amp;/eg
	silent s/</\&lt;/eg
	silent s/>/\&gt;/eg
	silent s/"/\&quot;/eg
endfunction

" trigger by :call HtmlUnEscape()
function HtmlUnEscape()
	silent s/&lt;/</eg
	silent s/&gt;/>/eg
	silent s/&amp;/\&/eg
	silent s/&quot;/"/eg
endfunction

" Erase the bad whitespace with the command |EraseBadWhitespace|
function! ToggleSpecialChar()
	if !&list
		set list
		ShowBadWhitespace
	else
		set nolist
		HideBadWhitespace
	endif
endfunction

" Set tabstop, softtabstop and shiftwidth to the same value
" From http://vimcasts.org/episodes/tabs-and-spaces/
command! -nargs=* Stab call Stab()
function! Stab()
	let l:tabstop = 1 * input('set tabstop = softtabstop = shiftwidth = ')
	if l:tabstop > 0
		let &l:sts = l:tabstop
		let &l:ts = l:tabstop
		let &l:sw = l:tabstop
	endif
	call SummarizeTabs()
endfunction

function! SummarizeTabs()
	try
		echohl ModeMsg
		echon 'tabstop='.&l:ts
		echon ' shiftwidth='.&l:sw
		echon ' softtabstop='.&l:sts
		if &l:et
			echon ' expandtab'
		else
			echon ' noexpandtab'
		end
	finally
		echohl None
	endtry
endfunction
" }}}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" [ FileType ]                                                               {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Ref: ~/.vim/filetype.vim
" }}}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" [ MISC ]                                                                   {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" VIM debug
function! ToggleVerbose()
	if !&verbose
		set verbosefile=~/tmp/vim_verbose.log
		set verbose=15
	else
		set verbose=0
		set verbosefile=
	endif
endfunction

" Delete all trailing whitespace
" :%s/\s\+$//

" Delete all trailing whitespace including pesky ^M
" :%s/[ \t\r]\+$//e

" Delete whitespace at the beginning of each line
" 1. :%s/^\s\+//    2. :%le

" To change all the existing tab characters to match the current tab settings, use:
" :retab  (related with "set expandtab / set noexpandtab)

" }}}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" [ After Loading All Plugin ]                                               {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function AfterStart ()
	" Used to remove my own specific defined behavior for others who use my .vimrc
	"autocmd! BufWritePost,FileWritePost [^jquery]*.js
endfunction
autocmd VimEnter * :call AfterStart()

" }}}

" vim:fdm=marker:fdl=0:
