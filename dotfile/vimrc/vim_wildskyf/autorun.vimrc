" ========================================
" ============== auto run ================
" ========================================

" au BufRead,BufNewFile *.ejs setf javascript.jsx

" stable ==========

" syntax highlight setup
au BufNewFile,BufRead *.hbs* set filetype=mustache

" limit char number for git commit
autocmd Filetype gitcommit setlocal spell textwidth=72

" redundant whitespace bye bye
autocmd BufWritePre * StripWhitespace
"
" auto toggle LineNumber between absolute or relative
" autocmd FocusLost   * :call SetNumber()
" autocmd FocusGained * :call SetRelativeNumber()
" autocmd InsertEnter * :call SetNumber()
" autocmd InsertLeave * :call SetRelativeNumber()

" restore the position last I open the file
if has("autocmd")
  au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
endif

" switch the shape of the cursor
if exists('$TMUX')
  let &t_SI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=1\x7\<Esc>\\"
  let &t_EI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=0\x7\<Esc>\\"
else
  let &t_SI = "\<Esc>]50;CursorShape=1\x7"
  let &t_EI = "\<Esc>]50;CursorShape=0\x7"
endif
autocmd InsertEnter * set cursorline
autocmd InsertLeave * set nocursorline


" auto switch paste mode
if &term =~ "xterm.*"
	let &t_ti = &t_ti . "\e[?2004h"
	let &t_te = "\e[?2004l" . &t_te
	function XTermPasteBegin(ret)
		set pastetoggle=<Esc>[201~
		set paste
		return a:ret
	endfunction
	map <expr> <Esc>[200~ XTermPasteBegin("i")
	imap <expr> <Esc>[200~ XTermPasteBegin("")
	cmap <Esc>[200~ <nop>
	cmap <Esc>[201~ <nop>
endif

