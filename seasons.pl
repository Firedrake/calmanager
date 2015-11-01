#! /usr/bin/perl

use strict;
use warnings;

package Calmanager::Season;

use Data::ICal::DateTime;
use Data::ICal::Entry::Event;

sub category {
  return 'Seasons';
};

sub generate {
  shift;
  my $y=shift;
  my $cal=Data::ICal->new;
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
  my @start=(DateTime->now,-1);
  $start[0]->set_time_zone($y->{tz});
  my @end=($start[0]+DateTime::Duration->new(seconds => 3974400),-1);
  $end[0]->set_time_zone('Europe/London');
  $start[1]=getlon($start[0]);
  my $tn=int($start[1]/45)+1;
  foreach my $tt ($tn..7,(0..7)x0,0..$tn-1) {
    my $target=45*$tt;
    my $dur=$end[0]->subtract_datetime_absolute($start[0]);
    $end[1]=getlon($end[0]);
    my @n;
    while ($dur->in_units('seconds')>0.5) {
      $dur->multiply(0.5);
      @n=($start[0]->clone->add($dur),-1);
      $n[1]=getlon($n[0]);
      if (angledelta($end[1],$target) > angledelta($target,$start[1])) {
        @end=@n;
      } else {
        @start=@n;
      }
    }
    $n[0]->set_time_zone($y->{tz});
    my $ev=Data::ICal::Entry::Event->new;
    $ev->add_properties(summary => $name[$tt],
                        dtstart => $n[0]->format_cldr('yyyyMMdd').'T'.$n[0]->format_cldr('HHmmss'));
    $cal->add_entry($ev);
    $start[0]=$n[0]+DateTime::Duration->new(seconds => 3456000);
    $start[0]->set_time_zone('Europe/London');
    $end[0]=$start[0]+DateTime::Duration->new(seconds => 864000);
    $end[0]->set_time_zone('Europe/London');
    $start[1]=getlon($start[0]);
  }
  return $cal;
}

sub dt2swe {
  my $dt=shift;
  $dt->set_time_zone('GMT');
  my @o;
  push @o,'-b'.$dt->format_cldr('d.M.yyyy');
  push @o,'-ut'.$dt->format_cldr('HH:mm:ss');
  return @o;
}

sub getlon {
  my $dt=shift;
  open I,'-|',qw(swetest -p0 -fl -head),dt2swe($dt);
  chomp (my $r=<I>);
  close I;
  return 0+$r;
}

sub angledelta {
  my ($end,$start)=@_;
  if ($end < $start) {
    $end+=360;
  }
  return $end-$start;
}

1;
