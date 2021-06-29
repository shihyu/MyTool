package DB::IO::Lines;


use Carp;
use strict;
use DB::IO::ScalarArray;
use vars qw($VERSION @ISA);

# The package version, both in 1.23 style *and* usable by MakeMaker:
$VERSION = substr q$Revision: 2.103 $, 10;

# Inheritance:
@ISA = qw(DB::IO::ScalarArray);     ### also gets us new_tie  :-)


#------------------------------
#
# getline
#
# Instance method, override.
# Return the next line, or undef on end of data.
# Can safely be called in an array context.
# Currently, lines are delimited by "\n".
#
sub getline {
    my $self = shift;

    if (!defined $/) {
	return join( '', $self->_getlines_for_newlines );
    }
    elsif ($/ eq "\n") {
	if (!*$self->{Pos}) {      ### full line...
	    return *$self->{AR}[*$self->{Str}++];
	}
	else {                     ### partial line...
	    my $partial = substr(*$self->{AR}[*$self->{Str}++], *$self->{Pos});
	    *$self->{Pos} = 0;
	    return $partial;
	}
    }
    else {
	croak 'unsupported $/: must be "\n" or undef';
    }
}

#------------------------------
#
# getlines
#
# Instance method, override.
# Return an array comprised of the remaining lines, or () on end of data.
# Must be called in an array context.
# Currently, lines are delimited by "\n".
#
sub getlines {
    my $self = shift;
    wantarray or croak("can't call getlines in scalar context!");

    if ((defined $/) and ($/ eq "\n")) {
	return $self->_getlines_for_newlines(@_);
    }
    else {         ### slow but steady
	return $self->SUPER::getlines(@_);
    }
}

#------------------------------
#
# _getlines_for_newlines
#
# Instance method, private.
# If $/ is newline, do fast getlines.
# This CAN NOT invoke getline!
#
sub _getlines_for_newlines {
    my $self = shift;
    my ($rArray, $Str, $Pos) = @{*$self}{ qw( AR Str Pos ) };
    my @partial = ();

    if ($Pos) {				### partial line...
	@partial = (substr( $rArray->[ $Str++ ], $Pos ));
	*$self->{Pos} = 0;
    }
    *$self->{Str} = scalar @$rArray;	### about to exhaust @$rArray
    return (@partial,
	    @$rArray[ $Str .. $#$rArray ]);	### remaining full lines...
}

#------------------------------
#
# print ARGS...
#
# Instance method, override.
# Print ARGS to the underlying line array.  
#
sub print {
    my $self = shift;
    ### print STDERR "\n[[ARRAY WAS...\n", @{*$self->{AR}}, "<<EOF>>\n";
    my @lines = split /^/, join('', @_); @lines or return 1;

    ### Did the previous print not end with a newline?  
    ### If so, append first line:
    if (@{*$self->{AR}} and (*$self->{AR}[-1] !~ /\n\Z/)) {
	*$self->{AR}[-1] .= shift @lines;
    }
    push @{*$self->{AR}}, @lines;       ### add the remainder
    ### print STDERR "\n[[ARRAY IS NOW...\n", @{*$self->{AR}}, "<<EOF>>\n";
    1;
}

#------------------------------
1;
