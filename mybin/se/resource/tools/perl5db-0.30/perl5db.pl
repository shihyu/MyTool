# perl5db.pl
# 
# Modified version of PerlDB.pl, for use with the ActiveState
# debugger protocol, DBGp
# See http://aspn.activestate.com/ASPN/DBGP for more info.
#
# Copyright (c) 1998-2006 ActiveState Software Inc.
# All rights reserved.
# 
# This software (the Perl-DBGP package) is covered by the Artistic License
# (http://www.opensource.org/licenses/artistic-license.php).


# Start with some lengthy, unattributed comments from perl5db.pl

=head2 REMOTE DEBUGGING

Copy the following files from a Komodo installation to
the target system

    <Komodo InstallDir>/perllib/* <TargetDir>

Set the following shell variables.  On Windows use C<set>
instead of C<export>, use double-quoting instead of
single-quoting, and use backslashes instead of forward-slashes.

    export PERLDB_OPTS=RemotePort=hostname:port
    export PERL5DB='BEGIN { require q(<TargetDir>/perl5db.pl) }'
    export PERL5LIB=<TargetDir>
    export DBGP_IDEKEY="username"

=cut

=head2 FLAGS, FLAGS, FLAGS

There is a certain C programming legacy in the debugger. Some variables,
such as C<$single>, C<$trace>, and C<$frame>, have "magical" values composed
of 1, 2, 4, etc. (powers of 2) OR'ed together. This allows several pieces
of state to be stored independently in a single scalar. 

=head4 C<$signal>

Used to track whether or not an C<INT> signal has been detected. C<DB::DB()>,
which is called before every statement, checks this and puts the user into
command mode if it finds C<$signal> set to a true value.

=head4 C<$single>

Controls behavior during single-stepping. Stacked in C<@stack> on entry to
each subroutine; popped again at the end of each subroutine.

=over 4 

=item * 0 - run continuously.

=item * 1 - single-step, go into subs. The 's' command.

=item * 2 - single-step, don't go into subs. The 'n' command.

=item * 4 - print current sub depth (turned on to force this when "too much
recursion" occurs.

=back

=head4 C<@saved>

Saves important globals (C<$@>, C<$!>, C<$^E>, C<$,>, C<$/>, C<$\>, C<$^W>)
so that the debugger can substitute safe values while it's running, and
restore them when it returns control.

=head4 C<@stack>

Saves the current value of C<$single> on entry to a subroutine.
Manipulated by the C<c> command to turn off tracing in all subs above the
current one.

=head4 C<%dbline>

Keys are line numbers, values are "condition\0action". If used in numeric
context, values are 0 if not breakable, 1 if breakable, no matter what is
in the actual hash entry.

=cut

=head1 DEBUGGER INITIALIZATION

The debugger\'s initialization actually jumps all over the place inside this
package. This is because there are several BEGIN blocks (which of course 
execute immediately) spread through the code. Why is that? 

The debugger needs to be able to change some things and set some things up 
before the debugger code is compiled; most notably, the C<$deep> variable that
C<DB::sub> uses to tell when a program has recursed deeply. In addition, the
debugger has to turn off warnings while the debugger code is compiled, but then
restore them to their original setting before the program being debugged begins
executing.

The first C<BEGIN> block simply turns off warnings by saving the current
setting of C<$^W> and then setting it to zero. The second one initializes
the debugger variables that are needed before the debugger begins executing.
The third one puts C<$^X> back to its former value. 

We'll detail the second C<BEGIN> block later; just remember that if you need
to initialize something before the debugger starts really executing, that's
where it has to go.

=cut

package DB;

sub DB {}

# 'my' variables used here could leak into (that is, be visible in)
# the context that the code being evaluated is executing in. This means that
# the code could modify the debugger's variables.
#
# Fiddling with the debugger's context could be Bad. We insulate things as
# much as we can.

sub eval {

    # 'my' would make it visible from user code
    #    but so does local! --tchrist  
    # Remember: this localizes @DB::res, not @main::res.
    local @res;
    {
        # Try to keep the user code from messing  with us. Save these so that 
        # even if the eval'ed code changes them, we can put them back again. 
        # Needed because the user could refer directly to the debugger's 
        # package globals (and any 'my' variables in this containing scope)
        # inside the eval(), and we want to try to stay safe.
        local $otrace  = $trace; 
        local $osingle = $single;
        local $od      = $^D;
	local ($^W) = 0;    # Switch run-time warnings off during eval.

        # Untaint the incoming eval() argument.
        { ($evalarg) = $evalarg =~ /(.*)/s; }

        # $usercontext built in DB::DB near the comment 
        # "set up the context for DB::eval ..."
        # Evaluate and save any results.

	# Do this in case there are user args in the expression --
	# pull them from the user's context.
	local @_;  # Clear each time.
	local @unused = caller($stackDepth + 2);
	if ($unused[3] eq 'DB::DB') {
	    # dblog("DB::eval -- caller($stackDepth + 2) => something in DB:DB, moving up one level");
	    @unused = caller($stackDepth + 3);
	}
	if ($unused[4]) {
	    # hasargs field is set -- an instance of @_ was set up.
	    eval { @_ = @DB::args; };
	    @_ = () if $@;
	}
	if ($interact) {
	    # Export the special pattern vars out of the eval's lexical
	    # context by saving in the var @DB::interact_pvs
	    
	    my $___kodb___saveCode = "\@DB::interact_pvs = map { defined \$-[\$_] ? \${\$_} : undef } (1 .. \$#-);push \@DB::interact_pvs, \$`, \$'";
	    my $___kodb___cmd = "$usercontext do { my \@thisRes=$evalarg ; $___kodb___saveCode; \@thisRes }";
	    if ($interact_str && $interact_ptn) {
		# Restore the pattern-vars by matching the string we set
		# up on the last interaction with the pattern we set up.
		$interact_str =~ qr/$interact_ptn/;
		@res = eval "$usercontext $___kodb___cmd\n"; # '\n' for nice recursive debug
	    } else {
		@res = eval "$usercontext $___kodb___cmd\n";
	    }
	    if ($@ || index($res[0], substr($___kodb___saveCode, 0, -10)) >= 0) {
		@res = eval "$usercontext $evalarg;\n";
	    } else {
		# Write the saved pattern-var info into strings to match
		# next time we're here to restore the special pattern vars
		# in this lexical context.
		$interact_str = $DB::interact_pvs[-2] || "";
		$interact_ptn = "";
		foreach my $pv (@DB::interact_pvs[0 .. $#DB::interact_pvs - 2]) {
		    if (length $pv) {
			$interact_str .= $pv;
			$interact_ptn .= "(" . quotemeta($pv) . ")";
		    } else {
			$interact_str .= "";
			# This pattern always succeeds, but leaves an
			# undefined pattern var.  Exactly what we want.
			$interact_ptn .= "((?=x)(?=y))?"; #optional failure
		    }
		}
		$interact_ptn = ".?" unless length $interact_ptn;
		$interact_str .= $DB::interact_pvs[-1] if $DB::interact_pvs[-1];
	    }
	} else {
	    @res = eval "$usercontext $evalarg;\n"; # '\n' for nice recursive debug
	}
	if (!$@ && scalar @res == 1 && !defined $res[0]) {
	    $res[0] = '';
	}

	if ($ldebug) {
	    if ($@) {
		dblog("eval($evalarg) => exception [$@]\n");
	    } elsif (scalar @res) {
		if (substr($evalarg, 0, 1) eq '%') {
		    dblog("eval($evalarg) => [hash val]\n");
		} elsif (scalar @res == 1 && ! defined $res[0]) {
		    dblog("eval($evalarg) => (undef)\n");
		    @res = ("");
		} else {
		    my $str_out = join('', @res);
		    my $max_len = $settings{max_data}[0];
		    $max_len = 103 if $max_len > 103;
		    if (length($str_out) > $max_len) {
			$str_out = substr($str_out, 0, $max_len - 3) . '...';
		    }
		    $str_out = nonXmlChar_Encode($str_out) unless ref $str_out;
		    dblog("eval($evalarg) => <<$str_out>>\n");
		}
	    } else {
		dblog("eval($evalarg) => no value\n");
		$DB::no_value = 1;
		@res = ("");
	    }
	} elsif (scalar @res == 1 && ! defined $res[0]) {
	    @res = ("");
	}

        # Restore those old values.
        $trace  = $otrace;
        $single = $osingle;
        $^D     = $od;
    }

    # Save the current value of $@, and preserve it in the debugger's copy
    # of the saved precious globals.
    my $at = $@;

    # Since we're only saving $@, we only have to localize the array element
    # that it will be stored in.
    local $saved[0];                          # Preserve the old value of $@
    eval { &DB::save };

    # Now see whether we need to report an error back to the user.
    if ($at) {
        die $at;
    }

    @res;
} ## end sub eval

use IO::Handle;

# Debugger for Perl 5.00x; perl5db.pl patch level:
$VERSION = 0.30;
$header  = "perl5db.pl version $VERSION";

# $Log$

=head1 DEBUGGER INITIALIZATION

The debugger starts up in phases.

=head2 BASIC SETUP

First, it initializes the environment it wants to run in: turning off
warnings during its own compilation, defining variables which it will need
to avoid warnings later, setting itself up to not exit when the program
terminates, and defaulting to printing return values for the C<r> command.

=cut

BEGIN {
    # Switch compilation warnings off until another BEGIN.
    $ini_warn = $^W;
    $^W       = 0;

    #init $deep to avoid warning
    # By default it doesn't stop.
    $deep = -1;
    $ready = 0;
    %postponed_file = ();
    %firstFileInfo = ();
    $OUT_selector = $_pending_check_enabled = undef;
    $is_perl_5_005 = $] < 5.006;
    $skip_alarm = 1;
    
    # uninitialized warning suppression
    $signal = $single = $trace = 0;
    # important stuff
    @stack = (0);
    $stack_depth = 0;    # Localized repeatedly; simple way to track $#stack
    $level = 0;
    $frame = 0;
}

local ($^W) = 0;    # Switch run-time warnings off during init.

# placeholder: dumpvar vars

# True if we're logging
$ldebug = 0;

# more stuff
require Config;
require Cwd;

# get current directory
$cwd = Cwd::cwd();

# cwd bug: returns C: rather than C:/ if we're in the root, so work around it
if ($cwd =~ /^[A-Z]:$/i) {
    $cwd .= "/";
}

# We set these variables to safe values. We don't want to blindly turn
# off warnings, because other packages may still want them.
$signal = $single = $finished = $runnonstop = 0;
$inPostponed = 0;
@postponedFiles = ();
$fall_off_end = 0;
$interact = 0;
$interact_str = undef;
$interact_ptn = undef;
@interact_pvs = undef;
# Uninitialized warning suppression
# (local $^W cannot help - other packages!).

# Variables for the eval things

# Hash on <<(eval \d+)[parentLocn:lineNum]>> to (filename, startLine, @src)

%evalTable = ();
@evalTableIdx = ();

# This is used with Syntax::Highlight::Perl::Improved
# to keep track of the variables.

%proxVarTable = ();
%proxVarEachVarTable = (); # Location of <each %var> iterator-consuming points
$formatter = undef;
eval {
    require Syntax::Highlight::Perl::Improved;
    $formatter = Syntax::Highlight::Perl::Improved->new();
    $formatter->set_format(
			   'Comment_Normal'   => ['<com>', '</com>'],
			   'Comment_POD'      => ['<pod>', '</pod>'],
			   'Quote'            => ['<quote>', '</quote>'],
			   'String'           => ['<str>', '</str>'],
			   'Variable_Scalar'  => ['<vs>', '</vs>'],
			   'Variable_Array'   => ['<va>', '</va>'],
			   'Variable_Hash'    => ['<vh>', '</vh>'],
			   'Variable_Typeglob'=> ['<vt>', '</vt>'],
			   );
};
if ($@) {
    dblog("Not using the Syntax::Highlight::Perl::Improved module: [$@]");
}
    

=head1 DEBUGGER SETTINGS

Keep track of the various settings in this hash

=cut

%supportedCommands = (
		      status => 1,
		      feature_get => 1,
		      feature_set => 1,
		      run => 1,
		      step_into => 1,
		      step_over => 1,
		      step_out => 1,
		      stop => 1, #xxxstop
		      detach => 1,
		      breakpoint_set => 1,
		      breakpoint_get => 1,
		      breakpoint_update => 1,
		      breakpoint_remove => 1,
		      breakpoint_list => 1,
		      stack_depth => 1,
		      stack_get => 1,
		      context_names => 1,
		      context_get => 1,
		      typemap_get => 1,
		      property_get => 1,
		      property_set => 1,
		      property_value => 1,
		      source => 1,
		      stdout => 1,
		      stderr => 1,
		      stdin => 0,
		      break => 0,
		      eval => 1,
		      interact => 1,
		      );
		      

# Feature name => [bool(3): is supported, is settable, has associated value]
%supportedFeatures = (
		      encoding => [1, 1, 1],
		      data_encoding => [1, 1, 1],
		      max_children => [1, 1, 1],
		      max_data => [1, 1, 1],
		      max_depth => [1, 1, 1],
		      multiple_sessions => [0, 0, 0],
		      language_supports_threads => [0, 0, 0],
		      language_name => [1, 0, 1],
		      language_version => [1, 0, 1],
		      protocol_version => [1, 0, 1],
		      supports_async => [0, 0, 0],
		      multiple_sessions => [0, 0, 0],
		      );

# Feature name => [value, allowed settable values, if constrained]

%settings = ( encoding => ['UTF-8', ['UTF-8', 'iso-8859-1']],
	      data_encoding => ['base64', ['urlescape', 'base64', 'none', 'binary']], # binary  and 'none' are the same
	      max_children => [10, 1],
	      max_data => [32767, 1],
	      max_depth => [1, 1],
	      language_name => ['Perl'],
	      language_version => [sprintf("%vd", $^V)],
	      protocol_version => ['1.0'],
	      );
*DB::DbgrCommon::settings = *settings;

sub xsdNamespace() {
  return q(xmlns:xsd="http://www.w3.org/2001/XMLSchema");
}

sub xsiNamespace() {
  return q(xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance");
}

sub decodeData($;$) {
    my ($str, $encoding) = @_;
    my $finalStr;
    my $currDataEncoding = defined $encoding ? $encoding : $settings{data_encoding}->[0];
    $finalStr = $str;
    eval {
	if ($currDataEncoding eq 'none' || $currDataEncoding eq 'binary') {
	    $finalStr = $str;
	} elsif ($currDataEncoding eq 'urlescape') {
	    $finalStr = DB::CGI::Util::unescape($str);
	} elsif ($currDataEncoding eq 'base64') {
	    $finalStr = DB::MIME::Base64::decode_base64($str);
	} else {
	    if ($ldebug) {
		dblog("Converting $str with unknown encoding of $currDataEncoding\n");
	    }
	    $finalStr = $str;
	}
    };
    if ($ldebug) {
	if ($@) {
	    # Log the string that caused problems.
	    $str = (substr($str, 0, 100) . '...') if length($str) > 100;
	    dblog("decodeData($str) => [$@]\n") if $ldebug;
	}
    }
    return $finalStr;
}

$stopReason = 0;
$lastContinuationCommand = undef;
# $lastContinuationCommand = 'step_into';
$lastContinuationStatus = 'break';
$lastTranID = 0;  # The transactionID that started

@stopReasons = (qw(starting stopping stopped running break interactive));
sub getStopReason {
  if ($stopReason >= 0 && $stopReason <= $#stopReasons) {
    return $stopReasons[$stopReason];
  }
  die "Bad \$stopReason = $stopReason\n";    
}

=head1 StopReasons

Why we are stopping

=over 4 

=item * 0 - started program

=item * 1 - user did a step_into

=item * 2 - user did a step_over

=item * 4 - user did a step_out

=item * 8 - program hit max-recursion depth

=back

=cut

# open input and output (to and from console)
open(IN,  "<&STDIN") || warn "open(IN)";
open(OUT, ">&STDERR") || open(OUT, ">&STDOUT") || warn "open(OUT)";

# force autoflush of output
eval {
    select(OUT);
    $| = 1;			# for DB::OUT
    select(STDERR);
    $| = 1;
    select(STDOUT);
    $| = 1;			# for real STDOUT
};

# to avoid warnings?
$sub = '';
#@ARGS;

my $current_filename = '';

# Variables and subs for doing option processing
# (Copied from standard perl5db.pl to support PDK products)

$remoteport = undef;
# If the PERLDB_OPTS variable has options in it, parse those out next.
if (defined $ENV{PERLDB_OPTS}) {
    parse_options($ENV{PERLDB_OPTS});
}
if (!defined $remoteport) {
    if (exists $ENV{RemotePort}) {
        $remoteport = $ENV{RemotePort};
    } else {
        die "Env variable RemotePort not set.";
    }
}
if ($remoteport =~ /^\d+$/) {
    die "Env variable RemotePort not numeric (set to $remoteport).";
}

sub emitBanner {
    require Config;
    local *Config = *Config::Config;
    my $version_str;
    if ($Config{PERL_REVISION}) {
	$version_str = $Config{PERL_REVISION};
	if ($Config{PERL_VERSION}) {
	    $version_str .= '.' . $Config{PERL_VERSION};
	    if ($Config{PERL_SUBVERSION}) {
		$version_str .= '.' . $Config{PERL_SUBVERSION};
	    }
	}
    } else {
	$version_str = $];
    }
    my $str = "# ";
    $str .= ($Config{cf_by} =~ /activestate/i
	     ? "ActivePerl" : ($Config{perl} || "Perl"));
    $str .= " v$version_str";
    $str .= " [$Config{archname}]\n";
    # $str .= "# Type    `perl -v`   for more info.\n";
    print STDOUT $str;
}

# placeholder - tty stuff

if ($is_perl_5_005) {
    # Don't bother debugging at all on 5.5 -- just run to completion
    #XXX - really?
}

if (defined $remoteport) {
  # If RemotePort was defined in the options, connect input and output
  # to the socket.
  require IO::Socket;
  $OUT = new IO::Socket::INET(
			      Timeout  => '10',
			      PeerAddr => $remoteport,
			      Proto    => 'tcp',
			     );
  if (!$OUT) {
      warn "Unable to connect to remote host: $remoteport ($!)\n";
      warn "Running program outside the debugger...\n";
  } else {
      $sentInitString = 0;
      $fakeFirstStepInto = 1;
      setDefaultOutput($OUT);
      $IN = $OUT;
      eval {
	  require IO::Select;
	  $OUT_selector = IO::Select->new();
	  $OUT_selector->add($OUT);
	  # Indicate that we support asynchrousness
	  $supportedCommands{break} = 1;
	  if (!$skip_alarm) {
	      $supportedFeatures{supports_async} = [1, 1, 1];
	      $settings{supports_async} = [1];
	      $_pending_check_enabled = 1;
	  }
	  $_pending_check_count = 0;
	  $_pending_check_lim = 100;
	  $_pending_check_timeout = .000001;
	  $_pending_check_interval = 1; # Check for a break every 1 second
	  @_pending_commands = ();
      };

      # print "# Talking to port $remoteport\n" if $ldebug;
      # Moved stuff to start of init loop
      # sendInitString();
  }

} else {
    warn "RemotePort not set for debugger\n";
    # Keep going
}

sub win32_pm_fixed {
    # The fast way
    return 1 if $File::Spec::VERSION >= 0.82;
    
    # The slow way
    my $win32_file = $INC{"File/Spec/Win32.pm"};
    open FH_WIN32, "<$win32_file" or return undef;
    my $fixed = 1;
    while (<FH_WIN32>) {
	# We should check for undefined $base first, not after
	if (/elsif.*!defined.*\$base\b/) {
	    # No version in this one
	    $fixed = undef;
	    last;
	}
    }
    close FH_WIN32;
    return $fixed;
}

sub getopt_std_fixed {
    # The fast way
    return 1 if $Getopt::Std::VERSION >= 1.02;
    # The slow way
    my $getopt_file = $INC{"Getopt/Std.pm"};
    open FH_GETOPT, "<$getopt_file" or return undef;
    my $fixed;
    my $qdd = quotemeta('/^--$/');
    while (<FH_GETOPT>) {
	# We should check for undefined $base first, not after
	if (/$qdd/) {
	    # This one allows for "--"
	    $fixed = 1;
	    last;
	}
    }
    close FH_GETOPT;
    return $fixed;
}

sub not_ready_for_5_005 {
    my ($action, $context, $lib) = @_;
    my $str = "$action with Perl 5.005 $context requires small fixes
to your $lib file, and Komodo has determined that
they have not yet been done.  Please contact support\@activestate.com
for further information.";
    # Re-wrap the lines.
    $str =~ s/\n/ /g;
    $str =~ s/ {2,}/ /g;
    $str =~ s/(.{40}[^ ]+) /$1\n/gs;
    print STDERR "$str\n";
}

if ($is_perl_5_005 && $^O eq 'MSWin32' && !win32_pm_fixed()) {
    not_ready_for_5_005("Debugging", "on Win32", "File/Spec/Win32.pm");
    exit();
} elsif ($OUT) {
    # Unbuffer DB::OUT. We need to see responses right away. 
    my $previous = select($OUT);
    # for DB::OUT
    $| = 1;
    select STDERR;
    $| = 1;
    select($previous);
    # $single = 1;
    if (!$skip_alarm) {
	$SIG{ALRM} = \&_break_check_handler;
    }
    if ($is_perl_5_005 && !getopt_std_fixed()) {
	$supportedCommands{interact} = 0;
    }
} else {
    # Implement a null debugger interface to keep the Perl program running
    *DB = sub {};
    *sub = sub { &$sub; };
}

# Set a breakpoint for the first line of breakable code now,
# so we don't have to duplicate the reason in two places.
# Chat with the debug server until we get a continuation command.

# things to help the breakpoint mechanism

# Data structures for managing breakpoints

use DB::DbgrCommon;
use DB::DbgrProperties;
use DB::DbgrURI qw(canonicalizeFName
		   canonicalizeURI
		   filenameToURI
		   uriToFilename
		   );
use DB::RedirectStdOutput;

use DB::CGI::Util;
use DB::MIME::Base64;

use constant BKPT_DISABLE => 1;
use constant BKPT_ENABLE => 2;
use constant BKPT_TEMPORARY => 3;

use constant BKPT_REQ_ENABLED => 'enabled';
use constant BKPT_REQ_DISABLED => 'disabled';
use constant BKPT_REQ_TEMPORARY => 'temporary';

# Indices into the breakpoint Table

use constant BKPTBL_FILEURI => 0;
use constant BKPTBL_LINENO => 1;
use constant BKPTBL_STATE => 2;
use constant BKPTBL_TYPE => 3;
use constant BKPTBL_FUNCTION_NAME => 4;
use constant BKPTBL_CONDITION => 5;
use constant BKPTBL_EXCEPTION => 6;
use constant BKPTBL_HIT_INFO => 7;

use constant HIT_TBL_COUNT => 0; # No. Times we've hit this bpt
use constant HIT_TBL_VALUE => 1; # Target hit value
use constant HIT_TBL_EVAL_FUNC => 2; # Function to call(VALUE, COUNT)
use constant HIT_TBL_COND_STRING => 3; # Condition string

use constant IB_STATE_NONE => 0;
use constant IB_STATE_START => 1;
use constant IB_STATE_PENDING => 2;

use constant STOP_REASON_STARTING => 0;
use constant STOP_REASON_STOPPING => 1;
use constant STOP_REASON_STOPPED => 2;
use constant STOP_REASON_RUNNING => 3;
use constant STOP_REASON_BREAK => 4;
use constant STOP_REASON_INTERACT => 5;

use DB::Data::Dump;
use File::Basename;
use File::Spec;
use Getopt::Std;

=head1 notyet

sub hook_file_spec_win32_fixes() {
    # There's a serious bug in 5.005's win32.pm, so supply fixes
    # from our own space.
    require DB::File::Spec::Win32;
    no strict 'refs';
    foreach $meth (qw(rel2abs splitpath)) {
	*{'File::Spec::Functions::' . $meth} = *{'DB::File::Spec::Win32::' . $meth};
	*{'File::Spec::' . $meth} = *{'DB::File::Spec::Win32::' . $meth};
	*{'File::Spec::Win32::' . $meth} = *{'DB::File::Spec::Win32::' . $meth};
	*{$meth} = *{'DB::File::Spec::Win32::' . $meth};
    }
}

=cut

# Load the proper base class at compile time
BEGIN {
    require File::Spec::Functions;
    if ($^O eq 'MSWin32') {
	require File::Spec::Win32;
=notyet
	if (0 && $is_perl_5_005) {
	    hook_file_spec_win32_fixes();
	}
=cut
    } else {
	require File::Spec::Unix;
    }
    my $junk = File::Spec::Functions::devnull();
    dblog("dev-null => $junk");
}

@bkptLookupTable = (); # Map fileURI_No -> hash of (lineNo => breakPtID)
%bkptInfoTable = ();   # Map breakPtID -> [fileURINo, lineNo, state, type, function, expression, exception, hitInfo]
%FQFnNameLookupTable = (); # Map fully qualified fn names =>
		           # { call => breakPtID, return => breakPtID }

@fileNameTable = ();                  # Map fileURI_No => [
				      #  $bFileURI,
				      #  $bFileName, (fwd slashes)
				      #  $perlFileName (backwd slashes)
				      # ]
%watchedExpressionLookupTable = ();   # Map watchedExpn => breakPtID

$nextBkPtIndex = 0;

$numWatchPoints = 0;

$ibState = IB_STATE_NONE;
$ibBuffer = undef;
$startedAsInteractiveShell = undef;

# End of initialization code.
$proximityrgx = qr/((?:\$\#?
                     |\%
                     |(?<!\w)\@)   # Avoid email addrs in strings
                    [a-zA-Z_]\w*[\[\{]?)/x;
$specialVarRgx = qr/(\$(?:\^\w
                        |\{\^.*?\}
                        |[\*\+\&\'\`\|\-\=\~\%\!\"\$\(\)\,\.\/\:\;]
                        |_
                        |\d+)
                     |\@[-_+]
                     |\%(?:\!|\^H))/x;

{
    $hostname = 'unknown';
    local $@;
    eval {
	require 'Sys/Hostname.pm';
	$hostname = Sys::Hostname::hostname();
	$hostname =~ s/\..*$//;	# Keep only the first part of a dotted name
	$hostname =~ s/[^-_\w\d]+/_/g; # Turn non-alnums to safe chars
	dblog("**** \$hostname=$hostname");
    };
    if ($@) {
	dblog("Error -- [$@]\n");
    }
    $partial_dbgp_prefix = "dbgp://perl";
    $full_dbgp_prefix = "$partial_dbgp_prefix/$hostname/$$";
}

DB::DbgrURI::init(ldebug => $ldebug, cwd => $cwd);
# Handle postponed requests that came in earlier.

finish_postponed();
$ready = 1;
$single = 0;
$full_bypass = 0;

if (!$formatter) {
    dblog("Not using the SHPI module: [$@]");
}
sub sendInitString {
    # Send the init command at this point
    my $ppid = $ENV{DEBUGGER_APPID} || "";
    my $appid = $$;  # getpid
    my $ideKey = $ENV{DBGP_IDEKEY} || "";
    my $initString = sprintf(qq(%s\n<init %s
				appid="%s"
				idekey="%s"
				parent="%s"
			       ),
			     xmlHeader(),
			     namespaceAttr(),
			     $appid,
			     $ideKey,
			     $ppid,
			     );
    if (exists $ENV{DBGP_COOKIE} && $ENV{DBGP_COOKIE}) {
	$initString .= qq( session="$ENV{DBGP_COOKIE}");
    }
    $initString .= sprintf(qq( thread="%s"
			       language="%s"
			       protocol_version="%s"),
			   0,	# Main thread in a program defined to be 0
			   'Perl', # Language
			   $settings{protocol_version}[0],
			   );
    if ($startedAsInteractiveShell) {
	$initString .= ' interactive="%"';
    } else {
	$initString .= ' fileuri="' . filenameToURI($0, 0) . '"';
    }
    my $hostname;
    if (!($hostname = $ENV{HOST_HTTP})) {
	# Get the hostname from perl
	require Sys::Hostname;
	$hostname = eval { Sys::Hostname::hostname() };
    }
    $initString .= qq( hostname="$hostname") if $hostname;
    $initString .= '/>';
    printWithLength($initString);
    $ENV{DEBUGGER_APPID} = $appid;
}

sub getArg {
  my ($cmdArgsARef, $optString) = @_;
  my $i;
  # Don't look at the last arg -- if it's an option, we're out of luck
  for ($i = 0; $i <= $#$cmdArgsARef - 1; $i++) {
    if ($cmdArgsARef->[$i] eq $optString) {
      return splice(@$cmdArgsARef, $i, 2);
    } elsif ($cmdArgsARef->[$i] eq '--') {
	last;
    }
  }
  return undef;
}

# Never delete entries here.

sub internFileURI {
    my ($bFileURI) = @_;
    $bFileURI = canonicalizeURI($bFileURI);
    if (!exists $fileURILookupTable{$bFileURI}) {
	my $tblSize = scalar keys %fileURILookupTable;
	$fileURILookupTable{$bFileURI} = $tblSize + 1;
	$fileURI_No_ReverseLookupTable[$tblSize + 1] = $bFileURI;
    }
    return $fileURILookupTable{$bFileURI};
}

sub internFileURINo_LineNo {
    my ($bFileURINo, $bLine) = @_;
    if (!$bkptLookupTable[$bFileURINo]) {
	$bkptLookupTable[$bFileURINo] = {$bLine => $nextBkPtIndex};
	return $nextBkPtIndex++;
    } elsif (! exists $bkptLookupTable[$bFileURINo]->{$bLine}) {
	$bkptLookupTable[$bFileURINo]->{$bLine} = $nextBkPtIndex;
	return $nextBkPtIndex++;
    }
    return $bkptLookupTable[$bFileURINo]->{$bLine};
}

sub internFunctionName_CallType_Breakpoint($$) {
    my ($functionName, $bType) = @_;
    if (! exists $FQFnNameLookupTable{$functionName}) {
	$FQFnNameLookupTable{$functionName} = { $bType => $nextBkPtIndex };
	return $nextBkPtIndex++;
    } elsif (exists $FQFnNameLookupTable{$functionName}{$bType}) {
	# Overwrite existing breakpoint
	return $FQFnNameLookupTable{$functionName}{$bType};
    } else {
	$FQFnNameLookupTable{$functionName}{$bType} = $nextBkPtIndex;
	return $nextBkPtIndex++;
    }
}

sub internFunctionName_watchedExpn($) {
    my ($bExpn) = @_;
    if (! exists $watchedExpressionLookupTable{$bExpn}) {
	$watchedExpressionLookupTable{$bExpn} = $nextBkPtIndex++;
    }
    return $watchedExpressionLookupTable{$bExpn};
}

sub getURIByNo {
    my ($fileURINo) = @_;
    return $fileURI_No_ReverseLookupTable[$fileURINo] || "";
}

sub storeBkPtInfo {
    my ($bkptID, $bFileURINo, $bLine, $bstate, $bType, $bCondition) = @_;
    $bkptInfoTable{$bkptID} = [$bFileURINo, $bLine, $bstate, $bType, undef, $bCondition, undef, undef];
}

# No conditions, but we want to maintain a hit count on the breakpoint.

sub setNullBkPtHitInfo {
    my ($bkptID) = @_;
    $bkptInfoTable{$bkptID}[BKPTBL_HIT_INFO] = [0, 0, undef, undef];
}

# Take a target value and a string representing a hit condition,
# and return a closure encapsulating the test.
# We need to expose the target, so there's no point encapsulating
# it into the closure.

# $bkptHitCount is the current value (hit count) on the breakpoint
# $bkptHitValue is the target value

sub testGE {
    my ($bkptHitCount, $bkptHitValue) = @_;
    return $bkptHitCount >= $bkptHitValue;
}

sub testEQ {
    my ($bkptHitCount, $bkptHitValue) = @_;
    return $bkptHitCount == $bkptHitValue;
}

sub testMod {
    my ($bkptHitCount, $bkptHitValue) = @_;
    return $bkptHitValue > 0 && $bkptHitCount % $bkptHitValue == 0;
}

sub parseBkPtHitInfo($) {
    my ($bkptHitConditionFunc) = @_;
    if ($bkptHitConditionFunc eq '>=') {
	return \&testGE;
    } elsif ($bkptHitConditionFunc eq '==') {
	return \&testEQ;
    } elsif ($bkptHitConditionFunc eq '%') {
	return \&testMod;
    } else {
	return undef;
    }
}

sub setBkPtHitInfo($$$) {
    my ($bkptID, $bkptHitValue, $bkptHitConditionString) = @_;
    $bkptHitConditionString = '>=' if (!defined $bkptHitConditionString);
    my $sub = parseBkPtHitInfo($bkptHitConditionString);
    if (!defined $sub) {
	# Formulate an error condition
	return 0;
    }
    if (! defined $bkptInfoTable{$bkptID}[BKPTBL_HIT_INFO]) {
	$bkptInfoTable{$bkptID}[BKPTBL_HIT_INFO] = [];
    }
    # Always reset hit-count to 0 -- part of bug 40561
    $bkptInfoTable{$bkptID}[BKPTBL_HIT_INFO][HIT_TBL_COUNT] = 0;
    $bkptInfoTable{$bkptID}[BKPTBL_HIT_INFO][HIT_TBL_VALUE] = $bkptHitValue; # Target
    $bkptInfoTable{$bkptID}[BKPTBL_HIT_INFO][HIT_TBL_EVAL_FUNC] = $sub;
    $bkptInfoTable{$bkptID}[BKPTBL_HIT_INFO][HIT_TBL_COND_STRING] = $bkptHitConditionString;
}
    

sub getBkPtInfo {
    my ($bkptID) = @_;
    if (!exists $bkptInfoTable{$bkptID} || (ref $bkptInfoTable{$bkptID}) ne 'ARRAY') {
	return;
    } else {
	return wantarray ? @{$bkptInfoTable{$bkptID}} : $bkptInfoTable{$bkptID};
    }
}

sub setBkPtState {
    my ($bkptID, $bstate) = @_;
    if (!exists $bkptInfoTable{$bkptID} || (ref $bkptInfoTable{$bkptID}) ne 'ARRAY') {
	# No such breakpoint
	return 0;
    }
    $bkptInfoTable{$bkptID}->[2] = $bstate;
    return 1;
}

sub getBkPtState {
    my ($bkptID, $bstate) = @_;
    if (!exists $bkptInfoTable{$bkptID} || (ref $bkptInfoTable{$bkptID}) ne 'ARRAY') {
	# No such breakpoint
	return BKPT_DISABLE;
    }
    return $bkptInfoTable{$bkptID}->[2];
}

sub deleteBkPtInfo {
    my ($bkptID) = @_;
    if (!exists $bkptInfoTable{$bkptID} || (ref $bkptInfoTable{$bkptID}) ne 'ARRAY') {
	# No such breakpoint
	return 0;
    }
    delete $bkptInfoTable{$bkptID};
    return 1;
}

sub remove_FileURI_LineNo_Breakpoint {
    my ($fileURINo, $bLine) = @_;
    if ($bkptLookupTable[$fileURINo]) {
	if (exists $bkptLookupTable[$fileURINo]->{$bLine}) {
	    if (defined $fileNameTable[$fileURINo]) {
		local (undef, undef, $perlFileName) = @{$fileNameTable[$fileURINo]};
		if ($perlFileName) {
		    local *dbline = $main::{'_<' . $perlFileName};
		    delete $dbline{$bLine};
		} else {
		    dblog("remove_FileURI_LineNo_Breakpoint: No perlFileName entry in info \$fileNameTable[$fileURINo]\n") if $ldebug;
		}
	    } else {
		dblog("remove_FileURI_LineNo_Breakpoint: No info \$fileNameTable[$fileURINo]\n") if $ldebug;
	    }
	    delete $bkptLookupTable[$fileURINo]->{$bLine};
	} else {
	    dblog("remove_FileURI_LineNo_Breakpoint: Can't find bkpt info for (uri $fileURINo, line $bLine)\n") if $ldebug;
	}
    }
}

sub getStateName {
    my ($bState) = @_;
    if ($bState == BKPT_DISABLE) {
	return BKPT_REQ_DISABLED;
    } elsif ($bState == BKPT_ENABLE) {
	return BKPT_REQ_ENABLED;
    } elsif ($bState == BKPT_TEMPORARY) {
	return BKPT_REQ_TEMPORARY;
    } else {
	return BKPT_REQ_DISABLED;
    }
}

sub getExpressionTag {
    my ($bExpression) = @_;
    if (!$bExpression) {
	return "";
    } else {
	return sprintf('<expression>%s</expression>',
		       xmlEncode($bExpression));
    }
}

sub lookupBkptInfo {
    my ($fileNameURINo, $lineNo) = @_;
    if (!defined $bkptLookupTable[$fileNameURINo]) {
	dblog("lookupBkptInfo: No \$fileNameURINo ($fileNameURINo)\n") if $ldebug;
	return undef;
    } elsif (!exists $bkptLookupTable[$fileNameURINo]->{$lineNo}) {
	dblog("lookupBkptInfo: No entry at \$fileNameURINo ($fileNameURINo)->\{$lineNo}\n") if $ldebug;
	return undef;
    } else {
	my $bkptID = eval { $bkptLookupTable[$fileNameURINo]->{$lineNo}};
	return undef if !defined $bkptID;
	dblog("lookupBkptInfo: \$bkptID = $bkptID\n") if $ldebug;
	return $bkptInfoTable{$bkptID};
    }
}


# Precondition: $bFileName is canonicalized

sub lookForPerlFileName {
    my ($bFileName) = @_;
    # Look at all keys that start with '_<', aren't in eval blocks
    # and find one that canonicalizes to the same thing

    my @perlKeys = grep /_</, (grep !/eval/, keys %{*main::});
    foreach my $perlFileKey (@perlKeys) {
	$perlFileKey =~ s/_<//;
	my $origKey = $perlFileKey;
	local $@;
	eval {
	    $perlFileKey = canonicalizeFName(uriToFilename(filenameToURI($perlFileKey, 1)));
	    if ($bFileName eq $perlFileKey) {
		return $origKey;
	    }
	};
	if ($@) {
	    dblog("Called uriToFilename in " .
		  join("\n", dump_trace(0)));
	}
    }
    return undef;
}
    
    
sub internEvalURI($;$) {
    my ($filename, $srcLinesARef) = @_;
    if (!exists $evalTable{$filename}) {
	my ($evalIdx, $parentLocation, $startingPoint) =
	    ($filename =~ /\(eval\s*(\d+)\)\[(.*):(\d+)\]$/);
	my $etCount = scalar @evalTableIdx;
	$evalTable{$filename} = {
	    file => $parentLocation,
	    startLine => $startingPoint,
	    src => $srcLinesARef,
	    idx => $etCount,
	};
	$evalTableIdx[$etCount] = $filename;
	if (!defined $srcLinesARef) {
	    local *dbline = $main::{'_<' . $filename};
	    dblog("internEvalURI -- found src lines for ($filename), using ", join('', (scalar @dbline > 100 ? @dbline[0..99] : @dbline))) if $ldebug;
	    $evalTable{$filename}{src} = \@dbline;
	}
    }
}

# Assume this routine is called from the main routine only
# while we're trying to convert the current filename to a URI
#
# Don't convert the case here.

sub calcFileURI($) {
    my ($filename) = @_;
    if ($filename =~ m/^(\(eval\s*\d+\))\[.+:\d+\]$/) {
	my $evalName = $1;
	internEvalURI($filename);
	my $idx;
	if (exists $evalTable{$filename}
	    && defined ($idx = $evalTable{$filename}{idx})
	    && defined $evalTableIdx[$idx]) {
	    my $retName = "$full_dbgp_prefix/$idx/" . encodeData($evalName, 'urlescape');
	    dblog "calcFileURI: mapping $filename => [$retName]\n" if $ldebug;
	    return $retName;
	} else {
	    dblog "Can't map [$filename] to an evalTableIdx entry" if $ldebug;
	    return "$full_dbgp_prefix/0/" . encodeData($filename, 'urlescape');
	}
    } elsif (defined &INC && (index($filename, "/PerlApp/") == 0 # PDK ... 6
			      || $filename =~ m@^/<.*>@     # PDK 7
			      )) {
	return "dbgp:///perl/$filename";
    } else {
	return filenameToURI($filename, 0);
    }
}

sub downcaseDriveLetter {
    # If we're on windows systems, we'll need to manually
    # lcase the drive letter -- the uri canonicalizer
    # doesn't do that.
    $_[0] =~ s@^([A-Z])(?=:[/\\])@lc $1@e;
}

# Functions for manipulating breaking at functions:

=head1 findAndAddFunctionBreakPoints

Four ways to break on a sub:

1. No file or line # given: break at the start (or end) of all instances
   of all loaded subs with the given name

2. File given, no line #: break at the start (or end) of all instances
   ot the named function in the given file

3. File and line # given: use the line # to identify which instance of
   a function that matches the given name.  This is to allow for a
   file that contains multiple packages, with the same function name
   in more than one package.

4. No file given, but line # given: This is weird, but we have a
   story:
   Find all instances of the given function, and accept only if the
   given line # falls in the function's range.

=cut

sub addSubBreakPoint($$$$$$$$$);

sub addSubBreakPoint($$$$$$$$$) {
    my ($functionName,
	$fileURINo,
	$lineNumber,
	$bState,
	$possibleSub,
	$bCondition,
	$bType,
	$bHitCount,
	$bHitConditionOperator) = @_;
    my $bkptID = internFunctionName_CallType_Breakpoint($functionName, $bType);
    dblog("FQFnNameLookupTable: ", DB::Data::Dump::dump(%FQFnNameLookupTable), "\n") if $ldebug;
    storeBkPtInfo($bkptID, $fileURINo, $lineNumber, $bState,
		  $bType, $bCondition);
    if ($bHitCount) {
	setBkPtHitInfo($bkptID, $bHitCount, $bHitConditionOperator);
    } else {
	setNullBkPtHitInfo($bkptID);
    }
    
}

sub findAndAddFunctionBreakPoints($$$$$$$$$) {
    my ($bFunctionName, $perlFileName, $lineNumber,
	$bCondition, $bState, $bIsTemporary, $bType,
	$bHitCount,
	$bHitConditionOperator) = @_;
    my $isQualified = ($bFunctionName =~ /::/);
    if (!$isQualified) {
	$fqSubName = 'main::' . $bFunctionName;
    } else {
	$fqSubName = $bFunctionName;
    }
    my @possibleSubNames;
    # First try the direct lookup approach
    if (exists $sub{$fqSubName}) {
	@possibleSubNames = ($fqSubName);
    } else {
	my ($baseFunctionName) = ($bFunctionName =~ /([^:]+)$/);
	@possibleSubNames = grep(/$baseFunctionName$/, keys %sub);
    }
    
    # First find all the packages
    return 0 if (!@possibleSubNames);
    my $totals = 0;
    foreach my $possibleSub (@possibleSubNames) {
	my $addIt = 0;
	my ($fileName, $startLineNo, $endLineNo) = ($sub{$possibleSub} =~ /^(.*):(\d+)-(\d+)$/);
	if ($fileName) {
	    if ($perlFileName) {
		if (lc $fileName eq lc $perlFileName
		    || $fileName =~ /$perlFileName/i) {
		    if (!defined $lineNumber
			|| ($lineNumber >= $startLineNo
			    && $lineNumber <= $endLineNo)) {
			$addIt = 1;
		    }
		}
	    } else {
		$addIt = (!defined $lineNumber
			  || ($lineNumber >= $startLineNo
			      && $lineNumber <= $endLineNo));
	    }
	}
	if ($addIt) {
	    ++$totals;
	    my $bFileURINo;
	    my $fileURI = filenameToURI($fileName, 1);
	    my $fileURINo = internFileURI($fileURI);
	    addSubBreakPoint($possibleSub,
			     $fileURINo,
			     $lineNumber,
			     $bState,
			     $possibleSub,
			     $bCondition,
			     $bType,
			     $bHitCount,
			     $bHitConditionOperator);
	}
    }
    return $totals;
}

# I try to make the types transparent, but we need to give a typemap
# anyway

sub emitTypeMapInfo($$) {
    my ($cmd, $transactionID) = @_;
    my $res = sprintf(qq(%s\n<response %s %s %s command="%s" 
			 transaction_id="%s" >),
		      xmlHeader(),
		      namespaceAttr(),
		      xsdNamespace(),
		      xsiNamespace(),
		      $cmd,
		      $transactionID);
    # Schema, CommonTypeName (type attr) LanguageTypeName (name attr)
    foreach my $e (['boolean', 'bool'],
		   ['float'],
		   ['integer', 'int'],
		   ['string']) {
	my $xsdName = $e->[0];
	my $commonTypeName = $e->[1] || $xsdName;
	my $languageTypeName = $e->[2] || $commonTypeName;
	$res .= qq(<map type="$commonTypeName" name="$languageTypeName" xsi:type="xsd:$xsdName"/>);
    }
    $res .= "\n</response>";
    printWithLength($res);
}

sub decodeCmdLineData($$) {
    my ($dataLength, $argsARef) = @_;
    my @args = @$argsARef;
    my $currDataEncoding = $settings{data_encoding}->[0];
    my $decodedData;
    if ($currDataEncoding eq 'none' || $currDataEncoding eq 'binary') {
	$decodedData = join(" ", @args);
	$dataLength = length ($decodedData);
    } elsif (scalar @args == 0) {
	printWithLength(sprintf
			qq(%s\n<response %s command="%s" transaction_id="%s" ><error code="%d" apperr="4"><message>Expecting exactly 1 argument for %s command, got [nothing].</message></error></response>),

			xmlHeader(),
			namespaceAttr(),
			$cmd,
			$transactionID,
			DBP_E_CommandUnimplemented,
			$cmd,
			);
	return ();
    } else {
	$decodedData = decodeData(join("", @args));
	$dataLength = length ($decodedData);
    }
    dblog("decodeCmdLineData: returning [$decodedData]\n") if $ldebug;
    return ($dataLength, $currDataEncoding, $decodedData);
}

sub checkForEvalStackType($) {
    my ($stackDumpTypeValue) = @_;
    if ($stackDumpTypeValue && $stackDumpTypeValue =~ /^eval [\"\'q<]/) {
	return 'eval';
    } else {
	return 'file';
    }
}

# Walk a list of array and hash selectors until we get a final value.

sub evalArgument($$$) {
    my ($property_long_name, $propertyKey, $currentArgsARef) = @_;
    my $returned_long_name;
    if ($property_long_name eq '@_') {
	if ($propertyKey =~ /^\[?(\d+)\]?/) {
	    my $val = $1;
	    $returned_long_name = sprintf('$_[%d]', $val);
	    return ($returned_long_name, $currentArgsARef->[$val]);
	} else {
	    return (undef, undef, DBP_E_CantGetProperty,
		    "Can't parse \@_ propertyKey $propertyKey");
	}
    } elsif ($property_long_name !~ /^\$_\[\d+\]/) {
	return (undef, undef, DBP_E_CantGetProperty,
		"Property $property_long_name doesn't identify an arg");
    }
    $returned_long_name = '$_';
    my $currVal;
    $property_long_name =~ /^\$_\[(\d+)\](?:->)?(.*)/;
    $currVal = $currentArgsARef->[$1];
    $returned_long_name = "\$_[$1]";
    $property_long_name = $2;
    while (length $property_long_name && ref $currVal) {
	if ($property_long_name =~ /^\[(\d+)\](?:->)?(.*)/) {
	    $currVal = $currVal->[$1];
	    $returned_long_name .= "[$1]";
	    $property_long_name = $2;
	} elsif ($property_long_name =~ /^\{(.+?)\}(?:->)?(.*)/) {
	    $currVal = $currVal->{$1};
	    $returned_long_name .= "{$1}";
	    $property_long_name = $2;
	} else {
	    last;
	}
    }
    if ($propertyKey && ref $currVal) {
	if ($propertyKey =~ /^\[(\d+)\]/) {
	    $currVal = $currVal->[$1];
	    $returned_long_name .= "[$1]";
	} elsif ($propertyKey =~ /^\{(.+?)\}(?:->)?(.*)/) {
	    $currVal = $currVal->{$1};
	    $returned_long_name .= "{$1}";
	}
    }
    return ($returned_long_name, $currVal);
}
	

sub getFileInfo($$$$$$$) {
    my ($optshref,
	$optionLetter,
	$filename,
	$rbFileURI,
	$rbFileURINo,
	$rbFileName,
	$rperlFileName) = @_;

    my ($bFileURI,
	$bFileURINo,
	$bFileName,
	$perlFileName);

    # Either the request specified a file uri, or we're
    # to use the current one.

    if (defined $optshref->{$optionLetter}) {
	$bFileURI = $optshref->{$optionLetter};
	# URIs need to be stored in a canonical format,
	# since they're how we look things up.
	# Filenames aren't used for lookups directly.
	$bFileURI = canonicalizeURI($bFileURI);
	$bFileURINo = internFileURI($bFileURI);
	if (defined $fileNameTable[$bFileURINo]) {
	    (undef, $bFileName, $perlFileName) = @{$fileNameTable[$bFileURINo]};
	} else {
	    local $@;
	    eval {
		$bFileName = canonicalizeFName(uriToFilename($bFileURI));
		$perlFileName = lookForPerlFileName($bFileName);
		if (defined $perlFileName) {
		    $perlNameToFileURINo{$perlFileName} = $bFileURINo;
		    $fileNameTable[$bFileURINo] = [$bFileURI,
						   $bFileName,
						   $perlFileName];
		}
	    };
	    if ($@) {
		dblog("Called uriToFilename in " .
		      join("\n", dump_trace(0)));
	    }
	}
    } else {
	$perlFileName = $filename;
	$bFileURI = canonicalizeURI($fileNameURI);
	$bFileURINo = $fileNameURINo;
	local $@;
	eval {
	    $bFileName = canonicalizeFName(uriToFilename($bFileURI));
	};
	if ($@) {
	    dblog("Called uriToFilename in " .
		  join("\n", dump_trace(0)));
	    return;
	}
	$perlNameToFileURINo{canonicalizeFName($perlFileName)} = $bFileURINo;

	# Do a sanity check
	local $tmpName = lookForPerlFileName($bFileName);
	if (! defined $tmpName) {
	    dblog("**** breakpoint_set: Error: Can't find a perl name for current name [$perlFileName], fullCanName [$bFileName], URI [$bFileURI]\n") if $ldebug;
	}
	$bFileURINo = internFileURI($bFileURI);
	$fileNameTable[$bFileURINo] = [$bFileURI,
				       $bFileName,
				       $perlFileName];
    }
    # And set the references
    $$rbFileURI = $bFileURI;
    $$rbFileURINo = $bFileURINo;
    $$rbFileName = $bFileName;
    $$rperlFileName = $perlFileName;
}
    

sub getBreakpointInfoString($%) {
    my ($bkptID, %extraInfo) = @_;
    my $bkptInfo = $bkptInfoTable{$bkptID};
    if (defined $bkptInfo && ref $bkptInfo eq 'ARRAY') {
	my ($xbFileURINo, $xbLine, $bState, $bType, $bFunction, $bExpression, $bException, $bHitInfo) = @$bkptInfo;
	my $res = sprintf(qq(<breakpoint
			     id="%s"
			     type="%s"),
			  $bkptID,
			  $bType
			  );
	if ($extraInfo{fileURI} || $xbFileURINo) {
	    my $bFileURI = getURIByNo($extraInfo{fileURI} || $xbFileURINo);
	    if ($bFileURI) {
		$res .= sprintf(' filename="%s"',
				$bFileURI);
	    }
	}
	if ($extraInfo{lineNo} || $xbLine) {
	    $res .= sprintf(' line="%s"',
			    ($extraInfo{lineNo} || $xbLine));
	}
	if ($extraInfo{function} || $bFunction) {
	    $res .= sprintf(' function="%s"',
			    ($extraInfo{function} || $bFunction));
	}
	$res .= sprintf(' state="%s"',
			$bState == BKPT_TEMPORARY ? BKPT_ENABLE : $bState);
	$res .= sprintf(' temporary="%d"',
			$bState == BKPT_TEMPORARY ? 1 : 0);
	$res .= sprintf(' exception="%s"',
			$bException) if defined $bException;
	if ($bHitInfo && defined $bHitInfo->[HIT_TBL_COUNT]) {
	    $res .= sprintf(' hit_count ="%s"', $bHitInfo->[HIT_TBL_COUNT]);
	    if (defined $bHitInfo->[HIT_TBL_VALUE]) {
		$res .= sprintf(' hit_value ="%s"', $bHitInfo->[HIT_TBL_VALUE]);
	    }
	    if (defined $bHitInfo->[HIT_TBL_COND_STRING]) {
		$res .= sprintf(' hit_condition ="%s"',
				xmlAttrEncode($bHitInfo->[HIT_TBL_COND_STRING]));
	    }
	}
	$res .= sprintf(">%s</breakpoint>\n",
			getExpressionTag($bExpression));
	return $res;
    } else {
	if ($ldebug) {
	    dblog("bkptInfo($bkptID, ",
	          join(", ", map{$_ => "($_, $extraInfo{$_})"} keys %extraInfo),
	          "), not defined\n");
	}
	return undef;
    }
}

sub processPossibleBreakpoint($$;$) {
    my ($bkptInfoRef, $locationString, $line) = @_;
    # ($bFileURINo, $bLine, $bState, $bType, $bFunction, $bExpression, $bException, $bHitInfo) = @$bkptInfoRef;
    if (!defined $bkptInfoRef) {
	return;
    }
    my $bState = $bkptInfoRef->[BKPTBL_STATE];
    if ($bState == BKPT_DISABLE) {
	return;
    }
    elsif ($bkptInfoRef->[BKPTBL_TYPE] eq 'watch') {
	dblog("Don't break on watch-breakpoints in processPossibleBreakpoint");
	return;
    }
    my $bHitInfo = $bkptInfoRef->[BKPTBL_HIT_INFO];
    if ($bHitInfo && defined $bHitInfo->[HIT_TBL_COUNT]) {
	$bHitInfo->[HIT_TBL_COUNT] += 1;

	# Are we doing hit-testing?
	if (defined $bHitInfo->[HIT_TBL_EVAL_FUNC]) {
	    $breakHere = $bHitInfo->[HIT_TBL_EVAL_FUNC]->($bHitInfo->[HIT_TBL_COUNT],
							  $bHitInfo->[HIT_TBL_VALUE]);
	} else {
	    $breakHere = 1;
	}
    } else {
	$breakHere = 1;
    }
    if (!$breakHere) {
	return;
    }
    my $bExpression = $bkptInfoRef->[BKPTBL_CONDITION];
    if ($bExpression) {
	# If we're here, $DB::signal must be false.
	# Can only be called from DB -- function breakpoints
	# can't be conditional.
	
	# As long as we're only called from DB::DB, there's
	# no reason to save the globals.
	    
	eval {
	    $evalarg = "\$DB::signal |= do {$bExpression;}"; &eval();
	};
	if ($@ || !$DB::signal) {
	    $breakHere = 0;
	}
    }
    if ($breakHere) {
	$signal |= 1;
	if ($bState == BKPT_TEMPORARY) {
	    $bkptInfoRef->[BKPTBL_STATE] = BKPT_DISABLE;
	    if ($line) {
		delete $dbline{$line};
	    }
	}
    } else {
	# Don't break here, but there are no
	# more items that need to be turned off.
	# If we got to the caller by stepping in, over, or out, we
	# wouldn't have invoked this routine at all.
    }
}

sub splitCommandLine {
    my ($cmd) = @_;
    my @args;
    ($cmd) = $cmd =~ /^\s*(.*)$/s;
    while (length $cmd) {
	if ($cmd =~ /^([\"\'])/) {
	    my $q = $1;
	    my $arg = "";
	    $cmd = substr($cmd, 1);
	    while (length $cmd) {
		if ($cmd =~ /^$q\s*(.*)$/s) {
		    $cmd = $1;
		    last;
		} elsif ($cmd =~ /^\\([\'\"\\])(.*)$/s) {
		    $arg .= $1;
		    $cmd = $2;
		} else {
		    $cmd =~ /^(.[^\'\"\\]*)(.*)$/s;
		    $arg .= $1;
		    $cmd = $2;
		}
	    }
	    push @args, $arg;
	} elsif ($cmd =~ /^'((?:\\.|[^\'])*)'\s*(.*)$/s) {
            push @args, $1;
	    $cmd = $2;
        } elsif ($cmd =~ /^([^\s\"]+)\s*(.*)$/s) {
            push @args, $1;
	    $cmd = $2;
        } else {
	    dblog "Can't deal with input [$cmd]";
	    push @args, substr($cmd, 0, 1);
	    $cmd = substr($cmd, 1);
	}
    }
    return @args;
}

sub trimEvalSubNames($) {
    my ($subname) = @_;
    if ($subname =~ /^eval\s+[\"\'q]/) {
	$subname = q(eval '...');
    } elsif ($subname =~ /^eval\s+\{/) {
	$subname = q(eval {...});
    }
    return $subname;
}

sub _extract_var {
    my ($type, $name, $context, $res) = @_;
    if ($context && $name =~ /^\$\W/) {
	# Skip it;
    } else {
        dblog("_extract_var: var $type: $name");
	if ($type eq 'va') {
	    $name =~ s/^\$/@/;
	} elsif ($type eq 'vh') {
	    $name =~ s/^\$/%/;
	} elsif ($type eq 'vt') {
	    $name =~ s/^\$/*/;
	}
	if (length $name > 1) {
	    # dblog("Found var [$name]");
	    $res->{$name} = undef;
	} else {
	    # dblog("_extract_var: no var found");
	}
    }
    $res;
}

