.DEFAULT_GOAL := copy_scripts
TARGET_BIN="${HOME}/.local/bin"

all: copy_scripts daemon

copy_scripts:
	echo "Attempting to install to $(TARGET_BIN)"
	mkdir -p $(TARGET_BIN)
	cp -v ./mpv-* $(TARGET_BIN)
	cp -v ./mpv $(TARGET_BIN)

daemon:
	pip install click python-mpv-jsonipc logzero

