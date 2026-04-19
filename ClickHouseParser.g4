// ClickHouseParser.g4
//
// Parser rules for the ClickHouse SQL grammar. See ClickHouseLexer.g4 for
// the token layer and ../README.md for design background.
//
// Checkpoint 2 scope: identifiers, literals, full data-type lattice, and the
// complete expression ladder (operator precedence + primary expressions).
// Statement rules are placeholder until checkpoints 3–6.
parser grammar ClickHouseParser;

options { tokenVocab = ClickHouseLexer; }

// =============================================================================
// Top-level
// =============================================================================

query           : SEMICOLON* (statement (SEMICOLON+ statement)*)? SEMICOLON* EOF ;

statement
    : selectUnion                       # stmtSelect
    | insertStatement                   # stmtInsert
    | updateStatement                   # stmtUpdate
    | deleteStatement                   # stmtDelete
    | useStatement                      # stmtUse
    | setStatement                      # stmtSet
    | transactionStatement              # stmtTxn
    | createStatement                   # stmtCreate
    | alterStatement                    # stmtAlter
    | dropStatement                     # stmtDrop
    | undropStatement                   # stmtUndrop
    | renameStatement                   # stmtRename
    | truncateStatement                 # stmtTruncate
    | optimizeStatement                 # stmtOptimize
    | checkStatement                    # stmtCheck
    | describeStatement                 # stmtDescribe
    | existsStatement                   # stmtExists
    | systemStatement                   # stmtSystem
    | showStatement                     # stmtShow
    | explainStatement                  # stmtExplain
    | killStatement                     # stmtKill
    | watchStatement                    # stmtWatch
    | attachStatement                   # stmtAttach
    | detachStatement                   # stmtDetach
    | grantStatement                    # stmtGrant
    | revokeStatement                   # stmtRevoke
    | checkGrantStatement               # stmtCheckGrant
    | setRoleStatement                  # stmtSetRole
    | createFunctionStatement           # stmtCreateFunction
    | dropFunctionStatement             # stmtDropFunction
    | createNamedCollectionStatement    # stmtCreateNamedCollection
    | alterNamedCollectionStatement     # stmtAlterNamedCollection
    | dropNamedCollectionStatement      # stmtDropNamedCollection
    | createResourceStatement           # stmtCreateResource
    | dropResourceStatement             # stmtDropResource
    | createWorkloadStatement           # stmtCreateWorkload
    | dropWorkloadStatement             # stmtDropWorkload
    | createAccessStatement             # stmtCreateAccess
    | alterAccessStatement              # stmtAlterAccess
    | dropAccessStatement               # stmtDropAccess
    | backupStatement                   # stmtBackup
    | restoreStatement                  # stmtRestore
    | snapshotStatement                 # stmtSnapshot
    | copyStatement                     # stmtCopy
    | parallelWithStatement             # stmtParallelWith
    | preparedStatement                 # stmtPrepared
    | deallocateStatement               # stmtDeallocate
    | expr                              # stmtExpr   // bare expression (e.g. `1 + 2`)
    ;

// =============================================================================
// Identifiers and qualified names
// =============================================================================

identifier
    : IDENT
    | QUOTED_IDENT
    | nonReservedKeyword
    ;

// Keywords that ClickHouse accepts in identifier position. This set is the
// practical floor — grown empirically from the test corpus.
nonReservedKeyword
    : ABI | ACCESS | ACTION | ADD | ADMIN | AFTER | ALGORITHM | ALIAS
    | ALL | ALLOCATE | AND | ANTI | ANY | APPEND | APPLY | ARGUMENTS | ARRAY
    | AS | ASC | ASCENDING | ASOF | ASSUME | AST | ASYNC | ASYNCHRONOUS
    | ATTACH | AUTHENTICATION | AZURE
    | BACKUP | BAGEXPANSION | BCRYPT_HASH | BCRYPT_PASSWORD | BEGIN
    | BIDIRECTIONAL | BINARY | BLOBS | BLOCKING | BOTH
    | CACHE | CACHES | CANCEL | CASCADE | CAST | CHANGE | CHANGED | CHAR | CHARACTER
    | CLEANUP | CLEAR | CLIENT | CLONE | CLUSTER | CLUSTERS | CN | CODEC
    | COLLATE | COLLECTION | COLUMN | COLUMNS | COMMENT | COMMIT | COMPILED
    | COMPRESSION | CONDITION | CONFIG | CONNECTIONS | CONST | CONSTRAINT
    | COPY | COVERAGE | CURRENT | CURRENTUSER | CURRENT_USER
    | D_KW | DATA | DATABASE | DATABASES | DATE | DAY | DAYS | DD | DDL | DIV | MOD
    | DOUBLE_SHA1_HASH | DOUBLE_SHA1_PASSWORD
    | DEALLOCATE | DEDUPLICATE | DEFAULT | DEFINER | DELAY | DELETED | DELTA
    | DEPENDS | DESC | DESCENDING | DETACHED | DICTIONARIES | DICTIONARY
    | DISABLE | DISK | DISTINCT | DISTRIBUTED | DNS | DOW | DOY | DRY
    | EMBEDDED | EMPTY | ENABLE | ENABLED | END | ENFORCED | ENGINE | ENGINES
    | EPHEMERAL | EPOCH | ESTIMATE | EVENT | EVENTS | EVERY | EXCHANGE
    | EXECUTE | EXISTS | EXPLAIN | EXPRESSION | EXTENDED | EXTERNAL | EXTRACT
    | FAKE | FAILPOINT | FETCH | FETCHES | FIELDS | FILE | FILES | FILESYSTEM
    | FORMAT | FROM | FULL
    | FILL | FILTER | FINAL | FIRST | FLUSH | FOLLOWING | FOR | FORCE | FOREIGN
    | FORGET | FORMAT | FREE | FREEZE | FULL | FULLTEXT | FUNCTION | FUNCTIONS
    | FUZZER
    | GRANTEES | GRANTS | GRANULARITY | GROUPS
    | H_KW | HASH | HDFS | HEADER | HH | HIERARCHICAL | HOST | HOUR | HOURS
    | HTTP
    | GROUP | GROUPING
    | CHECK | COMMIT
    | ICEBERG | ID | IDENTIFIED | IF | IGNORE | ILIKE | IMPLICIT | IN | INDEX
    | INDEXES | INSERT | INTERVAL
    | INDICES | INFILE | INHERIT | INJECTIVE | INNER | INSTRUMENT | INTO
    | INVISIBLE | INVOKER | IP | ISODOW | ISOYEAR
    | JEMALLOC | JOIN | JWT
    | KERBEROS | KERNEL | KEY | KEYED | KEYS | KILL | KIND
    | LANGUAGE | LARGE | LAST | LAYOUT | LDAP | LEADING | LEFT | LESS | LEVEL
    | LIFETIME | LIGHTWEIGHT | LIKE | LIMIT | LIMITS | LINEAR | LIST | LISTEN | LIVE | LOAD
    | LOADING | LOCAL | LOG | LOGS
    | M_KW | MARK | MASK | MASKING | MASTER | MATCH | MATERIALIZE | MATERIALIZED
    | MAX | MCS | MEMORY | MERGES | METADATA | METHODS | METRICS | MI
    | MICROSECOND | MICROSECONDS | MILLENNIUM | MILLISECOND | MILLISECONDS
    | MIN | MINUTE | MINUTES | MM | MMAP | MODEL | MODELS | MODIFY | MONTH
    | MONTHS | MOVE | MOVES | MS | MUTATION
    | N_KW | NAME | NAMED | NANOSECOND | NANOSECONDS | NATIONAL | NATURAL | NEW
    | NEXT | NULL_KW
    | NO | NONE | NOTIFY | NS | NULLS
    | OBJECT | OFFSET | ONLY | OPTIMIZE | OPTION | OR | ORDER | OUTER | OUTFILE
    | OVERRIDABLE | OVERRIDE
    | PAGE | PARALLEL | PARQUET | PART | PARTIAL | PARTITION | PARTITIONS | PARTS | PASTE | PATCHES
    | PLAINTEXT_PASSWORD
    | PATH | PAUSE | PERIODIC | PERMANENTLY | PERMISSIVE | PERSISTENT
    | PIPELINE | PLACING | PLAN | POLICY | POPULATE | POSTINGS | PRECEDING
    | PREWHERE
    | PRECISION | PREFIX | PREPARE | PREWARM | PRIMARY | PRIORITY | PRIVILEGES
    | PROCESSLIST | PROFILE | PROFILES | PROJECTION | PROTOBUF | PULL | PULLING
    | PURGE
    | Q_KW | QQ | QUARTER | QUARTERS | QUERIES | QUERY | QUEUE | QUEUES | QUOTA
    | RANDOMIZE | RANDOMIZED | RANGE | READ | READONLY | READY | REALM | REGEXP
    | RIGHT
    | ROLLUP | CUBE | RECURSIVE
    | RECOMPRESS | RECONNECT | REDUCE | REFERENCES | REFRESH | RELOAD | REMOVE
    | RENAME | REPLACE | REPLICA | REPLICAS | REPLICATED | REPLICATION | RESET
    | RESOURCE | RESPECT | RESTART | RESTORE | RESTRICT | RESTRICTIVE | RESUME
    | RETURNS | REVOKE | REWRITE | ROLE | ROLES | ROLLBACK | ROW | ROWS | RUN
    | S_KW | S3 | SALT | SAMPLE | SAN | SCHEMA | SCHEME | SEMI | SET
    | SQL_TSI_NANOSECOND | SQL_TSI_MICROSECOND | SQL_TSI_MILLISECOND
    | SQL_TSI_SECOND | SQL_TSI_MINUTE | SQL_TSI_HOUR
    | SQL_TSI_DAY | SQL_TSI_WEEK | SQL_TSI_MONTH | SQL_TSI_QUARTER | SQL_TSI_YEAR
    | SCRAM_SHA256_HASH | SCRAM_SHA256_PASSWORD | SECOND | SECONDS
    | SECURITY | SENDS | SEQUENTIAL | SERVER | SETS | SETTING | SETTINGS
    | SHA256_HASH | SHA256_PASSWORD
    | SHARD | SHOW | SHUTDOWN | SIGNED | SIMILARITY | SIMPLE | SKIP_KW
    | SNAPSHOT | SOURCE | SPATIAL | SQL | SS | STALENESS | START | STATISTICS
    | STDOUT | STEP | STOP | STORAGE | STRICT | SUBPARTITION | SUBPARTITIONS
    | SUSPEND | SYNC | SYNTAX | SYSTEM
    | TABLE | TABLES | TAG | TAGS | TEMPORARY | TEST | TEXT | THAN | THREAD
    | TIES | TIME | TIMESTAMP | TO | TOKENS | TOP | TOTALS | TRACING | TRACKING
    | TRAILING | TRANSACTION | TREE | TRIGGER | TRUNCATE | TTL | TYPE | TYPEOF
    | UNBOUNDED | UNCOMPRESSED | UNDROP | UNFREEZE | UNION | UNIQUE | UNKNOWN | UNLOAD
    | UNLOCK | UNREADY | UNSET | UNSIGNED | UNTIL | UPDATE | URL | USER | USERS
    | UUID
    | VALID | VALUES | VARYING | VECTOR | VIEW | VIEWS | VIRTUAL | VISIBLE
    | VOLUME
    | WAIT | WATCH | WATERMARK | WEEK | WEEKS | WINDOW | WK | WORKER | WORKLOAD
    | WRITABLE | WRITE | WW
    | YEAR | YEARS | YY | YYYY
    | ZKPATH | ZONE | ZOOKEEPER
    ;

