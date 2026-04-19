// ClickHouseLexer.g4
//
// ANTLR4 lexer for ClickHouse SQL. Transcribed from the C++ reference lexer at
//   ClickHouse/src/Parsers/Lexer.cpp and the keyword set at
//   ClickHouse/src/Parsers/CommonParsers.h (+ ASTSystemQuery.h).
//
// Design notes (see ../README.md for the full story):
//   * Multi-word "keywords" in CommonParsers.h (e.g. "ORDER BY", "NOT LIKE") are
//     matched by the reference parser with inter-word whitespace/comments
//     allowed. In ANTLR we tokenize each primitive word separately and compose
//     the multi-word phrases in parser rules.
//   * Keyword matching is case-insensitive (ClickHouse uses strncasecmp), which
//     we get via per-letter fragments (A : [aA]; ...).
//   * Nested /* ... */ comments are handled with a self-referential rule.
//   * Numbers are integer-only at lex time (decimal/hex/binary + optional
//     decimal exponent). The decimal point and any fractional part are
//     assembled at parse time (`NUMBER DOT NUMBER`). This is how we avoid the
//     ambiguity between tuple element access (`x.1.1`) and float literals
//     (`1.1`) without needing lexer modes or semantic predicates.
//   * Heredoc tag equality (`$tag$ ... $tag$`) cannot be enforced in a
//     target-agnostic grammar, so we accept any matched `$word$ ... $word$`
//     opaquely. Known limitation for queries that embed `$...$` sequences.

lexer grammar ClickHouseLexer;

// =============================================================================
// Whitespace and comments
// =============================================================================

BLOCK_COMMENT       : '/*' ( BLOCK_COMMENT | . )*? '*/' -> skip ;
LINE_COMMENT        : ('--' | '//') ~[\r\n]*            -> skip ;
HASH_COMMENT        : '#' [ !] ~[\r\n]*                 -> skip ;
// Unicode whitespace characters the reference lexer's skipWhitespacesUTF8
// also treats as whitespace (non-breaking space, BOM, figure space, etc.).
WS                  : [ \t\r\n\f\u000B\u00A0\u1680\u2000-\u200F\u2028\u2029\u202F\u205F\u2060\u3000\uFEFF]+
                        -> skip ;

// =============================================================================
// Punctuation and operators
// =============================================================================

LPAREN              : '(' ;
RPAREN              : ')' ;
LBRACKET            : '[' ;
RBRACKET            : ']' ;
LBRACE              : '{' ;
RBRACE              : '}' ;
COMMA               : ',' ;
SEMICOLON           : ';' ;
DOT                 : '.' ;

PLUS                : '+' ;
MINUS               : '-' | '\u2212' ;  // ASCII hyphen-minus or U+2212
STAR                : '*' ;
SLASH               : '/' ;
PERCENT             : '%' ;

SPACESHIP           : '<=>' ;
LE                  : '<=' ;
GE                  : '>=' ;
NE                  : '!=' | '<>' ;
EQ                  : '=' | '==' ;
LT                  : '<' ;
GT                  : '>' ;

ARROW               : '->' ;
DOUBLE_COLON        : '::' ;
CONCAT              : '||' ;
PIPE                : '|' ;
DOUBLE_AT           : '@@' ;
AT                  : '@' ;
CARET               : '^' ;
QUESTION            : '?' ;
COLON               : ':' ;
DOLLAR              : '$' ;
VERTICAL_DELIM      : '\\G' ;

// =============================================================================
// Keywords (case-insensitive). Multi-word keywords from CommonParsers.h are
// composed in the parser. Full list is derived from CommonParsers.h (both
// APPLY_FOR_PARSER_KEYWORDS and APPLY_FOR_PARSER_KEYWORDS_WITH_UNDERSCORES)
// and ASTSystemQuery.h (the SYSTEM command enum).
// The list is kept in sorted order for easy scanning; re-run
// `tools/gen_keywords.py --verify` to check for divergence from upstream.
// =============================================================================

