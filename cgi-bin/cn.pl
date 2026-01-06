#!/usr/bin/perl -w 
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
use strict;

&main;

sub main
{
    die("it ran\n");
    print start_html("Scritp running..."), end_html();
    exit(0);
}


