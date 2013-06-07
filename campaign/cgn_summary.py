import sys
import time
import re
import datetime
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.mlab as mlab

filename=sys.argv[1]

with open(filename) as f:
    fl=f.readlines()
    
t=[[e.strip('[') for e in re.findall("\[[0-9]*",l)] for l in fl]
t=[item for sublist in t for item in sublist]
t=map(lambda s:int(s),t)
ma=max(t)
mi=min(t)
l=len(t)
print("Log header information:")
print(fl[0])
print(fl[1])
print("MAX time IS "+str(ma))
print("MIN time IS "+str(mi))
print("Amount of jobs: "+str(l))
print("Time spread of the log: "+str(ma-mi)+" seconds. Human Readable: "+time.strftime('%m months, %d days and %H:%M:%S', time.gmtime(ma-mi)))
print("And that makes for "+str(float(l)/float(ma-mi))+" jobs per second on average.")

campaignamount=[]
resourcesamount=[]
walltimes=[]
campaignsize=[]






for l in fl[3:len(fl)]:
	b=l.split(":")
	user=b[0]
	data=b[1]
	data=re.sub("\|",";",data)
	data=re.split(";[0-9]*;",data)
	data=map(lambda c:c.strip(";\n"),data)
	data=[eval(e) for e in data]
	def the_great_normalizer(truc):
		if type(truc)==list:return (truc,)
		else :return truc
	data=map(the_great_normalizer,data)
	campaignamount.append(len(data))
	for c in data:
		
		campaignsize.append(len(e))
		for j in c:
			walltimes.append(j[3])

fig = plt.figure()
ax = fig.add_subplot(111)
n, bins, patches = ax.hist(t, 300, normed=0, facecolor='green', alpha=0.75)
fig2 = plt.figure()
ax2 = fig2.add_subplot(111)
n, bins, patches = ax2.hist(walltimes, 120, normed=0, facecolor='green', alpha=0.75)
fig3 = plt.figure()
ax3 = fig3.add_subplot(111)
n, bins, patches = ax3.hist(campaignamount, 12, normed=0, facecolor='green', alpha=0.75)
fig5 = plt.figure()
ax5 = fig5.add_subplot(111)
n, bins, patches = ax5.hist(campaignsize, 60, normed=0, facecolor='green', alpha=0.75)


ax5.set_xlabel('size of the campaign')
ax5.set_ylabel('Amount of campaigns')
ax5.set_title("Distribution of the campaign size(in number of jobs).")
ax5.set_xlim(0, 200)
#ax.set_ylim(0, 0.03)
ax5.grid(True)



ax3.set_xlabel('Amount of campaigns')
ax3.set_ylabel('Amount of users')
ax3.set_title("Distribution of campaigns per user.")
#ax.set_xlim(mi, ma)
#ax.set_ylim(0, 0.03)
ax3.grid(True)


ax2.set_xlabel('Walltime')
ax2.set_ylabel('Amount of jobs')
ax2.set_title("Distribution of job walltimes.")
#ax.set_xlim(mi, ma)
#ax.set_ylim(0, 0.03)
ax2.grid(True)


ax.set_xlabel('Time')
ax.set_ylabel('Amount of jobs')
ax.set_title("Distribution of job submission times.")
#ax.set_xlim(mi, ma)
#ax.set_ylim(0, 0.03)
ax.grid(True)


plt.show()

