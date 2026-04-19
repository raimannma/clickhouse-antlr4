//! ClickHouse SQL parser / syntactic validator.
//!
//! The ANTLR4 grammar in the parent directory is compiled to Rust at
//! build-time (see `build.rs`). This module wraps the generated parser
//! behind an ergonomic `validate()` API.

#![allow(clippy::result_large_err)]

use std::sync::{Arc, Mutex};

use antlr_rust::{InputStream, Parser};
use antlr_rust::common_token_stream::CommonTokenStream;
use antlr_rust::error_listener::ErrorListener;
use antlr_rust::errors::ANTLRError;
use antlr_rust::recognizer::Recognizer;
use antlr_rust::token_factory::TokenFactory;

mod generated;

use generated::clickhouselexer::ClickHouseLexer;
use generated::clickhouseparser::ClickHouseParser;

/// A single lex/parse diagnostic, as produced by the ANTLR runtime.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SyntaxError {
    /// Source of the error — lexer or parser.
    pub phase: Phase,
    /// 1-based line number.
    pub line: usize,
    /// 0-based column.
    pub column: usize,
    /// Human-readable message from the ANTLR error strategy.
    pub message: String,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Phase {
    Lex,
    Parse,
}

impl std::fmt::Display for SyntaxError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let tag = match self.phase {
            Phase::Lex => "lex",
            Phase::Parse => "parse",
        };
        write!(
            f,
            "{}:{}:{}: {} error: {}",
            tag, self.line, self.column, tag, self.message
        )
    }
}

impl std::error::Error for SyntaxError {}

/// Parse a single ClickHouse SQL string (one or more statements, separated
/// by `;`) and return all accumulated syntax errors.
///
/// Returns `Ok(())` iff the input is accepted by the `query` rule with no
/// diagnostics. The tree itself is dropped; use [`parse`] if you need it.
pub fn validate(sql: &str) -> Result<(), Vec<SyntaxError>> {
    let errors = run_parser(sql);
    if errors.is_empty() { Ok(()) } else { Err(errors) }
}

/// Lower-level entry point: drive the parser and always return the
/// diagnostic list (possibly empty).
pub fn parse(sql: &str) -> Vec<SyntaxError> {
    run_parser(sql)
}

fn run_parser(sql: &str) -> Vec<SyntaxError> {
    let lex_errors: Arc<Mutex<Vec<SyntaxError>>> = Arc::new(Mutex::new(Vec::new()));
    let parse_errors: Arc<Mutex<Vec<SyntaxError>>> = Arc::new(Mutex::new(Vec::new()));

    let input = InputStream::new(sql);
    let mut lexer = ClickHouseLexer::new(input);
    lexer.remove_error_listeners();
    lexer.add_error_listener(Box::new(CollectingListener {
        phase: Phase::Lex,
        sink: Arc::clone(&lex_errors),
    }));

    let token_stream = CommonTokenStream::new(lexer);
    let mut parser = ClickHouseParser::new(token_stream);
    parser.remove_error_listeners();
    parser.add_error_listener(Box::new(CollectingListener {
        phase: Phase::Parse,
        sink: Arc::clone(&parse_errors),
    }));

    // The grammar's top-level rule is `query`.
    let _ = parser.query();

    let mut all = std::mem::take(&mut *lex_errors.lock().unwrap());
    all.extend(std::mem::take(&mut *parse_errors.lock().unwrap()));
    all
}

struct CollectingListener {
    phase: Phase,
    sink: Arc<Mutex<Vec<SyntaxError>>>,
}

impl<'a, T> ErrorListener<'a, T> for CollectingListener
where
    T: Recognizer<'a>,
{
    fn syntax_error(
        &self,
        _recognizer: &T,
        _offending_symbol: Option<&<T::TF as TokenFactory<'a>>::Inner>,
        line: isize,
        column: isize,
        msg: &str,
        _error: Option<&ANTLRError>,
    ) {
        let line = if line < 0 { 0 } else { line as usize };
        let column = if column < 0 { 0 } else { column as usize };
        self.sink.lock().unwrap().push(SyntaxError {
            phase: self.phase,
            line,
            column,
            message: msg.to_string(),
        });
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn accepts_trivial_select() {
        assert!(validate("SELECT 1").is_ok());
    }

    #[test]
    fn accepts_trailing_semicolon() {
        assert!(validate("SELECT 1;").is_ok());
    }

    #[test]
    fn accepts_multi_statement() {
        assert!(validate("SELECT 1; SELECT 2;").is_ok());
    }

    #[test]
    fn accepts_cte_with_union() {
        let sql = "WITH x AS (SELECT 1 AS a) SELECT a FROM x UNION ALL SELECT 2";
        assert!(validate(sql).is_ok(), "{:?}", validate(sql));
    }

    #[test]
    fn accepts_create_table() {
        let sql = "CREATE TABLE t (a UInt64, b String) ENGINE = MergeTree() ORDER BY a";
        assert!(validate(sql).is_ok(), "{:?}", validate(sql));
    }

    #[test]
    fn rejects_gibberish() {
        let errs = validate("this is not sql at all").unwrap_err();
        assert!(!errs.is_empty());
    }

    #[test]
    fn rejects_unterminated_string() {
        let errs = validate("SELECT 'oops").unwrap_err();
        assert!(!errs.is_empty());
    }
}
