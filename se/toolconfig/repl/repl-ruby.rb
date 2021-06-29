#!/usr/bin/ruby
$stdout.sync = true;

$v="";
while true 
    print("ruby> ");
    v=readline();
    if v=="exit\n" then
        exit
    end
    begin
        puts eval(v);
    rescue Exception => exc
        puts exc
        #print "rescued\n";
    end
end

#while (<>) {
#  chomp;
#  my $result = eval;
#  print "$_ = $result\n";
#}
