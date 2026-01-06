#!/usr/bin/perl -w
use CGI qw(:standard);
use strict;

#BEGIN {
#    use CGI::Carp qw(carpout);
    #unlink("/home/polarbear/web/dezearch/.ds/activity_log");
    #open(LOG, ">>/home/polarbear/web/dezearch/.ds/activity_log")
#    open(LOG, ">>../.ds/activity_log")
#        or die "Unable to append to log: $!\n";
#    carpout(*LOG);
#}


print "Content-type:text/html\n\n";
print <<EndOfHTML;
<html><head><title>Print Environment</title></head>
<body>
EndOfHTML

    my $key;
foreach $key (sort(keys %ENV)) {
    print "$key = $ENV{$key}<br>\n";
}

print "</body></html>";
