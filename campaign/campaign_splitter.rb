#!/usr/bin/ruby

#require 'rubygems'
require 'getoptlong'
require 'pp'
require "../lib_swf.rb"


# Big number
$machine_bytes = ['foo'].pack('p').size
$machine_bits = $machine_bytes * 8
#$machine_max_unsigned =  2**$machine_bits - 1
$machine_max_signed = 2**($machine_bits-1) - 1
fix_session_threshold = $machine_max_signed
$algo = 'MAX'
#fix_batch_threshold = 60*20

opts = GetoptLong.new(  [ "--file","-f", GetoptLong::REQUIRED_ARGUMENT ],
                        ["--debug","-d", GetoptLong::NO_ARGUMENT],
                        ["--dev", GetoptLong::NO_ARGUMENT],
                        ["--help","-h", GetoptLong::NO_ARGUMENT])
opts.each do |option,value|
        if(option =="--file")
                $file=value
        end
        if(option =="--debug")
               $debug=true
        end
        if(option =="--dev")
               $dev=true
        end
        if (option =="--help")
                puts "--Usage--
Options: -f <file>      Load swf file
         -d             Debug Mode
         -h             This help
         "
                exit
        end
end


#### Dirty fetch of trace info
nb_procs = `cat #{$file} | grep MaxProcs| awk '{print $3}'`.to_i
nb_nodes = `cat #{$file} | grep MaxNodes| awk '{print $3}'`.to_i
$unixstarttime = `cat #{$file} | grep UnixStartTime| awk '{print $3}'`.to_i
####

# MODIF pour vinicius 
Job_Stretch =  Struct.new(
:job_id, :submit_time, :wait_time, :run_time, :procs_alloc, :cpu_time_used, :used_memory, :procs_req, :run_time_req, :mem_req, 
    :status, :user_id, :group_id, :exe_num, :queue_id, :partition_id, :preceding_job_id, :preceding_job_think_time, :stretch, :dependencies)


jobs = load_swf_file($file, nil, nil)
$output_file = "#{$file}.cgn" if !$debug
$output_file = "#{$file}.cgn.dbg" if $debug

users = Hash.new { |h, k| h[k] = Hash.new { |hash, key| hash[key] = [] } }
jobs.each_pair { |job_id, job_struct|
    if !(job_id =~ /^info/)
        users[job_struct.user_id][job_id] = job_struct
    end             
}


###
### Per user threshold info
###
### Fill the user threshold hash with fix values for init
user_session_threshold = {}
#user_batch_threshold = {}
users.each_pair{ |user_id, job_info|
    user_session_threshold[user_id] = fix_session_threshold
    #user_batch_threshold[user_id] = fix_batch_threshold
}
if !$user_threshold_file.nil?
    File.open($user_threshold_file) do |fp|
    fp.each do |line|
        key, value = line.chomp.split(" ")
        user_session_threshold[key.to_i] = value.to_i
    end
    end
end
######################################



