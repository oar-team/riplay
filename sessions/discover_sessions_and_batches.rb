#!/usr/bin/ruby

#require 'rubygems'
require 'getoptlong'
require 'pp'
require_relative "../lib_swf.rb"


fix_session_threshold = 60*60*0
$algo = 'ARR'
#fix_batch_threshold = 60*20

opts = GetoptLong.new(  [ "--file","-f", GetoptLong::REQUIRED_ARGUMENT ],
                        [ "--algorithm","-a", GetoptLong::REQUIRED_ARGUMENT ],
                        ["--threshold","-t", GetoptLong::REQUIRED_ARGUMENT ],
                        ["--user_threshold_file","-u", GetoptLong::REQUIRED_ARGUMENT ],
                        ["--write_user_threshold","-w", GetoptLong::REQUIRED_ARGUMENT ],
                        ["--debug","-d", GetoptLong::NO_ARGUMENT],
                        ["--dev", GetoptLong::NO_ARGUMENT],
                        ["--swf","-s", GetoptLong::NO_ARGUMENT],
                        ["--help","-h", GetoptLong::NO_ARGUMENT])
opts.each do |option,value|
        if(option =="--file")
                $file=value
        elsif(option =="--algorithm")
                $algo=value
        elsif(option =="--threshold")
                fix_session_threshold=value.to_i
        elsif(option =="--user_threshold_file")
                $user_threshold_file=value
        elsif(option =="--write_user_threshold")
                $write_user_threshold=value
        end
        if(option =="--debug")
               $debug=true
        end
        if(option =="--dev")
               $dev=true
        end
        if(option =="--swf")
               $swf=true
        end
        if (option =="--help")
                puts "Usage: ./discover_sessions_and_batches.rb
options: -f <file>      Load swf file
         -a <algo>      Specify algo to use for session detection, available are: MAX, LAST, ARR, MINMAX (default=ARR)
         -t <value>     Threshold in seconds for session detection (default=0 secs)
         -u <file>      Specify the file to read for per user thresholds (format: <user_id> <threshold_value>\\n)
         -w <file>      Specify the file to write user thresholds (mean of sessions TT)
         -s             Export result to swf files 
         -d             Debug Mode
         -h             This help
         "
                exit
        end
end


#### Dirty fetch of trace info
nb_procs = `cat #{$file} | grep MaxProcs| awk '{print $3}'`.to_i
nb_nodes = `cat #{$file} | grep MaxNodes| awk '{print $3}'`.to_i
####

jobs = load_swf_file($file, nil, nil)

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


# Big number
$machine_bytes = ['foo'].pack('p').size
$machine_bits = $machine_bytes * 8
#$machine_max_unsigned =  2**$machine_bits - 1
$machine_max_signed = 2**($machine_bits-1) - 1



