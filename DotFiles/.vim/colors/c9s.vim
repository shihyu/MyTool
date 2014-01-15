" vim:sw=18:ts=18:noexpandtab:
" Vim color file
" mainly green on black
"
" cool help screens
" :he group-name
" :he highlight-groups
" :he cterm-colors
" :he highlight-groups

set background=dark
syntax reset
hi clear
if exists("syntax_on")
endif

let g:colors_name = "c9s"


" Interface
" -----------------------------------------------------------------------------
hi Text	ctermfg=none		ctermbg=DarkGray	cterm=none
hi NonText	ctermfg=none		ctermbg=DarkGray	cterm=none
hi Normal 	ctermfg=none 		ctermbg=DarkGray	cterm=none 
hi Search 	ctermfg=White 		ctermbg=DarkGray 	cterm=none 
hi Visual 	ctermfg=Black 		ctermbg=Cyan	cterm=none 
hi LineNr 	ctermfg=DarkGreen 	ctermbg=Black 	cterm=none
hi Underlined	ctermfg=none

hi Cursor 	ctermfg=White 		ctermbg=DarkGray 	cterm=none 
hi CursorLine	ctermfg=gray		ctermbg=Black	cterm=none

hi StatusLine 	ctermfg=White 		ctermbg=DarkBlue	cterm=none
hi StatusLineNC	ctermfg=Black		ctermbg=Yellow

hi TabLine	ctermfg=DarkBlue	ctermbg=DarkGray
hi TabLineSel	ctermfg=Blue		ctermbg=Black
hi TabLineFill	ctermfg=DarkGray	ctermbg=DarkGray

hi Tag	ctermfg=none
hi Error	ctermfg=DarkGray	ctermbg=DarkRed
hi FoldColumn	ctermbg=Black
hi Folded	ctermfg=White	ctermbg=DarkGreen	cterm=bold

hi VertSplit 	ctermfg=Blue 		ctermbg=DarkBlue	cterm=none
hi SignColumn 	ctermfg=LightGreen 	ctermbg=DarkGreen	cterm=none
hi WildMenu 	ctermfg=LightGreen 	ctermbg=DarkGreen	cterm=none
hi Directory 	ctermfg=LightGreen 
hi ModeMsg	ctermfg=White	ctermbg=blue	

" Source code hilight
" -----------------------------------------------------------------------------
hi Function	ctermfg=green	ctermbg=none	cterm=bold
hi Comment	ctermfg=blue	ctermbg=DarkGray	cterm=none
hi Statement	ctermfg=darkgreen	ctermbg=none	cterm=bold
hi Identifier	ctermfg=green	ctermbg=none	cterm=none
"
hi Constant	ctermfg=blue
hi Operator	ctermfg=yellow		ctermbg=none	cterm=bold
hi Character	ctermfg=darkyellow		cterm=none
hi Number	ctermfg=white		cterm=bold
hi Boolean	ctermfg=blue
hi Float	ctermfg=white		cterm=bold
hi String	ctermfg=White	cterm=none

hi Define	ctermfg=blue
hi Keyword	ctermfg=blue	cterm=none
hi Repeat	ctermfg=green	cterm=bold
hi Function	ctermfg=none
hi Delimiter	ctermfg=yellow
hi Special	ctermfg=yellow		cterm=none
hi SpecialChar	ctermfg=yellow		cterm=none

" ------------------------------------------------------------------------------
" Common groups that link to other highlighting definitions.
hi Search 	ctermfg=White	ctermbg=DarkBlue
hi IncSearch	ctermfg=White	ctermbg=DarkBlue	cterm=none
hi link 	Question 	Statement
hi link 	VisualNOS 	Visual
" ------------------------------------------------------------------------------


" XXX: Diff
hi DiffAdd 	ctermfg=Blue 	ctermbg=DarkGray 	cterm=none 
hi DiffChange 	ctermfg=Yellow 	ctermbg=DarkGray 	cterm=none 
hi DiffDelete 	ctermfg=Green 	ctermbg=DarkGray 	cterm=none 
hi DiffText 	ctermfg=White 	ctermbg=DarkGray 	cterm=none 

