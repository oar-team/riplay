#!/usr/bin/ruby

require 'pp'
require 'getoptlong'
require "lib_swf.rb"


############
# Options
############

def usage_message
    <<EOS
Usage ./deploy_users [OPTIONS] -f FILE.swf

        OPTIONS:
                --swf_file | -f swf_file : specify the workload file
                --delete   | -d          : delete users instead of adding them
                --prefix   | -p prefix   : change user prefix to "prefix" (default: "user")
                --nodes    | -n file     : deploy users to the hosts contained in the file "file"
                --help     | -h display  : this help message
EOS
end

opts = GetoptLong.new(
[ "--swf_file","-f",              GetoptLong::REQUIRED_ARGUMENT ],
[ "--delete","-d",              GetoptLong::NO_ARGUMENT ],
[ "--prefix","-p",            GetoptLong::REQUIRED_ARGUMENT ],
[ "--nodes","-n",              GetoptLong::REQUIRED_ARGUMENT ],
[ "--help","-h",                GetoptLong::NO_ARGUMENT ]
)

$command = 'useradd -M -N'
$prefix = 'user'
$nodes = nil
$swf_file = nil

opts.each do |option, value| 
        if (option == "--swf_file")
                $swf_file = value
        elsif (option == "--delete")
                $command = 'userdel'
        elsif (option == "--prefix")
                $prefix = value
        elsif (option == "--nodes")
                $nodes = value
        elsif (option == "--help")
                puts usage_message
                exit 0
        end
end

if ($swf_file == nil)
  puts "Missing arguments."
  puts usage_message
  exit 0
end


############
# Main
############

#get users from swf file
jobs = load_swf_file($swf_file, nil, nil)

all_users_l = []
jobs.each_pair do |job_id, job_struct|
        all_users_l << job_struct["user_id"]
end

all_users_l.uniq!

all_users = all_users_l.join(" ")

#execute command
#TODO: use taktuk
if ($nodes == nil)
        p "for i in #{all_users}; do #{$command} #{$prefix}$i; done"
else
        p "for node in `cat #{$nodes}|sort -u`; do ssh $node 'for i in #{all_users}; do #{$command} #{$prefix}$i; done'; done"
end