### Functions ###
def get_sessions_MAX(users, user_session_threshold)
   user_sessions_batches = Hash.new { |user, hash_session| user[hash_session] = Hash.new { |session, hash_batch| session[hash_batch] = Hash.new { |batch, jobs| batch[jobs] = [] } } } 
   
   think_times = Hash.new { |user, hash_session| user[hash_session] = Hash.new { |session, hash_batch| session[hash_batch] = Hash.new { |info, value| info[value] = Hash.new()} } }
    
   users.each_pair{ |user_id, jobs_hash|
     
    max_job_end = -1
    sessions_cpt = 0
    batch_cpt = 0
                          
    jobs_hash.sort.map do |job_id, job|                      
               
        current_job_submit = job.submit_time.to_i
        current_job_end = job.submit_time.to_i+job.wait_time.to_i+job.run_time.to_i       
           
        if(max_job_end == -1)
            # Do nothing, it is the first job for this user, thus, new session and new batch
            think_times[user_id][sessions_cpt][batch_cpt]['start'] = current_job_submit   #start date of the new batch
        elsif(current_job_submit - max_job_end < 0)
            # Do nothing, they are in the same batch in the same session
        elsif((current_job_submit - max_job_end >= 0) && (current_job_submit - max_job_end < user_session_threshold[user_id]))
            # start a new batch
            if $debug      
                ### TEST if the previous batch has non overlapping jobs
                earliest_finish_time = $machine_max_signed                
                user_sessions_batches[user_id][sessions_cpt][batch_cpt].each{ |currjob|
                        currjob_end = currjob.submit_time.to_i+currjob.wait_time.to_i+currjob.run_time.to_i 
                        earliest_finish_time = currjob_end if (earliest_finish_time>currjob_end)
                }                                                              
                last_batch_job = user_sessions_batches[user_id][sessions_cpt][batch_cpt][-1]
                last_batch_job_arrival = last_batch_job.submit_time.to_i
                if (last_batch_job_arrival > earliest_finish_time) 
                    think_times[user_id][sessions_cpt][batch_cpt]['bad'] = 1
                end
                ###  
            end      
            batch_cpt = batch_cpt + 1
            think_times[user_id][sessions_cpt][batch_cpt]['start'] = current_job_submit   #start date of the new batch
        else
            # start a new session and batch, reset batch counter 
            if $debug                  
                ### TEST if the previous batch has non overlapping jobs
                earliest_finish_time = $machine_max_signed                
                user_sessions_batches[user_id][sessions_cpt][batch_cpt].each{ |currjob|
                        currjob_end = currjob.submit_time.to_i+currjob.wait_time.to_i+currjob.run_time.to_i 
                        earliest_finish_time = currjob_end if (earliest_finish_time>currjob_end)
                }                                                              
                last_batch_job = user_sessions_batches[user_id][sessions_cpt][batch_cpt][-1]
                last_batch_job_arrival = last_batch_job.submit_time.to_i
                if (last_batch_job_arrival > earliest_finish_time) 
                    think_times[user_id][sessions_cpt][batch_cpt]['bad'] = 1
                end
                ###
            end      
            sessions_cpt = sessions_cpt + 1
            batch_cpt = 0
            think_times[user_id][sessions_cpt][batch_cpt]['start'] = current_job_submit   #start date of the new batch
        end 
               
        # update max_job values       
        if(current_job_end > max_job_end)
           max_job_end = current_job_end
           think_times[user_id][sessions_cpt][batch_cpt]['end'] = max_job_end
        end        
               
        # add the job to the right session/batch for this user
        user_sessions_batches[user_id][sessions_cpt][batch_cpt] << job
      
    end
    
  }
  return user_sessions_batches, think_times 
    
end    

###

