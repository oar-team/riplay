#!/usr/bin/ruby

#require 'rubygems'
require 'getoptlong'
require 'pp'
require "lib_swf.rb"


session_threshold = 3600 # secs, according to Feitelson


opts = GetoptLong.new( [ "--file","-f", GetoptLong::REQUIRED_ARGUMENT ],
                        #["--threshold","-t", GetoptLong::REQUIRED_ARGUMENT ],
                        ["--help","-h", GetoptLong::NO_ARGUMENT])
opts.each do |option,value|
        if(option =="--file")
                $file=value
        #elsif(option =="--threshold")
        #        session_threshold=value.to_i
        elsif (option =="--help")
                puts "Usage: ./discover_sessions.rb
options: -f <file>
         "
                exit
        end
end

jobs = load_swf_file($file, nil, nil)


users = Hash.new { |h, k| h[k] = Hash.new { |hash, key| hash[key] = [] } }
user_sessions = Hash.new { |h, k| h[k] = Hash.new { |hash, key| hash[key] = [] } }


jobs.each_pair { |job_id, job_struct|
    if !(job_id =~ /^info/)
        users[job_struct.user_id][job_id] = job_struct
    end             
}


### Detect per user threshold

grouping = 1 # group per minute

interarrivals = {} 

users.each_pair{ |user_id, jobs_hash|
    last_submit = 0
    #interarrivals = {} 
               
    jobs_hash.sort.map do |job_id, job|                      
        current_interarrival = job.submit_time.to_i-last_submit.to_i
               
        current_interarrival = (current_interarrival.to_f/grouping.to_f).ceil.to_i
               
        last_submit = job.submit_time.to_i
        if interarrivals.has_key?(current_interarrival)       
            interarrivals[current_interarrival] = interarrivals[current_interarrival]+1 
        else
            interarrivals[current_interarrival] = 1
        end       
    end

               
            
               
               
    ### Accumulate
    previous_count = 0
    interarrivals.sort.map do |time, count|
        interarrivals[time] = count + previous_count
        previous_count = interarrivals[time]
    end        
       
               
               
    max_count_value = interarrivals.values.max           
# 
#      ### Detect Max
#     max_interarrival = -1
#     #max_before_interarrival = -1
#     interarrivals.each_pair{ |interarrival, count|
#         if max_interarrival==-1 || interarrivals[max_interarrival] < count
#            #max_before_interarrival = max_interarrival
#            max_interarrival = interarrival                 
#         end                   
#                                                           
#     }
#     
    # Set as percentages           
    interarrivals.each_pair{ |interarrival, count|
        interarrivals[interarrival] = (count*100)/max_count_value          
                                                          
    }           
               

#     if user_id == 100
# 
#            pp interarrivals.sort    
#                
#     end           
               
    #pp "User #{user_id} max_interarrival=#{max_interarrival}, count=#{interarrivals[max_interarrival]} ---- max_before_interarrival=#{max_before_interarrival}, count=#{interarrivals[max_before_interarrival]}"           
               
}

 
    
pp interarrivals.sort



###



# users.each_pair{ |user_id, jobs_hash|
#     last_submit = -1
#     sessions_cpt = 0
#             
#     jobs_hash.sort.map do |job_id, job|                      
#         if(job.submit_time.to_i-last_submit.to_i > session_threshold)
#             sessions_cpt = sessions_cpt+1       
#                 
#         end
#         #user_sessions[user_id][sessions_cpt] << job
#         #user_sessions[user_id][sessions_cpt] << job.job_id
#         user_sessions[user_id][sessions_cpt] << "job_id=#{job.job_id}, submit_time=#{job.submit_time}, runtime=#{job.run_time}, procs_alloc=#{job.procs_alloc}, walltime=#{job.run_time_req}"
#         last_submit = job.submit_time.to_i
#     end
#     
# }
# 
# pp user_sessions
# 
# user_sessions.each_pair{ |user_id, sessions|
#     puts "User #{user_id} has #{user_sessions[user_id].keys.length} sessions"
# }
