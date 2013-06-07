#!/usr/bin/python
import time
import re
import sched
import argparse
import sys
import signal, os

#author: Valentin Reis
#mail: Valentin.Reis@imag.fr

def main():
	parser = argparse.ArgumentParser(description="Replay a cgn log into SLURM without think time management")
	parser.add_argument("filename",metavar="File",help="the input file")
	parser.add_argument('-s', '--speedup',help="the speedup factor for the log replay",default=1)
	parser.add_argument("-p","--userprefix",help="the user prefix for creating users on the system. will work as USERPREFIX1,USERPREFIX2... and so on. The default value is u.",default="u")

	args=parser.parse_args()
	print(args)
	
	#standard input.
	#filename=sys.argv[1]
	print(args.filename)
	ratio=1/float(args.speedup)
	#opening the file.
	with open(args.filename) as f:
	    fl=f.readlines()

	#this is the main global variable for storing users'campaigns. format: [[user id,campaigns],..]
	#campaigns are stored as campaigns=[[submit time,jobs],..] 
	#and jobs as jobs=[[job id,requested runtime,actual runtime],..].
	ustacks=[]

	#user count for printing debug info.
	ucount=0
	print("Extracting jobs from Users:")

	#getting header info: user count.
	usercount=int(fl[3])

	for l in fl[6:len(fl)]:
		#printing debug info.
		sys.stdout.write(str(ucount)+".. ")
		ucount=ucount+1

		#Parsing the data from the cgn..
		#splitting campaigns and usernames
		b=l.split(":")	
		#putting campaigns into the data sttring
		data=b[1]
		#ignoring users with no campaigns.
		if len(data)==0:
			continue
		
		#treating sessions as campaign separators
		data=re.sub("\|",";",b[1])
		#removing the think times data
		data=re.split(";[0-9]*;",data)
		#removing trailing ;
		data=[re.sub(";","",e) for e in data]
		#removing \n from the string
		data=[e.strip() for e in data]
		#removing the dependency separator
		data=[re.sub(",\(\)", "",e) for e in data]
		#eval to get a correct data structure.
		data=[list(eval(e)) for e in data]
		#flattening the types into data:
		def forcelist(e):
			if type(e[0])==int:
				return [e]
			else:
				return e
		data=[forcelist(e) for e in data]
		#formatting as "campaigns".
		data=[ [ min([j[1] for j in campaign])  ,  [ [j[0],j[3],j[4]] for j in campaign] ] for campaign in data]
		#adding to the global user stack
		ustacks.append([b[0],data])
		sys.stdout.write("ok. ")
		
	#getting min and max start times from the campaigns
	min_time=min([min([c[0] for c in u[1]]) for u in ustacks])
	max_time=max([max([c[0] for c in u[1]]) for u in ustacks])

			
	#scheduler object to automate our job
	s=sched.scheduler(time.time, time.sleep)
	print("")
	print("Scheduling jobs: ")

	#creating a user manager to do the job:
	umanager=user_manager(args.userprefix)
	umanager.create_users(usercount)

	
	#sigterm handler to remove jobs.
	def handler(signum = None, frame = None):
		print 'Signal handler called with signal', signum
		print 'please wait, deleting extra users'
		umanager.del_users()
		print 'done'
		sys.exit(0)
	for sig in [signal.SIGTERM, signal.SIGINT, signal.SIGHUP, signal.SIGQUIT]:
		signal.signal(sig, handler)
	

	#entering the jobs into the scheduler
	for u in ustacks:
		for c in u[1]:
			#multiply by the ratio for speeding up a replay.
			s.enter(ratio*float(c[0]-min_time),1,slurm_campaign,[u[0],c,umanager])
		
		sys.stdout.write(str(u[0])+".. ok ")
	print("")
	
	print("Starting the log replay.")

	#starting the scheduler
	s.run()
	umanager.del_users();

##the communication device for slurm.
def slurm_campaign(u,campaign,umanager):
	print("starting campaign of user {} with {} jobs.".format(u,len(campaign[1])))
	print(campaign)
		
	for j in campaign[1][0:len(campaign[1])-2]:
		umanager.call(u,"srun --time=0:"+str(j[1])+" sleep "+str(j[2])+" &")
	umanager.call(u,"srun --comment=startcampaign --time=0:"+str(campaign[1][len(campaign[1])-1][1])+" sleep "+str(campaign[1][len(campaign[1])-1][2])+" &")

	

#this class manages the users on the system.
class user_manager:
	def __init__(self,prefix):
		self.prefix=prefix
	#	self.created=False
	#create users from 0 to n-1.
	def create_users(self,n):
		self.n=n
		for i in range(0,self.n):
			username=self.prefix+str(i)
			os.system("useradd "+username)
		self.created=True
		print("created {} users.".format(n))
	def del_users(self):
	#	if not self.created:
	#		print("ERROR: did not create users.")
		for i in range(0,self.n):
			username=self.prefix+str(i)
			os.system("killall -9 srun")
			os.system("userdel "+username)
			os.system("groupdel "+username)
			

		#self.created=False
	def call(self,u,s):
	#	if not self.created:
	#		print("ERROR: did not create users.")

		username=self.prefix+str(u)
		os.system("sudo -u "+username+" "+s)
	#	self.created=False



if __name__ == "__main__":
    main()
