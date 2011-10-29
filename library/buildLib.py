#!/usr/bin/python
# ucitava iz mp3.list sve mp3ice, i slaze ih u library
# mp3.list se moze dobit sa find . -name "*.mp3"
# + znaci novi folder, - znaci izadji iz foldera, u blokovima {} su pjesme
# izlaz je na ekran

from mutagen.easyid3 import EasyID3

def travel( p1, p2 ):
	i = 0
	while i < len(p1) and p1[i] == p2[i]:
		i=i+1

	for j in range(len(p1)-i):
		print "-"

	for d in p2[i:]:
		print "+ "+d

def outputTag( id3, tag ):
	if not tag in id3.keys():
		return '/'
	return id3[tag][0].encode('utf-8')

f = open('mp3.list')
lastPath = ['.', '.']
id = 0

for mp3 in f:
	mp3 = mp3[:-1] # makni newline
	path = mp3.split('/')

	travel( lastPath[:-1], path[:-1] )

	id3 = EasyID3(mp3)
	
	print "{"
	print id
	print path[-1] #filename
	print outputTag( id3, 'tracknumber' )
	print outputTag( id3, 'artist' )
	print outputTag( id3, 'album' )
	print outputTag( id3, 'title' )
	print "}"
	
	lastPath = path;
	id = id + 1

for j in range(len(path)-2):
	print "-"
	
f.close()