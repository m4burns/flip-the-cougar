#!/bin/sh -e

cd "$(dirname "$0")"
docker build -t m4burns/ftc:latest .
