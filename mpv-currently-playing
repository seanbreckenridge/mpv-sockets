#!/usr/bin/env bash
# mpv-get-property wrapper that gets full path of currently playing song
# If there are multiple instances of mpv playing at the same time,
# prints both
#
# Can provide the --socket flag to instead print the socket of the
# current mpv instance
#
# Pass the --all flag to print the path for all items, regardless
# of whether or not they're playing currently

declare PRINT_SOCKET=''
declare ALLOW_PAUSED=''
while [[ -n "$1" ]]; do
	case "$1" in
	--socket)
		PRINT_SOCKET='1'
		;;
	--all)
		ALLOW_PAUSED='1'
		;;
	*)
		printf 'Unknown option passed: %s\n' "$1" >&2
		exit 1
		;;
	esac
	shift
done
readonly PRINT_SOCKET ALLOW_PAUSED

# change directory to root, so when we try to compute the absolute path,
# it doesn't fail since the playing file is the current directory
cd /

declare -a result=()
for socket in $(mpv-active-sockets); do

	# if the user didn't specify the --all flag
	if ! ((ALLOW_PAUSED)); then
		# ignore items that aren't playing
		IS_PAUSED="$(mpv-get-property "${socket}" 'pause')"
		[[ "${IS_PAUSED}" == "true" ]] && continue
	fi

	if [[ -n "${PRINT_SOCKET}" ]]; then # if user asked for socket, just print the socket
		result+=("${socket}")
	else
		# else, try to get the full song path
		FULL_SONG_PATH='' # reset full song path var
		if REL_SONG_PATH="$(mpv-get-property "${socket}" 'path' 2>/dev/null)"; then
			# if the path doesn't correspond to its absolute path, or this doesn't exist, try prepending the working directory
			[[ -n "${REL_SONG_PATH}" && -e "${REL_SONG_PATH}" ]] || {
				FULL_SONG_PATH="$(mpv-get-property "${socket}" 'working-directory')/${REL_SONG_PATH}"
			}
			if [[ -n "${FULL_SONG_PATH}" && -e "${FULL_SONG_PATH}" ]]; then
				# prints the absolute path, if it exists
				result+=("${FULL_SONG_PATH}")
			else
				# relative song path, typically a URL?
				result+=("${REL_SONG_PATH}")
			fi
		fi
	fi
done

# switch on length of array (number of paths found)
case "${#result[@]}" in
0)
	exit 1
	;;
*)
	(
		IFS=$'\n'
		echo "${result[*]}"
	)
	;;
esac