hi Special 	ctermfg=Brown
hi Title 	ctermfg=Brown
hi Tag 	ctermfg=DarkRed 
"hi link 	Delimiter 	Special
"hi link 	SpecialChar 	Special
hi link 	SpecialComment 	Special
"hi link 	SpecialKey 	Special
"hi link 	NonText 	Special
""
"hi Error 	ctermfg=White 	ctermbg=DarkRed 	cterm=none
"hi Debug 	ctermfg=White 	ctermbg=DarkRed 	cterm=none
"hi ErrorMsg 	ctermfg=White 	ctermbg=DarkRed 	cterm=none
"hi WarningMsg 	ctermfg=White 	ctermbg=DarkBlue 	cterm=none
"hi Todo 	ctermfg=White 	ctermbg=DarkBlue 	cterm=none
"hi link 	cCommentStartError 	WarningMsg
"hi link 	cCommentError 		Debug
"
" Preprocesor
"hi PreCondit 	ctermfg=Cyan
"hi PreProc 	ctermfg=Magenta
"hi Include 	ctermfg=DarkCyan
"hi ifdefIfOut 	ctermfg=DarkGray
"hi link 	Macro 	Include
"hi link 	Define 	Include
"
" lang
"hi Function 	ctermfg=LightGreen
"hi Identifier 	ctermfg=LightGreen
"hi Statement 	ctermfg=LightGreen 
"hi Operator 	ctermfg=Yellow 
"hi Conditional 	ctermfg=LightBlue 
"
"
"hi link 	Exception 	Statement
"hi link 	Label 	Statement
"hi link 	Repeat 	Conditional
"
"hi link Keyword Label
"
"hi Constant 	ctermfg=LightGreen 
"hi link 	Character 	Constant
"hi link 	Number 	Constant
"hi link 	Boolean 	Constant
"hi link 	String 	Constant
"hi link 	Float 	Constant
""
"hi Type 	ctermfg=DarkGreen 
"hi link 	StorageClass 	Type
"hi link 	Structure 	Type
"hi link 	Typedef 	Type

