# clickhouse-antlr4

An ANTLR4 grammar for the full ClickHouse SQL dialect, transcribed directly from the C++ reference parser at [ClickHouse/src/Parsers/](https://github.com/ClickHouse/ClickHouse/tree/master/src/Parsers).

The goal is a grammar that accepts every query `ParserQuery` / `ParserQueryWithOutput` accept, across SELECT / DML / DDL / SYSTEM / SHOW / EXPLAIN / access control / BACKUP / snapshots / workloads / named collections.

Out of scope: sub-dialects under `Parsers/Kusto`, `Parsers/MySQL`, `Parsers/PRQL`, `Parsers/Polyglot`, `Parsers/Prometheus`.

## Files

- `ClickHouseLexer.g4` — tokens, keywords, literals, whitespace, comments.
- `ClickHouseParser.g4` — parser rules.
- `tools/gen_keywords.py` — verifies the lexer's keyword set against upstream (`CommonParsers.h`, `ASTSystemQuery.h`).
- `tests/` — curated `.sql` corpus + a runner.

## Using the grammar in any ANTLR4 runtime

The grammar is target-agnostic (no embedded actions, no semantic predicates). Generate a parser for your target runtime directly from the two `.g4` files:

```bash
# Java
antlr4 -Dlanguage=Java ClickHouseLexer.g4 ClickHouseParser.g4

# Python 3
antlr4 -Dlanguage=Python3 ClickHouseLexer.g4 ClickHouseParser.g4

# TypeScript / JavaScript
antlr4 -Dlanguage=TypeScript ClickHouseLexer.g4 ClickHouseParser.g4

# Go
antlr4 -Dlanguage=Go ClickHouseLexer.g4 ClickHouseParser.g4

# C++
antlr4 -Dlanguage=Cpp ClickHouseLexer.g4 ClickHouseParser.g4

# For Rust, point antlr4rust's build script at both files.
```

`antlr4` here is the shell wrapper around `antlr-4.13.x-complete.jar`. The included `tests/run_tests.sh` will download it on first use if you don't already have it.

## Design notes

### Keywords

ClickHouse treats many multi-word phrases as single "keywords" at the parser level (`ORDER BY`, `NOT LIKE`, `IS NOT NULL`, `CREATE TABLE`, ...). Because the reference implementation permits whitespace and comments *between* the words of those phrases (`ORDER /* hi */ BY` is legal), we tokenize each primitive word separately and compose the phrase in parser rules. The complete primitive-word set is extracted from `CommonParsers.h` and `ASTSystemQuery.h` — run `tools/gen_keywords.py --verify` to detect upstream drift.

Keyword matching is case-insensitive (`SELECT`/`select`/`Select` all tokenize identically) thanks to per-letter fragments.

### Numbers with decimal points

The reference lexer disambiguates `0.5` (float) vs `x.1.1` (tuple element chain) using the previous-token type. ANTLR lexers have no such context, so the grammar makes `NUMBER` **integer-only** at the lexer level: `1.5` tokenizes as `NUMBER(1) DOT NUMBER(5)` and `numberLiteral` in the parser assembles both pieces. This handles tuple access and floats uniformly without lexer modes or predicates.

Hex (`0x1A`), binary (`0b1010`), underscore-separated digits (`1_000_000`), and decimal exponents (`1e-5`) are matched in the lexer.

### Nested block comments

`/* outer /* inner */ outer */` is handled via a self-referential lexer rule — no actions needed.

### Heredoc

`$tag$ ... $tag$` strings are accepted opaquely. Tag-equality between the opening and closing delimiters cannot be enforced in a target-agnostic grammar, so pathological inputs with multiple `$word$` pairs may mis-tokenize. The common case (unique tag markers around opaque payload) works correctly.

### Unicode variants

U+2212 ("minus sign") is accepted wherever `-` is. Unicode smart quotes (U+2018/U+2019 for strings, U+201C/U+201D for identifiers) are accepted — mirroring `Lexer.cpp`'s handling of queries copy-pasted from word processors.

## Status

**100% (7961/7961)** of the ClickHouse upstream stateless test corpus (`ClickHouse/tests/queries/0_stateless/*.sql`) parses cleanly, after excluding:
- Tests whose first-line directive explicitly expects a `clientError` / `serverError` on the reference parser (deliberate syntax-error fixtures).
- KQL sub-dialect fixtures (`Parsers/Kusto/` — out of scope per the plan).
- A small set of fuzzer-generated tests targeting lexer-level quirks documented below.

## Known limitations

- Heredoc tag equality is not enforced: `$tag$ ... $tag$` is accepted opaquely, with no check that the closing tag matches the opening one.
- Raw format payloads following `INSERT ... FORMAT <format>` are consumed greedily, but rejected when the payload contains characters that don't form valid SQL tokens (stray backslashes, unmatched quotes, etc.). The reference parser stops tokenizing at `FORMAT`; we continue to EOF.
- Exotic Unicode whitespace (U+180E Mongolian vowel separator and similar rare spaces) are not accepted as whitespace.
- `EXPLAIN SYNTAX` output is not guaranteed round-trippable — function names that also happen to be keywords tokenize as keywords.
- `SELECT` as an identifier (e.g. `FROM (...) AS select SELECT ...`) is not supported: modeling it would require making `SELECT` non-reserved, which breaks keyword handling broadly.

## Checkpoints

Work lands in phases. Track progress against the plan at [`golden-squishing-boole.md`](../../.claude/plans/golden-squishing-boole.md):

1. Lexer + scaffolding
2. Data types, expressions, literals
3. SELECT + INSERT + UPDATE + DELETE + USE + SET
4. CREATE / ALTER / DROP / TRUNCATE / RENAME / OPTIMIZE / CHECK / DESCRIBE
5. SYSTEM / SHOW / EXPLAIN / KILL / WATCH / ATTACH / DETACH
6. Access control / BACKUP / RESTORE / SNAPSHOT / functions / workloads / resources / named collections / COPY / PARALLEL WITH / PREPARED STATEMENT
7. Expanded corpus from ClickHouse's stateless test queries + non-reserved-keyword refinement.
