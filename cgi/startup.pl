# startup file for preloading modules into Apache/mod_perl when the server starts
# (instead of when each httpd child starts)
# see http://apache.perl.org/docs/1.0/guide/performance.html#Code_Profiling_Techniques
#
use strict;

use Carp ();

eval { Carp::confess("init") };

# used for debugging hanging httpd processes
# http://perl.apache.org/docs/1.0/guide/debug.html#Detecting_hanging_processes
$SIG{'USR2'} = sub { 
   Carp::confess("caught SIGUSR2!");
};

use CGI ();
CGI->compile(':all');

use Storable ();
use LWP::Simple ();
use LWP::UserAgent ();
use Image::Magick ();
use File::Copy ();
use XML::Encoding ();
use Encode ();
use Text::Unaccent ();
use Cache::Memcached::Fast ();
use URI::Escape::XS ();

# Needs to be configured
use lib "/home/stephane/product-opener/cgi";

use Blogs::Store qw/:all/;
use Blogs::Config qw/:all/;
use Blogs::Display qw/:all/;
use Blogs::Products qw/:all/;
use Blogs::Food qw/:all/;
use Blogs::Images qw/:all/;
use Blogs::Index qw/:all/;
use Blogs::Version qw/:all/;

use Apache2::Const -compile => qw(OK);
use Apache2::Connection ();
use Apache2::RequestRec ();
use APR::Table ();


$Apache::Registry::NameWithVirtualHost = 0; 

sub My::ProxyRemoteAddr ($) {
  my $r = shift;

  # we'll only look at the X-Forwarded-For header if the requests
  # comes from our proxy at localhost
  
  return Apache2::Const::OK
      unless (
	($r->connection->remote_ip eq "213.251.136.98") 
	or 1 # do it for all ips
)
          and $r->headers_in->get('X-Forwarded-For');

  # Select last value in the chain -- original client's ip
  if (my ($ip) = $r->headers_in->get('X-Forwarded-For') =~ /([^,\s]+)$/) {
    $r->connection->remote_ip($ip);
  }

  return Apache2::Const::OK;
}

# needed?
#use Apache::RegistryLoader ( );
#Apache::RegistryLoader->new->handler("/cgi-bin/display_index.pl",
#                          "/home/cgi-bin/display_index.pl");

print STDERR "version: $Blogs::Version::version\n";

1;