// Compound identifier: dotted chain, each part is a simple identifier or a
// quoted identifier. Used for column references (a.b.c), database.table, etc.
compoundIdentifier
    : identifier (DOT identifier)*
    ;

// Qualified asterisk: table.* or db.table.* with optional COLUMNS-style
// transformers (EXCEPT, APPLY, REPLACE, RENAME).
qualifiedAsteriskExpr
    : identifier DOT (identifier DOT)? STAR columnsTransformer*
    ;

// Bare asterisk with optional transformers: `SELECT * EXCEPT (a) APPLY f`.
asteriskExpr
    : STAR columnsTransformer*
    ;

// Database-qualified name. Each side may also be a `{name:Identifier}` query
// parameter (ClickHouse test fixtures commonly parameterize DB names).
databaseAndTableName
    : nameOrParam (DOT nameOrParam)?
    ;

nameOrParam
    : identifier
    | queryParameter
    ;

// Function names can be bare identifiers only; ClickHouse does not use
// db-qualified function calls.
functionName
    : identifier
    ;

// =============================================================================
// Literals
// =============================================================================

literal
    : NULL_KW                       # literalNull
    | TRUE                          # literalTrue
    | FALSE                         # literalFalse
    | numberLiteral                 # literalNumber
    | STRING_LITERAL                # literalString
    | HEX_STRING_LITERAL            # literalHexString
    | BIN_STRING_LITERAL            # literalBinString
    | HEREDOC                       # literalHeredoc
    ;

// Number literal rule handles both integers and floats (NUMBER DOT NUMBER) —
// see the rationale in ClickHouseLexer.g4's header.
// NUMBER | NUMBER DOT | NUMBER DOT NUMBER — the trailing-dot form (`3.`) is
// a valid ClickHouse float.
// Float forms accepted: `1`, `1.`, `1.5`, and `.5` (the leading-dot form is
// unambiguous here because it is only tried as a primary expression, not as
// the continuation of an identifier chain).
numberLiteral
    : NUMBER (DOT NUMBER?)?
    | DOT NUMBER
    ;

// Signed numeric literal for contexts that want a single token-ish unit
// (enum element values, range boundaries, etc.).
signedNumberLiteral
    : (PLUS | MINUS)? numberLiteral
    ;

// =============================================================================
// Interval units (date parts). Used in INTERVAL, EXTRACT, Interval type, etc.
// =============================================================================

intervalUnit
    : NANOSECOND  | MICROSECOND  | MILLISECOND  | SECOND  | MINUTE  | HOUR
    | DAY         | WEEK         | MONTH        | QUARTER | YEAR
    | NANOSECONDS | MICROSECONDS | MILLISECONDS | SECONDS | MINUTES | HOURS
    | DAYS        | WEEKS        | MONTHS       | QUARTERS| YEARS
    | DECADE      | CENTURY      | MILLENNIUM
    | EPOCH       | DOW          | DOY          | ISODOW  | ISOYEAR
    | NS          | MCS          | MS           | SS      | MI       | HH
    | D_KW        | H_KW         | M_KW         | N_KW    | Q_KW     | S_KW
    | WK          | MM           | QQ           | YY      | YYYY     | DD
    | SQL_TSI_NANOSECOND | SQL_TSI_MICROSECOND | SQL_TSI_MILLISECOND
    | SQL_TSI_SECOND | SQL_TSI_MINUTE | SQL_TSI_HOUR
    | SQL_TSI_DAY    | SQL_TSI_WEEK   | SQL_TSI_MONTH
    | SQL_TSI_QUARTER | SQL_TSI_YEAR
    ;

// =============================================================================
// Data types (ParserDataType.cpp)
// =============================================================================

dataType
    : nationalType                                                  # dtNational
    | sizedCharType                                                 # dtSizedChar
    | doublePrecisionType                                           # dtDouble
    | intervalType                                                  # dtInterval
    | typeName LPAREN NUMBER? RPAREN (SIGNED | UNSIGNED)?           # dtIntMySQL
    | typeName (SIGNED | UNSIGNED)                                  # dtIntSignedUnsigned
    | typeName LPAREN dataTypeArgList? RPAREN                       # dtParametric
    | typeName                                                      # dtSimple
    ;

// Bare type name; since ARRAY/DATE/TIMESTAMP/UUID/TIME are in the
// nonReservedKeyword set, `identifier` already covers them here.
typeName
    : identifier
    ;

// SQL-standard compatibility shapes handled specially in ParserDataType.cpp.
nationalType
    : NATIONAL (CHARACTER | CHAR) (LARGE OBJECT | VARYING)? (LPAREN NUMBER RPAREN)?
    ;

sizedCharType
    : (BINARY | CHARACTER | CHAR | identifier) (LARGE OBJECT | VARYING) (LPAREN NUMBER RPAREN)?
    | (BINARY | CHARACTER | CHAR) (LPAREN NUMBER RPAREN)?
    ;

doublePrecisionType
    : typeName PRECISION (LPAREN NUMBER (COMMA NUMBER)? RPAREN)?
    ;  // matches DOUBLE PRECISION etc.; the name stays permissive to mirror
       // ParserDataType.cpp's text-based DOUBLE check.

intervalType
    : INTERVAL intervalUnit
    ;

dataTypeArgList
    : dataTypeArg (COMMA dataTypeArg)* COMMA?
    ;

// Data-type argument alternatives are loosely specified to cover the union of
// shapes ParserDataType.cpp accepts across type families (Enum, Tuple, Nested,
// JSON, Dynamic, AggregateFunction, Decimal, FixedString, DateTime64, ...).
// Order matters: more specific alternatives first.
dataTypeArg
    : SKIP_KW REGEXP STRING_LITERAL                   # dtaSkipRegexp
    | SKIP_KW compoundIdentifier                      # dtaSkipPath
    | enumElement                                     # dtaEnum
    | identifier EQ (signedNumberLiteral | STRING_LITERAL)  # dtaNamedParam
    | compoundIdentifier dataType                     # dtaPathWithType
    | identifier dataType                             # dtaNameAndType
    | functionCall                                    # dtaFuncCall
    | dataType                                        # dtaNestedType
    | signedNumberLiteral                             # dtaNumber
    | STRING_LITERAL                                  # dtaString
    | compoundIdentifier                              # dtaIdent
    ;

enumElement
    : STRING_LITERAL EQ (PLUS | MINUS)? NUMBER
    ;

// =============================================================================
// Expressions — the operator precedence ladder
// (ExpressionListParsers.cpp:2972–3022)
// =============================================================================

