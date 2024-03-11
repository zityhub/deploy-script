#!/bin/bash

declare -r end_colour="\033[0m\e[0m"
declare -r red_colour="\e[0;31m\033[1m"
declare -r yellow_colour="\e[0;33m\033[1m"
declare -r gray_colour="\e[0;37m\033[1m"

timestamp=$(date +%s)
file_log="$(cd "$(dirname "$0")" && pwd)/deploy.log"
changelog="$(pwd)/CHANGELOG.md"
declare -r timestamp
declare -r file_log

trap ctrl_c INT

function ctrl_c() {
  print_info "Coming out...."
  finish_script 0
}

function start_script() {
  set +e
  tput civis
  clear
}

function finish_script() {
  exit_code=$1 || 0
  tput cnorm
  set -e
  exit "$exit_code"
}

function print_info() {
  printf "${yellow_colour}[*] ${end_colour}${gray_colour}%s${end_colour}\n" "$1"
}

function print_info_raw() {
  printf "%s\n" "$1"
}

function print_error() {
  printf "${yellow_colour}[!] ${end_colour}${red_colour}%s${end_colour}\n" "$1"
}

function print_empty_line() {
  printf "\n"
}

function deploy() {
  version=$1
  main_branch=$2
  print_info "🚀 Starting deploy"

  print_info "Step 1 -> git fetch"
  git fetch >> "$file_log" 2>&1

  print_info "Step 2 -> git pull origin $main_branch"
  git pull origin "$main_branch" >> "$file_log" 2>&1

  print_info "Step 3 -> pnpm version"
  tag=$(pnpm version "$version")

  print_info "Step 4 -> edit changelog"
  update_changelog
  git add "$changelog" && git commit -m "CHANGELOG.md edited ($tag)" >> "$file_log" 2>&1

  print_info "Step 5 -> git push origin $main_branch"
  git push origin "$main_branch" >> "$file_log" 2>&1

  print_info "Step 6 -> git push tag $tag"
  git push origin "$tag" >> "$file_log" 2>&1

  print_info "Step 7 -> deploy $tag in production"
  git push origin refs/tags/"$tag"^\{commit\}:refs/heads/production --force >> "$file_log" 2>&1

  print_info "Deploying was finished 💪"
}

function clean_repository() {
  main_branch=$2
  print_empty_line
  print_info "🧹 Starting clean repository"

  print_info "Step 1 -> git fetch"
  git fetch >> "$file_log" 2>&1

  print_info "Step 2 -> git pull --all"
  git pull --all >> "$file_log" 2>&1

  print_info "Step 3 -> git remote prune origin"
  git remote prune origin >> "$file_log" 2>&1

  print_info "Step 4 -> clean local branches"
  git branch --merged | egrep -v "(^\*|$main_branch|production|sandbox)" | xargs git branch -d >> "$file_log" 2>&1

  print_info "Step 5 -> clean origin branches"
  git branch -r --merged | egrep -v "(^\*|$main_branch|production|sandbox)" | sed s/origin\\/// | xargs -n 1 git push --delete origin >> "$file_log" 2>&1
}

function ensure_correct_branch() {
  branch="$(git rev-parse --abbrev-ref HEAD)";
  if [[ "$branch" != "$main_branch" ]]; then
    print_error "Current branch must be $main_branch";
    finish_script 1;
  fi
}

function ensure_parameter() {
  parameter_counter=$1
  version=$2

  if [[ "$parameter_counter" == 0 ]]; then
    print_error "Parameter [-v] is required" && finish_script 1
  fi

  if [[ "$version" != "patch" && "$version" != "minor" && "$version" != "major" && "$version" != "dry" ]]; then
    print_error "Must select one valid type (major, minor or patch)"
  fi
}

function update_changelog() {
  divider="\n---\n"
  if [ ! -e "$changelog" ] ; then
      touch "$changelog"
      printf "%b" "$divider" > "$changelog"
  fi
  title="**[$tag] - $(date '+%Y-%m-%d')**"
  message="- $message"
  sed -i.bak "1s/^/$divider\n$title\n$message\n/" "$changelog" && rm "$changelog.bak"
}

function main() {
  start_script

  parameter_counter=0
  main_branch="master"
  while getopts ":v:b:" arg; do
    case $arg in
      v) version=$OPTARG && ((parameter_counter+=1)) ;;
      b) main_branch=$OPTARG ;;
      *) print_error "Usage: $0 [-v] [-b]" && finish_script 1 ;;
    esac
  done

  ensure_correct_branch
  ensure_parameter "$parameter_counter" "$version"

  print_info "You go to deploy $version in production, is correct? (Intro to continue)" && read -r
  print_info_raw "-------------------- $timestamp --------------------" >> "$file_log"

  print_info "Write changes description:" && read -r message
  print_info "Changes message: --- $message --- is correct? (Intro to continue)" && read -r

  if [[ "$version" != "dry" ]]; then
      deploy "$version" "$main_branch"
      clean_repository "$main_branch"
  else
      print_info_raw "🚀 Simulating deploy"
      print_info_raw "🧹 Simulating clean"
  fi

  finish_script 0
}

main "$@"
