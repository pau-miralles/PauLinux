#!/usr/bin/env bash
current=$(powerprofilesctl get)

case "$current" in
  power-saver) next=balanced ;;
  balanced) next=performance ;;
  performance) next=power-saver ;;
esac

powerprofilesctl set "$next"
