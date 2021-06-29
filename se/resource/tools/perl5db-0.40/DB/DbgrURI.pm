# DbgrURI.pm -- Manage Session filenames and URIs in this module
#
# Copyright (c) 2004-2006 ActiveState Software Inc.
# All rights reserved.
# 
# This software (the Perl-DBGP package) is covered by the Artistic License
# (http://www.opensource.org/licenses/artistic-license.php).

package DB::DbgrURI;

use DB::DbgrCommon;
use DB::OSType;

use File::Spec::Functions qw(
	canonpath
	catdir
	splitpath
	splitdir
	catpath
	rel2abs
);

use strict;
use vars qw($VERSION
	    @ISA
	    @EXPORT
	    @EXPORT_OK
	    %fileURILookupTable
	    @fileURI_No_ReverseLookupTable
	    %perlNameToFileURINo
	    %mem_uriToFilename
	    %mem_canonicalizeURI
	    %filenameToURI
	    $ldebug
	    $main_cwd
	    %module_paths
	    );

$VERSION = 0.10;
require Exporter;
@ISA = qw(Exporter);
# @EXPORT = qw(		 );
@EXPORT_OK = qw(canonicalizeFName
		    canonicalizeURI
		    filenameToURI
		    uriToFilename

		    %fileURILookupTable
		    %perlNameToFileURINo
		    );

%fileURILookupTable = ();             # Map fileURI => fileURI_No
@fileURI_No_ReverseLookupTable = ();  # Map fileURI_No => fileURI
%perlNameToFileURINo = ();            # Map perl-filename => fileURI_No

# Memoize things we look up often
%mem_uriToFilename = ();
%filenameToURI = ();

# ---------------- Configuring routine

sub init {
    my %options = @_;
    $ldebug = delete $options{ldebug};
    $main_cwd = delete $options{cwd};
}

# ---------------- Exported Routines

sub canonicalizeFName {
    my $fname = shift;
    $fname = canonpath($fname);
    if (IS_WIN32) {
	# Map everything to one case on Windows
	$fname = lc $fname;
	$fname =~ s@\\@/@g;
    }
    return $fname;
}

# The best way is to first unescape the URI, and then
# re-escape it so that incoming URIs follow the format
# used internally.
# Memoize because we have more queries than URIs we query on.

sub canonicalizeURI {
    my ($bFileURI) = @_;
    return $mem_canonicalizeURI{$bFileURI} if $mem_canonicalizeURI{$bFileURI};
    if ($bFileURI =~ m@^dbgp://@) {
	return ($mem_canonicalizeURI{$bFileURI} = $bFileURI);
    }
    local $@;
    my $new_URI = eval { filenameToURI(uriToFilename($bFileURI), 1) };
    if ($@ || !$new_URI) {
	$new_URI = $bFileURI;
	dblog($@) if ($@);
    } elsif ($new_URI ne $bFileURI) {
	dblog("canonicalizeURI($bFileURI) ==> $new_URI");
    }
    $mem_canonicalizeURI{$bFileURI} = $new_URI;
    return $new_URI;
}

# wrap_rel2abs -- first try resolving relative paths vs.
# the current directory,
# then vs. the process's original directory
# then finally return the last determined path.
# 
# Always ensure the path exists before memoizing it.
#
# Sometimes we return a non-existent dir, as in this case:

=example

chdir($dir1);
require ('foo.pm');  # Defines package Foo
chdir($dir2);
# This line finally steps into Foo
my $obj = Foo->new();  # Komodo debugger can't find it,
                       # returns a dbgp URI

=cut

sub wrap_rel2abs {
    my $bFileName = shift;
    my $absFileName = rel2abs($bFileName);
    if (-f $absFileName) {
	return $module_paths{$bFileName} = $absFileName;
    }
    if ($main_cwd) {
	my $absFileName2 = rel2abs($bFileName, $main_cwd);
	if (-f $absFileName2) {
	    return $module_paths{$bFileName} = $absFileName;
	}
    }
    if ($module_paths{$bFileName}) {
	return $module_paths{$bFileName};
    }
    # Return the original guess.
    return $absFileName;
}

