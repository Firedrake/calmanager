#! /usr/bin/perl

use strict;
use warnings;

package Calmanager::VCFBirthday;

use Text::vCard::Addressbook;
use Data::ICal::DateTime;
use Data::ICal::Entry::Event;

sub category {
  return 'Birthday';
}

sub generate {
  my $vcfpath="$ENV{HOME}/.vcf";
  opendir D,$vcfpath;
  my @vcffiles=map {"$vcfpath/$_"} grep /\.vcf$/,readdir D;
  closedir D;
  my $cal=Data::ICal->new;
  foreach my $vf (@vcffiles) {
    my $ab=Text::vCard::Addressbook->new({source_file => $vf});
    foreach my $vcard ($ab->vcards) {
      my $name=$vcard->fullname or next;
      if (my $b=$vcard->get({'node_type' => 'bday'})) {
        my ($y,$m,$d)=((localtime)[5]+1900,0,0);
        if ($b->[0]->{value} =~ /^--(\d\d)(\d\d)$/) {
          ($m,$d)=($1,$2);
        } elsif ($b->[0]->{value} =~ /^(\d\d)(\d\d)(\d\d)$/) {
          ($y,$m,$d)=(1900+$1,$2,$3);
        } elsif ($b->[0]->{value} =~ /^(\d\d\d\d)-?(\d\d)-?(\d\d)$/) {
          ($y,$m,$d)=($1,$2,$3);
        }
        if ($m && $d) {
          $m+=0;
          $d+=0;
          my $ev=Data::ICal::Entry::Event->new;
          $ev->add_properties(summary => "$name\'s birthday",
                              rrule => "FREQ=YEARLY;BYMONTHDAY=$d;BYMONTH=$m",
                              dtstart => sprintf('%04d%02d%02d',$y,$m,$d),
                              transp => 'TRANSPARENT');
          $cal->add_entry($ev);
        }
      }
    }
  }
  return $cal;
}

1;
