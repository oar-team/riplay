#
# --------------------------------------------------
# LSF specific subroutines
# --------------------------------------------------
#
use strict;
use warnings;

use BATCH;

package LSF;

our @ISA = qw{BATCH};

sub new {
	return bless  BATCH::new;
}

#  Number of processors busy
#
sub getrunning {
    my ($nrunpe, @fields);
    $nrunpe = 0;
    open( LLS, "qstat normal | grep run|");
    while (<LLS>) {
	@fields = split " ", $_;
	$nrunpe += $fields[0];
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
    open( QSTAT, "bjobs |");
    while (<QSTAT>) {
	@fields = split " ", $_;
	if ($fields[2] eq "PEND") {
	  ++$nque;
	}
	if ($fields[2] eq "RUN" ) {
	  ++$nrun;
	}
#	print "nque = $nque nrun = $nrun\n";
    }
    close(QSTAT);
    $nrunpe = getrunning();
    $main::espdone = !($nque || $nrun || $nrunpe);
    my $myepoch = main::epoch();

    printf("%d I nrun: %d, nrunpe: %d, nque: %d, espdone: %d\n", $myepoch, $nrun, $nrunpe, $nque, $main::espdone);
    printf main::LOG "%d  I  Runjobs: %d %d PEs Queued: %d espdone: %d\n", $myepoch, $nrun, $nrunpe, $nque, $main::espdone;
}

#
#  Fork and submit job
#
sub submit {
    my ($pid, $subcmd, $err, $doit);

    $subcmd = "bsub < " . $_[1];
    $doit   = $_[2];
    print "subcmd = $subcmd\n";
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


sub makereservation {
    my ($pid, $subcmd, $err);
    my $startdate = `date -d "+1 min" +%H:%M`;
    my $enddate = `date -d "+5 min" +%H:%M`;

    chop $startdate;
    chop $enddate;

	my ($host,$hosts,$reservation,$null);
    foreach my $i (`bhosts`) {
      ($host,$null) = split / /, $i;
      if ($host ne "HOST_NAME") {
	$hosts = $hosts . $host . " ";
      }
    }

    ($null, $reservation, $null)  = split " ", `brsvadd -n 32 -m "$hosts" -u tdavis -b $startdate -e $enddate`;
    print "reservation = $reservation\n";

}

sub create_jobs {
	my $self = shift;
	$self->initialize;

	my ($timer, $esphome, $espout, $scratch, $packed)
		= ($self->timer, $self->esphome, $self->espout,
			$self->scratch, $self->packed);
	foreach my $j (keys %{$self->jobdesc}) {
		my @jj = @{$self->jobdesc->{$j}};
		my $taskcount = $self->taskcount($jj[0]);
		my $cline = $self->command("./","$jj[2]");
		my $wlimit = int($jj[2]*1.50);
		for (my $i=0; $i < $jj[1]; $i++) {
			my $needed = $taskcount/$packed;
			my $nodes = "span[ptile=$packed]";
			my $joblabel = $self->joblabel($j,$taskcount,$i);
			my $workdir = "$scratch/$joblabel";
			print STDERR "creating $joblabel\n" if $self->verbose;
			open(NQS, "> $joblabel");
#
#  "here" template follows 
#  adapt to site batch queue system
#
			print NQS <<"EOF";
#\!/bin/sh
#BSUB -n $taskcount
#BSUB -R $nodes
#BSUB -o $espout/$joblabel.out
#BSUB -J $joblabel
#BSUB -sp $jj[2]
##BSUB -x
#
ESP=$esphome

echo `\$ESP/bin/Epoch` " START  " $joblabel "  Seq# SEQNUM"

mkdir -p $workdir/bin
cp $esphome/bin/* $workdir/bin
cd $workdir

# How many proc do I have?
NP=\$(wc -l /tmp/nodelist.\$LSB_JOBID | awk '{print \$1}')

echo "starting mpirun.."

$timer mpirun.ch_gm --gm-kill 10 -machinefile /tmp/nodelist.\$LSB_JOBID -np \$NP $cline

echo "mpirun finished."

echo `\$ESP/bin/Epoch` " FINISH " $joblabel "  Seq# SEQNUM"

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
