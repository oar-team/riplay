#
# --------------------------------------------------
# Torque/PBS specific subroutines
# --------------------------------------------------
#
use strict;
use warnings;

use BATCH;

package OAR;

our @ISA = qw{BATCH};

sub new {
	return bless  BATCH::new;
}

#  Number of processors busy
#
sub getrunning {
    my ($nrunpe, @fields);
    $nrunpe = 0;
    my $disco = `/home/g5k/oarnodes_utilized_cores`;
#    open( LLS, "/home/g5k/disco_utilized_cores");
 #   if (<LLS>) {
 	chomp($disco);
  	#$nrunpe = $_;
	print "runpe: $disco";
	$nrunpe = $disco;
#	@fields = split " ", $_;
#	if ($fields[5] eq "R") {
###CRAY count tasks, not nodes
#	  $nrunpe += $fields[3];
#	}
#    }
 #   close(LLS);
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
    open( QSTAT, "oarstat -u $ENV{USER} 2>/dev/null |");
    while (<QSTAT>) {
	@fields = split " ", $_;
        if  ($fields[5] eq "W" ) {
  	  ++$nque;
	} elsif ($fields[5] eq "R") {
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

    $subcmd = "oarsub -S " . $_[1];
    system("$subcmd");
#    $subcmd = $_[1];
    $doit   = $_[2];
    if (!$doit) {
       print "  SUBMIT -> $subcmd \n";
    }
#    exec("$subcmd");
#    if (!defined($pid=fork())) {
#	print "Cannot fork!\n";
#	exit(1);
#    } elsif (!$pid) {
#	chdir("jobmix") || die "cannot chdir!\n";
#	open STDERR, ">/dev/null" || die "cannot redirect stderr\n";
#	if (!$doit) {
#	    print "  SUBMIT -> $subcmd \n";
#	} 
 #       else {	
#	#print "  SUBMIT -> $subcmd \n";
#	    exec("$subcmd");
#	    die "commande_qui_prend_du_temps non trouvée dan}";
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
		my $min = int($wlimit/60);
		my $sec = int($wlimit%60);
		my $walltime = "00:$min:$sec";
		for (my $i=0; $i < $jj[1]; $i++) {
			my $needed = $taskcount/$packed;
			my $nodes = "/core=$taskcount,walltime=$walltime";
			my $np=$taskcount;
			if ($taskcount == 2){ $np = 3} 
			if ($taskcount == 16){ $np = 17}
			my $joblabel = $self->joblabel($j,$taskcount,$i);
			print STDERR "creating $joblabel\n" if $self->verbose;
			open(NQS, "> $joblabel");
#
#  "here" template follows 
#  adapt to site batch queue system
#
print NQS <<"EOF";
#\!/bin/sh
#OAR -n $joblabel
#OAR -l $nodes
#OAR --stdout /home/g5k/BENCHS/esp-2.2.1/logs/$joblabel.out

ESP=/home/g5k/BENCHS/esp-2.2.1/
# How many proc do I have?
#NP=\$(wc -l \$PBS_NODEFILE | awk '{print \$1}')

#cd \$PBS_O_WORKDIR

echo `\$ESP/bin/epoch` " START  $joblabel   Seq_\${SEQNUM}" >> \$ESP/LOG
$timer mpirun -np $np --hostfile \$OAR_NODEFILE --mca plm_rsh_agent "oarsh" $cline
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
