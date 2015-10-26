#! /usr/bin/perl

use strict;
use warnings;

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
  my @name=(
    ['New Moon',0],
    ['First Quarter',0.5],
    ['Full Moon',1],
    ['Last Quarter',0.5],
  );
  my $searchstart=DateTime->now-DateTime::Duration->new(seconds => 2807482);
  $searchstart->set_time_zone('GMT');
  $searchstart->set(hour => 0,minute => 0,second => 0);
  my $state=0;
  my $ophase=0;
  foreach my $span (0..28) {
    my $t=$searchstart+DateTime::Duration->new(days => $span);
    my $phase=getphase($t);
    if ($state==0 && $phase<$ophase) {
      $state=1;
    } elsif ($state==1 && $phase>$ophase) {
      $state=$span-2;
      last;
    }
    $ophase=$phase;
  }
  my $t=$searchstart+DateTime::Duration->new(days => $state);
  my $newmoon=chopsearch($t,86400*2,0);
  $newmoon->set_time_zone($y->{tz});
  my $pn;
  my $out;
  foreach my $tt ((0..3)x13) {
    if ($newmoon) {
      $out=$newmoon->clone;
      $pn=0;
      undef $newmoon;
    } else {
      $pn++;
      $pn%=4;
      my $ta=$pn==3?0.5:$pn/2;
      $out=chopsearch($out+DateTime::Duration->new(days => 7),86400*2,$ta);
      $out->set_time_zone($y->{tz});
    }
    my $ev=Data::ICal::Entry::Event->new;
    $ev->add_properties(summary => $name[$pn][0],
                        dtstart => $out->format_cldr('yyyyMMdd').'T'.$out->format_cldr('HHmmss'));
    $cal->add_entry($ev);
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

sub getphase {
  my $dt=shift;
  open I,'-|',qw(swetest -p1 -f- -head),dt2swe($dt);
  chomp (my $r=<I>);
  close I;
  return 0+$r;
}

sub chopsearch {
  my @start=(shift @_,-1);
  my $span=shift @_;
  my $target=shift @_;
  my @end=($start[0]+DateTime::Duration->new(seconds => $span),0);
  my $dur=$end[0]->subtract_datetime_absolute($start[0]);
  $start[1]=getphase($start[0]);
  $end[1]=getphase($end[0]);
  my @n;
  while ($dur->in_units('seconds')>0.5) {
    $dur->multiply(0.5);
    @n=($start[0]->clone->add($dur),-1);
    $n[1]=getphase($n[0]);
    if (abs($end[1]-$target) > abs($target-$start[1])) {
      @end=@n;
    } else {
      @start=@n;
    }
  }
  return $n[0];
}

1;
