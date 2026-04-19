#!/usr/bin/env bash
# run_tests.sh — parse every .sql file under tests/corpus/ with the generated
# ANTLR4 parser via a single-JVM, multi-threaded runner
# (tests/CorpusRunner.java). Exits non-zero on any parse error.
#
# Usage:
#   tests/run_tests.sh [--corpus <dir>] [--verbose] [--threads N]
#
# The first run downloads antlr-4.13.2-complete.jar to ~/.cache/antlr4/ and
# compiles the grammar + runner.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CORPUS="$REPO_ROOT/tests/corpus"
EXTRA_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --corpus)       CORPUS="$2"; shift 2 ;;
        --verbose|-v)   EXTRA_ARGS+=("--verbose"); shift ;;
        --threads)      EXTRA_ARGS+=("--threads" "$2"); shift 2 ;;
        -h|--help)
            sed -n '2,11p' "$0"; exit 0 ;;
        *) echo "unknown arg: $1" >&2; exit 2 ;;
    esac
done

ANTLR_VERSION="4.13.2"
ANTLR_JAR="${ANTLR_JAR:-$HOME/.cache/antlr4/antlr-${ANTLR_VERSION}-complete.jar}"

if [[ ! -f "$ANTLR_JAR" ]]; then
    mkdir -p "$(dirname "$ANTLR_JAR")"
    echo ">>> downloading ANTLR $ANTLR_VERSION to $ANTLR_JAR"
    curl -fsSL -o "$ANTLR_JAR" "https://www.antlr.org/download/antlr-${ANTLR_VERSION}-complete.jar"
fi

BUILD="$REPO_ROOT/build"
mkdir -p "$BUILD"

need_rebuild=0
for g in "$REPO_ROOT/ClickHouseLexer.g4" "$REPO_ROOT/ClickHouseParser.g4"; do
    if [[ ! -f "$BUILD/ClickHouseParser.class" || "$g" -nt "$BUILD/ClickHouseParser.class" ]]; then
        need_rebuild=1
    fi
done
if [[ $need_rebuild -eq 1 ]]; then
    echo ">>> generating and compiling parser"
    (cd "$REPO_ROOT" && java -jar "$ANTLR_JAR" -Dlanguage=Java -o "$BUILD" ClickHouseLexer.g4 ClickHouseParser.g4)
    (cd "$BUILD"      && javac -cp "$ANTLR_JAR" *.java)
fi

RUNNER_SRC="$REPO_ROOT/tests/CorpusRunner.java"
RUNNER_CLASS="$BUILD/CorpusRunner.class"
if [[ ! -f "$RUNNER_CLASS" || "$RUNNER_SRC" -nt "$RUNNER_CLASS" ]]; then
    javac -cp "$ANTLR_JAR:$BUILD" -d "$BUILD" "$RUNNER_SRC"
fi

exec java -cp "$ANTLR_JAR:$BUILD" CorpusRunner "$CORPUS" "${EXTRA_ARGS[@]}"