### Functions ###
def get_sessions_MAX(nb_procs, users, user_session_threshold)
   user_sessions_batches = Hash.new { |user, hash_session| user[hash_session] = Hash.new { |session, hash_batch| session[hash_batch] = Hash.new { |batch, jobs| batch[jobs] = [] } } } 
   
   think_times = Hash.new { |user, hash_session| user[hash_session] = Hash.new { |session, hash_batch| session[hash_batch] = Hash.new { |info, value| info[value] = Hash.new()} } }
   
   
   #events_stretch = Hash.new { |hash, key| hash[key] = []}
   events_stretch = Hash.new
   
    
   users.each_pair{ |user_id, jobs_hash|
     
    max_job_end = -1
    sessions_cpt = 0
    batch_cpt = 0
    last_job_submit = -1   
    first_job_submit = -1
    all_jobs_dependencies = Hash.new{|hash, key| hash[key] = []}              
                  
                          
    jobs_hash.sort.map do |job_id, job|                      
               
        current_job_submit = job.submit_time.to_i
        current_job_end = job.submit_time.to_i+job.wait_time.to_i+job.run_time.to_i
                  
        # MODIF pour vinicius                
        job_with_stretch = Job_Stretch.new
        job_with_stretch.job_id = job.job_id   
        job_with_stretch.submit_time = job.submit_time
        job_with_stretch.wait_time = job.wait_time
        job_with_stretch.run_time = job.run_time
        job_with_stretch.procs_alloc = job.procs_alloc
        job_with_stretch.cpu_time_used = job.cpu_time_used
        job_with_stretch.used_memory = job.used_memory
        job_with_stretch.procs_req = job.procs_req
        job_with_stretch.run_time_req = job.run_time_req
        job_with_stretch.mem_req = job.mem_req
        job_with_stretch.status = job.status
        job_with_stretch.user_id = job.user_id
        job_with_stretch.group_id = job.group_id
        job_with_stretch.exe_num = job.exe_num
        job_with_stretch.queue_id = job.queue_id
        job_with_stretch.partition_id = job.partition_id
        job_with_stretch.preceding_job_id = job.preceding_job_id
        job_with_stretch.preceding_job_think_time = job.preceding_job_think_time    
        job_with_stretch.dependencies = []
                  
        if (job.run_time.to_i !=0)          
            #stretch = ((current_job_end - current_job_submit) * nb_procs).to_f / (job.procs_alloc.to_i*job.run_time.to_i).to_f
            stretch = ((current_job_end - current_job_submit)).to_f / (job.run_time.to_i).to_f
        else 
            stretch = 0
        end
        job_with_stretch.stretch = stretch          
        #events_stretch[current_job_submit] = stretch if ((stretch !=0) && (!events_stretch.has_key?(current_job_submit) || (stretch > events_stretch[current_job_submit])))
        #events_stretch[current_job_end] = stretch  if ((stretch !=0) && (!events_stretch.has_key?(current_job_end) || (stretch > events_stretch[current_job_end])))     
        #          
                  
           
        if(max_job_end == -1)
            # Do nothing, it is the first job for this user, thus, new session and new batch
            first_job_submit = current_job_submit      
        elsif(current_job_submit - max_job_end < 0)
            # Do nothing, they are in the same batch in the same session
        elsif((current_job_submit - max_job_end >= 0) && (current_job_submit - max_job_end < user_session_threshold[user_id]))
            # start a new batch   
            batch_cpt = batch_cpt + 1
            first_job_submit = current_job_submit      
        else
            # start a new session and batch, reset batch counter      
            sessions_cpt = sessions_cpt + 1
            batch_cpt = 0
            first_job_submit = current_job_submit      
        end 
           
        curr_job_dependencies = []          
        ### manage jobs dependencies  
        # first fill the whole dependencies list all_jobs_dependencies
        user_sessions_batches[user_id][sessions_cpt][batch_cpt].each{ |job_in_the_batch|   # for each job in the batch submitted before it, compute the deps list
                this_job_end = job_in_the_batch.submit_time.to_i+job_in_the_batch.wait_time.to_i+job_in_the_batch.run_time.to_i 
                if (current_job_submit > this_job_end)# && job.queue_id == job_in_the_batch.queue_id) # TEST: add a constraint on the deps, they have to be submitted in the same queue
                    all_jobs_dependencies[job.job_id.to_i] << job_in_the_batch.job_id.to_i
                end
        }
        #   
        # then, remove chains
         if(all_jobs_dependencies[job.job_id.to_i].any?) # if the deps list is not empty...          
             current_job_dependencies_transitives = []    
             all_jobs_dependencies[job.job_id.to_i].each{ |job_depending_id|
                 current_job_dependencies_transitives.concat(all_jobs_dependencies[job_depending_id])
             }
             curr_job_dependencies = all_jobs_dependencies[job.job_id.to_i] - current_job_dependencies_transitives
         end          
        ###
        # job_with_stretch.dependencies = all_jobs_dependencies[job.job_id.to_i]
        job_with_stretch.dependencies = curr_job_dependencies
                  
        # update max_job values       
        if(current_job_end >= max_job_end)
           max_job_end = current_job_end
           think_times[user_id][sessions_cpt][batch_cpt]['end'] = max_job_end
        end 
                  
        last_job_submit = current_job_submit if (last_job_submit<current_job_submit)           
        think_times[user_id][sessions_cpt][batch_cpt]['first_start'] = first_job_submit  
                  
                  
        # TT is either calculated from the first job or the last job start
        #think_times[user_id][sessions_cpt][batch_cpt]['start'] = last_job_submit 
        think_times[user_id][sessions_cpt][batch_cpt]['start'] = first_job_submit          
        #         
                  
        # add the job to the right session/batch for this user
        user_sessions_batches[user_id][sessions_cpt][batch_cpt] << job_with_stretch
      
    end
    
  }
  return user_sessions_batches, think_times, events_stretch
    
end    

###

