#!/usr/bin/env bash
set -euo pipefail

MESSAGE='if you were interrupted due to session limits, please continue'
COUNT=0
START=""
TARGETS=()

usage() {
    cat <<EOF
Usage: $0 -t <NxHH:MM> -s <target [, target ...]>

  -t  NxHH:MM   fire N times starting at HH:MM, repeat every 5h
  -s  targets   comma/space separated tmux targets (session:window.pane)
EOF
    exit 1
}

while getopts "t:s:" OPT; do
    case "$OPT" in
        t)
            COUNT="${OPTARG%%x*}"
            START="${OPTARG##*x}"
            ;;
        s)
            IFS=', ' read -ra PARTS <<< "$OPTARG"
            for P in "${PARTS[@]}"; do
                [ -n "$P" ] && TARGETS+=("$P")
            done
            ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))

for ARG in "$@"; do
    TARGETS+=("$ARG")
done

[ "$COUNT" -gt 0 ] 2>/dev/null || usage
[ -n "$START" ] || usage
[ "${#TARGETS[@]}" -gt 0 ] || usage

T0=$(date -j -f "%H:%M" "$START" +%s)
[ "$T0" -le "$(date +%s)" ] && T0=$((T0 + 86400))

echo "will fire ${COUNT}x starting ${START}, every 5h, to: ${TARGETS[*]}"

for i in $(seq 0 $((COUNT - 1))); do
    NEXT=$((T0 + i * 3600 * 5))
    SLEEP=$((NEXT - $(date +%s)))
    [ "$SLEEP" -le 0 ] && SLEEP=0
    sleep "$SLEEP"
    for TARGET in "${TARGETS[@]}"; do
        tmux send-keys -t "$TARGET" "$MESSAGE" Enter
    done
    printf "sent at +%dh\n" $((i * 5))
done