expr
    : primaryExpr                                                                   # eePrimary
    | expr LBRACKET expr? RBRACKET                                                  # eeArrayElement     // (14) — `[]` allowed for JSON-style unwrap
    | expr DOT (NUMBER | identifier | STAR | CARET identifier | AT identifier | COLON dataType)  # eeTupleElement   // (14) JSON subcolumn forms included
    | expr DOUBLE_COLON dataType                                                    # eeCastOp           // (14)
    | (PLUS | MINUS) expr                                                           # eeUnaryMinus       // (13) — unary +/-
    | expr (STAR | SLASH | PERCENT | MOD | DIV) expr                                # eeMul              // (12)
    | expr (PLUS | MINUS) expr                                                      # eeAdd              // (11)
    | expr CONCAT expr                                                              # eeConcat           // (10)
    | expr IS NOT? NULL_KW                                                          # eeIsNull           // (6)
    | expr IS NOT? DISTINCT FROM expr                                               # eeDistinctFrom     // (6)
    | expr GLOBAL? NOT? IN expr                                                     # eeIn               // (9)
    | expr NOT? (LIKE | ILIKE | REGEXP | MATCH) expr                                # eeLike             // (9)
    | expr (EQ | NE | LE | GE | LT | GT | SPACESHIP) (ANY | ALL | SOME)? expr       # eeCompare          // (9)
    | expr NOT? BETWEEN expr AND expr                                               # eeBetween          // (7)
    | NOT expr                                                                      # eeNot              // (5)
    | expr AND expr                                                                 # eeAnd              // (4)
    | expr OR expr                                                                  # eeOr               // (3)
    | expr QUESTION expr COLON expr                                                 # eeTernary          // (2–3)
    | <assoc=right> expr ARROW expr                                                 # eeLambda           // (1)
    ;

// Primary (atom) expressions — literals, identifiers, function calls, etc.
primaryExpr
    : literal                                                   # peLiteral
    | caseExpr                                                  # peCase
    | castFunction                                              # peCast
    | extractFunction                                           # peExtract
    | intervalExpr                                              # peInterval
    | substringFunction                                         # peSubstring
    | trimFunction                                              # peTrim
    | positionFunction                                          # pePosition
    | columnsMatcher                                            # peColumnsMatcher
    | qualifiedAsteriskExpr                                     # peQualifiedAsterisk
    | asteriskExpr                                              # peAsterisk
    | functionCall                                              # peFunctionCall
    | queryParameter                                            # peQueryParam
    | LPAREN selectSubquery RPAREN                              # peSubquery
    | LPAREN arrayElementExpr COMMA (arrayElementExpr (COMMA arrayElementExpr)*)? COMMA? RPAREN  # peTuple   // includes 1-element (x,)
    | LPAREN expr AS identifier RPAREN                          # peParenAliased
    | LPAREN expr RPAREN                                        # peParen
    | LPAREN RPAREN                                             # peEmptyTuple
    | DOUBLE_AT identifier (DOT identifier)*                    # peMysqlGlobal   // @@session.foo
    | AT identifier                                             # peMysqlSession  // @user-variable
    | LBRACKET (arrayElementExpr (COMMA arrayElementExpr)* COMMA?)? RBRACKET # peArray
    | (DATE | TIME | TIMESTAMP) STRING_LITERAL                  # peTypedLiteral // SQL-standard typed date/time literal
    | LBRACE (mapElement (COMMA mapElement)* COMMA?)? RBRACE    # peMap
    | compoundIdentifier                                        # peIdentifier
    ;

// Subquery shape allowed in primary expressions. Accepts either a SELECT
// (possibly with UNION/INTERSECT/EXCEPT) or a bare expression list for
// cases like `(1, 2, 3)` which `peTuple` also matches — the parser prefers
// `selectUnion` when it starts with WITH/SELECT tokens.
selectSubquery
    : selectUnion
    | explainStatement                         // (EXPLAIN PLAN ... SELECT ...) is a valid subquery shape
    ;

mapElement
    : expr COLON expr
    ;

// Array element with optional inline alias (`[x AS a, y AS b]`). ClickHouse
// assigns the alias as the tuple-field name when the array is later treated
// as a named tuple.
arrayElementExpr
    : expr (AS identifier)?
    ;

// {name:Type} query parameter substitution.
queryParameter
    : LBRACE identifier COLON dataType RBRACE
    ;

// ---- CASE --------------------------------------------------------------------

caseExpr
    : CASE expr? caseWhen+ caseElse? END
    ;
// Inline AS-aliases after THEN/ELSE are legal in ClickHouse and reachable
// from outer expressions.
caseWhen : WHEN expr THEN expr (AS identifier)? ;
caseElse : ELSE expr (AS identifier)? ;

// ---- CAST --------------------------------------------------------------------

castFunction
    : CAST LPAREN expr (AS? identifier)? AS dataType RPAREN                       // CAST(x AS Type) and CAST(x alias AS Type)
    | CAST LPAREN expr (AS? identifier)? COMMA expr (AS? identifier)? RPAREN      // CAST(x, 'Type') and with optional aliases
    ;

// ---- EXTRACT -----------------------------------------------------------------

extractFunction
    : EXTRACT LPAREN intervalUnit FROM expr RPAREN
    ;

// ---- INTERVAL expression -----------------------------------------------------

intervalExpr
    : INTERVAL STRING_LITERAL (AS identifier)? (intervalUnit (TO intervalUnit)?)?
    | INTERVAL expr intervalUnit
    ;

// ---- SQL-standard string functions -------------------------------------------
// These forms use keyword-separated argument lists instead of comma-separated.

substringFunction
    : identifier LPAREN expr (AS? identifier)? FROM expr (AS? identifier)? (FOR expr (AS? identifier)?)? RPAREN
    ;

trimFunction
    : identifier LPAREN (LEADING | TRAILING | BOTH)? (expr (AS? identifier)?)? FROM expr (AS? identifier)? RPAREN
    ;

positionFunction
    : identifier LPAREN expr IN expr RPAREN
    ;

// ---- Function calls, window, filter, nulls -----------------------------------

// Split into parametric (two paren pairs, e.g. `quantile(0.5)(x)`) and
// regular (one pair). Keeping the parametric form as a separate alternative
// avoids ANTLR's greedy prediction committing to the optional first parens
// when only a single-pair call is actually present.
functionCall
    : functionName LPAREN functionArgList? RPAREN LPAREN (DISTINCT | ALL)? functionArgList? RPAREN
        filterClause? nullsAction? overClause?                              # parametricFunctionCall
    | functionName LPAREN (DISTINCT | ALL)? functionArgList? RPAREN
        filterClause? nullsAction? overClause?                              # regularFunctionCall
    ;

functionArgList
    : functionArg (COMMA functionArg)* COMMA?
    ;

// Named arguments (a=>b), SETTINGS k=v pairs (accepted by many table/aggregate
// functions), nested SELECTs (e.g. `view(SELECT ...)`), and plain expressions —
// with an optional inline alias.
functionArg
    : identifier ARROW expr
    | SETTINGS settingAssignment (COMMA settingAssignment)*
    | selectUnion
    | expr (AS? identifier)?
    ;

filterClause
    : FILTER LPAREN WHERE expr RPAREN
    ;

nullsAction
    : (RESPECT | IGNORE) NULLS
    ;

overClause
    : OVER (identifier | windowDefinition)
    ;

windowDefinition
    : LPAREN windowDefinitionElements? RPAREN
    ;

windowDefinitionElements
    : identifier? (PARTITION BY expr (COMMA expr)*)? (ORDER BY orderByElement (COMMA orderByElement)*)? windowFrame?
    ;

windowFrame
    : frameType BETWEEN frameBound AND frameBound
    | frameType frameBound
    ;

frameType
    : ROWS | RANGE | GROUPS
    ;

frameBound
    : UNBOUNDED PRECEDING
    | UNBOUNDED FOLLOWING
    | CURRENT ROW
    | expr PRECEDING
    | expr FOLLOWING
    ;

orderByElement
    : expr (AS identifier)?
           (ASC | DESC | ASCENDING | DESCENDING)?
           (NULLS (FIRST | LAST))?
           (COLLATE STRING_LITERAL)?
           withFillSpec?
    ;

withFillSpec
    : WITH FILL (FROM expr)? (TO expr)? (STEP expr)? (STALENESS expr)?
    ;

// ---- COLUMNS matcher + transformers ------------------------------------------

columnsMatcher
    : (databaseAndTableName DOT)? COLUMNS LPAREN columnsMatcherBody RPAREN columnsTransformer*
    ;

columnsMatcherBody
    : STRING_LITERAL
    | identifier (COMMA identifier)*
    ;

columnsTransformer
    : APPLY LPAREN (functionName (LPAREN functionArgList? RPAREN)? | expr) RPAREN (AS identifier)?
    | APPLY functionName (LPAREN functionArgList? RPAREN)? (AS identifier)?  // no outer parens
    | EXCEPT LPAREN identifier (COMMA identifier)* RPAREN
    | EXCEPT LPAREN STRING_LITERAL RPAREN
    | EXCEPT STRING_LITERAL                            // single regex literal, no parens
    | EXCEPT identifier                                // single column, no parens
    | REPLACE STRICT? LPAREN columnsReplaceItem (COMMA columnsReplaceItem)* RPAREN
    | REPLACE STRICT? columnsReplaceItem               // single item, no parens
    | RENAME LPAREN columnsRenameItem (COMMA columnsRenameItem)* RPAREN
    ;

columnsReplaceItem
    : expr AS identifier
    ;

