#!/bin/bash

PSQL="psql -X --username=freecodecamp --dbname=number_guess -t --no-align -c"

MAIN() {
  echo "Enter your username:"
  read -n 22  USERNAME
  CHECK_USERNAME $USERNAME
  START_GAME $USERNAME
}

CHECK_USERNAME() {
  SELECTED_USERNAME=$($PSQL "SELECT * FROM games WHERE username = '$1'")
  if [[ -z $SELECTED_USERNAME ]]
  then
    ADDED_USERNAME=$($PSQL "INSERT INTO games(username) VALUES('$1')")
    echo "Welcome, $1! It looks like this is your first time here."
  else
    FORMATTED_USERNAME=$(echo $SELECTED_USERNAME | sed -E 's/\|/ /g' | sed -E 's/(.+) (.*) (.*)/Welcome back\, \1\! You have played \2 games\, and your best game took \3 guesses\./')
    echo "$FORMATTED_USERNAME"
  fi
}

START_GAME() {
  SECRET_NUMBER=$((RANDOM % (1000 - 1 + 1) + 1))
  GUESS_COUNT=0
  echo "Guess the secret number between 1 and 1000:"
  CHECK_ANSWER $SECRET_NUMBER $GUESS_COUNT
  UPDATE_DATABASE $1 $GUESS_COUNT
}

CHECK_ANSWER() {
  GUESS_COUNT=$(($2 + 1))
  read ANSWER
  if [[ $ANSWER =~ ^[0-9]+$ ]]
  then
    if [ "$1" -lt "$ANSWER" ]
    then
      echo "It's lower than that, guess again:"
      CHECK_ANSWER $1 $GUESS_COUNT
    elif [ "$1" -gt "$ANSWER" ]
    then
      echo "It's higher than that, guess again:"
      CHECK_ANSWER $1 $GUESS_COUNT
    else
      echo "You guessed it in $GUESS_COUNT tries. The secret number was $1. Nice job!"
    fi
  else
    echo "That is not an integer, guess again:"
    CHECK_ANSWER $1 $GUESS_COUNT
  fi
}

UPDATE_DATABASE() {
  GAMES_PLAYED=$($PSQL "SELECT games_played FROM games WHERE username = '$1'")
  BEST_GAME=$($PSQL "SELECT best_game FROM games WHERE username = '$1'")
  if [[ -z $GAMES_PLAYED ]]
  then
    UPDATED_GAMES_PLAYED=$($PSQL "UPDATE games SET games_played = 1 WHERE username = '$1'")
    UPDATED_BEST_GAME=$($PSQL "UPDATE games SET best_game = $2 WHERE username = '$1'")
  else
    UPDATED_GAMES_PLAYED=$($PSQL "UPDATE games SET games_played = $GAMES_PLAYED + 1 WHERE username = '$1'")
    if [ "$2" -lt "$BEST_GAME" ]
    then
      UPDATED_BEST_GAME=$($PSQL "UPDATE games SET best_game = $2 WHERE username = '$1'")
    fi
  fi
}

MAIN
