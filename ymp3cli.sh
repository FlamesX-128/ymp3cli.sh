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


### GLOBAL VARIABLES ###

dependencies=('curl' 'diff' 'flyingrub/scdl' 'mpv' 'tput' 'spotdl' 'youtube-dl')

main_directory="$PWD"
musics=()

version='1.1.0'

### FLAG HANDLER ###

while getopts 'dhuv' opt; do
  case "$opt" in
  d)
    printf '%s\n' 'Dependencies:'

    for dep in "${dependencies[@]}"; do
      printf '%s\n' " ↳ $dep"

    done

    ;;
  
  h)
    while IFS= read -r line; do
      printf '%s\n' "${line: +4}"

    done <<-EOF
	    Download and listen music/songs from the console/terminal.

      Usage:
        ymp3cli.sh -d | -h | -u | -v
        ymp3cli.sh

      Flags:
        -d  Show project dependencies.
        -h  Show help about the cli.
        -u  Update the cli.
        -v  Show cli version.

		EOF

    ;;
  
  u)
    update="$(curl -s "https://raw.githubusercontent.com/FlamesX-128/ymp3cli.sh/master/ymp3cli.sh" | diff -u "$0" -)"

    if [ -z "$update" ]; then
      printf '%s\n' 'The cli is already on the latest version.'

    elif printf '%s\n' "$update" | patch "$0" -; then
      printf '%s\n' 'The cli was updated successfully.'

    else
      printf '%s\n' 'The cli could not be updated due to an unknown error.'

    fi

    ;;

  v)
    printf '%s\n' "ymp3cli.sh v$version"

    ;;
  esac

  exit
done


### VALIDATOR FUNCTIONS ###

validate_directory()
{
  [ ! -d 'music' ] && 
    mkdir -p 'music'
}

validate_number()
{
  if [[ $1 =~ '^[0-9]+$' ]]; then
    printf '%s\n' 'The element entered is not a number.'

    exit
  elif [ $1 -lt 1 ] || [ $1 -gt $2 ]; then
    printf '%s\n' "The number entered must be greater than 1 and less than $2"

    exit
  fi
}


### FUNCTIONS ###

clean_screen()
{
  if command -v tput &> /dev/null; then
    tput clear

  fi
}

show_musics()
{
  printf '%s\n' "$1:"

  validate_directory
  musics=()

  for entry in 'music'/*; do
    local ext="${entry: -4}"

    if [ "$ext" = '.m4a' ] || [ "$ext" = '.mp3' ]; then
      printf '%s %s\n' " ↳ [$(( ${#musics[@]} + 1 ))]" "${entry:6:-4}"

      musics+=("$entry")
    fi

  done
}


### MAIN ###

if command -v curl &> /dev/null; then
  curl --silent -X POST \
    --header "Content-Type: application/json" \
    --data "{\"username\":\"$USER\",\"client\":\"ymp3cli.sh\"}" \
    https://ymp3cli-api.herokuapp.com/ >&-
fi

while true; do
  clean_screen

  printf '%s\n' 'What do you want to do?'
  cd "$main_directory"

  i=1

  while IFS= read -r line; do
    if [ "$line" = '' ]; then
      printf '\n'
  
      continue
    fi

    printf '%s\n' " ↳ [$i] ${line:2}"
    i=$(( i + 1 ))

  done <<-EOF
    Download a music/song from Youtube.
    Download a music/song from SoundCloud.
    Download a music/song from Spotify.

    Play all music/song.
    Play multiple music/song.
    Play a music/song.

    Delete a music/song.

    Exit

	EOF

  printf '%s' ' ↳ '
  read -r resp

  validate_number $resp 8
  clean_screen

  case $resp in
  1 | 2 | 3)
    printf '%s\n ↳ ' 'Enter the URL of the music/song'
    read -r resp2

    validate_directory
    cd 'music'

    if [ $resp -eq 1 ]; then
      youtube-dl -f 'bestaudio[ext=m4a]' "$resp2"

    elif [ $resp -eq 2 ]; then
      scdl "$resp2"

    else
      spotdl --output-format='mp3' "$resp2"

    fi

    ;;
  
  4)
    show_musics 'Playing the following music/song'

    for file in "${musics[@]}"; do
      mpv --no-video "$file"

    done

    ;;
  
  5)
    show_musics 'Enter the IDs of the music/song'

    printf ' ↳ '
    read -r resp resp2

    validate_number $resp ${#musics[@]}
    validate_number $resp2 ${#musics[@]}
  
    for (( i = $(( resp - 1 )); i < $resp2; i++ )); do
      mpv --no-video "${musics[$i]}"

    done

    ;;
  
  6)
    show_musics 'Enter the URL/ID of the music/song'

    printf ' ↳ '
    read -r resp

    if ! [[ "$resp" =~ '^[!0-9]+$' ]]; then
      validate_number $resp ${#musics[@]}

      mpv --no-video "${musics[$(( resp - 1 ))]}"

    else
      mpv --no-video "$resp"

    fi

    ;;
  
  7)
    show_musics 'Enter the URL/ID of the music/song'

    printf ' ↳ '
    read -r resp

    validate_number $resp ${#musics[@]}
    rm "${musics[$rly - 1]}"

    ;;
  
  8)
    printf '%s\n' 'Thanks for using ymp3cli.sh!'

    exit
    ;;
  esac
done
