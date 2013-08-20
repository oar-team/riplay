#
# --------------------------------------------------
# OpenPBS specific subroutines
# --------------------------------------------------
#
use strict;
use warnings;

use BATCH;

package PBS;

our @ISA = qw{BATCH};

sub new {
	return bless  BATCH::new;
}

#  Number of processors busy
#
sub getrunning {
    my ($nrunpe, @fields);
    $nrunpe = 0;
    open( LLS, "qstat -u $ENV{USER} |");
    while (<LLS>) {
	@fields = split " ", $_;
	if ($fields[9] eq "R") {
	  $nrunpe += $fields[5];
	}
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
    open( QSTAT, "qstat -u $ENV{USER} 2>/dev/null |");
    while (<QSTAT>) {
	@fields = split " ", $_;
        if  ($fields[9] eq "Q" ) {
  	  ++$nque;
	} elsif ($fields[9] eq "R") {
	  ++$nrun;
	}
    }
    close(QSTAT);
    $nrunpe = getrunning();
    $main::espdone = !($nque || $nrun || $nrunpe);
    printf("%d  I  Runjobs: %d PEs: %d Queued: %d espdone: %d\n", time(), $nrun, $nrunpe, $nque, $main::espdone);
    printf main::LOG "%d  I  Runjobs: %d PEs: %d Queued: %d espdone: %d\n", time(), $nrun, $nrunpe, $nque, $main::espdone;
}

#
#  Fork and submit job
#
sub submit {
    my ($pid, $subcmd, $err, $doit);

    $subcmd = "qsub " . $_[1];
    $doit   = $_[2];
    if (!defined($pid=fork())) {
	print "Cannot fork!\n";
	exit(1);
    } elsif (!$pid) {
	chdir("jobmix") || die "cannot chdir!\n";
	open STDERR, ">/dev/null" || die "cannot redirect stderr\n";
	if (!$doit) {
	    print "  SUBMIT -> $subcmd \n";
	} 
        else {
	    exec("$subcmd");
        }
	exit(0);
    } else {
	$err = waitpid($pid, 0);
    }
}

sub create_jobs {
	my $self = shift;
	$self->initialize;

	my ($timer, $esphome, $espout, $packed)
		= ($self->timer, $self->esphome, $self->espout, $self->packed);
	foreach my $j (keys %{$self->jobdesc}) {
		my @jj = @{$self->jobdesc->{$j}};
		my $taskcount = $self->taskcount($jj[0]);
		my $cline = $self->command("./","$jj[2]");
		my $wlimit = int($jj[2]*1.50);
		for (my $i=0; $i < $jj[1]; $i++) {
			my $needed = $taskcount/$packed;
			my $nodes = "nodes=$needed:ppn=$packed";
			my $joblabel = $self->joblabel($j,$taskcount,$i);
			print STDERR "creating $joblabel\n" if $self->verbose;
			open(NQS, "> $joblabel");
#
#  "here" template follows 
#  adapt to site batch queue system
#
			print NQS <<"EOF";
#\!/bin/sh
#PBS -N $joblabel
#PBS -o $espout/$joblabel.out
#PBS -j oe
#PBS -m n
#PBS -v SEQNUM
#PBS -l $nodes,walltime=$wlimit
ESP=$esphome

# How many proc do I have?
NP=\$(wc -l \$PBS_NODEFILE | awk '{print \$1}')

cd \$PBS_O_WORKDIR

echo `\$ESP/bin/epoch` " START  $joblabel   Seq_\${SEQNUM}" >> \$ESP/LOG
$timer mpirun_rsh -hostfile \$PBS_NODEFILE -np \$NP $cline
echo `\$ESP/bin/epoch` " FINISH $joblabel   Seq_\${SEQNUM}" >> \$ESP/LOG

exit
EOF
#
#  end "here" document
#
	       		close(NQS);
		}
	}
}

1;
