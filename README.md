# mpv-sockets

Dependencies: `mpv`, `socat`, `jq`.

A collection of scripts to allow flexible and easier interaction with `mpv` sockets.

When launching `mpv`, one can use `--ipc-socket` (or set the property in your `mpv.conf`) to launch `mpv` with the *one* socket, but I tend to have lots of instances of `mpv` open. One for a video I'm watching, another for some album I'm listening to, another for a [playlist](https://github.com/seanbreckenridge/plaintext-playlist)...

If you use the one IPC socket, whenever a new instance of `mpv` is launched, the old instance gets disconnected. The `mpv` wrapper script creates a unique IPC socket for each `mpv` instance launched at `/tmp/mpvsockets`.

I run `mpv-history-daemon` in the background, which communicates with the sockets at `/tmp/mpvsockets`, to get fileinfo, metadata, and whenever I play/pause/skip anything playing in mpv. That lets me create a history and do statistics on which songs/videos I listen to often. See [here](./DAEMON.md) for more info on that.


`mpv-active-sockets` removes any inactive (leftover socket files from instances which have been quit) `mpv` sockets, and lists active `mpv` sockets

`mpv-communicate` is a basic `socat` wrapper to send commands to the IPC server. (sends all additional arguments to the socket described by the first argument)

To illustrate:

If I have two instances of `mpv` open:

```bash
$ mpv-active-sockets
/tmp/mpvsockets/1596170714
/tmp/mpvsockets/1596170180
```

To get metadata from the oldest (sockets are named based on epoch time, so `head` gets the oldest) launched `mpv` instance:

```bash
$ mpv-communicate "$(mpv-active-sockets | head -n 1)" '{ "command": ["get_property", "metadata"] }' | jq
{
  "data": {
    "title": "Roundabout",
    "album": "Fragile",
    "genre": "Progressive Rock",
    "track": "01/9",
    "disc": "1/1",
    "artist": "Yes",
    "album_artist": "Yes",
    "date": "1972"
  },
  "request_id": 0,
  "error": "success"
}
```

`mpv-get-property` interpolates the second argument into the `get_property` `command` syntax, but is practically no different from `mpv-communicate`

```bash
$ mpv-get-property "$(mpv-active-sockets)" path  # this works if theres only one instance of mpv active
Music/Yes/Yes - Fragile/01 - Roundabout.mp3
```

`mpv-currently-playing` is a `mpv-get-property` wrapper that gets information about the currently playing mpv instance. If there are multiple sockets, prints multiple lines, with one for each socket.

By default that will print the full path of the song thats currently playing, but you can provide the `--socket` flag to print the sockets instead. Thats used in `mpv-play-pause`, which keeps track of which sockets were recently paused. If that socket can be resumed, it does that; else, tries to look for another paused mpv instance. Can also be used with `mpv-communicate` to go to the next song:

`mpv-communicate $(mpv-currently-playing --socket | tail -n1) '{ "command": ["set_property", "percent-pos", 100 ] }'`

To quit the currently playing mpv instance:

`$ mpv-communicate $(mpv-currently-playing --socket | tail -n1) 'quit'`

There are lots of properties/commands one can send to `mpv`, see `mpv --list-properties` and these ([1](https://stackoverflow.com/q/35013075/9348376), [2](https://stackoverflow.com/q/62582594/9348376)) for reference.

I use this to monitor all `mpv` instances running, so I can run a task in the background to capture what I'm currently watching/listening to with `mpv`, to generate history/most-played statistics for my local media.

## Install

To install this, clone and copy all the scripts somewhere onto your `$PATH`:

```bash
git clone https://gitlab.com/seanbreckenridge/mpv-sockets && cd ./mpv-sockets
cp ./mpv* ~/.local/bin
```

This also includes a `Makefile` which does the above, `make all` installs the `python` dependencies for `mpv-history-daemon`.

I put the `mpv` wrapper script on my `$PATH` before `/usr/bin`, so the wrapper script intercepts calls that would typically call the `mpv` binary. You could alternatively rename the `mpv` wrapper script to something else.

You can set the `MPV_PATH` variable to the absolute path of `mpv` if the `mpv` executable isn't installed at `/usr/bin/mpv`,  e.g.: `MPV_PATH=/usr/local/bin/mpv mpv` (the second `mpv` is the script, not `/usr/local/bin/mpv`)