# With this algo, a job is in a batch if its arrival date is before the job (of this batch) that finishes the earliest
# TODO: change the TT ref value to test the algo behavior: can be last_job_submit, max_job_end, min_job_end or ?  
# the end of a batch is the submission date of the last job submitted
# OR
# the end of a batch is the end date of the last job to end
# OR
# the end of a batch is the end date of the earliest job to end +++
def get_sessions_MINMAX(users, user_session_threshold)
   user_sessions_batches = Hash.new { |user, hash_session| user[hash_session] = Hash.new { |session, hash_batch| session[hash_batch] = Hash.new { |batch, jobs| batch[jobs] = [] } } } 
   
   think_times = Hash.new { |user, hash_session| user[hash_session] = Hash.new { |session, hash_batch| session[hash_batch] = Hash.new { |info, value| info[value] = Hash.new()} } }
    
   users.each_pair{ |user_id, jobs_hash|
     
    min_job_end = nil
    last_job_submit = -1
    max_job_end = -1
                  
    sessions_cpt = 0
    batch_cpt = 0
                                 
    jobs_hash.sort.map do |job_id, job|                      
               
        current_job_submit = job.submit_time.to_i
        current_job_end = job.submit_time.to_i+job.wait_time.to_i+job.run_time.to_i
           
        if(min_job_end.nil?)
            # Do nothing, it is the first job for this user, thus, new session and new batch
            min_job_end = current_job_end      
            think_times[user_id][sessions_cpt][batch_cpt]['start'] = current_job_submit   #start date of the new batch
        elsif(current_job_submit - min_job_end < 0)
            # Do nothing, they are in the same batch in the same session                  
        #elsif((current_job_submit - min_job_end >= 0) && (current_job_submit - min_job_end < user_session_threshold[user_id]))  # We test the session with the TT
        #elsif((current_job_submit - min_job_end >= 0) && (current_job_submit < max_job_end))  # same session if there is still a job that is running
        elsif((current_job_submit - min_job_end >= 0) && (current_job_submit - max_job_end < user_session_threshold[user_id]))  # same session if overlapping batch or TT < threshold (can also be 0)        
            # start a new batch
            if $debug      
                ### TEST if the previous batch has non overlapping jobs
                earliest_finish_time = $machine_max_signed                
                user_sessions_batches[user_id][sessions_cpt][batch_cpt].each{ |currjob|
                        currjob_end = currjob.submit_time.to_i+currjob.wait_time.to_i+currjob.run_time.to_i 
                        earliest_finish_time = currjob_end if (earliest_finish_time>currjob_end)
                }                                                              
                last_batch_job = user_sessions_batches[user_id][sessions_cpt][batch_cpt][-1]
                last_batch_job_arrival = last_batch_job.submit_time.to_i
                if (last_batch_job_arrival > earliest_finish_time) 
                    think_times[user_id][sessions_cpt][batch_cpt]['bad'] = 1
                end
                ###  
            end    
            #think_times[user_id][sessions_cpt][batch_cpt]['end'] = max_job_end ###  TT is calculated from the end of the last job to finish    
            batch_cpt = batch_cpt + 1
            min_job_end = $machine_max_signed      
            think_times[user_id][sessions_cpt][batch_cpt]['start'] = current_job_submit   #start date of the new batch        
                  
        else
            # start a new session and batch, reset batch counter 
            if $debug                  
                ### TEST if the previous batch has non overlapping jobs
                earliest_finish_time = $machine_max_signed                
                user_sessions_batches[user_id][sessions_cpt][batch_cpt].each{ |currjob|
                        currjob_end = currjob.submit_time.to_i+currjob.wait_time.to_i+currjob.run_time.to_i 
                        earliest_finish_time = currjob_end if (earliest_finish_time>currjob_end)
                }                                                              
                last_batch_job = user_sessions_batches[user_id][sessions_cpt][batch_cpt][-1]
                last_batch_job_arrival = last_batch_job.submit_time.to_i
                if (last_batch_job_arrival > earliest_finish_time) 
                    think_times[user_id][sessions_cpt][batch_cpt]['bad'] = 1
                end
                ###
            end      
            #think_times[user_id][sessions_cpt][batch_cpt]['end'] = max_job_end ### we set the previous session end date as the last running job end date      
            sessions_cpt = sessions_cpt + 1
            batch_cpt = 0
            min_job_end = $machine_max_signed      
            think_times[user_id][sessions_cpt][batch_cpt]['start'] = current_job_submit   #start date of the new batch
        end 

        # update min_job value       
        if(current_job_end < min_job_end)
           min_job_end = current_job_end
        end
                  
        # update max_job_end value       
        if(current_job_end > max_job_end)
           max_job_end = current_job_end
        end
             
        last_job_submit = current_job_submit if (last_job_submit<current_job_submit)          
        #think_times[user_id][sessions_cpt][batch_cpt]['end'] = min_job_end ###  TT is calculated from the end of the first job to finish
        think_times[user_id][sessions_cpt][batch_cpt]['end'] = max_job_end ###  TT is calculated from the end of the last job to finish    
                  
        # add the job to the right session/batch for this user
        user_sessions_batches[user_id][sessions_cpt][batch_cpt] << job
      
    end
    
  }
  return user_sessions_batches, think_times 
    
end    


