#!/usr/bin/perl -w 
use strict;

# localhost version

#my $web_address = "192.168.1.5";
my $web_address = "www.robotsandspares.com";
my $mailp= "/usr/sbin/sendmail";
my $request_method = $ENV{'REQUEST_METHOD'};
my $webmaster = "julian\@holley.uklinux.net";
#my $webmaster = "polarbear\@ieee.org";
my $result_email = $webmaster;
my $exclusive_lock = 2;
my $unlock = 8;
my $big_image = "";
#my $path_to_root = "/home/polarbear/web/";
#my $path_from_root = "robot_graphics/";
my $path_to_root = "..";
my $path_from_root = "/";
my $product_path = $path_to_root . $path_from_root;
#my $cookie_path = $product_path . "cgi-bin/ck/";
my $cookie_path = "ck/";
#my $store_path = $product_path . "cgi-bin/done/";    # path to store emailed cookies 
my $store_path = "done/";
my $email_prefix = "web_info";           # filename prefix to sent email
my $file_path = $product_path;           # page to web pages
my $goods_path;                          # path to product directory
my $visit_name = "visit_count";          # file name of counter
my $sub_name = "sub_count";              # file name of counter
my $tfile = "row_template.html";         # used for product page
my $bfile = "brow_template.html";        # used for basket page
my $dfile = "details_template.html";     # used for verify page
my $ffile = "form_template.html";        # used for to fill form with current details
my $qfile = "quant_template.html";       # used for calculated quatities page
my $pfile = "paypal_template.html";      # used for generating paypal template
my $efpage = "submit_form_error.html";  # error form template
my $effile = "form_template_error.html"; # error form template
my @int_params = ("price", "weight", "pp", "cost");  
my @user_params = ("name", "address", "tel", "fax", "email", "notes");
my @required_params = ("name", "address", "email");

&main;

sub main 
{
    my ($cookie, %path_info, %page_info);
    &parse_form_data(\%page_info);
    if($request_method eq "GET") {
	my $form_file = $ENV{'PATH_INFO'};
	#my $last_page = $ENV{'HTTP_REFERER'};
	#print "Content-type: text/html", "\n\n";
  	#print "last page is $last_page";
	$cookie = $page_info{"id"};
	if($page_info{"cmd"} eq "add") {
	    &write_to_file($cookie, "path", $page_info{"product"});
	    &append_internal_data($cookie, \%page_info);
	}
	elsif($page_info{"cmd"} eq "del") {
	    &store_details($cookie, $page_info{"product"}, \%page_info);
	    if(! &append_internal_data($cookie, \%page_info)) {
		&empty_basket($cookie);
	    }
	}
	elsif($page_info{"cmd"} eq "Done") {
	    &store_details($cookie, "none",\%page_info);
	    #print "Content-type: text/html", "\n\n";
	    if(&details_present($cookie)) {
		&write_to_file($cookie, "date", &get_date_time);
	    }
	    else { $form_file = $efpage }
	}
	elsif($page_info{"cmd"} eq "empty") {
	    &empty_basket($cookie);
	}
	elsif($page_info{"cmd"} eq "big") {
	    $big_image = $page_info{"product"};
	    $big_image =~ s/\.jpg/_big\.jpg/;
	}
	if($form_file) {
	    if($page_info{"id"} eq "none") {
		$cookie = join ("_", $ENV{'REMOTE_HOST'}, time);
		$cookie = &escape($cookie);
		&visit_counter($visit_name);
	    }
	    else{ 
		$cookie = $page_info{"id"}; 
	    }
	    if($page_info{"cmd"} eq "cd") {
		$goods_path = $page_info{"product"};
	    }
	    if($page_info{"cmd"} eq "end") {
		&visit_counter($sub_name);
		&pseudo_ssi_email($form_file, $cookie, "/end.html");		
		&email_result($cookie);
		&clean_up($cookie);
	    }
	    if($page_info{"cmd"} eq "pay") {
		&visit_counter($sub_name);
		&pseudo_ssi_email($form_file, $cookie, 
		     "/cgi-bin/process.pl/pay_pal.html?id=$cookie&amp;cmd=none&amp;product=none");
		&email_result($cookie);
	    }
	    else {		
		&pseudo_ssi($form_file, $cookie);
	    }
	} else {
	    if($page_info{"cmd"} eq "add") {
		$cookie = $page_info{"id"};
		&write_to_file($cookie, "path", $page_info{"product"});
	    } else {
		&return_error(500, "CGI Network Error 1");
	    }
	}
	exit(0);
    }
    &return_error(500, "CGI Network Error 2");
}

