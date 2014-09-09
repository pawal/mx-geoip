#!/usr/bin/perl

use warnings;
use strict;

use Data::Dumper;

use Pod::Usage;
use Getopt::Long;
use Net::DNS;
use Geo::IP;

# global program parameters
my $DEBUG  = 0; # set to true if you want some debug output
my $filename;
my $country = 'SE'; # default home country, ISO 3166-1

# global resolver
my $res = Net::DNS::Resolver->new;
$res->nameservers('127.0.0.1');
$res->recurse(1);
$res->cdflag(0);
$res->udppacketsize(4096);
$res->tcp_timeout(10);
$res->udp_timeout(10);

# geoip configuration
my $gi = Geo::IP->open("./GeoLiteCity.dat", GEOIP_MEMORY_CACHE);
die "No GeoLiteCity.dat file available, get from http://dev.maxmind.com/geoip/legacy/geolite/" unless defined $gi;

# fetch all data we need for a domain name, returns with an array
sub readA
{
    my $name = shift;
    my @a;

    print "Quering A for $name\n" if $DEBUG;
    my $answer = $res->send($name,'A');
    return if not defined $answer;
    foreach my $data ($answer->answer)
    {
	if ($data->type eq 'A') {
	    push @a, $data->address;
	}
    }

    return @a;
}

# fetch all data we need for a domain name, returns with an array
sub readMX
{
    my $name = shift;
    my @mx;

    print "Quering MX for $name\n" if $DEBUG;
    my $answer = $res->send($name,'MX');
    return if not defined $answer;
    foreach my $data ($answer->answer)
    {
	if ($data->type eq 'MX') {
	    push @mx, $data->exchange;
	}
    }

    return @mx;
}

sub readGeoIP {
    my $ip = shift;

    print "Querying geo for $ip\n" if $DEBUG;
    my $record = $gi->record_by_addr($ip);
    return $record->country_code;
}

sub runQueue
{
    open FILE, "$filename" or die "Cannot read file $filename: $!";
    my $homecount = 0;
    my $allhomecount = 0;
    my $foreigncount = 0;
    my $totalcount = 0;
    my $missingmx = 0;
    while ( <FILE> ) {
	chomp;
	my $name = $_;
	my (@ip, @mx, @cc);

	# Lookup all data
	@mx = readMX($_);                     # Lookup MX from name
	push @ip, map { readA($_); } @mx;     # Lookup IP from MX
	push @cc, map { readGeoIP($_); } @ip; # Lookup GeoIP from IP

	# Output all collected data
	print "$name:";
	map { print " $_"; } @cc, @mx, @ip;
	print "\n";

	# Counters
	$totalcount++;
	if ($country ~~ @cc)
	{
	    $homecount++;
	} else
	{
	    $foreigncount++;
	}
	$missingmx++ if $#mx == -1; # if no MX at all
	# all home counter
	my $hc = 0; my $fc = 0;
	foreach (@cc)
	{
	    if ($_ eq $country)
	    {
		$hc++; # home
	    } else
	    {
		$fc++; #foreign
	    }
	}
	if ($hc > 1 and $fc == 0)
	{
	    $allhomecount++;
	}
    }
    print "Total with only MX in $country: $allhomecount\n";
    print "Total with some MX in $country: $homecount\n";
    print "Total with MX outside of $country: $foreigncount\n";
    print "Total missing MX: $missingmx\n";
    print "All names: $totalcount\n";
    close FILE;

    return;
}

sub main() {
    # non-global program parameters
    my $help = 0;
    my $name;
    GetOptions('help|?'      => \$help,
	       'name|n=s'    => \$name,
	       'file|f=s'    => \$filename,
	       'country|c=s' => \$country,
	       'debug'       => \$DEBUG,
	      )
    or pod2usage(2);
    pod2usage(1) if($help);
    pod2usage(1) if(not defined $name and not defined $filename);

    if (defined $name) {
	my (@ip, @mx, @cc);
	@mx = readMX($name);
	push @ip, map { readA($_); } @mx;     # Lookup IP from MX
	push @cc, map { readGeoIP($_); } @ip; # Lookup GeoIP from IP

	# Output all collected data
	print "$name:";
	map { print " $_"; } @cc, @mx, @ip;
	print "\n";
    } elsif (defined $filename) {
	runQueue($filename);
    }
}

main;

=head1 NAME

collect

=head1 SYNOPSIS

   collect.pl -n domain

    -n domain       specify name
    -f file.txt     read list of names from file
    -h country      specify "home" country (default SE) in ISO 3166-1
    --debug         debug mode

=head1 DESCRIPTION

   gets countries, hostnames and IP addresses of the MX of all input domain names

=head1 AUTHOR

   Patrik Wallstrom <pawal@iis.se>

=cut
