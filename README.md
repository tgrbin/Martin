Martin
======

![screenshot](/../gh-pages/images/screenshot.png?raw=true)

Martin is a lightweight open source audio player for OSX.

You point it to your music folders, and Martin displays them in the tree pane on the left.
Your files and folders are scanned and kept in internal library, which makes searching and browsing fast. Folders are watched for changes automatically.

Playlists are displayed in a tabbed interface.

There is last.fm support and some global shortcuts for controlling playback.

I've been working on Martin because I couldn't find anything out there to my liking.
Feel free to contact me if you have any questions or suggestions.
I apologize in advance for any annoying bugs that you may encounter.

Release notes
----------------

- v1.2.5
  - Fix unicode handling
- v1.2.4
  - Fix Last.FM scrobbling
  - Prevents crashing when playing some non-ascii songs
- v1.2
  - Added HTTP streams and FLAC support
- v1.1
  - Loading/saving m3u and pls playlists

Keyboard shortcuts and hints
------------------

While in search field:

- <kbd>Enter</kbd> - Add search results to the selected playlist
- <kbd>Command+Enter</kbd> - Create new playlist with search results
- <kbd>Alt+Q</kbd> - Enqueue search results

On selection:

- <kbd>Enter</kbd> - Play item
- <kbd>Command+Enter</kbd> - Create new playlist with selection
- <kbd>Alt+Q</kbd> - Enqueue selection

While in playlist:

- <kbd>Left arrow</kbd> or <kbd>Right arrow</kbd> to move between playlists

Global:

- <kbd>/</kbd> or <kbd>Command+F</kbd> - go to search

Use <kbd>Command</kbd>+drag to create a new playlist while dragging from tree or another playlist.
Other keyboard shortcuts should be discoverable through menu and context menus.
