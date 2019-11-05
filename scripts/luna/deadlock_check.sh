# Check if there is any simulation exited with deadlock (or any type of errors)
# Usage: ./deadlock_check.sh

grep "DEAD\|ERROR\|not empty\|gzip\|Stale" ./results_50M/*