###
# detect sessions based on arrival time and Threshold
# detect batch based on MAX approach
#
def get_sessions_ARR(users, user_session_threshold)
   user_sessions_batches = Hash.new { |user, hash_session| user[hash_session] = Hash.new { |session, hash_batch| session[hash_batch] = Hash.new { |batch, jobs| batch[jobs] = [] } } } 
   
   think_times = Hash.new { |user, hash_session| user[hash_session] = Hash.new { |session, hash_batch| session[hash_batch] = Hash.new { |info, value| info[value] = Hash.new()} } }
    
   users.each_pair{ |user_id, jobs_hash|
     
    max_job_end = -1
    sessions_cpt = 0
    batch_cpt = 0
    last_submit = -1
                          
    jobs_hash.sort.map do |job_id, job|                      
               
        current_job_submit = job.submit_time.to_i
        current_job_end = job.submit_time.to_i+job.wait_time.to_i+job.run_time.to_i       
           
        if(last_submit == -1)
            # Do nothing, it is the first job for this user, thus, new session and new batch
            think_times[user_id][sessions_cpt][batch_cpt]['start'] = current_job_submit   #start date of the new batch    
        elsif(current_job_submit-last_submit > user_session_threshold[user_id]) 
            # start a new session and batch, reset batch counter
            if $debug                  
                ### TEST if the previous batch has non overlapping jobs
                earliest_finish_time = $machine_max_signed                
                user_sessions_batches[user_id][sessions_cpt][batch_cpt].each{ |currjob|
                        currjob_end = currjob.submit_time.to_i+currjob.wait_time.to_i+currjob.run_time.to_i 
                        earliest_finish_time = currjob_end if (earliest_finish_time>currjob_end)
                }                                                              
                last_batch_job = user_sessions_batches[user_id][sessions_cpt][batch_cpt][-1]
                last_batch_job_arrival = last_batch_job.submit_time.to_i
                if (last_batch_job_arrival > earliest_finish_time) 
                    think_times[user_id][sessions_cpt][batch_cpt]['bad'] = 1
                end
                ###
            end 
                  
            sessions_cpt = sessions_cpt + 1
            batch_cpt = 0   
            think_times[user_id][sessions_cpt][batch_cpt]['start'] = current_job_submit   #start date of the new batch  
            #think_times[user_id][sessions_cpt-1][think_times[user_id][sessions_cpt-1].keys.max]['end'] = last_submit          #finish previous session  
        else
            if(current_job_submit > max_job_end)
                # start a new batch  
                if $debug                  
                    ### TEST if the previous batch has non overlapping jobs
                    earliest_finish_time = $machine_max_signed                
                    user_sessions_batches[user_id][sessions_cpt][batch_cpt].each{ |currjob|
                            currjob_end = currjob.submit_time.to_i+currjob.wait_time.to_i+currjob.run_time.to_i 
                            earliest_finish_time = currjob_end if (earliest_finish_time>currjob_end)
                    }                                                              
                    last_batch_job = user_sessions_batches[user_id][sessions_cpt][batch_cpt][-1]
                    last_batch_job_arrival = last_batch_job.submit_time.to_i
                    if (last_batch_job_arrival > earliest_finish_time) 
                        think_times[user_id][sessions_cpt][batch_cpt]['bad'] = 1
                    end
                    ###
                end 
                  
                batch_cpt = batch_cpt + 1
                think_times[user_id][sessions_cpt][batch_cpt]['start'] = current_job_submit   #start date of the new batch                  
            else
                # Do nothing, they are in the same batch in the same session
            end      
                 
        end          
                                               
        # update max_job values       
        if(current_job_end > max_job_end)
           max_job_end = current_job_end
        end   
                       
        think_times[user_id][sessions_cpt][batch_cpt]['end'] = current_job_submit
                 
        # add the job to the right session/batch for this user
        user_sessions_batches[user_id][sessions_cpt][batch_cpt] << job
        last_submit = current_job_submit          
      
    end
    
  }
  return user_sessions_batches, think_times 
    
end