// --- Single-word keywords, alphabetical ---
ABI                 : A B I ;
ACCESS              : A C C E S S ;
ACTION              : A C T I O N ;
ADD                 : A D D ;
ADMIN               : A D M I N ;
AFTER               : A F T E R ;
ALGORITHM           : A L G O R I T H M ;
ALIAS               : A L I A S ;
ALL                 : A L L ;
ALLOCATE            : A L L O C A T E ;
ALLOWED_LATENESS    : A L L O W E D '_' L A T E N E S S ;
ALTER               : A L T E R ;
AND                 : A N D ;
ANTI                : A N T I ;
ANY                 : A N Y ;
APPEND              : A P P E N D ;
APPLY               : A P P L Y ;
ARGUMENTS           : A R G U M E N T S ;
ARRAY               : A R R A Y ;
AS                  : A S ;
ASC                 : A S C ;
ASCENDING           : A S C E N D I N G ;
ASOF                : A S O F ;
ASSUME              : A S S U M E ;
AST                 : A S T ;
ASYNC               : A S Y N C ;
ASYNCHRONOUS        : A S Y N C H R O N O U S ;
ATTACH              : A T T A C H ;
AUTHENTICATION      : A U T H E N T I C A T I O N ;
AUTO_INCREMENT      : A U T O '_' I N C R E M E N T ;
AZURE               : A Z U R E ;
BACKUP              : B A C K U P ;
BAGEXPANSION        : B A G E X P A N S I O N ;
BASE_BACKUP         : B A S E '_' B A C K U P ;
BCRYPT_HASH         : B C R Y P T '_' H A S H ;
BCRYPT_PASSWORD     : B C R Y P T '_' P A S S W O R D ;
BEGIN               : B E G I N ;
BETWEEN             : B E T W E E N ;
BIDIRECTIONAL       : B I D I R E C T I O N A L ;
BINARY              : B I N A R Y ;
BLOBS               : B L O B S ;
BLOCKING            : B L O C K I N G ;
BOTH                : B O T H ;
BY                  : B Y ;
CACHE               : C A C H E ;
CACHES              : C A C H E S ;
CANCEL              : C A N C E L ;
CASCADE             : C A S C A D E ;
CASE                : C A S E ;
CAST                : C A S T ;
CATALOG             : C A T A L O G ;
CENTURY             : C E N T U R Y ;
CHANGE              : C H A N G E ;
CHANGEABLE_IN_READONLY : C H A N G E A B L E '_' I N '_' R E A D O N L Y ;
CHANGED             : C H A N G E D ;
CHAR                : C H A R ;
CHARACTER           : C H A R A C T E R ;
CHECK               : C H E C K ;
CLEANUP             : C L E A N U P ;
CLEAR               : C L E A R ;
CLIENT              : C L I E N T ;
CLONE               : C L O N E ;
CLUSTER             : C L U S T E R ;
CLUSTER_HOST_IDS    : C L U S T E R '_' H O S T '_' I D S ;
CLUSTERS            : C L U S T E R S ;
CN                  : C N ;
CODEC               : C O D E C ;
COLLATE             : C O L L A T E ;
COLLECTION          : C O L L E C T I O N ;
COLUMN              : C O L U M N ;
COLUMNS             : C O L U M N S ;
COMMENT             : C O M M E N T ;
COMMIT              : C O M M I T ;
COMPILED            : C O M P I L E D ;
COMPRESSION         : C O M P R E S S I O N ;
CONDITION           : C O N D I T I O N ;
CONFIG              : C O N F I G ;
CONNECTIONS         : C O N N E C T I O N S ;
CONST               : C O N S T ;
CONSTRAINT          : C O N S T R A I N T ;
COPY                : C O P Y ;
COVERAGE            : C O V E R A G E ;
CREATE              : C R E A T E ;
CROSS               : C R O S S ;
CUBE                : C U B E ;
CURRENT             : C U R R E N T ;
CURRENTUSER         : C U R R E N T U S E R ;
CURRENT_USER        : C U R R E N T '_' U S E R ;
D_KW                : D ;  // "D" as a keyword; renamed to avoid clash with lexer letter fragments' perceived names
DATA                : D A T A ;
DATABASE            : D A T A B A S E ;
DATABASES           : D A T A B A S E S ;
DATE                : D A T E ;
DAY                 : D A Y ;
DAYS                : D A Y S ;
DD                  : D D ;
DDL                 : D D L ;
DEALLOCATE          : D E A L L O C A T E ;
DECADE              : D E C A D E ;
DEDUPLICATE         : D E D U P L I C A T E ;
DEFAULT             : D E F A U L T ;
DEFINER             : D E F I N E R ;
DELAY               : D E L A Y ;
DELETE              : D E L E T E ;
DELETED             : D E L E T E D ;
DELTA               : D E L T A ;
DEPENDS             : D E P E N D S ;
DESC                : D E S C ;
DESCENDING          : D E S C E N D I N G ;
DESCRIBE            : D E S C R I B E ;
DETACH              : D E T A C H ;
DETACHED            : D E T A C H E D ;
DICTIONARIES        : D I C T I O N A R I E S ;
DICTIONARY          : D I C T I O N A R Y ;
DISABLE             : D I S A B L E ;
DISK                : D I S K ;
DISTINCT            : D I S T I N C T ;
DISTRIBUTED         : D I S T R I B U T E D ;
DIV                 : D I V ;
DNS                 : D N S ;
DOUBLE_SHA1_HASH    : D O U B L E '_' S H A '1' '_' H A S H ;
DOUBLE_SHA1_PASSWORD: D O U B L E '_' S H A '1' '_' P A S S W O R D ;
DOW                 : D O W ;
DOY                 : D O Y ;
DROP                : D R O P ;
DRY                 : D R Y ;
ELSE                : E L S E ;
EMBEDDED            : E M B E D D E D ;
EMPTY               : E M P T Y ;
ENABLE              : E N A B L E ;
ENABLED             : E N A B L E D ;
END                 : E N D ;
ENFORCED            : E N F O R C E D ;
ENGINE              : E N G I N E ;
ENGINES             : E N G I N E S ;
EPHEMERAL           : E P H E M E R A L ;
EPOCH               : E P O C H ;
ESTIMATE            : E S T I M A T E ;
EVENT               : E V E N T ;
EVENTS              : E V E N T S ;
EVERY               : E V E R Y ;
EXCEPT              : E X C E P T ;
EXCHANGE            : E X C H A N G E ;
EXECUTE             : E X E C U T E ;
EXISTS              : E X I S T S ;
EXPLAIN             : E X P L A I N ;
EXPRESSION          : E X P R E S S I O N ;
EXTENDED            : E X T E N D E D ;
EXTERNAL            : E X T E R N A L ;
EXTRACT             : E X T R A C T ;
FAKE                : F A K E ;
FAILPOINT           : F A I L P O I N T ;
FALSE               : F A L S E ;
FETCH               : F E T C H ;
FETCHES             : F E T C H E S ;
FIELDS              : F I E L D S ;
FILE                : F I L E ;
FILES               : F I L E S ;
FILESYSTEM          : F I L E S Y S T E M ;
FILL                : F I L L ;
FILTER              : F I L T E R ;
FINAL               : F I N A L ;
FIRST               : F I R S T ;
FLUSH               : F L U S H ;
FOLLOWING           : F O L L O W I N G ;
FOR                 : F O R ;
FORCE               : F O R C E ;
FOREIGN             : F O R E I G N ;
FORGET              : F O R G E T ;
FORMAT              : F O R M A T ;
FREE                : F R E E ;
FREEZE              : F R E E Z E ;
FROM                : F R O M ;
FULL                : F U L L ;
FULLTEXT            : F U L L T E X T ;
FUNCTION            : F U N C T I O N ;
FUNCTIONS           : F U N C T I O N S ;
FUZZER              : F U Z Z E R ;
GLOBAL              : G L O B A L ;
GRANT               : G R A N T ;
GRANTEES            : G R A N T E E S ;
GRANTS              : G R A N T S ;
GRANULARITY         : G R A N U L A R I T Y ;
GROUP               : G R O U P ;
GROUPING            : G R O U P I N G ;
GROUPS              : G R O U P S ;
H_KW                : H ;
HASH                : H A S H ;
HAVING              : H A V I N G ;
HDFS                : H D F S ;
HEADER              : H E A D E R ;
HH                  : H H ;
HIERARCHICAL        : H I E R A R C H I C A L ;
HOST                : H O S T ;
HOUR                : H O U R ;
HOURS               : H O U R S ;
HTTP                : H T T P ;
ICEBERG             : I C E B E R G ;
ID                  : I D ;
IDENTIFIED          : I D E N T I F I E D ;
IF                  : I F ;
IGNORE              : I G N O R E ;
ILIKE               : I L I K E ;
IMPLICIT            : I M P L I C I T ;
IN                  : I N ;
INDEX               : I N D E X ;
INDEXES             : I N D E X E S ;
INDICES             : I N D I C E S ;
INFILE              : I N F I L E ;
INHERIT             : I N H E R I T ;
INJECTIVE           : I N J E C T I V E ;
INNER               : I N N E R ;
INSERT              : I N S E R T ;
INSTRUMENT          : I N S T R U M E N T ;
INTERPOLATE         : I N T E R P O L A T E ;
INTERSECT           : I N T E R S E C T ;
INTERVAL            : I N T E R V A L ;
INTO                : I N T O ;
INVISIBLE           : I N V I S I B L E ;
INVOKER             : I N V O K E R ;
IP                  : I P ;
IS                  : I S ;
ISODOW              : I S O D O W ;
ISOYEAR             : I S O Y E A R ;
IS_OBJECT_ID        : I S '_' O B J E C T '_' I D ;
JEMALLOC            : J E M A L L O C ;
JOIN                : J O I N ;
JWT                 : J W T ;
KERBEROS            : K E R B E R O S ;
KERNEL              : K E R N E L ;
KEY                 : K E Y ;
KEYED               : K E Y E D ;
KEYS                : K E Y S ;
KILL                : K I L L ;
KIND                : K I N D ;
LANGUAGE            : L A N G U A G E ;
LARGE               : L A R G E ;
LAST                : L A S T ;
LAYOUT              : L A Y O U T ;
LDAP                : L D A P ;
LEADING             : L E A D I N G ;
LEFT                : L E F T ;
LESS                : L E S S ;
LEVEL               : L E V E L ;
LIFETIME            : L I F E T I M E ;
LIGHTWEIGHT         : L I G H T W E I G H T ;
LIKE                : L I K E ;
LIMIT               : L I M I T ;
LIMITS              : L I M I T S ;
LINEAR              : L I N E A R ;
LIST                : L I S T ;
LISTEN              : L I S T E N ;
LIVE                : L I V E ;
LOAD                : L O A D ;
LOADING             : L O A D I N G ;
LOCAL               : L O C A L ;
LOG                 : L O G ;
LOGS                : L O G S ;
M_KW                : M ;
MARK                : M A R K ;
MASK                : M A S K ;
MASKING             : M A S K I N G ;
MASTER              : M A S T E R ;
MATCH               : M A T C H ;
MATERIALIZE         : M A T E R I A L I Z E ;
MATERIALIZED        : M A T E R I A L I Z E D ;
MAX                 : M A X ;
MCS                 : M C S ;
MEMORY              : M E M O R Y ;
MERGES              : M E R G E S ;
METADATA            : M E T A D A T A ;
METHODS             : M E T H O D S ;
METRICS             : M E T R I C S ;
MI                  : M I ;
MICROSECOND         : M I C R O S E C O N D ;
MICROSECONDS        : M I C R O S E C O N D S ;
MILLENNIUM          : M I L L E N N I U M ;
MILLISECOND         : M I L L I S E C O N D ;
MILLISECONDS        : M I L L I S E C O N D S ;
MIN                 : M I N ;
MINUTE              : M I N U T E ;
MINUTES             : M I N U T E S ;
MM                  : M M ;
MMAP                : M M A P ;
MOD                 : M O D ;
MODEL               : M O D E L ;
MODELS              : M O D E L S ;
MODIFY              : M O D I F Y ;
MONTH               : M O N T H ;
MONTHS              : M O N T H S ;
MOVE                : M O V E ;
MOVES               : M O V E S ;
MS                  : M S ;
MUTATION            : M U T A T I O N ;
N_KW                : N ;
NAME                : N A M E ;
NAMED               : N A M E D ;
NANOSECOND          : N A N O S E C O N D ;
NANOSECONDS         : N A N O S E C O N D S ;
NATIONAL            : N A T I O N A L ;
NATURAL             : N A T U R A L ;
NEW                 : N E W ;
NEXT                : N E X T ;
NO                  : N O ;
NONE                : N O N E ;
NOT                 : N O T ;
NOTIFY              : N O T I F Y ;
NO_AUTHENTICATION   : N O '_' A U T H E N T I C A T I O N ;
NO_PASSWORD         : N O '_' P A S S W O R D ;
NS                  : N S ;
NULL_KW             : N U L L ;
NULLS               : N U L L S ;
OBJECT              : O B J E C T ;
OFFSET              : O F F S E T ;
ON                  : O N ;
ONLY                : O N L Y ;
OPTIMIZE            : O P T I M I Z E ;
OPTION              : O P T I O N ;
OR                  : O R ;
ORDER               : O R D E R ;
OUTER               : O U T E R ;
OUTFILE             : O U T F I L E ;
OVER                : O V E R ;
OVERRIDABLE         : O V E R R I D A B L E ;
OVERRIDE            : O V E R R I D E ;
PAGE                : P A G E ;
PARALLEL            : P A R A L L E L ;
PARQUET             : P A R Q U E T ;
PART                : P A R T ;
PARTIAL             : P A R T I A L ;
PARTITION           : P A R T I T I O N ;
PARTITIONS          : P A R T I T I O N S ;
PARTS               : P A R T S ;
PART_MOVE_TO_SHARD  : P A R T '_' M O V E '_' T O '_' S H A R D ;
PASTE               : P A S T E ;
PATCHES             : P A T C H E S ;
PATH                : P A T H ;
PAUSE               : P A U S E ;
PERIODIC            : P E R I O D I C ;
PERMANENTLY         : P E R M A N E N T L Y ;
PERMISSIVE          : P E R M I S S I V E ;
PERSISTENT          : P E R S I S T E N T ;
PIPELINE            : P I P E L I N E ;
PLACING             : P L A C I N G ;
PLAINTEXT_PASSWORD  : P L A I N T E X T '_' P A S S W O R D ;
PLAN                : P L A N ;
POLICY              : P O L I C Y ;
POPULATE            : P O P U L A T E ;
POSTINGS            : P O S T I N G S ;
PRECEDING           : P R E C E D I N G ;
PRECISION           : P R E C I S I O N ;
PREFIX              : P R E F I X ;
PREPARE             : P R E P A R E ;
PREWARM             : P R E W A R M ;
PREWHERE            : P R E W H E R E ;
PRIMARY             : P R I M A R Y ;
PRIORITY            : P R I O R I T Y ;
PRIVILEGES          : P R I V I L E G E S ;
PROCESSLIST         : P R O C E S S L I S T ;
PROFILE             : P R O F I L E ;
PROFILES            : P R O F I L E S ;
PROJECTION          : P R O J E C T I O N ;
PROTOBUF            : P R O T O B U F ;
PULL                : P U L L ;
PULLING             : P U L L I N G ;
PURGE               : P U R G E ;
Q_KW                : Q ;
QQ                  : Q Q ;
QUALIFY             : Q U A L I F Y ;
QUARTER             : Q U A R T E R ;
QUARTERS            : Q U A R T E R S ;
QUERIES             : Q U E R I E S ;
QUERY               : Q U E R Y ;
QUEUE               : Q U E U E ;
QUEUES              : Q U E U E S ;
QUOTA               : Q U O T A ;
RANDOMIZE           : R A N D O M I Z E ;
RANDOMIZED          : R A N D O M I Z E D ;
RANGE               : R A N G E ;
READ                : R E A D ;
READONLY            : R E A D O N L Y ;
READY               : R E A D Y ;
REALM               : R E A L M ;
RECOMPRESS          : R E C O M P R E S S ;
RECONNECT           : R E C O N N E C T ;
RECURSIVE           : R E C U R S I V E ;
REDUCE              : R E D U C E ;
REFERENCES          : R E F E R E N C E S ;
REFRESH             : R E F R E S H ;
REGEXP              : R E G E X P ;
RELOAD              : R E L O A D ;
REMOVE              : R E M O V E ;
RENAME              : R E N A M E ;
REPLACE             : R E P L A C E ;
REPLICA             : R E P L I C A ;
REPLICAS            : R E P L I C A S ;
REPLICATED          : R E P L I C A T E D ;
REPLICATION         : R E P L I C A T I O N ;
RESET               : R E S E T ;
RESOURCE            : R E S O U R C E ;
RESPECT             : R E S P E C T ;
RESTART             : R E S T A R T ;
RESTORE             : R E S T O R E ;
RESTRICT            : R E S T R I C T ;
RESTRICTIVE         : R E S T R I C T I V E ;
RESUME              : R E S U M E ;
RETURNS             : R E T U R N S ;
REVOKE              : R E V O K E ;
REWRITE             : R E W R I T E ;
RIGHT               : R I G H T ;
ROLE                : R O L E ;
ROLES               : R O L E S ;
ROLLBACK            : R O L L B A C K ;
ROLLUP              : R O L L U P ;
ROW                 : R O W ;
ROWS                : R O W S ;
RUN                 : R U N ;
S_KW                : S ;
S3                  : S '3' ;
SALT                : S A L T ;
SAMPLE              : S A M P L E ;
SAN                 : S A N ;
SCHEMA              : S C H E M A ;
SCHEME              : S C H E M E ;
SCRAM_SHA256_HASH   : S C R A M '_' S H A '2' '5' '6' '_' H A S H ;
SCRAM_SHA256_PASSWORD : S C R A M '_' S H A '2' '5' '6' '_' P A S S W O R D ;
SECOND              : S E C O N D ;
SECONDS             : S E C O N D S ;
SECURITY            : S E C U R I T Y ;
SELECT              : S E L E C T ;
SEMI                : S E M I ;
SENDS               : S E N D S ;
SEQUENTIAL          : S E Q U E N T I A L ;
SERVER              : S E R V E R ;
SET                 : S E T ;
SETS                : S E T S ;
SETTING             : S E T T I N G ;
SETTINGS            : S E T T I N G S ;
SHA256_HASH         : S H A '2' '5' '6' '_' H A S H ;
SHA256_PASSWORD     : S H A '2' '5' '6' '_' P A S S W O R D ;
SHARD               : S H A R D ;
SHOW                : S H O W ;
SHUTDOWN            : S H U T D O W N ;
SIGNED              : S I G N E D ;
SIMILARITY          : S I M I L A R I T Y ;
SIMPLE              : S I M P L E ;
SKIP_KW             : S K I P ;
SNAPSHOT            : S N A P S H O T ;
SOME                : S O M E ;
SOURCE              : S O U R C E ;
SPATIAL             : S P A T I A L ;
SQL                 : S Q L ;
SQL_TSI_DAY         : S Q L '_' T S I '_' D A Y ;
SQL_TSI_HOUR        : S Q L '_' T S I '_' H O U R ;
SQL_TSI_MICROSECOND : S Q L '_' T S I '_' M I C R O S E C O N D ;
SQL_TSI_MILLISECOND : S Q L '_' T S I '_' M I L L I S E C O N D ;
SQL_TSI_MINUTE      : S Q L '_' T S I '_' M I N U T E ;
SQL_TSI_MONTH       : S Q L '_' T S I '_' M O N T H ;
SQL_TSI_NANOSECOND  : S Q L '_' T S I '_' N A N O S E C O N D ;
SQL_TSI_QUARTER     : S Q L '_' T S I '_' Q U A R T E R ;
SQL_TSI_SECOND      : S Q L '_' T S I '_' S E C O N D ;
SQL_TSI_WEEK        : S Q L '_' T S I '_' W E E K ;
SQL_TSI_YEAR        : S Q L '_' T S I '_' Y E A R ;
SS                  : S S ;
SSH_KEY             : S S H '_' K E Y ;
SSL_CERTIFICATE     : S S L '_' C E R T I F I C A T E ;
STALENESS           : S T A L E N E S S ;
START               : S T A R T ;
STATISTICS          : S T A T I S T I C S ;
STDOUT              : S T D O U T ;
STEP                : S T E P ;
STOP                : S T O P ;
STORAGE             : S T O R A G E ;
STRICT              : S T R I C T ;
STRICTLY_ASCENDING  : S T R I C T L Y '_' A S C E N D I N G ;
SUBPARTITION        : S U B P A R T I T I O N ;
SUBPARTITIONS       : S U B P A R T I T I O N S ;
SUSPEND             : S U S P E N D ;
SYNC                : S Y N C ;
SYNTAX              : S Y N T A X ;
SYSTEM              : S Y S T E M ;
TABLE               : T A B L E ;
TABLES              : T A B L E S ;
TAG                 : T A G ;
TAGS                : T A G S ;
TEMPORARY           : T E M P O R A R Y ;
TEST                : T E S T ;
TEXT                : T E X T ;
THAN                : T H A N ;
THEN                : T H E N ;
THREAD              : T H R E A D ;
TIES                : T I E S ;
TIME                : T I M E ;
TIMESTAMP           : T I M E S T A M P ;
TO                  : T O ;
TOKENS              : T O K E N S ;
TOP                 : T O P ;
TOTALS              : T O T A L S ;
TRACING             : T R A C I N G ;
TRACKING            : T R A C K I N G ;
TRAILING            : T R A I L I N G ;
TRANSACTION         : T R A N S A C T I O N ;
TREE                : T R E E ;
TRIGGER             : T R I G G E R ;
TRUE                : T R U E ;
TRUNCATE            : T R U N C A T E ;
TTL                 : T T L ;
TYPE                : T Y P E ;
TYPEOF              : T Y P E O F ;
UNBOUNDED           : U N B O U N D E D ;
UNCOMPRESSED        : U N C O M P R E S S E D ;
UNDROP              : U N D R O P ;
UNFREEZE            : U N F R E E Z E ;
UNION               : U N I O N ;
UNIQUE              : U N I Q U E ;
UNKNOWN             : U N K N O W N ;
UNLOAD              : U N L O A D ;
UNLOCK              : U N L O C K ;
UNREADY             : U N R E A D Y ;
UNSET               : U N S E T ;
UNSIGNED            : U N S I G N E D ;
UNTIL               : U N T I L ;
UPDATE              : U P D A T E ;
URL                 : U R L ;
USE                 : U S E ;
USER                : U S E R ;
USERS               : U S E R S ;
USING               : U S I N G ;
UUID                : U U I D ;
VALID               : V A L I D ;
VALUES              : V A L U E S ;
VARYING             : V A R Y I N G ;
VECTOR              : V E C T O R ;
VIEW                : V I E W ;
VIEWS               : V I E W S ;
VIRTUAL             : V I R T U A L ;
VISIBLE             : V I S I B L E ;
VOLUME              : V O L U M E ;
WAIT                : W A I T ;
WASM                : W A S M ;
WATCH               : W A T C H ;
WATERMARK           : W A T E R M A R K ;
WEEK                : W E E K ;
WEEKS               : W E E K S ;
WHEN                : W H E N ;
WHERE               : W H E R E ;
WINDOW              : W I N D O W ;
WITH                : W I T H ;
WITH_ITEMINDEX      : W I T H '_' I T E M I N D E X ;
WK                  : W K ;
WORKER              : W O R K E R ;
WORKLOAD            : W O R K L O A D ;
WRITABLE            : W R I T A B L E ;
WRITE               : W R I T E ;
WW                  : W W ;
YEAR                : Y E A R ;
YEARS               : Y E A R S ;
YY                  : Y Y ;
YYYY                : Y Y Y Y ;
ZKPATH              : Z K P A T H ;
ZONE                : Z O N E ;
ZOOKEEPER           : Z O O K E E P E R ;

