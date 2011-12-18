#!/usr/bin/python

import commands
import re

url = 'http://ws.audioscrobbler.com/2.0/?'
apiKey = '3a570389ed801f07f07a7ea3d29d6673'
comm = "curl '" + url + "method=auth.getToken&api_key=" + apiKey + "'"

print comm

token = commands.getoutput( comm )

token = re.search( "<token>(.*)</token>", token ).group(1)

print 'token: ' + token

print 'http://www.last.fm/api/auth/?api_key='+apiKey+'&token='+token
