# ==========================================
# ⚡ AI Shell (Clean + Proper Detailed Mode)
# ==========================================

setopt NO_BAD_PATTERN

AI_COLOR="\033[1;36m"
AI_DIM="\033[2m"
AI_RESET="\033[0m"

# ---- patterns (tailored to your install) ----
AI_SHORT_PATTERN="summarize"
AI_DETAILED_PATTERN="analyze_prose"
AI_CODE_PATTERN="explain_code"

# ---- detect code vs query ----
_ai_detect() {
  local input="$1"

  if [[ "$input" == *";"* || "$input" == *"{"* || "$input" == *"=>"* || "$input" == *"function"* ]]; then
    echo "$AI_CODE_PATTERN"
  else
    echo "$AI_SHORT_PATTERN"
  fi
}

# ---- format output ----
_ai_format() {
  sed '
    /^## /d;              # remove Fabric headings
    s/^[-*] /• /;         # nicer bullets
  ' | awk 'NF {print} !NF{print ""}'
}

# ---- runner ----
_ai_run() {
  local prompt="$1"
  local pattern="$2"

  prompt=$(echo "$prompt" | head -c 20000)

  echo "${AI_COLOR}[ai]${AI_RESET} ${AI_DIM}${pattern}${AI_RESET}"
  echo

  fabric -p "$pattern" "$prompt" | _ai_format

  echo
}

# ---- stdin ----
_ai_stdin() {
  [ ! -t 0 ] && cat
}

# ---- help ----
ai-help() {
cat <<'EOF'

AI CLI (Clean Mode)
==================

ai what is kubernetes
  → short answer

ai -s docker swarm
  → short answer

ai -d kubernetes architecture
  → detailed explanation

ai -e "for i in range(10)"
  → explain code

ai -c
  → explain clipboard

ai -f app.py
  → explain file

ai -i
  → interactive mode

Pipe:
  cat error.log | ai

EOF
}

# ---- main ----
ai() {
  local mode="auto"
  local input=""
  local stdin_data=$(_ai_stdin)

  case "$1" in
    -s) mode="short"; shift; input="$*" ;;
    -d) mode="detailed"; shift; input="$*" ;;
    -e) mode="explain"; shift; input="$*" ;;
    -c) mode="clipboard" ;;
    -f) mode="file"; input="$2" ;;
    -i) mode="interactive" ;;
    --help) ai-help; return ;;
    *) input="$*" ;;
  esac

  # pipe override
  if [[ -n "$stdin_data" ]]; then
    input="$stdin_data"
    mode="auto"
  fi

  case "$mode" in

    short)
      [[ -z "$input" ]] && ai-help && return
      _ai_run "$input" "$AI_SHORT_PATTERN" | head -n 10
      ;;

    detailed)
      [[ -z "$input" ]] && ai-help && return
      _ai_run "$input" "$AI_DETAILED_PATTERN"
      ;;

    explain)
      _ai_run "$input" "$AI_CODE_PATTERN"
      ;;

    auto)
      [[ -z "$input" ]] && ai-help && return
      local pattern=$(_ai_detect "$input")

      if [[ "$pattern" == "$AI_SHORT_PATTERN" ]]; then
        _ai_run "$input" "$pattern" | head -n 10
      else
        _ai_run "$input" "$pattern"
      fi
      ;;

    clipboard)
      local content=$(pbpaste)
      [[ -z "$content" ]] && echo "Clipboard empty" && return 1
      _ai_run "$content" "$AI_CODE_PATTERN"
      ;;

    file)
      if [[ -f "$input" ]]; then
        echo "${AI_DIM}[file: $input]${AI_RESET}"
        _ai_run "$(head -c 20000 "$input")" "$AI_CODE_PATTERN"
      else
        echo "File not found"
      fi
      ;;

    interactive)
      echo "AI interactive mode (exit to quit)"
      while true; do
        echo -n "ai> "
        read q
        [[ "$q" == "exit" ]] && break
        [[ -z "$q" ]] && continue

        local pattern=$(_ai_detect "$q")
        _ai_run "$q" "$pattern"
      done
      ;;
  esac
}

alias a="ai"

# ==========================================
# END
# ==========================================