def print_to_stdout_siminput(nb_procs, user_sessions_batches, think_times)
    
  # to reset the user_ids, now start from 0 and is incremental
  user_id_cpt = 0
    
  events_stretch = Hash.new
  user_stretches = Hash.new { |user, stretches| user[stretches] = [] }
  users_mapping = Hash.new
    
  File.open($output_file, "w") {|f|  
    f.write "#nbcores\n#{nb_procs}\n"
    f.write "#nbusers\n#{user_sessions_batches.keys.count}\n"
    f.write "#unixstarttime\n#{$unixstarttime}\n"
    
    user_sessions_batches.sort.map{ |user_id, sessions|
                                    
        f.write "User real_id=#{user_id} -- logical_id=#{user_id_cpt}:\n" if $debug  
        users_mapping[user_id] = user_id_cpt                          
        f.write "#{user_id_cpt}:"        if !$debug    # set new user_id       
        user_id_cpt = user_id_cpt + 1                          
        sessions.sort.map{ |session_id, batch|
            
            if session_id>0        
                tt_session = (think_times[user_id][session_id][0]['start']) - (think_times[user_id][session_id-1][think_times[user_id][session_id-1].keys.max]['end'])
            else
                tt_session = -1
            end               
            f.write "\tsession #{session_id} start at #{think_times[user_id][session_id][0]['start']}, TT=#{tt_session}\n"  if $debug && (tt_session>=0)
            f.write "\tsession #{session_id} start at #{think_times[user_id][session_id][0]['start']}\n"  if $debug && (tt_session<0)
            f.write "|#{tt_session}|" if !$debug && (tt_session>=0)
            batch.sort.map{ |batch_id, job| 
                                            
                if batch_id>0                                 
                    tt_batch = (think_times[user_id][session_id][batch_id]['start']) - (think_times[user_id][session_id][batch_id-1]['end'])
                else
                    tt_batch = "n/a"
                end   
                
                batch_sa = 0
                batch_rt = 0
                batch_cores = 0
                                          
                f.write "\t\tbatch #{batch_id} start at #{think_times[user_id][session_id][batch_id]['start']}, TT=#{tt_batch}\n"   if $debug && (tt_batch.is_a? Integer)
                f.write "\t\tbatch #{batch_id} start at #{think_times[user_id][session_id][batch_id]['start']}\n"   if $debug && (tt_batch == "n/a")          
                         
                f.write ";#{tt_batch};" if !$debug && (tt_batch.is_a? Integer) #&& batch_id != think_times[user_id][session_id].keys.max
                # TEST: TT=0 in any case
                #f.write ";#{0};" if !$debug && batch_id != 0      
                          
                job.each_with_index{ |current_job, index|
                                     
                    dependencies_as_string = "("
                    current_job.dependencies.each{|dep| dependencies_as_string << "#{dep},"}
                    dependencies_as_string = dependencies_as_string.chop if current_job.dependencies.length!=0
                    dependencies_as_string << ")"                                   
                                     
                    f.write "\t\t\tjob #{current_job.job_id}, submit=#{current_job.submit_time}, resources=#{current_job.procs_alloc}, wait=#{current_job.wait_time}, runtime=#{current_job.run_time}, walltime=#{current_job.run_time_req}, job_stretch=#{sprintf('%.3f', current_job.stretch)}, dependencies = #{dependencies_as_string}\n"      if $debug
                    f.write "[#{current_job.job_id},#{current_job.submit_time},#{current_job.procs_alloc},#{current_job.run_time_req},#{current_job.run_time},#{dependencies_as_string}]"   if !$debug
                    #f.write "[#{current_job.submit_time},#{current_job.procs_alloc},#{current_job.run_time_req},#{current_job.run_time}]"   if !$debug
                    f.write ","  if !$debug && index<job.length-1
                    
                    batch_sa += current_job.run_time * current_job.procs_alloc
                    batch_rt += current_job.run_time 
                    batch_cores += current_job.procs_alloc if current_job.run_time!=0
                }
                if batch_cores > nb_procs   # we take the min between cores required and cores total available
                    work = nb_procs 
                else
                    work = batch_cores
                end          
                          
                if (batch_sa !=0)          
                    stretch_batch = (think_times[user_id][session_id][batch_id]['end'] - think_times[user_id][session_id][batch_id]['first_start']).to_f / (batch_sa.to_f/work.to_f)         
                else
                    stretch_batch = 0       
                end          
                f.write "\t\tbatch #{batch_id} stop at #{think_times[user_id][session_id][batch_id]['end']}, batch_stretch=#{sprintf('%.3f', stretch_batch)}\n"            if $debug 
                        
                          
                batch_sub = think_times[user_id][session_id][batch_id]['first_start']
                batch_end = think_times[user_id][session_id][batch_id]['end']        
                          
                #events_stretch[batch_sub] = stretch_batch if ((stretch_batch !=0) && (!events_stretch.has_key?(batch_sub) || (stretch_batch > events_stretch[batch_sub])))
                events_stretch[batch_end] = stretch_batch if ((stretch_batch !=0) && (!events_stretch.has_key?(batch_end) || (stretch_batch > events_stretch[batch_end])))   
                          
                user_stretches[user_id] << stretch_batch          
                                                  
#                 events_stretch[batch_sub] = 0 
#                 events_stretch[batch_end] = 0          
                          
            }
            last_session_batch = think_times[user_id][session_id].keys.max
            f.write "\tsession #{session_id} stop at #{think_times[user_id][session_id][last_session_batch]['end']}, Session Duration=#{think_times[user_id][session_id][last_session_batch]['end'] - think_times[user_id][session_id][0]['start']}\n"   if $debug
            f.write "|"  if !$debug && (session_id == think_times[user_id].keys.max)
        }
        f.write "################################################################################\n"   if $debug
        f.write "\n"        if !$debug                           
    }
  }
  return events_stretch, user_stretches, users_mapping