# def get_sessions_ARR(users, user_session_threshold)
#     user_sessions_batches = Hash.new { |user, hash_session| user[hash_session] = Hash.new { |session, hash_batch| session[hash_batch] = Hash.new { |batch, jobs| batch[jobs] = [] } } } 
#    
#     think_times = Hash.new { |user, hash_session| user[hash_session] = Hash.new { |session, hash_batch| session[hash_batch] = Hash.new { |info, value| info[value] = Hash.new()} } }
# 
#     users.each_pair{ |user_id, jobs_hash|
#         last_submit = -1
#         sessions_cpt = 0
#         batch_cpt = 0        
#         jobs_hash.sort.map do |job_id, job|       
#             current_job_submit = job.submit_time.to_i                   
#             if((last_submit != -1) && (job.submit_time.to_i-last_submit.to_i > user_session_threshold[user_id])) # interarrival over threshold, start new session
# 
#                 if $debug                  
#                     ### TEST if the previous batch has non overlapping jobs
#                     earliest_finish_time = $machine_max_signed                
#                     user_sessions_batches[user_id][sessions_cpt][batch_cpt].each{ |currjob|
#                             currjob_end = currjob.submit_time.to_i+currjob.wait_time.to_i+currjob.run_time.to_i 
#                             earliest_finish_time = currjob_end if (earliest_finish_time>currjob_end)
#                     }                                                              
#                     last_batch_job = user_sessions_batches[user_id][sessions_cpt][batch_cpt][-1]
#                     last_batch_job_arrival = last_batch_job.submit_time.to_i
#                     if (last_batch_job_arrival > earliest_finish_time) 
#                         think_times[user_id][sessions_cpt][batch_cpt]['bad'] = 1
#                     end
#                     ###
#                 end 
# 
#                 sessions_cpt = sessions_cpt+1       
#                 think_times[user_id][sessions_cpt][0]['start'] = current_job_submit   #start new session
#                 think_times[user_id][sessions_cpt-1][0]['end'] = last_submit          #finish previous session   
#             end
#                 
#             user_sessions_batches[user_id][sessions_cpt][0] << job   # only one batch for this algorithm
#             last_submit = current_job_submit
#             
#         end
#         
#     }
#     return user_sessions_batches, think_times 
#     
# end    


###

