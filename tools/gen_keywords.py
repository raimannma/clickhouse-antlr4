#!/usr/bin/env python3
"""Verify the lexer keyword set matches ClickHouse's upstream keyword list.

Reads:
  - ClickHouse/src/Parsers/CommonParsers.h (APPLY_FOR_PARSER_KEYWORDS and
    APPLY_FOR_PARSER_KEYWORDS_WITH_UNDERSCORES macros)
  - ClickHouse/src/Parsers/ASTSystemQuery.h (enum class Type, whose values
    become SYSTEM command keyword sequences by replacing '_' with ' ')

Derives the unique set of primitive keyword words (split on whitespace) and
compares to the token rules declared in ClickHouseLexer.g4.

Usage:
    tools/gen_keywords.py --verify          # exit 1 if divergent
    tools/gen_keywords.py --list            # print all unique keyword words
    tools/gen_keywords.py --lexer-missing   # print words in upstream but not in lexer
    tools/gen_keywords.py --lexer-extra     # print words in lexer but not in upstream
"""
from __future__ import annotations

import argparse
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent
CLICKHOUSE = REPO.parent / "ClickHouse"

COMMON_PARSERS_H = CLICKHOUSE / "src/Parsers/CommonParsers.h"
AST_SYSTEM_H = CLICKHOUSE / "src/Parsers/ASTSystemQuery.h"
LEXER_G4 = REPO / "ClickHouseLexer.g4"


def upstream_words() -> set[str]:
    words: set[str] = set()
    src = COMMON_PARSERS_H.read_text()
    for _ident, val in re.findall(
        r'MR_MACROS\(\s*([A-Za-z_0-9]+)\s*,\s*"([^"]+)"\s*\)', src
    ):
        for tok in val.split():
            words.add(tok.upper())
    sys_src = AST_SYSTEM_H.read_text()
    m = re.search(r"enum\s+class\s+Type\s*:\s*UInt64\s*\{([^}]*)\}", sys_src)
    if m:
        for line in m.group(1).splitlines():
            line = line.split("//")[0].strip().rstrip(",").strip()
            if re.match(r"^[A-Z0-9_]+$", line):
                for w in line.split("_"):
                    words.add(w)
    return words


def lexer_words() -> set[str]:
    """Extract every keyword rule from the lexer.

    Heuristic: a keyword rule is a declaration `NAME : A B C ;` where NAME is
    all-uppercase (or uppercase with a trailing `_KW` suffix), the body uses
    only fragment letters A-Z and underscore-escaped '_' fragments, and no
    non-fragment character classes / literals other than digits (for rules like
    `S3 : S '3'`).
    """
    src = LEXER_G4.read_text()
    words: set[str] = set()
    # Strip comments.
    src_no_comments = re.sub(r"//[^\n]*", "", src)
    for m in re.finditer(
        r"^([A-Z][A-Z0-9_]*)\s*:\s*([^;]+);",
        src_no_comments,
        flags=re.MULTILINE,
    ):
        name, body = m.group(1), m.group(2).strip()
        # Filter out non-keyword rules (operators, literals, fragments).
        if name in {
            "NUMBER", "STRING_LITERAL", "HEX_STRING_LITERAL", "BIN_STRING_LITERAL",
            "HEREDOC", "QUOTED_IDENT", "IDENT",
            "BLOCK_COMMENT", "LINE_COMMENT", "HASH_COMMENT", "WS",
            "LPAREN", "RPAREN", "LBRACKET", "RBRACKET", "LBRACE", "RBRACE",
            "COMMA", "SEMICOLON", "DOT",
            "PLUS", "MINUS", "STAR", "SLASH", "PERCENT",
            "SPACESHIP", "LE", "GE", "NE", "EQ", "LT", "GT",
            "ARROW", "DOUBLE_COLON", "CONCAT", "PIPE", "DOUBLE_AT", "AT",
            "CARET", "QUESTION", "COLON", "DOLLAR", "VERTICAL_DELIM",
        }:
            continue
        # Body must be a sequence of single letters / digit-chars / underscore
        # fragments, separated by whitespace.
        if not re.fullmatch(r"(?:[A-Z]|'[0-9]'|'_')(?:\s+(?:[A-Z]|'[0-9]'|'_'))*", body):
            continue
        word = ""
        for tok in body.split():
            if tok.startswith("'") and tok.endswith("'"):
                word += tok[1:-1]
            else:
                word += tok
        # Strip trailing _KW marker used to dodge target-language keyword clashes.
        mapped = name[:-3] if name.endswith("_KW") else name
        # Sanity: the derived `word` should equal the upstream spelling. Use it.
        words.add(word.upper())
        _ = mapped
    return words


def main() -> int:
    ap = argparse.ArgumentParser()
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--verify", action="store_true")
    g.add_argument("--list", action="store_true")
    g.add_argument("--lexer-missing", action="store_true")
    g.add_argument("--lexer-extra", action="store_true")
    args = ap.parse_args()

    upstream = upstream_words()
    lexer = lexer_words()

    if args.list:
        for w in sorted(upstream):
            print(w)
        return 0
    if args.lexer_missing:
        for w in sorted(upstream - lexer):
            print(w)
        return 0
    if args.lexer_extra:
        for w in sorted(lexer - upstream):
            print(w)
        return 0
    if args.verify:
        missing = upstream - lexer
        # Extras are allowed: some identifiers like EXTRACT, NATIONAL, BINARY
        # are matched in parsers via context-sensitive keyword checks outside
        # the central MR_MACROS enum (e.g. ParserDataType.cpp's text compare).
        # We only fail on missing keywords — those cause real parse failures.
        extra = lexer - upstream
        if missing:
            print(f"MISSING from lexer ({len(missing)}):", file=sys.stderr)
            for w in sorted(missing):
                print(f"  {w}", file=sys.stderr)
        if extra:
            print(f"INFO: lexer has {len(extra)} keyword(s) not in MR_MACROS "
                  "(used via context-sensitive parser paths): "
                  + ", ".join(sorted(extra)), file=sys.stderr)
        return 0 if not missing else 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