columnsRenameItem
    : identifier AS identifier
    ;

// =============================================================================
// SELECT (ParserSelectQuery.cpp, ParserSelectWithUnionQuery.cpp)
// =============================================================================

selectUnion
    : selectElement (selectUnionOp selectElement)* (settingsClause | outfileClause | formatClause)*
    ;

selectUnionOp
    : UNION (DISTINCT | ALL)?
    | INTERSECT (DISTINCT | ALL)?
    | EXCEPT (DISTINCT | ALL)?
    ;

selectElement
    : LPAREN selectUnion RPAREN
    | selectQuery
    ;

selectQuery
    : withClause?
      (FROM tableExpression (COMMA tableExpression)*)?
      SELECT
        (ALL | DISTINCT (ON LPAREN expr (COMMA expr)* RPAREN)?)?
        (TOP (LPAREN NUMBER RPAREN | NUMBER) (WITH TIES)?)?
        selectItemList
      (FROM tableExpression (COMMA tableExpression)*)?
      (PREWHERE expr (AS identifier)?)?
      (WHERE expr (AS identifier)?)?
      groupByClause?
      (HAVING expr (AS identifier)?)?
      windowClause?
      (QUALIFY expr)?
      orderByClause?
      limitByClause?
      limitClause?
      offsetFetchClause?
      (settingsClause | outfileClause | formatClause)*
    ;

withClause
    : WITH RECURSIVE? withElement (COMMA withElement)*
    ;

withElement
    : identifier AS MATERIALIZED? LPAREN selectSubquery RPAREN              # weSubquery
    | identifier LPAREN identifier (COMMA identifier)* RPAREN AS LPAREN selectSubquery RPAREN   # weSubqueryAliases
    | expr (AS identifier)?                                                  # weExprAlias
    ;

selectItemList
    : selectItem (COMMA selectItem)* COMMA?
    ;

selectItem
    : expr (AS? identifier)?
    ;

groupByClause
    : GROUP BY (ROLLUP | CUBE) LPAREN expr (COMMA expr)* RPAREN (WITH (ROLLUP | CUBE | TOTALS))*
    | GROUP BY (ROLLUP | CUBE)? groupByElement (COMMA groupByElement)* (WITH (ROLLUP | CUBE | TOTALS))*
    | GROUP BY GROUPING SETS LPAREN groupingSet (COMMA groupingSet)* RPAREN (WITH (ROLLUP | CUBE | TOTALS))*
    | GROUP BY ALL (WITH (ROLLUP | CUBE | TOTALS))*
    | (WITH (ROLLUP | CUBE | TOTALS))+                  // no GROUP BY, just trailing modifiers
    ;

// GROUP BY supports inline aliases for its expressions (`GROUP BY x AS alias`).
groupByElement
    : expr (AS identifier)?
    ;

groupingSet
    : LPAREN (expr (COMMA expr)*)? RPAREN
    | expr
    ;

windowClause
    : WINDOW windowDefinitionItem (COMMA windowDefinitionItem)*
    ;

windowDefinitionItem
    : identifier AS windowDefinition
    ;

orderByClause
    : ORDER BY ALL interpolateClause?
    | ORDER BY orderByElement (COMMA orderByElement)* interpolateClause?
    ;

interpolateClause
    : INTERPOLATE (LPAREN (interpolateElement (COMMA interpolateElement)*)? RPAREN)?
    ;

interpolateElement
    : identifier (AS expr)?
    ;

limitByClause
    : LIMIT expr (COMMA expr | OFFSET expr)? BY limitByElement (COMMA limitByElement)*
    ;

limitByElement
    : expr (AS identifier)?
    ;

limitClause
    : LIMIT expr (COMMA expr | OFFSET expr)? (WITH TIES)?
    ;

offsetFetchClause
    : OFFSET expr (ROW | ROWS)? (FETCH (FIRST | NEXT) expr (ROW | ROWS) (ONLY | WITH TIES))?
    | FETCH (FIRST | NEXT) expr (ROW | ROWS) (ONLY | WITH TIES)
    ;

settingsClause
    : SETTINGS (LPAREN settingAssignment (COMMA settingAssignment)* RPAREN
               | settingAssignment (COMMA settingAssignment)*)
    ;

settingAssignment
    : identifier (EQ expr)?
    ;

formatClause
    : FORMAT identifier
    ;

outfileClause
    : INTO OUTFILE STRING_LITERAL (APPEND | TRUNCATE)?
        (COMPRESSION STRING_LITERAL (LEVEL NUMBER)?)?
    ;

// =============================================================================
// Tables in FROM: name / subquery / table function, with JOINs
// (ParserTablesInSelectQuery.cpp)
// =============================================================================

tableExpression
    : tableExpressionAtom joinElement*
    ;

joinElement
    : arrayJoinClause
    | crossJoinClause
    | pasteJoinClause
    | naturalJoinClause
    | joinKind JOIN tableExpressionAtom joinConstraint? sampleClause?
    | COMMA tableExpressionAtom              // implicit CROSS JOIN via comma
    ;

arrayJoinClause
    : (INNER | LEFT)? ARRAY JOIN arrayJoinItem (COMMA arrayJoinItem)*
    ;

arrayJoinItem
    : expr (AS identifier)?
    ;

crossJoinClause
    : GLOBAL? CROSS JOIN tableExpressionAtom
    ;

pasteJoinClause
    : PASTE JOIN tableExpressionAtom
    ;

naturalJoinClause
    : NATURAL (LEFT OUTER? | RIGHT OUTER? | FULL OUTER? | INNER)? JOIN tableExpressionAtom joinConstraint?
    ;

joinKind
    : GLOBAL? (
          ANY | ALL | ASOF
        | SEMI | ANTI
        | (INNER | LEFT OUTER? | RIGHT OUTER? | FULL OUTER?)
        | (LEFT OUTER? | RIGHT OUTER? | FULL OUTER?) (ANY | ALL | ASOF | SEMI | ANTI)
        | (ANY | ALL | ASOF | SEMI | ANTI) (LEFT OUTER? | RIGHT OUTER? | FULL OUTER? | INNER)
      )?
    ;

joinConstraint
    : ON expr
    | USING LPAREN usingItem (COMMA usingItem)* RPAREN
    | USING usingItem (COMMA usingItem)*
    ;

// USING may alias columns inline: `USING (x AS y)`.
usingItem
    : identifier (AS identifier)?
    ;

tableExpressionAtom
    : tableExpressionPrimary
        (AS? identifier)?
        (LPAREN identifier (COMMA identifier)* RPAREN)?   // column-name alias list
        (FINAL)?
        sampleClause?
    ;

tableExpressionPrimary
    : databaseAndTableName
    | tableFunctionCall
    | LPAREN selectSubquery RPAREN      // (SELECT ...) and (EXPLAIN ... SELECT ...)
    | LPAREN tableExpression RPAREN     // grouped table expression for joins
    | LPAREN VALUES (valuesRow (COMMA valuesRow)* COMMA?)? RPAREN  // (VALUES ...) table constructor
    ;

tableFunctionCall
    : identifier LPAREN functionArgList? RPAREN settingsClause?
    ;

sampleClause
    : SAMPLE sampleRatio (OFFSET sampleRatio)?
    ;

sampleRatio
    : signedNumberLiteral (SLASH signedNumberLiteral)?
    ;

// =============================================================================
// INSERT (ParserInsertQuery.cpp)
// =============================================================================

insertStatement
    : withClause? INSERT INTO (TABLE? FUNCTION | TABLE)? insertTarget insertColumns?
        partitionByClause?
        settingsClause?
        insertBody
    ;

insertTarget
    : databaseAndTableName
    | tableFunctionCall
    ;

insertColumns
    : LPAREN identifier (COMMA identifier)* RPAREN
    ;

partitionByClause
    : PARTITION BY expr
    ;

insertBody
    : VALUES (valuesRow (COMMA? valuesRow)* COMMA?)?   # ibValues
    | selectUnion formatDataTail?                       # ibSelect
    | FORMAT identifier formatDataTail                  # ibFormatOnly
    | FROM INFILE STRING_LITERAL (COMPRESSION STRING_LITERAL)? settingsClause? (FORMAT identifier)?
                                                        # ibFromInfile
    ;

// Anything after `... FORMAT <name>` is raw data for the named format; we
// consume every remaining token so the parser doesn't trip on it.
formatDataTail
    : ( ~EOF )*
    ;

valuesRow
    : LPAREN (expr (COMMA expr)* COMMA?)? RPAREN
    ;

// =============================================================================
// UPDATE / DELETE (ParserUpdateQuery.cpp, ParserDeleteQuery.cpp) — lightweight
// =============================================================================

updateStatement
    : UPDATE databaseAndTableName onCluster?
        SET assignmentList
        (IN PARTITION expr)?
        WHERE expr
        settingsClause?
    ;

assignmentList
    : assignment (COMMA assignment)*
    ;

assignment
    : identifier EQ expr
    ;

deleteStatement
    : DELETE FROM databaseAndTableName onCluster?
        (IN PARTITION expr)?
        WHERE expr
        settingsClause?
    ;

onCluster
    : ON CLUSTER (identifier | STRING_LITERAL)
    ;

// =============================================================================
// USE / SET / Transaction control
// =============================================================================

