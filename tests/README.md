# Test corpus

`corpus/` holds small `.sql` files, one statement per file, organized by statement family. Every file must parse cleanly against `ClickHouseParser` with the `query` start rule.

## Layout

```
corpus/
├── lexer/       Token-level spot checks (all literal shapes, operators, comments)
├── types/       Data type declarations
├── expr/        Expressions and operator precedence
├── select/      SELECT + UNION/INTERSECT/EXCEPT
├── insert/      INSERT
├── mutation/    UPDATE, DELETE
├── ddl/         CREATE / DROP / TRUNCATE / RENAME / OPTIMIZE / CHECK / DESCRIBE
├── alter/       ALTER
├── system/      SYSTEM
├── show/        SHOW
├── explain/     EXPLAIN
├── access/      Access control (CREATE USER/ROLE/POLICY/..., GRANT, REVOKE, SET ROLE)
├── backup/      BACKUP / RESTORE / SNAPSHOT
└── misc/        CREATE FUNCTION/RESOURCE/WORKLOAD, COPY, PARALLEL WITH, KILL, WATCH, transactions
```

## Running

```
tests/run_tests.sh           # run every file
tests/run_tests.sh -v        # with per-file status
tests/run_tests.sh --corpus tests/corpus/select   # narrow scope
```

The runner auto-downloads ANTLR 4.13.2 to `~/.cache/antlr4/` on first use and rebuilds the generated parser when grammars change.