sub _extract_string {
    my ($type, $string, $res) = @_;
    # dblog("_extract_string: string $type: $string");
    if ($type eq '"' || $type eq 'qq' || $type =~ m@^[sm]?/@) {
	$string =~ s@^<str>@@;
	$string =~ s@</str>$@@;
	_extractVarsInner($string, 1, $res);
    }
}    

sub _extractVarsInner {
    my ($line, $context, $res) = @_;
    # Try parsing the line looking for things we want to keep
    # Variables only
    if ($line =~ m@^<str>(.*)</str>[ \t\r\n]*$@) {
	# Deal with bug 45114 -- missing some vars because
	# SHPI got out of sync
	# dblog("_extractVarsInner: **************** Try extracting($1)");
	return _extractVarsInner($1, $context, $res);
    }
    while ($line) {
	if ($line =~ s@^<(v[asht])>(.*?)</\1>@@) {
	    _extract_var($1, $2, $context, $res);
	} elsif ($line =~ /^[^<]*<(?:com|pod)>/) {
	    last;
	} elsif ($line =~ s@^<quote>(.*?)</quote>(.*?)<quote>(.*?)</quote>@@) {
	    _extract_string($1, $2, $res);
	} elsif ($line =~ s@^<(\w+)>(.*?)</\1>@@) {
	    #print "Skipping $1:$2...\n";
	} elsif ($line =~ s@^(.+?)(?=<)@@) {
	    #print "Skipping over [$1]\n";
	} else {
	    last;
	}
    }
}

