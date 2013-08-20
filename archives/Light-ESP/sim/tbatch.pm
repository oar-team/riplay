#
# Common routines used by the TBATCH scripts
#

use strict;
use warnings;

#
# Necessary Constants that need to be initialized
#
my $basedir = '.';

sub basedir {
	@_	?	$basedir = shift
		:	$basedir;
}

my $npipes = 0;

sub npipes {
	@_	?	$npipes = shift
		:	$npipes;
}

#
# internal epoch time (corresponds to seconds if real-time)
#
my $epoch = 0;

sub Epoch {
	@_	?	$epoch = shift
		:	$epoch;
}
sub EpochIncr {
	$epoch += shift;
}

#
# internal job number
#
my $job = 0;

sub Job {
	@_	?	$job = shift
		:	$job;
}
sub JobIncr {
	$job += 1;
}

sub Queue {
	"$basedir/tqueue.db";
}
sub Run {
	"$basedir/trun.db";
}

#
# Queue Database
#
our %QR = (
	file		=> 0,
	label		=> 1,
	size		=> 2,
	secs		=> 3,
	submitted	=> 4,
);

sub SplitRecord {
	split('\|', shift);
}

sub JoinRecord {
	join('|', @_);
}

our @qdb = ();

sub QueueTie {
	my ($queue) = (&Queue);
	if (! scalar @qdb) {
		tie @qdb, 'Tie::File', $queue
			|| die "Cannot open database file '$queue'\n";
	}
}

sub QueueUntie {
	if (scalar @qdb) {
		untie @qdb;
	}
}

sub AddQueueRecord {
	# my ($file, $label, $size, $secs) = @_;
	&QueueTie;
	push @qdb, &JoinRecord(@_);
	&QueueUntie;
}

sub QueueCopy {
	&QueueTie;
	my @copy = @qdb;
	&QueueUntie;
	return @copy	if   wantarray;
	return \@copy	if ! wantarray;
}

#
# Run database
#
our %RR = (
	pipe		=> 0,
	job		=> 1,
	file		=> 2,
	label		=> 3,
	size		=> 4,
	secs		=> 5,
	epochstart	=> 6,
	epochfinish	=> 7,
);

our @rdb = ();

sub RunTie {
	my ($run) = (&Run);
	if (! @rdb) {
		tie @rdb, 'Tie::File', $run
			|| die "Cannot open database file '$run'\n";
	}
}

sub RunUntie {
	if (@rdb) {
		untie @rdb;
	}
}

sub RunInit {
	&RunTie;
	for (my $i = 0; $i < $npipes; $i++) {
		$rdb[$i] = "$i|||||||";
	}
	&RunUntie;
}

sub RunCopy {
	&RunTie;
	my @copy = @rdb;
	&RunUntie;
	return @copy	if   wantarray;
	return \@copy	if ! wantarray;
}

sub RunMaxJobNum {
	my $jobs = &RunCopy();
	my $maxjn = 0;
	for (my $i = 0; $i < $npipes; $i++) {
		my $myjn = (&SplitRecord($jobs->[$i]))[$RR{'job'}];
		$maxjn = $myjn		if defined $myjn && $myjn > $maxjn;
	}
	$maxjn;
}

sub RunGetFreeList {
	my $copy = &RunCopy;
	my @list;

	for (my $i = 0; $i < $npipes; $i++) {
		my @rec = &SplitRecord($copy->[$i]);
		push @list, $i	
			if ! defined $rec[$RR{'job'}];
	}
	return @list	if   wantarray;
	return \@list	if ! wantarray;
}

sub RunStartJob {
	# queue parameters
	my ($file,$label,$size,$secs) = @_;
	# maybe just got record
	($file,$label,$size,$secs) = &SplitRecord($file)
		if ! defined $label;

	# get list of free pipes and number
	my $list = &RunGetFreeList;
	my $num = scalar @{$list};

	# can't do it
	return undef	if $size > $num;

	# fill pipes
	my ($i,$jn,$start) = (0,&Job(),&Epoch());
	my ($finish) = ($start + $secs);
	&RunTie;
	foreach my $p (@{$list}[0 .. $size-1]) {
		$rdb[$p] = &JoinRecord($p,$jn,$file,$label,$size,$secs,
					$start,$finish);
	}
	&RunUntie;

	# increment job number
	&JobIncr;

	return $size;
}

sub RunEndJob{
	# remove job given the jobnumber
	my $jn = shift;

	return undef	if ! defined $jn;

	# empty pipes
	my ($cnt) = (0);
	&RunTie;
	foreach my $p (0 .. $npipes-1) {
		my @rec = &SplitRecord($rdb[$p]);
		if (defined $rec[$RR{'job'}]
		&& ($rec[$RR{'job'}] == $jn)) {
			$rdb[$p] = "$p|||||||";
			$cnt++;
		}
	}
	&RunUntie;

	return $cnt;
}

sub RunEndTime{
	# remove job with end time less than the given
	my $endtime = shift;

	return undef	if ! defined $endtime;

	# get copy and collect the jobnumbers
	my $copy = &RunCopy;

	my %jlist;

	foreach my $p (0 .. $npipes-1) {
		my @rec = &SplitRecord($copy->[$p]);
		if (defined $rec[$RR{'job'}]
		&& ($rec[$RR{'epochfinish'}] <= $endtime)) {
			$jlist{$rec[$RR{'job'}]} = 1;
		}
	}

	# clear out those jobs identified
	my $cnt = 0;
	foreach my $j (sort keys %jlist) {
		$cnt += &RunEndJob($j);
	}

	return $cnt;
}

# display queued and running jobs

sub ShowRunning {
	my ($opt_l, $opt_R) = @_;

#		stat	job#	label	size	secs	start	end
	my $rformat =	"R 	%d	%s	%d	%d	%d	%d\n";

	my $run = &RunCopy;
	my ($text,%jlist) = ("");
	foreach my $p (@$run) {
		my ($pipe,$job,$file,$label,$size,$secs, $estart, $eend)
			= &SplitRecord($p);
		next	if ! defined $job;
		if (exists $jlist{$job}) {
			$jlist{$job}->{'num'}++;
		} else {
			$jlist{$job} = {
				num	=> 1,
				file	=> $file,
				label	=> $label,
				size	=> $size,
				secs	=> $secs,
				estart	=> $estart,
				eend	=> $eend,
			}
		}
	}
	# dump out results
	foreach my $j (keys %jlist) {
		my $jj = $jlist{$j};
		next	if (defined $opt_l) && ($jj->{'label'} ne $opt_l);
		my $line = sprintf $rformat, $j,
			$jj->{'label'},
			$jj->{'num'},
			$jj->{'secs'},
			$jj->{'estart'},
			$jj->{'eend'};
		if ($opt_R) {
			$text = $line.$text;
		} else {
			$text .= $line;
		}
	}
	$text;
}

sub ShowQueue {
	my ($opt_l, $opt_R) = @_;
#		stat		label	size	secs	submitted
my $qformat =	"Q 	_	%s	%d	%d	%d\n";

	my $queue = &QueueCopy;
	my $text = "";
	foreach my $p (@$queue) {
		my ($file,$label,$size,$secs, $submitted)
			= &SplitRecord($p);
		next	if (defined $opt_l) && ($label ne $opt_l);
#		stat		label	size	secs	submitted
		my $line = sprintf $qformat, 
			$label,
			$size,
			$secs,
			$submitted;
		if ($opt_R) {
			$text = $line.$text;
		} else {
			$text .= $line;
		}
	}
	$text;
}

1;
