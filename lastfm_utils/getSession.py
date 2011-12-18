#!/usr/bin/python

import commands
import sys
import md5

token = sys.argv[1]

url = 'http://ws.audioscrobbler.com/2.0/?'
apiKey = '3a570389ed801f07f07a7ea3d29d6673'
secret = '6a6d7126bbaedb1413768474fb1c80bd'

m = md5.new()
m.update( 'api_key'+apiKey+'methodauth.getSessiontoken' + token + secret )

comm = "curl '" + url + "api_key=" + apiKey + "&method=auth.getSession&token="+token+"&api_sig="+m.hexdigest()+"'"

print commands.getoutput( comm )
