augroup filetypedetect
    " cappuccino, objective j
    au BufNewFile,BufRead *.j setf objj
    au BufNewFile,BufRead *.objj setf objj
    " filetype for mkd
    au BufNewFile,BufRead *.mkd,*.markdown setfiletype markdown
    " lowlight ^M symbol.
    au BufRead *.c,*.h match Ignore /\r$/ | hi Ignore ctermfg=bg
    " use better colorscheme to edit HTML
    au BufRead *.htm*,*.css,*.js colorscheme ir_black_cterm | call Pl#Load()
    " increase the maximum nesting of folds for HTML
    au BufRead *.htm* set foldnestmax=10
    " Set default fdm for *.c,*.h file
    " WTF! Resource consuming monster when starting omni-completion in a larger file
    " au BufRead *.c,*.h set fdm=syntax
    " set Spell check: ON when svn,git commit
    au BufRead svn-commit.*tmp,COMMIT_EDITMSG :set spell
    " Syntax file for jQuery
    au BufRead,BufNewFile jquery.*.js set ft=javascript syntax=jquery synmaxcol=256
augroup END