def get_sessions_LAST(users, user_session_threshold)
    user_sessions_batches = Hash.new { |user, hash_session| user[hash_session] = Hash.new { |session, hash_batch| session[hash_batch] = Hash.new { |batch, jobs| batch[jobs] = [] } } } 
   
    think_times = Hash.new { |user, hash_session| user[hash_session] = Hash.new { |session, hash_batch| session[hash_batch] = Hash.new { |info, value| info[value] = Hash.new()} } }

    users.each_pair{ |user_id, jobs_hash|
        
        last_job_submit = -1
        last_job_end = -1
        sessions_cpt = 0
        batch_cpt = 0
                            
        jobs_hash.sort.map do |job_id, job|                      
                
            current_job_submit = job.submit_time.to_i
            current_job_end = job.submit_time.to_i+job.wait_time.to_i+job.run_time.to_i       
            
            if(last_job_end == -1)
                # Do nothing, it is the first job for this user, thus, new session and new batch
                think_times[user_id][sessions_cpt][batch_cpt]['start'] = current_job_submit   #start date of the new batch
            elsif(current_job_submit - last_job_end < 0)
                # Do nothing, they are in the same batch in the same session
            elsif((current_job_submit - last_job_end >= 0) && (current_job_submit - last_job_end < user_session_threshold[user_id]))
                # start a new batch
                if $debug                   
                    ### TEST if the previous batch has non overlapping jobs
                    earliest_finish_time = $machine_max_signed                
                    user_sessions_batches[user_id][sessions_cpt][batch_cpt].each{ |currjob|
                        currjob_end = currjob.submit_time.to_i+currjob.wait_time.to_i+currjob.run_time.to_i 
                        earliest_finish_time = currjob_end if (earliest_finish_time>currjob_end)
                    }                                                              
                    last_batch_job = user_sessions_batches[user_id][sessions_cpt][batch_cpt][-1]
                    last_batch_job_arrival = last_batch_job.submit_time.to_i
                    if (last_batch_job_arrival > earliest_finish_time) 
                    think_times[user_id][sessions_cpt][batch_cpt]['bad'] = 1
                    end
                    ###   
                end   
                batch_cpt = batch_cpt + 1
                think_times[user_id][sessions_cpt][batch_cpt]['start'] = current_job_submit   #start date of the new batch
            else
                # start a new session and batch, reset batch counter     
                if $debug               
                    ### TEST if the previous batch has non overlapping jobs
                    earliest_finish_time = $machine_max_signed                
                    user_sessions_batches[user_id][sessions_cpt][batch_cpt].each{ |currjob|
                        currjob_end = currjob.submit_time.to_i+currjob.wait_time.to_i+currjob.run_time.to_i 
                        earliest_finish_time = currjob_end if (earliest_finish_time>currjob_end)
                    }                                                              
                    last_batch_job = user_sessions_batches[user_id][sessions_cpt][batch_cpt][-1]
                    last_batch_job_arrival = last_batch_job.submit_time.to_i
                    if (last_batch_job_arrival > earliest_finish_time) 
                    think_times[user_id][sessions_cpt][batch_cpt]['bad'] = 1
                    end
                    ###
                end   
                sessions_cpt = sessions_cpt + 1
                batch_cpt = 0
                think_times[user_id][sessions_cpt][batch_cpt]['start'] = current_job_submit   #start date of the new batch
            end 
                
            # update last_job values       
            
            last_job_end = current_job_end
            last_job_submit = current_job_submit
            think_times[user_id][sessions_cpt][batch_cpt]['end'] = last_job_end
                    
               
            # add the job to the right session/batch for this user
            user_sessions_batches[user_id][sessions_cpt][batch_cpt] << job
        
        end
        
    }
    return user_sessions_batches, think_times 
    
end 



def test_if_bad_batch_exists(think_times)
   global_batch_counter = 0 
   global_bad_batch_counter = 0
   think_times.sort.map{ |user_id, sessions|
       batch_counter = 0 
       bad_batch_counter = 0
                         
       sessions.sort.map{ |session_id, batch|                          
           batch.sort.map{ |batch_id, info|
                batch_counter = batch_counter + 1
                global_batch_counter = global_batch_counter + 1
      
                if (info.has_key?('bad'))
                    bad_batch_counter = bad_batch_counter + 1  
                    global_bad_batch_counter = global_bad_batch_counter + 1
                end        
           }
       }
       bad_score = bad_batch_counter.to_f/batch_counter.to_f * 100
       print "#non overlapping batches for user #{user_id} = #{sprintf('%.2f', bad_score)}%\n"                
                       
   }
   bad_score = global_bad_batch_counter.to_f/global_batch_counter.to_f * 100
   print "#non overlapping batches for all users = #{sprintf('%.2f', bad_score)}%\n"
    
end


### Display results

def print_user_sessions_TT(think_times)
    user_threshold = {}
    File.open($write_user_threshold, "w") {|f|
    print "\n################################################################################\n" if $debug
    print "Sessions TT per user:\n" if $debug
    print "################################################################################\n" if $debug
    think_times.sort.map{ |user_id, sessions|
      print "#{user_id}\n" if $debug
      current_user_tt_array = []                  
      sessions.sort.map{ |session_id, batch|
        if session_id>0        
            tt_session = (think_times[user_id][session_id][0]['start']) - (think_times[user_id][session_id-1][think_times[user_id][session_id-1].keys.max]['end'])
            current_user_tt_array << tt_session
        else
            next #tt_session = -1
        end               
        #print "\t#{tt_session}\n"          
      } 
      pp current_user_tt_array  if $debug
      print "###DEV### #{user_id}: #{current_user_tt_array.sort}\n"  if $dev
      arr = current_user_tt_array
      if arr.length == 0 || arr.nil?
        len = 0
        lowest = highest = total = 0
        average = median = 0
        possible_th = 0                
      else
        lowest = arr.min
        highest = arr.max
        total = arr.inject(:+)
        len = arr.length
        average = total.to_f / len # to_f so we don't get an integer result      
        sorted = arr.sort           
        median = len % 2 == 1 ? sorted[len/2] : (sorted[len/2 - 1] + sorted[len/2]).to_f / 2        
        #possible_th = arr.find_all { |x| x <= median.to_i }.max + 1
        possible_th = arr.find_all { |x| x <= average.to_i }.max + 1                # TODO: it still misses the good idea of the possible threshold
      end         

      user_threshold[user_id] = possible_th
      
      f.write("#{user_id} #{user_threshold[user_id]}\n")
                        
      print "Median = #{median.to_i}\n" if $debug 
      print "Mean = #{average.to_i}\n" if $debug
      print "Threshold = #{user_threshold[user_id]}\n" if $debug
      print "################################################################################\n"   if $debug                
    }
    }
    #pp user_threshold
