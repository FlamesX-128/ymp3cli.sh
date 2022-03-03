#!/bin/sh

### LICENSE ###

# MIT License

# Copyright (c) 2022 FlamesX-128

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

### END OF LICENSE ###


### PROJECT INFO ###

audioplayer="mpv"

dependencies=("curl" "mpv" "tput" "spotdl" "youtube-dl")
devDependencies=()

version="1.0.0"

### END OF PROJECT INFO ###


### ###

print_options() {
  while IFS= read -r line; do
    printf '%s\n' "$line"
  done <<-EOF

  Download and listen songs/music from the console/terminal.

  Usage:
    ymp3cli.sh -d | -h | -v
    ymp3cli.sh

  Options:
    -d  Show project dependencies.
    -h  Show help about the cli.
    -u  Update the cli.
    -v  Show cli version.

	EOF
}

while getopts 'dhuv' opt; do
  case "$opt" in
  d)
    printf '%s\n' 'Dependencies:'

    for dep in "${deps[@]}"; do
      printf ' ↳ %s\n' "$dep"
    done

    exit
    ;;

  h)
    print_options
    exit
    ;;

  u)
    update="$(curl -s "https://raw.githubusercontent.com/FlamesX-128/ymp3cli.sh/master/ymp3cli.sh" | diff -u "$0" -)"

    [ -z "$update" ] && printf 'The cli is already on the latest version.'

    if printf '%s\n' "$update" | patch "$0" -; then
      printf 'The cli has been updated.'

      exit
    fi

    printf '%s\n' "Can't update for some reason!"
    exit
    ;;

  v)
    printf 'ymp3cli.sh %s\n' "$version"
    exit
    ;;
  esac
done

### ###


### VALIDATORS ###

validate_directory() {
  [[ ! -d "music" ]] && mkdir -p 'music'
}

validate_number() {
  [ $1 -lt 1 ] || [ $1 -gt $2 ] &&
    printf '%s\n' 'Invalid number entered.' && exit
}

### END OF VALIDATORS ###


### FUNCTIONS ###

clear_screen() {
  if command -v tput &>/dev/null; then
    tput clear
  fi
}

show_musics() {
  printf '%s\n' "$1:"
  musics=()

  for entry in 'music'/*; do
    file="${entry: -4}"

    if [ "$file" == ".m4a" ] || [ "$file" == ".mp3" ]; then
      printf ' ↳ %s\n' "[$((${#musics[@]} + 1))] ${entry: +6}"
      musics+=("$entry")

    fi

  done
}

### END OF FUNCTIONS ###


### MAIN ###

while true; do
  clear_screen

  printf '%s\n' 'What do you want to do?'
  i=1

  while IFS= read -r line; do
    [ "$line" = "" ] && printf '%s\n' "$line" && continue

    printf '%s\n' "[$i] $line"
    i=$(($i + 1))
  done <<-EOF
  Download a music/song from Youtube.
  Download a music/song from Spotify.

  Play all music/song.
  Play multiple music/song.
  Play a music/song.

  Delete a music/song.

  Exit
	EOF

  printf '\n ↳ '
  read -r rly

  validate_number $rly 7
  clear_screen

  case $rly in
  1 | 2)
    printf '%s\n ↳ ' 'Enter the URL of the song/music:'
    read -r rly2

    validate_directory
    cd 'music'

    [[ "$rly" -eq 1 ]] &&
      youtube-dl -f 'bestaudio[ext=m4a]' "$rly2" ||
      spotdl --output-format='mp3' "$rly2"

    cd ..
    ;;

  3)
    show_musics 'Playing the following music/songs'
    printf '\n'

    for file in "${musics[@]}"; do
      mpv --no-video "$file"

    done
    ;;

  4)
    show_musics 'Enter the IDs of the songs/musics'

    printf ' ↳ '
    read -r rly rly2

    validate_number $rly ${#musics[@]}
    validate_number $rly2 ${#musics[@]}

    for ((i = $((rly - 1)); i < $rly2; i++)); do
      mpv --no-video "${musics[$i]}"

    done
    ;;

  5)
    show_musics 'Enter the URL/ID of the song/music'

    printf ' ↳ '
    read -r rly

    [[ "$rly" =~ '^[!0-9]+$' ]] && mpv --no-video "$rly" && break

    validate_number $rly ${#musics[@]}
    mpv --no-video "${musics[$(($rly - 1))]}"
    ;;

  6)
    show_musics 'Enter the ID of the song/music'

    printf ' ↳ '
    read -r rly

    validate_number $rly ${#musics[@]}
    rm "${musics[$rly - 1]}"
    ;;

  7)
    printf '%s\n' 'Thanks for using ymp3cli.sh!'
    exit
    ;;
  esac
done