useStatement
    : USE DATABASE? nameOrParam
    ;

setStatement
    : SET settingAssignment (COMMA settingAssignment)*
    | SET TRANSACTION SNAPSHOT expr
    | SET transactionIsoLevel
    ;

transactionIsoLevel
    : TRANSACTION identifier
    ;

transactionStatement
    : BEGIN TRANSACTION?
    | START TRANSACTION
    | COMMIT
    | ROLLBACK
    ;

// =============================================================================
// CREATE (ParserCreateQuery.cpp, ParserCreateIndexQuery.cpp, ...)
// =============================================================================

createStatement
    : createTable
    | createView
    | createDatabase
    | createDictionary
    | createIndex
    ;

createOrReplace
    : CREATE (OR REPLACE)?
    | REPLACE
    | ATTACH
    ;

ifNotExists : IF NOT EXISTS ;

createTable
    : createOrReplace TEMPORARY? TABLE ifNotExists?
        databaseAndTableName uuidClause? onCluster?
        tableBody?
        (engineClause | asSelect | commentClause | settingsClause | formatClause)*
    ;

uuidClause
    : UUID STRING_LITERAL
    ;

asSelect
    : AS selectUnion
    | AS tableFunctionCall                         // CREATE TABLE t AS remote(...)
    | AS databaseAndTableName                      // CREATE ... AS other_table
    | CLONE AS databaseAndTableName                // REPLACE TABLE t CLONE AS src
    | EMPTY AS selectUnion
    | POPULATE AS? selectUnion
    ;

tableBody
    : LPAREN tableElement (COMMA tableElement)* COMMA? RPAREN
    ;

tableElement
    : columnDeclaration
    | indexDeclaration
    | constraintDeclaration
    | projectionDeclaration
    | primaryKeyDeclaration
    | foreignKeyDeclaration
    | tableStatistics
    ;

columnDeclaration
    : compoundIdentifier dataType?
        (nullableClause
         | defaultClause
         | codecClause
         | ttlClause
         | statisticsClause
         | commentClause
         | primaryKeyMarker
         | columnSettingsClause
        )*
    ;

// Per-column SETTINGS(...) clause (used by MergeTree column-level tuning).
columnSettingsClause
    : SETTINGS LPAREN settingAssignment (COMMA settingAssignment)* RPAREN
    ;

nullableClause
    : NOT NULL_KW
    | NULL_KW
    ;

defaultClause
    : (DEFAULT | MATERIALIZED | ALIAS) expr
    | EPHEMERAL expr?                              // EPHEMERAL may omit the expression
    ;

codecClause
    : CODEC LPAREN codecArg (COMMA codecArg)* RPAREN
    ;

codecArg
    : identifier (LPAREN functionArgList? RPAREN)?
    ;

ttlClause
    : TTL ttlElement (COMMA ttlElement)*
    ;

ttlElement
    : expr ttlAction? (WHERE expr)? (SETTINGS LPAREN settingAssignment (COMMA settingAssignment)* RPAREN)?
    ;

ttlAction
    : DELETE
    | TO DISK ifExists? STRING_LITERAL
    | TO VOLUME ifExists? STRING_LITERAL
    | GROUP BY expr (COMMA expr)* (SET assignmentList)?
    | RECOMPRESS CODEC LPAREN codecArg (COMMA codecArg)* RPAREN
    ;

statisticsClause
    : STATISTICS LPAREN identifier (COMMA identifier)* RPAREN
    ;

commentClause
    : COMMENT STRING_LITERAL
    ;

primaryKeyMarker
    : PRIMARY KEY
    ;

indexDeclaration
    : INDEX ifNotExists? identifier (LPAREN expr RPAREN | expr) (TYPE codecArg)? (GRANULARITY NUMBER)?
    ;

constraintDeclaration
    : CONSTRAINT identifier (CHECK | ASSUME) expr
    ;

projectionDeclaration
    : PROJECTION identifier
        (INDEX identifier TYPE codecArg)?          // PROJECTION p INDEX idx TYPE t
        (LPAREN selectUnion RPAREN)?
        (WITH SETTINGS LPAREN settingAssignment (COMMA settingAssignment)* RPAREN)?
    ;

primaryKeyDeclaration
    : PRIMARY KEY expr
    | PRIMARY KEY LPAREN (expr (COMMA expr)*)? RPAREN
    ;

foreignKeyDeclaration
    : FOREIGN KEY LPAREN identifier (COMMA identifier)* RPAREN
        REFERENCES databaseAndTableName LPAREN identifier (COMMA identifier)* RPAREN
        (ON DELETE (RESTRICT | CASCADE | SET NULL_KW | SET DEFAULT | NO ACTION))?
        (ON UPDATE (RESTRICT | CASCADE | SET NULL_KW | SET DEFAULT | NO ACTION))?
    ;

tableStatistics
    : STATISTICS identifier (COMMA identifier)* TYPE codecArg (COMMA codecArg)*
    ;

// ENGINE declaration. Both the `ENGINE = <name>` head and the trailing option
// list (`ORDER BY`, `PARTITION BY`, ...) are independently optional — the
// reference parser accepts `CREATE TABLE t(...) ORDER BY k AS SELECT ...`
// without an explicit ENGINE.
engineClause
    : ENGINE EQ? identifier (LPAREN functionArgList? RPAREN)? engineOption*
    | engineOption+
    ;

engineOption
    : PARTITION BY expr
    | PRIMARY KEY expr
    | ORDER BY engineOrderBy
    | SAMPLE BY expr
    | TTL ttlElement (COMMA ttlElement)*
    | settingsClause
    ;

engineOrderBy
    : engineOrderByExpr
    | LPAREN (engineOrderByExpr (COMMA engineOrderByExpr)*)? RPAREN
    ;

// Engine-level ORDER BY can annotate each expression with ASC/DESC for
// reverse primary keys.
engineOrderByExpr
    : expr (ASC | DESC)?
    ;

// --- CREATE VIEW variants -----------------------------------------------------

createView
    : createOrReplace (MATERIALIZED | LIVE | WINDOW)? VIEW ifNotExists?
        databaseAndTableName uuidClause? onCluster?
        viewTargets?
        refreshStrategy?
        tableBody?
        engineClause?
        sqlSecurity?
        asSelect
        commentClause?
    ;

viewTargets
    : TO databaseAndTableName tableBody?
    ;

refreshStrategy
    : REFRESH (EVERY | AFTER) expr intervalUnit?
        (OFFSET expr intervalUnit?)?
        (RANDOMIZE FOR expr intervalUnit?)?
        (DEPENDS ON refreshDependsList)?
        APPEND?
        (TO databaseAndTableName)?
        settingsClause?
    ;

refreshDependsList
    : databaseAndTableName (COMMA databaseAndTableName)*
    ;

sqlSecurity
    : SQL SECURITY (DEFINER | INVOKER | NONE)
    | DEFINER EQ (identifier | STRING_LITERAL)
    ;

// --- CREATE DATABASE ----------------------------------------------------------

createDatabase
    : createOrReplace DATABASE ifNotExists?
        databaseAndTableName uuidClause? onCluster?
        engineClause?
        (commentClause | formatClause | settingsClause)*
    ;

// --- CREATE DICTIONARY --------------------------------------------------------

createDictionary
    : createOrReplace DICTIONARY ifNotExists?
        databaseAndTableName uuidClause? onCluster?
        LPAREN dictionaryAttribute (COMMA dictionaryAttribute)* COMMA? RPAREN
        (PRIMARY KEY (LPAREN expr (COMMA expr)* RPAREN | expr (COMMA expr)*))?
        dictionaryBodyClause*
        commentClause?
    ;

dictionaryAttribute
    : identifier dataType dictionaryAttributeOption*
    ;

dictionaryAttributeOption
    : DEFAULT expr
    | EXPRESSION expr
    | HIERARCHICAL
    | INJECTIVE
    | IS_OBJECT_ID
    ;

// SOURCE/LAYOUT/LIFETIME/RANGE/SETTINGS may appear in any order after the
// dictionary attribute list.
dictionaryBodyClause
    : SOURCE LPAREN sourceArg* RPAREN
    | LIFETIME LPAREN lifetimeArg RPAREN
    | LAYOUT LPAREN layoutArg RPAREN
    | RANGE LPAREN rangeArg RPAREN
    | settingsClause
    ;

// Dictionary SOURCE(...) / LAYOUT(...) args use whitespace-separated
// key/value and nested-section forms rather than a comma list.
sourceArg
    : identifier LPAREN sourceArg* RPAREN            // nested section: MYSQL(...)
    | identifier EQ expr
    | identifier expr                                 // HOST 'localhost'
    | identifier                                      // bare flag
    ;

lifetimeArg
    : NUMBER
    | MIN NUMBER MAX NUMBER
    | MAX NUMBER MIN NUMBER
    ;

layoutArg
    : identifier (LPAREN sourceArg* RPAREN)?
    ;

rangeArg
    : MIN identifier MAX identifier
    | MAX identifier MIN identifier
    ;

// --- CREATE INDEX -------------------------------------------------------------

createIndex
    : CREATE UNIQUE? INDEX ifNotExists? identifier onCluster? ON databaseAndTableName
        (LPAREN expr RPAREN | expr)
        (TYPE codecArg)?
        (GRANULARITY NUMBER)?
    ;

