//! ch-sql-validate — CLI for the ClickHouse SQL parser/validator.
//!
//! Usage:
//!   ch-sql-validate [FILE ...]
//!   ch-sql-validate -        (read from stdin)
//!   ch-sql-validate --help
//!
//! Exit code is 0 iff every input parses cleanly.

use std::io::Read;
use std::path::PathBuf;
use std::process::ExitCode;

use clickhouse_sql_parser::{SyntaxError, validate};

fn main() -> ExitCode {
    let mut args = std::env::args().skip(1).collect::<Vec<_>>();
    let mut quiet = false;
    args.retain(|a| match a.as_str() {
        "-h" | "--help" => {
            print_help();
            std::process::exit(0);
        }
        "-q" | "--quiet" => {
            quiet = true;
            false
        }
        _ => true,
    });

    // No args → stdin. "-" arg → stdin. Otherwise each arg is a file.
    let inputs: Vec<Source> = if args.is_empty() {
        vec![Source::Stdin]
    } else {
        args.into_iter()
            .map(|a| {
                if a == "-" {
                    Source::Stdin
                } else {
                    Source::File(PathBuf::from(a))
                }
            })
            .collect()
    };

    let mut any_errors = false;
    for src in inputs {
        let label = src.label();
        let sql = match src.read() {
            Ok(s) => s,
            Err(e) => {
                eprintln!("{label}: read error: {e}");
                any_errors = true;
                continue;
            }
        };

        match validate(&sql) {
            Ok(()) => {
                if !quiet {
                    println!("{label}: OK");
                }
            }
            Err(errors) => {
                any_errors = true;
                report(&label, &errors, quiet);
            }
        }
    }

    if any_errors {
        ExitCode::from(1)
    } else {
        ExitCode::SUCCESS
    }
}

fn report(label: &str, errors: &[SyntaxError], quiet: bool) {
    if quiet {
        eprintln!("{label}: {} error(s)", errors.len());
        return;
    }
    eprintln!("{label}: {} error(s)", errors.len());
    for e in errors {
        eprintln!("  {label}:{}:{}: [{:?}] {}", e.line, e.column, e.phase, e.message);
    }
}

fn print_help() {
    println!(
        "ch-sql-validate — validate ClickHouse SQL against the ANTLR4 grammar\n\
         \n\
         USAGE:\n\
             ch-sql-validate [FILE ...]\n\
             ch-sql-validate -             # read SQL from stdin\n\
             echo 'SELECT 1' | ch-sql-validate\n\
         \n\
         FLAGS:\n\
             -h, --help     Print this help\n\
             -q, --quiet    Only print summary counts on failure\n\
         \n\
         EXIT CODE:\n\
             0 on success; 1 if any input had syntax errors or could not be read."
    );
}

enum Source {
    Stdin,
    File(PathBuf),
}

impl Source {
    fn label(&self) -> String {
        match self {
            Source::Stdin => "<stdin>".to_string(),
            Source::File(p) => p.display().to_string(),
        }
    }

    fn read(&self) -> std::io::Result<String> {
        match self {
            Source::Stdin => {
                let mut buf = String::new();
                std::io::stdin().read_to_string(&mut buf)?;
                Ok(buf)
            }
            Source::File(p) => std::fs::read_to_string(p),
        }
    }
}
