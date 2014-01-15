" Compiler:     PC-lint/FlexeLint: an enhanced Lint for C and C++
" Maintainer:   James Widman <widman->gimpel>
" URL:	        http://gimpel.com
" Last Change:  2008 May 31

if exists("current_compiler")
  finish
endif
let current_compiler = "flint"

" Note, env-vim.lnt sets Lint's error format to conform to Vim's
" default value of the 'errorformat' option.
CompilerSet errorformat&

CompilerSet makeprg=lint\ +v\ ~/makcomm/std_gnu_kent.lnt\ /home/kent/makcomm/env-vim.lnt\ -u\ %
"\\ ~/bin/lint
"\\ --i$HOME/lint_config
"\\ env-vim.lnt
"\\ +b


