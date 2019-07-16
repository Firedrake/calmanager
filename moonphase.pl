#! /usr/bin/perl

use strict;
use warnings;
use Astro::Coord::ECI;
use Astro::Coord::ECI::Moon;
use Astro::Coord::ECI::Utils qw{deg2rad rad2deg};
use Data::ICal::DateTime;
use Data::ICal::Entry::Event;
use Date::ICal;

package Calmanager::MoonPhase;

use Data::ICal::DateTime;
use Data::ICal::Entry::Event;

sub category {
  return 'Moon Phase';
};

sub generate {
  shift;
  my $y=shift;
  my $cal=Data::ICal->new;
  my $tmin=time;
  my $tbase=$tmin-5*86400;
  my $tmax=$tmin+365.25*86400;
  my $moon = Astro::Coord::ECI::Moon->new;
  $moon->universal($tbase);
  while (1) {
    my ($tq,$quarter,$desc)=$moon->next_quarter;
    my $ev=Data::ICal::Entry::Event->new;
    $ev->add_properties(summary => $desc,
                        duration => 'PT1S');
    $ev->start(DateTime->from_epoch(epoch => $tq-1));
    $cal->add_entry($ev);
    if ($tq > $tmax) {
      last;
    }
  }
  return $cal;
}

1;
