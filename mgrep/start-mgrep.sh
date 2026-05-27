#!/bin/sh
# Start mgrep daemon and watch the dictionary file for changes.
# When the dictionary is updated, mgrep is restarted automatically so the
# new terms are picked up without requiring a manual container restart.

DICT_FILE=/srv/mgrep/dictionary/dictionary.txt
MGREP_CMD="/usr/local/bin/mgrep --port 55556 -w /srv/mgrep/word_divider.txt -c /srv/mgrep/CaseFolding.txt -f $DICT_FILE"
RELOAD_INTERVAL=30  # seconds between dictionary hash checks

start_mgrep() {
  $MGREP_CMD
  sleep 2  # give mgrep time to daemonize and bind the port
  echo "$(date): mgrep (re)started"
}

start_mgrep
DICT_HASH=$(md5sum "$DICT_FILE" | cut -d' ' -f1)
echo "$(date): initial dictionary hash: $DICT_HASH"

while true; do
  sleep $RELOAD_INTERVAL
  NEW_HASH=$(md5sum "$DICT_FILE" | cut -d' ' -f1)
  if [ "$NEW_HASH" != "$DICT_HASH" ]; then
    echo "$(date): dictionary changed (was $DICT_HASH, now $NEW_HASH) — restarting mgrep..."
    DICT_HASH=$NEW_HASH
    pkill mgrep 2>/dev/null || true
    sleep 1
    start_mgrep
  fi
done
