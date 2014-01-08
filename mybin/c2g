#!/usr/bin/perl

if(! -x "/usr/bin/cflow"){print "\'cflow\' not installed.\n"; exit;}
$in=join " ",@ARGV;
my @color=qw(#eecc80 #ccee80 #80ccee #eecc80 #80eecc);
my @shape=qw(box ellipse octagon hexagon diamond);
my $pref="/tmp/cflow";
my $ext="svg";

foreach (`/usr/bin/cflow -l $in`){
	chomp;
	s/\(.*$//; s/^\{\s*//; s/\}\s*/\t/;
	my($n,$f)=split /\t/,$_;
	$index[$n]=$f;
	if($n){
	$_="$index[$n-1]->$f";
	push @output,"node [color=\"$color[$n-1]\" shape=$shape[$n]];edge [color=\"$color[$n-1]\"];\n$_\n" if(! $count{$_}++);
	}
	else{push @output,"$f [shape=box];\n";}
}
#print @output; exit;
unshift @output,"digraph G {\nnode [peripheries=2 style=\"filled,rounded\" fontname=\"Vera Sans YuanTi Mono\" color=\"$color[0]\"];\nrankdir=LR;\nlabel=\"$in\"\n";
push @output,"}\n";
open FILE,'>',"$pref.dot"; print FILE @output;close FILE;
print "dot output to $pref.dot.\n";
open (STDERR, ">/dev/null");
if(-x "/usr/bin/dot"){
`dot -T$ext "$pref.dot" -o $pref.$ext`;
print "$ext output to $pref.$ext.\n";
if(-x "/usr/bin/eog"){`eog $pref.$ext`;}
}
else{print "\'dot(graphviz)\' not installed.\n"}
close STDERR;