sub visit_counter
{
    my ($count_file_name) = @_;    # name of the file containing the count
    my $number = 0;
    if(-e $cookie_path . $count_file_name) {
	open(VFILE, "<" . $cookie_path . $count_file_name) or &return_error 
	    (500, "CGI Network Error 3", "Cannot open file");
	    if(defined($number = <VFILE>)) {
		$number++;
	    }
	close VFILE;
    }
    else { 
	$number = 1; 
    }
    open(VFILE, ">" . $cookie_path . $count_file_name) or &return_error 
	(500, "CGI Network Error 4", "Cannot open file");
    print VFILE $number;
    close VFILE;
    return $number;
}


sub get_counter
{
    my ($count_file_name) = @_;    # name of the file containing the count
    my $number = 0;
    if(-e $cookie_path . $count_file_name) {
	open(VFILE, "<" . $cookie_path . $count_file_name) or &return_error 
	    (500, "CGI Network Error 5", "Cannot open file");
	    if(! defined($number = <VFILE>)) {
		$number = "unknown";
	    }
	close VFILE;
    }
    return $number;
}
		
sub pseudo_ssi_email
{
    my ($form_file, $cname, $to_page) = @_;
    print "location: http://" . $web_address . $to_page, "\n\n";
    open(EMAIL_OUT, ">". $cookie_path . $email_prefix . $cname . ".html") or &return_error 
	(500, "CGI Network Error 6", "Cannot open file");
    select EMAIL_OUT;
    &pseudo_ssi($form_file, $cname);
    select STDOUT;
    close EMAIL_OUT;
}

sub email_result
{
    my ($cname) = @_;
    open(MAIL, "|$mailp $result_email") or &return_error 
	(500, "CGI Network Error 7", "Couldn't send the mail (couldn't run $mailp).");
    open(EFILE, "<" . $cookie_path . $email_prefix . $cname . ".html")  or &return_error 
	(500, "CGI Network Error 8", "Cannot open file.");
    while (<EFILE>) {
        print MAIL $_;
    }
    close(MAIL);
    close(EFILE);
}

sub clean_up
{
    my ($cname) = @_;
    if(-e $cookie_path . $cname) {
	my $textf_in = $cookie_path . $cname;
	my $webf_in = $cookie_path . $email_prefix . $cname . ".html";
	my $textf_out = $store_path . "customer" . $cname;
	my $webf_out = $store_path . $email_prefix . $cname . ".html";
	link $textf_in, $textf_out;
	link $webf_in, $webf_out;
	unlink $textf_in;
	unlink $webf_in;
    }
}

sub empty_basket
{
    my ($cname) = @_;   # cookie id
    if(-e $cookie_path . $cname) {
	my %details = &get_details($cookie_path . $cname);
	unlink($cname);
	open(FILE, ">" . $cookie_path . $cname) or &return_error 
	    (500, "CGI Network Error 9", "Cannot open file");
	while((my $key, my $value) = each %details ) {
	    foreach my $ptest (@user_params) {
		if($key eq $ptest) { 
		    print FILE "\n$key = $value";
		}
	    }
	}
	close(FILE);
    }
}


sub append_internal_data
{
    my ($cname, $page_info_ref) = @_;
    my $mods = 0;
    if(-e $cookie_path . $cname) {
	foreach my $ip (@int_params) {
	    my $c;
	    if($ip eq "price") { 
		$c = &total_price($cname);
	    }elsif($ip eq "weight") { 
		$c = &total_weight($cname);
	    }elsif($ip eq "pp") { 
		$c = &total_pp($cname);
	    }elsif($ip eq "cost") { 
		$c = &total_cost($cname);
	    }
	    if($c > 0) { 
		$$page_info_ref{$ip} = $c; 
		&store_details($cname, $ip, $page_info_ref);
		$mods++;
	    }
	}
    }
    return $mods;
}


