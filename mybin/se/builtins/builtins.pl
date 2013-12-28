#
#  Copyright 1998-2002 by SlickEdit Inc.
#  All rights reserved.
#
#  This software is the confidential and proprietary information
#  of SlickEdit Inc. You shall not disclose this information and
#  shall use it only with Visual SlickEdit.
#
#  You may modify this file to add new built-ins
#  for Visual SlickEdit's Context Tagging(TM).  Let us know about
#  new built-ins.  This way our installation/update will install the
#  most up-to-date version and you won't need to maintain a
#  backup.
#
print "copyright";


# The default input and pattern-searching space.
# The following pairs are equivalent: 
# 
#     while (<>) {...}    # equivalent in only while!
#     while (defined($_ = <>)) {...}
# 
#     /^Subject:/
#     $_ =~ /^Subject:/
# 
#     tr/a-z/A-Z/
#     $_ =~ tr/a-z/A-Z/
# 
#     chop
#     chop($_)
# 
# Here are the places where Perl will assume $_ even if you don't use it: 
# Various unary functions, including functions like ord() and int(), 
# as well as the all file tests ( -f, -d) except for -t, which defaults to STDIN. 
# 
# Various list functions like print() and unlink(). 
# 
# The pattern matching operations m//, s///, and tr/// when used without an =~ operator. 
# 
# The default iterator variable in a foreach loop if no other variable is supplied. 
# 
# The implicit iterator variable in the grep() and map() functions. 
# 
# The default place to put an input record when a <FH> operation's result is 
# tested by itself as the sole criterion of a while test. 
# Note that outside of a while test, this will not happen.
#  
# (Mnemonic: underline is understood in certain operations.)
# 
our ($ARG,"$_");

# Contains the subpattern from the corresponding set of parentheses 
# in the last pattern matched, not counting patterns matched in nested 
# blocks that have been exited already. 
# 
# (Mnemonic: like \digits.) 
# These variables are all read-only. 
#
our ($1,$2,$3,$4,$5,$6,$7,$8,$9); 

# The string matched by the last successful pattern match (not counting
#  any matches hidden within a BLOCK or eval() enclosed by the current BLOCK).
#  
# (Mnemonic: like & in some editors.) 
# This variable is read-only. 
#
our ($MATCH,"$&");

# The string preceding whatever was matched by the last successful pattern match 
# (not counting any matches hidden within a BLOCK or eval enclosed by the 
# current BLOCK). 
# 
# (Mnemonic: ` often precedes a quoted string.) 
# This variable is read-only. 
# 
our ($PREMATCH,"$`");

# The string following whatever was matched by the last successful pattern
# match (not counting any matches hidden within a BLOCK or eval() enclosed by 
# the current BLOCK). 
# 
# (Mnemonic: ' often follows a quoted string.) 
# 
# Example: 
# 
#     $_ = 'abcdefghi';
#     /def/;
#     print "$`:$&:$'\n";         # prints abc:def:ghi
# 
# This variable is read-only. 
# 
our ($POSTMATCH,"$'");

# The last bracket matched by the last search pattern. 
# This is useful if you don't know which of a set of alternative 
# patterns matched. For example: 
# 
#     /Version: (.*)|Revision: (.*)/ && ($rev = $+);
# 
# (Mnemonic: be positive and forward looking.) This variable is read-only. 
# 
our ($LAST_PAREN_MATCH,"$+");

# Set to 1 to do multi-line matching within a string, 0 to tell Perl
# that it can assume that strings contain a single line, for the purpose 
# of optimizing pattern matches. Pattern matches on strings containing 
# multiple newlines can produce confusing results when ``$*'' is 0. 
# Default is 0. 
# 
# (Mnemonic: * matches multiple things.) 
# 
# Note that this variable influences the interpretation of only ``^'' and ``$''. 
# A literal newline can be searched for even when $* == 0.
#  
# Use of ``$*'' is deprecated in modern Perls, 
# supplanted by the /s and /m modifiers on pattern matching. 
# 
our ($MULTILINE_MATCHING,"$*");

# The current input line number for the last file handle from which you read 
# (or performed a seek or tell on). An explicit close on a filehandle resets 
# the line number. Because ``<>'' never does an explicit close, line numbers 
# increase across ARGV files (but see examples under eof()). 
# Localizing $. has the effect of also localizing Perl's notion of ``the last 
# read filehandle''. 
# 
# (Mnemonic: many programs use ``.'' to mean the current line number.)
#  
our ($INPUT_LINE_NUMBER,$NR,"$.");

# The input record separator, newline by default. 
# Works like awk's RS variable, including treating empty lines as delimiters 
# if set to the null string. 
# 
# (Note: An empty line cannot contain any spaces or tabs.) 
# 
# You may set it to a multi-character string to match a multi-character delimiter, 
# or to undef to read to end of file. Note that setting it to "\n\n" means 
# something slightly different than setting it to "", if the file contains 
# consecutive empty lines. Setting it to "" will treat two or more consecutive 
# empty lines as a single empty line. Setting it to "\n\n" will blindly assume 
# that the next input character belongs to the next paragraph, even if it's a newline. 
# 
# (Mnemonic: / is used to delimit line boundaries when quoting poetry.) 
# 
#     undef $/;
#     $_ = <FH>;          # whole file now here
#     s/\n[ \t]+/ /g;
# 
# Remember: the value of $/ is a string, not a regexp. AWK has to be better for something :-) 
# 
# Setting $/ to a reference to an integer, scalar containing an integer, 
# or scalar that's convertable to an integer will attempt to read records 
# instead of lines, with the maximum record size being the referenced integer. 
# So this: 
#  
#     $/ = \32768; # or \"32768", or \$var_containing_32768
#     open(FILE, $myfile);
#     $_ = <FILE>;
# 
# will read a record of no more than 32768 bytes from FILE. If you're not reading 
# from a record-oriented file (or your OS doesn't have record-oriented files), 
# then you'll likely get a full chunk of data with every read. If a record is 
# larger than the record size you've set, you'll get the record back in pieces. 
# 
# On VMS, record reads are done with the equivalent of sysread, so it's best not 
# to mix record and non-record reads on the same file. (This is likely not a 
# problem, as any file you'd want to read in record mode is proably usable in 
# line mode) Non-VMS systems perform normal I/O, so it's safe to mix record 
# and non-record reads of a file. 
#
our ($INPUT_RECORD_SEPARATOR,$RS,"$/");

# If set to nonzero, forces a flush right away and after every write or 
# print on the currently selected output channel. 
# Default is 0 (regardless of whether the channel is actually buffered by the 
# system or not; $| tells you only whether you've asked Perl explicitly to 
# flush after each write). Note that STDOUT will typically be line buffered if 
# output is to the terminal and block buffered otherwise. 
# Setting this variable is useful primarily when you are outputting to a pipe, 
# such as when you are running a Perl script under rsh and want to see the 
# output as it's happening. This has no effect on input buffering. 
# 
# (Mnemonic: when you want your pipes to be piping hot.) 
# 
our ($OUTPUT_AUTOFLUSH,"$|");

# The output field separator for the print operator. Ordinarily the print operator
# simply prints out the comma-separated fields you specify. To get behavior more
# like awk, set this variable as you would set awk's OFS variable to specify what 
# is printed between fields. 
# 
# (Mnemonic: what is printed when there is a , in your print statement.) 
# 
our ($OUTPUT_FIELD_SEPARATOR,$OFS,"$,");

# The output record separator for the print operator. Ordinarily the print
# operator simply prints out the comma-separated fields you specify, 
# with no trailing newline or record separator assumed. 
# To get behavior more like awk, set this variable as you would set awk's ORS
# variable to specify what is printed at the end of the print. 
# 
# (Mnemonic: you set ``$\'' instead of adding \n at the end of the print. 
# Also, it's just like $/, but it's what you get ``back'' from Perl.) 
# 
our ($OUTPUT_RECORD_SEPARATOR,$ORS,"$\\");

# This is like ``$,'' except that it applies to array values interpolated 
# into a double-quoted string (or similar interpreted string). 
# Default is a space. 
# 
# (Mnemonic: obvious, I think.) 
# 
our ($LIST_SEPARATOR,"$\"");

# The subscript separator for multidimensional array emulation. 
# If you refer to a hash element as 
# 
#     $foo{$a,$b,$c}
# 
# it really means 
#  
#     $foo{join($;, $a, $b, $c)}
# 
# But don't put 
#  
#     @foo{$a,$b,$c}      # a slice--note the @
# 
# which means 
#  
#     ($foo{$a},$foo{$b},$foo{$c})
# 
# Default is ``\034'', the same as SUBSEP in awk. 
# Note that if your keys contain binary data there might not be any 
# safe value for ``$;''. (Mnemonic: comma (the syntactic subscript separator) 
# is a semi-semicolon. Yeah, I know, it's pretty lame, 
# but `` $,'' is already taken for something more important.) 
# 
# Consider using ``real'' multidimensional arrays. 
# 
our ($SUBSCRIPT_SEPARATOR,$SUBSEP,"$;");
 
# The output format for printed numbers. 
# This variable is a half-hearted attempt to emulate awk's OFMT variable. 
# There are times, however, when awk and Perl have differing notions of 
# what is in fact numeric. The initial value is %.ng, where n is the value 
# of the macro DBL_DIG from your system's float.h. This is different from 
# awk's default OFMT setting of %.6g, so you need to set ``$#'' explicitly 
# to get awk's value. 
# 
# (Mnemonic: # is the number sign.) 
# Use of ``$#'' is deprecated. 
# 
our ($OFMT,"$#");
 
# The current page number of the currently selected output channel. 
# 
# (Mnemonic: % is page number in nroff.) 
# 
our ($FORMAT_PAGE_NUMBER,"$%");

# The current page length (printable lines) of the currently selected 
# output channel. Default is 60. 
# 
# (Mnemonic: = has horizontal lines.) 
# 
our ($FORMAT_LINES_PER_PAGE,"$=");

# The number of lines left on the page of the currently selected 
# output channel. (Mnemonic: lines_on_page - lines_printed.) 
# 
our ($FORMAT_LINES_LEFT,"$-");

# The name of the current report format for the currently selected 
# output channel. Default is name of the filehandle. 
# 
# (Mnemonic: brother to ``$^''.) 
# 
our ($FORMAT_NAME,"$~");

# The name of the current top-of-page format for the currently 
# selected output channel. Default is name of the filehandle with _TOP 
# appended. 
# 
# (Mnemonic: points to top of page.)
# 
our ($FORMAT_TOP_NAME,"$^");
  
# The current set of characters after which a string may be broken to 
# fill continuation fields (starting with ^) in a format. 
# Default is " \n-", to break on whitespace or hyphens. 
# (Mnemonic: a ``colon'' in poetry is a part of a line.) 
# 
our ($FORMAT_LINE_BREAK_CHARACTERS,"$:");
 
# What formats output to perform a form feed. Default is \f. 
# 
our ($FORMAT_FORMFEED,"$^L");

# The current value of the write() accumulator for format() lines. 
# A format contains formline() commands that put their result into $^A. 
# After calling its format, write() prints out the contents of $^A and empties. 
# So you never actually see the contents of $^A unless you call formline() yourself
#  and then look at it. See the perlform manpage and formline(). 
# 
our ($ACCUMULATOR,"$^A");

# The status returned by the last pipe close, backtick (``) command, or system() 
# operator. Note that this is the status word returned by the wait() system call 
# (or else is made up to look like it). Thus, the exit value of the subprocess is 
# actually ( $? >> 8), and $? & 127 gives which signal, if any, the process died
# from, and $? & 128 reports whether there was a core dump. 
# 
# (Mnemonic: similar to sh and ksh.)
#  
# Additionally, if the h_errno variable is supported in C, its value is returned 
# via $? if any of the gethost*() functions fail. 
# 
# Note that if you have installed a signal handler for SIGCHLD, the value of $? 
# will usually be wrong outside that handler. 
# 
# Inside an END subroutine $? contains the value that is going to be given 
# to exit(). You can modify $? in an END subroutine to change the exit status of 
# the script. 
# 
# Under VMS, the pragma use vmsish 'status' makes $? reflect the actual VMS
# exit status, instead of the default emulation of POSIX status. 
# 
# Also see Error Indicators. 
# 
our ($CHILD_ERROR,"$?");
 
# If used in a numeric context, yields the current value of errno, with all 
# the usual caveats. (This means that you shouldn't depend on the value of $! 
# to be anything in particular unless you've gotten a specific error return 
# indicating a system error.) If used in a string context, yields the 
# corresponding system error string. You can assign to $! to set errno if, 
# for instance, you want "$!" to return the string for error n, or you want to 
# set the exit value for the die() operator. (Mnemonic: What just went bang?)
#  
# Also see Error Indicators. 
# 
our ($OS_ERROR,$ERRNO,"$!");

# Error information specific to the current operating system. 
# At the moment, this differs from $! under only VMS, OS/2, and Win32 
# (and for MacPerl). On all other platforms, $^E is always just the same as $!.
#  
# Under VMS, $^E provides the VMS status value from the last system error. 
# This is more specific information about the last system error than that provided 
# by $!. This is particularly important when $! is set to EVMSERR. 
# 
# Under OS/2, $^E is set to the error code of the last call to OS/2 API either 
# via CRT, or directly from perl. 
# 
# Under Win32, $^E always returns the last error information reported by the 
# Win32 call GetLastError() which describes the last error from within the Win32 API. 
# Most Win32-specific code will report errors via $^E. ANSI C and UNIX-like calls 
# set errno and so most portable Perl code will report errors via $!. 
# 
# Caveats mentioned in the description of $! generally apply to $^E, also. 
# 
# (Mnemonic: Extra error explanation.) 
# 
# Also see Error Indicators. 
# 
our ($EXTENDED_OS_ERROR,"$^E");
 
# The Perl syntax error message from the last eval() command. 
# If null, the last eval() parsed and executed correctly 
# (although the operations you invoked may have failed in the normal fashion). 
# 
# (Mnemonic: Where was the syntax error ``at''?)
#  
# Note that warning messages are not collected in this variable. 
# You can, however, set up a routine to process warnings by setting 
# $SIG{__WARN__} as described below. 
# 
# Also see Error Indicators. 
# 
our ($EVAL_ERROR,"$@");

# The process number of the Perl running this script. 
# (Mnemonic: same as shells.) 
# 
our ($PROCESS_ID,$PID,"$$");
 
# The real uid of this process. 
# (Mnemonic: it's the uid you came FROM, if you're running setuid.) 
# 
our ($REAL_USER_ID,$UID,"$<");

# The effective uid of this process. Example: 
# 
#     $< = $>;            # set real to effective uid
#     ($<,$>) = ($>,$<);  # swap real and effective uid
# 
# (Mnemonic: it's the uid you went TO, if you're running setuid.) 
# 
# Note: ``$<'' and ``$>'' can be swapped only on machines supporting setreuid(). 
# 
our ($EFFECTIVE_USER_ID,$EUID,"$>");

# The real gid of this process. If you are on a machine that supports membership 
# in multiple groups simultaneously, gives a space separated list of groups you 
# are in. The first number is the one returned by getgid(), and the subsequent 
# ones by getgroups(), one of which may be the same as the first number.
#  
# However, a value assigned to ``$('' must be a single number used to set the 
# real gid. So the value given by ``$('' should not be assigned back to ``$('' 
# without being forced numeric, such as by adding zero. 
# 
# (Mnemonic: parentheses are used to GROUP things. 
# The real gid is the group you LEFT, if you're running setgid.) 
# 
our ($REAL_GROUP_ID,$GID,"$(");

# The effective gid of this process. If you are on a machine that supports 
# membership in multiple groups simultaneously, gives a space separated list of 
# groups you are in. The first number is the one returned by getegid(), and the 
# subsequent ones by getgroups(), one of which may be the same as the first number.
#  
# Similarly, a value assigned to ``$)'' must also be a space-separated list of 
# numbers. The first number is used to set the effective gid, and the rest 
# (if any) are passed to setgroups(). To get the effect of an empty list for 
# setgroups(), just repeat the new effective gid; that is, to force an effective 
# gid of 5 and an effectively empty setgroups() list, 
# say <PRE> $) = &quot;5 5&quot; </PRE> . 
# 
# (Mnemonic: parentheses are used to GROUP things. 
# The effective gid is the group that's RIGHT for you, if you're running setgid.) 
# 
# Note: ``$<'', ``$>'', ``$('' and ``$)'' can be set only on machines that
# support the corresponding set[re][ug]id() routine. 
# ``$('' and ``$)'' can be swapped only on machines supporting setregid(). 
# 
our ($EFFECTIVE_GROUP_ID,$EGID,"$)");

# Contains the name of the file containing the Perl script being executed. 
# On some operating systems assigning to ``$0'' modifies the argument area that
# the ps(1) program sees. This is more useful as a way of indicating the current 
# program state than it is for hiding the program you're running. 
# 
# (Mnemonic: same as sh and ksh.) 
# 
our ($PROGRAM_NAME,"$0");
 
# The index of the first element in an array, and of the first character in a 
# substring. Default is 0, but you could set it to 1 to make Perl behave more 
# like awk (or Fortran) when subscripting and when evaluating the index() and 
# substr() functions. 
# 
# (Mnemonic: [ begins subscripts.)
#  
# As of Perl 5, assignment to ``$['' is treated as a compiler directive, 
# and cannot influence the behavior of any other file. Its use is discouraged. 
# 
our "$[";

# The version + patchlevel / 1000 of the Perl interpreter. 
# This variable can be used to determine whether the Perl interpreter 
# executing a script is in the right range of versions. 
# 
# (Mnemonic: Is this version of perl in the right bracket?) Example: 
# 
#     warn "No checksumming!\n" if $] < 3.019;
# 
# See also the documentation of use VERSION and require VERSION for a 
# convenient way to fail if the Perl interpreter is too old. 
# 
our ($PERL_VERSION,"$]");

# The current value of the debugging flags. 
# (Mnemonic: value of -D switch.) 
# 
our ($DEBUGGING,"$^D");

# The maximum system file descriptor, ordinarily 2. 
# System file descriptors are passed to exec()ed processes, 
# while higher file descriptors are not. Also, during an open(), 
# system file descriptors are preserved even if the open() fails. 
# 
# (Ordinary file descriptors are closed before the open() is attempted.) 
# Note that the close-on-exec status of a file descriptor will be decided 
# according to the value of $^F at the time of the open, not the time of the exec. 
# 
our ($SYSTEM_FD_MAX,"$^F");
 
# The current set of syntax checks enabled by use strict and other block scoped
# compiler hints. See the documentation of strict for more details. 
# 
our "$^H";

# The current value of the inplace-edit extension. 
# Use undef to disable inplace editing. 
# (Mnemonic: value of -i switch.) 
# 
our ($INPLACE_EDIT,"$^I");

# By default, running out of memory it is not trappable. 
# However, if compiled for this, Perl may use the contents of $^M as an 
# emergency pool after die()ing with this message. 
# 
# Suppose that your Perl were compiled with -DPERL_EMERGENCY_SBRK and 
# used Perl's malloc. Then 
# 
#     $^M = 'a' x (1<<16);
# 
# would allocate a 64K buffer for use when in emergency. 
# See the INSTALL file for information on how to enable this option. 
# As a disincentive to casual use of this advanced feature, 
# there is no the English manpage long name for this variable. 
# 
our "$^M";

# The name of the operating system under which this copy of Perl was built, 
# as determined during the configuration process. 
# The value is identical to $Config{'osname'}. 
# 
our ($OSNAME,"$^O");

# The internal variable for debugging support. 
# Different bits mean the following (subject to change):
#  
#  x01      Debug subroutine enter/exit. 
#  x02      Line-by-line debugging. 
#  x04      Switch off optimizations. 
#  x08      Preserve more data for future interactive inspections. 
#  x10      Keep info about source lines on which a subroutine is defined. 
#  x20      Start with single-step on.
#  
# Note that some bits may be relevent at compile-time only, some at run-time only. 
# This is a new mechanism and the details may change. 
# 
our ($PERLDB,"$^P");
 
# The result of evaluation of the last successful (?{ code }) regular expression 
# assertion. (Excluding those used as switches.) May be written to. 
# 
our "$^R";

# Current state of the interpreter. 
# Undefined if parsing of the current module/eval is not finished 
# (may happen in $SIG{__DIE__} and $SIG{__WARN__} handlers). 
# True if inside an eval, otherwise false. 
# 
our "$^S";
 
# The time at which the script began running, 
# in seconds since the epoch (beginning of 1970). 
# The values returned by the -M, -A, and -C filetests are based on this value. 
# 
our ($BASETIME,"$^T");

# The current value of the warning switch, either TRUE or FALSE. 
# (Mnemonic: related to the -w switch.) 
# 
our ($WARNING,"$^W");

# The name that the Perl binary itself was executed as, from C's argv[0]. 
# 
our ($EXECUTABLE_NAME,"$^X");

# contains the name of the current file when reading from <>. 
# 
our $ARGV;

# The array @ARGV contains the command line arguments intended for the script. 
# Note that $#ARGV is the generally number of arguments minus one, 
# because $ARGV[0] is the first argument, NOT the command name. 
# See ``$0'' for the command name.
#  
our @ARGV;
 
# The array @INC contains the list of places to look for Perl scripts to be 
# evaluated by the do EXPR, require, or use constructs. 
# It initially consists of the arguments to any -I command line switches, 
# followed by the default Perl library, probably /usr/local/lib/perl, 
# followed by ``.'', to represent the current directory. 
# 
# If you need to modify this at runtime, you should use the use lib pragma 
# to get the machine-dependent library properly loaded also: 
# 
#     use lib '/mypath/libdir/';
#     use SomeMod;
# 
our @INC;

# Within a subroutine the array @_ contains the parameters passed to 
# that subroutine. See the perlsub manpage. 
# 
our @_;

# The hash %INC contains entries for each filename that has been included 
# via do or require. The key is the filename you specified, and the value is 
# the location of the file actually found. The require command uses this array 
# to determine whether a given file has already been included. 
# 
our %INC;

# The hash %ENV contains your current environment. 
# Setting a value in ENV changes the environment for child processes. 
# 
our (%ENV,$ENV);

# The hash %SIG is used to set signal handlers for various signals. Example: 
# 
#     sub handler {       # 1st argument is signal name
#         my($sig) = @_;
#         print "Caught a SIG$sig--shutting down\n";
#         close(LOG);
#         exit(0);
#     }
# 
#     $SIG{'INT'}  = \&handler;
#     $SIG{'QUIT'} = \&handler;
#     ...
#     $SIG{'INT'} = 'DEFAULT';    # restore default action
#     $SIG{'QUIT'} = 'IGNORE';    # ignore SIGQUIT
# 
# The %SIG array contains values for only the signals actually set within the Perl script. Here are some other examples: 
# 
#     $SIG{"PIPE"} = Plumber;     # SCARY!!
#     $SIG{"PIPE"} = "Plumber";   # assumes main::Plumber (not recommended)
#     $SIG{"PIPE"} = \&Plumber;   # just fine; assume current Plumber
#     $SIG{"PIPE"} = Plumber();   # oops, what did Plumber() return??
# 
# The one marked scary is problematic because it's a bareword, which means 
# sometimes it's a string representing the function, and sometimes it's going to 
# call the subroutine call right then and there! Best to be sure and quote it or 
# take a reference to it. *Plumber works too. See the perlsub manpage. 
# 
# If your system has the sigaction() function then signal handlers are installed 
# using it. This means you get reliable signal handling. If your system has the 
# SA_RESTART flag it is used when signals handlers are installed. This means that 
# system calls for which it is supported continue rather than returning when a 
# signal arrives. If you want your system calls to be interrupted by signal 
# delivery then do something like this: 
# 
#     use POSIX ':signal_h';
# 
#     my $alarm = 0;
#     sigaction SIGALRM, new POSIX::SigAction sub { $alarm = 1 }
#         or die "Error setting SIGALRM handler: $!\n";
# 
# See the POSIX manpage. 
# 
# Certain internal hooks can be also set using the %SIG hash. 
# The routine indicated by $SIG{__WARN__} is called when a warning message is 
# about to be printed. The warning message is passed as the first argument. 
# The presence of a __WARN__ hook causes the ordinary printing of warnings to 
# STDERR to be suppressed. You can use this to save warnings in a variable, or 
# turn warnings into fatal errors, like this: 
# 
#     local $SIG{__WARN__} = sub { die $_[0] };
#     eval $proggie;
# 
# The routine indicated by $SIG{__DIE__} is called when a fatal exception is 
# about to be thrown. The error message is passed as the first argument. 
# When a __DIE__ hook routine returns, the exception processing continues as it 
# would have in the absence of the hook, unless the hook routine itself exits 
# via a goto, a loop exit, or a die(). The __DIE__ handler is explicitly disabled 
# during the call, so that you can die from a __DIE__ handler. Similarly for __WARN__. 
# 
# Note that the $SIG{__DIE__} hook is called even inside eval()ed blocks/strings. 
# See die and $^S for how to circumvent this. 
# 
# Note that __DIE__/__WARN__ handlers are very special in one respect: 
# they may be called to report (probable) errors found by the parser. 
# In such a case the parser may be in inconsistent state, so any attempt to 
# evaluate Perl code from such a handler will probably result in a segfault. 
# This means that calls which result/may-result in parsing Perl should be 
# used with extreme causion, like this: 
#  
#     require Carp if defined $^S;
#     Carp::confess("Something wrong") if defined &Carp::confess;
#     die "Something wrong, but could not load Carp to give backtrace...
#          To see backtrace try starting Perl with -MCarp switch";
# 
# Here the first line will load Carp unless it is the parser who called the 
# handler. The second line will print backtrace and die if Carp was available. 
# The third line will be executed only if Carp was not available. 
# 
# See die, warn and eval for additional info. 
# 
our (%SIG,$SIG);


