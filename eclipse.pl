#! /usr/bin/perl

use strict;
use warnings;

package Calmanager::LunarEclipse;

use Data::ICal::DateTime;
use Data::ICal::Entry::Event;

sub category {
  return 'Eclipse';
};

sub generate {
  shift;
  my $y=shift;
  my $cal=Data::ICal->new;
  my @pos=($y->{lon},$y->{lat},$y->{alt} || 100);
  foreach my $mode (qw(sol lun)) {
    my $searchstart=DateTime->now;
    my $limit=$searchstart+DateTime::Duration->new(years => 10);
    $searchstart->set_time_zone('GMT');
    while (DateTime::compare($searchstart,$limit)<0) {
      my %e=%{getecl($searchstart,$mode,\@pos)};
      my $class=$e{class};
      delete $e{class};
      if ($class !~ /^Penumb\. lunar/) {
        foreach my $type (keys %e) {
          map {$e{$type}[$_]->set_time_zone($y->{tz})} (0,1);
          my $ev=Data::ICal::Entry::Event->new;
          $ev->add_properties(summary => "$class $type phase",
                              dtstart => $e{$type}[0]->format_cldr('yyyyMMdd').'T'.$e{$type}[0]->format_cldr('HHmmss'),
                              dtend => $e{$type}[1]->format_cldr('yyyyMMdd').'T'.$e{$type}[1]->format_cldr('HHmmss'),
                                );
          $cal->add_entry($ev);
        }
      }
      my $rk=(keys %e)[0];
      $searchstart=$e{$rk}[1]+DateTime::Duration->new(days => 2);
    }
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

sub getecl {
  my $dt=shift;
  my $mode=shift;
  my $pos=shift;
  my @smlist=(["partial",0,3],["total",1,2]);
  if ($mode eq 'lun') {
    @smlist=(["penumbral",0,5],["partial",1,4],["total",2,3]);
  }
  my $rmax;
  my %r;
  open I,'-|',qw(swetest -head),dt2swe($dt),"-${mode}ecl","-geopos".join(',',@{$pos});
  my $state=0;
  while (<I>) {
    chomp;
    s/: /:0/g;
    my @data=split ' ',$_;
    if ($mode eq 'lun' && /saros/) {
      $r{class}=$data[0];
      $data[3] =~ /([0-9]+)\.([0-9]+)\.([0-9]+)/;
      my $dtx=DateTime->new(year => $3,month => $2,day => $1);
      $data[4] =~ /([0-9]+):([0-9]+):([0-9]+)/;
      $dtx->set(hour => $1,minute => $2,second => $3);
      $rmax=$dtx;
      $state=1;
    } elsif ($mode eq 'sol' && /saros/) {
      $r{class}=$data[0];
      $data[1] =~ /([0-9]+)\.([0-9]+)\.([0-9]+)/;
      my $dtx=DateTime->new(year => $3,month => $2,day => $1);
      $data[2] =~ /([0-9]+):([0-9]+):([0-9]+)/;
      $dtx->set(hour => $1,minute => $2,second => $3);
      $rmax=$dtx;
      $state=1;
    } elsif ($state==1) {
      foreach my $submode (@smlist) {
        my @s;
        foreach my $parm ($submode->[1],$submode->[2]) {
          my $dtx=$rmax->clone;
          if ($data[$parm] =~ /([0-9]+):([0-9]+):([0-9]+)/) {
            $dtx->set(hour => $1,minute => $2,second => $3);
            if (DateTime->compare($dtx,$rmax)>0 && $parm==$submode->[1]) {
              $dtx->subtract(days => 1);
            } elsif (DateTime->compare($dtx,$rmax)<0 && $parm==$submode->[2]) {
              $dtx->add(days => 1);
            }
            push @s,$dtx;
          } else {
            last;
          }
        }
        if (@s) {
          my $name=$submode->[0];
          my $visible=0;
          foreach my $dtx (@s) {
            if (getheight($dtx,$mode,$pos)>0) {
              $visible++;
            }
          }
          if ($visible==0) {
            $name="invisible $name";
          } elsif ($visible==1) {
            $name="part-visible $name";
          }
          $r{$name}=\@s;
        }
      }
      last;
    }
  }
  $r{class} .= " ${mode}ar eclipse";
  $r{class}=ucfirst($r{class});
  close I;
  return \%r;
}

sub getheight {
  my $dt=shift;
  my $mode=shift;
  my $pos=shift;
  my $mn=($mode eq 'sol')?0:1;
  open I,'-|',qw(swetest -fh -head),"-p$mn",dt2swe($dt),"-geopos".join(',',@{$pos});
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
