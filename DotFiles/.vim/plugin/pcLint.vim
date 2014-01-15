" File:         javascriptLint.vim
" Author:       Joe Stelmach (joe@zenbe.com)
" Version:      0.1
" Description:  javascriptLint.vim allows the JavaScript Lint (jsl) program from 
"               http://www.javascriptlint.com/ to be tightly integrated with vim. 
"               The contents of a javascript file will be passed through the jsl program
"               after the file's buffer is saved.  Any lint warnings will be placed in
"               the quickfix window.  JavaScript Lint must be installed on your system
"               for this plugin to work properly.  This page should get you started:
"               http://www.javascriptlint.com/docs/index.htm
" Last Modified: Tue Sep 08, 2009  01:37PM
if !exists("CLint_command")
  let CLint_command = 'lint +v ~/makcomm/std_gnu_kent.lnt ~/makcomm/env-vim.lnt'
endif

if !exists("CLint_command_options")
  let CLint_command_options = ''
endif

if !exists("CLint_highlight_color")
  let CLint_highlight_color = 'DarkMagenta'
endif

" set up auto commands, 
" Kent unmark below to enable CLint();
"autocmd BufWritePost,FileWritePost *.c,*.cpp call CLint()
"autocmd BufWinLeave * call s:MaybeClearCursorLineColor()

" Runs the current file through javascript lint and 
" opens a quickfix window with any warnings
function CLint() 
  " Kent
  setlocal errorformat=%f:(%l\\,%c):[%t%*[^:]\\,%n]:\ %m 

  " run javascript lint on the current file
  "let current_file = shellescape(expand('%:p'))
  let current_file = expand('%:p')
  let cmd_output = system(g:CLint_command . ' ' . g:CLint_command_options . ' ' . current_file . ' ' . "| dos2unix")
  "add by Kent to change path expression to unix-like, eg: \home\kent -> /home/kent
  let cmd_output = substitute(cmd_output, '\\', '\/', 'g') 

  " if some warnings were found, we process them
  if strlen(cmd_output) > 0

    " write quickfix errors to a temp file 
    let quickfix_tmpfile_name = tempname()
    exe "redir! > " . quickfix_tmpfile_name
      silent echon cmd_output
    redir END

    " read in the errors temp file 
    execute "silent! cgetfile " . quickfix_tmpfile_name

    " change the cursor line to something hard to miss 
    call s:SetCursorLineColor()

    " open the quicfix window
    botright copen 5 
    let s:qfix_win = bufnr("$")

    " delete the temp file
    call delete(quickfix_tmpfile_name)

  " if no javascript warnings are found, we revert the cursorline color
  " and close the quick fix window
  else 
    call s:ClearCursorLineColor()
    cclose
  endif
endfunction

" Kent, For makcomm -> make lint
function MakeLint()
    setlocal errorformat=%f:(%l\\,%c):[%t%*[^:]\\,%n]:\ %m
    let cmd_output = system("make lint | dos2unix")
    let cmd_output = substitute(cmd_output, '\\', '\/', 'g')
    " if some warnings were found, we process them
    if strlen(cmd_output) > 0 

        " write quickfix errors to a temp file 
        let quickfix_tmpfile_name = tempname()
        exe "redir! > " . quickfix_tmpfile_name
        silent echon cmd_output
        redir END 

        " read in the errors temp file 
        execute "silent! cfile " . quickfix_tmpfile_name

        " change the cursor line to something hard to miss 
        call s:SetCursorLineColor()

        " open the quicfix window
        botright copen 8
        let s:qfix_win = bufnr("$")

        " delete the temp file
        call delete(quickfix_tmpfile_name)

        " if no javascript warnings are found, we revert the cursorline color
        " and close the quick fix window
    else 
        call s:ClearCursorLineColor()
        cclose
    endif
endfunction
command! -nargs=0 MakeLint call MakeLint()


" sets the cursor line highlight color to the error highlight color 
function s:SetCursorLineColor() 
  call s:ClearCursorLineColor()
  let s:highlight_on = 1 

  " find the current cursor line highlight info 
  redir => l:highlight_info
    silent highlight CursorLine
  redir END

  " find the guibg property within the highlight info (if it exists)
  let l:start_index = match(l:highlight_info, "guibg")
  if(l:start_index > 0)
    let s:previous_cursor_guibg = strpart(l:highlight_info, l:start_index)

  elseif(exists("s:previous_cursor_guibg")) 
    unlet s:previous_cursor_guibg
  endif

  execute "highlight CursorLine guibg=" . g:CLint_highlight_color
endfunction

" Conditionally reverts the cursor line color based on the presence
" of the quickfix window
function s:MaybeClearCursorLineColor()
  if(exists("s:qfix_win") && s:qfix_win == bufnr("%"))
    call s:ClearCursorLineColor()
  endif
endfunction

" Reverts the cursor line color
function s:ClearCursorLineColor()
  " only revert if our highlight is currently enabled
  if(exists("s:highlight_on") && s:highlight_on) 
    let s:highlight_on = 0 

    " if a previous cursor guibg color was recorded, we use it
    if(exists("s:previous_cursor_guibg")) 
      execute "highlight CursorLine " . s:previous_cursor_guibg
      unlet s:previous_cursor_guibg

    " otherwise, we clear the curor line highlight entirely
    else
      highlight clear CursorLine 
    endif
  endif
endfunction
