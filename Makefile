.DEFAULT_GOAL := install
TARGET_BIN="${HOME}/.local/bin"

install:
	echo "Installing into $(TARGET_BIN)"
	mkdir -p $(TARGET_BIN)
	cp -v ./mpv ./mpv-* $(TARGET_BIN)

