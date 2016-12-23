#!/usr/bin/python

import os
import sys
import commands
import re

global_memo_path =os.environ.get("HOME") + "/memo/"
memo_path= global_memo_path + "memo/"
html_path= global_memo_path 


class Memo:
    def __init__(self,fn):
    	f = open(fn.strip('\n'),"r")
	self.fullpath=fn.strip('\n')
	tmp = self.fullpath.split('/')
	self.htmlpath=""
	self.name=tmp[len(tmp)-1]
        self.title=f.readline().strip('\n')
        self.body=f.readlines()
	f.close()

    def GetTitle(self,type="text"):
    	if type is "html":
		return "<H2>" + self.title + "</H2>"
	else:
		return self.title

    def GetFirstTag(self):
	alltags=re.findall("\[[a-z|A-Z|_|0-9|-]+\]",self.title,0)	
	if len(alltags) > 0:
		return re.findall("\[[a-z|A-Z|_|0-9|-]+\]",self.title,0)[0]
	else:
    		return "[Unclassified]"

    def GetTags(self):
    	alltags = ""
    	for tag in re.findall("\[[a-z|A-Z|_|0-9|-]+\]",self.title,0):
		alltags = alltags + " " + tag
	if alltags != "":
		return alltags
	else:
    		return "[Unclassified]"
		
    	
    def GetMemo(self,type="text"):
    	if type is "html":
    		strmem = "<H1>" +  "Title: " + self.title + "</H1>"  + "\n"
	else:
    		strmem = "Title: " + self.title + "\n"

	strmem +="<pre>"
	for i in self.body:
		strmem += i
	strmem +="</pre>"
	return strmem

    def GetCreateTimeStr(self):
    	dt=self.name.split('_')
	return dt[0] + "/" + dt[1] + "/" + dt[2] + "  " + dt[3] + ":" + dt[4] + ":" + dt[5]
	
    def Output(self,type="text"):
    	if type is "html":
		print "<H1>" +  "Title: " + self.title + "</H1>"
		for i in self.body:
			print i,
	else:
		print self.title
		for i in self.body:
			print i,

    def MakeHTML(self,path=html_path):
	self.htmlpath= path + "/" + self.name + ".html"
	f = open(self.htmlpath,"w")
	f.write(self.GetMemo("html"))
	f.close()

    def GetHMTLPath(self):
    	return self.htmlpath

    def GetFullPath(self):
    	return self.fullpath

    def GetName(self):
    	return self.name



def run(param):
	moset=[]
	search_target=memo_path
	search_result=[]
	allkeys=""
	mode="search"

	if len(param) != 0:
		for key in param:
			search_result=commands.getoutput("grep -rl" + " \'" + key + "\' " + search_target).split('\n')
			search_target=""
			for found in search_result:
				search_target += " " + found
			allkeys+=" " + key
	else:
		search_result=commands.getoutput("find " + " " + memo_path + " " + "-type f").split('\n')
		mode="list"
		

	result=[]
	for i in search_result:
		if i not in result and i.strip() !="":
			result.append(i)

	if len(result) != 0:
		f = open(html_path+ "/index.html","w")
		if mode == "list":
			f.write("<H1>All memos</H1>" )
		else:
			f.write("<H1>Search result for " + allkeys + "</H1>" )

		f.write("<UL>")

		f.write("<A href=" + "www.google.co.jp" +">" + "Web search" + "</A>")

		moset = []
		for m in result:
			mo = Memo(m)
			firsttag = mo.GetFirstTag()

			if len(moset) == 0:
				moset.append(mo)
			else:
				j=0
				while j < len(moset):
					if firsttag >= moset[j].GetFirstTag():
						j += 1
						if j == len(moset):
							moset.append(mo)
							break
					else:
						moset.insert(j,mo)
						break
		oldtag=""
		for mo in moset:
			tag = mo.GetFirstTag()
			if oldtag != tag:
				f.write("<BR><BR>")
				f.write("<H3>" +tag + "</H3>")
				oldtag = tag
			f.write(" <LI> <A href=" + "./memo/"+mo.GetName() + ">" + mo.GetTitle() + "</A><BR>" + 
				 "Created:" + mo.GetCreateTimeStr() + "<BR>" +
				 "Tags:" + mo.GetTags() + "<BR>")

		f.write("</UL>")
		f.close()
		os.system("w3m -num -T text/html" + " " + html_path + "/index.html")
	else:
		print "Not memo found."

def add(memo_format="text"):
	memo_book="~/memo/memo/"
	memo=commands.getoutput("date +%Y_%m_%d_%H_%M_%S")
	if memo_format == "html":
		os.system("vim" + " " + memo_book + "/" + memo + ".html");
	else:
		os.system("vim" + " " + memo_book + "/" + memo);

if __name__ == "__main__":
	os.system("memo_clear.sh")
	if len(sys.argv) >= 2 and sys.argv[1] == "-a":
		add()
		sys.exit(0)

	if len(sys.argv) >= 2 and sys.argv[1] == "-A":
		add("html")
		sys.exit(0)

	search_keys = []
	if len(sys.argv) >= 2 and sys.argv[1] == "-t":
		for key in sys.argv[2:]:
			search_keys.append("\[" + key )
	else:
		search_keys = sys.argv[1:]
			
	run(search_keys)
	os.system("memo_clear.sh")
