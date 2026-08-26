# Chaînes visibles d'AI Kit. Source unique : strings.json, lu aussi par rows.py.
# Langue : $AIKIT_LANG, sinon la locale (LC_ALL/LC_MESSAGES/LANG), anglais par défaut.

case "${AIKIT_LANG:-${LC_ALL:-${LC_MESSAGES:-${LANG:-en}}}}" in
  fr*) AIKIT_L=fr ;;
  *)   AIKIT_L=en ;;
esac
export AIKIT_L

declare -A AIKIT_T
while IFS=$'\t' read -r _k _v; do
  [[ -n $_k ]] && AIKIT_T[$_k]=$_v
done < <(jq -r --arg l "$AIKIT_L" '.[$l] | to_entries[] | "\(.key)\t\(.value)"' \
         "$HOME/.local/share/aikit/strings.json" 2>/dev/null)
unset _k _v

t() { # t <clé> [args de printf...] — une clé absente s'affiche telle quelle
  local key="$1"; shift
  printf "${AIKIT_T[$key]-$key}" "$@"
}
