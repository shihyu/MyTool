#
# DbgrCommon.pm -- common routines used by all the debugger modues.
#
# Copyright (c) 2003-2006 ActiveState Software Inc.
# All rights reserved.
# 
# This software (the Perl-DBGP package) is covered by the Artistic License
# (http://www.opensource.org/licenses/artistic-license.php).

package DB::DbgrCommon;

use DB::CGI::Util qw();
use DB::MIME::Base64 qw();
use File::Basename qw(dirname);

BEGIN	{
    if ($] >= 5.008) {
	require Encode;
    }
}

$VERSION = 0.10;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(encodeData
	     endPropertyTag getCommonType
             isFloat
	     makeErrorResponse namespaceAttr
	     printWithLength
	     setDefaultOutput
	     xmlHeader xmlEncode xmlAttrEncode
	     nonXmlChar_Decode
	     nonXmlChar_Encode

                    DBP_E_NoError
                    DBP_E_ParseError
                    DBP_E_DuplicateArguments
                    DBP_E_InvalidOption
                    DBP_E_CommandUnimplemented
                    DBP_E_CommandNotAvailable
                    DBP_E_UnrecognizedCommand

                    DBP_E_CantOpenSource

                    DBP_E_BreakpointNotSet
                    DBP_E_BreakpointTypeNotSupported
                    DBP_E_Unbreakable_InvalidCodeLine
                    DBP_E_Unbreakable_EmptyCodeLine
                    DBP_E_BreakpointStateInvalid
                    DBP_E_NoSuchBreakpoint
	            DBP_E_CantSetProperty
                    DBP_E_PropertyEvalError

                    DBP_E_CantGetProperty
                    DBP_E_StackDepthInvalid
                    DBP_E_ContextInvalid

	     DBP_E_EncodingNotSupported
	     DBP_E_InternalException
	     DBP_E_UnknownError
	     
	     NV_NAME
	     NV_VALUE
	     NV_NEED_MAIN_LEVEL_EVAL
	     NV_UNSET_FLAG

	     %settings
	     dblog
	     );

# Leave the other parts of the logger unexported.

@EXPORT_OK = qw();

# Error codes

use constant DBP_E_NoError => 0;
use constant DBP_E_ParseError => 1;
use constant DBP_E_DuplicateArguments => 2;
use constant DBP_E_InvalidOption => 3;
use constant DBP_E_CommandUnimplemented => 4;
use constant DBP_E_CommandNotAvailable => 5;

#todo: add this to protocol
use constant DBP_E_UnrecognizedCommand => 6;

use constant DBP_E_CantOpenSource => 100;

use constant DBP_E_BreakpointNotSet => 200;
use constant DBP_E_BreakpointTypeNotSupported => 201;
use constant DBP_E_Unbreakable_InvalidCodeLine => 202;
use constant DBP_E_Unbreakable_EmptyCodeLine => 203;
use constant DBP_E_BreakpointStateInvalid => 204;
use constant DBP_E_NoSuchBreakpoint => 205;
use constant DBP_E_PropertyEvalError => 206;
use constant DBP_E_CantSetProperty => 207;

use constant DBP_E_CantGetProperty => 300;
use constant DBP_E_StackDepthInvalid => 301;
use constant DBP_E_ContextInvalid => 302;

use constant DBP_E_EncodingNotSupported => 900;
use constant DBP_E_InternalException => 998;
use constant DBP_E_UnknownError => 999;

use constant NV_NAME => 0;
use constant NV_VALUE => 1;
use constant NV_NEED_MAIN_LEVEL_EVAL => 2;
use constant NV_UNSET_FLAG => 3;

# Real simple logging

$doLogging = 0;
$logFH = undef;

# enableLogger(filename || filehandle);
# dies if it fails to do logging

