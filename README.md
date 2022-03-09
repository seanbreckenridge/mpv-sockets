# mpv-sockets

Dependencies: [`mpv`](https://mpv.io/), [`socat`](https://linux.die.net/man/1/socat), [`jq`](https://github.com/stedolan/jq), ([`fzf`](https://github.com/junegunn/fzf) for `mpv-quit-pick`)

A collection of bash scripts to allow easier and programmatic interaction with `mpv` sockets

When launching `mpv`, one can use `--ipc-socket` (or set the property in your `mpv.conf`) to launch `mpv` with the _one_ socket, but I tend to have lots of instances of `mpv` open. One for a video I'm watching, another for some album I'm listening to, another for a [playlist](https://github.com/seanbreckenridge/plaintext-playlist)...

If you use the one IPC socket, whenever a new instance of `mpv` is launched, the old instance gets disconnected. The `mpv` wrapper script creates a unique IPC socket for each `mpv` instance launched at `/tmp/mpvsockets`.

`mpv-active-sockets` removes any inactive (leftover socket files from instances which have been quit) `mpv` sockets, and lists active `mpv` sockets

`mpv-communicate` is a basic `socat` wrapper to send commands to the IPC server. (sends all additional arguments to the socket described by the first argument)

To illustrate:

If I have two instances of `mpv` open:

```bash
$ mpv-active-sockets
/tmp/mpvsockets/1643226338072141025
/tmp/mpvsockets/1643226355764534189
```

To get metadata from the oldest (sockets are sorted by spawn time, so `head` gets the oldest) launched `mpv` instance:

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
$ mpv-get-property "$(mpv-active-sockets)" path  # this works if there's only one instance of mpv active
Music/Yes/Yes - Fragile/01 - Roundabout.mp3
```

Can also use `mpv-get-property` to construct a description from the `metadata`, like `mpv-song-description` does:

```bash
$ mpv-song-description
Yellow Submarine - The Beatles (Revolver)
```

`mpv-currently-playing` is a `mpv-get-property` wrapper that gets information about the currently playing mpv instance. If there are multiple sockets, prints multiple lines, with one for each socket.

By default that will print the full path of the song that's currently playing, but you can provide the `--socket` flag to print the sockets instead. That's used in `mpv-play-pause`, which toggles the currently playing `mpv` instance to paused/resumes it. It keeps track of which sockets were recently paused - if a socket can be resumed, it does that; else, tries to look for another paused `mpv` instance.

`mpv-currently-playing` can also be used with `mpv-communicate` to go to the next song, by sending the `playlist-next` command:

`mpv-communicate $(mpv-currently-playing --socket | tail -n1) '{ "command": ["playlist-next"] }'`

`mpv-seek` is another `mpv-currently-playing` wrapper, which moves forward/backward in the currently playing instance

To quit the currently playing `mpv` instance:

`$ mpv-communicate $(mpv-currently-playing --socket | tail -n1) 'quit'`

To list currently paused `mpv` instances:

`$ diff -y --suppress-common-lines <(mpv-currently-playing --socket) <(mpv-active-sockets) | grep -oP '(\/tmp\/mpvsockets\/\d+)'`

I bind some of these scripts to keybindings, so I can easily play/pause and skip songs without switching to the terminal with `mpv` running; search for `mpv` in my [config file](https://sean.fish/d/i3/config?dark)

There are lots of properties/commands one can send to `mpv`, see `mpv --list-properties` and these ([1](https://stackoverflow.com/q/35013075/9348376), [2](https://stackoverflow.com/q/62582594/9348376)) for reference.

## Install

To install this, clone and copy all the scripts somewhere onto your `$PATH`:

```bash
git clone https://github.com/seanbreckenridge/mpv-sockets
cd ./mpv-sockets
make
```

That puts them in `~/.local/bin`

I put the directory that the `mpv` wrapper script is installed into on my `$PATH` before `/usr/bin`, so the wrapper script intercepts calls that would typically call the `mpv` binary. In my shell profile, like:

```
PATH="${HOME}/.local/bin:${PATH}"
export PATH
```

You could alternatively rename the `mpv` wrapper script here to something like `mpvs` and then run `mpvs` instead of `mpv` when you want unique sockets.

This checks `/usr/bin/mpv`, `/bin/mpv` and `/usr/local/bin/mpv` for the `mpv` binary. If your `mpv` isn't at one of those locations, you can set the `MPV_PATH` variable in your shell profile;

```
export MPV_PATH=/home/user/bin/mpv
```

You can set the `MPV_SOCKET_DIR` environment variable to spawn sockets in a directory other than `/tmp/mpvsockets`

### Alternative Installation Methods

To automate the manual `git clone`/`cd`/`make`, you could instead use [`bpkg`](https://github.com/bpkg/bpkg):

```
bpkg install -g seanbreckenridge/mpv-sockets
```

Or [`basher`](https://github.com/basherpm/basher):

```
basher install seanbreckenridge/mpv-sockets
```

Note that in this case the basher `bin` has to appear before the `mpv` binary, see [my config](https://github.com/seanbreckenridge/dotfiles/blob/50fdef99d8e5343181cc68abe1a9fc0f941a0cad/.profile#L59-L60) as an example

### Daemon

I run [`mpv-history-daemon`](https://github.com/seanbreckenridge/mpv-history-daemon) in the background, which polls for new sockets at `/tmp/mpvsockets`, grabbing file info, metadata, and whenever I play/pause/skip anything playing in `mpv`. That creates a local scrobbling history for `mpv` - letting me create a `mpv` history, and do statistics on which songs/videos I listen to often.

```
1598956534118491075|1598957274.3349547|mpv-launched|1598957274.334953
1598956534118491075|1598957274.335344|working-directory|/home/sean/Music
1598956534118491075|1598957274.3356173|playlist-count|12
1598956534118491075|1598957274.3421223|playlist-pos|2
1598956534118491075|1598957274.342346|path|Masayoshi Takanaka/Masayoshi Takanaka - Alone (1988)/02 - Feedback's Feel.mp3
1598956534118491075|1598957274.3425295|media-title|Feedback's Feel
1598956534118491075|1598957274.3427346|metadata|{'title': "Feedback's Feel", 'album': 'Alone', 'genre': 'Jazz', 'album_artist': '高中正義', 'track': '02/8', 'disc': '1/1', 'artist': '高中正義', 'date': '1981'}
1598956534118491075|1598957274.342985|duration|351.033469
1598956534118491075|1598957274.343794|resumed|{'percent-pos': 66.85633}
1598956534118491075|1598957321.3952177|eof|None
1598956534118491075|1598957321.3955588|mpv-quit|1598957321.395554
Ignoring error: [Errno 32] Broken pipe
Connected refused for socket at /tmp/mpvsockets/1598956534118491075, removing dead socket file...
/tmp/mpvsockets/1598956534118491075: writing to file...
```
