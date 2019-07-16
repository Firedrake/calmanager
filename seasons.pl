#! /usr/bin/perl

use strict;
use warnings;
use Astro::Coord::ECI;
use Astro::Coord::ECI::Sun;
use Astro::Coord::ECI::Utils qw{deg2rad rad2deg};
use Data::ICal::DateTime;
use Data::ICal::Entry::Event;
use Date::ICal;

package Calmanager::Season;

sub category {
  return 'Seasons';
};

sub generate {
  shift;
  my $y=shift;
  my $cal=Data::ICal->new;
  my %lookup=(
    'Spring equinox' => 0,
    'Summer solstice' => 2,
    'Fall equinox' => 4,
    'Winter solstice' => 6,
      );
  my @name=(
    'Northward Equinox',
    'Beltane',
    'Northern Solstice',
    'Lammas',
    'Southward Equinox',
    'Samhain',
    'Southern Solstice',
    'Imbolc',
      );
  my $tmin=time;
  my $tbase=$tmin-35*86400;
  my $tmax=$tmin+365.25*86400;
  my $sun = Astro::Coord::ECI::Sun->new;
  $sun->universal($tbase);
  my $prev=0;
  while (1) {
    my ($tq,$quarter,$desc)=$sun->next_quarter;
    if ($prev) {
      my $start=($prev+$tq)/2;
      my $target=($quarter*2-1)*45;
      while ($target<0) {
        $target+=360;
      }
      $target=::deg2rad($target);
      my $step=10000;
      my $sign=0;
      while ($step > 0.001) {
        $start+=$step*$sign;
        $sun->universal($start);
        my $gl=$sun->geometric_longitude;
        if ($sign) {
          if (($gl-$target)*$sign>0) {
            $start-=$step*$sign;
            $step/=2;
            $sign=0;
          }
        } else {
          $sign=($gl>$target)?-1:1;
        }
      }
    my $ev=Data::ICal::Entry::Event->new;
    $ev->add_properties(summary => $name[2*$quarter-1],
                        duration => 'PT1S');
    $ev->start(DateTime->from_epoch(epoch => $start-1));
    $cal->add_entry($ev);
      $sun->universal($tq);
    }
    $prev=$tq;
    my $ev=Data::ICal::Entry::Event->new;
    $ev->add_properties(summary => $name[2*$quarter],
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
