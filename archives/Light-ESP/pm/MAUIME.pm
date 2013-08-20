#
#---------------------------------------------------------
# MauiME-specific functions
#---------------------------------------------------------
#
use strict;
use warnings;

use BATCH;

package MAUIME;

our @ISA = qw{BATCH};

sub new {
	return bless  BATCH::new;
}

#----------------------------------------------------------------------
# getClusterStatus - uses 'showq' to get number of active PEs
# Returns an array of the following in this order:
#	Number of Active PEs	( $numActivePE )
#	Number of Active Nodes	( $numActiveNodes )
#	Number of Active Jobs	( $numActiveJobs )
#	Number of Queued Jobs	( $numQueuedJobs )
#----------------------------------------------------------------------
sub getClusterStatus {
	my ($numActivePE, $numActiveNodes, $numActiveJobs, $numQueuedJobs);
	open( SHOWQ, "/usr/local/mauime/bin/showq |");
	while( <SHOWQ> )
	{
		if ( /Active:/ )
		{
 			s/Active: (\d+)\/\((\d+)//;

			$numActiveNodes = $1;
			$numActivePE = $2;
		}
		if ( /ACTIVE JOBS:/ )
		{
			s/(\d+)$//;
			$numActiveJobs = $1;
		}
		if ( /QUEUED JOBS:/ )
		{
			s/(\d+)$//;
			$numQueuedJobs = $1;
		}
	}
	close( SHOWQ );
	return( $numActivePE, $numActiveNodes, $numActiveJobs, $numQueuedJobs );
	
}

#----------------------------------------------------------------------
# getrunning - some shorthand
#----------------------------------------------------------------------
sub getrunning {
	return (&getClusterStatus)[0];
}

#----------------------------------------------------------------------
# monitor_queues - uses &getClusterStatus to get state of the queues.
# Takes one argument: time to sleep in seconds before getting info
# and printing. With no argument there's no sleeping.
#----------------------------------------------------------------------
sub monitor_queues {
	my ($numActivePE, $unused, $numActiveJobs, $numQueuedJobs);

	sleep($_[1]) if  $_[1] != "";
	( $numActivePE, $unused, $numActiveJobs, $numQueuedJobs ) =
		&getClusterStatus;
	my $espdone = !( $numQueuedJobs || $numActiveJobs || $numActivePE );
	printf("%d  I  Runjobs: %d PEs %d  Queued: %d espdone: %d\n",
		main::epoch(), $numActiveJobs, $numActivePE, $numQueuedJobs);
	printf(main::LOG "%d  I  Runjobs: %d PEs: %d  Queued: %d espdone: %d\n",
		main::epoch(), $numActiveJobs, $numActivePE, $numQueuedJobs);
}


#
#  Fork and submit job
#
sub submit {
    my ($pid, $subcmd, $err, $doit);
    $subcmd = "mauisubmit " . $_[1] . ".cmd";
    $doit   = $_[2];

    if (!defined($pid=fork())) {
	print "Cannot fork!\n";
	exit(1);
    } elsif (!$pid) {
	chdir("jobmix/MAUIME") || die "cannot chdir!\n";
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

	my ($timer, $esphome, $espout, $scratch, $packed)
		= ($self->timer, $self->esphome, $self->espout,
			$self->scratch, $self->packed);
	foreach my $j (keys %{$self->jobdesc}) {
		my @jj = @{$self->jobdesc->{$j}};
		my $taskcount = $self->taskcount($jj[0]);
		my $cline = $self->command("$esphome/","$jj[2]");
		my $wlimit = int($jj[2]*1.50);
		for (my $i=0; $i < $jj[1]; $i++) {
			my $needed = $taskcount/$packed;
			my $nodes = "nodes=$needed:ppn=$packed";
			my $joblabel = $self->joblabel($j,$taskcount,$i);
			print STDERR "creating $joblabel\n" if $self->verbose;
			open(CMD, ">".$joblabel.".cmd");
			print CMD <<"EOF_CMD";
# Initial working directory and wallclock time
IWD == "$scratch"
WCLimit == "3600"
# Account stanza
Account == "benchmarkuser"
# Task geometry
Nodes == $needed
Tasks == $taskcount
TaskPerNode == $packed
# Feature requests
Arch == x86
OS == Linux
# MPI Myrinet job
JobType == "mpi.ch_gm"
# Launch script (SEE NOTE BELOW)
Exec == "$esphome/jobmix/$joblabel"
# NOTE: args, if any, are separated by whitespace ` '
#Args == ""
# Output (Notice the envvar references!)
Output == "$espout/$joblabel.out"
Error  == "$espout/$joblabel.err"
Log    == "$espout/$joblabel.log"
# Stdin tied to null
Input == "/dev/null"
EOF_CMD
			close CMD;

			open(SH, ">$joblabel");
			print SH <<"EOF_SH";
#!/bin/sh

MAUI_TASK_COUNT=$taskcount
export MAUI_TASK_COUNT

echo `$esphome/bin/Epoch` " START  " $joblabel "  Seq# SEQNUM"
mkdir -p $scratch

#test -d ~/.gmpi || mkdir ~/.gmpi
#GMCONF=~/.gmpi/conf.\$MAUI_JOB_ID
#
## create tasks file
#touch \$GMCONF
#for node in `echo \$MAUI_JOB_TASKS | sed -e 's/:/ /g'` ; do
#        echo \$node >> \$GMCONF
#done
#
#NP=\$(wc -l \$GMCONF | awk '{print \$1}')
#
#echo "tasks_file=\$GMCONF, NP=\$NP"
#
#$timer mpirun.ch_gm -machinefile \$GMCONF --gm-kill 10 -np \$NP $cline
#
#rm -f \$GMCONF

#$timer sh -x /usr/local/mauime/bin/runmpi_gm $cline
$timer /usr/local/mauime/bin/runmpi_gm $cline
echo `$esphome/bin/Epoch` " FINISH " $joblabel "  Seq# SEQNUM"
EOF_SH
			close SH;
			chmod 0755, "$joblabel";
		}
	}
}

1;
