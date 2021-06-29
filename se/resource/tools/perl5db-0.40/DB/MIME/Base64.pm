# Copyright (c) 1998-2006 ActiveState Software Inc.
# All rights reserved.
# 
# This software (the Perl-DBGP package) is covered by the Artistic License
# (http://www.opensource.org/licenses/artistic-license.php).

package DB::MIME::Base64;

use strict;
use vars qw(@ISA $VERSION);

# Based on MIME::Base64::Perl
# Exports nothing

$VERSION = '1.00';

sub encode_base64 ($;$)
{
    if ($] >= 5.006) {
	require bytes;
	if (bytes::length($_[0]) > length($_[0]) ||
	    ($] >= 5.008 && $_[0] =~ /[^\0-\xFF]/))
	{
	    require Carp;
	    Carp::croak("The Base64 encoding is only defined for bytes");
	}
    }

    use integer;

    my $eol = $_[1];
    $eol = "\n" unless defined $eol;

    my $res = pack("u", $_[0]);
    # Remove first character of each line, remove newlines
    $res =~ s/^.//mg;
    $res =~ s/\n//g;

    $res =~ tr|` -_|AA-Za-z0-9+/|;               # `# help emacs
    # fix padding at the end
    my $padding = (3 - length($_[0]) % 3) % 3;
    $res =~ s/.{$padding}$/'=' x $padding/e if $padding;
    # break encoded string into lines of no more than 76 characters each
    if (length $eol) {
	$res =~ s/(.{1,76})/$1$eol/g;
    }
    return $res;
}


sub decode_base64 ($)
{
    local($^W) = 0; # unpack("u",...) gives bogus warning in 5.00[123]
    use integer;

    my $str = shift;
    $str =~ tr|A-Za-z0-9+=/||cd;            # remove non-base64 chars
    if (length($str) % 4) {
	require Carp;
	Carp::carp("Length of base64 data not a multiple of 4")
    }
    $str =~ s/=+$//;                        # remove padding
    $str =~ tr|A-Za-z0-9+/| -_|;            # convert to uuencoded format
    return "" unless length $str;

    ## I guess this could be written as
    #return unpack("u", join('', map( chr(32 + length($_)*3/4) . $_,
    #			$str =~ /(.{1,60})/gs) ) );
    ## but I do not like that...
    my $uustr = '';
    my ($i, $l);
    $l = length($str) - 60;
    for ($i = 0; $i <= $l; $i += 60) {
	$uustr .= "M" . substr($str, $i, 60);
    }
    $str = substr($str, $i);
    # and any leftover chars
    if ($str ne "") {
	$uustr .= chr(32 + length($str)*3/4) . $str;
    }
    return unpack ("u", $uustr);
}

1;

__END__

=head1 NAME

DB::MIME::Base64::Perl - Encoding and decoding of base64 strings

=head1 SYNOPSIS

 use DB::MIME::Base64::Perl;

 $encoded = encode_base64('Aladdin:open sesame');
 $decoded = decode_base64($encoded);

=head1 DESCRIPTION

This module provide the same interface as C<DB::MIME::Base64>, but these
functions are implemented in pure perl.

This module provides functions to encode and decode strings into and from the
base64 encoding specified in RFC 2045 - I<MIME (Multipurpose Internet
Mail Extensions)>. The base64 encoding is designed to represent
arbitrary sequences of octets in a form that need not be humanly
readable. A 65-character subset ([A-Za-z0-9+/=]) of US-ASCII is used,
enabling 6 bits to be represented per printable character.

The following functions are provided:

=over 4

=item encode_base64($str)

=item encode_base64($str, $eol);

Encode data by calling the encode_base64() function.  The first
argument is the string to encode.  The second argument is the
line-ending sequence to use.  It is optional and defaults to "\n".  The
returned encoded string is broken into lines of no more than 76
characters each and it will end with $eol unless it is empty.  Pass an
empty string as second argument if you do not want the encoded string
to be broken into lines.

=item decode_base64($str)

Decode a base64 string by calling the decode_base64() function.  This
function takes a single argument which is the string to decode and
returns the decoded data.

Any character not part of the 65-character base64 subset is
silently ignored.  Characters occurring after a '=' padding character
are never decoded.

=back

=head1 COPYRIGHT

Copyright 1995-1999, 2001-2004 Gisle Aas.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Distantly based on LWP::Base64 written by Martijn Koster
<m.koster@nexor.co.uk> and Joerg Reichelt <j.reichelt@nexor.co.uk> and
code posted to comp.lang.perl <3pd2lp$6gf@wsinti07.win.tue.nl> by Hans
Mulder <hansm@wsinti07.win.tue.nl>

=head1 SEE ALSO

L<DB::MIME::Base64>, L<DB::MIME::QuotedPrint::Perl>

=cut