sub enableLogger {
    if (!@_) {
	# Enable $doLogging if we have an existing log file handle
	if ($logFH) {
	    $doLogging = 1;
	    printf $logFH "Logging reenabled at %s\n", ('' . localtime(time()));
	}
	return;
    }
    if ($DB::is_perl_5_005) {
	print STDERR "Sorry, Komodo requires Perl 5.6 or higher to support debugger logging; this is version $].\n";
	$doLogging = 0;
	return;
    }
    my $outLogName;
    $DB::outLogName = $outLogName = shift;
    return unless $outLogName;
    if (ref $outLogName eq 'GLOB') {
	# Make sure we can write to it -- we die if we can't
	printf $outLogName "Logging enabled at %s\n", ('' . localtime(time()));
	$logFH = $outLogName;
    } else {
	# Check to see if the filename is urlencoded
	if ($outLogName =~ /\%u?[a-fA-F0-9]{2}/ && ! -d $outLogName && ! -d dirname($outLogName)) {
	    $outLogName = DB::CGI::Util::unescape($outLogName);
	}
	if (-d $outLogName) {
	    $outLogName =~ s@\\@/@g;
	    $outLogName =~ s@/$@@;
	    $outLogName .= "/perl5db.log";
	}
	my $ofh;
	open $ofh, ">$outLogName" or die "Failed to open $outLogName for writing: $!";
	my $oh = select $ofh;
	$| = 1;
	select $oh;
	printf $ofh "Logging enabled at %s\n", ('' . localtime(time()));
	$logFH = $ofh;
    }
    $doLogging = 1;
}

sub disableLogger {
    printf $logFH "Logging disabled at %s\n", ('' . localtime(time()));
    $doLogging = 0;
}

sub closeLogger {
    if ($logFH) {
	printf $logFH "Logging ended at %s\n", ('' . localtime(time()));
	close ($logFH);
	$logFH = undef;
    }
    $doLogging = 0;
}

sub dblog {
    if (@_ && $doLogging && $logFH) {
	print $logFH map { wide_char_safe_encode($_)} @_;
	# End with a newline
	print $logFH "\n" unless substr($_[-1], -1, 1) eq "\n";
    }
}

# our ($OUT, $ldebug);

sub setDefaultOutput {
    $OUT = shift;
}

sub encodeData($;$) {
    my ($str, $encoding) = @_;
    my $finalStr;
    my $currDataEncoding = defined $encoding ? $encoding : $settings{data_encoding}->[0];
    $finalStr = $str;
    local $@;
    eval {
	if ($currDataEncoding eq 'none' || $currDataEncoding eq 'binary') {
	    $finalStr = $str;
	} elsif ($currDataEncoding eq 'urlescape') {
	    $finalStr = DB::CGI::Util::escape($str);
	} elsif ($currDataEncoding eq 'base64') {
	    $finalStr = DB::MIME::Base64::encode_base64($str);
	} else {
	    dblog("Converting $str with unknown encoding of $currDataEncoding\n") if $ldebug;
	    $finalStr = $str;
	}
    };
    if ($ldebug) {
	my $str = safe_dump($str);
	if ($@) {
	    $str = (substr($str, 0, 100) . '...') if length($str) > 100;
	    dblog("encodeData('$str') => [$@]\n");
	} else {
	    dblog("encodeData('$str') => ['$finalStr']\n");
	}
    }
    return $finalStr;
}

sub endPropertyTag($$) {
    my ($encVal, $encoding) = @_;
    my $res;
    if (defined $encVal && length $encVal > 0) {
#		$res .= sprintf(qq(>%s</property>\n), ($encVal));
	$res = sprintf(qq(><![CDATA[%s]]></property>\n), ($encVal));
    } else {
	$res = qq(/>\n);
    }
    return $res;
}

# If other names are used here, be sure to update the
# list in sub DB::emitTypeMapInfo

sub getCommonType($) {
    my ($val) = @_;
    if (! defined $val) {
	return 'undef';
    }
    my $r;
    if ($r = ref $val) {
	$r =~ s/\(0x\w+\)//;
	return $r;
    } else {
	return '';
    }
}

sub isFloat($) {
    my ($val) = @_;
    return $val =~ /^
                    (?:
  		     [-+]?           # leading sign always optional
		     (?:
		        \d+          # required base
		        (?:\.\d*)?   # optional fractional part
	             )|(?:
		       \.            # required decimal pt and number
		       \d+
		       )
		     )
		     (?:[eE][-+]?\d+)?  # exponent always optional
		     $/x;
}

