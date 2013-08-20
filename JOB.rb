#!/usr/bin/ruby
 
require 'pp'


def get_job_code(job, type, output_dir, batch)
    nb_procs = job.procs_alloc
    duration = job.run_time
    job_id = job.job_id
    user_id = "%03d" % job.user_id
    
    if batch == 'OAR'    
        hostfile = "$OAR_NODE_FILE"
        connector = "oarsh"  
    elsif batch == 'SLURM'
         hostfile = "$SLURM_JOB_NODELIST"
         connector = "ssh"
    else
        return nil         
    end   
            
    if type == 'ior'
        return "mpirun -np #{nb_procs} --hostfile #{hostfile} --mca plm_rsh_agent '#{connector}' IOR -a MPIIO -t 1024K -b 1G -F -o #{output_dir}/execfile_job_#{job_id}"
    elsif type == 'sleep'
        return "srun -n #{nb_procs} sleep #{duration}"
#TODO: if doesn't work try this :         return "srun --uid=3#{user_id} -n #{nb_procs} sleep #{duration}"
    else
        return nil           
    end
end
