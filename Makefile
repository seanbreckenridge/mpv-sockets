TARGET_BIN="${HOME}/.local/bin"

all:
	echo "Attempting to install to $(TARGET_BIN)"
	mkdir -p $(TARGET_BIN)
	cp -v ./mpv $(TARGET_BIN)
	cp -v ./mpv-* $(TARGET_BIN)

