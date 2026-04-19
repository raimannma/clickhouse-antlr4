//! build.rs — auto-generate a Rust parser/validator from the ClickHouse
//! ANTLR4 grammar files in the parent directory.
//!
//! Strategy:
//!   1. Resolve the antlr4rust-capable ANTLR jar (env ANTLR_JAR, or cache dir).
//!   2. Download the jar on first run if absent.
//!   3. Invoke `java -jar <jar> -Dlanguage=Rust -o src/generated ...` whenever
//!      the grammar files are newer than the generated sources.
//!   4. Maintain a `src/generated/mod.rs` that exposes the ANTLR-produced
//!      modules to `lib.rs`.
//!
//! The grammar files live one level up so this crate can be dropped anywhere
//! under the repo root without polluting it.

use std::fs;
use std::io::{self, Write};
use std::path::{Path, PathBuf};
use std::process::Command;
use std::time::SystemTime;

const ANTLR_JAR_URL: &str = "https://github.com/rrevenantt/antlr4rust/releases/download/antlr4-4.8-2-Rust0.3.0-beta/antlr4-4.8-2-SNAPSHOT-complete.jar";
const ANTLR_JAR_NAME: &str = "antlr4-4.8-2-SNAPSHOT-complete.jar";

const GRAMMAR_FILES: &[&str] = &["ClickHouseLexer.g4", "ClickHouseParser.g4"];

// Files ANTLR generates with `-Dlanguage=Rust` for this grammar.
// Names come from the grammar filenames, lowercased.
const GENERATED_FILES: &[&str] = &[
    "clickhouselexer.rs",
    "clickhouseparser.rs",
    "clickhouseparserlistener.rs",
    "clickhouseparservisitor.rs",
];

fn main() {
    // Tell cargo to re-run only when inputs change.
    for g in GRAMMAR_FILES {
        println!("cargo:rerun-if-changed=../{g}");
    }
    println!("cargo:rerun-if-changed=build.rs");
    println!("cargo:rerun-if-env-changed=ANTLR_JAR");
    println!("cargo:rerun-if-env-changed=CLICKHOUSE_ANTLR_OFFLINE");

    let manifest_dir = PathBuf::from(env_or_panic("CARGO_MANIFEST_DIR"));
    let repo_root = manifest_dir
        .parent()
        .expect("crate must live in a subdirectory of the grammar repo")
        .to_path_buf();
    let out_dir = manifest_dir.join("src").join("generated");
    fs::create_dir_all(&out_dir).expect("create src/generated");

    // Verify grammar files exist before doing anything else.
    for g in GRAMMAR_FILES {
        let p = repo_root.join(g);
        if !p.exists() {
            panic!(
                "grammar file {} not found (looked in {}). \
                 This crate expects the ClickHouse{{Lexer,Parser}}.g4 files \
                 one directory up from Cargo.toml.",
                g,
                repo_root.display()
            );
        }
    }

    if up_to_date(&repo_root, &out_dir) {
        ensure_mod_rs(&out_dir);
        return;
    }

    let jar = resolve_jar();
    generate(&jar, &repo_root, &out_dir);
    ensure_mod_rs(&out_dir);
}

fn env_or_panic(k: &str) -> String {
    std::env::var(k).unwrap_or_else(|_| panic!("{k} not set"))
}

fn up_to_date(repo_root: &Path, out_dir: &Path) -> bool {
    let newest_grammar = GRAMMAR_FILES
        .iter()
        .map(|g| mtime(&repo_root.join(g)))
        .max()
        .unwrap_or(SystemTime::UNIX_EPOCH);

    for f in GENERATED_FILES {
        let p = out_dir.join(f);
        if !p.exists() || mtime(&p) < newest_grammar {
            return false;
        }
    }
    true
}

fn mtime(p: &Path) -> SystemTime {
    fs::metadata(p)
        .and_then(|m| m.modified())
        .unwrap_or(SystemTime::UNIX_EPOCH)
}

fn resolve_jar() -> PathBuf {
    if let Ok(p) = std::env::var("ANTLR_JAR") {
        let p = PathBuf::from(p);
        if p.exists() {
            return p;
        }
        panic!("ANTLR_JAR={} does not exist", p.display());
    }

    let cache_dir = cache_dir().join("antlr4rust");
    let jar = cache_dir.join(ANTLR_JAR_NAME);
    if jar.exists() {
        return jar;
    }

    if std::env::var_os("CLICKHOUSE_ANTLR_OFFLINE").is_some() {
        panic!(
            "{} not present and CLICKHOUSE_ANTLR_OFFLINE is set; \
             download it manually and place it at that path or set ANTLR_JAR.",
            jar.display()
        );
    }

    fs::create_dir_all(&cache_dir).expect("create antlr cache dir");
    download(ANTLR_JAR_URL, &jar).unwrap_or_else(|e| {
        panic!(
            "failed to download ANTLR jar from {ANTLR_JAR_URL}: {e}. \
             You can download it manually and point ANTLR_JAR at it."
        )
    });
    jar
}