sub filenameToURI {
    my ($bFileName, $foldCase) = @_;  # possibly backslashed name
    my $origFileName = $bFileName;
    my $fullKey = "$origFileName:$foldCase";
    return $filenameToURI{$fullKey} if $filenameToURI{$fullKey};
    # dblog("filenameToURI - 0 - [$bFileName]");
    my $start;
    $start = "filenameToURI($bFileName) => " if $ldebug;
    my $uri;
    my $canon_URI;
    my $leadingSlashes;
    if (IS_WIN32) {
	if ($bFileName =~ /^\w:[\\\/]/) {
	    # drive-letter -- colon -- path
	    $bFileName = final_check(canonpath($bFileName));
	    $bFileName = _encode_win_file_parts($bFileName, $foldCase);
	    $bFileName =~ s,\\,/,g;
	    $leadingSlashes = "///";
	} elsif ($bFileName =~ /^\\\\/) {
	    # It's a UNC path
	    # Remove extra "." and "x\\.." components
	    $bFileName = final_check(canonpath(substr($bFileName, 1)));
	    # dblog("filenameToURI - 1 - [$bFileName // $1]");
	    $bFileName = '\\' . _encode_unix_file_parts($bFileName);
	    # dblog("filenameToURI - 2 - [$bFileName]");
	    $bFileName =~ s,\\,/,g;
	    # dblog("filenameToURI - 3 - [$bFileName]");
	    $leadingSlashes = "";
	} else {
	    $bFileName = final_check(canonpath(wrap_rel2abs($bFileName)));
	    $bFileName = _encode_win_file_parts($bFileName, $foldCase);
	    $bFileName =~ s,\\,/,g;
	    $leadingSlashes = ($bFileName =~ /^\//) ? "//" : "///";
	}
    } else {
	# Unix pathnames go through the mount table,
	# so we never have a hostname here
	$bFileName = final_check(canonpath(wrap_rel2abs($bFileName)));
	$bFileName = _encode_unix_file_parts($bFileName);
	$leadingSlashes = "//";
    }
    $canon_URI = "file:$leadingSlashes$bFileName";
    # dblog("$start$canon_URI") if $ldebug;
    $filenameToURI{$fullKey} = $canon_URI;
    return $canon_URI;
}

# Because canonpath doesn't fold inner "/x/../" sequences
sub final_check {
    my ($fname) = @_;
    return $fname unless $fname =~ m@/\.\./@;
    my $i = 0;
    my @pieces = split(/\//, $fname, -1); #Keep trailing empty fields
    while ($i <= $#pieces) {
	if ($pieces[$i] eq '..') {
	    if ($i == 0) {
		splice @pieces, 0, 1;
	    } else {
		splice @pieces, $i - 1, 2;
		$i--;
	    }
	} else {
	    $i++;
	}
    }
    return join("/", @pieces);
}

# This one always returns an absolute forward-slashed filename
# Even UNC paths appear as "//<host>/<path>

sub uriToFilename {
    my ($bFileURI) = @_;
    my $origURI = $bFileURI;
    return $mem_uriToFilename{$origURI} if $mem_uriToFilename{$origURI};
    # Assume all file:// URIs are local
    
    my $filename;
    # Assume a dbgp URI denotes either a path starting with a
    # drive letter, a Unix-type path, or a UNC path
    
    if ($bFileURI =~ m@^file://(.*)$@) {
	my $path = $1;
	my $path2;
	if ($path =~ m@^/(\w:/.*)$@) {
	    $path2 = $1;
	} elsif (IS_WIN32 && $path =~ m@^[^/]+/@) {
	    # It's a UNC path, so we need to put a slash back
	    $path2 = "/$path";
	} else {
	    $path2 = $path;
	}
	my $file_part = _uri_decode($path2);
	$filename = $file_part;
    } else {
	die "uriToFilename: Can't process URI $bFileURI";
    }
    $mem_uriToFilename{$origURI} = $filename;
    return $filename;
}

sub _encode_win_file_parts {
    my ($full_win_name, $foldCase) = @_;
    # dblog("_encode_win_file_parts, \$full_win_name = $full_win_name");
    my ($volume, $directories, $path) = splitpath($full_win_name);
    # dblog("_encode_win_file_parts, \$directories = $directories");
    my @dir_parts = map { _uri_encode($_) } splitdir($directories);
    # dblog("_encode_win_file_parts: split into @dir_parts");
    my $new_name = catpath($volume,
			   catdir(@dir_parts),
			   _uri_encode($path));
    $new_name = lc $new_name if $foldCase;
    # dblog("_encode_win_file_parts: map [$full_win_name] => [$new_name]");
    return $new_name;
}

# Like Windows, but this kind of filename has no initial volume

sub _encode_unix_file_parts {
    my ($full_name) = @_;
    my @dir_parts = map { _uri_encode($_) } splitdir($full_name);
    my $new_name = catdir(@dir_parts);
    # dblog("_encode_unix_file_parts: map [$full_name] => [$new_name]");
    return $new_name;
}


sub _uri_decode {
  my $todecode = shift;
  $todecode =~ s/%([0-9a-fA-F]{2})/chr(hex($1))/ge;
  return $todecode;
}

sub _uri_encode {
  my $toencode = shift;
  # force bytes while preserving backward compatibility -- dankogai
  $toencode = pack("C*", unpack("C*", $toencode));
  $toencode=~s/([^a-zA-Z0-9_.-])/sprintf('%%%02x', ord($1))/eg;
  return $toencode;
}

unless (caller()) {
    require Cwd;
    my $cwd = Cwd::getcwd();
    $cwd = lc $cwd if IS_WIN32;
    $cwd =~ s,\\,/,g;
    $cwd =~ s,/[^/]+$,,;
    $cwd =~ s@^/@@; 
    my @fnames = (['\\\\host\\a\\b\\c\\d\\e.ext1',
		   'file://host/a/b/c/d/e.ext1'],
		  ["c:/a/z.ext2",
		   'file:///c:/a/z.ext2'],
		  ["..\\a\\b\\z.ext3",
		   "file:///$cwd/a/b/z.ext3"],
		  [
		  "/a/b",
		   "file:///a/b"
		   ],
		  [
		   "\\a\\b\\z.ext5",
		   "file:///a/b/z.ext5"
		   ],
		  [
		   "/skippy/the/bush/../happy/kangaroo.pl",
		   "file:///skippy/the/happy/kangaroo.pl"
		   ],
		  );
    print IS_WIN32 ? "is win32\n" : "isn't win32\n";
    foreach my $obj (@fnames) {
	my $fname = $obj->[0];
	print "Testing $fname...";
	if (!IS_WIN32) {
	    if ($fname =~ m/^\\\\/) {
		print "Skipping UNC path $fname\n";
		next;
	    } elsif ($fname =~ /^\w:/) {
	      print "Skipping DOS file $fname\n";
	      next;
	    }
	    $fname =~ s@\\@/@g;
	} else {
	}
	my $uri = filenameToURI($fname, 1);
	if ($uri ne $obj->[1]) {
	    print "\n  filenameToURI($fname) => [$uri], expecting [$obj->[1]]\n";
	} else {
	    print " ok\n";
	}
    }
}

1;