end



######## MAIN #########
user_sessions_batches, think_times, events_stretch_jobs = get_sessions_MAX(nb_procs, users, user_session_threshold)

#test_if_bad_batch_exists(think_times) if $debug
user_stretches = Hash.new { |user, stretches| user[stretches] = [] }
users_mapping = Hash.new
events_stretch_batch, user_stretches, users_mapping = print_to_stdout_siminput(nb_procs, user_sessions_batches, think_times)

# user_sessions_batches.sort.map{ |user_id, sessions|
#     sessions.sort.map{ |session_id, batch|
#         batch.sort.map{ |batch_id, job| 
#             batch_sa = 0
#             batch_rt = 0
#             batch_cores = 0                 
#             job.each_with_index{ |current_job, index|
# 
#                 batch_sa += current_job.run_time * current_job.procs_alloc
#                 batch_rt += current_job.run_time 
#                 batch_cores += current_job.procs_alloc if current_job.run_time!=0
#             }
#             if batch_cores > nb_procs   # we take the min between cores required and cores total available
#                 work = nb_procs 
#             else
#                 work = batch_cores
#             end          
#                         
#             if (batch_sa !=0)          
#                 stretch_batch = ((think_times[user_id][session_id][batch_id]['end'] - think_times[user_id][session_id][batch_id]['first_start'])*work).to_f / batch_sa.to_f         
#             else
#                 stretch_batch = 0       
#             end          
#                     
#             batch_sub = think_times[user_id][session_id][batch_id]['first_start']
#             batch_end = think_times[user_id][session_id][batch_id]['end']        
# 
#             #events_stretch_batch.sort.map{ |date, value| 
#             events_stretch_batch.reject {|date ,value| (date<batch_sub && date>batch_end) }.each_pair{|date, value|          
#                 
# #                 if(date<batch_sub)                          
# #                     next                     
# #                 elsif(date>batch_end)                         
# #                     break
# #                 else
#                     events_stretch_batch[date] = stretch_batch if (stretch_batch > events_stretch_batch[date])
# #                 end                          
#             }                               
#         }                
#     }                   
# }                                



File.open("#{$file}.stretch", "w") {|f|
    events_stretch_batch.sort.map{|key, value|
        line = "#{key+$unixstarttime} #{value}\n"
        f.write(line)
    }
}

File.open("#{$file}.users_mapping", "w") {|f|
    users_mapping.sort.map{|key, value|
        line = "#{key} #{value}\n"
        f.write(line)
    }
}

File.open("#{$file}.users_mean_stretch", "w") {|f|
    user_stretches.sort.map{|user, stretches|
        total = stretches.inject(:+)
        len = stretches.length
        if(len!=0)
            average = total.to_f / len
            line = "#{user} #{average}\n"
            f.write(line) if average!=0
        end
    }
}
File.open("#{$file}.users_max_stretch", "w") {|f|
    user_stretches.sort.map{|user, stretches|
        line = "#{user} #{stretches.max}\n"
        f.write(line) if stretches.max!=0
    }
}

File.open("#{$file}.users_median_stretch", "w") {|f|
    user_stretches.sort.map{|user, stretches|
        total = stretches.inject(:+)
        len = stretches.length
        if(len!=0)
            average = total.to_f / len
            sorted = stretches.sort
            median = len % 2 == 1 ? sorted[len/2] : (sorted[len/2 - 1] + sorted[len/2]).to_f / 2           
            line = "#{user} #{median}\n"
            f.write(line) if median!=0
        end
    }
}