fn cache_dir() -> PathBuf {
    if let Ok(d) = std::env::var("XDG_CACHE_HOME") {
        return PathBuf::from(d);
    }
    if let Ok(h) = std::env::var("HOME") {
        return PathBuf::from(h).join(".cache");
    }
    std::env::temp_dir()
}

fn download(url: &str, dest: &Path) -> io::Result<()> {
    // Prefer curl; fall back to wget. No network crate dependency.
    let tmp = dest.with_extension("part");
    let status = Command::new("curl")
        .args(["-fsSL", "--retry", "3", "-o"])
        .arg(&tmp)
        .arg(url)
        .status();
    match status {
        Ok(s) if s.success() => {
            fs::rename(&tmp, dest)?;
            return Ok(());
        }
        _ => {
            let _ = fs::remove_file(&tmp);
        }
    }

    let status = Command::new("wget")
        .args(["-q", "-O"])
        .arg(&tmp)
        .arg(url)
        .status()
        .map_err(|e| io::Error::new(io::ErrorKind::Other, format!("wget launch failed: {e}")))?;
    if !status.success() {
        let _ = fs::remove_file(&tmp);
        return Err(io::Error::new(
            io::ErrorKind::Other,
            "both curl and wget failed to download the jar",
        ));
    }
    fs::rename(&tmp, dest)?;
    Ok(())
}

fn generate(jar: &Path, repo_root: &Path, out_dir: &Path) {
    // Wipe stale generated files so a failed codegen does not leave a
    // half-matching mix on disk.
    if out_dir.exists() {
        for entry in fs::read_dir(out_dir).unwrap() {
            let entry = entry.unwrap();
            let name = entry.file_name();
            let name = name.to_string_lossy();
            // Keep mod.rs (we recreate it anyway); remove everything else.
            if name == "mod.rs" {
                continue;
            }
            let _ = fs::remove_file(entry.path());
        }
    }

    println!(
        "cargo:warning=generating ClickHouse Rust parser from {}",
        repo_root.display()
    );

    let mut cmd = Command::new("java");
    cmd.arg("-jar")
        .arg(jar)
        .arg("-Dlanguage=Rust")
        .arg("-o")
        .arg(out_dir)
        .arg("-Xexact-output-dir") // put all files directly in out_dir
        .arg("-no-visitor");

    for g in GRAMMAR_FILES {
        cmd.arg(repo_root.join(g));
    }

    let output = cmd
        .output()
        .expect("failed to execute java (is a JRE on PATH?)");
    if !output.status.success() {
        panic!(
            "ANTLR codegen failed ({}).\nstdout:\n{}\nstderr:\n{}",
            output.status,
            String::from_utf8_lossy(&output.stdout),
            String::from_utf8_lossy(&output.stderr),
        );
    }

    // Sanity: check the files we promised actually appeared.
    for f in GENERATED_FILES {
        let p = out_dir.join(f);
        if !p.exists() {
            // Listener/visitor were disabled — those are allowed to be missing.
            if f.contains("listener") || f.contains("visitor") {
                continue;
            }
            panic!("ANTLR did not produce expected file {}", p.display());
        }
    }

    patch_generated(out_dir);
}

/// Work around a known antlr4rust codegen quirk: when the parser grammar
/// file is named `FooParser.g4`, some labeled-alternative impl blocks are
/// emitted with the trait name `FooParserParserContext` (double "Parser")
/// while the trait itself is defined as `FooParserContext`. Rewrite the
/// spurious doubled token in the generated sources.
fn patch_generated(out_dir: &Path) {
    const TARGETS: &[(&str, &str)] = &[
        ("ClickHouseParserParserContext", "ClickHouseParserContext"),
    ];
    for f in GENERATED_FILES {
        let p = out_dir.join(f);
        if !p.exists() {
            continue;
        }
        let Ok(src) = fs::read_to_string(&p) else { continue };
        let mut patched = src.clone();
        for (from, to) in TARGETS {
            if patched.contains(from) {
                patched = patched.replace(from, to);
            }
        }
        if patched != src {
            fs::write(&p, patched).unwrap_or_else(|e| {
                panic!("failed to patch {}: {e}", p.display())
            });
        }
    }
}

fn ensure_mod_rs(out_dir: &Path) {
    // Expose whichever of the expected modules actually exist.
    let mut mod_src = String::from(
        "// Auto-generated by build.rs. Do not edit.\n\
         #![allow(clippy::all)]\n\
         #![allow(warnings)]\n\
         #![allow(non_snake_case, non_camel_case_types, unused, dead_code)]\n\n",
    );
    for f in GENERATED_FILES {
        let p = out_dir.join(f);
        if p.exists() {
            let module = f.trim_end_matches(".rs");
            mod_src.push_str(&format!("pub mod {module};\n"));
        }
    }
    let mod_path = out_dir.join("mod.rs");
    // Only rewrite if changed, to keep cargo happy.
    let old = fs::read_to_string(&mod_path).unwrap_or_default();
    if old != mod_src {
        let mut f = fs::File::create(&mod_path).expect("write mod.rs");
        f.write_all(mod_src.as_bytes()).expect("write mod.rs");
    }
}
