AccessGrinder
=============

Author: geoff.jones@cyberis.co.uk
Copyright Cyberis Limited 2013

A Perl script to test access controls on large web applications.

Testing access controls on web applications can be a difficult task if presented with multiple user roles and a large number of pages. Depending on the application, unauthorised access to a page may result in a client error code (40X), a redirect (30X), a straight 200 with an error message within the page, or possibly even a server-side error (50X).

During a web application assessment, it is the tester's job to identify access control vulnerabilities, such as the ability for a non-authenticated user, or user with limited privileges, to gain access to a restricted page. Accessgrinder.pl attempts to simplify this task, by performing multiple requests for a resource with different session cookies (and with no session cookie whatsoever), comparing the size of each response and reporting what response was issued by the server. As a quick check, accessgrinder.pl colours output in a terminal, allowing a tester to quickly identify varying responses, and arguably more importantly, cases where access to a resource is open to all. Optionally the output can be generated in CSV, allowing further analysis/formatting in a spreadsheet application.

Usage has been intentionally kept quite simple. Before running the tool, it is important to compile a list of all URLs to be tested. This can be done by spidering using the tool of your choice - personally I simply export from Burp proxy after profiling the site as the most privileged user role available.

At this point, record active session cookies from each account privilege level you wish to test. The script can take as many cookies as you like, allowing you to test basic applications with one or two user roles, or even complex sites with a large number of privilege levels. Specify each on the command line with the '-c' (--cookie) flag.

Finally, remove any logout URL's from your input file (or at least place it at the end), to ensure the test isn't compromised by sessions being destroyed during a run.

The full usage of the script is shown below:

./accessgrinder.pl -f <file containing urls> -c 'SESSION=session1' [-c 'SESSION=session2'] [--nocolour] [-v] [--string 'regex to match'] [--insecure] [-d 'delimiter'] [-u 'useragent']

If the application returns 'unauthorised' messages in 200 responses, be sure to set '--string' to detect these instances.

./accessgrinder.pl -f urls.txt -c 'JSESSIONID=89EB1671D756C3CEA933F0491AEC199A' --string '(Unauthori[sz]ed Access|Please login)'

This script will only test basic access to a given resource, not more complex access control issues such as varying page functionality per user role (though the returned size from accessgrinder.pl may be an indication) or POST based form submissions, though it's a great quick check to profile a large application. Once you've identified that a user can access a given URL, that's when the more interesting manual testing can begin.

If you want to install the CPAN dependencies yourself, you'll need Term::ANSIColor, Getopt::Long, LWP::UserAgent and LWP::Protocol::https.