# Pull all vars out of expressions and quoted strings.
sub _extractVars {
    my $line = shift;
    my $res = {};
    _extractVarsInner($line, 0, $res);
    return $res;
}

sub _getProximityVars($$$) {
    my ($pkg, $filename, $line) = @_;
    local *dbline = $main::{'_<' . $filename};
    my $limBack = 30;
    my $limFwd = 2;
    my $finalBack = $line - $limBack;
    $finalBack = 0 if $finalBack < 0;
    my $finalFwd;
    my $areaStart;
    my $inSub = 0;
    for ($areaStart = $line; $areaStart > $finalBack; $areaStart--) {
	my $thisLineText = $dbline[$areaStart];
	if ($thisLineText =~ /^\s*sub\b/) {
	    $inSub = 1;
	    last;
	}
    }
    $finalBack = $areaStart;
    my $fileSize = scalar @dbline;
    $finalFwd = $line + $limFwd;
    $finalFwd = $fileSize if $finalFwd > $fileSize;
    $formatFinalFwd = $finalFwd;
    # If we have a formatter, take advantage of its statefulness
    # to process a sub at a time.
    #
    # This doesn't work so well for cgi.pm-like modules that are
    # full of strings waiting to be eval'ed.
    #
    if ($formatter) {
	while ($formatFinalFwd < $fileSize &&
	       $formatFinalFwd < $finalFwd + 30) {
	    if ($dbline[$formatFinalFwd] &&
		$dbline[$formatFinalFwd] =~ /^\s{0,4}\}\s*$/) {
		last;
	    }
	    ++$formatFinalFwd;
	}
    }
    if ($inSub) {
	my $areaEnd = $finalFwd;
	# See if there's a possible close-brace
	foreach $areaEnd ($line .. $finalFwd) {
	    my $thisLineText = $dbline[$areaEnd] || "";
	    if ($thisLineText =~ /^\}/) {
		$finalFwd = $areaEnd;
		last;
	    }
	}
    }
    dblog("Doing prox vars for file $filename\[$finalBack - $finalFwd\]");
    my %proximityvars;

    my $currProxVarTable;
    my %each_vars;
    my $each_ptn = qr/each (\%\w+)/;
    # First get the each-vars up to the cutoff point, regardless
    # of whether we're using the formatter or not.
    my $currProxVarEachVarTable = ($proxVarEachVarTable{$filename} ||= []);
    if (!defined ($currProxVarEachVarTable->[$finalFwd])) {
	# And now pick up the list of each vars
	# Set each line to either 0 or a hash of the names
	foreach my $i ($finalBack .. $finalFwd) {
	    my @list = ($dbline[$i] =~ /$each_ptn/g);
	    $currProxVarEachVarTable[$i] = \@list || 0;
	}
    }
    # Pick up the each_vars in this run
    foreach my $i ($finalBack .. $finalFwd) {
	my $list = $currProxVarEachVarTable[$i];
	if ($list) {
	    foreach my $each_name (@$list) {
		$each_vars{$each_name} = 1;
	    }
	}
    }
    if ($formatter) {
	$currProxVarTable = ($proxVarTable{$filename} ||= []);
	if (!$currProxVarTable->[$finalFwd]) {
	    #XXX Don't be so quick to reset the formatter every time
	    $formatter->reset();
	    foreach my $i ($finalBack .. $formatFinalFwd) {
		if (!defined $currProxVarTable->[$i]) {
		    my $res = $formatter->format_string($dbline[$i]);
		    # dblog("format line $i ($dbline[$i]) => {$res}");
		    my $varHRef = _extractVars($res);
		    $currProxVarTable->[$i] = $varHRef;
		    # dblog("\$currProxVarTable->[$i] = $varHRef: " . join(" ", keys %$varHRef));
		# } else {
		    # dblog("Already did line $i of file $filename");
		}
	    }
	}
	# And now pick up the list of vars
	foreach my $i ($finalBack .. $finalFwd) {
	    foreach my $var (keys %{$currProxVarTable->[$i]}) {
		$proximityvars{$var} = undef;
	    }
	}
    } else {
	for my $_sourceString (@dbline[$finalBack .. $finalFwd]) {
	    # Remove definite (most likely) comments
	    my $sourceString = $_sourceString;
	    $sourceString = "" unless defined $sourceString;
	    $sourceString =~ s/#[^\"\']+$//m;

	    # Remove likely printf directives
	    if (my($s1, $s2, $s3) = ($sourceString =~ /^(.*?)s?printf\b(.*),?(.*)$/)) {
		$s2 =~ s/\%[a-zA-Z]//g;
		$sourceString = "$s1$s2$s3";
	    }
	    foreach my $var ($sourceString =~ /$proximityrgx/go) {
		my $sigil = substr($var, 0, 1);
		$var = substr($var, 1);
		my $indexerStart;
		if ($var =~ /^(.*)([\[\{])$/) {
		    $var = $1;
		    $indexerStart = $2;
		}
		if ($sigil eq "\$") {
		    if ($var =~ /^\#(.*)$/) {
			$proximityvars{'@' . $1} = undef;
		    } else {
			if ($indexerStart) {
			    $sigil = $indexerStart eq "\[" ? "\@" : "\%";
			}
			$proximityvars{"$sigil$var"} = undef;
		    }
		} elsif ($sigil eq "\%") {
		    $proximityvars{"$sigil$var"} = undef;
		} else {
		    # Map to hash-slices
		    $sigil = "\%" if ($indexerStart && $indexerStart eq "\{");
		    $proximityvars{"$sigil$var"} = undef;
		}
	    }
	}
    }
    foreach my $each_var_name (keys %each_vars) {
        delete $proximityvars{$each_var_name};
    }

    # Use the source strings to find longer expressions

    my %candidates = ();
    my $qr_sep = qr/[^a-zA-Z_ \t]/;
    my $cref = $formatter ? \%candidates : \%proximityvars;
    for my $_sourceString (@dbline[$line - 2 .. $line]) {
	my $sourceString = $_sourceString;
	$sourceString = "" unless defined $sourceString;
	my %opposites =  ('{' => '}', '[' => ']', '(' => ')', '<' => '>', );
	# Pull out things that look like patterns.
	# Better to pull out too much, as we already used
	# SHPI to find things that are definitely variables.
	
	# dblog("Raw \$sourceString #1 : [$sourceString]");
	$sourceString =~ s/\bqr([\{\[\(\<]).*?(??{quotemeta $opposites{$1}})//g;
	# dblog("Fixed \$sourceString #2 : [$sourceString]");
	$sourceString =~ s/\bqr($qr_sep).*?\1//g;
	# dblog("Fixed \$sourceString #3 : [$sourceString]");
	$sourceString =~ s/\b[ms]([\{\[\(\<]).*?(??{quotemeta $opposites{$1}})//g;
	# dblog("Fixed \$sourceString #4 : [$sourceString]");
	$sourceString =~ s/\b[ms]($qr_sep).*?\1//g;
	# dblog("Fixed \$sourceString #5 : [$sourceString]");
	$sourceString =~ s/\\[\@\$\%\*]//g;
	# dblog("Fixed \$sourceString #6 : [$sourceString]");
	$sourceString =~ s/[\%\@]?\$+\{?[\w_\d]+//g;
	foreach my $var ($sourceString =~ /$specialVarRgx/go) {
	    $cref->{$var} = undef;
	}
	if ($formatter) {
	    foreach my $k (keys %candidates) {
		$proximityvars{$k} = undef;
	    }
	}
    }
    # Now filter out the proximity vars that might cause trouble
    foreach my $vname (keys %proximityvars) {
	if ($vname =~ /->/) {
	    if ($vname =~ /[\[\{][^\]\}]+->/) {
		# Drop complex expressions that have an arrow inside an indexer
		dblog("**** Drop \$proximityvars{$vname}");
		delete $proximityvars{$vname};
	    } else {
		# We're going to walk bit by bit now to avoid
		# autovivification
		dblog("**** Work on \$proximityvars{$vname}");
		my @vparts = split(/->/, $vname);
		my $vpart;
		eval {
		    my $first_part = shift @vparts;
		    $vpart = eval($first_part);
		    dblog("eval(first_part = $first_part) = $vpart)");
		    while ($vpart && ref $vpart && @vparts) {
			my $vp2 = shift @vparts;
			if ($vp2 =~ /^\[(.*)\]$/) {
			    dblog("**** try [$1]");
			    $vpart = eval { $vpart->[eval($1)] };
			    dblog("**** after $1, result is ($vpart)");
			} elsif ($vp2 =~ /^\{(.*)\}$/) {
			    dblog("**** try {$1}");
			    $vpart = eval { $vpart->{eval($1)} };
			    dblog("**** after $1, result is ($vpart)");
			} else {
			    undef $vpart;
			    dblog("**** can't deal with [$vp2], bailing out");
			}
		    }
		};
		if (!$vpart) {
		    delete $proximityvars{$vname};
		} else {
		    $proximityvars{$vname} = $vpart;
		}
	    }
	}
    }
    my @results = map { [$_, $proximityvars{$_}, 1] } keys %proximityvars;
    if (!$proximityvars{'$_'}) {
	my $dollar_under_val = eval('$_');
	if (defined $dollar_under_val) {
	    push(@results, ['$_', $dollar_under_val, 1]);
	}
    }
    return \@results;
}

sub _guessScalarOrArray($) {
    my $valsARef = shift;
    if (!$valsARef) {
	return [];
    }
    my $size = scalar @$valsARef;
    if ($size == 0) {
	return "";
    } elsif ($size == 1) {
	return $valsARef->[0];
    } else {
	foreach my $currLine (@$valsARef) {
	    if (ref $currLine) {
		return $valsARef;
	    } elsif ($currLine !~ /\n$/) {
		return $valsARef;
	    }
	}
	# They're all strings
	return join('', @$valsARef);
    }
}

sub _isPrintable($$) {
    my($ibBuffer, $valRef) = @_;
    if ($ibBuffer =~ /^[\s\(]*[\*\&]/) {
	return;
    } elsif ($ibBuffer =~ /^\s*sub\b/) {
	return;
    }
    require overload;
    return (overload::Overloaded($valRef)
            || $valRef =~ /HASH|ARRAY|SCALAR/
            || (ref $valRef) =~ /Regexp/);
}

sub _removeLocalizers($) {
    require DB::Text::Balanced;
    my ($code) = @_;
    if ($code =~ /<</) {
	# Workaround bug in DB::Text::Balanced (or my understanding of it),
	# if there's a here-doc here
	#
	# This is a known bug
	# See http://rt.cpan.org/NoAuth/Bug.html?id=752
	# for more info.
	
	s/^\s*(?:my|local)\b//;
	return $code;
    }
    
    my @list = (sub { DB::Text::Balanced::extract_quotelike($_[0],'') },
		sub { DB::Text::Balanced::extract_codeblock($_[0],'{}','') },
    );
    my @parts = DB::Text::Balanced::extract_multiple($code, \@list);
    local $_;
    foreach (@parts) {
	my $char1 = substr($_, 0, 1);
	if ($char1 eq '{') {
	    # Do nothing
	} elsif ($char1 =~ /^[\"\']/
		 || /^q[rwxq]?\b/) {
	    # Do nothing
	} else {
	    s/^\s*(?:my|local)\b//g;
	    s/([;\\])\s*(?:\#.*\n\s*)*(?:my|local)\b/$1/g;
	}
    }
    return join("", @parts);
}

sub _source_handle_missing_podlines {
    my ($beginLine, $endLine, $dblines) = @_;
    my @copy = @$dblines[$beginLine .. $endLine];
    # Perl strips away the pod lines as a cheap way of
    # determining which lines are breakable -- sort of
    # -- we need to put something
    # back or Komodo goes berserk.

    my $eol;
    if ($copy[0] =~ /([\r\n]+)$/) {
	$eol = $1;
    } else {
	$eol = "\n";
    }
    for (my $i = 0; $i <= $#copy; ++$i) {
	dblog("Processing line $i : <<$copy[$i]>>");
	if (!defined $copy[$i]) {
	    if (substr($copy[$i - 1], 0, 1) == "=") {
		$copy[$i] = "<pod dropped>$eol";
		dblog("Setting line $i to pod-dropped");
		while (++$i <= $#copy && !defined $copy[$i]) {
		    $copy[$i] = "?$eol";
		    dblog("Setting line $i to unknown");
		}
		if ($i <= $#copy) {
		    if ($copy[$i] !~ /[\r\n]$/) {
			$copy[$i] = "=cut$eol";
		    } else {
			dblog("Hey, line $i : $copy[$i] already ends with nl");
		    }
		} else {
		    dblog("Ran off the end of the file");
		}
	    } else {
		dblog("line $i is undefined, but prev line = $copy[$i - 1]");
		$copy[$i] = "$eol";
	    }
	} elsif ($copy[$i] !~ /[\r\n]$/) {
	    dblog("line $i ($copy[$i]) doesn't end with newline");
	    if ($copy[$i - 1] =~ /^[\?=]/ && length($copy[$i]) == 0) {
		$copy[$i] = "=cut$eol";
	    } else {
		$copy[$i] .= "$eol";
	    }
	}
    } 
    return join("", @copy);
}

sub _source_handle_missing_podlines_1 {
    my ($perlFileName, $beginLine, $endLine, $dblines) = @_;
    my $sourceString;
    local $@;
    if ($perlFileName) {
	dblog("source: using file [$perlFileName]\n") if $ldebug;
	eval {
	    open my $fh, "<", $perlFileName;
	    if ($fh) {
		local $/ = undef;
		$sourceString = <$fh>;
		close $fh;
	    }
	};
	if ($@) {
	    dblog("open file $perlFileName: $@\n") if $ldebug;
	}
    }
    if (!defined $sourceString) {
	if (defined &INC && $perlFileName =~ m,^/(Perl\w{3}/|<.*?>)(.*),) {
	    my $pdkUtilityName = $1;
	    $sourceString = INC($2);
	    if ($ldebug && defined $sourceString) {
		my @lines = split(/\n/, $sourceString);
		$lines = \@lines;
		dblog("Debugging a $pdkUtilityName module, grab source and get [" . join("\n", @lines[0..2]) . "]");
	    }
	};
	if (!defined $sourceString) {
	    my $fname = '_<' . $perlFileName;
	    eval {
		local *dbline = $main::{$fname};
		$endLine = $opts{e} || $#dbline;
		$endLine < $beginLine and $endLine = $beginLine;
		$sourceString = _source_handle_missing_podlines($beginLine,
								$endLine,
								$dblines);
	    };
	}
	if (!defined $sourceString) {
	    if (!$@) {
		$@ = "# Error: Komodo couldn't find the file $perlFileName\n";
	    }
	}
    }
    return ($sourceString, $@);
}
    

sub _trimExceptionInfo($) {
    my $error = shift;
    $error =~ s/ at (?:\(eval \d+\))?\[.*:\d+\] line \d+, at .+$//;
    return $error;
}

# Better to wrap the function than to override it,
# as the user code might rely on alarm() faulting on
# certain systems.

sub db_alarm {
    return if $skip_alarm;
    my $time = shift;
    local $@;
    eval {
	alarm($time);
    };
    $skip_alarm = 1 if $@;
}

# DB::eval returns an array, but we can do better
sub eval_term {
    my ($term) = @_;
    my $valRef;
    my $firstChar = substr($term, 0, 1);
    $DB::no_value = undef;
    $evalarg = $term;
    if ($firstChar eq '@') {
	my @tmp = &eval();
	if ($DB::no_value) {
	    @tmp = ();
	}
	$valRef = \@tmp;
    } elsif ($firstChar eq '%') {
	my %tmp = &eval();
	if ($DB::no_value) {
	    %tmp = ();
	}
	$valRef = \%tmp;
    } else {
	# eval always fires in array context
	my @tmp = &eval();
	if ($DB::no_value) {
	    $valRef = \undef;
	} else {
	    $valRef = _guessScalarOrArray(\@tmp);
	}
    }
}

sub DB {
    if ($full_bypass) {
	($pkg, $filename, $line) = caller;
	dblog("Bypassing ($pkg, $filename, $line)");
	return;
    }
    # return unless $ready;
    if (! $ready) {
	#### dblog("Not ready in DB -- returning\n") if $ldebug;
	return;
    }
    db_alarm(0);

    # do important stuff
    #
    &save;
    ($pkg, $filename, $line) = caller;
    if (!defined $startedAsInteractiveShell) {
	# This won't work with code that changes $0 to "-e"
	# in a BEGIN block.
	if ($0 eq '-e') {
	    $startedAsInteractiveShell = 1;
	    if (!$supportedCommands{interact}) {
		not_ready_for_5_005("Using the interactive shell", "", "Getopt/Std.pm");
	    }		
	    $stopReason = STOP_REASON_INTERACT;
	    emitBanner();
	} else {
	    $startedAsInteractiveShell = 0;
	    $stopReason = STOP_REASON_BREAK;
	}
    }
    if ($ldebug && $pkg !~ /^DB::/) {
	dblog("In $pkg, $filename, $line\n");
    }
    
    $usercontext = '($@, $!, $,, $/, $\, $^W) = @saved;' .
	"package $pkg;";	# this won't let them modify, alas

    if ($filename =~ s/ \(autosplit .*$//) {
	my $substr = $Config::Config{prefix};
	$filename =~ s/^\.\./$substr/;
    }

    if ($pkg eq 'DB::fake') {
	# Fallen off the end, so allow debugging
	# Set the DB::eval context appropriately.
	if (exists $firstFileInfo{file}) {
	    ($pkg, $filename, $line) = @firstFileInfo{qw/pkg file lastLine/};
	    $line = $firstFileInfo{lastLineNumber};
	} else {
	    $pkg     = 'main';
	}
	$usercontext =
	    '($@, $!, $^E, $,, $/, $\, $^W) = @saved;' .
		"package $pkg;"; # this won't let them modify, alas
	if ($runnonstop) {
	    exit 0;
	}
	$supportedCommands{'detach'} = 1;
	# This just doesn't make sense: at the end of the program,
	# we aren't executing anymore.
	# But we can look at the global variables
	# $supportedCommands{'stack_get'} = 0;
	$supportedCommands{'context_get'} = 0;
	$single = 1;
    } elsif ($runnonstop) {
	db_alarm($_pending_check_interval);
	return;
    } elsif (!$sentInitString) {
	sendInitString();
	$sentInitString = 1;
    }


    local $fileNameURI;
    local $fileNameURINo;

    my $canPerlFileName = canonicalizeFName($filename);
    if (exists $perlNameToFileURINo{$canPerlFileName}) {
	$fileNameURINo = $perlNameToFileURINo{$canPerlFileName};
	($fileNameURI, undef, undef) = @{$fileNameTable[$fileNameURINo]};
    } else {
	$fileNameURI = filenameToURI($filename, 1);
	$fileNameURINo = internFileURI($fileNameURI);
    }

    local(*dbline) = "::_<$filename";
    if ($ldebug && $pkg eq 'DB::fake') {
	dblog $dbline[$line];
    }
    if ($filename =~ /\(eval (\d+)\)\[(.*):(\d+)\]$/) {
	internEvalURI($filename, \@dbline);
    }
    if ($pkg !~ /^DB::/) {
	if (! exists $firstFileInfo{file}) {
	    $firstFileInfo{file} = $filename; # Perl file name
	    $firstFileInfo{pkg} = $pkg;
	    $firstFileInfo{lastLine} = $line; # last line executed
	    $firstFileInfo{lineInfo} = \@dbline;
	    $firstFileInfo{lastLineNumber} = $#dbline;
	} elsif ($firstFileInfo{file} eq $filename) {
	    $firstFileInfo{lastLine} = $line; # last line executed
	}
    }
    
    $max = $#dbline;
    if (!$single) {
	$bkptInfoRef = lookupBkptInfo($fileNameURINo, $line);
	processPossibleBreakpoint($bkptInfoRef, "File $fileNameURINo, line $line", $line);
    }

    # If we have any watch expressions ...
    if (!$single && ($trace & 2) && $pkg !~ /^DB::/) {
        for (my $i = 0 ; $i <= $#to_watch ; $i++) {
            $evalarg = $to_watch[$i];

            # Fix context DB::eval() wants to return an array, but
            # we need a scalar here.
            my ($val) = join (' ', &eval );
            $val = ((defined $val) ? "'$val'" : 'undef');

            # Did it change?
            if ($val ne $old_watch[$i]) {
		dblog("checking watches, {$to_watch[$i]} was [$old_watch[$i]], not [$val]");
                # Yep! Show the difference, and fake an interrupt.
                $signal = 1;
                $old_watch[$i] = $val;
		last;
            }
        }
    }

    if (($single || $signal)
	&& ($pkg eq 'DB::fake' || $pkg !~ /^DB::/)
	&& !$inPostponed) {
        # Yes, go down a level.
        local $level = $level + 1;
	if ($ldebug) {
	    dblog "file:$filename, line:$line, package:$pkg\n";
	    dblog ($#stack . " levels deep in subroutine calls!\n") if $single & 4;
	}
	# Send a status thing back
	if ($pkg eq 'DB::fake') {
	    # Do nothing
	} elsif (defined $lastContinuationCommand) {
	  printWithLength(sprintf(qq(%s\n<response %s command="%s" status="%s"
				       reason="ok" transaction_id="%s"/>),
				  xmlHeader(),
				  namespaceAttr(),
				  $lastContinuationCommand,
				  $lastContinuationStatus,
				  $lastTranID));
	}
	$stopReason = STOP_REASON_BREAK;

	# command loop
	local $@;
      CMD:
	while (1) {
	    # dblog("About to get the command...\n") if $ldebug;
	    $cmd = &readline();
	    if ($cmd eq '') {
		# dblog("Got no command\n") if $ldebug;
		exit 0;
	    }
	    dblog("Got command [$cmd]\n") if $ldebug;

	    $single = 0;
	    $signal = 0;

	    #### print OUT "cmd: $cmd\n";
	    local @cmdArgs;
	    # For now assume commands use urlencoding
	    eval { @cmdArgs = splitCommandLine($cmd); };
	    if ($@) {
		makeErrorResponse("cmd",
				  -1,
				  1,
				  "Failed to parse command-line [$cmd]");
		next CMD;
	    }
	    local $transactionID;
	    $transactionID = getArg(\@cmdArgs, '-i');

	    # Enter the big pseudo-switch stmt.

	    my $cmd = $cmdArgs[0];
	    if (exists $supportedCommands{$cmd}) {
		if (!$supportedCommands{$cmd}) {
		    printWithLength(sprintf
				    (qq(%s\n<response %s command="%s" 
					transaction_id="%s" ><error code="%d" apperr="4">
					<message>command '%s' not currently supported</message>
					</error></response>),
				     xmlHeader(),
				     namespaceAttr(),
				     $cmd,
				     $transactionID,
				     DBP_E_CommandUnimplemented,
				     $cmd,
				     ));
		    next CMD;
		}
	    } else {
		printWithLength(sprintf
				(qq(%s\n<response %s command="%s" 
				    transaction_id="%s" ><error code="%d" apperr="4">
				    <message>command '%s' not recognized</message>
				    </error></response>),
				 xmlHeader(),
				 namespaceAttr(),
				 $cmd,
				 $transactionID,
				 DBP_E_UnrecognizedCommand,
				 $cmd,
				 ));
		next CMD;
	    }

	    if ($cmd eq 'status') {
		printWithLength(sprintf
				(qq(%s\n<response %s command="status" status="%s"
				    reason="ok" transaction_id="%s"/>),
				 xmlHeader(),
				 namespaceAttr(),
				 $startedAsInteractiveShell ? 'interactive' : getStopReason(),
				 $transactionID));

	    } elsif ($cmd eq 'feature_get') {
		local $featureName = getArg(\@cmdArgs, '-n');
		local ($supported, $innerText);

		if (! defined $featureName) {
		    $featureName = "unspecified";
		    $supported = 0;
		    $innerText = "";
		} elsif (exists $supportedCommands{$featureName}) {
		    $supported = $supportedCommands{$featureName};
		    $innerText = "";
		} elsif (exists $supportedFeatures{$featureName}) {
		    my @vals = @{$supportedFeatures{$featureName}};
		    $supported = $vals[0];
		    if (!$vals[2] || !exists $settings{$featureName}) {
			$innerText = "";
		    } else {
			$innerText = $settings{$featureName}->[0];
		    }
		} else {
		    # Command not recognized
		    $supported = 0;
		    $innerText = "";
		}
		printWithLength(sprintf
				(qq(%s\n<response %s command="%s" feature_name="%s"
				    supported="%d" transaction_id="%s">%s</response>),
				 xmlHeader(),
				 namespaceAttr(),
				 $cmd,
				 $featureName,
				 $supported,
				 $transactionID,
				 $innerText));
		if ($transactionID == 1 && $DB::finished) {
		    # Observed behavior: we've hit the END block,
		    # and called DB::fake::at_exit(),
		    # but the debugger is still calling us.  Let's
		    # tell it that we've stopped, and then stop.
		    #
		    # This came up in bug 33128.

		    close $IN;
		    close $OUT;
		    exit 0;
		}

	    } elsif ($cmd eq 'feature_set') {
		local $featureName = getArg(\@cmdArgs, '-n');
		local $featureValue = getArg(\@cmdArgs, '-v');
		local ($status, $success, $reason);

		# $success not used
		$reason = undef;
		if (!defined $featureName) {
		    $success = 0;
		    $reason = "Command not specified";
		} elsif (!exists $supportedFeatures{$featureName}) {
		    $status = 0;
		    $reason = "Command $featureName not recognized";
		} else {
		    my $vals = $supportedFeatures{$featureName};
		    if (!$vals->[1]) {
			$status = 0;
			$reason = "Command $featureName not modifiable";
		    } elsif (!$vals->[2]) {
			# No associated data, use boolean value in
			# table
			$vals->[0] = $featureValue ? 1 : 0;
			$status = 1;
			$success = $vals->[0];
		    } elsif (!exists $settings{$featureName}) {
			$status = 0;
			$reason = "Command $featureName not in settings table";
		    } else {
			my $svals = $settings{$featureName}->[1];
			if (!defined $svals) {
			    $status = 0;
			    $reason = "Command $featureName is readonly settings table";
			} elsif ($svals == 1) {
				# Hardwire numeric values
			    if ($featureValue =~ /^\d+$/) {
				$status = 1;
				$settings{$featureName}->[0] = $featureValue;
			    } else {
				$status = 0;
				$reason = "Command $featureName value of $featureValue isn't numeric.";
			    }
			} elsif ($svals == 'a') {
				# Allow any ascii data
			    $status = 1;
			    $settings{$featureName}->[0] = $featureValue;
			} elsif (ref $svals eq 'ARRAY') {
			    $status = 0;
			    foreach my $allowedValue (@$svals) {
				if ($featureValue eq $allowedValue) {
				    $status = 1;
				    $settings{$featureName}->[0] = $featureValue;
				    last;
				}
			    }
			    if (!$status) {
				$reason = "Command $featureName value of $featureValue isn't an allowed value.";
			    }
			} else {
			    $status = 0;
			    $reason = "Command $featureName=$featureValue, can't deal with current setting of " . ref $vals . "\n";
			}
		    }
		}
		printWithLength(sprintf
				(qq(%s\n<response %s command="%s" feature_name="%s"
				    success="%d" transaction_id="%s" %s/>),
				 xmlHeader(),
				 namespaceAttr(),
				 $cmd,
				 $featureName,
				 $status,
				 $transactionID,
				 $reason ? ('reason="' . $reason . '"') : ''
				 ));

		# Continuation commands
	    } elsif ($cmd eq 'run') {
		if ($finished and $level <= 1) {
		    end_report($cmd, $transactionID);
		    next CMD;
		}
		$lastContinuationCommand = $cmd;
		$lastContinuationStatus = 'break';
		$lastTranID = $transactionID;
		my $getNextCmd;

		# debug message
		if ($fakeFirstStepInto) {
		    $bkptInfoRef = lookupBkptInfo($fileNameURINo, $line);
		    if ($bkptInfoRef) {
			dblog("hit a breakpoint at first breakable line");
			$getNextCmd = 1;
		    } else {
			dblog("\$fakeFirstStepInto was true, turning it off.");
			dblog("\$single = $single");
			$getNextCmd = 0;
		    }
		    $fakeFirstStepInto = 0;
		} else {
		    $getNextCmd = 0;
		    $interact_str = undef;
		}
		# dblog("Continuing...\n") if $ldebug;

		# continue
		for ($i=0; $i <= $#stack; ) {
		    $stack[$i++] &= ~1;
		}
		if ($getNextCmd) {
		    printWithLength(sprintf
				    (qq(%s\n<response %s command="%s"
					status="break"
					reason="ok" transaction_id="%s"/>),
				     xmlHeader(),
				     namespaceAttr(),
				     $cmd,
				     $transactionID));
		    next CMD;
		} else {
		    $stopReason = STOP_REASON_RUNNING;
		    last CMD;
		}

	    } elsif ($cmd eq 'break') {
		$fakeFirstStepInto = 0;
		printWithLength(sprintf
				(qq(%s\n<response %s command="%s"
				    status="break"
				    success="1"
				    transaction_id="%s"/>),
				 xmlHeader(),
				 namespaceAttr(),
				 $cmd,
				 $transactionID));
		next CMD;
	    } elsif ($cmd eq 'step_into') {
		if ($finished and $level <= 1) {
		    end_report($cmd, $transactionID);
		    next CMD;
		} elsif ($fakeFirstStepInto) {
		    # We're already at position 1, so don't go anywhere.
		    $fakeFirstStepInto = 0;
		    printWithLength(sprintf
				    (qq(%s\n<response %s command="%s"
					status="break"
					reason="ok" transaction_id="%s"/>),
				     xmlHeader(),
				     namespaceAttr(),
				     $cmd,
				     $transactionID));
		    next CMD;
		}
		$interact_str = undef;

		$lastContinuationCommand = $cmd;
		$lastContinuationStatus = 'break';
		$lastTranID = $transactionID;
		# debug message
		dblog("Stepping into...\n") if $ldebug;

		# step into
		$single = 1;
		$stopReason = STOP_REASON_RUNNING;
		last CMD;

	    } elsif ($cmd eq 'step_over') {
		if ($finished and $level <= 1) {
		    end_report($cmd, $transactionID);
		    next CMD;
		} elsif ($fakeFirstStepInto) {
		    # We're already at position 1, so don't go anywhere.
		    $fakeFirstStepInto = 0;
		    printWithLength(sprintf
				    (qq(%s\n<response %s command="%s"
					status="break"
					reason="ok" transaction_id="%s"/>),
				     xmlHeader(),
				     namespaceAttr(),
				     $cmd,
				     $transactionID));
		    next CMD;
		}

		$interact_str = undef;

		$lastContinuationCommand = $cmd;
		$lastContinuationStatus = 'break';
		$lastTranID = $transactionID;
		# debug message
		dblog("Stepping over...\n") if $ldebug;

		# step over
		$single = 2;
		$stopReason = STOP_REASON_RUNNING;
		last CMD;

	    } elsif ($cmd eq 'step_out') {
		if ($finished and $level <= 1) {
		    end_report($cmd, $transactionID);
		    next CMD;
		}
		my $getNextCmd;
		# This is more like starting with a run than a step
		# So always check $fakeFirstStepInto to 0.
		if ($fakeFirstStepInto) {
		    $bkptInfoRef = lookupBkptInfo($fileNameURINo, $line);
		    if ($bkptInfoRef) {
			dblog("hit a breakpoint at first breakable line");
			$getNextCmd = 1;
		    } else {
			dblog("\$fakeFirstStepInto was true, turning it off.");
			$getNextCmd = 0;
		    }
		    $fakeFirstStepInto = 0;
		} else {
		    $getNextCmd = 0;
		}
		$interact_str = undef;

		$lastContinuationCommand = $cmd;
		$lastContinuationStatus = 'break';
		$lastTranID = $transactionID;
		# debug message
		dblog("Stepping out...\n") if $ldebug;

		# step out
		$stack[$stack_depth] |= 2;
		if ($getNextCmd) {
		    printWithLength(sprintf
				    (qq(%s\n<response %s command="%s"
					status="break"
					reason="ok" transaction_id="%s"/>),
				     xmlHeader(),
				     namespaceAttr(),
				     $cmd,
				     $transactionID));
		    next CMD;
		} else {
		    $stopReason = STOP_REASON_RUNNING;
		    last CMD;
		}

	    } elsif ($cmd eq 'stop') { #xxxstop
		$fall_off_end = 1;
		$stopReason = STOP_REASON_STOPPING;
		printWithLength(sprintf(qq(%s\n<response %s command="%s" status="%s"
					   reason="ok" transaction_id="%s"/>),
					xmlHeader(),
					namespaceAttr(),
					$cmd,
					'stopped',
					$transactionID));
		dblog("Exiting script on stop command ...\n") if $ldebug;
		close $IN;
		close $OUT;
		exit 0;

	    } elsif ($cmd eq 'detach') {
		$stopReason = STOP_REASON_STOPPED;
		$runnonstop = 1;
		# Disable all the move commands
		map { $supportedCommands{$_} = 0 } (qw(run step_into step_over step_out detach));
		# status will be emitted when the program hits the end
		$lastContinuationCommand = $cmd;
		$lastContinuationStatus = 'stopping';
		$lastTranID = $transactionID;
		last CMD;

		# Breakpoint commands...
	    } elsif ($cmd eq 'breakpoint_update') {
		local %opts;
		{
		    local *ARGV = *cmdArgs;
		    shift @ARGV;
		    getopts('d:h:n:o:r:s:t:', \%opts);
		}
		my $bkptID = $opts{d};
		my $bNewState = $opts{s} || BKPT_REQ_ENABLED;
		my $bIsTemporary = $opts{r} ? 1 : 0;
		my $bHitCount = $opts{h};
		my $bHitConditionOperator = $opts{o};

		# Currently ignored:
		# -n <line no>

		local ($bFileURINo, $bLine, $bType, $bFunction, $bException);
		local $bptErrorCode = 0;
		local $bptErrorMsg;
		local $bFileURI;
		local $fileNameTableInfo;
		my $bpCmd;
		my $bHitInfo;
		($bFileURINo, $bLine, $bState, $bType, $bFunction, $bExpression, $bException, $bHitInfo) = getBkPtInfo($bkptID);
		if (!defined $bFileURINo) {
		    $bptErrorCode = DBP_E_NoSuchBreakpoint;
		    $bptErrorMsg = "Unknown breakpoint ID $bkptID.";
		} elsif (!($bFileURI = getURIByNo($bFileURINo))) {
		    $bptErrorCode = DBP_E_NoSuchBreakpoint;
		    $bptErrorMsg = "Unknown fileURI NO $bFileURINo.";
		} elsif (!($fileNameTableInfo = $fileNameTable[$bFileURINo])) {
		    $bptErrorCode = DBP_E_NoSuchBreakpoint;
		    $bptErrorMsg = "No fileURI info under URI NO $bFileURINo.";
		}		    

		if ($bptErrorCode == 0) {
		    $bpCmd = ($bNewState eq BKPT_REQ_DISABLED
				 ? BKPT_DISABLE
				 : ($bIsTemporary
				    ? BKPT_TEMPORARY
				    : BKPT_ENABLE));
		    if (!setBkPtState($bkptID, $bpCmd)) {
			$bptErrorCode = DBP_E_BreakpointNotSet;
			$bptErrorMsg = sprintf("Can't %able breakpoint ID %s",
					       $bpCmd == BKPT_DISABLE ? 'dis' : 'en',

					       $bkptID);
		    } else {
			# Komodo only sends in changed values, so merge in old values
			if (!$bHitCount && $bHitInfo->[HIT_TBL_VALUE]) {
			    $bHitCount = $bHitInfo->[HIT_TBL_VALUE];
			}
			if (!$bHitConditionOperator && $bHitInfo->[HIT_TBL_COND_STRING]) {
			    $bHitConditionOperator = $bHitInfo->[HIT_TBL_COND_STRING];
			}
		    }
		}
		if ($bptErrorCode == 0) {
		    local $perlFileName = $fileNameTableInfo->[2];
		    local (*dbline) = $main::{'_<' . $perlFileName};

		    $dbline{$bLine} = $bpCmd == BKPT_ENABLE ? 1 : 0;
		    if ($bHitCount) {
			setBkPtHitInfo($bkptID, $bHitCount, $bHitConditionOperator);
		    } elsif (!$bHitInfo
			     || !defined $bHitInfo->[HIT_TBL_EVAL_FUNC]) {
			setNullBkPtHitInfo($bkptID);
		    } else {
			dblog("breakpoint_update -- doing nothing");
		    }
		    dblog("doing op $cmd\n") if $ldebug;
		    local $res = sprintf(qq(%s\n<response %s command="%s" 
					    transaction_id="%s" >),
					 xmlHeader(),
					 namespaceAttr(),
					 $cmd,
					 $transactionID);
		    my $bpInfo = getBreakpointInfoString($bkptID);
		    if (! defined $bpInfo || length $bpInfo == 0) {
			makeErrorResponse($cmd,
					  $transactionID,
					  DBP_E_NoSuchBreakpoint,
					  "Unknown breakpoint ID $bkptID.");
		    } else {
			$res .= $bpInfo;
			$res .= "\n</response>\n";
			dblog("$cmd => $res") if $ldebug;
			printWithLength($res);
		    }
		} else {
		    dblog "failed to do op $cmd (error code $bptErrorCode)\n" if $ldebug;
		    makeErrorResponse($cmd,
				      $transactionID,
				      $bptErrorCode,
				      $bptErrorMsg);
		}
	    } elsif ($cmd eq 'breakpoint_remove') {
		local $bkptID = getArg(\@cmdArgs, '-d');
		local ($bFileURINo, $bLine, $bState, $bType, $bFunction, $bException);
		local $bptErrorCode = 0;
		local $bptErrorMsg;
		local $bFileURI;
		($bFileURINo, $bLine, $bState, $bType, $bFunction, $bExpression, $bException) = getBkPtInfo($bkptID);
		if ($bType eq 'watch') {
		    dblog("Deleting watchpoint [$bExpression]");
		    my $i_cnt = 0;
		    foreach (@to_watch) {
			my $val = $to_watch[$i_cnt];

			# Does this one match the command argument?
			if ($val eq $bExpression) { # =~ m/^\Q$i$/) {
				# Yes. Turn it off, and its value too.
			    splice(@to_watch, $i_cnt, 1);
			    splice(@old_watch, $i_cnt, 1);
			    last;
			}
			$i_cnt++;
		    }		## end foreach (@to_watch)
		    if (--$numWatchPoints <= 0) {
			dblog("No more watching anything [\$numWatchPoints = $numWatchPoints]");
			$numWatchPoints = 0;
			$trace &= ~2;
		    } else {
			dblog("Still watching $numWatchPoints watchPoints");
		    }
		} elsif (!defined $bFileURINo) {
		    $bptErrorCode = DBP_E_NoSuchBreakpoint;
		    $bptErrorMsg = "Unknown breakpoint ID $bkptID.";
		} elsif (!($bFileURI = getURIByNo($bFileURINo))) {
		    $bptErrorCode = DBP_E_NoSuchBreakpoint;
		    $bptErrorMsg = "Unknown fileURI NO $bFileURINo.";
		}

		if (!deleteBkPtInfo($bkptID)) {
		    $bptErrorCode = DBP_E_NoSuchBreakpoint;
		    $bptErrorMsg = "Problems deleting breakpoint ID $bkptID";
		} else {
		    remove_FileURI_LineNo_Breakpoint($bFileURINo, $bLine);
		}
		if ($bptErrorCode == 0) {
		    my $res = sprintf(qq(%s\n<response %s command="%s" 
					 transaction_id="%s" />\n),
				      xmlHeader(),
				      namespaceAttr(),
				      $cmd,
				      $transactionID);
		    dblog("$cmd => $res") if $ldebug;
		    printWithLength($res);
		} else {
		    makeErrorResponse($cmd,
				      $transactionID,
				      $bptErrorCode,
				      $bptErrorMsg);
		}

	    } elsif ($cmd eq 'breakpoint_get') {
		local $bkptID = getArg(\@cmdArgs, '-d');
		local $res = sprintf(qq(%s\n<response %s command="%s" 
					transaction_id="%s" >),
				     xmlHeader(),
				     namespaceAttr(),
				     $cmd,
				     $transactionID);
		my $bpInfo = getBreakpointInfoString($bkptID);
		if (! defined $res || length $res == 0) {
		    makeErrorResponse($cmd,
				      $transactionID,
				      DBP_E_NoSuchBreakpoint,
				      "Unknown breakpoint ID $bkptID.");
		    next CMD;
		}
		$res .= $bpInfo;
		$res .= "\n</response>\n";
		dblog("$cmd => $res") if $ldebug;
		printWithLength($res);

	    } elsif ($cmd eq 'breakpoint_list') {
		local $res = sprintf(qq(%s\n<response %s command="%s" 
					transaction_id="%s" >),
				     xmlHeader(),
				     namespaceAttr(),
				     $cmd,
				     $transactionID);

		while (my ($fileURI, $fileURINo) = each %fileURILookupTable) {
		    my $fileURIInfo = $bkptLookupTable[$fileURINo];
		    if (!$fileURIInfo) {
			dblog("No breakpoint info for URI $fileURI ($fileURINo)\n") if $ldebug;
			next;
		    }
		    while (my ($lineNo, $bkptID) = each %$fileURIInfo) {
			my $bpInfo = getBreakpointInfoString($bkptID, fileURI => $fileURINo, lineNo => $lineNo);
			if ($bpInfo) {
			    $res .= $bpInfo;
			}
		    }
		}
		dblog("bpList: FQFnNameLookupTable: ", DB::Data::Dump::dump(%FQFnNameLookupTable)) if $ldebug;
		while (my ($bFunction, $val) = each %FQFnNameLookupTable) {
		    dblog("info($bFunction, $val): ", DB::Data::Dump::dump($val)) if $ldebug;
		    while (my ($bType, $bkptID) = each %$val) {
			my $bpInfo = getBreakpointInfoString($bkptID, function => $bFunction);
		    }
		}
		$res .= "\n</response>\n";
		dblog("$cmd => $res") if $ldebug;
		printWithLength($res);

	    } elsif ($cmd eq 'breakpoint_set') {

		local ($bFileURINo, $bLine, $bState, $bType, $bFunction, $bException, $bCondition);
		local $bkptID;
		local ($perlFileName, $bFileURI, $bFileName);
		local %opts;
		{
		    local *ARGV = *cmdArgs;
		    shift @ARGV;
		    getopts('c:f:h:m:n:o:r:s:t:x', \%opts);
		}

		# For now, set the filename to either $opts{f} or curr filename

		$bHitCount = $opts{h};
		$bFunctionName = $opts{m};
		$bLine = $opts{n} || $line;
		$bHitConditionOperator = $opts{o};
		$bIsTemporary = $opts{r} ? 1 : 0;
		$bState = $opts{s} || BKPT_REQ_ENABLED;
		$bType = $opts{t};
		$bException = $opts{x};
		local $perlFileName = undef;
		$bCondition = "";
		if (exists $opts{f}) {
		    $opts{f} =~ s@^dbgp:///file:/@file:/@;
		    $opts{f} =~ s@^file:/([^/])@file://$1@;
		}		

		getFileInfo(\%opts, 'f', $filename,
			    \$bFileURI,
			    \$bFileURINo,
			    \$bFileName,
			    \$perlFileName);
		$bptErrorCode = 0;
		$bptErrorMsg = undef;

		if ($opts{f} =~ m@^dbgp:///perl//(?:PerlApp/|<.*>)@) {
		    $bptErrorCode = DBP_E_BreakpointTypeNotSupported;
		    $bptErrorMsg = "Breakpoints in compiled modules are not supported.";
		} elsif (defined $bException) {
		    # Don't support break on exceptions
		    $bptErrorCode = DBP_E_BreakpointTypeNotSupported;
		    $bptErrorMsg = "Breaking on exceptions not supported.";
		} elsif (defined $bFunctionName) {
		    if (!defined $bType || ($bType ne 'call'
					    &&  $bType ne 'return')) {
			$bptErrorMsg = "Breaking on functions requires a breakpoint type of 'call' or 'return', got [$bType].";
			$bptErrorCode = DBP_E_InvalidOption;
		    }
		} elsif ($bType eq 'conditional') {
		    if (!defined $bLine) {
			$bptErrorCode = DBP_E_InvalidOption;
			$bptErrorMsg = "Line number required for setting a conditional breakpoint in Perl.";
		    } else {
			$bType = 'line';
			if ($cmdArgs[0] && length $cmdArgs[0]) {
			    $bCondition = $cmdArgs[0];
			    dblog("Got raw condition [$bCondition]") if $ldebug;
			    $bCondition = decodeData($bCondition);
			    dblog("Got decoded condition [$bCondition]") if $ldebug;
			} else {
			    $bptErrorCode = DBP_E_InvalidOption;
			    $bptErrorMsg = "Condition required for setting a conditional breakpoint.";
			}
		    }
		} elsif ($bType eq 'watch') {
		    if ($cmdArgs[0] && length $cmdArgs[0]) {
			$bCondition = $cmdArgs[0];
			dblog("Got raw condition [$bCondition]") if $ldebug;
			$bCondition = decodeData($bCondition);
			dblog("Got decoded condition [$bCondition]") if $ldebug;
			if ($bCondition) {
			    $evalarg = $bCondition;
			    my ($val) = join(' ', &eval);
			    $val = (defined $val) ? "'$val'" : 'undef';
			    push @to_watch, $bCondition;
			    push @old_watch, $val;
				# We are now watching expressions.
			    $trace |= 2;
			    ++$numWatchPoints;
			}
		    } else {
			$bptErrorCode = DBP_E_InvalidOption;
			$bptErrorMsg = "Expression required for setting a watchpoint.";
		    }
		} elsif (defined $bType && $bType ne 'line') {
		    $bptErrorMsg = "Breakpoint type of $bType not supported -- only 'line' is supported.";
		    $bptErrorCode = DBP_E_BreakpointTypeNotSupported;

		} elsif (!defined $bFileName && !defined $bLine) {
		    # Need a filename and a line no for breaking
		    $bptErrorMsg = "Filename and line number required for setting a breakpoint.";
		    $bptErrorCode = DBP_E_InvalidOption;
		} elsif ($bLine < 0) {
		    $bptErrorMsg = "Negative line numbers not supported (got [$bLine])";
		    $bptErrorCode = DBP_E_InvalidOption;
		} elsif ($bHitConditionOperator && ! defined $bHitCount) {
		    $bptErrorMsg = "Hit condition operator specified without a target hit count.";
		    $bptErrorCode = DBP_E_InvalidOption;
		}

		# Figure out our state
		if ($bptErrorCode == 0) {
		    if ($bState eq BKPT_REQ_ENABLED) {
			$bStateVal = $bIsTemporary ? BKPT_TEMPORARY : BKPT_ENABLE;
		    } elsif ($bState eq BKPT_REQ_DISABLED) {
			$bStateVal = BKPT_DISABLE;
		    } else {
			$bptErrorCode = DBP_E_BreakpointStateInvalid;
			$bptErrorMsg = "Breakpoint state '$bState' not recognized.";
		    }
		}

		if ($bptErrorCode != 0) {
		    makeErrorResponse($cmd,
				      $transactionID,
				      $bptErrorCode,
				      $bptErrorMsg);
		    next CMD;
		}

		if ($bFunctionName) {
		    my $bptCount =
			findAndAddFunctionBreakPoints($bFunctionName,
						      defined $opts{f} && $perlFileName,
						      $opts{n},
						      $bCondition,
						      $bStateVal,
						      $bIsTemporary,
						      $bType,
						      $bHitCount,
						      $bHitConditionOperator);
		    if ($bptCount == 0) {
			# No breakpoints found
			my $fname = $opts{f} || "any loaded file";
			my $msg = "Currently can't find sub $bFunctionName in $fname.";
			makeErrorResponse($cmd,
					  $transactionID,
					  DBP_E_NoSuchBreakpoint,
					  $msg);
			next CMD;
		    }
		} else {
		    # None of these can fail
		    if ($bType eq 'watch') {
			$bkptID = internFunctionName_watchedExpn($bCondition);
		    } else {
			$bkptID = internFileURINo_LineNo($bFileURINo, $bLine);
		    }
		    storeBkPtInfo($bkptID, $bFileURINo, $bLine, $bStateVal, $bType, $bCondition);
		    if ($bHitCount) {
			setBkPtHitInfo($bkptID, $bHitCount, $bHitConditionOperator);
		    } else {
			setNullBkPtHitInfo($bkptID);
		    }

		    #todo: add pending, etc. on the dbline thing
		    if (defined $perlFileName && $bStateVal != BKPT_DISABLE) {
			local $internalName = $main::{'_<' . $perlFileName};
			local (*dbline) = $main::{'_<' . $perlFileName};
			if (!($a = $dbline[$bLine]) || $a =~ /^\s*$/s) {
			    my $code = (($bLine < 1 || $bLine > $#dbline)
					? DBP_E_Unbreakable_InvalidCodeLine
					: DBP_E_Unbreakable_EmptyCodeLine);
			    $msg = "Line $bLine isn't breakable";
			    makeErrorResponse($cmd,
					      $transactionID,
					      $code,
					      $msg);
			    next CMD;
			}
			$dbline{$bLine} = 1;
			if ($ldebug) {
			    dblog("Here are the breakpoints for file [$perlFileName] (ID $bkptID, fileNum $bFileURINo):\n");
			    dblog((join(", ", grep ($dbline{$_}, keys %dbline)), "\n"));
			}
		    } else {
			if ($ldebug) {
			    my $str = "Curr file = |$filename|, bpt set for file |$bFileName|, bStateVal = |$bStateVal|, \$bFileURI = |$bFileURI|";
			    $str .= ", \$perlFileName=$perlFileName" if $perlFileName;
			    $str .= "\n";
			    dblog($str);
			}
			$postponed_fileuri{$bFileURINo} = 1;
		    }
		}

		printWithLength(sprintf
				(qq(%s\n<response %s command="%s" 
				    state="%s" id="%d" transaction_id="%s" />),
				 xmlHeader(),
				 namespaceAttr(),
				 $cmd,
				 $bState,
				 $bkptID,
				 $transactionID));

	    } elsif ($cmd eq 'stack_depth') {
		my @stackTrace = dump_trace(1);
		printWithLength(sprintf
				(qq(%s\n<response %s command="%s" 
				    depth="%d" transaction_id="%s" />),
				 xmlHeader(),
				 namespaceAttr(),
				 $cmd,
				 scalar(@stackTrace),
				 $transactionID,
				 ));

	    } elsif ($cmd eq 'stack_get') {
		local $stackDepth = getArg(\@cmdArgs, '-d');
		local $numLevelsToShow;
		if (!defined $stackDepth) {
		    $numLevelsToShow = 1e9; # Get them all
		} elsif ($stackDepth !~ /^\d+$/ || $stackDepth < 0) {
		    printWithLength(sprintf
				    (qq(%s\n<response %s command="%s" 
					transaction_id="%s" ><error code="%d" apperr="4">
					<message>%s</message>
					</error></response>),
				     xmlHeader(),
				     namespaceAttr(),
				     $cmd,
				     $transactionID,
				     DBP_E_StackDepthInvalid,
				     "Invalid stack depth arg of '$stackDepth'"));
		    next CMD;
		} else {
		    $numLevelsToShow = $stackDepth;
		}
		local $res = sprintf(qq(%s\n<response %s command="%s" 
					transaction_id="%s" >),
				     xmlHeader(),
				     namespaceAttr(),
				     $cmd,
				     $transactionID);
		my @sub = dump_trace(0); # , $numLevelsToShow);
		# dblog("raw stack trace = ", DB::Data::Dump::dump(@sub), "\n") if $ldebug;
		if (@sub && $sub[$#sub]->{line} == 0) {
		    # We have no active stacks at this point
		    @sub = ();
		}
		if (defined $stackDepth || scalar @sub == 0) {
		    if (defined $stackDepth) {
			if ($stackDepth > scalar @sub) {
			    printWithLength(sprintf
					    (qq(%s\n<response %s command="%s" 
						transaction_id="%s" ><error code="%d" apperr="4">
						<message>%s</message>
						</error></response>),
					     xmlHeader(),
					     namespaceAttr(),
					     $cmd,
					     $transactionID,
					     DBP_E_StackDepthInvalid,
					     "Invalid stack depth arg of '$stackDepth'"));
			    next CMD;
			}
			if ($stackDepth == 0) {
			    $res .= sprintf(qq(<stack level="%d"
					       type="%s"
					       filename="%s"
					       lineno="%s"
					       where="%s"/>),
					    $stackDepth,
					    checkForEvalStackType($sub[0]->{sub}),
					    calcFileURI $filename,
					    $line,
					    (($#sub >= 0 && $sub[0]{sub})
					     ? trimEvalSubNames ($sub[0]{sub})
					     : 'main'),
					    );
			} else {
			    my $sub2 = $sub[$stackDepth - 1];
			    dblog("raw stack trace [$stackDepth] = ", DB::Data::Dump::dump($sub2), "\n") if $ldebug;
			    $res .= sprintf(qq(<stack level="%d"
					       type="%s"
					       filename="%s"
					       lineno="%s"
					       where="%s"/>),
					    $stackDepth,
					    ($stackDepth == scalar @sub
					     ? $pkg
					     : checkForEvalStackType($sub[$stackDepth]->{sub})),
					    calcFileURI $sub2->{file},
					    $sub2->{line},
					    ($stackDepth == scalar @sub
					     ? 'main'
					     : trimEvalSubNames ($sub[$stackDepth]{sub})),
					    );
			}
		    } else {
			$res .= sprintf(qq(<stack level="%d"
					   type="%s"
					   filename="%s"
					   lineno="%s"
					   where="%s"/>),
					0,
					$pkg,
					calcFileURI $filename,
					$line,
					(($#sub >= 0 && $sub[0]{sub})
					 ? trimEvalSubNames ($sub[0]{sub})
					 : 'main'),
					);
		    }
		} else {
		    # We get back a stack of callers, and need to
		    # transform it into a stack of positions
		    $res .= sprintf(qq(<stack level="%d"
				       type="%s"
				       filename="%s"
				       lineno="%s"
				       where="%s"/>),
				    0,
				    checkForEvalStackType($sub[0]->{sub}), # where we are
				    calcFileURI $filename, # and where we were called
				    $line,
				    (($#sub >= 0 && $sub[0]{sub})
				     ? trimEvalSubNames($sub[0]{sub})
				     : 'main'),
				    );

		    for ($i = 1 ; $i <= $#sub ; $i++) {
			$res .= sprintf(qq(<stack level="%d"
					   type="%s"
					   filename="%s"
					   lineno="%s"
					   where="%s"/>),
					$i,
					checkForEvalStackType($sub[$i]->{sub}),
					calcFileURI $sub[$i - 1]->{file},
					$sub[$i - 1]->{line},
					trimEvalSubNames($sub[$i]{sub}),
					);
		    }
		    $res .= sprintf(qq(<stack level="%d"
				       type="%s"
				       filename="%s"
				       lineno="%s"
				       where="%s"/>),
				    $i,
				    $pkg,
				    calcFileURI $sub[$#sub]->{file},
				    $sub[$#sub]->{line},
				    'main');
		}
		$res .= "\n</response>\n";
		# dblog("$cmd => $res") if $ldebug;
		printWithLength($res);

	    } elsif ($cmd eq 'context_names') {
		local $stackDepth = getArg(\@cmdArgs, '-d');
		emitContextNames($cmd,
				 $transactionID);

	    } elsif ($cmd eq 'context_get') {
		local $stackDepth = getArg(\@cmdArgs, '-d');
		local $context_id = getArg(\@cmdArgs, '-c');
		$stackDepth = 0 unless defined $stackDepth;
		local $settings{max_depth}[0] = 0;
		my $currStackSize = scalar dump_trace(0); # , $numLevelsToShow;
		dblog("main->getContextProperties: \$currStackSize = $currStackSize\n") if $ldebug;
		my $namesAndValues;
		if ($context_id == FunctionArguments) {
		    my @savedArgs;
		    my $actualStackDepth = $stackDepth + 1;
		    while (1) {
			@unused = caller($actualStackDepth);
			if (!@unused) {
			    last;
			} elsif ($unused[3] eq '(eval)' && !$unused[4]) {
			    $actualStackDepth++;
				# dblog("context_get: moving up to level $actualStackDepth");
			} else {
				# dblog("context_get: settle on caller => [@unused]");
				# dblog("stack depth [$actualStackDepth]: curr args are [", join(", ", @DB::args), "]") if $ldebug;
			    @savedArgs = @DB::args;
			    last;
			}
		    }
		    if (@savedArgs) {
			# Are there args?  This gets around Perl's
			# behavior where if caller fails it doesn't
			# change the value of @DB::args

			# dblog("caller => [@unused]");
			# dblog("stack depth [$stackDepth]: curr args are [", join(", ", @DB::args), "]") if $ldebug;
			$namesAndValues = [];
			for (my $j = 0; $j < @savedArgs; $j++) {
			    push (@$namesAndValues, [sprintf('$_[%d]', $j), $savedArgs[$j]]);
			}
		    }
		} elsif ($context_id == LocalVars) {
		    $stackDepth = 0;
		    $namesAndValues = eval { _getProximityVars($pkg, $filename, $line); };
		} else {
		    $stackDepth = 0;
		    $namesAndValues = eval { getContextProperties($context_id, $pkg); };
		}
		if ($@) {
		    my ($code, $error) = ($@ =~ /code:(.*):error<:<(.*?)>:>/);
		    if (!$code) {
			$code = DBP_E_ParseError;
			$error = _trimExceptionInfo($@);
		    }
		    makeErrorResponse($cmd,
				      $transactionID,
				      $code,
				      $error);
		    next CMD;
		}
		#dblog("unsorted vars:", DB::Data::Dump::dump($namesAndValues), "\n") if $ldebug;
		my @sortedNames;
		if ($context_id != FunctionArguments) {
		    @sortedNames = sort {
			# For some reason this doesn't work as an external fn
			# All the values come in undef'ed
			my ($a1, $a2) = split(//, $a->[0], 2);
			my ($b1, $b2) = split(//, $b->[0], 2);
			($a2 cmp $b2 || $a1 cmp $b1);
		    } @$namesAndValues;
		} else {
		    @sortedNames = @$namesAndValues;
		}
		# dblog("sorted vars:", DB::Data::Dump::dump(@sortedNames), "\n") if $ldebug;
		foreach my $entry (@sortedNames) {
		    if ($entry->[NV_NEED_MAIN_LEVEL_EVAL]
			|| !$entry->[NV_VALUE]) {
			eval {
			    $entry->[NV_VALUE] = eval_term($entry->[NV_NAME]);
			};
			if ($@) {
			    $entry->[NV_VALUE] = _trimExceptionInfo($@);
			    $entry->[NV_UNSET_FLAG] = 1;
			}
		    }
		}
		# If anything had to be re-evaluated, and didn't return
		# a value, remove it.
		@sortedNames = grep { !($_->[NV_NEED_MAIN_LEVEL_EVAL])
					  || defined $_->[NV_VALUE] } @sortedNames;
		if ($context_id == PunctuationVariables) {
		    # Filter out unset values, and add the pattern-matching ones.
		    @sortedNames = grep { ! defined $_->[NV_UNSET_FLAG] } @sortedNames;
		    # And add the pattern-match vars
		    $evalarg = '$#-';
		    my ($numPVs) = &eval();
		    for (my $pvnum = $numPVs; $pvnum > 0; $pvnum--) {
			eval {
			    my $pvname = "\$$pvnum";
			    $evalarg = $pvname;
			    my ($val) = &eval();
			    if (length $val) {
				unshift @sortedNames, [$pvname, $val, 1];
			    }
			};
		    }
		}
		eval { emitContextProperties($cmd, $transactionID, $context_id, \@sortedNames, $settings{max_data}[0]); };
	    } elsif ($cmd eq 'typemap_get') {
		emitTypeMapInfo($cmd, $transactionID);

	    } elsif ($cmd eq 'property_get') {
		# First get the args, and then sanity check.
		local %opts = ();
		{
		    local *ARGV = *cmdArgs;
		    shift @ARGV;
		    getopts('c:d:k:m:n:p:', \%opts);
		}
		local $context_id = $opts{c};
		local $stackDepth = $opts{d} || 0;
		local $propertyKey = $opts{k};
		local $maxDataSize = $opts{m} || $settings{max_data}[0];
		local $property_long_name = $opts{n};
		local $pageIndex = $opts{p} || 0;
		my $nameAndValue;
		$property_long_name = nonXmlChar_Decode($property_long_name);
		if ($context_id != FunctionArguments) {
		    $nameAndValue = eval {
			getPropertyInfo($property_long_name, $propertyKey);
		    };
		} else {
		    my @savedArgs;
		    my $actualStackDepth = $stackDepth + 1;
		    while (1) {
			@unused = caller($actualStackDepth);
			if (!@unused) {
			    last;
			} elsif ($unused[3] eq '(eval)' && !$unused[4]) {
			    $actualStackDepth++;
				# dblog("property_get: moving up to level $actualStackDepth");
			} else {
				# dblog("property_get: settle on caller => [@unused]");
				# dblog("stack depth [$actualStackDepth]: curr args are [", join(", ", @DB::args), "]") if $ldebug;
			    @savedArgs = @DB::args;
			    last;
			}
		    }
		    my $finalValue;
		    ($property_long_name, $finalValue, $code, $error) =
			evalArgument($property_long_name, $propertyKey,
				     \@savedArgs);
		    if ($code) {
			makeErrorResponse($cmd,
					  $transactionID,
					  $code,
					  $error);
			next CMD;
		    }
		    $nameAndValue = [$property_long_name, $finalValue, 0];
		    $propertyKey = '';

		}
		if ($@) {
		    dblog("Got error [$@]\n") if $ldebug;
		    # Fix $@;
		    my ($code, $error) = ($@ =~ /code:(.*):error<:<(.*?)>:>/);
		    if (!$code) {
			$code = DBP_E_CantGetProperty;
			$error = _trimExceptionInfo($@);
		    }
		    makeErrorResponse($cmd,
				      $transactionID,
				      $code,
				      $error);
		    next CMD;
		} elsif ($nameAndValue) {
		    if ($nameAndValue->[NV_NEED_MAIN_LEVEL_EVAL]) {
			eval {
			    my $valRef;
			    $evalarg = $nameAndValue->[NV_NAME];
			    my $firstChar = substr($evalarg, 0, 1);
				# Avoid pattern-matching
			    if ($firstChar eq '@') {
				my @tmp = &eval();
				$valRef = \@tmp;
			    } elsif ($firstChar eq '%') {
				my %tmp = &eval();
				$valRef = \%tmp;
			    } else {
				# eval always fires in array context
				my @tmp = &eval();
				$valRef = _guessScalarOrArray(\@tmp);
			    }
			    $nameAndValue->[NV_VALUE] = $valRef;
			};
			if ($@) {
			    $nameAndValue->[NV_VALUE] = _trimExceptionInfo($@);
			}
		    }
		    eval {
			emitEvaluatedPropertyGetInfo($cmd,
						     $transactionID,
						     $nameAndValue,
						     $property_long_name,
						     $propertyKey,
						     $maxDataSize,
						     $pageIndex);
		    };
		    if ($@) {
			dblog("Error in emitEvaluatedPropertyGetInfo: [$@]");
			makeErrorResponse($cmd,
					  $transactionID,
					  $code,
					  $error);
		    }
		} else {
		    # We already emitted an error message, and returned undef
		}

	    } elsif ($cmd eq 'property_set') {
		# First get the args, and then sanity check.
		local %opts = ();
		{
		    local *ARGV = *cmdArgs;
		    shift @ARGV;
		    getopts('a:c:d:l:n:t:', \%opts);
		}
		my $context_id = $opts{c};
		my $stackDepth = $opts{d} || 0;
		my $advertisedDataLength = $opts{l} || 0;
		my $property_long_name = $opts{n};
		$property_long_name = nonXmlChar_Decode($property_long_name);
		my $valueType = $opts{t};

		if ($context_id == FunctionArguments) {
		    makeErrorResponse($cmd,
				      $transactionID,
				      DBP_E_CantSetProperty,
				      "This debugger currently doesn't modify function arguments");
		    next CMD;
		}

		my ($actualDataLength, $currDataEncoding, $decodedData);
		if (scalar @cmdArgs) {
		    ($actualDataLength, $currDataEncoding, $decodedData) =
			decodeCmdLineData($advertisedDataLength, \@cmdArgs);
		}
		if (!defined $decodedData) {
		    dblog("property_set: \$decodedData not defined\n") if $ldebug;
		    makeErrorResponse($cmd,
				      $transactionID,
				      DBP_E_CantSetProperty,
				      "Can't decode the data");
		    next CMD;
		}
		if ($valueType
		    && $valueType eq 'string'
		    && substr($decodedData, 0, 1) !~ /[\"\']/) {
		    $decodedData =~ s,\\,\\\\,g;
		    $decodedData =~ s,',\\',g;
		    $decodedData = "\'$decodedData\'";
		}
		my $nameAndValue = doPropertySetInfo($cmd,
						     $transactionID,
						     $property_long_name);
		if (!$nameAndValue) {
		    # Already gave an error message
		    next CMD;
		}

		if ($nameAndValue->[NV_NEED_MAIN_LEVEL_EVAL]) {
		    if ($context_id == FunctionArguments && $stackDepth > 0) {
			makeErrorResponse($cmd,
					  $transactionID,
					  DBP_E_CantSetProperty,
					  "Can't modify function arguments inside current frame");
			next CMD;
		    }
		    $evalarg = $nameAndValue->[NV_NAME] . '=' . $decodedData;
		    eval {
			&eval();
		    };
		    if ($@) {
			# dblog("Have to deal with error [$@]\n") if $ldebug;
			# Fix $@;
			my ($code, $error) = ($@ =~ /code:(.*):error<:<(.*?)>:>/);
			if (!$code) {
			    $code = DBP_E_CantGetProperty;
			    $error = _trimExceptionInfo($@);
			}
			makeErrorResponse($cmd,
					  $transactionID,
					  207, #XXX: Invalid expression
					  $error);
		    } else {
			local $res = sprintf(qq(%s\n<response %s command="%s" 
						transaction_id="%s" success="1" />),
					     xmlHeader(),
					     namespaceAttr(),
					     $cmd,
					     $transactionID);
			{
			    printWithLength($res);
			}
		    }
		}

	    } elsif ($cmd eq 'property_value') {
		# First get the args, and then sanity check.
		local %opts = ();
		{
		    local *ARGV = *cmdArgs;
		    shift @ARGV;
		    getopts('c:d:k:n:', \%opts);
		}
		local $context_id = $opts{c};
		local $stackDepth = $opts{d} || 0;
		local $propertyKey = $opts{k}; # Used only for arguments?
		local $property_long_name = $opts{n};
		$property_long_name = nonXmlChar_Decode($property_long_name);
		my $currStackSize = scalar dump_trace(0);
		my $nameAndValue;
		if ($context_id != FunctionArguments) {
		    $nameAndValue = eval {
			getPropertyValue($cmd,
					 $context_id,
					 $stackDepth,
					 $currStackSize,
					 $pkg,
					 $property_long_name,
					 2);
		    };
		} else {
		    my $key;
		    if ($property_long_name =~ /^\$_\[(.*)\]$/) {
			$key = $1;
		    } elsif ($propertyKey =~ /^\[?(.*)\]?$/) {
			#XXX: Need to nonXMlChar_Decode($propertyKey)?
			$key = $1;
		    } else {
			$key = 0;
		    }
		    @stuff = caller($stackDepth + 1);
		    @stuff2 = @DB::args;
		    $nameAndValue = [sprintf('$_[%d]', $key),
				     $DB::args[$key], 0];
		}
		if ($@) {
		    my ($code, $error) = ($@ =~ /code:(.*):error<:<(.*?)>:>/);
		    if (!$code) {
			$code = DBP_E_CantGetProperty;
			$error = _trimExceptionInfo($@);
		    }
		    makeErrorResponse($cmd,
				      $transactionID,
				      $code,
				      $error);
		    next CMD;
		} elsif ($nameAndValue) {
		    my @valList;
		    if ($nameAndValue->[NV_NEED_MAIN_LEVEL_EVAL]) {
			eval {
			    $evalarg = $nameAndValue->[NV_NAME];
			    @valList = &eval();
			};
			if ($@) {
			    makeErrorResponse($cmd,
					      $transactionID,
					      DBP_E_CantGetProperty,
					      $@);
			    next CMD;
			}
		    } else {
			(@valList) = $nameAndValue->[NV_VALUE];
		    }
		    eval {
			# Think about truncating valList here
			local $maxDataSize = $opts{m} || $settings{max_data}[0];
			if ($maxDataSize > 0) {
			    dblog("property_value: emitFinalPropertyValue(... \$maxDataSize=$maxDataSize");
			    my $amt_read = 0;
			    my $i;
			    for ($i = 0; $i < $#valList; $i++) {
				if (($amt_read += length $valList[$i]) > $maxDataSize) {
				    splice(@valList, $i + 1);
				    $valList[$i + 1] = '...';
				    last;
				}
			    }
			} else {
			    dblog("property_value: emitFinalPropertyValue(... \$maxDataSize=$maxDataSize");
			}
			emitFinalPropertyValue($cmd,
					       $transactionID,
					       $property_long_name,
					       \@valList,
					       $maxDataSize);
		    };
		} else {
		    # We already emitted either the value or an error message.
		}
	    } elsif ($cmd eq 'source') {
		my %opts;
		{
		    local *ARGV = *cmdArgs;
		    dblog("source: args={@ARGV}");

		    shift @ARGV;
		    getopts('b:e:f:', \%opts);
		}
		# Line 0 contains the 'require perl5db.pl thing'?
		my $beginLine = $opts{b} || 1;
		$beginLine < 1 and $beginLine = 1;
		my $endLine;
		my $sourceString;
		my $error;
		if (!defined $opts{f}) {
		    dblog("source: -f not defined");
		    my $lines;
		    if ($perlFileName) {
			if (defined &INC &&
			    $perlFileName =~ m,^/(Perl\w{3}/|<.*?>)(.*),) {
			    my $pdkUtilityName = $1;
			    my @lines = split(/\n/, INC($2));
			    $lines = \@lines;
			    dblog("Debugging a $pdkUtilityName module, grab source and get [" . join("\n", @lines[0..2]) . "]");
			} else {
			    local *dbline = $main::{"_<$filename"};
			    $lines = \@dbline;
			}
		    } else {
			dblog("source -- yipes -- no -f url and no local filename");
			$lines = [];
		    }
		    $endLine = $opts{e} || $#lines;
		    $endLine < $beginLine and $endLine = $beginLine;
		    
		    dblog("** source -- file $filename, perl name not given");
		    ($sourceString, $error) =
			_source_handle_missing_podlines_1(undef,
							  $beginLine,
							  $endLine,
							  $lines);
		} elsif (defined &INC && $opts{f} =~ m@^dbgp:///perl//(PerlApp/|<.*?>)(.*)@) {
		    # Definitely three slashes between 'perl' and 'PerlApp'
		    my $pdkUtilityName = $1;
		    my @lines = split(/\n/, INC($2));
		    dblog("Line " . __LINE__ . ": Debugging a $pdkUtilityName module, grab source($1) and get [" . join("\n", @lines[0..2]) . "]");
		    ($sourceString, $error) =
			_source_handle_missing_podlines_1($1,
							  $beginLine,
							  $endLine,
							  \@lines);
		    # One slash or two in this next pattern?
		} elsif ($opts{f} =~ m@^dbgp:///?perl/(?:[-_\w\d]+/\d+/)?(.+)$@) {
		    dblog("source: it's a dbgp thing ($1)");
		    my $dynamicLocation = $1;
		    if ($dynamicLocation =~ /^(\d+)\/\(eval\s*\d+\)/) {
			my $dynLocnIdx = $1;
			if (defined $evalTableIdx[$dynLocnIdx]
			    && exists $evalTable{$evalTableIdx[$dynLocnIdx]}) {
			    dblog("source -- mapping \$dynamicLocation = $dynamicLocation to evalstring" . $evalTableIdx[$dynLocnIdx]) if $ldebug;
			    $dynamicLocation = $evalTableIdx[$dynLocnIdx];
			} else {
			    dblog("source -- can't resolve numeric \$dynamicLocation = $dynamicLocation") if $ldebug;
			    $error = "Can't find src for location $dynamicLocation";
			}
		    } elsif ($dynamicLocation =~ /^\d+$/) {
			if (defined $evalTableIdx[$dynamicLocation]
			    && exists $evalTable{$evalTableIdx[$dynamicLocation]}) {
				# dblog("source -- mapping \$dynamicLocation = $dynamicLocation to evalstring" . $evalTableIdx[$dynamicLocation]) if $ldebug;
			    $dynamicLocation = $evalTableIdx[$dynamicLocation];
			} else {
			    dblog("source -- can't resolve numeric \$dynamicLocation = $dynamicLocation") if $ldebug;
			    $error = "Can't find src for location $dynamicLocation";
			}
		    } else {
			dblog("source -- got old-style dbgp value \$dynamicLocation") if $ldebug;
			$dynamicLocation = decodeData($dynamicLocation, 'urlescape');
		    }
		    # dblog("source: locn = ", $dynamicLocation) if $ldebug;
		    if (!$error) {
			if (!exists $evalTable{$dynamicLocation}) {
			    local *dbline = $main::{"_<$dynamicLocation"};
			    if ($dbline eq $dynamicLocation) {
				if ($dynamicLocation =~ /\(eval (\d+)\)\[(.*):(\d+)\]$/) {
				    my ($innerEvalIdx, $parentLocation, $startingPoint) = ($1, $2, $3);
				    my $etCount = scalar @evalTableIdx;
				    $evalTable{$dynamicLocation} = {
					file => $parentLocation,
					startLine => $startingPoint,
					src => \@dbline,
					idx => $etCount,
				    };
				    $evalTableIdx[$etCount] = \$evalTable{$filename};
				} else {
				    dblog "get source error: Can't parse [$dynamicLocation]\n" if $ldebug;
				}
			    } else {
				dblog "get source error: Can't find a glob from [$dynamicLocation]\n" if $ldebug;
			    }
			}
			if (exists $evalTable{$dynamicLocation}) {
			    my @src = @{$evalTable{$dynamicLocation}{src}};
			    $endLine = $opts{e} || $#src;
			    $endLine < $beginLine and $endLine = $beginLine;
			    eval {
				$sourceString = join("",
						     @src[$beginLine .. $endLine]
						     );
			    };
			} else {
			    $error = "Can't find src for URI " . $opts{f};
			}
		    }
		} else {
		    my ($bFileURI,
			$bFileURINo,
			$bFileName,
			$perlFileName);
		    getFileInfo(\%opts, 'f', $filename,
				\$bFileURI,
				\$bFileURINo,
				\$bFileName,
				\$perlFileName);
		    dblog("** source -- file $filename, perl name $perlFileName");
		    ($sourceString, $error) =
			_source_handle_missing_podlines_1($perlFileName,
							  $beginLine,
							  $endLine,
							  \@dbline);
		}
		if ($error || !$sourceString) {
		    if (!$error) {
			dblog("Failed to set an error, but got no string");
			$error = "source cmd -- unknown error";
		    } else {
			dblog("source: $error\n") if $ldebug;
		    }
		    makeErrorResponse($cmd,
				      $transactionID,
				      DBP_E_CantOpenSource,
				      $error);
		    next CMD;
		};
		($encoding, $encVal) = figureEncoding($sourceString);
		my $res = sprintf(qq(%s\n<response %s command="%s" 
				     transaction_id="%s"
				     success="1"
				     encoding="%s"
				     >%s</response>\n),
				  xmlHeader(),
				  namespaceAttr(),
				  $cmd,
				  $transactionID,
				  $encoding,
				  $encVal);
		printWithLength($res);

	    } elsif ($cmd eq 'stdout' || $cmd eq 'stderr') {
		local %opts = ();
		{
		    local *ARGV = *cmdArgs;
		    shift @ARGV;
		    getopts('c:', \%opts);
		}
		my $copyType = $opts{c} || 0;
		eval {
		    my $redirectType;
		    if ($copyType < DBGP_Redirect_Disable
			|| $copyType > DBGP_Redirect_Redirect) {
			makeErrorResponse($cmd,
					  $transactionID,
					  DBP_E_InvalidOption,
					  "Invalid -c value of $copyType");
			next CMD;
		    }
		    if ($cmd eq 'stdout') {
			if (exists $tiedFileHandles{'stdout'}) {
				# Update the copy-type
			    untie(*STDOUT);
			}
			if (!open ActualSTDOUT, ">&STDOUT") {
			    makeErrorResponse($cmd,
					      $transactionID,
					      DBP_E_InvalidOption,
					      "Invalid -c value of $copyType");
			    next CMD;
			}
			tie(*STDOUT, 'DB::RedirectStdOutput', *ActualSTDOUT, $OUT, $cmd, $copyType);
			$tiedFileHandles{'stdout'} = 1;
		    } elsif ($cmd eq 'stderr' && !$ldebug) {
			if (exists $tiedFileHandles{'stderr'}) {
				# Update the copy-type
			    untie(*STDERR);
			}
			if (!open ActualSTDERR, ">&STDERR") {
			    makeErrorResponse($cmd,
					      $transactionID,
					      DBP_E_InvalidOption,
					      "Invalid -c value of $copyType");
			    next CMD;
			}
			tie(*STDERR, 'DB::RedirectStdOutput', *ActualSTDERR, $OUT, $cmd, $copyType);
			$tiedFileHandles{'stderr'} = 1;
		    }
		    local $res = sprintf(qq(%s\n<response %s command="%s" 
					    transaction_id="%s" success="1" />),
					 xmlHeader(),
					 namespaceAttr(),
					 $cmd,
					 $transactionID);
		    {
			local $ldebug = $cmd ne 'stderr' && $ldebug;
			printWithLength($res);
		    }
		};
		if ($@) {
		    makeErrorResponse($cmd,
				      $transactionID,
				      DBP_E_InvalidOption,
				      "Invalid -c value of $copyType");
		}
	    } elsif ($cmd eq 'stdin') {
=head unsupported
		    local %opts = ();
		{
		    local *ARGV = *cmdArgs;
		    shift @ARGV;
		    getopts('c:l:', \%opts);
		}
		if ($opts{c} == 1) {
		} else {
		    dblog("stdin: opts{c} = $opts{c}\n") if $ldebug;
		    next CMD;
		}
		my $dataLength = $opts{l}; # ignore
		my $encodedData = join("", @cmdArgs);
		my $actualData = decodeData($encodedData, 'base64');
		dblog "stdin: [$actualData]\n" if $ldebug;
=cut
		makeErrorResponse($cmd,
				  $transactionID,
				  DBP_E_CommandUnimplemented,
				  "stdin not supported via protocol");
	    } elsif ($cmd eq 'eval') {
		local %opts = ();
		{
		    local *ARGV = *cmdArgs;
		    shift @ARGV;
		    getopts('l:', \%opts);
		}
		my $dataLength = $opts{l};
		my ($actualDataLength, $currDataEncoding, $decodedData);
		if (scalar @cmdArgs) {
		    ($actualDataLength, $currDataEncoding, $decodedData) =
			decodeCmdLineData($dataLength, \@cmdArgs);
		}
		if (!defined $decodedData) {
		    next CMD;
		}
		my $res = eval_term($decodedData);
		emitEvalResultAsProperty($cmd,
					 $transactionID,
					 $decodedData,
					 $res,
					 $maxDataSize);
	    } elsif ($cmd eq 'interact') {
		local %opts = ();
		{
		    local *ARGV = *cmdArgs;
		    shift @ARGV;
		    getopts('am:', \%opts);
		}
		my $abort = $opts{a};
		my $mode = $opts{m};
		my ($actualDataLength, $currDataEncoding, $decodedData);
		if (scalar @cmdArgs) {
		    ($actualDataLength, $currDataEncoding, $decodedData) =
			decodeCmdLineData($advertisedDataLength, \@cmdArgs);
		}
		$stopReason = STOP_REASON_INTERACT;
		if ($ibState == IB_STATE_NONE) {
		    $ibState = IB_STATE_START;
		}
		if (defined $mode) {
		    if ($mode == 0) {
			$ibState = IB_STATE_NONE;
			if ($startedAsInteractiveShell) {
			    $stopReason = STOP_REASON_STOPPED;
			} else {
			    $stopReason = STOP_REASON_BREAK;
			}
			printWithLength(sprintf
					(qq(%s\n<response %s command="%s"
					    transaction_id="%s"
					    status="%s"
					    reason="ok"
					    more="0"
					    prompt=""
					    />),
					 xmlHeader(),
					 namespaceAttr(),
					 $cmd,
					 $transactionID,
					 getStopReason(),
					 ));
			next CMD;
		    }
		}
		$stopReason = STOP_REASON_INTERACT;
		my $valRef;
		my $evalStdoutSideEffects = '';
		my $doContinue;
		my $moreValue;
		my $prompt;
		if (!$abort && defined $decodedData) {
		    # Decide what to do next
		    if ($ibState == IB_STATE_START) {
			$ibBuffer = $decodedData;
		    } else {
			# dblog("Have [$ibBuffer], appending [\\n$decodedData]");
			$ibBuffer .= "\n$decodedData";
			# Check for ending a here-doc
			if ($ibBuffer =~ /<<(\w+).+^\1$/sm) {
				# dblog("Found bareword here-doc ending for [$ibBuffer]");
			    $ibBuffer .= "\n";
			} elsif ($ibBuffer =~ /<<([\"\'])((?:\.|.)*?)\1.*^\2$/sm) {
				# dblog("Found quoted-target here-doc ending for [$ibBuffer]");
			    $ibBuffer .= "\n";
			} elsif ($ibBuffer =~ /<< .*\n$/s) {
				# dblog("Found empty-line here-doc ending for [$ibBuffer]");
			    $ibBuffer .= "\n";
			}
			# dblog("Have -- 1 ** [$ibBuffer]");
		    }
		    my $tmpVal;
		    my @tmpArray;
		    my $evalWarning;
		    my $mainError;
		    $ibBuffer =~ s/^\s+$//s; # Remove all white-space
		    if (length $ibBuffer) {
			# dblog("Have -- 2 ** [$ibBuffer]");
			if ($ibBuffer =~ /^(.*?(?<!\\.)(?:\\\\)*)\\$/s) {
				# Make sure the final \\ isn't an escaped
				# \\ at the end of a string.
			    $ibBuffer = $1;
			    dblog("found it, now: $ibBuffer");
			    $doContinue = 1;
			} else {
			    my $ah;
			    my $oh;
			    eval {
				require DB::IO::Scalar;
				$ah = DB::IO::Scalar->new(\$evalStdoutSideEffects);
				$oh = select $ah;
				$| = 1;
			    };
			    eval {
				local $SIG{__WARN__} = sub {
				    $evalWarning = $_[0];
				    dblog("warn handler fired: $evalWarning");
				# print STDERR "Invalid expression: @_\n";
				};
				# dblog("Have -- 3 ** [$ibBuffer]");
				my $fixedBuffer = _removeLocalizers($ibBuffer);
				# dblog("_removeLocalizers($ibBuffer) => [$fixedBuffer]");
				$evalarg = $fixedBuffer;
				local $interact = 1;
				my @tmp = &eval();
				if ($evalarg =~ /^[\@\%]/) {
				    $valRef = \@tmp;
				} else {
				    $valRef = _guessScalarOrArray(\@tmp);
				}
			    };
			    if ($@) {
				$mainError = $@;
				if ($mainError =~ /^syntax error/m) {
				    if ($mainError =~ /^Missing right curly or square bracket/m) {
					dblog("We'll continue: $@");
					dblog("  Using [$ibBuffer]");
					$doContinue = 1;
				    }
				} elsif ($mainError =~ /^Can.t find string terminator/m) {
				    dblog("We'll continue (2): $@");
				    dblog("  Using [$ibBuffer]");
				    $doContinue = 1;
				}
				if (!$doContinue) {
				    $mainError =~ s/at \(eval \d+\).*$//;
				}
				dblog("Error: $@");
				if ($evalWarning) { 
				    dblog("Extra error: $evalWarning");
				    if (!$doContinue) {
					$evalWarning =~ s/^\s+//;
					$mainError .= "\n$evalWarning";
				    }
				}
			    }
			    $ah->close() if $ah;
			    select $oh if $oh;
			}
		    }
		    if ($doContinue) {
			# dblog("State pending");
			$ibState = IB_STATE_PENDING;
			$moreValue = 1;
			$prompt = '>';
		    } else {
			# dblog("=> State start");
			$ibState = IB_STATE_START;
			$moreValue = 0;
			$prompt = '%';
			if ($mainError) {
			    $mainError =~ s/\n+$/\n/;
			    print STDERR $mainError;
			} elsif (length $evalStdoutSideEffects) {
				# Do nothing more
			    _preprocess_results($ibBuffer, $evalStdoutSideEffects);
			} else {
			    if (ref $valRef) {
				if (!_isPrintable($ibBuffer, $valRef)) {
				    # Don't print anything.
				} elsif ($ibBuffer !~ /^\s*use\b/) {
				    _preprocess_results($ibBuffer, DB::Data::Dump::dump($valRef));
				}
			    } elsif ($valRef && length("$valRef")) {
				if ($ibBuffer !~ /^\s*printf?\b/) {
				    _preprocess_results($ibBuffer, $valRef);
				} elsif ($ldebug) {
				    dblog("squelching [$ibBuffer] => [$valRef]");
				}
			    } else {
				# Do this in case the thing being
				# eval'ed wrote to stderr but for some
				# reason hasn't flushed (I'm talking about
				# you, Devel::Peek).
				print STDERR "";
			    }
			}
		    }
		} else {
		    dblog("interact: \$decodedData not defined\n") if $ldebug;
		    if (!$mode || $ibState == IB_STATE_START) {
			# dblog("State start");
			$moreValue = 0;
			$prompt = '%';
		    } else {
			# dblog("State pending");
			$moreValue = 1;
			$prompt = '>';
		    }
		}
		printWithLength(sprintf
				(qq(%s\n<response %s command="%s" 
				    transaction_id="%s"
				    status="%s"
				    more="%d"
				    prompt="%s"
				    />),
				 xmlHeader(),
				 namespaceAttr(),
				 $cmd,
				 $transactionID,
				 getStopReason(),
				 $moreValue,
				 $prompt,
				 ));
	    } else {
		# Fallback
		printWithLength(sprintf
				(qq(%s\n<response %s command="%s" 
				    transaction_id="%s" ><error code="6" apperr="4">
				    <message>%s command not recognized</message>
				    </error></response>),
				 xmlHeader(),
				 namespaceAttr(),
				 $cmd,
				 $transactionID));

	    }
	}
    } elsif ($pkg =~ /^DB::/) {
	dblog("Skipping package [$pkg]\n") if $ldebug;
    } elsif ($inPostponed) {
	dblog("Still postponed: [$pkg/$filename/$line]\n") if $ldebug;
    }
	
    # Put the user's globals back where you found them.
    ($@, $!, $,, $/, $\, $^W) = @saved;
    db_alarm($_pending_check_interval);
    $_pending_check_enabled = 1 unless $skip_alarm;
    return ();
}

sub _preprocess_results {
    my ($ibBuffer, $val) = @_;

    $val =~ s/(?<!\n)$/\n/;
    $val =~ s/\x00/^@/g;
    my @a;
    if ($ibBuffer =~ /^\s*[\$\@\%][a-zA-Z0-9_:]+\s*=/
	&& scalar (@a = split(/\n/, $val, 10)) > 8) {
	pop @a;
	pop @a;
	print STDOUT join("\n", @a, "...\n");
    } else {
	print STDOUT nonXmlChar_Encode($val);
    }
}

# Avoid re-entrancy problems by putting newly entered files in a
# queue and processing them when it's appropriate.

sub postponed {
    local *dbline_arg = shift;
    push @postponedFiles, *dbline_arg;
    if ($inPostponed || !$ready) {
	return;
    }
    finish_postponed();
    return 1;
}

sub finish_postponed {
    local $inPostponed = 1;
    while (@postponedFiles) {
	local *dbline = shift @postponedFiles;
	my $filename = $dbline;
	$filename =~ s/^<_//;

	# Get the Perl filename, canonical filename, and URI, and see
	# if it was set as postponed
	my $perlFileName = $filename;
	my ($bFileURI, $bFileURINo, $bFileName);

	if (exists $perlNameToFileURINo{$perlFileName}) {
	    # Why are we here -- we already know about this filename.
	    $bFileURINo = $perlNameToFileURINo{$perlFileName};
	    ($bFileURI, $bFileName, undef) = @{$fileNameTable[$bFileURINo]};
	} else {
	    $bFileURI = canonicalizeURI(filenameToURI($filename, 1));
	    $bFileURINo = internFileURI($bFileURI);
	    local $@;
	    eval {
		$bFileName = canonicalizeFName(uriToFilename($bFileURI));
	    };
	    if ($@) {
		dblog("Called uriToFilename in " .
		      join("\n", dump_trace(0)));
		return;
	    }
	    $perlNameToFileURINo{canonicalizeFName($perlFileName)} = $bFileURINo;
	    $fileNameTable[$bFileURINo] = [$bFileURI,
					   $bFileName,
					   $perlFileName];
	}
	if (exists $postponed_fileuri{$bFileURINo}) {
	    delete $postponed_fileuri{$bFileURINo};
	}

	if (defined $bkptLookupTable[$bFileURINo]) {
	    # Set the breakpoints in %dbline now...
	    foreach my $k (keys %{$bkptLookupTable[$bFileURINo]}) {
		$dbline{$k} = 1;
	    }
	}
    }
}

# This routine needs to localize these globals, as function
# breakpoints are not conditional.  We only need to localize
# $@ because the eval() destroys it.

sub tryBreaking($$) {
    return if ($signal || $single); # we're about to break anyway.
    my ($fqsubname, $callDirection) = @_;
    local $@;
    eval {
	my $bkptEntry = exists $FQFnNameLookupTable{$fqsubname} && $FQFnNameLookupTable{$fqsubname};
	if ($bkptEntry && exists $bkptEntry->{$callDirection}) {
	    my $breakHere = 0;
	    my $bkptInfoRef = getBkPtInfo($bkptEntry->{$callDirection});
	    processPossibleBreakpoint($bkptInfoRef, "sub $fqsubname");
	}
	if (!$single && _checkForBreak()) {
	    $single = 1;
	}
    };
    if ($@) {
	dblog "Error while trying to eval breakpoint($fqsubname, $callDirection): $@" if $ldebug;
    }
}


sub sub
{
    my ($i, @i); ## dcb -- Bug Fix from John Mongan (john@rescomp.stanford.edu ) 3/20/98
    local $stack_depth = $stack_depth + 1;    # Protect from non-local exits
    $#stack = $stack_depth;
    $stack[-1] = $single;
    $single &= 1;
    $single |= 4 if $#stack == $deep;
    my ($pkg, $filename, $line) = caller;
    my $inDB = ($pkg && index($pkg, "DB::") == 0);
    tryBreaking($sub, 'call') unless $inDB;
	    
    if (wantarray)
    {
	@i = &$sub;
        $single |= $stack[$stack_depth--];
	tryBreaking($sub, 'return') unless $inDB;
	@i;
    }
    else
    {
        if (defined wantarray) {
	    $i = &$sub;
        } else {
            &$sub; undef $i;
        };
        $single |= $stack[$stack_depth--];
	tryBreaking($sub, 'return') unless $inDB;
	$i;
    }
}

# exception handling?
$SIG{'INT'} = "DB::catch";

sub catch
{
    $signal = 1;
}
#
# save
#
# Save registers.
#
sub save
{
    @saved = ($@, $!, $,, $/, $\, $^W);
    $, = ""; $/ = "\n"; $\ = ""; $^W = 0;
}

sub chr_expand {
    my $s = shift;
    return "" unless defined $s;
    $s =~ s/([\x00-\x08\x0a-\x1f\x7e-\xff])/sprintf('\\x%02x', ord($1))/eg;
    $s;
}

# Slight modification so this routine buffers,
# returning strings separated by nulls or newlines

sub readline {
    local $.;
    local $frame = 0;
    local $doret = -2;
    # Nothing on the filehandle stack. Socket?
    if (ref $OUT and UNIVERSAL::isa($OUT, 'IO::Socket::INET')) {
        # Send anything we have to send.
	if (@_) {
	    $OUT->write(join ('', @_));
	}

        # Receive anything there is to receive.
        my $finalBuffer = '';
	if (@_pending_commands) {
	    return shift @_pending_commands;
	}
	my $amtToRead = 2048;
	while (1) {
	    my $thisBuffer;
	    $IN->recv($thisBuffer, $amtToRead);  # XXX "what's wrong with sysread?"
						 # XXX Don't know. You tell me.
	    # Check the size before removing nulls
	    my $leave = (length($thisBuffer) < $amtToRead);
	    # dblog("Read in [", chr_expand($thisBuffer), "], adding to [", chr_expand($finalBuffer), "]");
	    # And allow for embedded newlines
	    $thisBuffer =~ s/\r?\n//g;
	    $finalBuffer .= $thisBuffer;
	    last if $leave && (length($finalBuffer) == 0
			       || $finalBuffer =~ /\0$/);
	}
	# Remove trailing null on last command
	$finalBuffer =~ s/\0$//;
	
	# And if we read multiple commands in one go, hold on to them.
	($finalBuffer, @_pending_commands) = split(/[\x00\n]/, $finalBuffer);
	if ($ldebug && @_pending_commands) {
	    dblog("Multiple cmds read in: <$finalBuffer>, <",
		  join(">, <", @_pending_commands), ">");
	}
        return $finalBuffer;
    } ## end if (ref $OUT and UNIVERSAL::isa...)
} ## end sub readline

sub _break_check_handler {
    if (!$single) {
	# We timed out, so move the pending-check counter up
	$_pending_check_count = $_pending_check_lim;
	if (_checkForBreak()) {
	    $single = 1;
	    db_alarm(0);
	}
    }
    if (!$single) {
	db_alarm($_pending_check_interval);
    }
}

sub _checkForBreak {
    return if $skip_alarm;
    return unless $_pending_check_enabled && $OUT_selector;
    return if ++$_pending_check_count < $_pending_check_lim;
    $_pending_check_count = 0;
    # dblog("_checkForBreak: About to select...($_pending_check_timeout)");
    my $have_something = $OUT_selector->can_read($_pending_check_timeout);
    # dblog("... Done");
    return unless $have_something;
    my $cmd = &readline();
    # dblog("_checkForBreak: Got command [$cmd]\n");
    if ($cmd =~ /\Abreak\b/) {
	unshift(@_pending_commands, $cmd);
	$_pending_check_enabled = 0;
	return 1;
    } else {
	# Put the command back at the front, so we process it in due time.
	my $directive = $cmd;
	if (!@_pending_commands
	    || ($cmd =~ /^(\w+)\b/ && $supportedCommands{$1})) {
	    unshift(@_pending_commands, $cmd);
	} else {
	    dblog("_checkForBreak: Appending [$cmd] onto $_pending_commands[0]\n");
	    $_pending_commands[0] .= $cmd;
	}
    }
    return 0;
}

sub dump_trace {

    # How many levels to skip.
    my $skip = shift;

    # How many levels to show. (1e9 is a cheap way of saying "all of them";
    # it's unlikely that we'll have more than a billion stack frames. If you
    # do, you've got an awfully big machine...)
    my $count = shift || 1e9;

    # We increment skip because caller(1) is the first level *back* from
    # the current one.  Add $skip to the count of frames so we have a 
    # simple stop criterion, counting from $skip to $count+$skip.
    $skip++;
    $count += $skip;

    # These variables are used to capture output from caller();
    my ($p, $file, $line, $sub, $h, $context);

    my ($e, $r, @a, @sub, $args);

    # XXX Okay... why'd we do that?
    my $nothard = not $frame & 8;
    local $frame = 0;

    # Do not want to trace this.
    my $otrace = $trace;
    $trace = 0;

    # Start out at the skip count.
    # If we haven't reached the number of frames requested, and caller() is
    # still returning something, stay in the loop. (If we pass the requested
    # number of stack frames, or we run out - caller() returns nothing - we
    # quit.
    # Up the stack frame index to go back one more level each time.
    for (
        $i = $skip ;
        $i < $count
        and ($p, $file, $line, $sub, $hasArgs, $context, $e, $r) = caller($i) ;
        $i++
      )
    {
        if ($p eq 'DB') {
	    # Don't count debugger entries
	    next;
	}
        # Go through the arguments and save them for later.
        @a = ();
        # Grab the args and hold on to them, since they seem to change
	# as we run through this code -- this fixes bug 32384.
	if ($hasArgs) {
	    my @fixArgs;
	    eval {@fixArgs = @DB::args;};
	    if ($@) {
		dblog("Failed to get function args at stack level $i: $@");
		@fixArgs = ();
	    }
	    for $arg (@fixArgs) {
		my $type;
		if (not defined $arg) {	# undefined parameter
		    push @a, "undef";
		}

		elsif ($nothard and tied $arg) { # tied parameter
		    push @a, "tied";
		}
		elsif ($nothard and $type = ref $arg) {	# reference
		    push @a, "ref($type)";
		}
		else {		# can be stringified
		    local $_ =
			"$arg";	# Safe to stringify now - should not call f().

		    # Backslash any single-quotes or backslashes.
		    s/([\'\\])/\\$1/g;

		    # Single-quote it unless it's a number or a colon-separated
		    # name.
		    s/(.*)/'$1'/s
			unless /^(?: -?[\d.]+ | \*[\w:]* )$/x;

		    # Turn high-bit characters into meta-whatever.
		    s/([\200-\377])/sprintf("M-%c",ord($1)&0177)/eg;

		    # Turn control characters into ^-whatever.
		    s/([\0-\37\177])/sprintf("^%c",ord($1)^64)/eg;

		    push (@a, $_);
		}		## end else [ if (not defined $arg)
	    }			## end for $arg (@args)
	    $args = [@a];
	} else {
	    $args = undef;
	}

        # If context is true, this is array (@)context.
        # If context is false, this is scalar ($) context.
        # If neither, context isn't defined. (This is apparently a 'can't 
        # happen' trap.)
        $context = $context ? '@' : (defined $context ? "\$" : '.');

        # remove trailing newline-whitespace-semicolon-end of line sequence
        # from the eval text, if any.
        $e =~ s/\n\s*\;\s*\Z//  if $e;

        # Escape backslashed single-quotes again if necessary.
        $e =~ s/([\\\'])/\\$1/g if $e;

        # if the require flag is true, the eval text is from a require.
        if ($r) {
            $sub = "require '$e'";
        }
        # if it's false, the eval text is really from an eval.
        elsif (defined $r) {
            $sub = "eval '$e'";
        }

        # If the sub is '(eval)', this is a block eval, meaning we don't
        # know what the eval'ed text actually was.
        elsif ($sub eq '(eval)') {
            $sub = "eval {...}";
        }
	if ($sub =~ /^DB::/) {
	    next;
	}

        # Stick the collected information into @sub as an anonymous hash.
        push (
            @sub,
            {
                context => $context,
                sub     => $sub,
                args    => $args,
                file    => $file,
                line    => $line
            }
            );

        # Stop processing frames if the user hit control-C.
        last if $signal;
    } ## end for ($i = $skip ; $i < ...

    # Restore the trace value again.
    $trace = $otrace;
    @sub;
} ## end sub dump_trace

=head2 C<parse_options>

Trimmed down version for processing only RemotePort=\d+

=cut

sub parse_options {
    local ($_) = @_;
    local $\ = '';

    # These options need a value. Don't allow them to be clobbered by accident.
    my %opt_needs_val = map { ($_ => 1) } qw{
      dumpDepth arrayDepth hashDepth LineInfo maxTraceLen ornaments windowSize
      pager quote ReadLine recallCommand RemotePort ShellBang TTY CommandSet
					     LogFile
      };

    while (length) {
        my $val_defaulted;

        # Clean off excess leading whitespace.
        s/^\s+//;
	
        s/^(\w+)(\W?)// or last;
        my ($opt, $sep) = ($1, $2);
        my $val;

	print OUT "Info: Opt = [$opt], sep=[$sep]\n" if $ldebug;

        # '?' as separator means query, but must have whitespace after it.
        if ("?" eq $sep) {
            print(OUT "Option query `$opt?' followed by non-space `$_'\n"),
              last
              if /^\S/;
        } ## end if ("?" eq $sep)

        # Separator is whitespace (or just a carriage return).
        # They're going for a default, which we assume is 1.
        elsif ($sep !~ /\S/) {
            $val_defaulted = 1;
            $val           = "1"; #  this is an evil default; make 'em set it!
        }

        # Separator is =. Trying to set a value.
        elsif ($sep eq "=") {
            # If quoted, extract a quoted string.
            if (s/ ([\"\']) ( (?: \\. | (?! \1 ) [^\\] )* ) \1 //x) {
                my $quote = $1;
                ($val = $2) =~ s/\\([$quote\\])/$1/g;
            }

            # Not quoted. Use the whole thing. Warn about 'option='.
            else {
                s/^(\S*)//;
                $val = $1;
                print OUT qq(Option better cleared using $opt=""\n)
                  unless length $val;
		print OUT "Info: Val = [$val]\n" if $ldebug;
            } ## end else [ if (s/ (["']) ( (?: \\. | (?! \1 ) [^\\] )* ) \1 //x)

        } ## end elsif ($sep eq "=")

        # "Quoted" with [], <>, or {}.  
        else {    #{ to "let some poor schmuck bounce on the % key in B<vi>."
            my ($end) = "\\" . substr(")]>}$sep", index("([<{", $sep), 1);  #}
            s/^(([^\\$end]|\\[\\$end])*)$end($|\s+)//
              or print(OUT "Unclosed option value `$opt$sep$_'\n"), last;
            ($val = $1) =~ s/\\([\\$end])/$1/g;
        } ## end else [ if ("?" eq $sep)

        # Impedance-match the code above to the code below.
        my $option = $opt;

        # Save the option value.
        next unless length($val);
	if (lc $option eq 'remoteport' && $val =~ /.*:\d+$/) {
	    $remoteport = $val;
	} elsif ($option eq 'LogFile' && length($val)) {
	    my $logThing;
	    if (lc $val eq 'stdout') {
	        $logThing = \*STDOUT;
	    } elsif (lc $val eq 'stderr') {
	        $logThing = \*STDERR;
	    } else {
	        $logThing = $val;
	    }
	    if ($logThing) {
	        eval {
		    DB::DbgrCommon::enableLogger($logThing);
		    $ldebug = 1;
		    $DB::DbgrProperties::ldebug = 1;
		};
		if ($@) {
		    # Disable this.
		    print STDERR "Info: enableLogger => $@\n";
		}
	    }
	} elsif (lc $option eq 'alarm' || lc $option eq 'async') {
	    # Both options mean the same
	    if ($] >= 5.008) {
		$val = eval($val) if $val =~ /^\d+$/;
		$skip_alarm = 0 if $val;
	    } elsif ($val) {
		print STDERR "Info: PERLDB_OPTS option $option not supported for Perl version $].\n" . "Minimum supporting version is Perl 5.8.0\n";
	    }
        } elsif ($option eq 'RecursionCheckDepth' && $val =~ /^\d+$/) {
	    $deep = $val;
	}
    } ## end while (length)
} ## end sub parse_options

END {
    # Do not stop in at_exit() and destructors on exit:
    $DB::finished = 1;
    if ($DB::fall_off_end) {
	dblog("END block: single <= 0\n") if $ldebug;
	$DB::single = 0;
    } else {
	dblog("END block: single <= 1\n") if $ldebug;
	$DB::single = 1;
	if ($OUT) {
	    # Send a status of stopping

	    # Invariant:
	    # $lastContinuationCommand and $lastTranID must be set

	    printWithLength(sprintf(qq(%s\n<response %s command="%s" status="%s"
				       reason="ok" transaction_id="%s"/>),
				    xmlHeader(),
				    namespaceAttr(),
				    $lastContinuationCommand || 'run',
				    $lastContinuationStatus = 'stopping',
				    $lastTranID || '0'));
	}
        DB::fake::at_exit();
    }
} ## end END

sub end_report {
    my ($cmd, $transactionID) = @_;
    printWithLength(sprintf
		    (qq(%s\n<response %s command="%s" 
			transaction_id="%s" ><error code="6" apperr="4">
			<message>Command '%s' not valid at end of run.</message>
			</error></response>),
		     xmlHeader(),
		     namespaceAttr(),
		     $cmd,
		     $transactionID,
		     $cmd,
		     ));
}

=head1 C<DB::fake>

Contains the C<at_exit> routine that the debugger uses to issue the
C<Debugged program terminated ...> message after the program completes. See
the C<END> block documentation for more details.

=cut

package DB::fake;

sub at_exit {
    $DB::single = 1;
    "Debugged program terminated.";
}

package DB;    # Do not trace this 1; below!

1;
