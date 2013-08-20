#
# --------------------------------------------------
# Torque/PBS specific subroutines
# --------------------------------------------------
#
use strict;
use warnings;

use BATCH;

package TORQUE;

our @ISA = qw{BATCH};

sub new {
	return bless  BATCH::new;
}

#  Number of processors busy
#
sub getrunning {
    my ($nrunpe, @fields);
    $nrunpe = 0;

    my $disco = `/home/g5k/qstat_utilized_cores`;
    chomp($disco);
    print "runpe: $disco";
            $nrunpe = $disco;
#    open( LLS, "/home/g5k/qstat_utilized_cores");
 #   while (<LLS>) {
#	@fields = split " ", $_;
#	if ($fields[6] eq "run") {
###CRAY count tasks, not nodes
#	  $nrunpe += $fields[3];
#	}
 #   }
  #  close(LLS);
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
    open( QSTAT, "qstat -a 2>/dev/null |");
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
    system("$subcmd");
    $doit   = $_[2];
#    if (!defined($pid=fork())) {
#	print "Cannot fork!\n";
#	exit(1);
 #   } elsif (!$pid) {
#	chdir("jobmix") || die "cannot chdir!\n";
#	open STDERR, ">/dev/null" || die "cannot redirect stderr\n";
	if (!$doit) {
	    print "  SUBMIT -> $subcmd \n";
	} 
 #       else {
#	    exec("$subcmd");
 #       }
#	exit(0);
 #   } else {
#	$err = waitpid($pid, 0);
 #   }
}

sub create_jobs {
	my $self = shift;
	$self->initialize;

	my ($timer, $esphome, $espout, $packed)
		= ($self->timer, $self->esphome, $self->espout, $self->packed);
	foreach my $j (keys %{$self->jobdesc}) {
		my @jj = @{$self->jobdesc->{$j}};
		my $taskcount = $self->taskcount($jj[0]);
		my $cline = $self->command("\$ESP/","$jj[2]");
		my $wlimit = int($jj[2]*1.50);
		for (my $i=0; $i < $jj[1]; $i++) {
			my $needed = int($taskcount/8);
			my $ppn = int($taskcount % 8);
			my $nodes;
			my $np;
			if ($needed == 0){
				$nodes = "nodes=1:ppn=$ppn";}
			elsif($ppn == 0){
				$nodes = "nodes=$needed:ppn=8";}
			else				{
				$nodes = "nodes=$needed:ppn=8+1:ppn=$ppn";}
			if ($taskcount == 2){
				$np = 3;
			}elsif ($taskcount == 16){
				$np = 17;
			}else {$np = $taskcount;}
			my $joblabel = $self->joblabel($j,$taskcount,$i);	
			print STDERR "creating $joblabel\n" if $self->verbose;
			open(NQS, "> $joblabel");
#
#  "here" template follows 
#  adapt to site batch queue system
# $timer /usr/bin/aprun -N $packed -n $taskcount $clin
# #PBS -l nodes=4:ppn=2,walltime=30:00 e
			print NQS <<"EOF";
#\!/bin/sh
#PBS -N $joblabel
#PBS -o /home/g5k/BENCHS/esp-2.2.1/logs/$joblabel.out
#PBS -j oe
#PBS -m n
#PBS -v SEQNUM
#PBS -l $nodes,walltime=$wlimit
#PBS -q batch
#PBS -S /bin/sh
ESP=/home/g5k/BENCHS/esp-2.2.1

cd \$PBS_O_WORKDIR

echo `\$ESP/bin/epoch` " START  $joblabel   Seq_\${SEQNUM} \$PBS_JOBID" >> \$ESP/LOG
$timer mpirun -np $np --hostfile \$PBS_NODEFILE $cline
echo `\$ESP/bin/epoch` " FINISH $joblabel   Seq_\${SEQNUM} \$PBS_JOBID" >> \$ESP/LOG

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