// =============================================================================
// Literals
//
// NUMBER covers integer forms only (decimal, hex, binary) plus optional base-10
// exponent. Fractional floats are assembled as `NUMBER DOT NUMBER` in the
// parser — see header comment above for why.
// Underscore numeric separators are allowed between digits, matching
// Lexer.cpp's isNumberSeparator behavior.
// =============================================================================

NUMBER
    : '0' [xX] HEX_DIGIT ('_'? HEX_DIGIT)*
    | '0' [bB] [01] ('_'? [01])*
    | DIGIT ('_'? DIGIT)* (E_LETTER [+-]? DIGIT ('_'? DIGIT)*)?
    ;

// Single-quoted string with SQL-style doubled-quote escape or backslash escape.
STRING_LITERAL
    : '\'' ( '\\' . | '\'\'' | ~['\\] )* '\''
    | '\u2018' ( ~'\u2019' )* '\u2019'    // Unicode single quotes ‘...’
    ;

// Hex or binary string literals: x'DEADBEEF' or b'1010'. Prefix is case-insensitive.
HEX_STRING_LITERAL  : [xX] '\'' [0-9a-fA-F]* '\'' ;
BIN_STRING_LITERAL  : [bB] '\'' [01]* '\'' ;

// Heredoc: $tag$ ... $tag$. We cannot enforce tag equality in a target-agnostic
// grammar; we accept any $word$ ... $word$ pair. Known limitation.
HEREDOC
    : '$' [A-Za-z0-9_]* '$' .*? '$' [A-Za-z0-9_]* '$'
    ;

// Identifiers.
// Backtick- or double-quoted identifiers carry an internal escape that mirrors
// single-quoted strings (doubled-quote or backslash).
QUOTED_IDENT
    : '`' ( '\\' . | '``' | ~[`\\] )* '`'
    | '"' ( '\\' . | '""' | ~["\\] )* '"'
    | '\u201C' ( ~'\u201D' )* '\u201D'    // Unicode smart double quotes “...”
    ;

// ClickHouse's lexer tolerates identifiers that start with digits
// (Lexer.cpp:242-256: if a parsed number is immediately followed by word
// characters, the whole run is reclassified as BareWord). We accept the
// same via a second alt that requires an alphabetic/underscore after the
// leading digits.
IDENT
    : [A-Za-z_$] [A-Za-z0-9_$]*
    | [0-9]+ [A-Za-z_$] [A-Za-z0-9_$]*
    ;

// =============================================================================
// Fragments
// =============================================================================

fragment DIGIT      : [0-9] ;
fragment HEX_DIGIT  : [0-9a-fA-F] ;
fragment E_LETTER   : [eE] ;

fragment A : [aA] ;  fragment B : [bB] ;  fragment C : [cC] ;  fragment D : [dD] ;
fragment E : [eE] ;  fragment F : [fF] ;  fragment G : [gG] ;  fragment H : [hH] ;
fragment I : [iI] ;  fragment J : [jJ] ;  fragment K : [kK] ;  fragment L : [lL] ;
fragment M : [mM] ;  fragment N : [nN] ;  fragment O : [oO] ;  fragment P : [pP] ;
fragment Q : [qQ] ;  fragment R : [rR] ;  fragment S : [sS] ;  fragment T : [tT] ;
fragment U : [uU] ;  fragment V : [vV] ;  fragment W : [wW] ;  fragment X : [xX] ;
fragment Y : [yY] ;  fragment Z : [zZ] ;