end    


def print_to_stdout_siminput(nb_procs, user_sessions_batches, think_times)
    print "#nbcores=#{nb_procs}\n"
    #print "#nbnodes=#{nb_nodes}\n\n"
    print "#nbusers=#{user_sessions_batches.keys.count}\n\n"

    user_sessions_batches.sort.map{ |user_id, sessions|
        print "User #{user_id}:\n" if $debug    
        print "#{user_id}:"        if !$debug                           
        sessions.sort.map{ |session_id, batch|
            
            if session_id>0        
                tt_session = (think_times[user_id][session_id][0]['start']) - (think_times[user_id][session_id-1][think_times[user_id][session_id-1].keys.max]['end'])
            else
                tt_session = -1
            end               
            print "\tsession #{session_id} start at #{think_times[user_id][session_id][0]['start']}, TT=#{tt_session}\n"  if $debug && (tt_session>=0)
            print "\tsession #{session_id} start at #{think_times[user_id][session_id][0]['start']}\n"  if $debug && (tt_session<0)
            print "|#{tt_session}|" if !$debug && (tt_session>=0)
            batch.sort.map{ |batch_id, job| 
                                            
                if batch_id>0                                 
                    tt_batch = (think_times[user_id][session_id][batch_id]['start']) - (think_times[user_id][session_id][batch_id-1]['end'])
                else
                    tt_batch = "n/a"
                end               
                print "\t\tbatch #{batch_id} start at #{think_times[user_id][session_id][batch_id]['start']}, TT=#{tt_batch}\n"   if $debug && (tt_batch.is_a? Integer)
                print "\t\tbatch #{batch_id} start at #{think_times[user_id][session_id][batch_id]['start']}\n"   if $debug && (tt_batch == "n/a")          
                print ";#{tt_batch};" if !$debug && (tt_batch.is_a? Integer) #&& batch_id != think_times[user_id][session_id].keys.max
                job.each_with_index{ |current_job, index|
                    print "\t\t\tjob #{current_job.job_id}, submit=#{current_job.submit_time}, resources=#{current_job.procs_alloc}, wait=#{current_job.wait_time}, runtime=#{current_job.run_time}, walltime=#{current_job.run_time_req}\n"      if $debug
                    print "[#{current_job.submit_time},#{current_job.procs_alloc},#{current_job.run_time_req},#{current_job.run_time}]"   if !$debug
                    #print "[#{current_job.submit_time},#{current_job.wait_time},#{current_job.procs_alloc},#{current_job.run_time_req},#{current_job.run_time}]"   if !$debug
                    print ","  if !$debug && index<job.length-1
                }        
                print "\t\tbatch #{batch_id} stop at #{think_times[user_id][session_id][batch_id]['end']}\n"            if $debug         
            }
            last_session_batch = think_times[user_id][session_id].keys.max
            print "\tsession #{session_id} stop at #{think_times[user_id][session_id][last_session_batch]['end']}, Session Duration=#{think_times[user_id][session_id][last_session_batch]['end'] - think_times[user_id][session_id][0]['start']}\n"   if $debug
            print "|"  if !$debug && (session_id == think_times[user_id].keys.max)
        }
        print "################################################################################\n"   if $debug
        print "\n"        if !$debug                           
    }
