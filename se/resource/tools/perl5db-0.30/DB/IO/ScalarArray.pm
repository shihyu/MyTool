package DB::IO::ScalarArray;

use Carp;
use strict;
use vars qw($VERSION @ISA);
use IO::Handle;

# The package version, both in 1.23 style *and* usable by MakeMaker:
$VERSION = substr q$Revision: 2.103 $, 10;

# Inheritance:
@ISA = qw(IO::Handle);
require DB::IO::WrapTie and push @ISA, 'DB::IO::WrapTie::Slave' if ($] >= 5.004);


#==============================

=head2 Construction 

=over 4

=cut

#------------------------------

=item new [ARGS...]

I<Class method.>
Return a new, unattached array handle.  
If any arguments are given, they're sent to open().

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = bless \do { local *FH }, $class;
    tie *$self, $class, $self;
    $self->open(@_);  ### open on anonymous by default
    $self;
}
sub DESTROY { 
    shift->close;
}


#------------------------------

=item open [ARRAYREF]

I<Instance method.>
Open the array handle on a new array, pointed to by ARRAYREF.
If no ARRAYREF is given, a "private" array is created to hold
the file data.

Returns the self object on success, undefined on error.

=cut

sub open {
    my ($self, $aref) = @_;

    ### Sanity:
    defined($aref) or do {my @a; $aref = \@a};
    (ref($aref) eq "ARRAY") or croak "open needs a ref to a array";

    ### Setup:
    $self->setpos([0,0]);
    *$self->{AR} = $aref;
    $self;
}

#------------------------------

=item opened

I<Instance method.>
Is the array handle opened on something?

=cut

sub opened {
    *{shift()}->{AR};
}

#------------------------------

=item close

I<Instance method.>
Disassociate the array handle from its underlying array.
Done automatically on destroy.

=cut

sub close {
    my $self = shift;
    %{*$self} = ();
    1;
}

=back

=cut



#==============================

=head2 Input and output

=over 4

=cut

#------------------------------

=item flush 

I<Instance method.>
No-op, provided for OO compatibility.

=cut

sub flush {} 

#------------------------------

=item getc

I<Instance method.>
Return the next character, or undef if none remain.
This does a read(1), which is somewhat costly.

=cut

sub getc {
    my $buf = '';
    ($_[0]->read($buf, 1) ? $buf : undef);
}

#------------------------------

=item getline

I<Instance method.>
Return the next line, or undef on end of data.
Can safely be called in an array context.
Currently, lines are delimited by "\n".

=cut

