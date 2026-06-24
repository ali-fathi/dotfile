##### https://pi.dev/
# ------------------------------------------
# Pi shortcut (p → polished output, macOS-safe)
# ------------------------------------------

p() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: p <query>"
    return 1
  fi

  local query="$*"
  local output
  output=$(pi -p "$query")

  # Header
  echo "\033[1;35m[pi]\033[0m $query"
  echo

  # Clean + format output (macOS safe)
  echo "$output" | sed -E '
    s/\*\*([^*]+)\*\*/\1/g;   # remove **bold**
    s/^> /  → /;              # quote → arrow
    s/^- /  • /;              # nicer bullets
  ' | awk '
    NF {
      if (blank) { print ""; blank=0 }
      print
    }
    !NF { blank=1 }           # collapse empty lines
  '

  echo
}
