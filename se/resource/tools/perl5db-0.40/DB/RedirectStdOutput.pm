# RedirectStdOutput.pm
# 
# Module for redirecting standard output/error.
#
# Copyright (c) 2003-2006 ActiveState Software Inc.
# All rights reserved.
# 
# This software (the Perl-DBGP package) is covered by the Artistic License
# (http://www.opensource.org/licenses/artistic-license.php).

package DB::RedirectStdOutput;

$VERSION = 0.10;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
	     DBGP_Redirect_Disable
	     DBGP_Redirect_Copy
	     DBGP_Redirect_Redirect
	     );
@EXPORT_OK = ();

use strict;
use Carp;

use DB::DbgrCommon;
use DB::DbgrProperties (qw(figureEncoding));

use constant DBGP_Redirect_Disable => 0;
use constant DBGP_Redirect_Copy => 1;
use constant DBGP_Redirect_Redirect => 2;

sub TIEHANDLE {
    my ($class, $origHandle, $newFileHandle, $streamType, $redirectState) = @_;
    my $data = { h_new => $newFileHandle,
		 h_old => $origHandle,
		 streamType => $streamType,
		 redirectState => $redirectState,
	       };
    bless $data, $class;
}

sub doOutput($$$$) {
    my ($buf, $streamType, $redirectState, $h_old) = @_;
    local $DB::full_bypass = 1;
    if ($redirectState != DBGP_Redirect_Disable)  {
	my ($encoding, $encVal) = figureEncoding($buf);
	printWithLength(sprintf(qq(%s\n<stream %s
				   type="%s"
				   encoding="%s">%s</stream>\n),
				xmlHeader(),
				namespaceAttr(),
				$streamType,
				$encoding,
				$encVal,
				));
    }
    if ($redirectState != DBGP_Redirect_Redirect)  {
	print $h_old $buf;
    }
}


sub WRITE {
    my $self = shift;
    my $h_new = $self->{h_new};
    my $h_old = $self->{h_old};
    my $streamType = $self->{streamType};
    my $redirectState = $self->{redirectState};
    my ($buf, $len, $offset) = @_;
    substr($buf, $len) = "" if $len;
    doOutput($buf, $streamType, $redirectState, $h_old);
}

sub PRINT { 
    my $self = shift;
    my $h_new = $self->{h_new};
    my $h_old = $self->{h_old};
    my $streamType = $self->{streamType};
    my $redirectState = $self->{redirectState};
    my $buf = join('', @_);
    doOutput($buf, $streamType, $redirectState, $h_old);
}

sub PRINTF { 
    my $self = shift;
    my $h_new = $self->{h_new};
    my $h_old = $self->{h_old};
    my $streamType = $self->{streamType};
    my $redirectState = $self->{redirectState};
    my $fmt = shift;
    my $buf = sprintf($fmt, @_);
    doOutput($buf, $streamType, $redirectState, $h_old);
}

sub READ { 
}

sub READLINE {
}

sub GETC {
}

sub CLOSE {
}

sub UNTIE { 
    my $self = shift;
#    die "Not expected";
}

sub DESTROY {
    my $self = shift;
    my $h_new = $self->{h_new};
    my $h_old = $self->{h_old};
    close $h_new;
}

sub FILENO {
    my $self = shift;
    my $h_new = $self->{h_new};
    my $h_old = $self->{h_old};
    my $redirectState = $self->{redirectState};
    if ($redirectState != DBGP_Redirect_Disable)  {
	return fileno($h_new);
    } else {
	return fileno($h_old);
    }
}

sub BINMODE {
    my ($self, $layer) = @_;
    return binmode $self->{h_old}, $layer if $layer;
    return binmode $self->{h_old};
}

# "Optional" routines, according to perldoc perltie.  
# Bug 34879 shows they were using them.  The proper
# fix is to die when they're used, so the user can 
# figure something else out.

sub _buildMessage_Die {
    my $op = shift;
    my @messages = (
		    "Unexpected use of a standard filehandle while debugging:",
		    "The STDOUT and STDERR handles have been tied for remote debugging, ",
		    "and can't $op in the code being debugged.",
		    "",
		    "Try adding ",
		    "  untie(\*STDOUT) if tied(\*STDOUT);",
		    "  untie(\*STDERR) if tied(\*STDERR);",
		    "to the code",
		    );
    carp join("\n", @messages);
}

sub OPEN {
    _buildMessage_Die('be redirected');
}

sub EOF {
    _buildMessage_Die('be read from');
}

sub SEEK {
    _buildMessage_Die('support seek');
}

sub TELL {
    _buildMessage_Die('support seek');
}

1;