sub getline {
    my $self = shift;
    my ($str, $line) = (undef, '');


    ### Minimal impact implementation!
    ### We do the fast fast thing (no regexps) if using the
    ### classic input record separator.

    ### Case 1: $/ is undef: slurp all...    
    if    (!defined($/)) {

	### Get the rest of the current string, followed by remaining strings:
	my $ar = *$self->{AR};
	my @slurp = (
		     substr($ar->[*$self->{Str}], *$self->{Pos}),
		     @$ar[(1 + *$self->{Str}) .. $#$ar ] 
		     );
	     	
	### Seek to end:
	$self->_setpos_to_eof;
	return join('', @slurp);
    }

    ### Case 2: $/ is "\n": 
    elsif ($/ eq "\012") {    
	
	### Until we hit EOF (or exitted because of a found line):
	until ($self->eof) {
	    ### If at end of current string, go fwd to next one (won't be EOF):
	    if ($self->_eos) {++*$self->{Str}, *$self->{Pos}=0};

	    ### Get ref to current string in array, and set internal pos mark:
	    $str = \(*$self->{AR}[*$self->{Str}]); ### get current string
	    pos($$str) = *$self->{Pos};            ### start matching from here
	
	    ### Get from here to either \n or end of string, and add to line:
	    $$str =~ m/\G(.*?)((\n)|\Z)/g;         ### match to 1st \n or EOS
	    $line .= $1.$2;                        ### add it
	    *$self->{Pos} += length($1.$2);        ### move fwd by len matched
	    return $line if $3;                    ### done, got line with "\n"
        }
        return ($line eq '') ? undef : $line;  ### return undef if EOF
    }

    ### Case 3: $/ is ref to int.  Bail out.
    elsif (ref($/)) {
        croak '$/ given as a ref to int; currently unsupported';
    }

    ### Case 4: $/ is either "" (paragraphs) or something weird...
    ###         Bail for now.
    else {                
        croak '$/ as given is currently unsupported';
    }
}

#------------------------------

=item getlines

I<Instance method.>
Get all remaining lines.
It will croak() if accidentally called in a scalar context.

=cut

sub getlines {
    my $self = shift;
    wantarray or croak("can't call getlines in scalar context!");
    my ($line, @lines);
    push @lines, $line while (defined($line = $self->getline));
    @lines;
}

#------------------------------

=item print ARGS...

I<Instance method.>
Print ARGS to the underlying array.  

Currently, this always causes a "seek to the end of the array"
and generates a new array entry.  This may change in the future.

=cut

sub print {
    my $self = shift;
    push @{*$self->{AR}}, join('', @_);      ### add the data
    $self->_setpos_to_eof;
    1;
}

#------------------------------

=item read BUF, NBYTES, [OFFSET];

I<Instance method.>
Read some bytes from the array.
Returns the number of bytes actually read, 0 on end-of-file, undef on error.

=cut

sub read {
    my $self = $_[0];
    ### we must use $_[1] as a ref
    my $n    = $_[2];
    my $off  = $_[3] || 0;

    ### print "getline\n";
    my $justread;
    my $len;
    ($off ? substr($_[1], $off) : $_[1]) = '';

    ### Stop when we have zero bytes to go, or when we hit EOF:
    my @got;
    until (!$n or $self->eof) {       
        ### If at end of current string, go forward to next one (won't be EOF):
        if ($self->_eos) {
            ++*$self->{Str};
            *$self->{Pos} = 0;
        }

        ### Get longest possible desired substring of current string:
        $justread = substr(*$self->{AR}[*$self->{Str}], *$self->{Pos}, $n);
        $len = length($justread);
        push @got, $justread;
        $n            -= $len; 
        *$self->{Pos} += $len;
    }
    $_[1] .= join('', @got);
    return length($_[1])-$off;
}

#------------------------------

=item write BUF, NBYTES, [OFFSET];

I<Instance method.>
Write some bytes into the array.

=cut

sub write {
    my $self = $_[0];
    my $n    = $_[2];
    my $off  = $_[3] || 0;

    my $data = substr($_[1], $n, $off);
    $n = length($data);
    $self->print($data);
    return $n;
}


=back

=cut



#==============================

=head2 Seeking/telling and other attributes

=over 4

=cut

#------------------------------

=item autoflush 

I<Instance method.>
No-op, provided for OO compatibility.

=cut

sub autoflush {} 

#------------------------------

=item binmode

I<Instance method.>
No-op, provided for OO compatibility.

=cut

sub binmode {} 

#------------------------------

=item clearerr

I<Instance method.>  Clear the error and EOF flags.  A no-op.

=cut

sub clearerr { 1 }

#------------------------------

=item eof 

I<Instance method.>  Are we at end of file?

=cut

sub eof {
    ### print "checking EOF [*$self->{Str}, *$self->{Pos}]\n";
    ### print "SR = ", $#{*$self->{AR}}, "\n";

    return 0 if (*{$_[0]}->{Str} < $#{*{$_[0]}->{AR}});  ### before EOA
    return 1 if (*{$_[0]}->{Str} > $#{*{$_[0]}->{AR}});  ### after EOA
    ###                                                  ### at EOA, past EOS:
    ((*{$_[0]}->{Str} == $#{*{$_[0]}->{AR}}) && ($_[0]->_eos)); 
}

#------------------------------
#
# _eos
#
# I<Instance method, private.>  Are we at end of the CURRENT string?
#
sub _eos {
    (*{$_[0]}->{Pos} >= length(*{$_[0]}->{AR}[*{$_[0]}->{Str}])); ### past last char
}

#------------------------------

=item seek POS,WHENCE

I<Instance method.>
Seek to a given position in the stream.
Only a WHENCE of 0 (SEEK_SET) is supported.

=cut

sub seek {
    my ($self, $pos, $whence) = @_; 

    ### Seek:
    if    ($whence == 0) { $self->_seek_set($pos); }
    elsif ($whence == 1) { $self->_seek_cur($pos); }
    elsif ($whence == 2) { $self->_seek_end($pos); }
    else                 { croak "bad seek whence ($whence)" }
}

#------------------------------
#
# _seek_set POS
#
# Instance method, private.
# Seek to $pos relative to start:
#
sub _seek_set {
    my ($self, $pos) = @_; 

    ### Advance through array until done:
    my $istr = 0;
    while (($pos >= 0) && ($istr < scalar(@{*$self->{AR}}))) {
	if (length(*$self->{AR}[$istr]) > $pos) {   ### it's in this string! 
	    return $self->setpos([$istr, $pos]);
	}
	else {                                      ### it's in next string
	    $pos -= length(*$self->{AR}[$istr++]);  ### move forward one string
	}
    }
    ### If we reached this point, pos is at or past end; zoom to EOF:
    return $self->_setpos_to_eof;
}

#------------------------------
#
# _seek_cur POS
#
# Instance method, private.
# Seek to $pos relative to current position.
#
sub _seek_cur {
    my ($self, $pos) = @_; 
    $self->_seek_set($self->tell + $pos);
}

#------------------------------
#
# _seek_end POS
#
# Instance method, private.
# Seek to $pos relative to end.
# We actually seek relative to beginning, which is simple.
#
sub _seek_end {
    my ($self, $pos) = @_; 
    $self->_seek_set($self->_tell_eof + $pos);
}

#------------------------------

=item tell

I<Instance method.>
Return the current position in the stream, as a numeric offset.

=cut

sub tell {
    my $self = shift;
    my $off = 0;
    my ($s, $str_s);
    for ($s = 0; $s < *$self->{Str}; $s++) {   ### count all "whole" scalars
	defined($str_s = *$self->{AR}[$s]) or $str_s = '';
	###print STDERR "COUNTING STRING $s (". length($str_s) . ")\n";
	$off += length($str_s);
    }
    ###print STDERR "COUNTING POS ($self->{Pos})\n";
    return ($off += *$self->{Pos});            ### plus the final, partial one
}

#------------------------------
#
# _tell_eof
#
# Instance method, private.
# Get position of EOF, as a numeric offset.
# This is identical to the size of the stream - 1.
#
sub _tell_eof {
    my $self = shift;
    my $len = 0;
    foreach (@{*$self->{AR}}) { $len += length($_) }
    $len;
}

#------------------------------

=item setpos POS

I<Instance method.>
Seek to a given position in the array, using the opaque getpos() value.
Don't expect this to be a number.

=cut

sub setpos { 
    my ($self, $pos) = @_;
    (ref($pos) eq 'ARRAY') or
	die "setpos: only use a value returned by getpos!\n";
    (*$self->{Str}, *$self->{Pos}) = @$pos;
}

#------------------------------
#
# _setpos_to_eof
#
# Fast-forward to EOF.
#
sub _setpos_to_eof {
    my $self = shift;
    $self->setpos([scalar(@{*$self->{AR}}), 0]);
}

#------------------------------

=item getpos

I<Instance method.>
Return the current position in the array, as an opaque value.
Don't expect this to be a number.

=cut

sub getpos {
    [*{$_[0]}->{Str}, *{$_[0]}->{Pos}];
}

#------------------------------

=item aref

I<Instance method.>
Return a reference to the underlying array.

=cut

sub aref {
    *{shift()}->{AR};
}

=back

=cut

#------------------------------
# Tied handle methods...
#------------------------------

### Conventional tiehandle interface:
sub TIEHANDLE { (defined($_[1]) && UNIVERSAL::isa($_[1],"DB::IO::ScalarArray"))
		    ? $_[1] 
		    : shift->new(@_) }
sub GETC      { shift->getc(@_) }
sub PRINT     { shift->print(@_) }
sub PRINTF    { shift->print(sprintf(shift, @_)) }
sub READ      { shift->read(@_) }
sub READLINE  { wantarray ? shift->getlines(@_) : shift->getline(@_) }
sub WRITE     { shift->write(@_); }
sub CLOSE     { shift->close(@_); }
sub SEEK      { shift->seek(@_); }
sub TELL      { shift->tell(@_); }
sub EOF       { shift->eof(@_); }

#------------------------------------------------------------

1;