sub store_details
{
    my ($cname, $product_type, $page_info_ref) = @_;   #cookie id and wpage 'product' and page info
    my (%details, @pfiles); 
    my @params = (@int_params, @user_params);
    if(-e $cookie_path . $cname) {
	%details = &get_details($cookie_path . $cname);
	@pfiles = bfile_list($cname);
	unlink($cname);
    }
    open (FILE, ">" . $cookie_path . $cname) or &return_error 
	(500, "CGI Network Error 10", "Cannot open file.");

    foreach my $iparams (@params) {
      if($$page_info_ref{$iparams}) {
	if(($iparams eq "address") || ($iparams eq "notes")) {
	    $$page_info_ref{$iparams} =~ s/\s/_/g;
	    $$page_info_ref{$iparams} =~ s/_/ /g;
	}
  	print FILE "\n$iparams = " . $$page_info_ref{$iparams};
    }
    elsif($details{$iparams}) {
  	print FILE "\n$iparams = " . $details{$iparams};
    }
  }
    foreach my $efile (@pfiles) {
	if($efile ne $product_type) { 
	    print FILE "\npath = " . $efile; 
	}
	else { $product_type = "none"; }
    }
    print FILE "\n";
    close(FILE);
}


sub details_present
{
    my ($cname) = @_;   # cookie id
    my $status = 0;
    my $par_count = 0;
    if(-e $cookie_path . $cname) {
	my %details = &get_details($cookie_path . $cname);
	open(FILE, "<" . $cookie_path . $cname) or &return_error 
	    (500, "CGI Network Error 9", "Cannot open file");
	foreach my $ptest (@required_params) {
	    $par_count++;
	    while((my $key, my $value) = each %details ) {
		if($key eq $ptest) { 
		    $status++;
		}
	    }
	}
	close(FILE);
    }
    return ($status == $par_count);
}


sub write_to_file
{ 
    my ($cname, $pname, $item) = @_;
    open (FILE, ">>" . $cookie_path . $cname) or 
	&return_error (500, "CGI Network Error 11", "Cannot write to file.");
    print FILE "\n$pname = " . $item;
    close (FILE);
}


sub parse_form_data
{
    my ($FORM_DATA_REF) = @_;	# web page parameters
    my ($query_string, @key_value_pairs, $key_value, $key, $value);	
    read (STDIN, $query_string, $ENV{'CONTENT_LENGTH'});
    if ($ENV{'QUERY_STRING'}) {
            $query_string = join("&", $query_string, $ENV{'QUERY_STRING'});
    }     
    @key_value_pairs = split (/&/, $query_string);
    foreach $key_value (@key_value_pairs) {
        ($key, $value) = split (/=/, $key_value);
	$key   =~ tr/+/ /; 
        $value =~ tr/+/ /;
        $key   =~ s/%([\dA-Fa-f][\dA-Fa-f])/pack ("C", hex ($1))/eg;
        $value =~ s/%([\dA-Fa-f][\dA-Fa-f])/pack ("C", hex ($1))/eg;
        if (defined($$FORM_DATA_REF{$key})) {
            $$FORM_DATA_REF{$key} = join ("\0", $$FORM_DATA_REF{$key}, $value);
        } else {
            $$FORM_DATA_REF{$key} = $value;
        }
    }
}


sub escape
{
    my ($cname) = @_;  # cookie id
    $cname =~ s/(\W)/sprintf("%%%x", ord($1))/eg;
    return($cname);
}


