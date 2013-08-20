#
# --------------------------------------------------
# SGE specific subroutines
# --------------------------------------------------
#
use strict;
use warnings;

use BATCH;

package SGE;

our @ISA = qw{BATCH};

sub new {
	return bless  BATCH::new;
}

#  Number of processors busy
#
sub getrunning {
    my ($nrunpe, @fields);
    $nrunpe = 0;
    open( LLS, "qstat -f | grep BIP|");
    while (<LLS>) {
	@fields = split " ", $_;
	my @pes = split "/", $fields[2];
	$nrunpe += $pes[0];
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
    
    sleep($_[0]);
    $nque = 0;
    $nrun = 0;
    open( QSTAT, "qstat -u tdavis 2>/dev/null |");
    while (<QSTAT>) {
	@fields = split " ", $_;
        if  ($fields[4] eq "qw" ) {
  	  ++$nque;
	} elsif ($fields[4] eq "r" && $fields[8] eq "MASTER" ) {
	  ++$nrun;
	}
    }
    close(QSTAT);
    $nrunpe = getrunning();
    my $espdone = !($nque || $nrun || $nrunpe);
    printf("%d I nrun: %d, nrunpe: %d, nque: %d, espdone: %d\n", epoch(), $nrun, $nrunpe, $nque, $espdone);
    printf LOG "%d  I  Runjobs: %d %d PEs   Queued: %d\n", epoch(), $nrun, $nrunpe, $nque;
}

my $qsub = " qsub";

#
#  Fork and submit job
#
sub submit {
    my ($pid, $subcmd, $err, $doit);

    $subcmd = $qsub . " " . $_[1];
    $doit   = $_[2];
    if (!defined($pid=fork())) {
	print "Cannot fork!\n";
	exit(1);
    } elsif (!$pid) {
	chdir("jobmix/SGE") || die "cannot chdir!\n";
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

	my ($timer, $esphome, $espout, $scratch)
		= ($self->timer, $self->esphome, $self->espout, $self->scratch);
	foreach my $j (keys %{$self->jobdesc}) {
		my @jj = @{$self->jobdesc->{$j}};
		my $taskcount = $self->taskcount($jj[0]);
		my $cline = $self->command("./","$jj[2]");
		for (my $i=0; $i < $jj[1]; $i++) {
			my $joblabel = $self->joblabel($j,$taskcount,$i);
			my $workdir = "$scratch/$joblabel";
			print STDERR "creating $joblabel\n" if $self->verbose;
#    $out = $main::espout . "/SGE";
			open(NQS, "> $joblabel");
#
#  "here" template follows 
#  adapt to site batch queue system
#
	print NQS <<"EOF";
#\!/bin/sh
#\$ -N $joblabel
#\$ -o $espout/$joblabel.out
#\$ -j y
#\$ -pe mpich $jj[2]
#\$ -cwd
#\$ -p $jj[2]
#
ESP=$esphome
t0=`\$ESP/bin/Epoch`

test -d ~/.gmpi || mkdir ~/.gmpi
GMCONF=~/.gmpi/conf.\$JOB_ID
sgenodefile2gmconf \$PE_HOSTFILE >\$GMCONF
NP=\$(head -1 \$GMCONF)

echo \$t0 " S " $joblabel "  Seq# SEQNUM"

mkdir -p $workdir/bin
cp $esphome/bin/* $workdir/bin
cd $workdir

$timer mpirun.ch_gm --gm-kill 10 --gm-f \$GMCONF -np \$NP $cline

echo `\$ESP/bin/Epoch` " F " $joblabel "  Seq# SEQNUM"

rm -f \$GMCONF
EOF
#
#  end "here" document
#
	       		close(NQS);
		}
	}
}

1;
