## `mpv-history-daemon`

For each `mpv` socket, this attaches event handlers which tell me whenever a file in a playlist ends, whenever I seek (skip), what the current working directory/path is, and whenever I play/pause an item. Once the `mpv` instance quits, it saves all the events to a JSON file.

Later, I can reconstruct whether or not a file was paused/playing based on the events, how long `mpv` was open, and which file was playing, in addition to being able to see what file/URL I was playing.

```
Usage: mpv-history-daemon [OPTIONS] SOCKET_DIR DATA_DIR

  Socket dir is the directory with mpv sockets (/tmp/mpvsockets, probably)
  Data dir is the directory to store the history JSON files

Options:
  --log-file PATH  location of logfile
  --help           Show this message and exit.
```

Some logs, to get an idea of what this captures:

```
[D 200901 03:47:54 mpv-history-daemon:115] 1598956534118491075|1598957274.3349547|mpv-launched|1598957274.334953
[D 200901 03:47:54 mpv-history-daemon:115] 1598956534118491075|1598957274.335344|working-directory|/home/sean/Music
[D 200901 03:47:54 mpv-history-daemon:115] 1598956534118491075|1598957274.3356173|playlist-count|12
[D 200901 03:47:54 mpv-history-daemon:115] 1598956534118491075|1598957274.3421223|playlist-pos|2
[D 200901 03:47:54 mpv-history-daemon:115] 1598956534118491075|1598957274.342346|path|Masayoshi Takanaka/Masayoshi Takanaka - Alone (1988)/02 - Feedback's Feel.mp3
[D 200901 03:47:54 mpv-history-daemon:115] 1598956534118491075|1598957274.3425295|media-title|Feedback's Feel
[D 200901 03:47:54 mpv-history-daemon:115] 1598956534118491075|1598957274.3427346|metadata|{'title': "Feedback's Feel", 'album': 'Alone', 'genre': 'Jazz', 'album_artist': '高中正義', 'track': '02/8', 'disc': '1/1', 'artist': '高中正義', 'date': '1981'}
[D 200901 03:47:54 mpv-history-daemon:115] 1598956534118491075|1598957274.342985|duration|351.033469
[D 200901 03:47:54 mpv-history-daemon:115] 1598956534118491075|1598957274.343794|resumed|{'percent-pos': 66.85633}
[D 200901 03:48:41 mpv-history-daemon:115] 1598956534118491075|1598957321.3952177|eof|None
[D 200901 03:48:41 mpv-history-daemon:115] 1598956534118491075|1598957321.3955588|mpv-quit|1598957321.395554
[W 200901 03:48:41 mpv-history-daemon:186] Ignoring error: [Errno 32] Broken pipe
[D 200901 03:48:44 mpv-history-daemon:236] Connected refused for socket at /tmp/mpvsockets/1598956534118491075, removing dead socket file...
[I 200901 03:48:44 mpv-history-daemon:314] /tmp/mpvsockets/1598956534118491075: writing to file...
```

The corresponding JSON file looks like:

```
  "1598957274.3349547": {
    "mpv-launched": 1598957274.334953
  },
  "1598957274.335344": {
    "working-directory": "/home/sean/Music"
  },
  "1598957274.3356173": {
    "playlist-count": 12
  },
  "1598957274.339725": {},
  "1598957274.3421223": {
    "playlist-pos": 2
  },
  "1598957274.342346": {
    "path": "Masayoshi Takanaka/Masayoshi Takanaka - Alone (1981)/02 - Feedback's Feel.mp3"
  },
  "1598957274.3425295": {
    "media-title": "Feedback's Feel"
  },
  "1598957274.3427346": {
    "metadata": {
      "title": "Feedback's Feel",
      "album": "Alone",
      "genre": "Jazz",
      "album_artist": "高中正義",
      "track": "02/8",
      "disc": "1/1",
      "artist": "高中正義",
      "date": "1981"
    }
  },
  "1598957274.342985": {
    "duration": 351.033469
  },
  "1598957274.343794": {
    "resumed": {
      "percent-pos": 66.85633
    }
  },
  "1598957321.3952177": {
    "eof": null
  },
  "1598957321.3955588": {
    "mpv-quit": 1598957321.395554
  }
}
```

More events would keep getting logged, as I pause/play, or the file ends and a new file starts. The key for each JSON value is the epoch time, so everything is timestamped.

I parse the stream of events with some code [here](https://github.com/seanbreckenridge/HPI/blob/master/my/mpv.py); which lets me access it through a REPL/through `my.mpv`. For example, to find my most played song:

```
>>> import my.mpv, collections
>>> collections.Counter([e.path for e in list(my.mpv())]).most_common(1)
[('/home/data/media/music/Janelle Monáe/The_Electric_Lady/15-Victory.mp3', 8)]
```
