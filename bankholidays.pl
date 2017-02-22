#! /usr/bin/perl

use strict;
use warnings;
use utf8;

package Calmanager::BankHoliday;

use Data::ICal::DateTime;
use Data::ICal::Entry::Event;
use LWP::Simple;

sub category {
  return 'Bank Holiday';
};

sub generate {
  my $calstr=get('https://www.gov.uk/bank-holidays/england-and-wales.ics');
  my $cal=Data::ICal->new;
  if ($calstr) {
    $calstr =~ s/’/'/g;
    $calstr =~ s/(SUMMARY:[\w ]*)/$1 Bank Holiday/g;
    $cal=Data::ICal->new(data => $calstr);
  }
  return $cal;
}

1;
