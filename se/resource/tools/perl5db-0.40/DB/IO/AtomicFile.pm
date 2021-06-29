package DB::IO::AtomicFile;

### DOCUMENTATION AT BOTTOM OF FILE

# Be strict:
use strict;

# External modules:
use IO::File;


#------------------------------
#
# GLOBALS...
#
#------------------------------
use vars qw($VERSION @ISA);

# The package version, both in 1.23 style *and* usable by MakeMaker:
$VERSION = substr q$Revision: 2.101 $, 10;

# Inheritance:
@ISA = qw(IO::File);


#------------------------------
# new ARGS...
#------------------------------
# Class method, constructor.
# Any arguments are sent to open().
#
sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    ${*$self}{'io_atomicfile_suffix'} = '';
    $self->open(@_) if @_;
    $self;
}

#------------------------------
# DESTROY 
#------------------------------
# Destructor.
#
sub DESTROY {
    shift->close(1);   ### like close, but raises fatal exception on failure
}

#------------------------------
# open PATH, MODE
#------------------------------
# Class/instance method.
#
sub open {
    my ($self, $path, $mode) = @_;
    ref($self) or $self = $self->new;    ### now we have an instance! 

    ### Create tmp path, and remember this info: 
    my $temp = "${path}..TMP" . ${*$self}{'io_atomicfile_suffix'};
    ${*$self}{'io_atomicfile_temp'} = $temp;
    ${*$self}{'io_atomicfile_path'} = $path;

    ### Open the file!  Returns filehandle on success, for use as a constructor: 
    $self->SUPER::open($temp, $mode) ? $self : undef;
}

#------------------------------
# _closed [YESNO]
#------------------------------
# Instance method, private.
# Are we already closed?  Argument sets new value, returns previous one.
#
sub _closed {
    my $self = shift;
    my $oldval = ${*$self}{'io_atomicfile_closed'};
    ${*$self}{'io_atomicfile_closed'} = shift if @_;
    $oldval;
}

#------------------------------
# close
#------------------------------
# Instance method.
# Close the handle, and rename the temp file to its final name.
#
sub close {
    my ($self, $die) = @_;
    unless ($self->_closed(1)) {             ### sentinel...
        $self->SUPER::close();    
        rename(${*$self}{'io_atomicfile_temp'},
	       ${*$self}{'io_atomicfile_path'}) 
            or ($die ? die "close atomic file: $!\n" : return undef); 
    }
    1;
}

#------------------------------
# delete
#------------------------------
# Instance method.
# Close the handle, and delete the temp file.
#
sub delete {
    my $self = shift;
    unless ($self->_closed(1)) {             ### sentinel...
        $self->SUPER::close();    
        return unlink(${*$self}{'io_atomicfile_temp'});
    }
    1;
}

#------------------------------
# detach
#------------------------------
# Instance method.
# Close the handle, but DO NOT delete the temp file.
#
sub detach {
    my $self = shift;
    $self->SUPER::close() unless ($self->_closed(1));
    1;
}

#------------------------------
1;
