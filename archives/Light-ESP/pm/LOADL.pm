#
# --------------------------------------------------
#  Loadleveler specific subroutines (LOADL)
# --------------------------------------------------
#
use strict;
use warnings;

use BATCH;

package LOADL;

our @ISA = qw{BATCH};

sub new {
	return bless  BATCH::new;
}

# 
# Site variables
#
# Number of processors per node
#
my $proc_smp = 16;

#  Number of processors busy
#
sub getrunning {
    my ($nrunpe, @fields);
    $nrunpe = 0;
    open( LLS, "llstatus -r %r |");
    while (<LLS>) {
      $nrunpe += $_
    }
    close(LLS);
    return $nrunpe;
}


#
#  Monitor & log batch queues
#
sub monitor_queues {
    my ($nque, $nrun, @fields, $nrunpe);
    my ($sleeptime, $txx0, $ty);

    sleep($_[1]);
    $nque = 0;
    $nrun = 0;
    open( QSTAT, "llq -u $ENV{USER} -r %st 2>/dev/null |");
    while (<QSTAT>) {
	++$nque if (/^I/);
	++$nrun if (/^R/);
    }
    close(QSTAT);
    my $espdone = !($nque || $nrun);
    $nrunpe = getrunning();
    printf(    "%d  I  Runjobs: %d %d PEs   Queued: %d\n", time(), $nrun, $nrunpe, $nque);
    printf main::LOG "%d  I  Runjobs: %d %d PEs   Queued: %d\n", time(), $nrun, $nrunpe, $nque;
    return $espdone;
}


#
#  Fork and submit job
#
sub submit {
    my ($pid, $subcmd, $err, $doit);

    $doit   = $_[2];
    $subcmd = "llsubmit " . $_[1];
    $subcmd = "printf \"SUBMIT -> $_[1]\n\"" if (!$doit);
    if (!defined($pid=fork())) {
	print "Cannot fork!\n";
	exit(1);
    }
    elsif (!$pid) {
	open STDERR, ">/dev/null" || die "cannot redirect stderr\n";
	exec("$subcmd");
	exit(0);
    }
    else {
	$err = waitpid($pid, 0);
    }
}


#
#  Create batch scripts
#  
sub create_jobs {
	my $self = shift;
	$self->initialize;

	my ($timer, $esphome, $espout)
		= ($self->timer, $self->esphome, $self->espout);
	foreach my $j (keys %{$self->jobdesc}) {
		my @jj = @{$self->jobdesc->{$j}};
		my $taskcount = $self->taskcount($jj[0]);
		my $nnode     = int(($taskcount/$proc_smp))
			+ (($taskcount % $proc_smp) ? 1 : 0);
		my $class     = ($j eq "Z") ? "system"  : "special1";
		my $wlimit    = ($j eq "Z") ? "00:03:00" : "10:00:00";
		my $cline = $self->command("\$ESP/","$jj[2]");
		for (my $i=0; $i < $jj[1]; $i++) {
			my $joblabel = $self->joblabel($j,$taskcount,$i);
			print STDERR "creating $joblabel\n" if $self->verbose;
			open(NQS, "> $joblabel");
#
#  "here" template follows 
#  adapt to site batch queue system
#
	print NQS <<"EOF";
# @ job_type         = parallel
# @ job_name         = $joblabel
# @ output           = $espout/$joblabel.out
# @ error            = $espout/$joblabel.out
# @ notification     = never
# @ environment      = \$SEQNUM
# @ node_usage       = not_shared
# @ class            = $class
# @ network.MPI      = csss,shared,us
# @ wall_clock_limit = $wlimit
# @ node             = $nnode
# @ total_tasks      = $taskcount
#
# @ queue
export ESP=$esphome
echo `\$ESP/bin/epoch` " START  $joblabel   Seq_\${SEQNUM}" >> \$ESP/LOG
$cline
echo `\$ESP/bin/epoch` " FINISH $joblabel   Seq_\${SEQNUM}" >> \$ESP/LOG

exit
EOF
#
#  end "here" document
#
	       		close(NQS);
	    		chmod 0744, "$joblabel";
		}
	}
}

1;
