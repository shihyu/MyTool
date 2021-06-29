package DB::IO::Wrap;

# SEE DOCUMENTATION AT BOTTOM OF FILE

require 5.002;

use strict;
use vars qw(@ISA @EXPORT $VERSION);
@ISA = qw(Exporter);
@EXPORT = qw(wraphandle);

use FileHandle;
use Carp;

# The package version, both in 1.23 style *and* usable by MakeMaker:
$VERSION = substr q$Revision: 2.102 $, 10;


#------------------------------
# wraphandle RAW
#------------------------------
sub wraphandle {
    my $raw = shift;
    new DB::IO::Wrap $raw;
}

#------------------------------
# new STREAM
#------------------------------
sub new {
    my ($class, $stream) = @_;
    no strict 'refs';

    ### Convert raw scalar to globref:
    ref($stream) or $stream = \*$stream;

    ### Wrap globref and incomplete objects:
    if ((ref($stream) eq 'GLOB') or      ### globref
	(ref($stream) eq 'FileHandle') && !defined(&FileHandle::read)) {
	return bless \$stream, $class;
    }
    $stream;           ### already okay!
}

#------------------------------
# I/O methods...
#------------------------------
sub close {
    my $self = shift;
    return close($$self);
}
sub getline {
    my $self = shift;
    my $fh = $$self;
    return scalar(<$fh>);
}
sub getlines {
    my $self = shift;
    wantarray or croak("Can't call getlines in scalar context!");
    my $fh = $$self;
    <$fh>;
}
sub print {
    my $self = shift;
    print { $$self } @_;
}
sub read {
    my $self = shift;
    return read($$self, $_[0], $_[1]);
}
sub seek {
    my $self = shift;
    return seek($$self, $_[0], $_[1]);
}
sub tell {
    my $self = shift;
    return tell($$self);
}

#------------------------------
1;
