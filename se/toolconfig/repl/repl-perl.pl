#! /usr/bin/perl
use IO::Handle;
$|=1;  # Flush printed output
my($v)="";
for (;;) {
    print("perl> ");
    $v=readline();
    my $result=eval($v);
    my $status=$@;
    if ($status ne "") {
        print " $status\n";
    } else {
        print " $result\n";
    }
}
