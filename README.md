MX-GeoIP
========

This is a simple tool to examine the geographic location of a domain,
or a batch of domains.

Usage:  

    mx-geoip.pl -n domain

      -n domain       specify name
      -f file.txt     read list of names from file
      -h country      specify "home" country (default SE) in ISO 3166-1
      --debug         debug mode

Example use:  

      $~/mx-geoip>./mx-geoip.pl -n iis.se
      iis.se: SE SE mx2.iis.se mx1.iis.se 212.247.8.148 91.226.36.39

The first item listed is the domain name tested, the following are the
ISO 3166-1 names of the IP addresses, the MX records from the domain and
then the resolved IP addresses from the MX records.

MX-GeoIP uses the GeoLite City database from
http://dev.maxmind.com/geoip/legacy/geolite/
