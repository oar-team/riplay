#
# FCFS - First Come, First Served scheduler
#
#	This scheduler will just take the first entry in the
#	queue and run it (if there is sufficient resources)
#
# To craft your own schedule it must define as least the following
# routine that samples the Running and Queued jobs and decide whether
# to move a queued job to running ... that's it.
#

use strict;
use warnings;

our (@qdb, @rdb, %QR, %RR);

sub ChooseNext {
# how many open pipes
	my $list = &RunGetFreeList;
	my ($empty,$started) = (scalar @$list, 0);
# look at Queue
	&QueueTie;
	if (scalar @qdb) {
		# check if any Z jobs are in the queue
		if (scalar grep /\|Z_/, @qdb) {
			# found one ... don't submit any other jobs
			# can't start one unless empty
			if ($empty) {
				my ($i,$qz) = (0,'');
				foreach $qz (@qdb) {
					last	if $qz =~ /\|Z_/;
					$i++;
				}
				my @rec = &SplitRecord($qdb[$i]);
				if ($rec[$QR{'size'}] <= $empty) {
					# run with it
					if (&RunStartJob($qdb[$i])) {
						splice @qdb, $i;
						$started = 1;
					}
				}
			}
		} else {
			# grab first one and look at it
			my @rec = &SplitRecord($qdb[0]);
			if ($rec[$QR{'size'}] <= $empty) {
				# run with it
				$started = 1	if (&RunStartJob(shift @qdb));
			}
		}
	}
	&QueueUntie;
	# return 1 if started a job, 0 otherwise.
	$started;
}

1;