// =============================================================================
// ALTER (ParserAlterQuery.cpp)
// =============================================================================

alterStatement
    : ALTER (TABLE | TEMPORARY TABLE | DATABASE | USER | ROLE | QUOTA | POLICY | SETTINGS PROFILE)?
        databaseAndTableName onCluster?
        alterCommand (COMMA alterCommand)*
        (settingsClause | formatClause)*
    ;

alterCommand
    : alterColumn
    | alterIndex
    | alterProjection
    | alterConstraint
    | alterStatistics
    | alterTableLevel
    | alterPartition
    | alterMutation
    | alterCleanup
    | LPAREN alterCommand RPAREN
    ;

alterColumn
    : ADD COLUMN ifNotExists? columnDeclaration (AFTER compoundIdentifier | FIRST)?
    | DROP COLUMN ifExists? compoundIdentifier
    | CLEAR COLUMN ifExists? compoundIdentifier (IN PARTITION expr)?
    | RENAME COLUMN ifExists? compoundIdentifier TO compoundIdentifier
    | COMMENT COLUMN ifExists? compoundIdentifier STRING_LITERAL
    | MATERIALIZE COLUMN compoundIdentifier (IN PARTITION expr)?
    | MODIFY COLUMN ifExists? columnDeclaration (AFTER compoundIdentifier | FIRST)?
    | MODIFY COLUMN ifExists? compoundIdentifier REMOVE (DEFAULT | MATERIALIZED | ALIAS | CODEC | COMMENT | TTL | SETTINGS)
    | MODIFY COLUMN ifExists? compoundIdentifier RESET SETTING identifier (COMMA identifier)*
    | MODIFY COLUMN ifExists? compoundIdentifier MODIFY SETTING settingAssignment (COMMA settingAssignment)*
    ;

ifExists : IF EXISTS ;

alterIndex
    : ADD indexDeclaration (AFTER identifier | FIRST)?
    | DROP INDEX ifExists? identifier
    | CLEAR INDEX ifExists? identifier (IN PARTITION expr)?
    | MATERIALIZE INDEX identifier (IN PARTITION expr)?
    ;

alterProjection
    : ADD PROJECTION ifNotExists? identifier LPAREN selectUnion RPAREN
        (WITH SETTINGS LPAREN settingAssignment (COMMA settingAssignment)* RPAREN)?
        (AFTER identifier | FIRST)?
    | DROP PROJECTION ifExists? identifier
    | CLEAR PROJECTION ifExists? identifier (IN PARTITION expr)?
    | MATERIALIZE PROJECTION ifExists? identifier (IN PARTITION expr)?
    ;

alterConstraint
    : ADD CONSTRAINT ifNotExists? constraintDeclaration
    | DROP CONSTRAINT ifExists? identifier
    ;

alterStatistics
    : ADD STATISTICS identifier (COMMA identifier)* TYPE codecArg (COMMA codecArg)*
    | DROP STATISTICS identifier (COMMA identifier)*
    | CLEAR STATISTICS identifier (COMMA identifier)*
    | MATERIALIZE STATISTICS identifier (COMMA identifier)*
    | MODIFY STATISTICS identifier (COMMA identifier)* TYPE codecArg (COMMA codecArg)*
    ;

alterTableLevel
    : MODIFY ORDER BY expr
    | MODIFY SAMPLE BY expr
    | REMOVE SAMPLE BY
    | MODIFY TTL ttlElement (COMMA ttlElement)*
    | REMOVE TTL
    | MATERIALIZE TTL (IN PARTITION expr)?
    | MODIFY QUERY selectUnion
    | MODIFY REFRESH refreshStrategy
    | MODIFY SETTING settingAssignment (COMMA settingAssignment)*
    | RESET SETTING identifier (COMMA identifier)*
    | MODIFY COMMENT STRING_LITERAL
    | MODIFY DATABASE COMMENT STRING_LITERAL
    | MODIFY DEFINER EQ (identifier | STRING_LITERAL)
    | MODIFY SQL SECURITY (DEFINER | INVOKER | NONE)
    ;

alterPartition
    : ATTACH PARTITION (partitionKey | ALL) (FROM databaseAndTableName)?
    | ATTACH PART expr (FROM databaseAndTableName)?
    | DETACH PARTITION (partitionKey | ALL)
    | DETACH PART expr
    | DROP PARTITION (partitionKey | ALL)
    | DROP PART expr
    | DROP DETACHED PARTITION partitionKey
    | DROP DETACHED PART expr
    | FORGET PARTITION partitionKey
    | MOVE PARTITION partitionKey (TO (DISK | VOLUME | TABLE | SHARD) expr)?
    | MOVE PART expr (TO (DISK | VOLUME | TABLE | SHARD) expr)?
    | REPLACE PARTITION partitionKey FROM databaseAndTableName
    | FREEZE (PARTITION partitionKey)? (WITH NAME STRING_LITERAL)?
    | UNFREEZE (PARTITION partitionKey)? (WITH NAME STRING_LITERAL)?
    | FETCH PARTITION partitionKey FROM STRING_LITERAL
    | FETCH PART expr FROM STRING_LITERAL
    ;

partitionKey
    : ID STRING_LITERAL
    | expr
    ;

alterMutation
    : UPDATE assignmentList (IN PARTITION partitionKey)? WHERE expr (IN PARTITION partitionKey)?
    | DELETE (IN PARTITION partitionKey)? WHERE expr (IN PARTITION partitionKey)?
    ;

alterCleanup
    : CLEANUP
    | APPLY PATCHES
    | APPLY DELETED MASK (IN PARTITION partitionKey)?
    | REWRITE PARTS
    ;

// =============================================================================
// DROP / UNDROP / RENAME / TRUNCATE
// =============================================================================

dropStatement
    : DROP TEMPORARY? (TABLE | VIEW | DICTIONARY | DATABASE) ifExists?
        databaseAndTableName (COMMA databaseAndTableName)* onCluster?
        (PERMANENTLY | NO DELAY | SYNC | ASYNC)?
        (settingsClause | formatClause)*
    | DROP INDEX ifExists? identifier onCluster? (ON databaseAndTableName)?
    ;

undropStatement
    : UNDROP TABLE ifExists? databaseAndTableName uuidClause? onCluster?
    ;

renameStatement
    : RENAME (TABLE | DICTIONARY | DATABASE)?
        renameEntry (COMMA renameEntry)* onCluster?
    | EXCHANGE (TABLES | DICTIONARIES) databaseAndTableName AND databaseAndTableName onCluster?
    ;

renameEntry
    : databaseAndTableName TO databaseAndTableName
    ;

truncateStatement
    : TRUNCATE TEMPORARY? TABLE? ifExists? databaseAndTableName onCluster?
        (PERMANENTLY | NO DELAY | SYNC | ASYNC)?
        settingsClause?
    | TRUNCATE ALL? TABLES FROM ifExists? nameOrParam ((NOT)? LIKE STRING_LITERAL)? onCluster?
    ;

// =============================================================================
// OPTIMIZE / CHECK / DESCRIBE / EXISTS
// =============================================================================

optimizeStatement
    : OPTIMIZE TABLE databaseAndTableName onCluster?
        (PARTITION partitionKey)?
        ( FINAL | FORCE
        | DEDUPLICATE (BY (LPAREN expr (COMMA expr)* RPAREN | expr (COMMA expr)*))?
        | DRY RUN PARTS STRING_LITERAL (COMMA STRING_LITERAL)*
        | CLEANUP
        )*
        settingsClause?
    ;

checkStatement
    : CHECK TABLE databaseAndTableName (PARTITION partitionKey | PART STRING_LITERAL)?
        (settingsClause | formatClause)*
    | CHECK DATABASE databaseAndTableName (settingsClause | formatClause)*
    | CHECK ALL TABLES (settingsClause | formatClause)*
    ;

describeStatement
    : (DESCRIBE | DESC) TABLE? TEMPORARY?
        (databaseAndTableName | tableFunctionCall | LPAREN selectUnion RPAREN | selectUnion)
        (settingsClause | formatClause)*
    ;

existsStatement
    : EXISTS TEMPORARY? (TABLE | VIEW | DATABASE | DICTIONARY)?
        databaseAndTableName
    ;

// =============================================================================
// SYSTEM (ParserSystemQuery.cpp; command enum in ASTSystemQuery.h)
// =============================================================================

systemStatement
    : SYSTEM onCluster? systemCommand onCluster? systemTarget? settingsClause?
    ;

// SYSTEM commands. These are sequences of single-word keywords (from the
// Type enum in ASTSystemQuery.h with underscore → space). The full list is
// expressed as alternatives of token sequences; the rule is intentionally
// permissive to cover the ~110 command variants.
systemCommand
    : SHUTDOWN
    | KILL
    | SUSPEND (FOR expr (SECOND | SECONDS))?
    | UNFREEZE (WITH NAME STRING_LITERAL)?
    | UNLOCK SNAPSHOT STRING_LITERAL (FROM identifier LPAREN functionArgList? RPAREN)?
    // START / STOP / RESTART / RESTORE families
    | (START | STOP | RESTART | RESTORE | SYNC | WAIT | REFRESH | CANCEL | TEST | PAUSE | RESUME | DROP | CLEAR | LOAD | UNLOAD | PREWARM | ENABLE | DISABLE | NOTIFY | RELOAD | FLUSH | RESET | SYNC | SET | UNSET | ALLOCATE | FREE) systemCommandTail
    // SYSTEM KILL ...
    | KILL systemCommandTail
    // JEMALLOC
    | JEMALLOC (PURGE | FLUSH PROFILE | ENABLE PROFILE | DISABLE PROFILE)
    // Special INSTRUMENT commands
    | INSTRUMENT (ADD | REMOVE) identifier (LPAREN functionArgList? RPAREN)?
    ;

