" https://gist.github.com/hotchpotch/719707
"
" function! Ggrep(arg)
"   setlocal grepprg=git\ grep\ --no-color\ -n\ $*
"   silent execute ':grep '.a:arg
"   setlocal grepprg=git\ --no-pager\ submodule\ --quiet\ foreach\ 'git\ grep\ --full-name\ -n\ --no-color\ $*\ ;true'
"   silent execute ':grepadd '.a:arg
"   silent cwin
"   redraw!
" endfunction
"
" command! -nargs=1 -complete=buffer Gg call Ggrep(<q-args>)
" command! -nargs=1 -complete=buffer Ggrep call Ggrep(<q-args>)
" nnoremap <unique> gG :exec ':silent Ggrep ' . expand('<cword>')<CR>
"