sub makeErrorResponse($$$$) {
    my ($cmd, $transactionID, $code, $error) = @_;
    printWithLength(sprintf
		    (qq(%s\n<response %s command="%s" 
			transaction_id="%s" ><error code="%d" apperr="4">
			<message>%s</message>
			</error></response>),
		     xmlHeader(),
		     namespaceAttr(),
		     $cmd,
		     $transactionID,
		     $code,
		     $error));
    return undef;
}

sub namespaceAttr() {
  return 'xmlns="urn:debugger_protocol_v1"';
}

sub printWithLength {
  local $mainArg = shift;
  local $argLen = length($mainArg);
  local $finalStr = sprintf("%d\0%s\0", $argLen, $mainArg);
####   local $SIG{__WARN__} = sub {
####       my $msg = shift;
####       dblog("**************** Warn hook: {$msg}");
####       if ($msg !~ /Wide character in print at .*DbgrCommon\.pm/s) {
#### 	  warn $msg;
#### 	  dblog("Don't have wide char");
####       }
####   };
  # dblog $finalStr;
  $OUT = \*STDOUT unless $OUT;
  print $OUT $finalStr;
}
  
# Like xmlEncode, but escape the quotes

sub xmlAttrEncode {
    my ($str) = @_;
    $str = xmlEncode($str);
    $str =~ s/([\'\"])/'&#' . ord($1) . ';'/eg;
    return $str;
}

# This routine *cannot* do logging until dblog checks its caller
# before calling wide_char_safe_encode

sub wide_char_safe_encode {
    my ($str) = @_;
    if ($] < 5.007) {
	# Don't bother trying to do wide-char processing with 5.6
	return $str;
    }
    require bytes;
    if (bytes::length($str) == length($str)) {
	# don't utf-8-encode a string in latin* or cp1251
	# just pass it to Komodo as is.
	return $str;
    }
    my $enc_str = eval { Encode::encode_utf8($str); };
    return $enc_str || $str;
}

sub safe_dump {
    my $str = shift;
    $str =~ s/([^\x09\x0a\0x0d\x20-\x7f])/sprintf('\\x%02x', ord($1))/eg;
    $str;
}


sub wide_char_safe_decode {
    my ($str) = @_;
    if ($] < 5.007 || $str !~ /[^\x00-\x7f]/) {
	return $str;
    }

    # Not all strings are utf8 strings, but if a string looks like
    # a UTF-8 string, assume that it is, and return its actual value.
    #
    # The problem is that strings coming from the program might be
    # utf-8 or latin1, but strings coming from Mozilla are
    # always latin1-encoded.
    #
    # The prototype of this function changed from ($) to ($;$)
    # at version 5.8.3RC1
    # Use an indirect function call to bypass prototype checking at
    # compile-time. Earlier versions of Perl will process only the first arg.

    local $@;
    my $fn_ref = \&Encode::decode_utf8;
    my $enc_str = eval { $fn_ref->($str, Encode::FB_CROAK); };
    return $enc_str || $str;
}

sub nonXmlChar_Encode {
    my ($str) = @_;
    if ($] >= 5.007) {
	$str = wide_char_safe_encode($str);
    }
    return $str;
}

sub nonXmlChar_Decode {
    my ($str) = @_;
    if ($] >= 5.008) {
	$str = wide_char_safe_decode($str);
    }
    return $str;
}

sub xmlEncode {
    my ($str) = @_;
    $str =~ s/\&/&amp;/g;
    $str =~ s/</&lt;/g;
    $str =~ s/>/&gt;/g;
    $str =~ s/([\x00-\x08\x0b\x0c\x0e-\x1f])/'&#' . ord($1) . ';'/eg;
    if ($] >= 5.007) {
	$str = wide_char_safe_encode($str);
    }
    # No need to escape quotes.
    return $str;
}

sub xmlHeader() {
  return '<?xml version="1.0" encoding="' . $settings{encoding}->[0] . '" ?>';
}

1;