// Catch-all tail for the many space-separated SYSTEM command names
// (MERGES, REPLICA, DATABASE REPLICA, MARK CACHE, DISTRIBUTED SENDS, ...).
// Accepts an optional comma-separated identifier tail for commands like
// SYSTEM FLUSH LOGS log1, log2 and SYSTEM FLUSH ASYNC INSERT QUEUE name.
systemCommandTail
    : identifier+ (LPAREN functionArgList? RPAREN)? (COMMA identifier)*
    ;

// Target specifier — SYSTEM SYNC REPLICA name, SYSTEM DROP REPLICA '...' FROM ...
systemTarget
    : ON VOLUME identifier DOT identifier
    | STRING_LITERAL (FROM SHARD STRING_LITERAL)?
        ( FROM TABLE databaseAndTableName
        | FROM DATABASE identifier
        | FROM ZKPATH STRING_LITERAL
        )?
    | databaseAndTableName
    ;

// =============================================================================
// SHOW (ParserShow*Query.cpp)
// =============================================================================

showStatement
    : SHOW CREATE TEMPORARY? (TABLE | VIEW | DICTIONARY | DATABASE | USER | ROLE | QUOTA | ROW? POLICY | SETTINGS? PROFILE | NAMED COLLECTION | WORKLOAD | RESOURCE | FUNCTION)? showTarget (settingsClause | formatClause)*  # showCreate
    | SHOW TABLE databaseAndTableName (settingsClause | formatClause)*        # showTable   // alias for SHOW CREATE TABLE
    | SHOW DATABASE databaseAndTableName (settingsClause | formatClause)*     # showDatabase // alias for SHOW CREATE DATABASE
    | SHOW FULL? TEMPORARY? TABLES (FROM databaseAndTableName | IN databaseAndTableName)? showFilter? limitOptional? formatClause?   # showTables
    | SHOW DATABASES showFilter? limitOptional? formatClause?                  # showDatabases
    | SHOW CLUSTERS showFilter? limitOptional? formatClause?                   # showClusters
    | SHOW CLUSTER STRING_LITERAL                                              # showCluster
    | SHOW DICTIONARIES (FROM identifier)? showFilter? limitOptional? formatClause?  # showDictionaries
    | SHOW (EXTENDED | FULL)? COLUMNS (FROM | IN) databaseAndTableName (FROM identifier)? showFilter? limitOptional?  # showColumns
    | SHOW (EXTENDED | FULL)? (INDEX | INDEXES | INDICES | KEYS) (FROM | IN) databaseAndTableName (FROM identifier)? showFilter?  # showIndexes
    | SHOW MERGES (FROM databaseAndTableName)? (WHERE expr)? limitOptional?    # showMerges
    | SHOW CHANGED? SETTINGS ((LIKE | ILIKE) STRING_LITERAL)? limitOptional?   # showSettings
    | SHOW SETTING identifier                                                  # showSetting
    | SHOW FILESYSTEM CACHES                                                   # showFsCaches
    | SHOW ENGINES                                                             # showEngines
    | SHOW FUNCTIONS showFilter? limitOptional?                                # showFunctions
    | SHOW PROCESSLIST showFilter? (WHERE expr)?                               # showProcesslist
    | SHOW ACCESS                                                              # showAccess
    | SHOW CURRENT? QUOTA                                                      # showQuota
    | SHOW GRANTS (FOR (CURRENTUSER | CURRENT_USER | identifier))? formatClause?  # showGrants
    | SHOW PRIVILEGES                                                          # showPrivileges
    | SHOW CURRENT ROLES                                                       # showCurrentRoles
    | SHOW ENABLED ROLES                                                       # showEnabledRoles
    | SHOW ROW? accessEntitiesKeyword ((FROM | ON) databaseAndTableName)?      # showAccessEntities
    ;

// Words used as access-entity list keywords — many (POLICIES, QUOTAS) are not
// in CommonParsers.h as MR_MACROS keywords but are recognized by access-query
// parsers (ParserShowAccessEntitiesQuery.cpp) via text match. We accept them
// either as a declared keyword or a bare identifier.
accessEntitiesKeyword
    : USERS | ROLES | PROFILES | identifier
    ;

showFilter
    : NOT? (LIKE | ILIKE) STRING_LITERAL
    | WHERE expr
    ;

// Target for SHOW CREATE — may be a qualified name, a `user@host` access-
// entity target, or a bare identifier (e.g. SHOW CREATE QUOTA default).
showTarget
    : (databaseAndTableName | STRING_LITERAL) (AT (identifier | STRING_LITERAL))?
    ;

limitOptional
    : LIMIT expr
    ;

// =============================================================================
// EXPLAIN (ParserExplainQuery.cpp)
// =============================================================================

explainStatement
    : EXPLAIN explainKind?
        (settingsClause | explainSetting (COMMA explainSetting)*)?
        statement?
    ;

// EXPLAIN can take bare key=value settings without the SETTINGS prefix
// (e.g. `EXPLAIN PLAN header = 1 SELECT 1`).
explainSetting
    : identifier EQ expr
    ;

explainKind
    : AST
    | SYNTAX
    | QUERY TREE
    | PIPELINE
    | PLAN
    | ESTIMATE
    | TABLE OVERRIDE
    | CURRENT TRANSACTION
    ;

// =============================================================================
// KILL (ParserKillQueryQuery.cpp)
// =============================================================================

killStatement
    : KILL (QUERY | MUTATION | TRANSACTION | PART_MOVE_TO_SHARD)? onCluster?
        (WHERE expr)? (SYNC | ASYNC | TEST)?
        formatClause?
    ;

// =============================================================================
// WATCH (ParserWatchQuery.cpp)
// =============================================================================

watchStatement
    : WATCH databaseAndTableName EVENTS? (LIMIT expr)?
    ;

// =============================================================================
// ATTACH / DETACH (ParserAttachAccessEntity.cpp + ParserDetach... via ALTER)
// Generic forms; access-entity ATTACH variants land in checkpoint 6.
// =============================================================================

attachStatement
    : ATTACH (TABLE | VIEW | DICTIONARY | DATABASE | TEMPORARY TABLE)? ifNotExists?
        databaseAndTableName uuidClause? onCluster?
        (FROM STRING_LITERAL)?          // ATTACH TABLE t FROM '/path' (cols) ENGINE=...
        tableBody? engineClause? asSelect?
    | ATTACH PART STRING_LITERAL FROM? STRING_LITERAL?
    | ATTACH PARTITION partitionKey FROM? STRING_LITERAL?
    ;

detachStatement
    : DETACH (TABLE | VIEW | DICTIONARY | DATABASE | TEMPORARY TABLE)? ifExists?
        databaseAndTableName onCluster? (PERMANENTLY | NO DELAY | SYNC | ASYNC)?
    | DETACH PART STRING_LITERAL
    | DETACH PARTITION partitionKey
    ;

// =============================================================================
// Access control: GRANT / REVOKE / CHECK GRANT / SET ROLE (Parsers/Access/*)
// =============================================================================

grantStatement
    : GRANT onCluster? grantPrivItem (COMMA grantPrivItem)*
        TO granteeList (WITH GRANT OPTION | WITH REPLACE OPTION)*
    | GRANT onCluster? roleList TO granteeList
        (WITH ADMIN OPTION | WITH REPLACE OPTION)*
    ;

// A single `<privs> ON <target>` — GRANT can chain several with commas.
grantPrivItem
    : privilegeList ON grantTarget
    ;

revokeStatement
    : REVOKE onCluster? (GRANT OPTION FOR | ADMIN OPTION FOR)?
        (privilegeList ON grantTarget FROM granteeList
         | roleList FROM granteeList)
    ;

checkGrantStatement
    : CHECK GRANT privilegeList ON grantTarget
    ;

privilegeList
    : privilege (COMMA privilege)*
    ;

privilege
    : privilegeWord+ (LPAREN identifier (COMMA identifier)* RPAREN)?
    ;

// Words that may appear in GRANT/REVOKE privilege names. Many are core
// keywords (SELECT, INSERT, ...) that aren't non-reserved identifiers
// elsewhere, so we carve out a dedicated set here.
privilegeWord
    : identifier
    | SELECT | INSERT | UPDATE | DELETE | CREATE | ALTER | DROP | SHOW
    | GRANT | REVOKE | BACKUP | RESTORE | SYSTEM | OPTIMIZE | TRUNCATE | USE
    | ALL | NONE | ADMIN | OPTION
    ;

grantTarget
    : STAR DOT STAR
    | identifier DOT STAR
    | databaseAndTableName
    ;

granteeList
    : grantee (COMMA grantee)*
    ;

