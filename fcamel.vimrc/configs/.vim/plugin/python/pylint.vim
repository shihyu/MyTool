" Vim compiler file
" Compiler:     Style checking tool for Python
" Maintainer:   Alexander Timoshenko <gonzo@univ.kiev.ua>
" Last Change: 2004 Feb 01


autocmd BufRead,BufNewFile *.py call SetPyLint()

function SetPyLint()
    if exists("current_compiler")
      finish
    endif
    let current_compiler = "pylint"

    " We should echo filename because pylint trancates .py
    " If someone know better way - let me know :) 
    "
    setlocal makeprg=(echo\ '[%]';\ pylint\ %)
    " We could omit end of file-entry, there is only one file
    setlocal efm=%+P[%f],%t:\ %#%l:%m
endfunction
