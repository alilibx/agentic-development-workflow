#!/bin/sh
# runs-gh-pr.sh VERB < command
#
# Exit 0 when the shell command on stdin would run `gh pr VERB`, 1 otherwise.
# Shared by the repo's .claude/hooks/pr-lifecycle.sh and the global
# ~/.claude/hooks/pr-review-policy.sh. The two copies in the templates are
# kept identical by a test; change both together.
#
# A substring match fires on heredocs, commit messages and echo lines that only
# mention the command. So a small tokenizer first reduces the command to the
# text bash would execute as commands:
#   - single-quoted and $'...' strings are dropped, across lines;
#   - double-quoted text is dropped, across lines, but a $(...) or `...`
#     inside it is kept, because bash runs it;
#   - heredoc bodies are dropped. A heredoc starts only at an unquoted <<
#     outside $(( )), its delimiter may be any quoted or unquoted word, and
#     the body ends at a line that is exactly that word (leading tabs
#     stripped for <<-);
#   - arithmetic $(( )) and (( )) is dropped, so a << shift is not a heredoc;
#   - comments are dropped;
#   - every $(...) and `...` becomes a line of its own, and a `_` takes its
#     place in the surrounding command.
# Then `gh pr VERB` must start a command on one of those lines: at the start
# of the line or after ; & | ( or &&, optionally after VAR=value prefixes and
# gh's -R/--repo flag.
#
# Known limits, all rare in agent commands: $(...) inside an unquoted heredoc
# body is not scanned, and a `case` pattern's `)` inside $(...) closes it early.
#
# POSIX awk only (gawk, mawk, BusyBox and BSD awk). Set AWK to test another.

verb="$1"

${AWK:-awk} -v sq="'" '
function push(type, d) {
  sp++; ctx[sp] = type; depth[sp] = d
  if (type == "P" || type == "B") { parent[sp] = cb; cb = sp; buf[sp] = ""; prev = "\n" }
}
function pop() {
  if (ctx[sp] == "P" || ctx[sp] == "B") {
    side = side buf[sp] "\n"     # the substitution is a command line of its own
    cb = parent[sp]
    emit("_")                    # and a plain word where it stood
  }
  sp--
}
function emit(s) { buf[cb] = buf[cb] s; prev = s }

# A delimiter word: unquoted characters plus the contents of any quotes,
# up to a blank or an operator. Sets wend to the index after the word.
function heredoc_word(s, j,    n, d, k, w) {
  n = length(s); w = ""
  while (j <= n) {
    d = substr(s, j, 1)
    if (d == " " || d == "\t" || index(";&|<>()", d)) break
    if (d == sq || d == "\"") {
      k = index(substr(s, j + 1), d)
      if (k == 0) { w = w substr(s, j + 1); j = n + 1; break }
      w = w substr(s, j + 1, k - 1); j += k + 1; continue
    }
    if (d == "\\") { w = w substr(s, j + 1, 1); j += 2; continue }
    w = w d; j++
  }
  wend = j
  return w
}

function scan(s,    n, i, c, top, joined, strip, j, w) {
  n = length(s); i = 1; joined = 0
  while (i <= n) {
    c = substr(s, i, 1); top = ctx[sp]

    if (top == "S") { if (c == sq) pop(); i++; continue }
    if (top == "E") {
      if (c == "\\") i += 2; else { if (c == sq) pop(); i++ }
      continue
    }
    if (top == "A") {
      if (c == "(") depth[sp]++
      else if (c == ")" && --depth[sp] == 0) pop()
      i++; continue
    }
    if (top == "D") {
      if (c == "\\") { i += 2; continue }
      if (c == "\"") { pop(); emit("\""); i++; continue }
      if (c == "`") { push("B", 0); i++; continue }
      if (substr(s, i, 3) == "$((") { push("A", 2); i += 3; continue }
      if (substr(s, i, 2) == "$(") { push("P", 1); i += 2; continue }
      i++; continue
    }

    # A command context: top level (N), $( ) (P) or backticks (B).
    if (c == "\\") {
      if (i == n) { joined = 1; i++; continue }   # line continuation
      c = substr(s, i + 1, 1)
      emit((c ~ /[A-Za-z0-9_]/) ? c : "_"); i += 2; continue
    }
    if (c == "#" && index(" \t;&|()<>\n", prev)) break   # a comment
    if (c == sq) { push("S", 0); emit(sq sq); i++; continue }
    if (substr(s, i, 2) == "$" sq) { push("E", 0); emit(sq sq); i += 2; continue }
    if (c == "\"") { emit("\""); push("D", 0); i++; continue }
    if (substr(s, i, 2) == "$\"") { emit("\""); push("D", 0); i += 2; continue }
    if (c == "`") {
      if (top == "B") pop(); else push("B", 0)
      i++; continue
    }
    if (substr(s, i, 3) == "$((") { push("A", 2); emit("_"); i += 3; continue }
    if (substr(s, i, 2) == "((" && index(" \t;&|()\n", prev)) {
      push("A", 2); emit("_"); i += 2; continue
    }
    if (substr(s, i, 2) == "$(") { push("P", 1); i += 2; continue }
    if (c == "(" && top == "P") { depth[sp]++; emit(c); i++; continue }
    if (c == ")" && top == "P") {
      if (--depth[sp] == 0) pop(); else emit(c)
      i++; continue
    }
    if (substr(s, i, 3) == "<<<") { emit("<<<"); i += 3; continue }
    if (substr(s, i, 2) == "<<") {
      j = i + 2; strip = 0
      if (substr(s, j, 1) == "-") { strip = 1; j++ }
      while (substr(s, j, 1) == " " || substr(s, j, 1) == "\t") j++
      w = heredoc_word(s, j)
      if (wend > j) { nq++; qdelim[nq] = w; qstrip[nq] = strip }   # a word was read, even an empty one like ''
      emit("<<_"); i = wend; continue
    }
    emit(c); i++
  }

  # The newline ends a command only outside quotes and arithmetic.
  top = ctx[sp]
  if ((top == "N" || top == "P" || top == "B") && !joined) {
    emit("\n")
    if (nq > 0) hd = 1        # heredoc bodies start on the next line
  }
}

BEGIN { sp = 0; cb = 0; side = ""; nq = 0; hd = 0; push("N", 0); cb = 1; buf[1] = ""; prev = "\n" }

hd > 0 {
  line = $0
  if (qstrip[hd]) sub(/^\t+/, "", line)
  if (line == qdelim[hd] && ++hd > nq) { hd = 0; nq = 0 }
  next
}

{ scan($0) }

END {
  # Unclosed substitutions still count: print every command buffer.
  for (k = sp; k >= 1; k--) if (ctx[k] == "P" || ctx[k] == "B" || ctx[k] == "N") side = side buf[k] "\n"
  printf "%s", side
}
' | grep -Eq "(^|[;&|(]|&&)[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*gh([[:space:]]+(-R|--repo)([[:space:]]+|=)[^[:space:]]+)?[[:space:]]+pr[[:space:]]+$verb([[:space:];&|)]|$)"
