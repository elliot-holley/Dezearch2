#!/usr/bin/perl -w -T
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);

use strict;

BEGIN {
    use CGI::Carp qw(carpout);
    open(LOG, ">>/home/polarbear/web/dezearch/cgi-bin/activity_log")
        or die "Unable to append to log: $!\n";
    carpout(*LOG);
}

my $cookie_path = "/home/polarbear/web/dezearch/";
my $webmaster = "holley\@iee.org";
my @cookie_params = ("visits", "date");  

&main;

sub main 
{
    my $remote_host = $ENV{'HTTP_HOST'};
    my $remote_addr = $ENV{'REMOTE_ADDR'};
    my $ran_id = "ran from `" . $remote_host . "' ` " . $remote_addr . "'";
    warn $ran_id;

    my $cookname = "Dezearch";
    my $client_id = "";
    my $cookie_id = cookie($cookname);
    my $oname;

    if($cookie_id) {
	$oname  = substr($cookie_id,0,20);  # limit cookie value to 20 chars
	if ($oname =~ /^([-\@\w.]+)$/) {    # only words, alpha & underscores 
	    $cookie_id = $1;                # untaint data
	} else {
	    die "Bad data in '$oname'";     
	}
	print header(),
	start_html("Cookie already set"),
	h1("Old client $cookie_id $oname"),
	hr(),
	end_html();
    } else {
	$cookie_id = new_cookie_name();
	my $cookie = cookie(
	    -NAME    => $cookname,
	    -VALUE   => $cookie_id,
	    -EXPIRES => "+2y",
	    );

	print header(-COOKIE => $cookie),
	start_html("Cookie not set"),
	h1("Hello new client"),
	p("The cookie has been set"),
	end_html();
    }
    visit_counter($cookie_id);
    exit(0);
}



sub new_cookie_name
{
    my $rvalue = int(rand(1000000) + 1000000);
    return("id_$rvalue" . time);
}

sub visit_counter
{
    my ($count_file_name) = @_;
    #$count_file_name = "test";
    my $number = 0;
    my $fname = $cookie_path . $count_file_name;
    if(-e $fname) {
	open(VFILE, "<" . $cookie_path . $count_file_name) or 
	    die "Cannot open file $fname";
	    if(defined($number = <VFILE>)) {
		$number++;
	    }
	close VFILE;
    }
    else { 
	$number = 1; 
    }
    open(VFILE, ">" . $fname) or 
	die "Cannot open file $fname";
    print VFILE $number;
    close VFILE;
    return $number;
}


