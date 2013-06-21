#!/usr/bin/perl

# Perl script to test web application access controls
# Usage - ./accessgrinder.pl -f <file containing urls> -c 'SESSION=session1'  \
# 	[-c 'SESSION=session2'] [--nocolour] [-v] [--string 'regex to match'] \
#	[--insecure] [-d 'delimiter'] [-u 'useragent']

# geoff.jones@cyberis.co.uk - Geoff Jones 17/05/2012 - v0.1

# Perl script to test access controls of web applications. Given an 
# arbitrary number of session cookies, this script will access a number
# of URL's and report response code, length, any redirects and whether 
# a given string is contained within the response (e.g. 'Unauthorized'). 
# Coloured output gives a quick indication of inadequate access 
# control issues across the application.

# Copyright (C) 2012  Cyberis Limited

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Term::ANSIColor;
use Getopt::Long;
use LWP::UserAgent;
require LWP::Protocol::https;

my @urls;
my $urlfile;
my @cookies;
my $nocolour = '';
my $verbose = '';
my $failstring;
my $useragent = 'Mozilla/5.0';
my $insecure = '';
my $ua;
my $delim = ' ';

my $result = GetOptions("file=s"   => \$urlfile,    
                        "cookie=s"   => \@cookies,     
                        "nocolour"   => \$nocolour,    
                        "verbose+"  => \$verbose,
			"string=s" => \$failstring,
			"useragent=s" => \$useragent,
			"insecure" => \$insecure,
			"delim=s" => \$delim ); 

if ($insecure) {
	$ua = LWP::UserAgent->new(agent => $useragent, ssl_opts => { verify_hostname => 0 });
}
else {
 	$ua = LWP::UserAgent->new(agent => $useragent, ssl_opts => { verify_hostname => 1 });
}

if (! defined($urlfile)) {
	print usage();
}


# Load the URL's into memory
open(F,$urlfile) or die "Failed to open file containing URL's - $!\n";
while (<F>){
        if (m/^http[s]?:\/\//) {
		chomp;
                push (@urls, $_);
        }
}
close(F);

print STDERR "[INFO] Read ". @urls ." urls from file \"$urlfile\" \n";

if (defined($failstring)) {
	$failstring = qr/$failstring/;
}
else {
	print STDERR "[WARN] No string match set. Be aware that some applications will return 200 OK upon failed access requests.\n";
}

print STDERR "[INFO] Request 1 - No cookie\n";

for (my $i=0; $i<@cookies; $i++) {
	my $count = $i + 2;
	print STDERR "[INFO] Request $count - cookie: " .$cookies[$i]."\n";
}

print STDERR "[RESULTS] (key: C=Code, L=Length, R=Redirect M=Match NM=No_Match):\n\n";

foreach (@urls) {
	
	#Get the URL with no cookies first
	my $url = $_;
	my $request = HTTP::Request->new(GET => $url);
	my $response = $ua->simple_request($request);

	my @responses = ( {
        	cookie => '',
        	response => $response }
    	);

	# Perform the request for each cookie
	foreach (@cookies) {
		$request = HTTP::Request->new(GET => $url,HTTP::Headers->new('Cookie' => $_));
		$response = $ua->simple_request($request);

		push (@responses, {
	        	cookie => '$_',
	       		response => $response }
		);
	}

	print $url;
	for (my $i=0; $i<@responses; $i++) {
		my $r = $responses[$i]{response};
		my $match = 0;

		print $delim;
	
		if ($r->code eq 200 && ! $nocolour) { print color 'green'; }
		if (($r->code eq 301 || $r->code eq 302) && ! $nocolour) { print color 'blue'; }
		if ($r->code >= 400 && $r->code < 500 && ! $nocolour) { print color 'yellow'; }
		if ($r->code eq 500 && ! $nocolour) { print color 'red'; }
		
		if (defined($failstring)) {
			if ($r->content =~ /$failstring/ && ! $nocolour) { 
				print color 'magenta'; 
				$match = 1;
			}
		}

		if (defined($r->header('Location'))) {
			if ($match) {
				if ($verbose) {
					print "[C:" . $r->code . " L:" . length($r->content) . " R:" . $r->header('Location') . " M]";
				}
				else {
					print "[C:" . $r->code . " L:" . length($r->content) . " R M]";
				}
			} 
			else {
				if ($verbose) {
					print "[C:" . $r->code . " L:" . length($r->content) . " R:" . $r->header('Location') . " NM]";
				}
				else {
					print "[C:" . $r->code . " L:" . length($r->content) . " R NM]";
				}
			}
		}
		else {
			if ($match) {
				print "[C:" . $r->code . " L:" . length($r->content) . " M]";
			}
			else 
			{
				print "[C:" . $r->code . " L:" . length($r->content) . " NM]";
			}
		}
		print color 'reset';
	}
	print "\n";

}

sub usage {
	print STDERR "\n $0 -f <file containing urls> -c 'SESSION=session1' \\\n\t[-c 'SESSION=session2'] [--nocolour] [-v] [--string 'regex to match'] \\\n\t[--insecure] [-d 'DELIM'] [-u 'useragent']\n\n";
	print STDERR " Perl script to test access controls of web applications. Given an arbitrary\n number of session cookies, this script will access a number of URL's and\n report response code, length, any redirects, and whether a given string is\n contained within the response (e.g. 'Unauthorized'). Coloured output gives\n a quick indication of inadequate access control issues across the application.\n\n";
	print STDERR "\te.g. $0 -f urls.txt -c 'JSESSIONID=89EB1671D756C3CEA933F0491AEC199A' --string '(Unauthori[sz]ed Access|Please login)'\n\n";
	exit;
}