sub pseudo_ssi
{
    my ($file, $cname) = @_;     # web page path info and cookie id
    my ($command, $argument, $parameter, $line);
    open (FILE, "<" . $file_path . $file) or
	&return_error(500, "CGI Network Error 12", "Cannot open file.");
    flock (FILE, $exclusive_lock);
    print "Content-type: text/html\n";
    print "Expires: Thu, 29 Oct 1998 17:04:19 GMT","\n\n";
    while (<FILE>) {
	while ( ($command, $argument, $parameter) = 
		(/<!--\s*#\s*(\w+)\s+(\w+)\s*=\s*"?(\w+)"?\s*-->/io) ) {
	        if ($command eq "insert") {
		    if ($argument eq "var") {
	                if ($parameter eq "COOKIE") {
			    s//$cname/;
		        } elsif ($parameter eq "HEADER") {
			    my $h = &include_file("header.html");
		            s//$h/;
			} elsif ($parameter eq "FOOTER") {
			    my $h = &include_file("footer.html");
		            s//$h/;
			} elsif ($parameter eq "TABLE_LIST") {
			    my $t = &table_list($cname, $goods_path);
		            s//$t/;
			} elsif ($parameter eq "PRODUCT_RANGE") {
			    my $t = $goods_path;
		            s//$t/;
			} elsif ($parameter eq "BASKET_LIST") {
			    my @a = <>;
			    if(-e ($cookie_path . $cname)) {
				@a = &basket_list($cname);
			    }
		            s//@a/;
			} elsif ($parameter eq "FORM_LIST") {
			    my @a = <>;
				@a = &form_list($cname, $file);
		            s//@a/;
			} elsif ($parameter eq "QUANTITIES") {
			    my @a = <>;
			    if((-e ($cookie_path . $cname)) && (&product_quantity($cname) > 0) && 
			       !&check_poa($cname)) {
				@a = &quantities_list($cname);
			    }
			    s//@a/;
			} elsif ($parameter eq "PAYPAL") {
			    my @a = <>;
			    if((-e ($cookie_path . $cname)) && (&product_quantity($cname) > 0) &&
			       !&check_poa($cname)) {
				@a = &paypal_list($cname);
			    }
			    s//@a/;
			} elsif ($parameter eq "VISIT_COUNTER") {
			    my $c = &get_counter($visit_name);
			    s//$c/;
			} elsif ($parameter eq "PERSONAL") {
  			    my @a = &personal_list($cname);
  			    s//@a/;
  			} elsif ($parameter eq "SUBMISSION_COUNTER") {
			    my $c = &get_counter($sub_name);
			    s//$c/;
			} elsif ($parameter eq "LARGE_IMAGE") {
			    s//$big_image/;
			} elsif ($parameter eq "SOURCE") {
			    #s//$ENV{'HTTP_REFERER'}/;
			    my $c = &source_parse($ENV{'HTTP_REFERER'});
			    s//$c/;
			}
			else {
			    s///;
			}
		    } else {
			s///;
		    }
		} else {
		    s///;
		}
	     }
	    print;
	    }
	flock (FILE, $unlock);
	close (FILE);
}


sub source_parse
{
    my ($inp_strn) = @_;
    $inp_strn =~ s/cmd=add&/cmd=check&/g;
    $inp_strn =~ s/cmd=del&/cmd=check&/g;
    return $inp_strn;
}


# return numeric value of 'param' listed in all files listed in basket
sub get_accum 
{
    my ($cname, $param) = @_;   #cookie id and parameter to accumulate
    my @files = &glob_file($cname);
    my $tot = 0;
    my $item;
    my $nvalue = 1;
      foreach my $efile (@files) {
	my %details = &get_details($product_path . $efile);
	$item = $details{$param};
	if(($item eq "poa") || ($item eq "POA")) { $nvalue = 0; };
  	$tot += $details{$param};
      }
    if($nvalue) { return $tot; }
    else { return 0; }
}

sub total_price 
{
    my ($cname) = @_;  #cookie id
    return sprintf "%.2f", &get_accum($cname, "price");
}

sub total_weight
{
    my ($cname) = @_;  #cookie id
    return sprintf "%.2f", &get_accum($cname, "weight");
}

sub total_pp
{
    my ($cname) = @_;  #cookie id
    my $tp = &total_weight($cname);
    my $pp_cost = 0.0;
    my $pp_min = ($tp != 0) ? 1 : 0 ;
    my $tt = $pp_min + $tp * $pp_cost;
    $tt = 0;  # temp bodge
    return $tt;
}

sub total_cost
{
    my ($cname) = @_;  #cookie id
    my $tp = &total_price($cname);
    my $tw = &total_pp($cname);
    my $tt = $tp + $tw;
    return $tt;
}


sub basket_list 
{
    my ($cname) = @_;            #cookie id
    my @files = &bfile_list($cname);
    my $rt;
    foreach my $efile (@files) {
  	my ($fname) = $efile;
  	$fname =~ /(\w+)\/(\w+)/; 
  	$fname = "$1";

	my %details = &get_details($product_path . $efile);
	$details{"picture"} =  $fname . "/" .  $details{"picture"};
	$details{"path"} =  $efile;
	$rt .= &sub_ssi($bfile, \%details, $cname);
    }
    return $rt;
}

sub personal_list 
{
    my ($cname) = @_;     #cookie id
    my $rt;
    my %details = &get_details($cookie_path . $cname);
    $details{"notes"} =~ s/  /<br>/g;
    $details{"address"} =~ s/  /<br>/g;
    $rt .= &sub_ssi($dfile, \%details);
    return $rt;
}

sub form_list 
{
    my ($cname, $ifile) = @_;     #cookie id
    my $rt;
    my %details;
    if(-e ($cookie_path . $cname)) {
	%details = &get_details($cookie_path . $cname);
	if(defined($details{"notes"})) { $details{"notes"} =~ s/  /\n/g; }
	if(defined($details{"address"})) { $details{"address"} =~ s/  /\n/g; }
    }
    if($ifile eq $efpage) {
	$rt .= &sub_ssi($effile, \%details);
    }
    else {
	$rt .= &sub_ssi($ffile, \%details);
    }
    return $rt;
}

sub quantities_list 
{
    my ($cname) = @_;     #cookie id
    my $rt;
    my %details = &get_details($cookie_path . $cname);
    $rt .= &sub_ssi($qfile, \%details);
    return $rt;
}

sub paypal_list 
{
    my ($cname) = @_;     #cookie id
    my $rt;
    my %details = &get_details($cookie_path . $cname);
    $rt .= &sub_ssi($pfile, \%details, $cname);
    return $rt;
}

# returns an array of path&filenames of products in basket file
sub bfile_list
{
    my ($cname) = @_; # cookie id
    my @fflist = &glob_file($cname);
    return @fflist;
}

sub glob_file
{
    my ($cname) = @_;  # cookie id 
    my @flist;
    my $stemp = $_;
    open(GFILE, "<" . $cookie_path . $cname) or 
	&return_error (500, "CGI Network Error 13","Cannot open file.");
    while(defined(my $tp = <GFILE>)) {
	$_ = $tp;
	chomp; 
	s/#.*//;
	s/^\s+//;
	s/\s+$//;
	next unless length;
	my ($var, $value) = split(/\s*=\s*/,$_, 2);
	if($var eq "path") {
	    push(@flist, $value);
	}
    }
    close(GFILE);
    $_ = $stemp;
    return @flist;
}


sub include_file 
{
    my ($file) = @_;    # name of html page to be included
    my $rtn = "";
    open (HFILE, "<" . $file_path . $file) or
	&return_error(500, "CGI Network Error xx", "Cannot open file.");
    while(defined(my $fp = <HFILE>)) {
	$rtn .= $fp;
    }
    close HFILE;
    return $rtn;
}




sub table_list 
{
    my ($cname, $spath) = @_;    # cookie id and path to root of product tree directory
    $spath .= "/";
    my $dir = $path_to_root . $path_from_root . $spath;
    my @files = glob $dir . "*.des";
    my $rt;
    foreach my $efile (@files) {
	my ($fname) = $efile;
	$fname =~ /(\w+)\.(\w+)/; 
	$fname = "$1" . ".$2";
	my %details;
	%details = &get_details($efile);
	$details{"picture"} = $spath . $details{"picture"};
	$details{"path"} = $spath . $fname;
	$rt .= &sub_ssi($tfile, \%details, $cname);
    }
    return $rt;
}


# organise data in the description file into a hash table
sub get_details
{
    my ($pfile) = @_;    # full path and name of input file to process
    my %dt;
    my $stemp = $_;
    open(TFILE, "<" . $pfile) or 
	&return_error(500, "CGI Network Error 14", "could not open file.\n");
    while(defined(my $tp = <TFILE>)) {
	$_ = $tp;
	chomp; 
	s/#.*//;
	s/^\s+//;
	s/\s+$//;
	next unless length;
	my ($var, $value) = split(/\s*=\s*/,$_, 2);
	$dt{$var} = $value;
    }
    close(TFILE);
    $_ = $stemp;
    return %dt;
}

# returns current number of product in the basket
sub product_quantity
{
    my ($cname) = @_;  # cookie id 
    my $stemp = $_;
    my $ptot = 0;
    open(GFILE, "<" . $cookie_path . $cname) or 
	&return_error (500, "CGI Network Error 13","Cannot open file.");
    while(defined(my $tp = <GFILE>)) {
	$_ = $tp;
	chomp; 
	s/#.*//;
	s/^\s+//;
	s/\s+$//;
	next unless length;
	my ($var, $value) = split(/\s*=\s*/,$_, 2);
	if($var eq "path") {
	    $ptot++;
	}
    }
    close(GFILE);
    $_ = $stemp;
    return $ptot;
}


# returns true if any of the selected products are poa
sub check_poa 
{
    my ($cname, $param) = @_;   #cookie id and parameter to accumulate
    my @files = &glob_file($cname);
    foreach my $efile (@files) {
	my %details = &get_details($product_path . $efile);
	my $mt = $details{"price"};
	if($mt =~ /[A-Za-z_]/) { return 1; };
    }
    return 0;
}

# return true id 'cmd' exists with hash table pointed to by 'ht_ref'
sub cmd_exist
{
    my ($cmd, $ht_ref) = @_;    # command query and reference to hash table 
    my ($key, $value, $rtn);
    $rtn = 0;
    while(($key, $value) = each %$ht_ref) {
	if($cmd eq $key) { 
	    $rtn = 1;
	}
    }
    return $rtn;
}


# places 'command = insertions' pairs pointed to by ht_ref to web page snipet 
# 'template_file'  
sub sub_ssi
{
    my ($template_file, $ht_ref, $cname) = @_;    #template html page and reference to command list 
    my ($command, $argument, $parameter, $line, $key, $value, $rs);
    open (SFILE, "<" . $product_path . $template_file) or 
	&return_error (500, "CGI Network Error 15","Cannot open file.");
    flock (SFILE, $exclusive_lock);
    while (<SFILE>) {
	while ( ($command, $argument, $parameter) = 
		(/<!--\s*#\s*(\w+)\s+(\w+)\s*=\s*"?(\w+)"?\s*-->/io) ) {
		 if ($command eq "insert") {
		     if ($argument eq "var") {
			 if (&cmd_exist($parameter, $ht_ref)) {
			     s//$$ht_ref{$parameter}/;
			 } elsif ($parameter eq "COOKIE") {
			    s//$cname/;          
			 } else {
			     s///;
			 }
		     } elsif ($argument eq "col") {
			 my $ci = (&cmd_exist($parameter, $ht_ref)) ? 
			     "<span class=\"c2\">" : "<span class=\"c6\">";
			 s//$ci/;
		     }
		     else {   #var
			 s///;
		     }
		 } else {   #insert
		     s///;
		 }
	     } # while params
	     print;
    } # while file
    flock (SFILE, $unlock);
    close (SFILE);
}


sub get_date_time 
{
    my ($months, $weekdays, $ampm, $time_string);
    $months = "January/Febraury/March/April/May/June/July/August/September/October/November/December";
    $weekdays = "Sunday/Monday/Tuesday/Wednesday/Thursday/Friday/Saturday";
    my ($sec, $min, $hour, $day, $nmonth, $year, $wday, $yday, $isdst) = localtime(time);
    if ($hour > 12) {
        $hour -= 12;
        $ampm = "pm";
    } else {
        $ampm = "am";
    }
    if ($hour == 0) {
	       $hour = 12;
    }
    $year += 1900;
    my $week  = (split("/", $weekdays))[$wday];
    my $month = (split("/", $months))[$nmonth];
    my $time_string = sprintf("%s, %s %s, %s - %02d:%02d:%02d %s", 
                                $week, $month, $day, $year, 
                                $hour, $min, $sec, $ampm);
    return ($time_string);
}



sub return_error
{
    my ($status, $keyword, $message) = @_;
    print "Content-type: text/html", "\n";
    print "Status: ", $status, " ", $keyword, "\n\n";
    print <<End_of_Error;

<title>CGI Program - Unexpected Error</title>
<h1>$keyword</h1>
<hr>$message</hr>
Please contact $webmaster for more information.

End_of_Error

    exit(1);
}