# Returns the absolute value of its argument.
#
sub abs{#(VALUE) return mytypexx
}
# Accepts an incoming socket connect, just as the
# accept(2) system call does.  Returns the packed
# address if it succeeded, FALSE otherwise.  See
# example in the section on Sockets: Client/Server
# Communication in the perlipc manpage.
#
sub accept{#(NEWSOCKET,GENERICSOCKET)
}
# Arranges to have a SIGALRM delivered to this
# process after the specified number of seconds have
# elapsed.  (On some machines, unfortunately, the
# elapsed time may be up to one second less than you
# specified because of how seconds are counted.)
# Only one timer may be counting at once.  Each call
# disables the previous timer, and an argument of 0
# may be supplied to cancel the previous timer
# without starting a new one.  The returned value is
# the amount of time remaining on the previous
# timer.
#
# For delays of finer granularity than one second,
# you may use Perl's syscall() interface to access
# setitimer(2) if your system supports it, or else
# see the select() entry elsewhere in this
# documentbelow.  It is not advised to intermix
# alarm() and sleep() calls.
#
sub alarm{#(SECONDS)
}
# Returns the arctangent of Y/X in the range -pi to
# pi.
#
sub atan2{#(Y,X)
}
# Binds a network address to a socket, just as the
# bind system call does.  Returns TRUE if it
# succeeded, FALSE otherwise.  NAME should be a
# packed address of the appropriate type for the
# socket.  See the examples in the section on
# Sockets: Client/Server Communication in the
# perlipc manpage.
#
sub bind{#(SOCKET,NAME)
}
# Arranges for the file to be read or written in
# "binary" mode in operating systems that
# distinguish between binary and text files.  Files
# that are not in binary mode have CR LF sequences
# translated to LF on input and LF translated to CR
# LF on output.  Binmode has no effect under Unix;
# in DOS and similarly archaic systems, it may be
# imperative--otherwise your DOS-damaged C library
# may mangle your file.  The key distinction between
# systems that need binmode and those that don't is
# their text file formats.  Systems like Unix and
# Plan9 that delimit lines with a single character,
# and that encode that character in C as '\n', do
# not need binmode.  The rest need it.  If
# FILEHANDLE is an expression, the value is taken as
# the name of the filehandle.
#
sub binmode{#(FILEHANDLE)
}
# This function tells the referenced object (passed
# as REF) that it is now an object in the CLASSNAME
# package--or the current package if no CLASSNAME is
# specified, which is often the case.  It returns
# the reference for convenience, since a bless() is
# often the last thing in a constructor.  Always use
# the two-argument version if the function doing the
# blessing might be inherited by a derived class.
# See the perlobj manpage for more about the
# blessing (and blessings) of objects.
#
sub bless{#(REF)
}
# This function tells the referenced object (passed
# as REF) that it is now an object in the CLASSNAME
# package--or the current package if no CLASSNAME is
# specified, which is often the case.  It returns
# the reference for convenience, since a bless() is
# often the last thing in a constructor.  Always use
# the two-argument version if the function doing the
# blessing might be inherited by a derived class.
# See the perlobj manpage for more about the
# blessing (and blessings) of objects.
#
sub bless{#(REF,CLASSNAME)
}
# Returns the context of the current subroutine
# call.  In a scalar context, returns TRUE if there
# is a caller, that is, if we're in a subroutine or
# eval() or require(), and FALSE otherwise.  In a
# list context, returns
#
#     ($package, $filename, $line) = caller;
#
# With EXPR, it returns some extra information that
# the debugger uses to print a stack trace.  The
# value of EXPR indicates how many call frames to go
# back before the current one.
#
#     ($package, $filename, $line,
#      $subroutine, $hasargs, $wantargs) = caller($i);
#
# Furthermore, when called from within the DB
# package, caller returns more detailed information:
# it sets the list variable @DB::args to be the
# arguments with which that subroutine was invoked.
#
sub caller{#()
}
# Returns the context of the current subroutine
# call.  In a scalar context, returns TRUE if there
# is a caller, that is, if we're in a subroutine or
# eval() or require(), and FALSE otherwise.  In a
# list context, returns
#
#     ($package, $filename, $line) = caller;
#
# With EXPR, it returns some extra information that
# the debugger uses to print a stack trace.  The
# value of EXPR indicates how many call frames to go
# back before the current one.
#
#     ($package, $filename, $line,
#      $subroutine, $hasargs, $wantargs) = caller($i);
#
# Furthermore, when called from within the DB
# package, caller returns more detailed information:
# it sets the list variable @DB::args to be the
# arguments with which that subroutine was invoked.
#
sub caller{#(EXPR)
}
# Changes the working directory to EXPR, if
# possible.  If EXPR is omitted, changes to home
# directory.  Returns TRUE upon success, FALSE
# otherwise.  See example under die().
#
sub chdir{#(EXPR)
}
# Changes the permissions of a list of files.  The
# first element of the list must be the numerical
# mode, which should probably be an octal number.
# Returns the number of files successfully changed.
#
#     $cnt = chmod 0755, 'foo', 'bar';
#     chmod 0755, @executables;
#
#
sub chmod{#(LIST)
}
# This is a slightly safer version of chop (see
# below).  It removes any line ending that
# corresponds to the current value of $/ (also known
# as $INPUT_RECORD_SEPARATOR in the English module).
# It returns the number of characters removed.  It's
# often used to remove the newline from the end of
# an input record when you're worried that the final
# record may be missing its newline.  When in
# paragraph mode ($/ = ""), it removes all trailing
# newlines from the string.  If VARIABLE is omitted,
# it chomps $_.  Example:
#     while (<>) {
#         chomp;  # avoid \n on last field
#         @array = split(/:/);
#         ...
#     }
#
# You can actually chomp anything that's an lvalue,
# including an assignment:
#
#     chomp($cwd = `pwd`);
#     chomp($answer = <STDIN>);
#
# If you chomp a list, each element is chomped, and
# the total number of characters removed is
# returned.
#
sub chomp{#()
}
# This is a slightly safer version of chop (see
# below).  It removes any line ending that
# corresponds to the current value of $/ (also known
# as $INPUT_RECORD_SEPARATOR in the English module).
# It returns the number of characters removed.  It's
# often used to remove the newline from the end of
# an input record when you're worried that the final
# record may be missing its newline.  When in
# paragraph mode ($/ = ""), it removes all trailing
# newlines from the string.  If VARIABLE is omitted,
# it chomps $_.  Example:
#     while (<>) {
#         chomp;  # avoid \n on last field
#         @array = split(/:/);
#         ...
#     }
#
# You can actually chomp anything that's an lvalue,
# including an assignment:
#
#     chomp($cwd = `pwd`);
#     chomp($answer = <STDIN>);
#
# If you chomp a list, each element is chomped, and
# the total number of characters removed is
# returned.
#
sub chomp{#(VARIABLE)
}
# This is a slightly safer version of chop (see
# below).  It removes any line ending that
# corresponds to the current value of $/ (also known
# as $INPUT_RECORD_SEPARATOR in the English module).
# It returns the number of characters removed.  It's
# often used to remove the newline from the end of
# an input record when you're worried that the final
# record may be missing its newline.  When in
# paragraph mode ($/ = ""), it removes all trailing
# newlines from the string.  If VARIABLE is omitted,
# it chomps $_.  Example:
#     while (<>) {
#         chomp;  # avoid \n on last field
#         @array = split(/:/);
#         ...
#     }
#
# You can actually chomp anything that's an lvalue,
# including an assignment:
#
#     chomp($cwd = `pwd`);
#     chomp($answer = <STDIN>);
#
# If you chomp a list, each element is chomped, and
# the total number of characters removed is
# returned.
#
sub chomp{#(LIST)
}
# Chops off the last character of a string and
# returns the character chopped.  It's used
# primarily to remove the newline from the end of an
# input record, but is much more efficient than
# s/\n// because it neither scans nor copies the
# string.  If VARIABLE is omitted, chops $_.
# Example:
#
#     while (<>) {
#         chop;   # avoid \n on last field
#         @array = split(/:/);
#         ...
#     }
#
# You can actually chop anything that's an lvalue,
# including an assignment:
#
#     chop($cwd = `pwd`);
#     chop($answer = <STDIN>);
#
# If you chop a list, each element is chopped.  Only
# the value of the last chop is returned.
#
# Note that chop returns the last character.  To
# return all but the last character, use
# substr($string, 0, -1).
#
sub chop{#()
}
# Chops off the last character of a string and
# returns the character chopped.  It's used
# primarily to remove the newline from the end of an
# input record, but is much more efficient than
# s/\n// because it neither scans nor copies the
# string.  If VARIABLE is omitted, chops $_.
# Example:
#
#     while (<>) {
#         chop;   # avoid \n on last field
#         @array = split(/:/);
#         ...
#     }
#
# You can actually chop anything that's an lvalue,
# including an assignment:
#
#     chop($cwd = `pwd`);
#     chop($answer = <STDIN>);
#
# If you chop a list, each element is chopped.  Only
# the value of the last chop is returned.
#
# Note that chop returns the last character.  To
# return all but the last character, use
# substr($string, 0, -1).
#
sub chop{#(VARIABLE)
}
# Chops off the last character of a string and
# returns the character chopped.  It's used
# primarily to remove the newline from the end of an
# input record, but is much more efficient than
# s/\n// because it neither scans nor copies the
# string.  If VARIABLE is omitted, chops $_.
# Example:
#
#     while (<>) {
#         chop;   # avoid \n on last field
#         @array = split(/:/);
#         ...
#     }
#
# You can actually chop anything that's an lvalue,
# including an assignment:
#
#     chop($cwd = `pwd`);
#     chop($answer = <STDIN>);
#
# If you chop a list, each element is chopped.  Only
# the value of the last chop is returned.
#
# Note that chop returns the last character.  To
# return all but the last character, use
# substr($string, 0, -1).
#
sub chop{#(LIST)
}
# Changes the owner (and group) of a list of files.
# The first two elements of the list must be the
# NUMERICAL uid and gid, in that order.  Returns the
# number of files successfully changed.
#     $cnt = chown $uid, $gid, 'foo', 'bar';
#     chown $uid, $gid, @filenames;
#
# Here's an example that looks up non-numeric uids
# in the passwd file:
#
#     print "User: ";
#     chop($user = <STDIN>);
#     print "Files: "
#     chop($pattern = <STDIN>);
#
#     ($login,$pass,$uid,$gid) = getpwnam($user)
#         or die "$user not in passwd file";
#
#     @ary = <${pattern}>;        # expand filenames
#     chown $uid, $gid, @ary;
#
# On most systems, you are not allowed to change the
# ownership of the file unless you're the superuser,
# although you should be able to change the group to
# any of your secondary groups.  On insecure
# systems, these restrictions may be relaxed, but
# this is not a portable assumption.
#
sub chown{#(LIST)
}
# Returns the character represented by that NUMBER
# in the character set.  For example, chr(65) is "A"
# in ASCII.
#
sub chr{#(NUMBER)
}
# This function works as the system call by the same
# name: it makes the named directory the new root
# directory for all further pathnames that begin
# with a "/" by your process and all of its
# children.  (It doesn't change your current working
# directory is unaffected.)  For security reasons,
# this call is restricted to the superuser.  If
# FILENAME is omitted, does chroot to $_.
#
sub chroot{#(FILENAME)
}
# Closes the file or pipe associated with the file
# handle, returning TRUE only if stdio successfully
# flushes buffers and closes the system file
# descriptor.  You don't have to close FILEHANDLE if
# you are immediately going to do another open() on
# it, since open() will close it for you.  (See
# open().)  However, an explicit close on an input
# file resets the line counter ($.), while the
# implicit close done by open() does not.  Also,
# closing a pipe will wait for the process executing
# on the pipe to complete, in case you want to look
# at the output of the pipe afterwards.  Closing a
# pipe explicitly also puts the status value of the
# command into $?.  Example:
#     open(OUTPUT, '|sort >foo'); # pipe to sort
#     ...                         # print stuff to output
#     close OUTPUT;               # wait for sort to finish
#     open(INPUT, 'foo');         # get sort's results
#
# FILEHANDLE may be an expression whose value gives
# the real filehandle name.
#
sub close{#(FILEHANDLE)
}
# Closes a directory opened by opendir().
#
sub closedir{#(DIRHANDLE)
}
# Attempts to connect to a remote socket, just as
# the connect system call does.  Returns TRUE if it
# succeeded, FALSE otherwise.  NAME should be a
# packed address of the appropriate type for the
# socket.  See the examples in the section on
# Sockets: Client/Server Communication in the
# perlipc manpage.
#
sub connect{#(SOCKET,NAME)
}
# Actually a flow control statement rather than a
# function.  If there is a continue BLOCK attached
# to a BLOCK (typically in a while or foreach), it
# is always executed just before the conditional is
# about to be evaluated again, just like the third
# part of a for loop in C.  Thus it can be used to
# increment a loop variable, even when the loop has
# been continued via the next statement (which is
# similar to the C continue statement).
#
sub continue{#(BLOCK)
}
# Returns the cosine of EXPR (expressed in radians).
# If EXPR is omitted takes cosine of $_.
#
sub cos{#(EXPR)
}
# Encrypts a string exactly like the crypt(3)
# function in the C library (assuming that you
# actually have a version there that has not been
# extirpated as a potential munition).  This can
# prove useful for checking the password file for
# lousy passwords, amongst other things.  Only the
# guys wearing white hats should do this.
#
# Here's an example that makes sure that whoever
# runs this program knows their own password:
#
#     $pwd = (getpwuid($<))[1];
#     $salt = substr($pwd, 0, 2);
#     system "stty -echo";
#     print "Password: ";
#     chop($word = <STDIN>);
#     print "\n";
#     system "stty echo";
#
#     if (crypt($word, $salt) ne $pwd) {
#         die "Sorry...\n";
#     } else {
#         print "ok\n";
#     }
#
# Of course, typing in your own password to whoever
# asks you for it is unwise.
#
sub crypt{#(PLAINTEXT,SALT)
}
# [This function has been superseded by the untie()
# function.]
#
# Breaks the binding between a DBM file and an
# associative array.
#
sub dbmclose{#(ASSOC_ARRAY)
}
# [This function has been superseded by the tie()
# function.]
#
# This binds a dbm(3), ndbm(3), sdbm(3), gdbm(), or
# Berkeley DB file to an associative array.  ASSOC
# is the name of the associative array.  (Unlike
# normal open, the first argument is NOT a
# filehandle, even though it looks like one).
# DBNAME is the name of the database (without the
# .dir or .pag extension if any).  If the database
# does not exist, it is created with protection
# specified by MODE (as modified by the umask()).
# If your system only supports the older DBM
# functions, you may perform only one dbmopen() in
# your program.  In older versions of Perl, if your
# system had neither DBM nor ndbm, calling dbmopen()
# produced a fatal error; it now falls back to
# sdbm(3).
#
# If you don't have write access to the DBM file,
# you can only read associative array variables, not
# set them.  If you want to test whether you can
# write, either use file tests or try setting a
# dummy array entry inside an eval(), which will
# trap the error.
#
# Note that functions such as keys() and values()
# may return huge array values when used on large
# DBM files.  You may prefer to use the each()
# function to iterate over large DBM files.
# Example:
#     # print out history file offsets
#     dbmopen(%HIST,'/usr/lib/news/history',0666);
#     while (($key,$val) = each %HIST) {
#         print $key, ' = ', unpack('L',$val), "\n";
#     }
#     dbmclose(%HIST);
#
# See also the AnyDBM_File manpage for a more
# general description of the pros and cons of the
# various dbm apparoches, as well as the DB_File
# manpage for a particularly rich implementation.
#
sub dbmopen{#(ASSOC,DBNAME,MODE)
}
# Returns a boolean value saying whether EXPR has a
# real value or not.  Many operations return the
# undefined value under exceptional conditions, such
# as end of file, uninitialized variable, system
# error and such.  This function allows you to
# distinguish between an undefined null scalar and a
# defined null scalar with operations that might
# return a real null string, such as referencing
# elements of an array.  You may also check to see
# if arrays or subroutines exist.  Use of defined on
# predefined variables is not guaranteed to produce
# intuitive results.
#
# When used on a hash array element, it tells you
# whether the value is defined, not whether the key
# exists in the hash.  Use exists() for that.
#
# Examples:
#
#     print if defined $switch{'D'};
#     print "$val\n" while defined($val = pop(@ary));
#     die "Can't readlink $sym: $!"
#         unless defined($value = readlink $sym);
#     eval '@foo = ()' if defined(@foo);
#     die "No XYZ package defined" unless defined %_XYZ;
#     sub foo { defined &$bar ? &$bar(@_) : die "No bar"; }
#
# See also undef().
#
# Note: many folks tend to overuse defined(), and
# then are surprised to discover that the number 0
# and the null string are, in fact, defined
# concepts.  For example, if you say
#
#     "ab" =~ /a(.*)b/;
#
# the pattern match succeeds, and $1 is defined,
# despite the fact that it matched "nothing".  But
# it didn't really match nothing--rather, it matched
# something that happened to be 0 characters long.
# This is all very above-board and honest.  When a
# function returns an undefined value, it's an
# admission that it couldn't give you an honest
# answer.  So you should only use defined() when
# you're questioning the integrity of what you're
# trying to do.  At other times, a simple comparison
# to 0 or "" is what you want.
#
sub defined{#(EXPR)
}
# Deletes the specified value from its hash array.
# Returns the deleted value, or the undefined value
# if nothing was deleted.  Deleting from $ENV{}
# modifies the environment.  Deleting from an array
# tied to a DBM file deletes the entry from the DBM
# file.  (But deleting from a tie()d hash doesn't
# necessarily return anything.)
#
# The following deletes all the values of an
# associative array:
#
#     foreach $key (keys %ARRAY) {
#         delete $ARRAY{$key};
#     }
#
# (But it would be faster to use the undef()
# command.)  Note that the EXPR can be arbitrarily
# complicated as long as the final operation is a
# hash key lookup:
#
#     delete $ref->[$x][$y]{$key};
#
#
sub delete{#(EXPR)
}
# Outside of an eval(), prints the value of LIST to
# STDERR and exits with the current value of $!
# (errno).  If $! is 0, exits with the value of ($?
# >> 8) (backtick `command` status).  If ($? >> 8)
# is 0, exits with 255.  Inside an eval(), the error
# message is stuffed into $@, and the eval() is
# terminated with the undefined value; this makes
# die() the way to raise an exception.
#
# Equivalent examples:
#
#     die "Can't cd to spool: $!\n" unless chdir '/usr/spool/news';
#     chdir '/usr/spool/news' or die "Can't cd to spool: $!\n"
#
# If the value of EXPR does not end in a newline,
# the current script line number and input line
# number (if any) are also printed, and a newline is
# supplied.  Hint: sometimes appending ", stopped"
# to your message will cause it to make better sense
# when the string "at foo line 123" is appended.
# Suppose you are running script "canasta".
#     die "/etc/games is no good";
#     die "/etc/games is no good, stopped";
#
# produce, respectively
#
#     /etc/games is no good at canasta line 123.
#     /etc/games is no good, stopped at canasta line 123.
#
# See also exit() and warn().
#
sub die{#(LIST)
}
# This causes an immediate core dump.  Primarily
# this is so that you can use the undump program to
# turn your core dump into an executable binary
# after having initialized all your variables at the
# beginning of the program.  When the new binary is
# executed it will begin by executing a goto LABEL
# (with all the restrictions that goto suffers).
# Think of it as a goto with an intervening core
# dump and reincarnation.  If LABEL is omitted,
# restarts the program from the top.  WARNING: any
# files opened at the time of the dump will NOT be
# open any more when the program is reincarnated,
# with possible resulting confusion on the part of
# Perl.  See also -u option in the perlrun manpage.
#
# Example:
#
#     #!/usr/bin/perl
#     require 'getopt.pl';
#     require 'stat.pl';
#     %days = (
#         'Sun' => 1,
#         'Mon' => 2,
#         'Tue' => 3,
#         'Wed' => 4,
#         'Thu' => 5,
#         'Fri' => 6,
#         'Sat' => 7,
#     );
#
#     dump QUICKSTART if $ARGV[0] eq '-d';
#
#     QUICKSTART:
#     Getopt('f');
#
#
sub dump{#(LABEL)
}
# Returns a 2-element array consisting of the key
# and value for the next value of an associative
# array, so that you can iterate over it.  Entries
# are returned in an apparently random order.  When
# the array is entirely read, a null array is
# returned (which when assigned produces a FALSE (0)
# value).  The next call to each() after that will
# start iterating again.  The iterator can be reset
# only by reading all the elements from the array.
# You should not add elements to an array while
# you're iterating over it.  There is a single
# iterator for each associative array, shared by all
# each(), keys() and values() function calls in the
# program.  The following prints out your
# environment like the printenv(1) program, only in
# a different order:
#
#     while (($key,$value) = each %ENV) {
#         print "$key=$value\n";
#     }
#
# See also keys() and values().
sub each{#(ASSOC_ARRAY)
}
# Returns 1 if the next read on FILEHANDLE will
# return end of file, or if FILEHANDLE is not open.
# FILEHANDLE may be an expression whose value gives
# the real filehandle name.  (Note that this
# function actually reads a character and then
# ungetc()s it, so it is not very useful in an
# interactive context.)  Do not read from a terminal
# file (or call eof(FILEHANDLE) on it) after end-of-
# file is reached.  Filetypes such as terminals may
# lose the end-of-file condition if you do.
#
# An eof without an argument uses the last file read
# as argument.  Empty parentheses () may be used to
# indicate the pseudofile formed of the files listed
# on the command line, i.e.  eof() is reasonable to
# use inside a while (<>) loop to detect the end of
# only the last file.  Use eof(ARGV) or eof without
# the parentheses to test EACH file in a while (<>)
# loop.  Examples:
#
#     # reset line numbering on each input file
#     while (<>) {
#         print "$.\t$_";
#         close(ARGV) if (eof);   # Not eof().
#     }
#
#     # insert dashes just before last line of last file
#     while (<>) {
#         if (eof()) {
#             print "--------------\n";
#             close(ARGV);        # close or break; is needed if we
#                                 # are reading from the terminal
#         }
#         print;
#     }
#
# Practical hint: you almost never need to use eof
# in Perl, because the input operators return undef
# when they run out of data.
#
sub eof{#()
}
# Returns 1 if the next read on FILEHANDLE will
# return end of file, or if FILEHANDLE is not open.
# FILEHANDLE may be an expression whose value gives
# the real filehandle name.  (Note that this
# function actually reads a character and then
# ungetc()s it, so it is not very useful in an
# interactive context.)  Do not read from a terminal
# file (or call eof(FILEHANDLE) on it) after end-of-
# file is reached.  Filetypes such as terminals may
# lose the end-of-file condition if you do.
#
# An eof without an argument uses the last file read
# as argument.  Empty parentheses () may be used to
# indicate the pseudofile formed of the files listed
# on the command line, i.e.  eof() is reasonable to
# use inside a while (<>) loop to detect the end of
# only the last file.  Use eof(ARGV) or eof without
# the parentheses to test EACH file in a while (<>)
# loop.  Examples:
#
#     # reset line numbering on each input file
#     while (<>) {
#         print "$.\t$_";
#         close(ARGV) if (eof);   # Not eof().
#     }
#
#     # insert dashes just before last line of last file
#     while (<>) {
#         if (eof()) {
#             print "--------------\n";
#             close(ARGV);        # close or break; is needed if we
#                                 # are reading from the terminal
#         }
#         print;
#     }
#
# Practical hint: you almost never need to use eof
# in Perl, because the input operators return undef
# when they run out of data.
#
sub eof{#(FILEHANDLE)
}
# Returns 1 if the next read on FILEHANDLE will
# return end of file, or if FILEHANDLE is not open.
# FILEHANDLE may be an expression whose value gives
# the real filehandle name.  (Note that this
# function actually reads a character and then
# ungetc()s it, so it is not very useful in an
# interactive context.)  Do not read from a terminal
# file (or call eof(FILEHANDLE) on it) after end-of-
# file is reached.  Filetypes such as terminals may
# lose the end-of-file condition if you do.
#
# An eof without an argument uses the last file read
# as argument.  Empty parentheses () may be used to
# indicate the pseudofile formed of the files listed
# on the command line, i.e.  eof() is reasonable to
# use inside a while (<>) loop to detect the end of
# only the last file.  Use eof(ARGV) or eof without
# the parentheses to test EACH file in a while (<>)
# loop.  Examples:
#
#     # reset line numbering on each input file
#     while (<>) {
#         print "$.\t$_";
#         close(ARGV) if (eof);   # Not eof().
#     }
#
#     # insert dashes just before last line of last file
#     while (<>) {
#         if (eof()) {
#             print "--------------\n";
#             close(ARGV);        # close or break; is needed if we
#                                 # are reading from the terminal
#         }
#         print;
#     }
#
# Practical hint: you almost never need to use eof
# in Perl, because the input operators return undef
# when they run out of data.
#
sub eof{#()
}
# The exec() function executes a system command AND
# NEVER RETURNS.  Use the system() function if you
# want it to return.
#
# If there is more than one argument in LIST, or if
# LIST is an array with more than one value, calls
# execvp(3) with the arguments in LIST.  If there is
# only one scalar argument, the argument is checked
# for shell metacharacters.  If there are any, the
# entire argument is passed to /bin/sh -c for
# parsing.  If there are none, the argument is split
# into words and passed directly to execvp(), which
# is more efficient.  Note: exec() and system() do
# not flush your output buffer, so you may need to
# set $| to avoid lost output.  Examples:
#
#     exec '/bin/echo', 'Your arguments are: ', @ARGV;
#     exec "sort $outfile | uniq";
#
# If you don't really want to execute the first
# argument, but want to lie to the program you are
# executing about its own name, you can specify the
# program you actually want to run as an "indirect
# object" (without a comma) in front of the LIST.
# (This always forces interpretation of the LIST as
# a multi-valued list, even if there is only a
# single scalar in the list.)  Example:
#
#     $shell = '/bin/csh';
#     exec $shell '-sh';          # pretend it's a login shell
#
# or, more directly,
#
#     exec {'/bin/csh'} '-sh';    # pretend it's a login shell
#
#
sub exec{#(LIST)
}
# Returns TRUE if the specified hash key exists in
# its hash array, even if the corresponding value is
# undefined.
#
#     print "Exists\n" if exists $array{$key};
#     print "Defined\n" if defined $array{$key};
#     print "True\n" if $array{$key};
#
# A hash element can only be TRUE if it's defined,
# and defined if it exists, but the reverse doesn't
# necessarily hold true.
#
# Note that the EXPR can be arbitrarily complicated
# as long as the final operation is a hash key
# lookup:
#
#     if (exists $ref->[$x][$y]{$key}) { ... }
#
#
sub exists{#(EXPR)
}
# Evaluates EXPR and exits immediately with that
# value.  (Actually, it calls any defined END
# routines first, but the END routines may not abort
# the exit.  Likewise any object destructors that
# need to be called are called before exit.)
# Example:
#
#     $ans = <STDIN>;
#     exit 0 if $ans =~ /^[Xx]/;
#
# See also die().  If EXPR is omitted, exits with 0
# status.
#
sub exit{#(EXPR)
}
# Returns e (the natural logarithm base) to the
# power of EXPR.  If EXPR is omitted, gives exp($_).
#
sub exp{#(EXPR)
}
# Implements the fcntl(2) function.  You'll probably
# have to say
#
#     use Fcntl;
#
# first to get the correct function definitions.
# Argument processing and value return works just
# like ioctl() below.  Note that fcntl() will
# produce a fatal error if used on a machine that
# doesn't implement fcntl(2).  For example:
#
#     use Fcntl;
#     fcntl($filehandle, F_GETLK, $packed_return_buffer);
#
#
sub fcntl{#(FILEHANDLE,FUNCTION,SCALAR)
}
# Returns the file descriptor for a filehandle.
# This is useful for constructing bitmaps for
# select().  If FILEHANDLE is an expression, the
# value is taken as the name of the filehandle.
#
sub fileno{#(FILEHANDLE)
}
# Calls flock(2) on FILEHANDLE.  See the flock(2)
# manpage for definition of OPERATION.  Returns TRUE
# for success, FALSE on failure.  Will produce a
# fatal error if used on a machine that doesn't
# implement either flock(2) or fcntl(2). The
# fcntl(2) system call will be automatically used if
# flock(2) is missing from your system.  This makes
# flock() the portable file locking strategy,
# although it will only lock entire files, not
# records.  Note also that some versions of flock()
# cannot lock things over the network; you would
# need to use the more system-specific fcntl() for
# that.
#
# Here's a mailbox appender for BSD systems.
#
#     $LOCK_SH = 1;
#     $LOCK_EX = 2;
#     $LOCK_NB = 4;
#     $LOCK_UN = 8;
#
#     sub lock {
#         flock(MBOX,$LOCK_EX);
#         # and, in case someone appended
#         # while we were waiting...
#         seek(MBOX, 0, 2);
#     }
#
#     sub unlock {
#         flock(MBOX,$LOCK_UN);
#     }
#
#     open(MBOX, ">>/usr/spool/mail/$ENV{'USER'}")
#             or die "Can't open mailbox: $!";
#
#     lock();
#     print MBOX $msg,"\n\n";
#     unlock();
#
# See also the DB_File manpage for other flock()
# examples.
#
sub flock{#(FILEHANDLE,OPERATION)
}
# Does a fork(2) system call.  Returns the child pid
# to the parent process and 0 to the child process,
# or undef if the fork is unsuccessful.  Note:
# unflushed buffers remain unflushed in both
# processes, which means you may need to set $|
# ($AUTOFLUSH in English) or call the autoflush()
# FileHandle method to avoid duplicate output.
#
# If you fork() without ever waiting on your
# children, you will accumulate zombies:
#
#     $SIG{CHLD} = sub { wait };
#
# There's also the double-fork trick (error checking
# on fork() returns omitted);
#     unless ($pid = fork) {
#         unless (fork) {
#             exec "what you really wanna do";
#             die "no exec";
#             # ... or ...
#             ## (some_perl_code_here)
#             exit 0;
#         }
#         exit 0;
#     }
#     waitpid($pid,0);
#
# See also the perlipc manpage for more examples of
# forking and reaping moribund children.
#
sub fork{#()
}
# This is an internal function used by formats,
# though you may call it too.  It formats (see the
# perlform manpage) a list of values according to
# the contents of PICTURE, placing the output into
# the format output accumulator, $^A (or
# $ACCUMULATOR in English).  Eventually, when a
# write() is done, the contents of $^A are written
# to some filehandle, but you could also read $^A
# yourself and then set $^A back to "".  Note that a
# format typically does one formline() per line of
# form, but the formline() function itself doesn't
# care how many newlines are embedded in the
# PICTURE.  This means that the ~ and ~~ tokens will
# treat the entire PICTURE as a single line.  You
# may therefore need to use multiple formlines to
# implement a single record format, just like the
# format compiler.
#
# Be careful if you put double quotes around the
# picture, since an "@" character may be taken to
# mean the beginning of an array name.  formline()
# always returns TRUE.  See the perlform manpage for
# other examples.
#
sub formline{#(PICTURE, LIST)
}
# Returns the next character from the input file
# attached to FILEHANDLE, or a null string at end of
# file.  If FILEHANDLE is omitted, reads from STDIN.
# This is not particularly efficient.  It cannot be
# used to get unbuffered single-characters, however.
# For that, try something more like:
#
#     if ($BSD_STYLE) {
#         system "stty cbreak </dev/tty >/dev/tty 2>&1";
#     }
#     else {
#         system "stty", '-icanon', 'eol', "\001";
#     }
#
#     $key = getc(STDIN);
#
#     if ($BSD_STYLE) {
#         system "stty -cbreak </dev/tty >/dev/tty 2>&1";
#     }
#     else {
#         system "stty", 'icanon', 'eol', '^@'; # ascii null
#     }
#     print "\n";
#
# Determination of whether to whether $BSD_STYLE
# should be set is left as an exercise to the
# reader.
#
# See also the Term::ReadKey module from your
# nearest CPAN site; details on CPAN can be found on
# the CPAN entry in the perlmod manpage
#
sub getc{#()
}
# Returns the next character from the input file
# attached to FILEHANDLE, or a null string at end of
# file.  If FILEHANDLE is omitted, reads from STDIN.
# This is not particularly efficient.  It cannot be
# used to get unbuffered single-characters, however.
# For that, try something more like:
#
#     if ($BSD_STYLE) {
#         system "stty cbreak </dev/tty >/dev/tty 2>&1";
#     }
#     else {
#         system "stty", '-icanon', 'eol', "\001";
#     }
#
#     $key = getc(STDIN);
#
#     if ($BSD_STYLE) {
#         system "stty -cbreak </dev/tty >/dev/tty 2>&1";
#     }
#     else {
#         system "stty", 'icanon', 'eol', '^@'; # ascii null
#     }
#     print "\n";
#
# Determination of whether to whether $BSD_STYLE
# should be set is left as an exercise to the
# reader.
#
# See also the Term::ReadKey module from your
# nearest CPAN site; details on CPAN can be found on
# the CPAN entry in the perlmod manpage
#
sub getc{#(FILEHANDLE)
}
# Returns the current login from /etc/utmp, if any.
# If null, use getpwuid().
#
#     $login = getlogin || (getpwuid($<))[0] || "Kilroy";
#
# Do not consider getlogin() for authorentication:
# it is not as secure as getpwuid().
#
sub getlogin{#()
}
# Returns the packed sockaddr address of other end
# of the SOCKET connection.
#
#     use Socket;
#     $hersockaddr    = getpeername(SOCK);
#     ($port, $iaddr) = unpack_sockaddr_in($hersockaddr);
#     $herhostname    = gethostbyaddr($iaddr, AF_INET);
#     $herstraddr     = inet_ntoa($iaddr);
sub getpeername{#(SOCKET)
}
# Returns the current process group for the
# specified PID, 0 for the current process.  Will
# raise an exception if used on a machine that
# doesn't implement getpgrp(2).  If PID is omitted,
# returns process group of current process.
#
sub getpgrp{#(PID)
}
# Returns the process id of the parent process.
#
sub getppid{#()
}
# Returns the current priority for a process, a
# process group, or a user.  (See the getpriority(2)
# manpage.)  Will raise a fatal exception if used on
# a machine that doesn't implement getpriority(2).
#
sub getpriority{#(WHICH,WHO)
}
# These routines perform the same functions as their
# counterparts in the system library.  Within a list
# context, the return values from the various get
# routines are as follows:
#
#     ($name,$passwd,$uid,$gid,
#        $quota,$comment,$gcos,$dir,$shell) = getpw*
#     ($name,$passwd,$gid,$members) = getgr*
#     ($name,$aliases,$addrtype,$length,@addrs) = gethost*
#     ($name,$aliases,$addrtype,$net) = getnet*
#     ($name,$aliases,$proto) = getproto*
#     ($name,$aliases,$port,$proto) = getserv*
#
# (If the entry doesn't exist you get a null list.)
#
# Within a scalar context, you get the name, unless
# the function was a lookup by name, in which case
# you get the other thing, whatever it is.  (If the
# entry doesn't exist you get the undefined value.)
# For example:
#
#     $uid = getpwnam
#     $name = getpwuid
#     $name = getpwent
#     $gid = getgrnam
#     $name = getgrgid
#     $name = getgrent
#     etc.
#
# The $members value returned by getgr*() is a space
# separated list of the login names of the members
# of the group.
# For the gethost*() functions, if the h_errno
# variable is supported in C, it will be returned to
# you via $? if the function call fails.  The @addrs
# value returned by a successful call is a list of
# the raw addresses returned by the corresponding
# system library call.  In the Internet domain, each
# address is four bytes long and you can unpack it
# by saying something like:
#
#     ($a,$b,$c,$d) = unpack('C4',$addr[0]);
#
#
sub endservent{#()
}
# These routines perform the same functions as their
# counterparts in the system library.  Within a list
# context, the return values from the various get
# routines are as follows:
#
#     ($name,$passwd,$uid,$gid,
#        $quota,$comment,$gcos,$dir,$shell) = getpw*
#     ($name,$passwd,$gid,$members) = getgr*
#     ($name,$aliases,$addrtype,$length,@addrs) = gethost*
#     ($name,$aliases,$addrtype,$net) = getnet*
#     ($name,$aliases,$proto) = getproto*
#     ($name,$aliases,$port,$proto) = getserv*
#
# (If the entry doesn't exist you get a null list.)
#
# Within a scalar context, you get the name, unless
# the function was a lookup by name, in which case
# you get the other thing, whatever it is.  (If the
# entry doesn't exist you get the undefined value.)
# For example:
#
#     $uid = getpwnam
#     $name = getpwuid
#     $name = getpwent
#     $gid = getgrnam
#     $name = getgrgid
#     $name = getgrent
#     etc.
#
# The $members value returned by getgr*() is a space
# separated list of the login names of the members
# of the group.
# For the gethost*() functions, if the h_errno
# variable is supported in C, it will be returned to
# you via $? if the function call fails.  The @addrs
# value returned by a successful call is a list of
# the raw addresses returned by the corresponding
# system library call.  In the Internet domain, each
# address is four bytes long and you can unpack it
# by saying something like:
#
#     ($a,$b,$c,$d) = unpack('C4',$addr[0]);
#
#
sub getpwnam{#(NAME)
}
# These routines perform the same functions as their
# counterparts in the system library.  Within a list
# context, the return values from the various get
# routines are as follows:
#
#     ($name,$passwd,$uid,$gid,
#        $quota,$comment,$gcos,$dir,$shell) = getpw*
#     ($name,$passwd,$gid,$members) = getgr*
#     ($name,$aliases,$addrtype,$length,@addrs) = gethost*
#     ($name,$aliases,$addrtype,$net) = getnet*
#     ($name,$aliases,$proto) = getproto*
#     ($name,$aliases,$port,$proto) = getserv*
#
# (If the entry doesn't exist you get a null list.)
#
# Within a scalar context, you get the name, unless
# the function was a lookup by name, in which case
# you get the other thing, whatever it is.  (If the
# entry doesn't exist you get the undefined value.)
# For example:
#
#     $uid = getpwnam
#     $name = getpwuid
#     $name = getpwent
#     $gid = getgrnam
#     $name = getgrgid
#     $name = getgrent
#     etc.
#
# The $members value returned by getgr*() is a space
# separated list of the login names of the members
# of the group.
# For the gethost*() functions, if the h_errno
# variable is supported in C, it will be returned to
# you via $? if the function call fails.  The @addrs
# value returned by a successful call is a list of
# the raw addresses returned by the corresponding
# system library call.  In the Internet domain, each
# address is four bytes long and you can unpack it
# by saying something like:
#
#     ($a,$b,$c,$d) = unpack('C4',$addr[0]);
#
#
sub getgrnam{#(NAME)
}
# These routines perform the same functions as their
# counterparts in the system library.  Within a list
# context, the return values from the various get
# routines are as follows:
#
#     ($name,$passwd,$uid,$gid,
#        $quota,$comment,$gcos,$dir,$shell) = getpw*
#     ($name,$passwd,$gid,$members) = getgr*
#     ($name,$aliases,$addrtype,$length,@addrs) = gethost*
#     ($name,$aliases,$addrtype,$net) = getnet*
#     ($name,$aliases,$proto) = getproto*
#     ($name,$aliases,$port,$proto) = getserv*
#
# (If the entry doesn't exist you get a null list.)
#
# Within a scalar context, you get the name, unless
# the function was a lookup by name, in which case
# you get the other thing, whatever it is.  (If the
# entry doesn't exist you get the undefined value.)
# For example:
#
#     $uid = getpwnam
#     $name = getpwuid
#     $name = getpwent
#     $gid = getgrnam
#     $name = getgrgid
#     $name = getgrent
#     etc.
#
# The $members value returned by getgr*() is a space
# separated list of the login names of the members
# of the group.
# For the gethost*() functions, if the h_errno
# variable is supported in C, it will be returned to
# you via $? if the function call fails.  The @addrs
# value returned by a successful call is a list of
# the raw addresses returned by the corresponding
# system library call.  In the Internet domain, each
# address is four bytes long and you can unpack it
# by saying something like:
#
#     ($a,$b,$c,$d) = unpack('C4',$addr[0]);
#
#
sub gethostbyname{#(NAME)
}
# These routines perform the same functions as their
# counterparts in the system library.  Within a list
# context, the return values from the various get
# routines are as follows:
#
#     ($name,$passwd,$uid,$gid,
#        $quota,$comment,$gcos,$dir,$shell) = getpw*
#     ($name,$passwd,$gid,$members) = getgr*
#     ($name,$aliases,$addrtype,$length,@addrs) = gethost*
#     ($name,$aliases,$addrtype,$net) = getnet*
#     ($name,$aliases,$proto) = getproto*
#     ($name,$aliases,$port,$proto) = getserv*
#
# (If the entry doesn't exist you get a null list.)
#
# Within a scalar context, you get the name, unless
# the function was a lookup by name, in which case
# you get the other thing, whatever it is.  (If the
# entry doesn't exist you get the undefined value.)
# For example:
#
#     $uid = getpwnam
#     $name = getpwuid
#     $name = getpwent
#     $gid = getgrnam
#     $name = getgrgid
#     $name = getgrent
#     etc.
#
# The $members value returned by getgr*() is a space
# separated list of the login names of the members
# of the group.
# For the gethost*() functions, if the h_errno
# variable is supported in C, it will be returned to
# you via $? if the function call fails.  The @addrs
# value returned by a successful call is a list of
# the raw addresses returned by the corresponding
# system library call.  In the Internet domain, each
# address is four bytes long and you can unpack it
# by saying something like:
#
#     ($a,$b,$c,$d) = unpack('C4',$addr[0]);
#
#
sub getnetbyname{#(NAME)
}
# These routines perform the same functions as their
# counterparts in the system library.  Within a list
# context, the return values from the various get
# routines are as follows:
#
#     ($name,$passwd,$uid,$gid,
#        $quota,$comment,$gcos,$dir,$shell) = getpw*
#     ($name,$passwd,$gid,$members) = getgr*
#     ($name,$aliases,$addrtype,$length,@addrs) = gethost*
#     ($name,$aliases,$addrtype,$net) = getnet*
#     ($name,$aliases,$proto) = getproto*
#     ($name,$aliases,$port,$proto) = getserv*
#
# (If the entry doesn't exist you get a null list.)
#
# Within a scalar context, you get the name, unless
# the function was a lookup by name, in which case
# you get the other thing, whatever it is.  (If the
# entry doesn't exist you get the undefined value.)
# For example:
#
#     $uid = getpwnam
#     $name = getpwuid
#     $name = getpwent
#     $gid = getgrnam
#     $name = getgrgid
#     $name = getgrent
#     etc.
#
# The $members value returned by getgr*() is a space
# separated list of the login names of the members
# of the group.
# For the gethost*() functions, if the h_errno
# variable is supported in C, it will be returned to
# you via $? if the function call fails.  The @addrs
# value returned by a successful call is a list of
# the raw addresses returned by the corresponding
# system library call.  In the Internet domain, each
# address is four bytes long and you can unpack it
# by saying something like:
#
#     ($a,$b,$c,$d) = unpack('C4',$addr[0]);
#
#
sub getprotobyname{#(NAME)
}
# These routines perform the same functions as their
# counterparts in the system library.  Within a list
# context, the return values from the various get
# routines are as follows:
#
#     ($name,$passwd,$uid,$gid,
#        $quota,$comment,$gcos,$dir,$shell) = getpw*
#     ($name,$passwd,$gid,$members) = getgr*
#     ($name,$aliases,$addrtype,$length,@addrs) = gethost*
#     ($name,$aliases,$addrtype,$net) = getnet*
#     ($name,$aliases,$proto) = getproto*
#     ($name,$aliases,$port,$proto) = getserv*
#
# (If the entry doesn't exist you get a null list.)
#
# Within a scalar context, you get the name, unless
# the function was a lookup by name, in which case
# you get the other thing, whatever it is.  (If the
# entry doesn't exist you get the undefined value.)
# For example:
#
#     $uid = getpwnam
#     $name = getpwuid
#     $name = getpwent
#     $gid = getgrnam
#     $name = getgrgid
#     $name = getgrent
#     etc.
#
# The $members value returned by getgr*() is a space
# separated list of the login names of the members
# of the group.
# For the gethost*() functions, if the h_errno
# variable is supported in C, it will be returned to
# you via $? if the function call fails.  The @addrs
# value returned by a successful call is a list of
# the raw addresses returned by the corresponding
# system library call.  In the Internet domain, each
# address is four bytes long and you can unpack it
# by saying something like:
#
#     ($a,$b,$c,$d) = unpack('C4',$addr[0]);
#
#
sub getpwuid{#(UID)
}
# These routines perform the same functions as their
# counterparts in the system library.  Within a list
# context, the return values from the various get
# routines are as follows:
#
#     ($name,$passwd,$uid,$gid,
#        $quota,$comment,$gcos,$dir,$shell) = getpw*
#     ($name,$passwd,$gid,$members) = getgr*
#     ($name,$aliases,$addrtype,$length,@addrs) = gethost*
#     ($name,$aliases,$addrtype,$net) = getnet*
#     ($name,$aliases,$proto) = getproto*
#     ($name,$aliases,$port,$proto) = getserv*
#
# (If the entry doesn't exist you get a null list.)
#
# Within a scalar context, you get the name, unless
# the function was a lookup by name, in which case
# you get the other thing, whatever it is.  (If the
# entry doesn't exist you get the undefined value.)
# For example:
#
#     $uid = getpwnam
#     $name = getpwuid
#     $name = getpwent
#     $gid = getgrnam
#     $name = getgrgid
#     $name = getgrent
#     etc.
#
# The $members value returned by getgr*() is a space
# separated list of the login names of the members
# of the group.
# For the gethost*() functions, if the h_errno
# variable is supported in C, it will be returned to
# you via $? if the function call fails.  The @addrs
# value returned by a successful call is a list of
# the raw addresses returned by the corresponding
# system library call.  In the Internet domain, each
# address is four bytes long and you can unpack it
# by saying something like:
#
#     ($a,$b,$c,$d) = unpack('C4',$addr[0]);
#
#
sub getgrgid{#(GID)
}
# These routines perform the same functions as their
# counterparts in the system library.  Within a list
# context, the return values from the various get
# routines are as follows:
#
#     ($name,$passwd,$uid,$gid,
#        $quota,$comment,$gcos,$dir,$shell) = getpw*
#     ($name,$passwd,$gid,$members) = getgr*
#     ($name,$aliases,$addrtype,$length,@addrs) = gethost*
#     ($name,$aliases,$addrtype,$net) = getnet*
#     ($name,$aliases,$proto) = getproto*
#     ($name,$aliases,$port,$proto) = getserv*
#
# (If the entry doesn't exist you get a null list.)
#
# Within a scalar context, you get the name, unless
# the function was a lookup by name, in which case
# you get the other thing, whatever it is.  (If the
# entry doesn't exist you get the undefined value.)
# For example:
#
#     $uid = getpwnam
#     $name = getpwuid
#     $name = getpwent
#     $gid = getgrnam
#     $name = getgrgid
#     $name = getgrent
#     etc.
#
# The $members value returned by getgr*() is a space
# separated list of the login names of the members
# of the group.
# For the gethost*() functions, if the h_errno
# variable is supported in C, it will be returned to
# you via $? if the function call fails.  The @addrs
# value returned by a successful call is a list of
# the raw addresses returned by the corresponding
# system library call.  In the Internet domain, each
# address is four bytes long and you can unpack it
# by saying something like:
#
#     ($a,$b,$c,$d) = unpack('C4',$addr[0]);
#
#
sub getservbyname{#(NAME,PROTO)
}
# These routines perform the same functions as their
# counterparts in the system library.  Within a list
# context, the return values from the various get
# routines are as follows:
#
#     ($name,$passwd,$uid,$gid,
#        $quota,$comment,$gcos,$dir,$shell) = getpw*
#     ($name,$passwd,$gid,$members) = getgr*
#     ($name,$aliases,$addrtype,$length,@addrs) = gethost*
#     ($name,$aliases,$addrtype,$net) = getnet*
#     ($name,$aliases,$proto) = getproto*
#     ($name,$aliases,$port,$proto) = getserv*
#
# (If the entry doesn't exist you get a null list.)
#
# Within a scalar context, you get the name, unless
# the function was a lookup by name, in which case
# you get the other thing, whatever it is.  (If the
# entry doesn't exist you get the undefined value.)
# For example:
#
#     $uid = getpwnam
#     $name = getpwuid
#     $name = getpwent
#     $gid = getgrnam
#     $name = getgrgid
#     $name = getgrent
#     etc.
#
# The $members value returned by getgr*() is a space
# separated list of the login names of the members
# of the group.
# For the gethost*() functions, if the h_errno
# variable is supported in C, it will be returned to
# you via $? if the function call fails.  The @addrs
# value returned by a successful call is a list of
# the raw addresses returned by the corresponding
# system library call.  In the Internet domain, each
# address is four bytes long and you can unpack it
# by saying something like:
#
#     ($a,$b,$c,$d) = unpack('C4',$addr[0]);
#
#
sub gethostbyaddr{#(ADDR,ADDRTYPE)
}
# These routines perform the same functions as their
# counterparts in the system library.  Within a list
# context, the return values from the various get
# routines are as follows:
#
#     ($name,$passwd,$uid,$gid,
#        $quota,$comment,$gcos,$dir,$shell) = getpw*
#     ($name,$passwd,$gid,$members) = getgr*
#     ($name,$aliases,$addrtype,$length,@addrs) = gethost*
#     ($name,$aliases,$addrtype,$net) = getnet*
#     ($name,$aliases,$proto) = getproto*
#     ($name,$aliases,$port,$proto) = getserv*
#
# (If the entry doesn't exist you get a null list.)
#
# Within a scalar context, you get the name, unless
# the function was a lookup by name, in which case
# you get the other thing, whatever it is.  (If the
# entry doesn't exist you get the undefined value.)
# For example:
#
#     $uid = getpwnam
#     $name = getpwuid
#     $name = getpwent
#     $gid = getgrnam
#     $name = getgrgid
#     $name = getgrent
#     etc.
#
# The $members value returned by getgr*() is a space
# separated list of the login names of the members
# of the group.
# For the gethost*() functions, if the h_errno
# variable is supported in C, it will be returned to
# you via $? if the function call fails.  The @addrs
# value returned by a successful call is a list of
# the raw addresses returned by the corresponding
# system library call.  In the Internet domain, each
# address is four bytes long and you can unpack it
# by saying something like:
#
#     ($a,$b,$c,$d) = unpack('C4',$addr[0]);
#
#
sub getnetbyaddr{#(ADDR,ADDRTYPE)
}
# These routines perform the same functions as their
# counterparts in the system library.  Within a list
# context, the return values from the various get
# routines are as follows:
#
#     ($name,$passwd,$uid,$gid,
#        $quota,$comment,$gcos,$dir,$shell) = getpw*
#     ($name,$passwd,$gid,$members) = getgr*
#     ($name,$aliases,$addrtype,$length,@addrs) = gethost*
#     ($name,$aliases,$addrtype,$net) = getnet*
#     ($name,$aliases,$proto) = getproto*
#     ($name,$aliases,$port,$proto) = getserv*
#
# (If the entry doesn't exist you get a null list.)
#
# Within a scalar context, you get the name, unless
# the function was a lookup by name, in which case
# you get the other thing, whatever it is.  (If the
# entry doesn't exist you get the undefined value.)
# For example:
#
#     $uid = getpwnam
#     $name = getpwuid
#     $name = getpwent
#     $gid = getgrnam
#     $name = getgrgid
#     $name = getgrent
#     etc.
#
# The $members value returned by getgr*() is a space
# separated list of the login names of the members
# of the group.
# For the gethost*() functions, if the h_errno
# variable is supported in C, it will be returned to
# you via $? if the function call fails.  The @addrs
# value returned by a successful call is a list of
# the raw addresses returned by the corresponding
# system library call.  In the Internet domain, each
# address is four bytes long and you can unpack it
# by saying something like:
#
#     ($a,$b,$c,$d) = unpack('C4',$addr[0]);
#
#
sub getprotobynumber{#(NUMBER)
}
# These routines perform the same functions as their
# counterparts in the system library.  Within a list
# context, the return values from the various get
# routines are as follows:
#
#     ($name,$passwd,$uid,$gid,
#        $quota,$comment,$gcos,$dir,$shell) = getpw*
#     ($name,$passwd,$gid,$members) = getgr*
#     ($name,$aliases,$addrtype,$length,@addrs) = gethost*
#     ($name,$aliases,$addrtype,$net) = getnet*
#     ($name,$aliases,$proto) = getproto*
#     ($name,$aliases,$port,$proto) = getserv*
#
# (If the entry doesn't exist you get a null list.)
#
# Within a scalar context, you get the name, unless
# the function was a lookup by name, in which case
# you get the other thing, whatever it is.  (If the
# entry doesn't exist you get the undefined value.)
# For example:
#
#     $uid = getpwnam
#     $name = getpwuid
#     $name = getpwent
#     $gid = getgrnam
#     $name = getgrgid
#     $name = getgrent
#     etc.
#
# The $members value returned by getgr*() is a space
# separated list of the login names of the members
# of the group.
# For the gethost*() functions, if the h_errno
# variable is supported in C, it will be returned to
# you via $? if the function call fails.  The @addrs
# value returned by a successful call is a list of
# the raw addresses returned by the corresponding
# system library call.  In the Internet domain, each
# address is four bytes long and you can unpack it
# by saying something like:
#
#     ($a,$b,$c,$d) = unpack('C4',$addr[0]);
#
#
sub getservbyport{#(PORT,PROTO)
}
# These routines perform the same functions as their
# counterparts in the system library.  Within a list
# context, the return values from the various get
# routines are as follows:
#
#     ($name,$passwd,$uid,$gid,
#        $quota,$comment,$gcos,$dir,$shell) = getpw*
#     ($name,$passwd,$gid,$members) = getgr*
#     ($name,$aliases,$addrtype,$length,@addrs) = gethost*
#     ($name,$aliases,$addrtype,$net) = getnet*
#     ($name,$aliases,$proto) = getproto*
#     ($name,$aliases,$port,$proto) = getserv*
#
# (If the entry doesn't exist you get a null list.)
#
# Within a scalar context, you get the name, unless
# the function was a lookup by name, in which case
# you get the other thing, whatever it is.  (If the
# entry doesn't exist you get the undefined value.)
# For example:
#
#     $uid = getpwnam
#     $name = getpwuid
#     $name = getpwent
#     $gid = getgrnam
#     $name = getgrgid
#     $name = getgrent
#     etc.
#
# The $members value returned by getgr*() is a space
# separated list of the login names of the members
# of the group.
# For the gethost*() functions, if the h_errno
# variable is supported in C, it will be returned to
# you via $? if the function call fails.  The @addrs
# value returned by a successful call is a list of
# the raw addresses returned by the corresponding
# system library call.  In the Internet domain, each
# address is four bytes long and you can unpack it
# by saying something like:
#
#     ($a,$b,$c,$d) = unpack('C4',$addr[0]);
#
#
sub getpwent{#()
}
# These routines perform the same functions as their
# counterparts in the system library.  Within a list
# context, the return values from the various get
# routines are as follows:
#
#     ($name,$passwd,$uid,$gid,
#        $quota,$comment,$gcos,$dir,$shell) = getpw*
#     ($name,$passwd,$gid,$members) = getgr*
#     ($name,$aliases,$addrtype,$length,@addrs) = gethost*
#     ($name,$aliases,$addrtype,$net) = getnet*
#     ($name,$aliases,$proto) = getproto*
#     ($name,$aliases,$port,$proto) = getserv*
#
# (If the entry doesn't exist you get a null list.)
#
# Within a scalar context, you get the name, unless
# the function was a lookup by name, in which case
# you get the other thing, whatever it is.  (If the
# entry doesn't exist you get the undefined value.)
# For example:
#
#     $uid = getpwnam
#     $name = getpwuid
#     $name = getpwent
#     $gid = getgrnam
#     $name = getgrgid
#     $name = getgrent
#     etc.
#
# The $members value returned by getgr*() is a space
# separated list of the login names of the members
# of the group.
# For the gethost*() functions, if the h_errno
# variable is supported in C, it will be returned to
# you via $? if the function call fails.  The @addrs
# value returned by a successful call is a list of
# the raw addresses returned by the corresponding
# system library call.  In the Internet domain, each
# address is four bytes long and you can unpack it
# by saying something like:
#
#     ($a,$b,$c,$d) = unpack('C4',$addr[0]);
#
#
sub getgrent{#()
}
# These routines perform the same functions as their
# counterparts in the system library.  Within a list
# context, the return values from the various get
# routines are as follows:
#
#     ($name,$passwd,$uid,$gid,
#        $quota,$comment,$gcos,$dir,$shell) = getpw*
#     ($name,$passwd,$gid,$members) = getgr*
#     ($name,$aliases,$addrtype,$length,@addrs) = gethost*
#     ($name,$aliases,$addrtype,$net) = getnet*
#     ($name,$aliases,$proto) = getproto*
#     ($name,$aliases,$port,$proto) = getserv*
#
# (If the entry doesn't exist you get a null list.)
#
# Within a scalar context, you get the name, unless
# the function was a lookup by name, in which case
# you get the other thing, whatever it is.  (If the
# entry doesn't exist you get the undefined value.)
# For example:
#
#     $uid = getpwnam
#     $name = getpwuid
#     $name = getpwent
#     $gid = getgrnam
#     $name = getgrgid
#     $name = getgrent
#     etc.
#
# The $members value returned by getgr*() is a space
# separated list of the login names of the members
# of the group.
# For the gethost*() functions, if the h_errno
# variable is supported in C, it will be returned to
# you via $? if the function call fails.  The @addrs
# value returned by a successful call is a list of
# the raw addresses returned by the corresponding
# system library call.  In the Internet domain, each
# address is four bytes long and you can unpack it
# by saying something like:
#
#     ($a,$b,$c,$d) = unpack('C4',$addr[0]);
#
#
sub gethostent{#()
}
# These routines perform the same functions as their
# counterparts in the system library.  Within a list
# context, the return values from the various get
# routines are as follows:
#
#     ($name,$passwd,$uid,$gid,
#        $quota,$comment,$gcos,$dir,$shell) = getpw*
#     ($name,$passwd,$gid,$members) = getgr*
#     ($name,$aliases,$addrtype,$length,@addrs) = gethost*
#     ($name,$aliases,$addrtype,$net) = getnet*
#     ($name,$aliases,$proto) = getproto*
#     ($name,$aliases,$port,$proto) = getserv*
#
# (If the entry doesn't exist you get a null list.)
#
# Within a scalar context, you get the name, unless
# the function was a lookup by name, in which case
# you get the other thing, whatever it is.  (If the
# entry doesn't exist you get the undefined value.)
# For example:
#
#     $uid = getpwnam
#     $name = getpwuid
#     $name = getpwent
#     $gid = getgrnam
#     $name = getgrgid
#     $name = getgrent
#     etc.
#
# The $members value returned by getgr*() is a space
# separated list of the login names of the members
# of the group.
# For the gethost*() functions, if the h_errno
# variable is supported in C, it will be returned to
# you via $? if the function call fails.  The @addrs
# value returned by a successful call is a list of
# the raw addresses returned by the corresponding
# system library call.  In the Internet domain, each
# address is four bytes long and you can unpack it
# by saying something like:
#
#     ($a,$b,$c,$d) = unpack('C4',$addr[0]);
#
#
sub getnetent{#()
}
# These routines perform the same functions as their
# counterparts in the system library.  Within a list
# context, the return values from the various get
# routines are as follows:
#
#     ($name,$passwd,$uid,$gid,
#        $quota,$comment,$gcos,$dir,$shell) = getpw*
#     ($name,$passwd,$gid,$members) = getgr*
#     ($name,$aliases,$addrtype,$length,@addrs) = gethost*
#     ($name,$aliases,$addrtype,$net) = getnet*
#     ($name,$aliases,$proto) = getproto*
#     ($name,$aliases,$port,$proto) = getserv*
#
# (If the entry doesn't exist you get a null list.)
#
# Within a scalar context, you get the name, unless
# the function was a lookup by name, in which case
# you get the other thing, whatever it is.  (If the
# entry doesn't exist you get the undefined value.)
# For example:
#
#     $uid = getpwnam
#     $name = getpwuid
#     $name = getpwent
#     $gid = getgrnam
#     $name = getgrgid
#     $name = getgrent
#     etc.
#
# The $members value returned by getgr*() is a space
# separated list of the login names of the members
# of the group.
# For the gethost*() functions, if the h_errno
# variable is supported in C, it will be returned to
# you via $? if the function call fails.  The @addrs
# value returned by a successful call is a list of
# the raw addresses returned by the corresponding
# system library call.  In the Internet domain, each
# address is four bytes long and you can unpack it
# by saying something like:
#
#     ($a,$b,$c,$d) = unpack('C4',$addr[0]);
#
#
sub getprotoent{#()
}
# These routines perform the same functions as their
# counterparts in the system library.  Within a list
# context, the return values from the various get
# routines are as follows:
#
#     ($name,$passwd,$uid,$gid,
#        $quota,$comment,$gcos,$dir,$shell) = getpw*
#     ($name,$passwd,$gid,$members) = getgr*
#     ($name,$aliases,$addrtype,$length,@addrs) = gethost*
#     ($name,$aliases,$addrtype,$net) = getnet*
#     ($name,$aliases,$proto) = getproto*
#     ($name,$aliases,$port,$proto) = getserv*
#
# (If the entry doesn't exist you get a null list.)
#
# Within a scalar context, you get the name, unless
# the function was a lookup by name, in which case
# you get the other thing, whatever it is.  (If the
# entry doesn't exist you get the undefined value.)
# For example:
#
#     $uid = getpwnam
#     $name = getpwuid
#     $name = getpwent
#     $gid = getgrnam
#     $name = getgrgid
#     $name = getgrent
#     etc.
#
# The $members value returned by getgr*() is a space
# separated list of the login names of the members
# of the group.
# For the gethost*() functions, if the h_errno
# variable is supported in C, it will be returned to
# you via $? if the function call fails.  The @addrs
# value returned by a successful call is a list of
# the raw addresses returned by the corresponding
# system library call.  In the Internet domain, each
# address is four bytes long and you can unpack it
# by saying something like:
#
#     ($a,$b,$c,$d) = unpack('C4',$addr[0]);
#
#
sub getservent{#()
}
# These routines perform the same functions as their
# counterparts in the system library.  Within a list
# context, the return values from the various get
# routines are as follows:
#
#     ($name,$passwd,$uid,$gid,
#        $quota,$comment,$gcos,$dir,$shell) = getpw*
#     ($name,$passwd,$gid,$members) = getgr*
#     ($name,$aliases,$addrtype,$length,@addrs) = gethost*
#     ($name,$aliases,$addrtype,$net) = getnet*
#     ($name,$aliases,$proto) = getproto*
#     ($name,$aliases,$port,$proto) = getserv*
#
# (If the entry doesn't exist you get a null list.)
#
# Within a scalar context, you get the name, unless
# the function was a lookup by name, in which case
# you get the other thing, whatever it is.  (If the
# entry doesn't exist you get the undefined value.)
# For example:
#
#     $uid = getpwnam
#     $name = getpwuid
#     $name = getpwent
#     $gid = getgrnam
#     $name = getgrgid
#     $name = getgrent
#     etc.
#
# The $members value returned by getgr*() is a space
# separated list of the login names of the members
# of the group.
# For the gethost*() functions, if the h_errno
# variable is supported in C, it will be returned to
# you via $? if the function call fails.  The @addrs
# value returned by a successful call is a list of
# the raw addresses returned by the corresponding
# system library call.  In the Internet domain, each
# address is four bytes long and you can unpack it
# by saying something like:
#
#     ($a,$b,$c,$d) = unpack('C4',$addr[0]);
#
#
sub setpwent{#()
}
# These routines perform the same functions as their
# counterparts in the system library.  Within a list
# context, the return values from the various get
# routines are as follows:
#
#     ($name,$passwd,$uid,$gid,
#        $quota,$comment,$gcos,$dir,$shell) = getpw*
#     ($name,$passwd,$gid,$members) = getgr*
#     ($name,$aliases,$addrtype,$length,@addrs) = gethost*
#     ($name,$aliases,$addrtype,$net) = getnet*
#     ($name,$aliases,$proto) = getproto*
#     ($name,$aliases,$port,$proto) = getserv*
#
# (If the entry doesn't exist you get a null list.)
#
# Within a scalar context, you get the name, unless
# the function was a lookup by name, in which case
# you get the other thing, whatever it is.  (If the
# entry doesn't exist you get the undefined value.)
# For example:
#
#     $uid = getpwnam
#     $name = getpwuid
#     $name = getpwent
#     $gid = getgrnam
#     $name = getgrgid
#     $name = getgrent
#     etc.
#
# The $members value returned by getgr*() is a space
# separated list of the login names of the members
# of the group.
# For the gethost*() functions, if the h_errno
# variable is supported in C, it will be returned to
# you via $? if the function call fails.  The @addrs
# value returned by a successful call is a list of
# the raw addresses returned by the corresponding
# system library call.  In the Internet domain, each
# address is four bytes long and you can unpack it
# by saying something like:
#
#     ($a,$b,$c,$d) = unpack('C4',$addr[0]);
#
#
sub setgrent{#()
}
# These routines perform the same functions as their
# counterparts in the system library.  Within a list
# context, the return values from the various get
# routines are as follows:
#
#     ($name,$passwd,$uid,$gid,
#        $quota,$comment,$gcos,$dir,$shell) = getpw*
#     ($name,$passwd,$gid,$members) = getgr*
#     ($name,$aliases,$addrtype,$length,@addrs) = gethost*
#     ($name,$aliases,$addrtype,$net) = getnet*
#     ($name,$aliases,$proto) = getproto*
#     ($name,$aliases,$port,$proto) = getserv*
#
# (If the entry doesn't exist you get a null list.)
#
# Within a scalar context, you get the name, unless
# the function was a lookup by name, in which case
# you get the other thing, whatever it is.  (If the
# entry doesn't exist you get the undefined value.)
# For example:
#
#     $uid = getpwnam
#     $name = getpwuid
#     $name = getpwent
#     $gid = getgrnam
#     $name = getgrgid
#     $name = getgrent
#     etc.
#
# The $members value returned by getgr*() is a space
# separated list of the login names of the members
# of the group.
# For the gethost*() functions, if the h_errno
# variable is supported in C, it will be returned to
# you via $? if the function call fails.  The @addrs
# value returned by a successful call is a list of
# the raw addresses returned by the corresponding
# system library call.  In the Internet domain, each
# address is four bytes long and you can unpack it
# by saying something like:
#
#     ($a,$b,$c,$d) = unpack('C4',$addr[0]);
#
#
sub sethostent{#(STAYOPEN)
}
# These routines perform the same functions as their
# counterparts in the system library.  Within a list
# context, the return values from the various get
# routines are as follows:
#
#     ($name,$passwd,$uid,$gid,
#        $quota,$comment,$gcos,$dir,$shell) = getpw*
#     ($name,$passwd,$gid,$members) = getgr*
#     ($name,$aliases,$addrtype,$length,@addrs) = gethost*
#     ($name,$aliases,$addrtype,$net) = getnet*
#     ($name,$aliases,$proto) = getproto*
#     ($name,$aliases,$port,$proto) = getserv*
#
# (If the entry doesn't exist you get a null list.)
#
# Within a scalar context, you get the name, unless
# the function was a lookup by name, in which case
# you get the other thing, whatever it is.  (If the
# entry doesn't exist you get the undefined value.)
# For example:
#
#     $uid = getpwnam
#     $name = getpwuid
#     $name = getpwent
#     $gid = getgrnam
#     $name = getgrgid
#     $name = getgrent
#     etc.
#
# The $members value returned by getgr*() is a space
# separated list of the login names of the members
# of the group.
# For the gethost*() functions, if the h_errno
# variable is supported in C, it will be returned to
# you via $? if the function call fails.  The @addrs
# value returned by a successful call is a list of
# the raw addresses returned by the corresponding
# system library call.  In the Internet domain, each
# address is four bytes long and you can unpack it
# by saying something like:
#
#     ($a,$b,$c,$d) = unpack('C4',$addr[0]);
#
#
sub setnetent{#(STAYOPEN)
}
# These routines perform the same functions as their
# counterparts in the system library.  Within a list
# context, the return values from the various get
# routines are as follows:
#
#     ($name,$passwd,$uid,$gid,
#        $quota,$comment,$gcos,$dir,$shell) = getpw*
#     ($name,$passwd,$gid,$members) = getgr*
#     ($name,$aliases,$addrtype,$length,@addrs) = gethost*
#     ($name,$aliases,$addrtype,$net) = getnet*
#     ($name,$aliases,$proto) = getproto*
#     ($name,$aliases,$port,$proto) = getserv*
#
# (If the entry doesn't exist you get a null list.)
#
# Within a scalar context, you get the name, unless
# the function was a lookup by name, in which case
# you get the other thing, whatever it is.  (If the
# entry doesn't exist you get the undefined value.)
# For example:
#
#     $uid = getpwnam
#     $name = getpwuid
#     $name = getpwent
#     $gid = getgrnam
#     $name = getgrgid
#     $name = getgrent
#     etc.
#
# The $members value returned by getgr*() is a space
# separated list of the login names of the members
# of the group.
# For the gethost*() functions, if the h_errno
# variable is supported in C, it will be returned to
# you via $? if the function call fails.  The @addrs
# value returned by a successful call is a list of
# the raw addresses returned by the corresponding
# system library call.  In the Internet domain, each
# address is four bytes long and you can unpack it
# by saying something like:
#
#     ($a,$b,$c,$d) = unpack('C4',$addr[0]);
#
#
sub setprotoent{#(STAYOPEN)
}
# These routines perform the same functions as their
# counterparts in the system library.  Within a list
# context, the return values from the various get
# routines are as follows:
#
#     ($name,$passwd,$uid,$gid,
#        $quota,$comment,$gcos,$dir,$shell) = getpw*
#     ($name,$passwd,$gid,$members) = getgr*
#     ($name,$aliases,$addrtype,$length,@addrs) = gethost*
#     ($name,$aliases,$addrtype,$net) = getnet*
#     ($name,$aliases,$proto) = getproto*
#     ($name,$aliases,$port,$proto) = getserv*
#
# (If the entry doesn't exist you get a null list.)
#
# Within a scalar context, you get the name, unless
# the function was a lookup by name, in which case
# you get the other thing, whatever it is.  (If the
# entry doesn't exist you get the undefined value.)
# For example:
#
#     $uid = getpwnam
#     $name = getpwuid
#     $name = getpwent
#     $gid = getgrnam
#     $name = getgrgid
#     $name = getgrent
#     etc.
#
# The $members value returned by getgr*() is a space
# separated list of the login names of the members
# of the group.
# For the gethost*() functions, if the h_errno
# variable is supported in C, it will be returned to
# you via $? if the function call fails.  The @addrs
# value returned by a successful call is a list of
# the raw addresses returned by the corresponding
# system library call.  In the Internet domain, each
# address is four bytes long and you can unpack it
# by saying something like:
#
#     ($a,$b,$c,$d) = unpack('C4',$addr[0]);
#
#
sub setservent{#(STAYOPEN)
}
# These routines perform the same functions as their
# counterparts in the system library.  Within a list
# context, the return values from the various get
# routines are as follows:
#
#     ($name,$passwd,$uid,$gid,
#        $quota,$comment,$gcos,$dir,$shell) = getpw*
#     ($name,$passwd,$gid,$members) = getgr*
#     ($name,$aliases,$addrtype,$length,@addrs) = gethost*
#     ($name,$aliases,$addrtype,$net) = getnet*
#     ($name,$aliases,$proto) = getproto*
#     ($name,$aliases,$port,$proto) = getserv*
#
# (If the entry doesn't exist you get a null list.)
#
# Within a scalar context, you get the name, unless
# the function was a lookup by name, in which case
# you get the other thing, whatever it is.  (If the
# entry doesn't exist you get the undefined value.)
# For example:
#
#     $uid = getpwnam
#     $name = getpwuid
#     $name = getpwent
#     $gid = getgrnam
#     $name = getgrgid
#     $name = getgrent
#     etc.
#
# The $members value returned by getgr*() is a space
# separated list of the login names of the members
# of the group.
# For the gethost*() functions, if the h_errno
# variable is supported in C, it will be returned to
# you via $? if the function call fails.  The @addrs
# value returned by a successful call is a list of
# the raw addresses returned by the corresponding
# system library call.  In the Internet domain, each
# address is four bytes long and you can unpack it
# by saying something like:
#
#     ($a,$b,$c,$d) = unpack('C4',$addr[0]);
#
#
sub endpwent{#()
}
# These routines perform the same functions as their
# counterparts in the system library.  Within a list
# context, the return values from the various get
# routines are as follows:
#
#     ($name,$passwd,$uid,$gid,
#        $quota,$comment,$gcos,$dir,$shell) = getpw*
#     ($name,$passwd,$gid,$members) = getgr*
#     ($name,$aliases,$addrtype,$length,@addrs) = gethost*
#     ($name,$aliases,$addrtype,$net) = getnet*
#     ($name,$aliases,$proto) = getproto*
#     ($name,$aliases,$port,$proto) = getserv*
#
# (If the entry doesn't exist you get a null list.)
#
# Within a scalar context, you get the name, unless
# the function was a lookup by name, in which case
# you get the other thing, whatever it is.  (If the
# entry doesn't exist you get the undefined value.)
# For example:
#
#     $uid = getpwnam
#     $name = getpwuid
#     $name = getpwent
#     $gid = getgrnam
#     $name = getgrgid
#     $name = getgrent
#     etc.
#
# The $members value returned by getgr*() is a space
# separated list of the login names of the members
# of the group.
# For the gethost*() functions, if the h_errno
# variable is supported in C, it will be returned to
# you via $? if the function call fails.  The @addrs
# value returned by a successful call is a list of
# the raw addresses returned by the corresponding
# system library call.  In the Internet domain, each
# address is four bytes long and you can unpack it
# by saying something like:
#
#     ($a,$b,$c,$d) = unpack('C4',$addr[0]);
#
#
sub endgrent{#()
}
# These routines perform the same functions as their
# counterparts in the system library.  Within a list
# context, the return values from the various get
# routines are as follows:
#
#     ($name,$passwd,$uid,$gid,
#        $quota,$comment,$gcos,$dir,$shell) = getpw*
#     ($name,$passwd,$gid,$members) = getgr*
#     ($name,$aliases,$addrtype,$length,@addrs) = gethost*
#     ($name,$aliases,$addrtype,$net) = getnet*
#     ($name,$aliases,$proto) = getproto*
#     ($name,$aliases,$port,$proto) = getserv*
#
# (If the entry doesn't exist you get a null list.)
#
# Within a scalar context, you get the name, unless
# the function was a lookup by name, in which case
# you get the other thing, whatever it is.  (If the
# entry doesn't exist you get the undefined value.)
# For example:
#
#     $uid = getpwnam
#     $name = getpwuid
#     $name = getpwent
#     $gid = getgrnam
#     $name = getgrgid
#     $name = getgrent
#     etc.
#
# The $members value returned by getgr*() is a space
# separated list of the login names of the members
# of the group.
# For the gethost*() functions, if the h_errno
# variable is supported in C, it will be returned to
# you via $? if the function call fails.  The @addrs
# value returned by a successful call is a list of
# the raw addresses returned by the corresponding
# system library call.  In the Internet domain, each
# address is four bytes long and you can unpack it
# by saying something like:
#
#     ($a,$b,$c,$d) = unpack('C4',$addr[0]);
#
#
sub endhostent{#()
}
# These routines perform the same functions as their
# counterparts in the system library.  Within a list
# context, the return values from the various get
# routines are as follows:
#
#     ($name,$passwd,$uid,$gid,
#        $quota,$comment,$gcos,$dir,$shell) = getpw*
#     ($name,$passwd,$gid,$members) = getgr*
#     ($name,$aliases,$addrtype,$length,@addrs) = gethost*
#     ($name,$aliases,$addrtype,$net) = getnet*
#     ($name,$aliases,$proto) = getproto*
#     ($name,$aliases,$port,$proto) = getserv*
#
# (If the entry doesn't exist you get a null list.)
#
# Within a scalar context, you get the name, unless
# the function was a lookup by name, in which case
# you get the other thing, whatever it is.  (If the
# entry doesn't exist you get the undefined value.)
# For example:
#
#     $uid = getpwnam
#     $name = getpwuid
#     $name = getpwent
#     $gid = getgrnam
#     $name = getgrgid
#     $name = getgrent
#     etc.
#
# The $members value returned by getgr*() is a space
# separated list of the login names of the members
# of the group.
# For the gethost*() functions, if the h_errno
# variable is supported in C, it will be returned to
# you via $? if the function call fails.  The @addrs
# value returned by a successful call is a list of
# the raw addresses returned by the corresponding
# system library call.  In the Internet domain, each
# address is four bytes long and you can unpack it
# by saying something like:
#
#     ($a,$b,$c,$d) = unpack('C4',$addr[0]);
#
#
sub endnetent{#()
}
# These routines perform the same functions as their
# counterparts in the system library.  Within a list
# context, the return values from the various get
# routines are as follows:
#
#     ($name,$passwd,$uid,$gid,
#        $quota,$comment,$gcos,$dir,$shell) = getpw*
#     ($name,$passwd,$gid,$members) = getgr*
#     ($name,$aliases,$addrtype,$length,@addrs) = gethost*
#     ($name,$aliases,$addrtype,$net) = getnet*
#     ($name,$aliases,$proto) = getproto*
#     ($name,$aliases,$port,$proto) = getserv*
#
# (If the entry doesn't exist you get a null list.)
#
# Within a scalar context, you get the name, unless
# the function was a lookup by name, in which case
# you get the other thing, whatever it is.  (If the
# entry doesn't exist you get the undefined value.)
# For example:
#
#     $uid = getpwnam
#     $name = getpwuid
#     $name = getpwent
#     $gid = getgrnam
#     $name = getgrgid
#     $name = getgrent
#     etc.
#
# The $members value returned by getgr*() is a space
# separated list of the login names of the members
# of the group.
# For the gethost*() functions, if the h_errno
# variable is supported in C, it will be returned to
# you via $? if the function call fails.  The @addrs
# value returned by a successful call is a list of
# the raw addresses returned by the corresponding
# system library call.  In the Internet domain, each
# address is four bytes long and you can unpack it
# by saying something like:
#
#     ($a,$b,$c,$d) = unpack('C4',$addr[0]);
#
#
sub endprotoent{#()
}
# Returns the packed sockaddr address of this end of
# the SOCKET connection.
#
#     use Socket;
#     $mysockaddr = getsockname(SOCK);
#     ($port, $myaddr) = unpack_sockaddr_in($mysockaddr);
#
#
sub getsockname{#(SOCKET)
}
# Returns the socket option requested, or undefined
# if there is an error.
#
sub getsockopt{#(SOCKET,LEVEL,OPTNAME)
}
# Returns the value of EXPR with filename expansions
# such as a shell would do.  This is the internal
# function implementing the <*.*> operator, except
# it's easier to use.
#
sub glob{#(EXPR)
}
# Converts a time as returned by the time function
# to a 9-element array with the time localized for
# the standard Greenwich timezone.  Typically used
# as follows:
#
#     ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
#                                             gmtime(time);
#
# All array elements are numeric, and come straight
# out of a struct tm.  In particular this means that
# $mon has the range 0..11 and $wday has the range
# 0..6.  If EXPR is omitted, does gmtime(time()).
#
sub gmtime{#(EXPR)
}
# The goto-LABEL form finds the statement labeled
# with LABEL and resumes execution there.  It may
# not be used to go into any construct that requires
# initialization, such as a subroutine or a foreach
# loop.  It also can't be used to go into a
# construct that is optimized away.  It can be used
# to go almost anywhere else within the dynamic
# scope, including out of subroutines, but it's
# usually better to use some other construct such as
# last or die.  The author of Perl has never felt
# the need to use this form of goto (in Perl, that
# is--C is another matter).
#
# The goto-EXPR form expects a label name, whose
# scope will be resolved dynamically.  This allows
# for computed gotos per FORTRAN, but isn't
# necessarily recommended if you're optimizing for
# maintainability:
#
#     goto ("FOO", "BAR", "GLARCH")[$i];
#
# The goto-&NAME form is highly magical, and
# substitutes a call to the named subroutine for the
# currently running subroutine.  This is used by
# AUTOLOAD subroutines that wish to load another
# subroutine and then pretend that the other
# subroutine had been called in the first place
# (except that any modifications to @_ in the
# current subroutine are propagated to the other
# subroutine.)  After the goto, not even caller()
# will be able to tell that this routine was called
# first.
#
sub goto{#(&NAME)
}
# The goto-LABEL form finds the statement labeled
# with LABEL and resumes execution there.  It may
# not be used to go into any construct that requires
# initialization, such as a subroutine or a foreach
# loop.  It also can't be used to go into a
# construct that is optimized away.  It can be used
# to go almost anywhere else within the dynamic
# scope, including out of subroutines, but it's
# usually better to use some other construct such as
# last or die.  The author of Perl has never felt
# the need to use this form of goto (in Perl, that
# is--C is another matter).
#
# The goto-EXPR form expects a label name, whose
# scope will be resolved dynamically.  This allows
# for computed gotos per FORTRAN, but isn't
# necessarily recommended if you're optimizing for
# maintainability:
#
#     goto ("FOO", "BAR", "GLARCH")[$i];
#
# The goto-&NAME form is highly magical, and
# substitutes a call to the named subroutine for the
# currently running subroutine.  This is used by
# AUTOLOAD subroutines that wish to load another
# subroutine and then pretend that the other
# subroutine had been called in the first place
# (except that any modifications to @_ in the
# current subroutine are propagated to the other
# subroutine.)  After the goto, not even caller()
# will be able to tell that this routine was called
# first.
#
sub goto{#(LABEL)
}
# The goto-LABEL form finds the statement labeled
# with LABEL and resumes execution there.  It may
# not be used to go into any construct that requires
# initialization, such as a subroutine or a foreach
# loop.  It also can't be used to go into a
# construct that is optimized away.  It can be used
# to go almost anywhere else within the dynamic
# scope, including out of subroutines, but it's
# usually better to use some other construct such as
# last or die.  The author of Perl has never felt
# the need to use this form of goto (in Perl, that
# is--C is another matter).
#
# The goto-EXPR form expects a label name, whose
# scope will be resolved dynamically.  This allows
# for computed gotos per FORTRAN, but isn't
# necessarily recommended if you're optimizing for
# maintainability:
#
#     goto ("FOO", "BAR", "GLARCH")[$i];
#
# The goto-&NAME form is highly magical, and
# substitutes a call to the named subroutine for the
# currently running subroutine.  This is used by
# AUTOLOAD subroutines that wish to load another
# subroutine and then pretend that the other
# subroutine had been called in the first place
# (except that any modifications to @_ in the
# current subroutine are propagated to the other
# subroutine.)  After the goto, not even caller()
# will be able to tell that this routine was called
# first.
#
sub goto{#(EXPR)
}
# Evaluates the BLOCK or EXPR for each element of
# LIST (locally setting $_ to each element) and
# returns the list value consisting of those
# elements for which the expression evaluated to
# TRUE.  In a scalar context, returns the number of
# times the expression was TRUE.
#
#     @foo = grep(!/^#/, @bar);    # weed out comments
#
# or equivalently,
#
#     @foo = grep {!/^#/} @bar;    # weed out comments
#
# Note that, since $_ is a reference into the list
# value, it can be used to modify the elements of
# the array.  While this is useful and supported, it
# can cause bizarre results if the LIST is not a
# named array.
#
sub grep{#(EXPR,LIST)
}
# Evaluates the BLOCK or EXPR for each element of
# LIST (locally setting $_ to each element) and
# returns the list value consisting of those
# elements for which the expression evaluated to
# TRUE.  In a scalar context, returns the number of
# times the expression was TRUE.
#
#     @foo = grep(!/^#/, @bar);    # weed out comments
#
# or equivalently,
#
#     @foo = grep {!/^#/} @bar;    # weed out comments
#
# Note that, since $_ is a reference into the list
# value, it can be used to modify the elements of
# the array.  While this is useful and supported, it
# can cause bizarre results if the LIST is not a
# named array.
#
sub grep{#(BLOCK LIST)
}
# Interprets EXPR as a hex string and returns the
# corresponding decimal value.  (To convert strings
# that might start with 0 or 0x see oct().)  If EXPR
# is omitted, uses $_.
#
sub hex{#(EXPR)
}
# There is no built-in import() function.  It is
# merely an ordinary method (subroutine) defined (or
# inherited) by modules that wish to export names to
# another module.  The use() function calls the
# import() method for the package used.  See also
# the use entry elsewhere in this documentthe
# perlmod manpage, and the Exporter manpage.
#
sub import{#()
}
# Returns the position of the first occurrence of
# SUBSTR in STR at or after POSITION.  If POSITION
# is omitted, starts searching from the beginning of
# the string.  The return value is based at 0 (or
# whatever you've set the $[ variable to--but don't
# do that).  If the substring is not found, returns
# one less than the base, ordinarily -1.
#
sub index{#(STR,SUBSTR)
}
# Returns the position of the first occurrence of
# SUBSTR in STR at or after POSITION.  If POSITION
# is omitted, starts searching from the beginning of
# the string.  The return value is based at 0 (or
# whatever you've set the $[ variable to--but don't
# do that).  If the substring is not found, returns
# one less than the base, ordinarily -1.
#
sub index{#(STR,SUBSTR,POSITION)
}
# Returns the integer portion of EXPR.  If EXPR is
# omitted, uses $_.
#
sub int{#(EXPR)
}
# Implements the ioctl(2) function.  You'll probably
# have to say
#
#     require "ioctl.ph"; # probably in /usr/local/lib/perl/ioctl.ph
#
# first to get the correct function definitions.  If
# ioctl.ph doesn't exist or doesn't have the correct
# definitions you'll have to roll your own, based on
# your C header files such as <sys/ioctl.h>.  (There
# is a Perl script called h2ph that comes with the
# Perl kit which may help you in this, but it's non-
# trivial.)  SCALAR will be read and/or written
# depending on the FUNCTION--a pointer to the string
# value of SCALAR will be passed as the third
# argument of the actual ioctl call.  (If SCALAR has
# no string value but does have a numeric value,
# that value will be passed rather than a pointer to
# the string value.  To guarantee this to be TRUE,
# add a 0 to the scalar before using it.)  The
# pack() and unpack() functions are useful for
# manipulating the values of structures used by
# ioctl().  The following example sets the erase
# character to DEL.
#     require 'ioctl.ph';
#     $getp = &TIOCGETP;
#     die "NO TIOCGETP" if $@ || !$getp;
#     $sgttyb_t = "ccccs";                # 4 chars and a short
#     if (ioctl(STDIN,$getp,$sgttyb)) {
#         @ary = unpack($sgttyb_t,$sgttyb);
#         $ary[2] = 127;
#         $sgttyb = pack($sgttyb_t,@ary);
#         ioctl(STDIN,&TIOCSETP,$sgttyb)
#             || die "Can't ioctl: $!";
#     }
#
# The return value of ioctl (and fcntl) is as
# follows:
#
#         if OS returns:          then Perl returns:
#             -1                    undefined value
#              0                  string "0 but true"
#         anything else               that number
#
# Thus Perl returns TRUE on success and FALSE on
# failure, yet you can still easily determine the
# actual value returned by the operating system:
#
#     ($retval = ioctl(...)) || ($retval = -1);
#     printf "System returned %d\n", $retval;
#
#
sub ioctl{#(FILEHANDLE,FUNCTION,SCALAR)
}
# Joins the separate strings of LIST or ARRAY into a
# single string with fields separated by the value
# of EXPR, and returns the string.  Example:
#
#     $_ = join(':', $login,$passwd,$uid,$gid,$gcos,$home,$shell);
#
# See the split entry in the perlfunc manpage.
#
sub join{#(EXPR,LIST)
}
# Returns a normal array consisting of all the keys
# of the named associative array.  (In a scalar
# context, returns the number of keys.)  The keys
# are returned in an apparently random order, but it
# is the same order as either the values() or each()
# function produces (given that the associative
# array has not been modified).  Here is yet another
# way to print your environment:
#
#     @keys = keys %ENV;
#     @values = values %ENV;
#     while ($#keys >= 0) {
#         print pop(@keys), '=', pop(@values), "\n";
#     }
#
# or how about sorted by key:
#     foreach $key (sort(keys %ENV)) {
#         print $key, '=', $ENV{$key}, "\n";
#     }
#
# To sort an array by value, you'll need to use a
# sort{} function.  Here's a descending numeric sort
# of a hash by its values:
#
#     foreach $key (sort { $hash{$b} <=> $hash{$a} } keys %hash)) {
#         printf "%4d %s\n", $hash{$key}, $key;
#     }
#
#
sub keys{#(ASSOC_ARRAY)
}
# Sends a signal to a list of processes.  The first
# element of the list must be the signal to send.
# Returns the number of processes successfully
# signaled.
#
#     $cnt = kill 1, $child1, $child2;
#     kill 9, @goners;
#
# Unlike in the shell, in Perl if the SIGNAL is
# negative, it kills process groups instead of
# processes.  (On System V, a negative PROCESS
# number will also kill process groups, but that's
# not portable.)  That means you usually want to use
# positive not negative signals.  You may also use a
# signal name in quotes.  See the the section on
# Signals in the perlipc manpage man page for
# details.
#
sub kill{#(LIST)
}
# The last command is like the break statement in C
# (as used in loops); it immediately exits the loop
# in question.  If the LABEL is omitted, the command
# refers to the innermost enclosing loop.  The
# continue block, if any, is not executed:
#
#     LINE: while (<STDIN>) {
#         last LINE if /^$/;      # exit when done with header
#         ...
#     }
#
#
sub last{#()
}
# The last command is like the break statement in C
# (as used in loops); it immediately exits the loop
# in question.  If the LABEL is omitted, the command
# refers to the innermost enclosing loop.  The
# continue block, if any, is not executed:
#
#     LINE: while (<STDIN>) {
#         last LINE if /^$/;      # exit when done with header
#         ...
#     }
#
#
sub last{#(LABEL)
}
# Returns an lowercased version of EXPR.  This is
# the internal function implementing the \L escape
# in double-quoted strings.  Should respect any
# POSIX setlocale() settings.
#
sub lc{#(EXPR )
}
# Returns the value of EXPR with the first character
# lowercased.  This is the internal function
# implementing the \l escape in double-quoted
# strings.  Should respect any POSIX setlocale()
# settings.
#
sub lcfirst{#(EXPR)
}
# Returns the length in characters of the value of
# EXPR.  If EXPR is omitted, returns length of $_.
#
sub length{#(EXPR)
}
# Creates a new filename linked to the old filename.
# Returns 1 for success, 0 otherwise.
#
sub link{#(OLDFILE,NEWFILE)
}
# Does the same thing that the listen system call
# does.  Returns TRUE if it succeeded, FALSE
# otherwise.  See example in the section on Sockets:
# Client/Server Communication in the perlipc
# manpage.
#
sub listen{#(SOCKET,QUEUESIZE)
}
# A local modifies the listed variables to be local
# to the enclosing block, subroutine, eval{} or do.
# If more than one value is listed, the list must be
# placed in parens.  See L<perlsub/"Temporary Values
# via local()"> for details.
#
# But you really probably want to be using my()
# instead, because local() isn't what most people
# think of as "local").  See L<perlsub/"Private
# Variables via my()"> for details.
#
sub local{#(EXPR)
}
# Converts a time as returned by the time function
# to a 9-element array with the time analyzed for
# the local timezone.  Typically used as follows:
#
#     ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
#                                                 localtime(time);
#
# All array elements are numeric, and come straight
# out of a struct tm.  In particular this means that
# $mon has the range 0..11 and $wday has the range
# 0..6.  If EXPR is omitted, does localtime(time).
#
# In a scalar context, prints out the ctime(3)
# value:
#
#     $now_string = localtime;  # e.g. "Thu Oct 13 04:54:34 1994"
#
# Also see the timelocal.pl library, and the
# strftime(3) function available via the POSIX
# modulie.
sub localtime{#(EXPR)
}
# Returns logarithm (base e) of EXPR.  If EXPR is
# omitted, returns log of $_.
#
sub log{#(EXPR)
}
# Does the same thing as the stat() function, but
# stats a symbolic link instead of the file the
# symbolic link points to.  If symbolic links are
# unimplemented on your system, a normal stat() is
# done.
#
sub lstat{#(EXPR)
}
# Does the same thing as the stat() function, but
# stats a symbolic link instead of the file the
# symbolic link points to.  If symbolic links are
# unimplemented on your system, a normal stat() is
# done.
#
sub lstat{#(FILEHANDLE)
}
# Evaluates the BLOCK or EXPR for each element of
# LIST (locally setting $_ to each element) and
# returns the list value composed of the results of
# each such evaluation.  Evaluates BLOCK or EXPR in
# a list context, so each element of LIST may
# produce zero, one, or more elements in the
# returned value.
#
#     @chars = map(chr, @nums);
#
# translates a list of numbers to the corresponding
# characters.  And
#
#     %hash = map { getkey($_) => $_ } @array;
#
# is just a funny way to write
#
#     %hash = ();
#     foreach $_ (@array) {
#         $hash{getkey($_)} = $_;
#     }
#
#
sub map{#(EXPR,LIST)
}
# Evaluates the BLOCK or EXPR for each element of
# LIST (locally setting $_ to each element) and
# returns the list value composed of the results of
# each such evaluation.  Evaluates BLOCK or EXPR in
# a list context, so each element of LIST may
# produce zero, one, or more elements in the
# returned value.
#
#     @chars = map(chr, @nums);
#
# translates a list of numbers to the corresponding
# characters.  And
#
#     %hash = map { getkey($_) => $_ } @array;
#
# is just a funny way to write
#
#     %hash = ();
#     foreach $_ (@array) {
#         $hash{getkey($_)} = $_;
#     }
#
#
sub map{#(BLOCK LIST)
}
# Creates the directory specified by FILENAME, with
# permissions specified by MODE (as modified by
# umask).  If it succeeds it returns 1, otherwise it
# returns 0 and sets $! (errno).
#
sub mkdir{#(FILENAME,MODE)
}
# Calls the System V IPC function msgctl(2).  If CMD
# is &IPC_STAT, then ARG must be a variable which
# will hold the returned msqid_ds structure.
# Returns like ioctl: the undefined value for error,
# "0 but true" for zero, or the actual return value
# otherwise.
sub msgctl{#(ID,CMD,ARG)
}
# Calls the System V IPC function msgget(2).
# Returns the message queue id, or the undefined
# value if there is an error.
#
sub msgget{#(KEY,FLAGS)
}
# Calls the System V IPC function msgsnd to send the
# message MSG to the message queue ID.  MSG must
# begin with the long integer message type, which
# may be created with pack("l", $type).  Returns
# TRUE if successful, or FALSE if there is an error.
#
sub msgsnd{#(ID,MSG,FLAGS)
}
# Calls the System V IPC function msgrcv to receive
# a message from message queue ID into variable VAR
# with a maximum message size of SIZE.  Note that if
# a message is received, the message type will be
# the first thing in VAR, and the maximum length of
# VAR is SIZE plus the size of the message type.
# Returns TRUE if successful, or FALSE if there is
# an error.
#
sub msgrcv{#(ID,VAR,SIZE,TYPE,FLAGS)
}
# A "my" declares the listed variables to be local
# (lexically) to the enclosing block, subroutine,
# eval, or do/require/use'd file.  If more than one
# value is listed, the list must be placed in
# parens.  See the section on Private Variables via
# my() in the perlsub manpage for details.
#
sub my{#(EXPR )
}
# The next command is like the continue statement in
# C; it starts the next iteration of the loop:
#
#     LINE: while (<STDIN>) {
#         next LINE if /^#/;      # discard comments
#         ...
#     }
#
# Note that if there were a continue block on the
# above, it would get executed even on discarded
# lines.  If the LABEL is omitted, the command
# refers to the innermost enclosing loop.
#
sub next{#()
}
# The next command is like the continue statement in
# C; it starts the next iteration of the loop:
#
#     LINE: while (<STDIN>) {
#         next LINE if /^#/;      # discard comments
#         ...
#     }
#
# Note that if there were a continue block on the
# above, it would get executed even on discarded
# lines.  If the LABEL is omitted, the command
# refers to the innermost enclosing loop.
#
sub next{#(LABEL)
}
# Interprets EXPR as an octal string and returns the
# corresponding decimal value.  (If EXPR happens to
# start off with 0x, interprets it as a hex string
# instead.)  The following will handle decimal,
# octal, and hex in the standard Perl or C notation:
#     $val = oct($val) if $val =~ /^0/;
#
# If EXPR is omitted, uses $_.
#
sub oct{#(EXPR)
}
# Opens the file whose filename is given by EXPR,
# and associates it with FILEHANDLE.  If FILEHANDLE
# is an expression, its value is used as the name of
# the real filehandle wanted.  If EXPR is omitted,
# the scalar variable of the same name as the
# FILEHANDLE contains the filename.  If the filename
# begins with "<" or nothing, the file is opened for
# input.  If the filename begins with ">", the file
# is opened for output.  If the filename begins with
# ">>", the file is opened for appending.  You can
# put a '+' in front of the '>' or '<' to indicate
# that you want both read and write access to the
# file; thus '+<' is usually preferred for
# read/write updates--the '+>' mode would clobber
# the file first.  These correspond to the fopen(3)
# modes of 'r', 'r+', 'w', 'w+', 'a', and 'a+'.
#
# If the filename begins with "|", the filename is
# interpreted as a command to which output is to be
# piped, and if the filename ends with a "|", the
# filename is interpreted See the section on Using
# open() for IPC in the perlipc manpage for more
# examples of this.  as command which pipes input to
# us.  (You may not have a raw open() to a command
# that pipes both in and out, but see See the open2
# manpage, the open3 manpage, and the section on
# Bidirectional Communication in the perlipc manpage
# for alternatives.)
#
# Opening '-' opens STDIN and opening '>-' opens
# STDOUT.  Open returns non-zero upon success, the
# undefined value otherwise.  If the open involved a
# pipe, the return value happens to be the pid of
# the subprocess.
#
# If you're unfortunate enough to be running Perl on
# a system that distinguishes between text files and
# binary files (modern operating systems don't
# care), then you should check out the binmode entry
# elsewhere in this documentfor tips for dealing
# with this.  The key distinction between systems
# that need binmode and those that don't is their
# text file formats.  Systems like Unix and Plan9
# that delimit lines with a single character, and
# that encode that character in C as '\n', do not
# need binmode.  The rest need it.
# Examples:
#
#     $ARTICLE = 100;
#     open ARTICLE or die "Can't find article $ARTICLE: $!\n";
#     while (<ARTICLE>) {...
#
#     open(LOG, '>>/usr/spool/news/twitlog'); # (log is reserved)
#
#     open(DBASE, '+<dbase.mine');            # open for update
#
#     open(ARTICLE, "caesar <$article |");    # decrypt article
#
#     open(EXTRACT, "|sort >/tmp/Tmp$$");     # $$ is our process id
#
#     # process argument list of files along with any includes
#
#     foreach $file (@ARGV) {
#         process($file, 'fh00');
#     }
#
#     sub process {
#         local($filename, $input) = @_;
#         $input++;               # this is a string increment
#         unless (open($input, $filename)) {
#             print STDERR "Can't open $filename: $!\n";
#             return;
#         }
#
#         while (<$input>) {              # note use of indirection
#             if (/^#include "(.*)"/) {
#                 process($1, $input);
#                 next;
#             }
#             ...         # whatever
#         }
#     }
#
# You may also, in the Bourne shell tradition,
# specify an EXPR beginning with ">&", in which case
# the rest of the string is interpreted as the name
# of a filehandle (or file descriptor, if numeric)
# which is to be duped and opened.  You may use &
# after >, >>, <, +>, +>> and +<.  The mode you
# specify should match the mode of the original
# filehandle.  (Duping a filehandle does not take
# into acount any existing contents of stdio
# buffers.)  Here is a script that saves, redirects,
# and restores STDOUT and STDERR:
#
#     #!/usr/bin/perl
#     open(SAVEOUT, ">&STDOUT");
#     open(SAVEERR, ">&STDERR");
#     open(STDOUT, ">foo.out") || die "Can't redirect stdout";
#     open(STDERR, ">&STDOUT") || die "Can't dup stdout";
#
#     select(STDERR); $| = 1;     # make unbuffered
#     select(STDOUT); $| = 1;     # make unbuffered
#
#     print STDOUT "stdout 1\n";  # this works for
#     print STDERR "stderr 1\n";  # subprocesses too
#
#     close(STDOUT);
#     close(STDERR);
#
#     open(STDOUT, ">&SAVEOUT");
#     open(STDERR, ">&SAVEERR");
#
#     print STDOUT "stdout 2\n";
#     print STDERR "stderr 2\n";
#
# If you specify "<&=N", where N is a number, then
# Perl will do an equivalent of C's fdopen() of that
# file descriptor; this is more parsimonious of file
# descriptors.  For example:
#
#     open(FILEHANDLE, "<&=$fd")
#
# If you open a pipe on the command "-", i.e. either
# "|-" or "-|", then there is an implicit fork done,
# and the return value of open is the pid of the
# child within the parent process, and 0 within the
# child process.  (Use defined($pid) to determine
# whether the open was successful.)  The filehandle
# behaves normally for the parent, but i/o to that
# filehandle is piped from/to the STDOUT/STDIN of
# the child process.  In the child process the
# filehandle isn't opened--i/o happens from/to the
# new STDOUT or STDIN.  Typically this is used like
# the normal piped open when you want to exercise
# more control over just how the pipe command gets
# executed, such as when you are running setuid, and
# don't want to have to scan shell commands for
# metacharacters.  The following pairs are more or
# less equivalent:
#
#     open(FOO, "|tr '[a-z]' '[A-Z]'");
#     open(FOO, "|-") || exec 'tr', '[a-z]', '[A-Z]';
#
#     open(FOO, "cat -n '$file'|");
#     open(FOO, "-|") || exec 'cat', '-n', $file;
#
# See the section on Safe Pipe Opens in the perlipc
# manpage for more examples of this.
#
# Explicitly closing any piped filehandle causes the
# parent process to wait for the child to finish,
# and returns the status value in $?.  Note: on any
# operation which may do a fork, unflushed buffers
# remain unflushed in both processes, which means
# you may need to set $| to avoid duplicate output.
#
# Using the FileHandle constructor from the
# FileHandle package, you can generate anonymous
# filehandles which have the scope of whatever
# variables hold references to them, and
# automatically close whenever and however you leave
# that scope:
#
#     use FileHandle;
#     ...
#     sub read_myfile_munged {
#         my $ALL = shift;
#         my $handle = new FileHandle;
#         open($handle, "myfile") or die "myfile: $!";
#         $first = <$handle>
#             or return ();     # Automatically closed here.
#         mung $first or die "mung failed";       # Or here.
#         return $first, <$handle> if $ALL;       # Or here.
#         $first;                                 # Or here.
#     }
#
# The filename that is passed to open will have
# leading and trailing whitespace deleted.  In order
# to open a file with arbitrary weird characters in
# it, it's necessary to protect any leading and
# trailing whitespace thusly:
#
#     $file =~ s#^(\s)#./$1#;
#     open(FOO, "< $file\0");
#
# If you want a "real" C open() (see the open(2)
# manpage on your system), then you should use the
# sysopen() function.  This is another way to
# protect your filenames from interpretation.  For
# example:
#
#     use FileHandle;
#     sysopen(HANDLE, $path, O_RDWR|O_CREAT|O_EXCL, 0700)
#         or die "sysopen $path: $!";
#     HANDLE->autoflush(1);
#     HANDLE->print("stuff $$\n");
#     seek(HANDLE, 0, 0);
#     print "File contains: ", <HANDLE>;
#
# See the seek() entry elsewhere in this documentfor
# some details about mixing reading and writing.
#
sub open{#(FILEHANDLE)
}
# Opens the file whose filename is given by EXPR,
# and associates it with FILEHANDLE.  If FILEHANDLE
# is an expression, its value is used as the name of
# the real filehandle wanted.  If EXPR is omitted,
# the scalar variable of the same name as the
# FILEHANDLE contains the filename.  If the filename
# begins with "<" or nothing, the file is opened for
# input.  If the filename begins with ">", the file
# is opened for output.  If the filename begins with
# ">>", the file is opened for appending.  You can
# put a '+' in front of the '>' or '<' to indicate
# that you want both read and write access to the
# file; thus '+<' is usually preferred for
# read/write updates--the '+>' mode would clobber
# the file first.  These correspond to the fopen(3)
# modes of 'r', 'r+', 'w', 'w+', 'a', and 'a+'.
#
# If the filename begins with "|", the filename is
# interpreted as a command to which output is to be
# piped, and if the filename ends with a "|", the
# filename is interpreted See the section on Using
# open() for IPC in the perlipc manpage for more
# examples of this.  as command which pipes input to
# us.  (You may not have a raw open() to a command
# that pipes both in and out, but see See the open2
# manpage, the open3 manpage, and the section on
# Bidirectional Communication in the perlipc manpage
# for alternatives.)
#
# Opening '-' opens STDIN and opening '>-' opens
# STDOUT.  Open returns non-zero upon success, the
# undefined value otherwise.  If the open involved a
# pipe, the return value happens to be the pid of
# the subprocess.
#
# If you're unfortunate enough to be running Perl on
# a system that distinguishes between text files and
# binary files (modern operating systems don't
# care), then you should check out the binmode entry
# elsewhere in this documentfor tips for dealing
# with this.  The key distinction between systems
# that need binmode and those that don't is their
# text file formats.  Systems like Unix and Plan9
# that delimit lines with a single character, and
# that encode that character in C as '\n', do not
# need binmode.  The rest need it.
# Examples:
#
#     $ARTICLE = 100;
#     open ARTICLE or die "Can't find article $ARTICLE: $!\n";
#     while (<ARTICLE>) {...
#
#     open(LOG, '>>/usr/spool/news/twitlog'); # (log is reserved)
#
#     open(DBASE, '+<dbase.mine');            # open for update
#
#     open(ARTICLE, "caesar <$article |");    # decrypt article
#
#     open(EXTRACT, "|sort >/tmp/Tmp$$");     # $$ is our process id
#
#     # process argument list of files along with any includes
#
#     foreach $file (@ARGV) {
#         process($file, 'fh00');
#     }
#
#     sub process {
#         local($filename, $input) = @_;
#         $input++;               # this is a string increment
#         unless (open($input, $filename)) {
#             print STDERR "Can't open $filename: $!\n";
#             return;
#         }
#
#         while (<$input>) {              # note use of indirection
#             if (/^#include "(.*)"/) {
#                 process($1, $input);
#                 next;
#             }
#             ...         # whatever
#         }
#     }
#
# You may also, in the Bourne shell tradition,
# specify an EXPR beginning with ">&", in which case
# the rest of the string is interpreted as the name
# of a filehandle (or file descriptor, if numeric)
# which is to be duped and opened.  You may use &
# after >, >>, <, +>, +>> and +<.  The mode you
# specify should match the mode of the original
# filehandle.  (Duping a filehandle does not take
# into acount any existing contents of stdio
# buffers.)  Here is a script that saves, redirects,
# and restores STDOUT and STDERR:
#
#     #!/usr/bin/perl
#     open(SAVEOUT, ">&STDOUT");
#     open(SAVEERR, ">&STDERR");
#     open(STDOUT, ">foo.out") || die "Can't redirect stdout";
#     open(STDERR, ">&STDOUT") || die "Can't dup stdout";
#
#     select(STDERR); $| = 1;     # make unbuffered
#     select(STDOUT); $| = 1;     # make unbuffered
#
#     print STDOUT "stdout 1\n";  # this works for
#     print STDERR "stderr 1\n";  # subprocesses too
#
#     close(STDOUT);
#     close(STDERR);
#
#     open(STDOUT, ">&SAVEOUT");
#     open(STDERR, ">&SAVEERR");
#
#     print STDOUT "stdout 2\n";
#     print STDERR "stderr 2\n";
#
# If you specify "<&=N", where N is a number, then
# Perl will do an equivalent of C's fdopen() of that
# file descriptor; this is more parsimonious of file
# descriptors.  For example:
#
#     open(FILEHANDLE, "<&=$fd")
#
# If you open a pipe on the command "-", i.e. either
# "|-" or "-|", then there is an implicit fork done,
# and the return value of open is the pid of the
# child within the parent process, and 0 within the
# child process.  (Use defined($pid) to determine
# whether the open was successful.)  The filehandle
# behaves normally for the parent, but i/o to that
# filehandle is piped from/to the STDOUT/STDIN of
# the child process.  In the child process the
# filehandle isn't opened--i/o happens from/to the
# new STDOUT or STDIN.  Typically this is used like
# the normal piped open when you want to exercise
# more control over just how the pipe command gets
# executed, such as when you are running setuid, and
# don't want to have to scan shell commands for
# metacharacters.  The following pairs are more or
# less equivalent:
#
#     open(FOO, "|tr '[a-z]' '[A-Z]'");
#     open(FOO, "|-") || exec 'tr', '[a-z]', '[A-Z]';
#
#     open(FOO, "cat -n '$file'|");
#     open(FOO, "-|") || exec 'cat', '-n', $file;
#
# See the section on Safe Pipe Opens in the perlipc
# manpage for more examples of this.
#
# Explicitly closing any piped filehandle causes the
# parent process to wait for the child to finish,
# and returns the status value in $?.  Note: on any
# operation which may do a fork, unflushed buffers
# remain unflushed in both processes, which means
# you may need to set $| to avoid duplicate output.
#
# Using the FileHandle constructor from the
# FileHandle package, you can generate anonymous
# filehandles which have the scope of whatever
# variables hold references to them, and
# automatically close whenever and however you leave
# that scope:
#
#     use FileHandle;
#     ...
#     sub read_myfile_munged {
#         my $ALL = shift;
#         my $handle = new FileHandle;
#         open($handle, "myfile") or die "myfile: $!";
#         $first = <$handle>
#             or return ();     # Automatically closed here.
#         mung $first or die "mung failed";       # Or here.
#         return $first, <$handle> if $ALL;       # Or here.
#         $first;                                 # Or here.
#     }
#
# The filename that is passed to open will have
# leading and trailing whitespace deleted.  In order
# to open a file with arbitrary weird characters in
# it, it's necessary to protect any leading and
# trailing whitespace thusly:
#
#     $file =~ s#^(\s)#./$1#;
#     open(FOO, "< $file\0");
#
# If you want a "real" C open() (see the open(2)
# manpage on your system), then you should use the
# sysopen() function.  This is another way to
# protect your filenames from interpretation.  For
# example:
#
#     use FileHandle;
#     sysopen(HANDLE, $path, O_RDWR|O_CREAT|O_EXCL, 0700)
#         or die "sysopen $path: $!";
#     HANDLE->autoflush(1);
#     HANDLE->print("stuff $$\n");
#     seek(HANDLE, 0, 0);
#     print "File contains: ", <HANDLE>;
#
# See the seek() entry elsewhere in this documentfor
# some details about mixing reading and writing.
#
sub open{#(FILEHANDLE,EXPR)
}
# Opens a directory named EXPR for processing by
# readdir(), telldir(), seekdir(), rewinddir() and
# closedir().  Returns TRUE if successful.
# DIRHANDLEs have their own namespace separate from
# FILEHANDLEs.
#
sub opendir{#(DIRHANDLE,EXPR)
}
# Returns the numeric ascii value of the first
# character of EXPR.  If EXPR is omitted, uses $_.
#
sub ord{#(EXPR)
}
# Takes an array or list of values and packs it into
# a binary structure, returning the string
# containing the structure.  The TEMPLATE is a
# sequence of characters that give the order and
# type of values, as follows:
#
#     A   An ascii string, will be space padded.
#     a   An ascii string, will be null padded.
#     b   A bit string (ascending bit order, like vec()).
#     B   A bit string (descending bit order).
#     h   A hex string (low nybble first).
#     H   A hex string (high nybble first).
#
#     c   A signed char value.
#     C   An unsigned char value.
#     s   A signed short value.
#     S   An unsigned short value.
#     i   A signed integer value.
#     I   An unsigned integer value.
#     l   A signed long value.
#     L   An unsigned long value.
#
#     n   A short in "network" order.
#     N   A long in "network" order.
#     v   A short in "VAX" (little-endian) order.
#     V   A long in "VAX" (little-endian) order.
#
#     f   A single-precision float in the native format.
#     d   A double-precision float in the native format.
#
#     p   A pointer to a null-terminated string.
#     P   A pointer to a structure (fixed-length string).
#
#     u   A uuencoded string.
#
#     x   A null byte.
#     X   Back up a byte.
#     @   Null fill to absolute position.
#
# Each letter may optionally be followed by a number
# which gives a repeat count.  With all types except
# "a", "A", "b", "B", "h" and "H", and "P" the pack
# function will gobble up that many values from the
# LIST.  A * for the repeat count means to use
# however many items are left.  The "a" and "A"
# types gobble just one value, but pack it as a
# string of length count, padding with nulls or
# spaces as necessary.  (When unpacking, "A" strips
# trailing spaces and nulls, but "a" does not.)
# Likewise, the "b" and "B" fields pack a string
# that many bits long.  The "h" and "H" fields pack
# a string that many nybbles long.  The "P" packs a
# pointer to a structure of the size indicated by
# the length.  Real numbers (floats and doubles) are
# in the native machine format only; due to the
# multiplicity of floating formats around, and the
# lack of a standard "network" representation, no
# facility for interchange has been made.  This
# means that packed floating point data written on
# one machine may not be readable on another - even
# if both use IEEE floating point arithmetic (as the
# endian-ness of the memory representation is not
# part of the IEEE spec).  Note that Perl uses
# doubles internally for all numeric calculation,
# and converting from double into float and thence
# back to double again will lose precision (i.e.
# unpack("f", pack("f", $foo)) will not in general
# equal $foo).
#
# Examples:
#
#     $foo = pack("cccc",65,66,67,68);
#     # foo eq "ABCD"
#     $foo = pack("c4",65,66,67,68);
#     # same thing
#
#     $foo = pack("ccxxcc",65,66,67,68);
#     # foo eq "AB\0\0CD"
#
#     $foo = pack("s2",1,2);
#     # "\1\0\2\0" on little-endian
#     # "\0\1\0\2" on big-endian
#
#     $foo = pack("a4","abcd","x","y","z");
#     # "abcd"
#
#     $foo = pack("aaaa","abcd","x","y","z");
#     # "axyz"
#
#     $foo = pack("a14","abcdefg");
#     # "abcdefg\0\0\0\0\0\0\0"
#
#     $foo = pack("i9pl", gmtime);
#     # a real struct tm (on my system anyway)
#
#     sub bintodec {
#         unpack("N", pack("B32", substr("0" x 32 . shift, -32)));
#     }
# The same template may generally also be used in
# the unpack function.
#
sub pack{#(TEMPLATE,LIST)
}
# Declares the compilation unit as being in the
# given namespace.  The scope of the package
# declaration is from the declaration itself through
# the end of the enclosing block (the same scope as
# the local() operator).  All further unqualified
# dynamic identifiers will be in this namespace.  A
# package statement only affects dynamic
# variables--including those you've used local()
# on--but not lexical variables created with my().
# Typically it would be the first declaration in a
# file to be included by the require or use
# operator.  You can switch into a package in more
# than one place; it merely influences which symbol
# table is used by the compiler for the rest of that
# block.  You can refer to variables and filehandles
# in other packages by prefixing the identifier with
# the package name and a double colon:
# $Package::Variable.  If the package name is null,
# the main package as assumed.  That is, $::sail is
# equivalent to $main::sail.
#
# See the section on Packages in the perlmod manpage
# for more information about packages, modules, and
# classes.  See the perlsub manpage for other
# scoping issues.
#
sub package{#(NAMESPACE)
}
# Opens a pair of connected pipes like the
# corresponding system call.  Note that if you set
# up a loop of piped processes, deadlock can occur
# unless you are very careful.  In addition, note
# that Perl's pipes use stdio buffering, so you may
# need to set $| to flush your WRITEHANDLE after
# each command, depending on the application.
#
# See the open2 manpage, the open3 manpage, and the
# section on Bidirectional Communication in the
# perlipc manpage for examples of such things.
#
sub pipe{#(READHANDLE,WRITEHANDLE)
}
# Pops and returns the last value of the array,
# shortening the array by 1.  Has a similar effect
# to
#
#     $tmp = $ARRAY[$#ARRAY--];
#
# If there are no elements in the array, returns the
# undefined value.  If ARRAY is omitted, pops the
# @ARGV array in the main program, and the @_ array
# in subroutines, just like shift().
sub pop{#(ARRAY)
}
# Returns the offset of where the last m//g search
# left off for the variable in question.  May be
# modified to change that offset.
#
sub pos{#(SCALAR)
}
# Prints a string or a comma-separated list of
# strings.  Returns TRUE if successful.  FILEHANDLE
# may be a scalar variable name, in which case the
# variable contains the name of or a reference to
# the filehandle, thus introducing one level of
# indirection.  (NOTE: If FILEHANDLE is a variable
# and the next token is a term, it may be
# misinterpreted as an operator unless you interpose
# a + or put parens around the arguments.)  If
# FILEHANDLE is omitted, prints by default to
# standard output (or to the last selected output
# channel--see select()).  If LIST is also omitted,
# prints $_ to STDOUT.  To set the default output
# channel to something other than STDOUT use the
# select operation.  Note that, because print takes
# a LIST, anything in the LIST is evaluated in a
# list context, and any subroutine that you call
# will have one or more of its expressions evaluated
# in a list context.  Also be careful not to follow
# the print keyword with a left parenthesis unless
# you want the corresponding right parenthesis to
# terminate the arguments to the print--interpose a
# + or put parens around all the arguments.
#
# Note that if you're storing FILEHANDLES in an
# array or other expression, you will have to use a
# block returning its value instead
#
#     print { $files[$i] } "stuff\n";
#     print { $OK ? STDOUT : STDERR } "stuff\n";
#
#
sub print{#()
}
# Prints a string or a comma-separated list of
# strings.  Returns TRUE if successful.  FILEHANDLE
# may be a scalar variable name, in which case the
# variable contains the name of or a reference to
# the filehandle, thus introducing one level of
# indirection.  (NOTE: If FILEHANDLE is a variable
# and the next token is a term, it may be
# misinterpreted as an operator unless you interpose
# a + or put parens around the arguments.)  If
# FILEHANDLE is omitted, prints by default to
# standard output (or to the last selected output
# channel--see select()).  If LIST is also omitted,
# prints $_ to STDOUT.  To set the default output
# channel to something other than STDOUT use the
# select operation.  Note that, because print takes
# a LIST, anything in the LIST is evaluated in a
# list context, and any subroutine that you call
# will have one or more of its expressions evaluated
# in a list context.  Also be careful not to follow
# the print keyword with a left parenthesis unless
# you want the corresponding right parenthesis to
# terminate the arguments to the print--interpose a
# + or put parens around all the arguments.
#
# Note that if you're storing FILEHANDLES in an
# array or other expression, you will have to use a
# block returning its value instead
#
#     print { $files[$i] } "stuff\n";
#     print { $OK ? STDOUT : STDERR } "stuff\n";
#
#
sub print{#(FILEHANDLE LIST)
}
# Prints a string or a comma-separated list of
# strings.  Returns TRUE if successful.  FILEHANDLE
# may be a scalar variable name, in which case the
# variable contains the name of or a reference to
# the filehandle, thus introducing one level of
# indirection.  (NOTE: If FILEHANDLE is a variable
# and the next token is a term, it may be
# misinterpreted as an operator unless you interpose
# a + or put parens around the arguments.)  If
# FILEHANDLE is omitted, prints by default to
# standard output (or to the last selected output
# channel--see select()).  If LIST is also omitted,
# prints $_ to STDOUT.  To set the default output
# channel to something other than STDOUT use the
# select operation.  Note that, because print takes
# a LIST, anything in the LIST is evaluated in a
# list context, and any subroutine that you call
# will have one or more of its expressions evaluated
# in a list context.  Also be careful not to follow
# the print keyword with a left parenthesis unless
# you want the corresponding right parenthesis to
# terminate the arguments to the print--interpose a
# + or put parens around all the arguments.
#
# Note that if you're storing FILEHANDLES in an
# array or other expression, you will have to use a
# block returning its value instead
#
#     print { $files[$i] } "stuff\n";
#     print { $OK ? STDOUT : STDERR } "stuff\n";
#
#
sub print{#(LIST)
}
# Equivalent to a "print FILEHANDLE sprintf(LIST)".
# The first argument of the list will be interpreted
# as the printf format.
#
sub printf{#(LIST)
}
# Equivalent to a "print FILEHANDLE sprintf(LIST)".
# The first argument of the list will be interpreted
# as the printf format.
#
sub printf{#(FILEHANDLE LIST)
}
# Treats ARRAY as a stack, and pushes the values of
# LIST onto the end of ARRAY.  The length of ARRAY
# increases by the length of LIST.  Has the same
# effect as
#     for $value (LIST) {
#         $ARRAY[++$#ARRAY] = $value;
#     }
#
# but is more efficient.  Returns the new number of
# elements in the array.
#
sub push{#(ARRAY,LIST)
}
# Returns the value of EXPR with with all regular
# expression metacharacters backslashed.  This is
# the internal function implementing the \Q escape
# in double-quoted strings.
#
sub quotemeta{#(EXPR)
}
# Returns a random fractional number between 0 and
# the value of EXPR.  (EXPR should be positive.)  If
# EXPR is omitted, returns a value between 0 and 1.
# This function produces repeatable sequences unless
# srand() is invoked.  See also srand().
#
# (Note: if your rand function consistently returns
# numbers that are too large or too small, then your
# version of Perl was probably compiled with the
# wrong number of RANDBITS.  As a workaround, you
# can usually multiply EXPR by the correct power of
# 2 to get the range you want.  This will make your
# script unportable, however.  It's better to
# recompile if you can.)
#
sub rand{#()
}
# Returns a random fractional number between 0 and
# the value of EXPR.  (EXPR should be positive.)  If
# EXPR is omitted, returns a value between 0 and 1.
# This function produces repeatable sequences unless
# srand() is invoked.  See also srand().
#
# (Note: if your rand function consistently returns
# numbers that are too large or too small, then your
# version of Perl was probably compiled with the
# wrong number of RANDBITS.  As a workaround, you
# can usually multiply EXPR by the correct power of
# 2 to get the range you want.  This will make your
# script unportable, however.  It's better to
# recompile if you can.)
#
sub rand{#(EXPR)
}
# Attempts to read LENGTH bytes of data into
# variable SCALAR from the specified FILEHANDLE.
# Returns the number of bytes actually read, or
# undef if there was an error.  SCALAR will be grown
# or shrunk to the length actually read.  An OFFSET
# may be specified to place the read data at some
# other place than the beginning of the string.
# This call is actually implemented in terms of
# stdio's fread call.  To get a true read system
# call, see sysread().
sub read{#(FILEHANDLE,SCALAR,LENGTH)
}
# Attempts to read LENGTH bytes of data into
# variable SCALAR from the specified FILEHANDLE.
# Returns the number of bytes actually read, or
# undef if there was an error.  SCALAR will be grown
# or shrunk to the length actually read.  An OFFSET
# may be specified to place the read data at some
# other place than the beginning of the string.
# This call is actually implemented in terms of
# stdio's fread call.  To get a true read system
# call, see sysread().
sub read{#(FILEHANDLE,SCALAR,LENGTH,OFFSET)
}
# Returns the next directory entry for a directory
# opened by opendir().  If used in a list context,
# returns all the rest of the entries in the
# directory.  If there are no more entries, returns
# an undefined value in a scalar context or a null
# list in a list context.
#
# If you're planning to filetest the return values
# out of a readdir(), you'd better prepend the
# directory in question.  Otherwise, since we didn't
# chdir() there, it would have been testing the
# wrong file.
#
#     opendir(DIR, $some_dir) || die "can't opendir $some_dir: $!";
#     @dots = grep { /^\./ && -f "$some_dir/$_" } readdir(DIR);
#     closedir DIR;
#
#
sub readdir{#(DIRHANDLE)
}
# Returns the value of a symbolic link, if symbolic
# links are implemented.  If not, gives a fatal
# error.  If there is some system error, returns the
# undefined value and sets $! (errno).  If EXPR is
# omitted, uses $_.
#
sub readlink{#(EXPR)
}
# Receives a message on a socket.  Attempts to
# receive LENGTH bytes of data into variable SCALAR
# from the specified SOCKET filehandle.  Actually
# does a C recvfrom(), so that it can returns the
# address of the sender.  Returns the undefined
# value if there's an error.  SCALAR will be grown
# or shrunk to the length actually read.  Takes the
# same flags as the system call of the same name.
# See the section on UDP: Message Passing in the
# perlipc manpage for examples.
#
sub recv{#(SOCKET,SCALAR,LEN,FLAGS)
}
# The redo command restarts the loop block without
# evaluating the conditional again.  The continue
# block, if any, is not executed.  If the LABEL is
# omitted, the command refers to the innermost
# enclosing loop.  This command is normally used by
# programs that want to lie to themselves about what
# was just input:
#     # a simpleminded Pascal comment stripper
#     # (warning: assumes no { or } in strings)
#     LINE: while (<STDIN>) {
#         while (s|({.*}.*){.*}|$1 |) {}
#         s|{.*}| |;
#         if (s|{.*| |) {
#             $front = $_;
#             while (<STDIN>) {
#                 if (/}/) {      # end of comment?
#                     s|^|$front{|;
#                     redo LINE;
#                 }
#             }
#         }
#         print;
#     }
#
#
sub redo{#()
}
# The redo command restarts the loop block without
# evaluating the conditional again.  The continue
# block, if any, is not executed.  If the LABEL is
# omitted, the command refers to the innermost
# enclosing loop.  This command is normally used by
# programs that want to lie to themselves about what
# was just input:
#     # a simpleminded Pascal comment stripper
#     # (warning: assumes no { or } in strings)
#     LINE: while (<STDIN>) {
#         while (s|({.*}.*){.*}|$1 |) {}
#         s|{.*}| |;
#         if (s|{.*| |) {
#             $front = $_;
#             while (<STDIN>) {
#                 if (/}/) {      # end of comment?
#                     s|^|$front{|;
#                     redo LINE;
#                 }
#             }
#         }
#         print;
#     }
#
#
sub redo{#(LABEL)
}
# Returns a TRUE value if EXPR is a reference, FALSE
# otherwise.  The value returned depends on the type
# of thing the reference is a reference to.  Builtin
# types include:
#
#     REF
#     SCALAR
#     ARRAY
#     HASH
#     CODE
#     GLOB
#
# If the referenced object has been blessed into a
# package, then that package name is returned
# instead.  You can think of ref() as a typeof()
# operator.
#
#     if (ref($r) eq "HASH") {
#         print "r is a reference to an associative array.\n";
#     }
#     if (!ref ($r) {
#         print "r is not a reference at all.\n";
#     }
#
# See also the perlref manpage.
#
sub ref{#(EXPR)
}
# Changes the name of a file.  Returns 1 for
# success, 0 otherwise.  Will not work across
# filesystem boundaries.
#
sub rename{#(OLDNAME,NEWNAME)
}
# Demands some semantics specified by EXPR, or by $_
# if EXPR is not supplied.  If EXPR is numeric,
# demands that the current version of Perl ($] or
# $PERL_VERSION) be equal or greater than EXPR.
#
# Otherwise, demands that a library file be included
# if it hasn't already been included.  The file is
# included via the do-FILE mechanism, which is
# essentially just a variety of eval().  Has
# semantics similar to the following subroutine:
#
#     sub require {
#         local($filename) = @_;
#         return 1 if $INC{$filename};
#         local($realfilename,$result);
#         ITER: {
#             foreach $prefix (@INC) {
#                 $realfilename = "$prefix/$filename";
#                 if (-f $realfilename) {
#                     $result = do $realfilename;
#                     last ITER;
#                 }
#             }
#             die "Can't find $filename in \@INC";
#         }
#         die $@ if $@;
#         die "$filename did not return true value" unless $result;
#         $INC{$filename} = $realfilename;
#         $result;
#     }
#
# Note that the file will not be included twice
# under the same specified name.  The file must
# return TRUE as the last statement to indicate
# successful execution of any initialization code,
# so it's customary to end such a file with "1;"
# unless you're sure it'll return TRUE otherwise.
# But it's better just to put the "1;", in case you
# add more statements.
#
# If EXPR is a bare word, the require assumes a
# ".pm" extension for you, to make it easy to load
# standard modules.  This form of loading of modules
# does not risk altering your namespace.
#
# For a yet-more-powerful import facility, see the
# the use() entry elsewhere in this documentthe
# perlmod manpage.
#
sub require{#()
}
# Demands some semantics specified by EXPR, or by $_
# if EXPR is not supplied.  If EXPR is numeric,
# demands that the current version of Perl ($] or
# $PERL_VERSION) be equal or greater than EXPR.
#
# Otherwise, demands that a library file be included
# if it hasn't already been included.  The file is
# included via the do-FILE mechanism, which is
# essentially just a variety of eval().  Has
# semantics similar to the following subroutine:
#
#     sub require {
#         local($filename) = @_;
#         return 1 if $INC{$filename};
#         local($realfilename,$result);
#         ITER: {
#             foreach $prefix (@INC) {
#                 $realfilename = "$prefix/$filename";
#                 if (-f $realfilename) {
#                     $result = do $realfilename;
#                     last ITER;
#                 }
#             }
#             die "Can't find $filename in \@INC";
#         }
#         die $@ if $@;
#         die "$filename did not return true value" unless $result;
#         $INC{$filename} = $realfilename;
#         $result;
#     }
#
# Note that the file will not be included twice
# under the same specified name.  The file must
# return TRUE as the last statement to indicate
# successful execution of any initialization code,
# so it's customary to end such a file with "1;"
# unless you're sure it'll return TRUE otherwise.
# But it's better just to put the "1;", in case you
# add more statements.
#
# If EXPR is a bare word, the require assumes a
# ".pm" extension for you, to make it easy to load
# standard modules.  This form of loading of modules
# does not risk altering your namespace.
#
# For a yet-more-powerful import facility, see the
# the use() entry elsewhere in this documentthe
# perlmod manpage.
#
sub require{#(EXPR)
}
# Generally used in a continue block at the end of a
# loop to clear variables and reset ?? searches so
# that they work again.  The expression is
# interpreted as a list of single characters
# (hyphens allowed for ranges).  All variables and
# arrays beginning with one of those letters are
# reset to their pristine state.  If the expression
# is omitted, one-match searches (?pattern?) are
# reset to match again.  Only resets variables or
# searches in the current package.  Always returns
# 1.  Examples:
#
#     reset 'X';          # reset all X variables
#     reset 'a-z';        # reset lower case variables
#     reset;              # just reset ?? searches
#
# Resetting "A-Z" is not recommended since you'll
# wipe out your ARGV and ENV arrays.  Only resets
# package variables--lexical variables are
# unaffected, but they clean themselves up on scope
# exit anyway, so anymore you probably want to use
# them instead.  See the my entry elsewhere in this
# document.
#
sub reset{#()
}
# Generally used in a continue block at the end of a
# loop to clear variables and reset ?? searches so
# that they work again.  The expression is
# interpreted as a list of single characters
# (hyphens allowed for ranges).  All variables and
# arrays beginning with one of those letters are
# reset to their pristine state.  If the expression
# is omitted, one-match searches (?pattern?) are
# reset to match again.  Only resets variables or
# searches in the current package.  Always returns
# 1.  Examples:
#
#     reset 'X';          # reset all X variables
#     reset 'a-z';        # reset lower case variables
#     reset;              # just reset ?? searches
#
# Resetting "A-Z" is not recommended since you'll
# wipe out your ARGV and ENV arrays.  Only resets
# package variables--lexical variables are
# unaffected, but they clean themselves up on scope
# exit anyway, so anymore you probably want to use
# them instead.  See the my entry elsewhere in this
# document.
#
sub reset{#(EXPR)
}
# Returns from a subroutine or eval with the value
# specified.  (Note that in the absence of a return
# a subroutine or eval() will automatically return
# the value of the last expression evaluated.)
#
sub return{#(LIST)
}
# In a list context, returns a list value consisting
# of the elements of LIST in the opposite order.  In
# a scalar context, returns a string value
# consisting of the bytes of the first element of
# LIST in the opposite order.
#
#     print reverse <>;                   # line tac
#
#     undef $/;
#     print scalar reverse scalar <>;     # byte tac
#
#
sub reverse{#(LIST)
}
# Sets the current position to the beginning of the
# directory for the readdir() routine on DIRHANDLE.
#
sub rewinddir{#(DIRHANDLE)
}
# Works just like index except that it returns the
# position of the LAST occurrence of SUBSTR in STR.
# If POSITION is specified, returns the last
# occurrence at or before that position.
#
sub rindex{#(STR,SUBSTR)
}
# Works just like index except that it returns the
# position of the LAST occurrence of SUBSTR in STR.
# If POSITION is specified, returns the last
# occurrence at or before that position.
#
sub rindex{#(STR,SUBSTR,POSITION)
}
# Deletes the directory specified by FILENAME if it
# is empty.  If it succeeds it returns 1, otherwise
# it returns 0 and sets $! (errno).  If FILENAME is
# omitted, uses $_.
#
sub rmdir{#(FILENAME)
}
# Forces EXPR to be interpreted in a scalar context
# and returns the value of EXPR.
#
#     @counts = ( scalar @a, scalar @b, scalar @c );
#
# There is no equivalent operator to force an
# expression to be interpolated in a list context
# because it's in practice never needed.  If you
# really wanted to do so, however, you could use the
# construction @{[ (some expression) ]}, but usually
# a simple (some expression) suffices.
#
sub scalar{#(EXPR)
}
# Randomly positions the file pointer for
# FILEHANDLE, just like the fseek() call of stdio.
# FILEHANDLE may be an expression whose value gives
# the name of the filehandle.  The values for WHENCE
# are 0 to set the file pointer to POSITION, 1 to
# set the it to current plus POSITION, and 2 to set
# it to EOF plus offset.  You may use the values
# SEEK_SET, SEEK_CUR, and SEEK_END for this from
# POSIX module.  Returns 1 upon success, 0
# otherwise.
#
# On some systems you have to do a seek whenever you
# switch between reading and writing.  Amongst other
# things, this may have the effect of calling
# stdio's clearerr(3).  A "whence" of 1 (SEEK_CUR)
# is useful for not moving the file pointer:
#
#     seek(TEST,0,1);
#
# This is also useful for applications emulating
# tail -f.  Once you hit EOF on your read, and then
# sleep for a while, you might have to stick in a
# seek() to reset things.  First the simple trick
# listed above to clear the filepointer.  The seek()
# doesn't change the current position, but it does
# clear the end-of-file condition on the handle, so
# that the next <FILE> makes Perl try again to read
# something.  Hopefully.
#
# If that doesn't work (some stdios are particularly
# cantankerous), then you may need something more
# like this:
#     for (;;) {
#         for ($curpos = tell(FILE); $_ = <FILE>; $curpos = tell(FILE)) {
#             # search for some stuff and put it into files
#         }
#         sleep($for_a_while);
#         seek(FILE, $curpos, 0);
#     }
#
#
sub seek{#(FILEHANDLE,POSITION,WHENCE)
}
# Sets the current position for the readdir()
# routine on DIRHANDLE.  POS must be a value
# returned by telldir().  Has the same caveats about
# possible directory compaction as the corresponding
# system library routine.
#
sub seekdir{#(DIRHANDLE,POS)
}
# Returns the currently selected filehandle.  Sets
# the current default filehandle for output, if
# FILEHANDLE is supplied.  This has two effects:
# first, a write or a print without a filehandle
# will default to this FILEHANDLE.  Second,
# references to variables related to output will
# refer to this output channel.  For example, if you
# have to set the top of form format for more than
# one output channel, you might do the following:
#
#     select(REPORT1);
#     $^ = 'report1_top';
#     select(REPORT2);
#     $^ = 'report2_top';
#
# FILEHANDLE may be an expression whose value gives
# the name of the actual filehandle.  Thus:
#
#     $oldfh = select(STDERR); $| = 1; select($oldfh);
#
# Some programmers may prefer to think of
# filehandles as objects with methods, preferring to
# write the last example as:
#
#     use FileHandle;
#     STDERR->autoflush(1);
#
#
sub select{#()
}
# Returns the currently selected filehandle.  Sets
# the current default filehandle for output, if
# FILEHANDLE is supplied.  This has two effects:
# first, a write or a print without a filehandle
# will default to this FILEHANDLE.  Second,
# references to variables related to output will
# refer to this output channel.  For example, if you
# have to set the top of form format for more than
# one output channel, you might do the following:
#
#     select(REPORT1);
#     $^ = 'report1_top';
#     select(REPORT2);
#     $^ = 'report2_top';
#
# FILEHANDLE may be an expression whose value gives
# the name of the actual filehandle.  Thus:
#
#     $oldfh = select(STDERR); $| = 1; select($oldfh);
#
# Some programmers may prefer to think of
# filehandles as objects with methods, preferring to
# write the last example as:
#
#     use FileHandle;
#     STDERR->autoflush(1);
#
#
sub select{#(FILEHANDLE)
}
# This calls the select(2) system call with the
# bitmasks specified, which can be constructed using
# fileno() and vec(), along these lines:
#     $rin = $win = $ein = '';
#     vec($rin,fileno(STDIN),1) = 1;
#     vec($win,fileno(STDOUT),1) = 1;
#     $ein = $rin | $win;
#
# If you want to select on many filehandles you
# might wish to write a subroutine:
#
#     sub fhbits {
#         local(@fhlist) = split(' ',$_[0]);
#         local($bits);
#         for (@fhlist) {
#             vec($bits,fileno($_),1) = 1;
#         }
#         $bits;
#     }
#     $rin = fhbits('STDIN TTY SOCK');
#
# The usual idiom is:
#
#     ($nfound,$timeleft) =
#       select($rout=$rin, $wout=$win, $eout=$ein, $timeout);
#
# or to block until something becomes ready just do
# this
#
#     $nfound = select($rout=$rin, $wout=$win, $eout=$ein, undef);
#
# Most systems do not both to return anything useful
# in $timeleft, so calling select() in a scalar
# context just returns $nfound.
#
# Any of the bitmasks can also be undef.  The
# timeout, if specified, is in seconds, which may be
# fractional.  Note: not all implementations are
# capable of returning the $timeleft.  If not, they
# always return $timeleft equal to the supplied
# $timeout.
#
# You can effect a 250-microsecond sleep this way:
#
#     select(undef, undef, undef, 0.25);
#
# WARNING: Do not attempt to mix buffered I/O (like
# read() or <FH>) with select().  You have to use
# sysread() instead.
#
sub select{#(RBITS,WBITS,EBITS,TIMEOUT)
}
# Calls the System V IPC function semctl.  If CMD is
# &IPC_STAT or &GETALL, then ARG must be a variable
# which will hold the returned semid_ds structure or
# semaphore value array.  Returns like ioctl: the
# undefined value for error, "0 but true" for zero,
# or the actual return value otherwise.
sub semctl{#(ID,SEMNUM,CMD,ARG)
}
# Calls the System V IPC function semget.  Returns
# the semaphore id, or the undefined value if there
# is an error.
#
sub semget{#(KEY,NSEMS,FLAGS)
}
# Calls the System V IPC function semop to perform
# semaphore operations such as signaling and
# waiting.  OPSTRING must be a packed array of semop
# structures.  Each semop structure can be generated
# with pack("sss", $semnum, $semop, $semflag).  The
# number of semaphore operations is implied by the
# length of OPSTRING.  Returns TRUE if successful,
# or FALSE if there is an error.  As an example, the
# following code waits on semaphore $semnum of
# semaphore id $semid:
#
#     $semop = pack("sss", $semnum, -1, 0);
#     die "Semaphore trouble: $!\n" unless semop($semid, $semop);
#
# To signal the semaphore, replace "-1" with "1".
#
sub semop{#(KEY,OPSTRING)
}
# Sends a message on a socket.  Takes the same flags
# as the system call of the same name.  On
# unconnected sockets you must specify a destination
# to send TO, in which case it does a C sendto().
# Returns the number of characters sent, or the
# undefined value if there is an error.  See the
# section on UDP: Message Passing in the perlipc
# manpage for examples.
#
sub send{#(SOCKET,MSG,FLAGS)
}
# Sends a message on a socket.  Takes the same flags
# as the system call of the same name.  On
# unconnected sockets you must specify a destination
# to send TO, in which case it does a C sendto().
# Returns the number of characters sent, or the
# undefined value if there is an error.  See the
# section on UDP: Message Passing in the perlipc
# manpage for examples.
#
sub send{#(SOCKET,MSG,FLAGS,TO)
}
# Sets the current process group for the specified
# PID, 0 for the current process.  Will produce a
# fatal error if used on a machine that doesn't
# implement setpgrp(2).
#
sub setpgrp{#(PID,PGRP)
}
# Sets the current priority for a process, a process
# group, or a user.  (See setpriority(2).)  Will
# produce a fatal error if used on a machine that
# doesn't implement setpriority(2).
#
sub setpriority{#(WHICH,WHO,PRIORITY)
}
# Sets the socket option requested.  Returns
# undefined if there is an error.  OPTVAL may be
# specified as undef if you don't want to pass an
# argument.
#
sub setsockopt{#(SOCKET,LEVEL,OPTNAME,OPTVAL)
}
# Shifts the first value of the array off and
# returns it, shortening the array by 1 and moving
# everything down.  If there are no elements in the
# array, returns the undefined value.  If ARRAY is
# omitted, shifts the @ARGV array in the main
# program, and the @_ array in subroutines.  (This
# is determined lexically.)  See also unshift(),
# push(), and pop().  Shift() and unshift() do the
# same thing to the left end of an array that push()
# and pop() do to the right end.
#
sub shift{#()
}
# Shifts the first value of the array off and
# returns it, shortening the array by 1 and moving
# everything down.  If there are no elements in the
# array, returns the undefined value.  If ARRAY is
# omitted, shifts the @ARGV array in the main
# program, and the @_ array in subroutines.  (This
# is determined lexically.)  See also unshift(),
# push(), and pop().  Shift() and unshift() do the
# same thing to the left end of an array that push()
# and pop() do to the right end.
#
sub shift{#(ARRAY)
}
# Calls the System V IPC function shmctl.  If CMD is
# &IPC_STAT, then ARG must be a variable which will
# hold the returned shmid_ds structure.  Returns
# like ioctl: the undefined value for error, "0 but
# true" for zero, or the actual return value
# otherwise.
#
sub shmctl{#(ID,CMD,ARG)
}
# Calls the System V IPC function shmget.  Returns
# the shared memory segment id, or the undefined
# value if there is an error.
#
sub shmget{#(KEY,SIZE,FLAGS)
}
# Reads or writes the System V shared memory segment
# ID starting at position POS for size SIZE by
# attaching to it, copying in/out, and detaching
# from it.  When reading, VAR must be a variable
# which will hold the data read.  When writing, if
# STRING is too long, only SIZE bytes are used; if
# STRING is too short, nulls are written to fill out
# SIZE bytes.  Return TRUE if successful, or FALSE
# if there is an error.
#
sub shmwrite{#(ID,STRING,POS,SIZE)
}
# Reads or writes the System V shared memory segment
# ID starting at position POS for size SIZE by
# attaching to it, copying in/out, and detaching
# from it.  When reading, VAR must be a variable
# which will hold the data read.  When writing, if
# STRING is too long, only SIZE bytes are used; if
# STRING is too short, nulls are written to fill out
# SIZE bytes.  Return TRUE if successful, or FALSE
# if there is an error.
#
sub shmread{#(ID,VAR,POS,SIZE)
}
# Shuts down a socket connection in the manner
# indicated by HOW, which has the same
# interpretation as in the system call of the same
# name.
#
sub shutdown{#(SOCKET,HOW)
}
# Returns the sine of EXPR (expressed in radians).
# If EXPR is omitted, returns sine of $_.
#
sub sin{#(EXPR)
}
# Causes the script to sleep for EXPR seconds, or
# forever if no EXPR.  May be interrupted by sending
# the process a SIGALRM.  Returns the number of
# seconds actually slept.  You probably cannot mix
# alarm() and sleep() calls, since sleep() is often
# implemented using alarm().
#
# On some older systems, it may sleep up to a full
# second less than what you requested, depending on
# how it counts seconds.  Most modern systems always
# sleep the full amount.
#
# For delays of finer granularity than one second,
# you may use Perl's syscall() interface to access
# setitimer(2) if your system supports it, or else
# see the select() entry elsewhere in this
# documentbelow.
#
sub sleep{#()
}
# Causes the script to sleep for EXPR seconds, or
# forever if no EXPR.  May be interrupted by sending
# the process a SIGALRM.  Returns the number of
# seconds actually slept.  You probably cannot mix
# alarm() and sleep() calls, since sleep() is often
# implemented using alarm().
#
# On some older systems, it may sleep up to a full
# second less than what you requested, depending on
# how it counts seconds.  Most modern systems always
# sleep the full amount.
#
# For delays of finer granularity than one second,
# you may use Perl's syscall() interface to access
# setitimer(2) if your system supports it, or else
# see the select() entry elsewhere in this
# documentbelow.
#
sub sleep{#(EXPR)
}
# Opens a socket of the specified kind and attaches
# it to filehandle SOCKET.  DOMAIN, TYPE and
# PROTOCOL are specified the same as for the system
# call of the same name.  You should "use Socket;"
# first to get the proper definitions imported.  See
# the example in the section on Sockets:
# Client/Server Communication in the perlipc
# manpage.
#
sub socket{#(SOCKET,DOMAIN,TYPE,PROTOCOL)
}
# Creates an unnamed pair of sockets in the
# specified domain, of the specified type.  DOMAIN,
# TYPE and PROTOCOL are specified the same as for
# the system call of the same name.  If
# unimplemented, yields a fatal error.  Returns TRUE
# if successful.
#
sub socketpair{#(SOCKET1,SOCKET2,DOMAIN,TYPE,PROTOCOL)
}
# Sorts the LIST and returns the sorted list value.
# Nonexistent values of arrays are stripped out.  If
# SUBNAME or BLOCK is omitted, sorts in standard
# string comparison order.  If SUBNAME is specified,
# it gives the name of a subroutine that returns an
# integer less than, equal to, or greater than 0,
# depending on how the elements of the array are to
# be ordered.  (The <=> and cmp operators are
# extremely useful in such routines.)  SUBNAME may
# be a scalar variable name, in which case the value
# provides the name of the subroutine to use.  In
# place of a SUBNAME, you can provide a BLOCK as an
# anonymous, in-line sort subroutine.
#
# In the interests of efficiency the normal calling
# code for subroutines is bypassed, with the
# following effects: the subroutine may not be a
# recursive subroutine, and the two elements to be
# compared are passed into the subroutine not via @_
# but as the package global variables $a and $b (see
# example below).  They are passed by reference, so
# don't modify $a and $b.  And don't try to declare
# them as lexicals either.
#
# Examples:
#
#     # sort lexically
#     @articles = sort @files;
#
#     # same thing, but with explicit sort routine
#     @articles = sort {$a cmp $b} @files;
#
#     # now case-insensitively
#     @articles = sort { uc($a) cmp uc($b)} @files;
#
#     # same thing in reversed order
#     @articles = sort {$b cmp $a} @files;
#
#     # sort numerically ascending
#     @articles = sort {$a <=> $b} @files;
#
#     # sort numerically descending
#     @articles = sort {$b <=> $a} @files;
#
#     # sort using explicit subroutine name
#     sub byage {
#         $age{$a} <=> $age{$b};  # presuming integers
#     }
#     @sortedclass = sort byage @class;
#
#     # this sorts the %age associative arrays by value
#     # instead of key using an inline function
#     @eldest = sort { $age{$b} <=> $age{$a} } keys %age;
#
#     sub backwards { $b cmp $a; }
#     @harry = ('dog','cat','x','Cain','Abel');
#     @george = ('gone','chased','yz','Punished','Axed');
#     print sort @harry;
#             # prints AbelCaincatdogx
#     print sort backwards @harry;
#             # prints xdogcatCainAbel
#     print sort @george, 'to', @harry;
#             # prints AbelAxedCainPunishedcatchaseddoggonetoxyz
#
#     # inefficiently sort by descending numeric compare using
#     # the first integer after the first = sign, or the
#     # whole record case-insensitively otherwise
#     @new = sort {
#         ($b =~ /=(\d+)/)[0] <=> ($a =~ /=(\d+)/)[0]
#                             ||
#                     uc($a)  cmp  uc($b)
#     } @old;
#
#     # same thing, but much more efficiently;
#     # we'll build auxiliary indices instead
#     # for speed
#     @nums = @caps = ();
#     for (@old) {
#         push @nums, /=(\d+)/;
#         push @caps, uc($_);
#     }
#
#     @new = @old[ sort {
#                         $nums[$b] <=> $nums[$a]
#                                  ||
#                         $caps[$a] cmp $caps[$b]
#                        } 0..$#old
#                ];
#
#     # same thing using a Schwartzian Transform (no temps)
#     @new = map { $_->[0] }
#         sort { $b->[1] <=> $a->[1]
#                         ||
#                $a->[2] cmp $b->[2]
#         } map { [$_, /=(\d+)/, uc($_)] } @old;
#
# If you're and using strict, you MUST NOT declare
# $a and $b as lexicals.  They are package globals.
# That means if you're in the main package, it's
#
#     @articles = sort {$main::b <=> $main::a} @files;
#
# or just
#
#     @articles = sort {$::b <=> $::a} @files;
#
# but if you're in the FooPack package, it's
#
#     @articles = sort {$FooPack::b <=> $FooPack::a} @files;
#
#
sub sort{#(LIST)
}
# Sorts the LIST and returns the sorted list value.
# Nonexistent values of arrays are stripped out.  If
# SUBNAME or BLOCK is omitted, sorts in standard
# string comparison order.  If SUBNAME is specified,
# it gives the name of a subroutine that returns an
# integer less than, equal to, or greater than 0,
# depending on how the elements of the array are to
# be ordered.  (The <=> and cmp operators are
# extremely useful in such routines.)  SUBNAME may
# be a scalar variable name, in which case the value
# provides the name of the subroutine to use.  In
# place of a SUBNAME, you can provide a BLOCK as an
# anonymous, in-line sort subroutine.
#
# In the interests of efficiency the normal calling
# code for subroutines is bypassed, with the
# following effects: the subroutine may not be a
# recursive subroutine, and the two elements to be
# compared are passed into the subroutine not via @_
# but as the package global variables $a and $b (see
# example below).  They are passed by reference, so
# don't modify $a and $b.  And don't try to declare
# them as lexicals either.
#
# Examples:
#
#     # sort lexically
#     @articles = sort @files;
#
#     # same thing, but with explicit sort routine
#     @articles = sort {$a cmp $b} @files;
#
#     # now case-insensitively
#     @articles = sort { uc($a) cmp uc($b)} @files;
#
#     # same thing in reversed order
#     @articles = sort {$b cmp $a} @files;
#
#     # sort numerically ascending
#     @articles = sort {$a <=> $b} @files;
#
#     # sort numerically descending
#     @articles = sort {$b <=> $a} @files;
#
#     # sort using explicit subroutine name
#     sub byage {
#         $age{$a} <=> $age{$b};  # presuming integers
#     }
#     @sortedclass = sort byage @class;
#
#     # this sorts the %age associative arrays by value
#     # instead of key using an inline function
#     @eldest = sort { $age{$b} <=> $age{$a} } keys %age;
#
#     sub backwards { $b cmp $a; }
#     @harry = ('dog','cat','x','Cain','Abel');
#     @george = ('gone','chased','yz','Punished','Axed');
#     print sort @harry;
#             # prints AbelCaincatdogx
#     print sort backwards @harry;
#             # prints xdogcatCainAbel
#     print sort @george, 'to', @harry;
#             # prints AbelAxedCainPunishedcatchaseddoggonetoxyz
#
#     # inefficiently sort by descending numeric compare using
#     # the first integer after the first = sign, or the
#     # whole record case-insensitively otherwise
#     @new = sort {
#         ($b =~ /=(\d+)/)[0] <=> ($a =~ /=(\d+)/)[0]
#                             ||
#                     uc($a)  cmp  uc($b)
#     } @old;
#
#     # same thing, but much more efficiently;
#     # we'll build auxiliary indices instead
#     # for speed
#     @nums = @caps = ();
#     for (@old) {
#         push @nums, /=(\d+)/;
#         push @caps, uc($_);
#     }
#
#     @new = @old[ sort {
#                         $nums[$b] <=> $nums[$a]
#                                  ||
#                         $caps[$a] cmp $caps[$b]
#                        } 0..$#old
#                ];
#
#     # same thing using a Schwartzian Transform (no temps)
#     @new = map { $_->[0] }
#         sort { $b->[1] <=> $a->[1]
#                         ||
#                $a->[2] cmp $b->[2]
#         } map { [$_, /=(\d+)/, uc($_)] } @old;
#
# If you're and using strict, you MUST NOT declare
# $a and $b as lexicals.  They are package globals.
# That means if you're in the main package, it's
#
#     @articles = sort {$main::b <=> $main::a} @files;
#
# or just
#
#     @articles = sort {$::b <=> $::a} @files;
#
# but if you're in the FooPack package, it's
#
#     @articles = sort {$FooPack::b <=> $FooPack::a} @files;
#
#
sub sort{#(SUBNAME LIST)
}
# Sorts the LIST and returns the sorted list value.
# Nonexistent values of arrays are stripped out.  If
# SUBNAME or BLOCK is omitted, sorts in standard
# string comparison order.  If SUBNAME is specified,
# it gives the name of a subroutine that returns an
# integer less than, equal to, or greater than 0,
# depending on how the elements of the array are to
# be ordered.  (The <=> and cmp operators are
# extremely useful in such routines.)  SUBNAME may
# be a scalar variable name, in which case the value
# provides the name of the subroutine to use.  In
# place of a SUBNAME, you can provide a BLOCK as an
# anonymous, in-line sort subroutine.
#
# In the interests of efficiency the normal calling
# code for subroutines is bypassed, with the
# following effects: the subroutine may not be a
# recursive subroutine, and the two elements to be
# compared are passed into the subroutine not via @_
# but as the package global variables $a and $b (see
# example below).  They are passed by reference, so
# don't modify $a and $b.  And don't try to declare
# them as lexicals either.
#
# Examples:
#
#     # sort lexically
#     @articles = sort @files;
#
#     # same thing, but with explicit sort routine
#     @articles = sort {$a cmp $b} @files;
#
#     # now case-insensitively
#     @articles = sort { uc($a) cmp uc($b)} @files;
#
#     # same thing in reversed order
#     @articles = sort {$b cmp $a} @files;
#
#     # sort numerically ascending
#     @articles = sort {$a <=> $b} @files;
#
#     # sort numerically descending
#     @articles = sort {$b <=> $a} @files;
#
#     # sort using explicit subroutine name
#     sub byage {
#         $age{$a} <=> $age{$b};  # presuming integers
#     }
#     @sortedclass = sort byage @class;
#
#     # this sorts the %age associative arrays by value
#     # instead of key using an inline function
#     @eldest = sort { $age{$b} <=> $age{$a} } keys %age;
#
#     sub backwards { $b cmp $a; }
#     @harry = ('dog','cat','x','Cain','Abel');
#     @george = ('gone','chased','yz','Punished','Axed');
#     print sort @harry;
#             # prints AbelCaincatdogx
#     print sort backwards @harry;
#             # prints xdogcatCainAbel
#     print sort @george, 'to', @harry;
#             # prints AbelAxedCainPunishedcatchaseddoggonetoxyz
#
#     # inefficiently sort by descending numeric compare using
#     # the first integer after the first = sign, or the
#     # whole record case-insensitively otherwise
#     @new = sort {
#         ($b =~ /=(\d+)/)[0] <=> ($a =~ /=(\d+)/)[0]
#                             ||
#                     uc($a)  cmp  uc($b)
#     } @old;
#
#     # same thing, but much more efficiently;
#     # we'll build auxiliary indices instead
#     # for speed
#     @nums = @caps = ();
#     for (@old) {
#         push @nums, /=(\d+)/;
#         push @caps, uc($_);
#     }
#
#     @new = @old[ sort {
#                         $nums[$b] <=> $nums[$a]
#                                  ||
#                         $caps[$a] cmp $caps[$b]
#                        } 0..$#old
#                ];
#
#     # same thing using a Schwartzian Transform (no temps)
#     @new = map { $_->[0] }
#         sort { $b->[1] <=> $a->[1]
#                         ||
#                $a->[2] cmp $b->[2]
#         } map { [$_, /=(\d+)/, uc($_)] } @old;
#
# If you're and using strict, you MUST NOT declare
# $a and $b as lexicals.  They are package globals.
# That means if you're in the main package, it's
#
#     @articles = sort {$main::b <=> $main::a} @files;
#
# or just
#
#     @articles = sort {$::b <=> $::a} @files;
#
# but if you're in the FooPack package, it's
#
#     @articles = sort {$FooPack::b <=> $FooPack::a} @files;
#
#
sub sort{#(BLOCK LIST)
}
# Removes the elements designated by OFFSET and
# LENGTH from an array, and replaces them with the
# elements of LIST, if any.  Returns the elements
# removed from the array.  The array grows or
# shrinks as necessary.  If LENGTH is omitted,
# removes everything from OFFSET onward.  The
# following equivalencies hold (assuming $[ == 0):
#
#     push(@a,$x,$y)      splice(@a,$#a+1,0,$x,$y)
#     pop(@a)             splice(@a,-1)
#     shift(@a)           splice(@a,0,1)
#     unshift(@a,$x,$y)   splice(@a,0,0,$x,$y)
#     $a[$x] = $y         splice(@a,$x,1,$y);
#
# Example, assuming array lengths are passed before
# arrays:
#
#     sub aeq {   # compare two list values
#         local(@a) = splice(@_,0,shift);
#         local(@b) = splice(@_,0,shift);
#         return 0 unless @a == @b;       # same len?
#         while (@a) {
#             return 0 if pop(@a) ne pop(@b);
#         }
#         return 1;
#     }
#     if (&aeq($len,@foo[1..$len],0+@bar,@bar)) { ... }
#
#
sub splice{#(ARRAY,OFFSET)
}
# Removes the elements designated by OFFSET and
# LENGTH from an array, and replaces them with the
# elements of LIST, if any.  Returns the elements
# removed from the array.  The array grows or
# shrinks as necessary.  If LENGTH is omitted,
# removes everything from OFFSET onward.  The
# following equivalencies hold (assuming $[ == 0):
#
#     push(@a,$x,$y)      splice(@a,$#a+1,0,$x,$y)
#     pop(@a)             splice(@a,-1)
#     shift(@a)           splice(@a,0,1)
#     unshift(@a,$x,$y)   splice(@a,0,0,$x,$y)
#     $a[$x] = $y         splice(@a,$x,1,$y);
#
# Example, assuming array lengths are passed before
# arrays:
#
#     sub aeq {   # compare two list values
#         local(@a) = splice(@_,0,shift);
#         local(@b) = splice(@_,0,shift);
#         return 0 unless @a == @b;       # same len?
#         while (@a) {
#             return 0 if pop(@a) ne pop(@b);
#         }
#         return 1;
#     }
#     if (&aeq($len,@foo[1..$len],0+@bar,@bar)) { ... }
#
#
sub splice{#(ARRAY,OFFSET,LENGTH,LIST)
}
# Removes the elements designated by OFFSET and
# LENGTH from an array, and replaces them with the
# elements of LIST, if any.  Returns the elements
# removed from the array.  The array grows or
# shrinks as necessary.  If LENGTH is omitted,
# removes everything from OFFSET onward.  The
# following equivalencies hold (assuming $[ == 0):
#
#     push(@a,$x,$y)      splice(@a,$#a+1,0,$x,$y)
#     pop(@a)             splice(@a,-1)
#     shift(@a)           splice(@a,0,1)
#     unshift(@a,$x,$y)   splice(@a,0,0,$x,$y)
#     $a[$x] = $y         splice(@a,$x,1,$y);
#
# Example, assuming array lengths are passed before
# arrays:
#
#     sub aeq {   # compare two list values
#         local(@a) = splice(@_,0,shift);
#         local(@b) = splice(@_,0,shift);
#         return 0 unless @a == @b;       # same len?
#         while (@a) {
#             return 0 if pop(@a) ne pop(@b);
#         }
#         return 1;
#     }
#     if (&aeq($len,@foo[1..$len],0+@bar,@bar)) { ... }
#
#
sub splice{#(ARRAY,OFFSET,LENGTH)
}
# Splits a string into an array of strings, and
# returns it.
#
# If not in a list context, returns the number of
# fields found and splits into the @_ array.  (In a
# list context, you can force the split into @_ by
# using ?? as the pattern delimiters, but it still
# returns the array value.)  The use of implicit
# split to @_ is deprecated, however.
#
# If EXPR is omitted, splits the $_ string.  If
# PATTERN is also omitted, splits on whitespace
# (after skipping any leading whitespace).  Anything
# matching PATTERN is taken to be a delimiter
# separating the fields.  (Note that the delimiter
# may be longer than one character.)  If LIMIT is
# specified and is not negative, splits into no more
# than that many fields (though it may split into
# fewer).  If LIMIT is unspecified, trailing null
# fields are stripped (which potential users of
# pop() would do well to remember).  If LIMIT is
# negative, it is treated as if an arbitrarily large
# LIMIT had been specified.
# A pattern matching the null string (not to be
# confused with a null pattern //, which is just one
# member of the set of patterns matching a null
# string) will split the value of EXPR into separate
# characters at each point it matches that way.  For
# example:
#
#     print join(':', split(/ */, 'hi there'));
#
# produces the output 'h:i:t:h:e:r:e'.
#
# The LIMIT parameter can be used to partially split
# a line
#
#     ($login, $passwd, $remainder) = split(/:/, $_, 3);
#
# When assigning to a list, if LIMIT is omitted,
# Perl supplies a LIMIT one larger than the number
# of variables in the list, to avoid unnecessary
# work.  For the list above LIMIT would have been 4
# by default.  In time critical applications it
# behooves you not to split into more fields than
# you really need.
#
# If the PATTERN contains parentheses, additional
# array elements are created from each matching
# substring in the delimiter.
#
#     split(/([,-])/, "1-10,20");
#
# produces the list value
#
#     (1, '-', 10, ',', 20)
#
# If you had the entire header of a normal Unix
# email message in $header, you could split it up
# into fields and their values this way:
#
#     $header =~ s/\n\s+/ /g;  # fix continuation lines
#     %hdrs   =  (UNIX_FROM => split /^(.*?):\s*/m, $header);
#
# The pattern /PATTERN/ may be replaced with an
# expression to specify patterns that vary at
# runtime.  (To do runtime compilation only once,
# use /$variable/o.)
#
# As a special case, specifying a PATTERN of space
# (' ') will split on white space just as split with
# no arguments does.  Thus, split(' ') can be used
# to emulate awk's default behavior, whereas split(/
# /) will give you as many null initial fields as
# there are leading spaces.  A split on /\s+/ is
# like a split(' ') except that any leading
# whitespace produces a null first field.  A split
# with no arguments really does a split(' ', $_)
# internally.
#
# Example:
#
#     open(passwd, '/etc/passwd');
#     while (<passwd>) {
#         ($login, $passwd, $uid, $gid, $gcos,
#             $home, $shell) = split(/:/);
#         ...
#     }
#
# (Note that $shell above will still have a newline
# on it.  See the chop, chomp,  and join entries
# elsewhere in this document.)
#
sub split{#()
}
# Splits a string into an array of strings, and
# returns it.
#
# If not in a list context, returns the number of
# fields found and splits into the @_ array.  (In a
# list context, you can force the split into @_ by
# using ?? as the pattern delimiters, but it still
# returns the array value.)  The use of implicit
# split to @_ is deprecated, however.
#
# If EXPR is omitted, splits the $_ string.  If
# PATTERN is also omitted, splits on whitespace
# (after skipping any leading whitespace).  Anything
# matching PATTERN is taken to be a delimiter
# separating the fields.  (Note that the delimiter
# may be longer than one character.)  If LIMIT is
# specified and is not negative, splits into no more
# than that many fields (though it may split into
# fewer).  If LIMIT is unspecified, trailing null
# fields are stripped (which potential users of
# pop() would do well to remember).  If LIMIT is
# negative, it is treated as if an arbitrarily large
# LIMIT had been specified.
# A pattern matching the null string (not to be
# confused with a null pattern //, which is just one
# member of the set of patterns matching a null
# string) will split the value of EXPR into separate
# characters at each point it matches that way.  For
# example:
#
#     print join(':', split(/ */, 'hi there'));
#
# produces the output 'h:i:t:h:e:r:e'.
#
# The LIMIT parameter can be used to partially split
# a line
#
#     ($login, $passwd, $remainder) = split(/:/, $_, 3);
#
# When assigning to a list, if LIMIT is omitted,
# Perl supplies a LIMIT one larger than the number
# of variables in the list, to avoid unnecessary
# work.  For the list above LIMIT would have been 4
# by default.  In time critical applications it
# behooves you not to split into more fields than
# you really need.
#
# If the PATTERN contains parentheses, additional
# array elements are created from each matching
# substring in the delimiter.
#
#     split(/([,-])/, "1-10,20");
#
# produces the list value
#
#     (1, '-', 10, ',', 20)
#
# If you had the entire header of a normal Unix
# email message in $header, you could split it up
# into fields and their values this way:
#
#     $header =~ s/\n\s+/ /g;  # fix continuation lines
#     %hdrs   =  (UNIX_FROM => split /^(.*?):\s*/m, $header);
#
# The pattern /PATTERN/ may be replaced with an
# expression to specify patterns that vary at
# runtime.  (To do runtime compilation only once,
# use /$variable/o.)
#
# As a special case, specifying a PATTERN of space
# (' ') will split on white space just as split with
# no arguments does.  Thus, split(' ') can be used
# to emulate awk's default behavior, whereas split(/
# /) will give you as many null initial fields as
# there are leading spaces.  A split on /\s+/ is
# like a split(' ') except that any leading
# whitespace produces a null first field.  A split
# with no arguments really does a split(' ', $_)
# internally.
#
# Example:
#
#     open(passwd, '/etc/passwd');
#     while (<passwd>) {
#         ($login, $passwd, $uid, $gid, $gcos,
#             $home, $shell) = split(/:/);
#         ...
#     }
#
# (Note that $shell above will still have a newline
# on it.  See the chop, chomp,  and join entries
# elsewhere in this document.)
#
sub split{#(/PATTERN/,EXPR,LIMIT)
}
# Splits a string into an array of strings, and
# returns it.
#
# If not in a list context, returns the number of
# fields found and splits into the @_ array.  (In a
# list context, you can force the split into @_ by
# using ?? as the pattern delimiters, but it still
# returns the array value.)  The use of implicit
# split to @_ is deprecated, however.
#
# If EXPR is omitted, splits the $_ string.  If
# PATTERN is also omitted, splits on whitespace
# (after skipping any leading whitespace).  Anything
# matching PATTERN is taken to be a delimiter
# separating the fields.  (Note that the delimiter
# may be longer than one character.)  If LIMIT is
# specified and is not negative, splits into no more
# than that many fields (though it may split into
# fewer).  If LIMIT is unspecified, trailing null
# fields are stripped (which potential users of
# pop() would do well to remember).  If LIMIT is
# negative, it is treated as if an arbitrarily large
# LIMIT had been specified.
# A pattern matching the null string (not to be
# confused with a null pattern //, which is just one
# member of the set of patterns matching a null
# string) will split the value of EXPR into separate
# characters at each point it matches that way.  For
# example:
#
#     print join(':', split(/ */, 'hi there'));
#
# produces the output 'h:i:t:h:e:r:e'.
#
# The LIMIT parameter can be used to partially split
# a line
#
#     ($login, $passwd, $remainder) = split(/:/, $_, 3);
#
# When assigning to a list, if LIMIT is omitted,
# Perl supplies a LIMIT one larger than the number
# of variables in the list, to avoid unnecessary
# work.  For the list above LIMIT would have been 4
# by default.  In time critical applications it
# behooves you not to split into more fields than
# you really need.
#
# If the PATTERN contains parentheses, additional
# array elements are created from each matching
# substring in the delimiter.
#
#     split(/([,-])/, "1-10,20");
#
# produces the list value
#
#     (1, '-', 10, ',', 20)
#
# If you had the entire header of a normal Unix
# email message in $header, you could split it up
# into fields and their values this way:
#
#     $header =~ s/\n\s+/ /g;  # fix continuation lines
#     %hdrs   =  (UNIX_FROM => split /^(.*?):\s*/m, $header);
#
# The pattern /PATTERN/ may be replaced with an
# expression to specify patterns that vary at
# runtime.  (To do runtime compilation only once,
# use /$variable/o.)
#
# As a special case, specifying a PATTERN of space
# (' ') will split on white space just as split with
# no arguments does.  Thus, split(' ') can be used
# to emulate awk's default behavior, whereas split(/
# /) will give you as many null initial fields as
# there are leading spaces.  A split on /\s+/ is
# like a split(' ') except that any leading
# whitespace produces a null first field.  A split
# with no arguments really does a split(' ', $_)
# internally.
#
# Example:
#
#     open(passwd, '/etc/passwd');
#     while (<passwd>) {
#         ($login, $passwd, $uid, $gid, $gcos,
#             $home, $shell) = split(/:/);
#         ...
#     }
#
# (Note that $shell above will still have a newline
# on it.  See the chop, chomp,  and join entries
# elsewhere in this document.)
#
sub split{#(/PATTERN/,EXPR)
}
# Splits a string into an array of strings, and
# returns it.
#
# If not in a list context, returns the number of
# fields found and splits into the @_ array.  (In a
# list context, you can force the split into @_ by
# using ?? as the pattern delimiters, but it still
# returns the array value.)  The use of implicit
# split to @_ is deprecated, however.
#
# If EXPR is omitted, splits the $_ string.  If
# PATTERN is also omitted, splits on whitespace
# (after skipping any leading whitespace).  Anything
# matching PATTERN is taken to be a delimiter
# separating the fields.  (Note that the delimiter
# may be longer than one character.)  If LIMIT is
# specified and is not negative, splits into no more
# than that many fields (though it may split into
# fewer).  If LIMIT is unspecified, trailing null
# fields are stripped (which potential users of
# pop() would do well to remember).  If LIMIT is
# negative, it is treated as if an arbitrarily large
# LIMIT had been specified.
# A pattern matching the null string (not to be
# confused with a null pattern //, which is just one
# member of the set of patterns matching a null
# string) will split the value of EXPR into separate
# characters at each point it matches that way.  For
# example:
#
#     print join(':', split(/ */, 'hi there'));
#
# produces the output 'h:i:t:h:e:r:e'.
#
# The LIMIT parameter can be used to partially split
# a line
#
#     ($login, $passwd, $remainder) = split(/:/, $_, 3);
#
# When assigning to a list, if LIMIT is omitted,
# Perl supplies a LIMIT one larger than the number
# of variables in the list, to avoid unnecessary
# work.  For the list above LIMIT would have been 4
# by default.  In time critical applications it
# behooves you not to split into more fields than
# you really need.
#
# If the PATTERN contains parentheses, additional
# array elements are created from each matching
# substring in the delimiter.
#
#     split(/([,-])/, "1-10,20");
#
# produces the list value
#
#     (1, '-', 10, ',', 20)
#
# If you had the entire header of a normal Unix
# email message in $header, you could split it up
# into fields and their values this way:
#
#     $header =~ s/\n\s+/ /g;  # fix continuation lines
#     %hdrs   =  (UNIX_FROM => split /^(.*?):\s*/m, $header);
#
# The pattern /PATTERN/ may be replaced with an
# expression to specify patterns that vary at
# runtime.  (To do runtime compilation only once,
# use /$variable/o.)
#
# As a special case, specifying a PATTERN of space
# (' ') will split on white space just as split with
# no arguments does.  Thus, split(' ') can be used
# to emulate awk's default behavior, whereas split(/
# /) will give you as many null initial fields as
# there are leading spaces.  A split on /\s+/ is
# like a split(' ') except that any leading
# whitespace produces a null first field.  A split
# with no arguments really does a split(' ', $_)
# internally.
#
# Example:
#
#     open(passwd, '/etc/passwd');
#     while (<passwd>) {
#         ($login, $passwd, $uid, $gid, $gcos,
#             $home, $shell) = split(/:/);
#         ...
#     }
#
# (Note that $shell above will still have a newline
# on it.  See the chop, chomp,  and join entries
# elsewhere in this document.)
#
sub split{#(/PATTERN/)
}
# Returns a string formatted by the usual printf
# conventions of the C language.  See the sprintf(3)
# manpage or the printf(3) manpage on your system
# for details.  (The * character for an indirectly
# specified length is not supported, but you can get
# the same effect by interpolating a variable into
# the pattern.)  Some C libraries' implementations
# of sprintf() can dump core when fed ludicrous
# arguments.
#
sub sprintf{#(FORMAT,LIST)
}
# Return the square root of EXPR.  If EXPR is
# omitted, returns square root of $_.
#
sub sqrt{#(EXPR)
}
# Sets the random number seed for the rand operator.
# If EXPR is omitted, does srand(time).  Many folks
# use an explicit srand(time ^ $$) instead.  Of
# course, you'd need something much more random than
# that for cryptographic purposes, since it's easy
# to guess the current time.  Checksumming the
# compressed output of rapidly changing operating
# system status programs is the usual method.
# Examples are posted regularly to the
# comp.security.unix newsgroup.
#
sub srand{#(EXPR)
}
# Returns a 13-element array giving the status info
# for a file, either the file opened via FILEHANDLE,
# or named by EXPR.  Returns a null list if the stat
# fails.  Typically used as follows:
#
#     ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
#        $atime,$mtime,$ctime,$blksize,$blocks)
#            = stat($filename);
# Not all fields are supported on all filesystem
# types.  Here are the meaning of the fields:
#
#   dev       device number of filesystem
#   ino       inode number
#   mode      file mode  (type and permissions)
#   nlink     number of (hard) links to the file
#   uid       numeric user ID of file's owner
#   gid       numer group ID of file's owner
#   rdev      the device identifier (special files only)
#   size      total size of file, in bytes
#   atime     last access time since the epoch
#   mtime     last modify time since the epoch
#   ctime     inode change time (NOT creation type!) since the epoch
#   blksize   preferred blocksize for file system I/O
#   blocks    actual number of blocks allocated
#
# (The epoch was at 00:00 January 1, 1970 GMT.)
#
# If stat is passed the special filehandle
# consisting of an underline, no stat is done, but
# the current contents of the stat structure from
# the last stat or filetest are returned.  Example:
#
#     if (-x $file && (($d) = stat(_)) && $d < 0) {
#         print "$file is executable NFS file\n";
#     }
#
# (This only works on machines for which the device
# number is negative under NFS.)
#
sub stat{#(EXPR)
}
# Returns a 13-element array giving the status info
# for a file, either the file opened via FILEHANDLE,
# or named by EXPR.  Returns a null list if the stat
# fails.  Typically used as follows:
#
#     ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
#        $atime,$mtime,$ctime,$blksize,$blocks)
#            = stat($filename);
# Not all fields are supported on all filesystem
# types.  Here are the meaning of the fields:
#
#   dev       device number of filesystem
#   ino       inode number
#   mode      file mode  (type and permissions)
#   nlink     number of (hard) links to the file
#   uid       numeric user ID of file's owner
#   gid       numer group ID of file's owner
#   rdev      the device identifier (special files only)
#   size      total size of file, in bytes
#   atime     last access time since the epoch
#   mtime     last modify time since the epoch
#   ctime     inode change time (NOT creation type!) since the epoch
#   blksize   preferred blocksize for file system I/O
#   blocks    actual number of blocks allocated
#
# (The epoch was at 00:00 January 1, 1970 GMT.)
#
# If stat is passed the special filehandle
# consisting of an underline, no stat is done, but
# the current contents of the stat structure from
# the last stat or filetest are returned.  Example:
#
#     if (-x $file && (($d) = stat(_)) && $d < 0) {
#         print "$file is executable NFS file\n";
#     }
#
# (This only works on machines for which the device
# number is negative under NFS.)
#
sub stat{#(FILEHANDLE)
}
# Takes extra time to study SCALAR ($_ if
# unspecified) in anticipation of doing many pattern
# matches on the string before it is next modified.
# This may or may not save time, depending on the
# nature and number of patterns you are searching
# on, and on the distribution of character
# frequencies in the string to be searched--you
# probably want to compare runtimes with and without
# it to see which runs faster.  Those loops which
# scan for many short constant strings (including
# the constant parts of more complex patterns) will
# benefit most.  You may have only one study active
# at a time--if you study a different scalar the
# first is "unstudied".  (The way study works is
# this: a linked list of every character in the
# string to be searched is made, so we know, for
# example, where all the 'k' characters are.  From
# each search string, the rarest character is
# selected, based on some static frequency tables
# constructed from some C programs and English text.
# Only those places that contain this "rarest"
# character are examined.)
#
# For example, here is a loop which inserts index
# producing entries before any line containing a
# certain pattern:
#
#     while (<>) {
#         study;
#         print ".IX foo\n" if /\bfoo\b/;
#         print ".IX bar\n" if /\bbar\b/;
#         print ".IX blurfl\n" if /\bblurfl\b/;
#         ...
#         print;
#     }
#
# In searching for /\bfoo\b/, only those locations
# in $_ that contain "f" will be looked at, because
# "f" is rarer than "o".  In general, this is a big
# win except in pathological cases.  The only
# question is whether it saves you more time than it
# took to build the linked list in the first place.
#
# Note that if you have to look for strings that you
# don't know till runtime, you can build an entire
# loop as a string and eval that to avoid
# recompiling all your patterns all the time.
# Together with undefining $/ to input entire files
# as one record, this can be very fast, often faster
# than specialized programs like fgrep(1).  The
# following scans a list of files (@files) for a
# list of words (@words), and prints out the names
# of those files that contain a match:
#
#     $search = 'while (<>) { study;';
#     foreach $word (@words) {
#         $search .= "++\$seen{\$ARGV} if /\\b$word\\b/;\n";
#     }
#     $search .= "}";
#     @ARGV = @files;
#     undef $/;
#     eval $search;               # this screams
#     $/ = "\n";          # put back to normal input delim
#     foreach $file (sort keys(%seen)) {
#         print $file, "\n";
#     }
#
#
sub study{#()
}
# Takes extra time to study SCALAR ($_ if
# unspecified) in anticipation of doing many pattern
# matches on the string before it is next modified.
# This may or may not save time, depending on the
# nature and number of patterns you are searching
# on, and on the distribution of character
# frequencies in the string to be searched--you
# probably want to compare runtimes with and without
# it to see which runs faster.  Those loops which
# scan for many short constant strings (including
# the constant parts of more complex patterns) will
# benefit most.  You may have only one study active
# at a time--if you study a different scalar the
# first is "unstudied".  (The way study works is
# this: a linked list of every character in the
# string to be searched is made, so we know, for
# example, where all the 'k' characters are.  From
# each search string, the rarest character is
# selected, based on some static frequency tables
# constructed from some C programs and English text.
# Only those places that contain this "rarest"
# character are examined.)
#
# For example, here is a loop which inserts index
# producing entries before any line containing a
# certain pattern:
#
#     while (<>) {
#         study;
#         print ".IX foo\n" if /\bfoo\b/;
#         print ".IX bar\n" if /\bbar\b/;
#         print ".IX blurfl\n" if /\bblurfl\b/;
#         ...
#         print;
#     }
#
# In searching for /\bfoo\b/, only those locations
# in $_ that contain "f" will be looked at, because
# "f" is rarer than "o".  In general, this is a big
# win except in pathological cases.  The only
# question is whether it saves you more time than it
# took to build the linked list in the first place.
#
# Note that if you have to look for strings that you
# don't know till runtime, you can build an entire
# loop as a string and eval that to avoid
# recompiling all your patterns all the time.
# Together with undefining $/ to input entire files
# as one record, this can be very fast, often faster
# than specialized programs like fgrep(1).  The
# following scans a list of files (@files) for a
# list of words (@words), and prints out the names
# of those files that contain a match:
#
#     $search = 'while (<>) { study;';
#     foreach $word (@words) {
#         $search .= "++\$seen{\$ARGV} if /\\b$word\\b/;\n";
#     }
#     $search .= "}";
#     @ARGV = @files;
#     undef $/;
#     eval $search;               # this screams
#     $/ = "\n";          # put back to normal input delim
#     foreach $file (sort keys(%seen)) {
#         print $file, "\n";
#     }
#
#
sub study{#(SCALAR)
}
# This is subroutine definition, not a real function
# per se.  With just a NAME (and possibly
# prototypes), it's just a forward declaration.
# Without a NAME, it's an anonymous function
# declaration, and does actually return a value: the
# CODE ref of the closure you just created. See the
# perlsub manpage and the perlref manpage for
# details.
#
sub sub{#(NAME BLOCK)
}
# This is subroutine definition, not a real function
# per se.  With just a NAME (and possibly
# prototypes), it's just a forward declaration.
# Without a NAME, it's an anonymous function
# declaration, and does actually return a value: the
# CODE ref of the closure you just created. See the
# perlsub manpage and the perlref manpage for
# details.
#
sub sub{#(BLOCK)
}
# This is subroutine definition, not a real function
# per se.  With just a NAME (and possibly
# prototypes), it's just a forward declaration.
# Without a NAME, it's an anonymous function
# declaration, and does actually return a value: the
# CODE ref of the closure you just created. See the
# perlsub manpage and the perlref manpage for
# details.
#
sub sub{#(NAME)
}
# Extracts a substring out of EXPR and returns it.
# First character is at offset 0, or whatever you've
# set $[ to.  If OFFSET is negative, starts that far
# from the end of the string.  If LEN is omitted,
# returns everything to the end of the string.  If
# LEN is negative, leaves that many characters off
# the end of the string.
#
# You can use the substr() function as an lvalue, in
# which case EXPR must be an lvalue.  If you assign
# something shorter than LEN, the string will
# shrink, and if you assign something longer than
# LEN, the string will grow to accommodate it.  To
# keep the string the same length you may need to
# pad or chop your value using sprintf().
#
sub substr{#(EXPR,OFFSET)
}
# Extracts a substring out of EXPR and returns it.
# First character is at offset 0, or whatever you've
# set $[ to.  If OFFSET is negative, starts that far
# from the end of the string.  If LEN is omitted,
# returns everything to the end of the string.  If
# LEN is negative, leaves that many characters off
# the end of the string.
#
# You can use the substr() function as an lvalue, in
# which case EXPR must be an lvalue.  If you assign
# something shorter than LEN, the string will
# shrink, and if you assign something longer than
# LEN, the string will grow to accommodate it.  To
# keep the string the same length you may need to
# pad or chop your value using sprintf().
#
sub substr{#(EXPR,OFFSET,LEN)
}
# Creates a new filename symbolically linked to the
# old filename.  Returns 1 for success, 0 otherwise.
# On systems that don't support symbolic links,
# produces a fatal error at run time.  To check for
# that, use eval:
#
#     $symlink_exists = (eval 'symlink("","");', $@ eq '');
#
#
sub symlink{#(OLDFILE,NEWFILE)
}
# Calls the system call specified as the first
# element of the list, passing the remaining
# elements as arguments to the system call.  If
# unimplemented, produces a fatal error.  The
# arguments are interpreted as follows: if a given
# argument is numeric, the argument is passed as an
# int.  If not, the pointer to the string value is
# passed.  You are responsible to make sure a string
# is pre-extended long enough to receive any result
# that might be written into a string.  If your
# integer arguments are not literals and have never
# been interpreted in a numeric context, you may
# need to add 0 to them to force them to look like
# numbers.
#
#     require 'syscall.ph';               # may need to run h2ph
#     syscall(&SYS_write, fileno(STDOUT), "hi there\n", 9);
# Note that Perl only supports passing of up to 14
# arguments to your system call, which in practice
# should usually suffice.
#
sub syscall{#(LIST)
}
# Opens the file whose filename is given by
# FILENAME, and associates it with FILEHANDLE.  If
# FILEHANDLE is an expression, its value is used as
# the name of the real filehandle wanted.  This
# function calls the underlying operating system's
# open function with the parameters FILENAME, MODE,
# PERMS.
#
# The possible values and flag bits of the MODE
# parameter are system-dependent; they are available
# via the standard module Fcntl.  However, for
# historical reasons, some values are universal:
# zero means read-only, one means write-only, and
# two means read/write.
#
# If the file named by FILENAME does not exist and
# the open call creates it (typically because MODE
# includes the O_CREAT flag), then the value of
# PERMS specifies the permissions of the newly
# created file.  If PERMS is omitted, the default
# value is 0666, which allows read and write for
# all.  This default is reasonable: see umask.
#
sub sysopen{#(FILEHANDLE,FILENAME,MODE,PERMS)
}
# Opens the file whose filename is given by
# FILENAME, and associates it with FILEHANDLE.  If
# FILEHANDLE is an expression, its value is used as
# the name of the real filehandle wanted.  This
# function calls the underlying operating system's
# open function with the parameters FILENAME, MODE,
# PERMS.
#
# The possible values and flag bits of the MODE
# parameter are system-dependent; they are available
# via the standard module Fcntl.  However, for
# historical reasons, some values are universal:
# zero means read-only, one means write-only, and
# two means read/write.
#
# If the file named by FILENAME does not exist and
# the open call creates it (typically because MODE
# includes the O_CREAT flag), then the value of
# PERMS specifies the permissions of the newly
# created file.  If PERMS is omitted, the default
# value is 0666, which allows read and write for
# all.  This default is reasonable: see umask.
#
sub sysopen{#(FILEHANDLE,FILENAME,MODE)
}
# Attempts to read LENGTH bytes of data into
# variable SCALAR from the specified FILEHANDLE,
# using the system call read(2).  It bypasses stdio,
# so mixing this with other kinds of reads may cause
# confusion.  Returns the number of bytes actually
# read, or undef if there was an error.  SCALAR will
# be grown or shrunk to the length actually read.
# An OFFSET may be specified to place the read data
# at some other place than the beginning of the
# string.
#
sub sysread{#(FILEHANDLE,SCALAR,LENGTH)
}
# Attempts to read LENGTH bytes of data into
# variable SCALAR from the specified FILEHANDLE,
# using the system call read(2).  It bypasses stdio,
# so mixing this with other kinds of reads may cause
# confusion.  Returns the number of bytes actually
# read, or undef if there was an error.  SCALAR will
# be grown or shrunk to the length actually read.
# An OFFSET may be specified to place the read data
# at some other place than the beginning of the
# string.
#
sub sysread{#(FILEHANDLE,SCALAR,LENGTH,OFFSET)
}
# Does exactly the same thing as "exec LIST" except
# that a fork is done first, and the parent process
# waits for the child process to complete.  Note
# that argument processing varies depending on the
# number of arguments.  The return value is the exit
# status of the program as returned by the wait()
# call.  To get the actual exit value divide by 256.
# See also the exec entry elsewhere in this
# document.  This is NOT what you want to use to
# capture the output from a command, for that you
# should merely use backticks, as described in the
# section on `STRING` in the perlop manpage.
#
sub system{#(LIST)
}
# Attempts to write LENGTH bytes of data from
# variable SCALAR to the specified FILEHANDLE, using
# the system call write(2).  It bypasses stdio, so
# mixing this with prints may cause confusion.
# Returns the number of bytes actually written, or
# undef if there was an error.  An OFFSET may be
# specified to get the write data from some other
# place than the beginning of the string.
#
sub syswrite{#(FILEHANDLE,SCALAR,LENGTH)
}
# Attempts to write LENGTH bytes of data from
# variable SCALAR to the specified FILEHANDLE, using
# the system call write(2).  It bypasses stdio, so
# mixing this with prints may cause confusion.
# Returns the number of bytes actually written, or
# undef if there was an error.  An OFFSET may be
# specified to get the write data from some other
# place than the beginning of the string.
#
sub syswrite{#(FILEHANDLE,SCALAR,LENGTH,OFFSET)
}
# Returns the current file position for FILEHANDLE.
# FILEHANDLE may be an expression whose value gives
# the name of the actual filehandle.  If FILEHANDLE
# is omitted, assumes the file last read.
#
sub tell{#()
}
# Returns the current file position for FILEHANDLE.
# FILEHANDLE may be an expression whose value gives
# the name of the actual filehandle.  If FILEHANDLE
# is omitted, assumes the file last read.
#
sub tell{#(FILEHANDLE)
}
# Returns the current position of the readdir()
# routines on DIRHANDLE.  Value may be given to
# seekdir() to access a particular location in a
# directory.  Has the same caveats about possible
# directory compaction as the corresponding system
# library routine.
#
sub telldir{#(DIRHANDLE)
}
# This function binds a variable to a package class
# that will provide the implementation for the
# variable.  VARIABLE is the name of the variable to
# be enchanted.  CLASSNAME is the name of a class
# implementing objects of correct type.  Any
# additional arguments are passed to the "new"
# method of the class (meaning TIESCALAR, TIEARRAY,
# or TIEHASH).  Typically these are arguments such
# as might be passed to the dbm_open() function of
# C.  The object returned by the "new" method is
# also returned by the tie() function, which would
# be useful if you want to access other methods in
# CLASSNAME.
#
# Note that functions such as keys() and values()
# may return huge array values when used on large
# objects, like DBM files.  You may prefer to use
# the each() function to iterate over such.
# Example:
#     # print out history file offsets
#     use NDBM_File;
#     tie(%HIST, NDBM_File, '/usr/lib/news/history', 1, 0);
#     while (($key,$val) = each %HIST) {
#         print $key, ' = ', unpack('L',$val), "\n";
#     }
#     untie(%HIST);
#
# A class implementing an associative array should
# have the following methods:
#
#     TIEHASH classname, LIST
#     DESTROY this
#     FETCH this, key
#     STORE this, key, value
#     DELETE this, key
#     EXISTS this, key
#     FIRSTKEY this
#     NEXTKEY this, lastkey
#
# A class implementing an ordinary array should have
# the following methods:
#
#     TIEARRAY classname, LIST
#     DESTROY this
#     FETCH this, key
#     STORE this, key, value
#     [others TBD]
#
# A class implementing a scalar should have the
# following methods:
#
#     TIESCALAR classname, LIST
#     DESTROY this
#     FETCH this,
#     STORE this, value
#
# Unlike dbmopen(), the tie() function will not use
# or require a module for you--you need to do that
# explicitly yourself.  See the DB_File manpage or
# the Config module for interesting tie()
# implementations.
#
sub tie{#(VARIABLE,CLASSNAME,LIST)
}
# Returns a reference to the object underlying
# VARIABLE (the same value that was originally
# returned by the tie() call which bound the
# variable to a package.)  Returns the undefined
# value if VARIABLE isn't tied to a package.
#
sub tied{#(VARIABLE)
}
# Returns the number of non-leap seconds since
# 00:00:00 UTC, January 1, 1970.  Suitable for
# feeding to gmtime() and localtime().
sub time{#()
}
# Returns a four-element array giving the user and
# system times, in seconds, for this process and the
# children of this process.
#
#     ($user,$system,$cuser,$csystem) = times;
#
#
sub times{#()
}
# Truncates the file opened on FILEHANDLE, or named
# by EXPR, to the specified length.  Produces a
# fatal error if truncate isn't implemented on your
# system.
#
sub truncate{#(EXPR,LENGTH)
}
# Truncates the file opened on FILEHANDLE, or named
# by EXPR, to the specified length.  Produces a
# fatal error if truncate isn't implemented on your
# system.
#
sub truncate{#(FILEHANDLE,LENGTH)
}
# the internal function implementing the \U escape
# in double-quoted strings.  Should respect any
# POSIX setlocale() settings.
#
sub uc{#(EXPR Returns an uppercased version of EXPR.  This is)
}
# Returns the value of EXPR with the first character
# uppercased.  This is the internal function
# implementing the \u escape in double-quoted
# strings.  Should respect any POSIX setlocale()
# settings.
#
sub ucfirst{#(EXPR)
}
# Sets the umask for the process and returns the old
# one.  If EXPR is omitted, merely returns current
# umask.
#
sub umask{#()
}
# Sets the umask for the process and returns the old
# one.  If EXPR is omitted, merely returns current
# umask.
#
sub umask{#(EXPR)
}
# Undefines the value of EXPR, which must be an
# lvalue.  Use only on a scalar value, an entire
# array, or a subroutine name (using "&").  (Using
# undef() will probably not do what you expect on
# most predefined variables or DBM list values, so
# don't do that.)  Always returns the undefined
# value.  You can omit the EXPR, in which case
# nothing is undefined, but you still get an
# undefined value that you could, for instance,
# return from a subroutine.  Examples:
#
#     undef $foo;
#     undef $bar{'blurfl'};
#     undef @ary;
#     undef %assoc;
#     undef &mysub;
#     return (wantarray ? () : undef) if $they_blew_it;
sub undef{#()
}
# Undefines the value of EXPR, which must be an
# lvalue.  Use only on a scalar value, an entire
# array, or a subroutine name (using "&").  (Using
# undef() will probably not do what you expect on
# most predefined variables or DBM list values, so
# don't do that.)  Always returns the undefined
# value.  You can omit the EXPR, in which case
# nothing is undefined, but you still get an
# undefined value that you could, for instance,
# return from a subroutine.  Examples:
#
#     undef $foo;
#     undef $bar{'blurfl'};
#     undef @ary;
#     undef %assoc;
#     undef &mysub;
#     return (wantarray ? () : undef) if $they_blew_it;
sub undef{#(EXPR)
}
# Deletes a list of files.  Returns the number of
# files successfully deleted.
#
#     $cnt = unlink 'a', 'b', 'c';
#     unlink @goners;
#     unlink <*.bak>;
#
# Note: unlink will not delete directories unless
# you are superuser and the -U flag is supplied to
# Perl.  Even if these conditions are met, be warned
# that unlinking a directory can inflict damage on
# your filesystem.  Use rmdir instead.
#
sub unlink{#(LIST)
}
# Unpack does the reverse of pack: it takes a string
# representing a structure and expands it out into a
# list value, returning the array value.  (In a
# scalar context, it merely returns the first value
# produced.)  The TEMPLATE has the same format as in
# the pack function.  Here's a subroutine that does
# substring:
#
#     sub substr {
#         local($what,$where,$howmuch) = @_;
#         unpack("x$where a$howmuch", $what);
#     }
#
# and then there's
#
#     sub ordinal { unpack("c",$_[0]); } # same as ord()
#
# In addition, you may prefix a field with a
# %<number> to indicate that you want a <number>-bit
# checksum of the items instead of the items
# themselves.  Default is a 16-bit checksum.  For
# example, the following computes the same number as
# the System V sum program:
#
#     while (<>) {
#         $checksum += unpack("%16C*", $_);
#     }
#     $checksum %= 65536;
#
# The following efficiently counts the number of set
# bits in a bit vector:
#
#     $setbits = unpack("%32b*", $selectmask);
#
#
sub unpack{#(TEMPLATE,EXPR)
}
# Breaks the binding between a variable and a
# package.  (See tie().)
sub untie{#(VARIABLE)
}
# Does the opposite of a shift.  Or the opposite of
# a push, depending on how you look at it.  Prepends
# list to the front of the array, and returns the
# new number of elements in the array.
#
#     unshift(ARGV, '-e') unless $ARGV[0] =~ /^-/;
#
# Note the LIST is prepended whole, not one element
# at a time, so the prepended elements stay in the
# same order.  Use reverse to do the reverse.
#
sub unshift{#(ARRAY,LIST)
}
# Changes the access and modification times on each
# file of a list of files.  The first two elements
# of the list must be the NUMERICAL access and
# modification times, in that order.  Returns the
# number of files successfully changed.  The inode
# modification time of each file is set to the
# current time.  Example of a "touch" command:
#
#     #!/usr/bin/perl
#     $now = time;
#     utime $now, $now, @ARGV;
#
#
sub utime{#(LIST)
}
# Returns a normal array consisting of all the
# values of the named associative array.  (In a
# scalar context, returns the number of values.)
# The values are returned in an apparently random
# order, but it is the same order as either the
# keys() or each() function would produce on the
# same array.  See also keys(), each(), and sort().
#
sub values{#(ASSOC_ARRAY)
}
# Treats the string in EXPR as a vector of unsigned
# integers, and returns the value of the bitfield
# specified by OFFSET.  BITS specifies the number of
# bits that are reserved for each entry in the bit
# vector. This must be a power of two from 1 to 32.
# vec() may also be assigned to, in which case
# parens are needed to give the expression the
# correct precedence as in
#
#     vec($image, $max_x * $x + $y, 8) = 3;
#
# Vectors created with vec() can also be manipulated
# with the logical operators |, & and ^, which will
# assume a bit vector operation is desired when both
# operands are strings.
# To transform a bit vector into a string or array
# of 0's and 1's, use these:
#
#     $bits = unpack("b*", $vector);
#     @bits = split(//, unpack("b*", $vector));
#
# If you know the exact length in bits, it can be
# used in place of the *.
#
sub vec{#(EXPR,OFFSET,BITS)
}
# Waits for a child process to terminate and returns
# the pid of the deceased process, or -1 if there
# are no child processes.  The status is returned in
# $?.
#
sub wait{#()
}
# Waits for a particular child process to terminate
# and returns the pid of the deceased process, or -1
# if there is no such child process.  The status is
# returned in $?.  If you say
#
#     use POSIX "wait_h";
#     ...
#     waitpid(-1,&WNOHANG);
#
# then you can do a non-blocking wait for any
# process.  Non-blocking wait is only available on
# machines supporting either the waitpid(2) or
# wait4(2) system calls.  However, waiting for a
# particular pid with FLAGS of 0 is implemented
# everywhere.  (Perl emulates the system call by
# remembering the status values of processes that
# have exited but have not been harvested by the
# Perl script yet.)
#
sub waitpid{#(PID,FLAGS)
}
# Returns TRUE if the context of the currently
# executing subroutine is looking for a list value.
# Returns FALSE if the context is looking for a
# scalar.
#
#     return wantarray ? () : undef;
#
#
sub wantarray{#()
}
# Produces a message on STDERR just like die(), but
# doesn't exit or on an exception.
#
sub warn{#(LIST)
}
# Writes a formatted record (possibly multi-line) to
# the specified file, using the format associated
# with that file.  By default the format for a file
# is the one having the same name is the filehandle,
# but the format for the current output channel (see
# the select() function) may be set explicitly by
# assigning the name of the format to the $~
# variable.
#
# Top of form processing is handled automatically:
# if there is insufficient room on the current page
# for the formatted record, the page is advanced by
# writing a form feed, a special top-of-page format
# is used to format the new page header, and then
# the record is written.  By default the top-of-page
# format is the name of the filehandle with "_TOP"
# appended, but it may be dynamically set to the
# format of your choice by assigning the name to the
# $^ variable while the filehandle is selected.  The
# number of lines remaining on the current page is
# in variable $-, which can be set to 0 to force a
# new page.
#
# If FILEHANDLE is unspecified, output goes to the
# current default output channel, which starts out
# as STDOUT but may be changed by the select
# operator.  If the FILEHANDLE is an EXPR, then the
# expression is evaluated and the resulting string
# is used to look up the name of the FILEHANDLE at
# run time.  For more on formats, see the perlform
# manpage.
#
# Note that write is NOT the opposite of read.
# Unfortunately.
#
sub write{#()
}
# Writes a formatted record (possibly multi-line) to
# the specified file, using the format associated
# with that file.  By default the format for a file
# is the one having the same name is the filehandle,
# but the format for the current output channel (see
# the select() function) may be set explicitly by
# assigning the name of the format to the $~
# variable.
#
# Top of form processing is handled automatically:
# if there is insufficient room on the current page
# for the formatted record, the page is advanced by
# writing a form feed, a special top-of-page format
# is used to format the new page header, and then
# the record is written.  By default the top-of-page
# format is the name of the filehandle with "_TOP"
# appended, but it may be dynamically set to the
# format of your choice by assigning the name to the
# $^ variable while the filehandle is selected.  The
# number of lines remaining on the current page is
# in variable $-, which can be set to 0 to force a
# new page.
#
# If FILEHANDLE is unspecified, output goes to the
# current default output channel, which starts out
# as STDOUT but may be changed by the select
# operator.  If the FILEHANDLE is an EXPR, then the
# expression is evaluated and the resulting string
# is used to look up the name of the FILEHANDLE at
# run time.  For more on formats, see the perlform
# manpage.
#
# Note that write is NOT the opposite of read.
# Unfortunately.
#
sub write{#(FILEHANDLE)
}
# Writes a formatted record (possibly multi-line) to
# the specified file, using the format associated
# with that file.  By default the format for a file
# is the one having the same name is the filehandle,
# but the format for the current output channel (see
# the select() function) may be set explicitly by
# assigning the name of the format to the $~
# variable.
#
# Top of form processing is handled automatically:
# if there is insufficient room on the current page
# for the formatted record, the page is advanced by
# writing a form feed, a special top-of-page format
# is used to format the new page header, and then
# the record is written.  By default the top-of-page
# format is the name of the filehandle with "_TOP"
# appended, but it may be dynamically set to the
# format of your choice by assigning the name to the
# $^ variable while the filehandle is selected.  The
# number of lines remaining on the current page is
# in variable $-, which can be set to 0 to force a
# new page.
#
# If FILEHANDLE is unspecified, output goes to the
# current default output channel, which starts out
# as STDOUT but may be changed by the select
# operator.  If the FILEHANDLE is an EXPR, then the
# expression is evaluated and the resulting string
# is used to look up the name of the FILEHANDLE at
# run time.  For more on formats, see the perlform
# manpage.
#
# Note that write is NOT the opposite of read.
# Unfortunately.
#
sub write{#(EXPR)
}