grantee
    : CURRENT_USER
    | CURRENTUSER
    | identifier
    ;

roleList
    : identifier (COMMA identifier)*
    ;

setRoleStatement
    : SET DEFAULT ROLE (roleList | ALL | NONE) TO granteeList
    | SET ROLE (DEFAULT | NONE | ALL (EXCEPT roleList)? | roleList)
    ;

// ===== CREATE/ALTER/DROP USER/ROLE/POLICY/QUOTA/PROFILE ======================

createAccessStatement
    : (CREATE | ATTACH) (OR REPLACE)? accessEntityKind (OR REPLACE)? ifNotExists?
        accessEntityNameTarget (COMMA accessEntityNameTarget)*
        onCluster?
        (ON policyTarget (COMMA policyTarget)*)?
        accessEntityBodyItem*
    ;

alterAccessStatement
    : ALTER accessEntityKind ifExists?
        accessEntityNameTarget (COMMA accessEntityNameTarget)*
        onCluster?
        (ON policyTarget (COMMA policyTarget)*)?
        (RENAME TO accessEntityNameTarget)?
        accessEntityBodyItem*
    ;

// Row policies are scoped to a table (`CREATE ROW POLICY p ON db.t ...`); all
// access entities also support ON CLUSTER. Branching on what follows ON avoids
// ANTLR prematurely committing to one alternative.
accessEntityOnClause
    : ON CLUSTER (identifier | STRING_LITERAL)
    | ON policyTarget (COMMA policyTarget)*
    ;

// Row policies can scope to a single table (`db.t`), all tables in a db
// (`db.*`), or everything (`*`).
policyTarget
    : databaseAndTableName
    | identifier DOT STAR
    | STAR
    ;

dropAccessStatement
    : DROP accessEntityKind ifExists?
        accessEntityNameTarget (COMMA accessEntityNameTarget)*
        (ON policyTarget (COMMA policyTarget)*)?
        onCluster?
        (FROM STRING_LITERAL)?
    | MOVE accessEntityKind identifier TO STRING_LITERAL
    ;

// Access-entity name targets. Users can be scoped by `@host`; quoted-string
// names are accepted as well (e.g. SHOW CREATE USER 'alice@1.2.3.4').
accessEntityNameTarget
    : (identifier | STRING_LITERAL) (AT (identifier | STRING_LITERAL))?
    ;

accessEntityKind
    : USER
    | ROLE
    | QUOTA
    | ROW? POLICY
    | MASKING POLICY
    | SETTINGS? PROFILE
    ;

// Loose grab-bag for the per-entity clauses; mirrors the extensive options in
// ParserCreateUserQuery.cpp / ParserCreateRowPolicyQuery.cpp / etc.
accessEntityBodyItem
    : IDENTIFIED identifiedMethod (COMMA identifiedMethod)*
    | IDENTIFIED
    | NOT IDENTIFIED
    | DEFAULT ROLE (identifier (COMMA identifier)* | NONE | ALL (EXCEPT identifier+)?)
    | DEFAULT DATABASE identifier
    | (ADD | DROP)? HOST (ANY | NONE | hostSpec (COMMA hostSpec)*)
    | GRANTEES (ANY | NONE | identifier (COMMA identifier)* | EXCEPT identifier (COMMA identifier)*)
    | SETTINGS accessSettingItem (COMMA accessSettingItem)*
    | VALID UNTIL STRING_LITERAL
    | IN STRING_LITERAL
    | TO granteeList
    | FOR (SELECT | INSERT | UPDATE | DELETE | ALL)
    | AS (PERMISSIVE | RESTRICTIVE)
    | USING expr
    | WITH CHECK expr
    | KEYED BY identifier (COMMA identifier)*
    | FOR RANDOMIZED? INTERVAL expr intervalUnit quotaLimits
    | NO LIMITS
    | TRACKING ONLY
    | (ADD | MODIFY)? SETTINGS accessSettingItem (COMMA accessSettingItem)*
    | DROP SETTINGS identifier (COMMA identifier)*
    | ADMIN OPTION FOR identifier
    | ENABLE FOR granteeList
    | DISABLE FOR granteeList
    | commentClause
    ;

hostSpec
    : (LOCAL | NAME | REGEXP | LIKE | IP)? STRING_LITERAL
    | (LOCAL | NAME | REGEXP | LIKE | IP)
    ;

// Authentication clause segments. ClickHouse allows mixing method and BY
// clauses in any order, with subsequent BY-only entries reusing the previous
// method name. We accept the union loosely.
identifiedMethod
    : WITH identifier (BY identifiedBy)?
    | BY identifiedBy
    | identifier (BY identifiedBy)?
    ;

identifiedBy
    : STRING_LITERAL
    | queryParameter
    | LPAREN functionArgList? RPAREN
    ;

accessSettingItem
    : identifier (EQ expr)?
      (MIN EQ? expr | MAX EQ? expr | READONLY | WRITABLE | CONST | CHANGEABLE_IN_READONLY)*
    ;

quotaLimits
    : NO? LIMITS
    | (MAX identifier (EQ expr | expr))+
    ;

// =============================================================================
// CREATE / DROP FUNCTION, NAMED COLLECTION, RESOURCE, WORKLOAD
// =============================================================================

createFunctionStatement
    : (CREATE | ATTACH) (OR REPLACE)? WASM? FUNCTION ifNotExists?
        identifier onCluster?
        AS (expr | STRING_LITERAL) settingsClause?
    ;

dropFunctionStatement
    : DROP FUNCTION ifExists? identifier onCluster?
    ;

createNamedCollectionStatement
    : (CREATE | ATTACH) (OR REPLACE)? NAMED COLLECTION ifNotExists?
        identifier onCluster?
        AS namedCollectionAssignment (COMMA namedCollectionAssignment)*
        commentClause?
    ;

namedCollectionAssignment
    : identifier EQ expr (OVERRIDABLE | NOT OVERRIDABLE)?
    ;

alterNamedCollectionStatement
    : ALTER NAMED COLLECTION ifExists? identifier onCluster?
        (SET namedCollectionAssignment (COMMA namedCollectionAssignment)*)?
        (DELETE identifier (COMMA identifier)*)?
    ;

dropNamedCollectionStatement
    : DROP NAMED COLLECTION ifExists? identifier onCluster?
    ;

createResourceStatement
    : (CREATE | ATTACH) (OR REPLACE)? RESOURCE ifNotExists?
        identifier onCluster?
        LPAREN resourceOp (COMMA resourceOp)* RPAREN
        settingsClause?
    ;

resourceOp
    : (READ | WRITE | MASTER THREAD | WORKER THREAD) (DISK | ANY DISK) identifier?
    ;

dropResourceStatement
    : DROP RESOURCE ifExists? identifier onCluster?
    ;

createWorkloadStatement
    : (CREATE | ATTACH) (OR REPLACE)? WORKLOAD ifNotExists?
        identifier onCluster?
        (IN identifier)?
        settingsClause?
    ;

dropWorkloadStatement
    : DROP WORKLOAD ifExists? identifier onCluster?
    ;

// =============================================================================
// BACKUP / RESTORE / SNAPSHOT
// =============================================================================

backupStatement
    : BACKUP ASYNC? backupScope TO backupDestination onCluster?
        (settingsClause | formatClause)*
    ;

restoreStatement
    : RESTORE ASYNC? backupScope FROM backupDestination onCluster?
        (settingsClause | formatClause)*
    ;

snapshotStatement
    : SNAPSHOT backupScope TO backupDestination onCluster? settingsClause?
    ;

// The reference parser allows backup targets to appear either comma-separated
// or space-separated: BACKUP TABLES a, b EXCEPT TABLES c TO ...
backupScope
    : backupTarget (COMMA? backupTarget)*
    ;

backupTarget
    : (DATABASES | DATABASE) identifier (COMMA identifier)*
    | (TABLES | TABLE) databaseAndTableName (COMMA databaseAndTableName)* (AS databaseAndTableName)?
    | EXCEPT (DATABASES | DATABASE) identifier (COMMA identifier)*
    | EXCEPT (TABLES | TABLE) databaseAndTableName (COMMA databaseAndTableName)*
    | (PARTITION | PARTITIONS) partitionKey (COMMA partitionKey)*
    | TEMPORARY TABLE databaseAndTableName
    | ALL
    ;

backupDestination
    : identifier (LPAREN functionArgList? RPAREN)?
    | STRING_LITERAL
    ;

// =============================================================================
// COPY / PARALLEL WITH / PREPARED STATEMENT
// =============================================================================

copyStatement
    : COPY (databaseAndTableName (LPAREN identifier (COMMA identifier)* RPAREN)?
            | LPAREN selectUnion RPAREN)
        (FROM | TO) (STRING_LITERAL | identifier LPAREN functionArgList? RPAREN)
        settingsClause?
    ;

parallelWithStatement
    : PARALLEL WITH (statement | LPAREN selectUnion RPAREN)
        (COMMA (statement | LPAREN selectUnion RPAREN))+
    ;

preparedStatement
    : PREPARE identifier AS statement
    | EXECUTE identifier (LPAREN (expr (COMMA expr)*)? RPAREN)?
    ;

deallocateStatement
    : DEALLOCATE PREPARE? identifier
    ;