end


def generate_swf(nb_procs, user_sessions_batches, think_times)
    date = `date +%s`.chomp   
    File.open("./swf_output/#{date}", 'w') do |file|
    user_sessions_batches.sort.map{ |user_id, sessions|                         
        sessions.sort.map{ |session_id, batch|            
            if session_id>0        
                tt_session = (think_times[user_id][session_id][0]['start']) - (think_times[user_id][session_id-1][think_times[user_id][session_id-1].keys.max]['end'])
            else
                tt_session = -1
            end
            batch.sort.map{ |batch_id, job|
                if batch_id>0        
                    tt_batch = (think_times[user_id][session_id][batch_id]['start']) - (think_times[user_id][session_id][batch_id-1]['end'])
                else
                    tt_batch = -1
                end
                job.each_with_index{ |current_job, index|
                    job_id = current_job.job_id
                    submit_time = current_job.submit_time
                    wait_time = current_job.wait_time
                    run_time = current_job.run_time
                    procs_alloc = current_job.procs_alloc
                    cpu_time_used = current_job.cpu_time_used
                    used_memory = current_job.used_memory
                    procs_req = current_job.procs_req
                    run_time_req = current_job.run_time_req
                    mem_req = current_job.mem_req
                    status = current_job.status
                    user_id = current_job.user_id
                    group_id = current_job.group_id
                    exe_num = current_job.exe_num
                    queue_id = current_job.queue_id
                    partition_id = current_job.partition_id 
                    preceding_job_id = current_job.preceding_job_id
                    preceding_job_think_time = current_job.preceding_job_think_time
                                   
                    # TODO: post-process info depending hypothesis
                    ### if ARR:
                      # preceding_job_id = job soumis juste avant
                      # preceding_job_think_time = soumission du job soumis juste avant
                    ### if LAST:
                      # preceding_job_id = job soumis juste avant
                      # receding_job_think_time = terminaison du job soumis juste avant
                    ### if MAX:
                      # preceding_job_id = job du batch precedent termine le plus tard
                      # receding_job_think_time = terminaison de job ci dessus
                                   
                                   
                     if $algo == 'ARR'
                           
                                   
                     elsif $algo == 'MAX'
                                   
                                   
                     elsif $algo == 'LAST'
                                   
                     
                     elsif $algo == 'MINMAX'              
                                   
                    else
                        # nothing
                    end
                     
                                   
                    line = "#{job_id} #{submit_time} #{wait_time} #{run_time} #{procs_alloc} #{cpu_time_used} #{used_memory} #{procs_req} #{run_time_req} #{mem_req} #{status} #{user_id} #{group_id} #{exe_num} #{queue_id} #{partition_id} #{preceding_job_id} #{preceding_job_think_time}"
                    
                    file.write(line)
                    file.write("\n")
                }             
            }
        }
    }
    end
end


######## MAIN #########

if $algo == 'MAX'
    user_sessions_batches, think_times = get_sessions_MAX(users, user_session_threshold)
elsif $algo == 'ARR'
    user_sessions_batches, think_times = get_sessions_ARR(users, user_session_threshold)
elsif $algo == 'LAST'
    user_sessions_batches, think_times = get_sessions_LAST(users, user_session_threshold)    
elsif $algo == 'MINMAX'
    user_sessions_batches, think_times = get_sessions_MINMAX(users, user_session_threshold) 
else
    puts "Algorithm not recognized, please choose between MAX, LAST, ARR and MINMAX."
    exit 0
end


test_if_bad_batch_exists(think_times) if $debug
print_to_stdout_siminput(nb_procs, user_sessions_batches, think_times)
generate_swf(nb_procs, user_sessions_batches, think_times) if $swf

print_user_sessions_TT(think_times) if !$write_user_threshold.nil?