"" Perl Code:
"" /usr/share/vim/vim71/syntax/perl.vim
"" ----------------------------------------------------------------------
"
"" Perl Identifiers.
""
"" Should be cleaned up to better handle identifiers in particular situations
"" (in hash keys for example)
""
"" Plain identifiers: $foo, @foo, $#foo, %foo, &foo and dereferences $$foo, @$foo, etc.
"" We do not process complex things such as @{${"foo"}}. Too complicated, and
"" too slow. And what is after the -> is *not* considered as part of the
"" variable - there again, too complicated and too slow.
"
"" Special variables first ($^A, ...) and ($|, $', ...)
"hi perlIdentifier	ctermfg=yellow	cterm=none
"" $/ $^A $| $'
"" but avoids confusion in $::foo (equivalent to $main::foo)
"hi perlVarSlash		ctermfg=yellow	cterm=none
"
"hi perlVarPlain		ctermfg=Magenta	cterm=bold
"" %hash , @array
"hi perlVarPlain2	ctermfg=Magenta	cterm=bold
hi perlVarBlock		ctermfg=none	ctermbg=none	cterm=bold
"
"" my , our 
"hi perlStatementStorage	ctermfg=cyan	ctermbg=none	cterm=none
"
"hi perlAutoload		ctermfg=Magenta	ctermbg=none	cterm=bold
"
"" Brackets: in qq()
"hi perlBrackets		ctermfg=none	ctermbg=none	cterm=none
"
"" Conditional: if switch eq ne gt lt ge le cmp not and or xor ...
"hi perlConditional	ctermfg=Magenta	ctermbg=none	cterm=bold
"
"" Control: BEGIN CHECK INIT NED
"hi perlControl		ctermfg=Magenta	ctermbg=none	cterm=bold
"
"" Function:		sub 
"hi perlStatementSub	ctermfg=Magenta	ctermbg=none	cterm=bold
"
"" Function: sub [_name_] [(_prototype_)] {
"hi perlFunction		ctermfg=none	ctermbg=none	cterm=none
hi perlFunctionName	ctermfg=Cyan	ctermbg=Black	cterm=bold
hi perlFunctionPrototype	ctermfg=Cyan	cterm=bold
"
"" $o->method
"hi perlMethod		ctermfg=Magenta	cterm=none
"
"" $o->{membername}
""	\i	identifier character (see 'isident' option)
""	\I	like "\i", but excluding digits
"hi perlVarMember	ctermfg=none	ctermbg=none	cterm=none
"hi perlVarSimpleMember	ctermfg=Magenta	cterm=bold
"hi perlVarSimpleMemberName	ctermfg=Magenta	cterm=none
"
"" \w*::
""hi perlFunctionPRef		ctermfg=white	cterm=bold
"
"" Package:
"" keyword:		package FOO::Bar;
"hi perlStatementPackage	ctermfg=Magenta	ctermbg=none	cterm=bold
"" declarations: pacakge _package::name_;
"hi perlPackageDecl		ctermfg=Magenta	cterm=none
"" plain identifiers:  $_package_::foo
"hi perlPackageRef		ctermfg=white	cterm=none
"
"
"
"" Heredoc: text inside heredoc
"hi perlHereDoc		ctermfg=white	ctermbg=none	cterm=none
"
"" Heredoc: heredoc id ( <<EOF
"hi perlHereIdentifier	ctermfg=none	ctermbg=none	cterm=none
"
"" Substitutions:
"" caters for tr///, tr### and tr[][]
"" perlMatch is the first part, perlTranslation* is the second, translator part.
"hi perlMatch		ctermfg=none	ctermbg=none	cterm=none
"hi perlTranslationBracket	ctermfg=none	ctermbg=none	cterm=none
"hi perlTranslationCurly	ctermfg=none	ctermbg=none	cterm=none
"hi perlTranslationDQ	ctermfg=none	ctermbg=none	cterm=none
"hi perlTranslationHash	ctermfg=none	ctermbg=none	cterm=none
"hi perlTranslationSQ	ctermfg=none	ctermbg=none	cterm=none
"hi perlTranslationSlash	ctermfg=none	ctermbg=none	cterm=none
"
"" Substitutions:
"" caters for s///, s### and s[][]
"" perlMatch is the first part, perlSubstitution* is the substitution part
"" single quote: s'foo'bar'
"hi perlSubstitutionSQ	ctermfg=cyan	ctermbg=none	cterm=none
"" double quote: s"foo"bar"
"hi perlSubstitutionDQ	ctermfg=cyan	ctermbg=none	cterm=none
"" slash: s/foo/bar/
"hi perlSubstitutionSlash	ctermfg=cyan	ctermbg=none	cterm=none
"" bracket: s[foo][bar]
"hi perlSubstitutionBracket	ctermfg=cyan	ctermbg=none	cterm=none
"" cruly:  s{foo}{bar}
"hi perlSubstitutionCurly	ctermfg=cyan	ctermbg=none	cterm=none
"" hash: s#foo#bar#
"hi perlSubstitutionHash	ctermfg=cyan	ctermbg=none	cterm=none
"" Pling  s!foo!bar!
"hi perlSubstitutionPling	ctermfg=cyan	ctermbg=none	cterm=none
"
"" Operators: 		defined undef and or not bless ref
"hi perlOperator		ctermfg=none	ctermbg=none	cterm=none
"
"" POD: =head1 [name]
"hi perlPOD		ctermfg=Magenta	ctermbg=none	cterm=none
""hi perlType		
"
"hi perlPackageFold	ctermfg=none	ctermbg=none	cterm=none
"hi perlBlockFold	ctermfg=none	ctermbg=none	cterm=none
"hi perlSubFold		ctermfg=none	ctermbg=none	cterm=none
"
"" QQ: link to perlString: 	qq{ } , qw/ / , qr/ / , qx/ /
"hi perlQQ		ctermfg=cyan	ctermbg=none	cterm=none
"
"" Repeat: 		while for foreach do until continue
"hi perlRepeat		ctermfg=cyan	ctermbg=none	cterm=bold
"
"" keyword 		goto return last next redo
"hi perlStatementControl	ctermfg=cyan	ctermbg=none	cterm=bold
"
"" keyword 		binmode close closedir eof fileno getc lstat print printf readdir readline readpipe rewinddir select stat tell telldir write nextgroup=perlFiledescStatementNocomma skipwhite
"" keyword 		fcntl flock ioctl open opendir read seek seekdir sysopen sysread sysseek syswrite truncate nextgroup=perlFiledescStatementComma skipwhite
"hi perlStatementFiledesc	ctermfg=darkyellow	ctermbg=none	cterm=none
"
"" keyword:		chdir chmod chown chroot glob link mkdir readlink rename rmdir symlink umask unlink utime
""  -[rwxoRWXOezsfdlpSbctugkTBMAC]\>
"hi perlStatementFiles	ctermfg=none	ctermbg=none	cterm=none
"
"" keyword: 		caller die dump eval exit wantarray
hi perlStatementFlow	ctermfg=yellow	ctermbg=none	cterm=bold
"
"" keyword: 		each exists keys values tie tied untie
hi perlStatementHash	ctermfg=yellow	ctermbg=none	cterm=bold
"
"" keyword:		carp confess croak dbmclose dbmopen die syscall
"hi perlStatementIOfunc	ctermfg=yellow	ctermbg=none	cterm=none
"
"" keyword:		msgctl msgget msgrcv msgsnd semctl semget semop shmctl shmget shmread shmwrite
"hi perlStatementIPC	ctermfg=yellow	ctermbg=none	cterm=none
"
"" keyword 		require
""		"\<\(use\|no\)\s\+\(\(integer\|strict\|lib\|sigtrap\|subs\|vars\|warnings\|utf8\|byte\|base\|fields\)\>\)\="
"hi perlStatementInclude	ctermfg=Magenta	ctermbg=none	cterm=none
"
"" keyword:		splice unshift shift push pop split join reverse grep map sort unpack
hi perlStatementList	ctermfg=yellow	ctermbg=none	cterm=bold
"
"" keyword:		warn formline reset scalar delete prototype lock
hi perlStatementMisc	ctermfg=yellow	ctermbg=none	cterm=bold
"
"" keyword		endhostent endnetent endprotoent endservent gethostbyaddr gethostbyname gethostent getnetbyaddr getnetbyname getnetent getprotobyname getprotobynumber getprotoent getservbyname getservbyport getservent sethostent setnetent setprotoent setservent
"hi perlStatementNetwork	ctermfg=none	ctermbg=none	cterm=none
"
"" $o->new()
"hi perlStatementNew	ctermfg=Magenta	ctermbg=none	cterm=bold
"
"" keyword:		abs atan2 cos exp hex int log oct rand sin sqrt srand
hi perlStatementNumeric	ctermfg=yellow	ctermbg=none	cterm=bold
"
"
"" keyword:		alarm exec fork getpgrp getppid getpriority kill pipe setpgrp setpriority sleep system times wait waitpid
"hi perlStatementProc	ctermfg=none	ctermbg=none	cterm=none
"
"hi perlStatementPword	ctermfg=none	ctermbg=none	cterm=none
"hi perlStatementRegexp	ctermfg=none	ctermbg=none	cterm=none
"hi perlStatementScalar	ctermfg=none	ctermbg=none	cterm=none
hi perlStatementScope	ctermfg=yellow	ctermbg=none	cterm=none
"hi perlStatementSocket	ctermfg=none	ctermbg=none	cterm=none
"
"
"hi perlStatementTime	ctermfg=none	ctermbg=none	cterm=none
"hi perlStatementVector	ctermfg=none	ctermbg=none	cterm=none
"
"
"" The => operator forces a bareword to the left of it to be interpreted as
"" a string
"" "\<\I\i*\s*=>"me=e-2
"" Strings and q, qq, qw and qr expressions
"hi perlString		ctermfg=cyan	ctermbg=none	cterm=none
"hi perlStringUnexpanded	ctermfg=cyan	ctermbg=none	cterm=none
"
"hi perlTodo		ctermfg=Black	ctermbg=yellow	cterm=none
""hi perlUntilEOFDQ	ctermfg=none	ctermbg=none	cterm=none
""hi perlUntilEOFSQ	ctermfg=none	ctermbg=none	cterm=none
""hi perlUntilEOFStart	ctermfg=none	ctermbg=none	cterm=none
""hi perlUntilEmptyDQ	ctermfg=none	ctermbg=none	cterm=none
""hi perlUntilEmptySQ	ctermfg=none	ctermbg=none	cterm=none
""
"" Comment:
"" All other # are comments, except ^#!
"hi perlSharpBang		ctermfg=cyan	cterm=bold
"hi perlComment			ctermfg=blue	cterm=none
"
"" File Descriptors:
"" open FH , "< filename";
""hi perlFiledescRead		ctermfg=Magenta	cterm=none
"hi perlFiledescStatement		ctermfg=Magenta	cterm=none
"hi perlFiledescStatementComma		ctermfg=Magenta	cterm=bold
"hi perlFiledescStatementNocomma		ctermfg=Magenta	cterm=none
"
"" Constant:
"hi perlFloat			ctermfg=yellow	cterm=none
"hi perlNumber			ctermfg=yellow	cterm=none
"
"" Special characters in strings and matches
"" \123 \xA0 \c1
hi perlSpecialString		ctermfg=none	cterm=bold
hi perlInterpDQ			ctermfg=White	cterm=bold
"
"" something like: \d \n \t
hi perlSpecialStringU		ctermfg=none	cterm=bold
"
"" something like: (?[imsx]\+)  (?[#:=!]   [+*()?.]
"hi perlSpecialMatch		ctermfg=none	cterm=none
"
""hi perlFormat		ctermfg=none	ctermbg=none	cterm=none
""hi perlFormatField		ctermfg=none	cterm=none
""hi perlFormatName		ctermfg=none	cterm=none
"
"
""hi perlNotEmptyLine		ctermfg=none	cterm=none
""hi perlUntilEOFStart		ctermfg=none	cterm=none
"
""hi perlVarNotInMatches		ctermfg=none	cterm=none
"
