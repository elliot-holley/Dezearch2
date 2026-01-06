#!/usr/bin/perl -w -T
# ic_cookies - sample CGI script that uses a cookie
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);

use strict;

BEGIN {
    use CGI::Carp qw(carpout);
    open(LOG, ">>/home/polarbear/web/susannah/cgi-bin/activity_log")
        or die "Unable to append to mycgi-log: $!\n";
    carpout(*LOG);
}

my $remote_host = $ENV{'HTTP_HOST'};
my $remote_addr = $ENV{'REMOTE_ADDR'};
#my $ran_id = join("remote_host", $remote_host);

my $ran_id = "ran from `" . $remote_host . "' ` " . $remote_addr . "'";
#warn "OK";
warn $ran_id;
#die "Bad error here";

my $cookname = "Favourite ice cream";
my $favorite = param("flavor");   # from the form
my $tasty    = cookie($cookname) || 'default';

unless ($favorite) {
    print header(), start_html("Ice Cookies"), h1("Hello Ice Cream"),
          hr(), start_form(),
            p("Please select a flavor:", textfield("flavor",$tasty)),
              end_form(), hr(), end_html();
    exit;
}

my $cookie = cookie(
                -NAME    => $cookname,
                -VALUE   => $favorite,
                -EXPIRES => "+2y",
            );

print header(-COOKIE => $cookie),
      start_html("Ice Cookies, #2"),
      h1("Hello Ice Cream"),
      p("You chose as your favorite flavor `$favorite'."), end_html();
