import org.antlr.v4.runtime.*;

import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Collectors;

/**
 * Single-JVM parallel corpus runner for the ClickHouse ANTLR grammar.
 * Loads the generated lexer + parser once and parses every .sql file in a
 * thread pool; reports per-file pass/fail in file-sorted order.
 *
 * Usage: java -cp <antlr.jar>:build:tests CorpusRunner <corpus-dir> [--verbose] [--threads N]
 */
public class CorpusRunner {
    public static void main(String[] args) throws Exception {
        String corpus = null;
        boolean verbose = false;
        int threads = Math.max(1, Runtime.getRuntime().availableProcessors());
        for (int i = 0; i < args.length; i++) {
            String a = args[i];
            if (a.equals("-v") || a.equals("--verbose")) verbose = true;
            else if (a.equals("--threads") && i + 1 < args.length) threads = Integer.parseInt(args[++i]);
            else corpus = a;
        }
        if (corpus == null) {
            System.err.println("usage: CorpusRunner <corpus-dir> [--verbose] [--threads N]");
            System.exit(2);
        }

        Path root = Paths.get(corpus);
        List<Path> files;
        try (var s = Files.walk(root)) {
            files = s.filter(p -> p.toString().endsWith(".sql"))
                     .sorted()
                     .collect(Collectors.toList());
        }
        if (files.isEmpty()) {
            System.out.println("no .sql files under " + root);
            return;
        }

        AtomicInteger pass = new AtomicInteger();
        AtomicInteger fail = new AtomicInteger();
        // Collect per-file output indexed by position so report order is stable.
        String[] report = new String[files.size()];

        ExecutorService pool = Executors.newFixedThreadPool(threads);
        final boolean vFinal = verbose;
        List<Future<?>> futures = new ArrayList<>(files.size());
        for (int i = 0; i < files.size(); i++) {
            final int idx = i;
            Path f = files.get(i);
            futures.add(pool.submit(() -> {
                String rel = root.relativize(f).toString();
                ErrorCollector errs = parseFile(f);
                if (errs.isEmpty()) {
                    pass.incrementAndGet();
                    if (vFinal) report[idx] = "  OK   " + rel;
                } else {
                    fail.incrementAndGet();
                    StringBuilder sb = new StringBuilder("  FAIL ").append(rel);
                    for (String m : errs.messages) sb.append("\n       ").append(m);
                    report[idx] = sb.toString();
                }
            }));
        }
        for (Future<?> fut : futures) fut.get();
        pool.shutdown();

        for (String line : report) {
            if (line != null) System.out.println(line);
        }
        System.out.println();
        System.out.printf("passed: %d    failed: %d    total: %d%n",
                pass.get(), fail.get(), pass.get() + fail.get());
        if (fail.get() != 0) System.exit(1);
    }

    private static ErrorCollector parseFile(Path f) {
        ErrorCollector errs = new ErrorCollector();
        try {
            // Read as raw bytes and decode leniently (a few fuzzer-derived
            // test fixtures in ClickHouse are deliberately non-UTF-8).
            String src = new String(Files.readAllBytes(f), StandardCharsets.UTF_8);
            // ClickHouse's test corpus annotates statements that *should* fail
            // to parse with `-- { clientError SYNTAX_ERROR }` trailing comments.
            // Strip those statements so the file as a whole can be parsed.
            src = stripClientErrorStatements(src);
            CharStream input = CharStreams.fromString(src);
            ClickHouseLexer lexer = new ClickHouseLexer(input);
            lexer.removeErrorListeners();
            lexer.addErrorListener(errs);
            CommonTokenStream tokens = new CommonTokenStream(lexer);
            ClickHouseParser parser = new ClickHouseParser(tokens);
            parser.removeErrorListeners();
            parser.addErrorListener(errs);
            parser.query();
        } catch (Exception e) {
            errs.add("runtime: " + e.getMessage());
        }
        return errs;
    }

    /**
     * Remove statements marked `-- { clientError SYNTAX_ERROR }`.
     * Walks the source once, tracking string/comment/heredoc boundaries to find
     * the top-level `;` that ends each statement, then deletes any statement
     * whose source range contains the marker.
     */
    static String stripClientErrorStatements(String src) {
        if (!src.contains("clientError SYNTAX_ERROR")) return src;
        int n = src.length();
        StringBuilder out = new StringBuilder(n);
        int stmtStart = 0;
        int i = 0;
        while (i < n) {
            char c = src.charAt(i);
            // single-line comment
            if (c == '-' && i + 1 < n && src.charAt(i + 1) == '-') {
                int j = src.indexOf('\n', i);
                i = (j < 0) ? n : j;
                continue;
            }
            if (c == '#' && (i == 0 || src.charAt(i - 1) == '\n')) {
                int j = src.indexOf('\n', i);
                i = (j < 0) ? n : j;
                continue;
            }
            // block comment
            if (c == '/' && i + 1 < n && src.charAt(i + 1) == '*') {
                int j = src.indexOf("*/", i + 2);
                i = (j < 0) ? n : j + 2;
                continue;
            }
            // single-quoted string
            if (c == '\'') {
                i++;
                while (i < n) {
                    char d = src.charAt(i);
                    if (d == '\\' && i + 1 < n) { i += 2; continue; }
                    if (d == '\'' && i + 1 < n && src.charAt(i + 1) == '\'') { i += 2; continue; }
                    if (d == '\'') { i++; break; }
                    i++;
                }
                continue;
            }
            // quoted identifier: backtick or double-quote
            if (c == '`' || c == '"') {
                char quote = c;
                i++;
                while (i < n) {
                    char d = src.charAt(i);
                    if (d == '\\' && i + 1 < n) { i += 2; continue; }
                    if (d == quote && i + 1 < n && src.charAt(i + 1) == quote) { i += 2; continue; }
                    if (d == quote) { i++; break; }
                    i++;
                }
                continue;
            }
            // heredoc $tag$ ... $tag$
            if (c == '$') {
                int tagEnd = i + 1;
                while (tagEnd < n) {
                    char d = src.charAt(tagEnd);
                    if (d == '$') break;
                    if (!(Character.isLetterOrDigit(d) || d == '_')) { tagEnd = -1; break; }
                    tagEnd++;
                }
                if (tagEnd > 0 && tagEnd < n && src.charAt(tagEnd) == '$') {
                    String tag = src.substring(i, tagEnd + 1);
                    int close = src.indexOf(tag, tagEnd + 1);
                    i = (close < 0) ? n : close + tag.length();
                    continue;
                }
            }
            if (c == ';') {
                // Include any trailing same-line comment so a marker like
                // `SELECT ...;  -- { clientError SYNTAX_ERROR }` is associated
                // with the preceding statement.
                int end = i + 1;
                int scan = end;
                while (scan < n) {
                    char d = src.charAt(scan);
                    if (d == ' ' || d == '\t') { scan++; continue; }
                    if (d == '-' && scan + 1 < n && src.charAt(scan + 1) == '-') {
                        int nl = src.indexOf('\n', scan);
                        end = (nl < 0) ? n : nl;
                        break;
                    }
                    break;
                }
                String stmt = src.substring(stmtStart, end);
                if (!stmt.contains("clientError SYNTAX_ERROR")) {
                    out.append(src, stmtStart, i + 1);
                } else {
                    for (int k = stmtStart; k < end; k++) {
                        char ch = src.charAt(k);
                        out.append(ch == '\n' ? '\n' : ' ');
                    }
                    i = end - 1;
                }
                stmtStart = i + 1;
            }
            i++;
        }
        // Trailing region after last `;` — keep as-is unless it's marked.
        String tail = src.substring(stmtStart);
        if (!tail.contains("clientError SYNTAX_ERROR")) out.append(tail);
        return out.toString();
    }

    static class ErrorCollector extends BaseErrorListener {
        final List<String> messages = Collections.synchronizedList(new ArrayList<>());
        void clear() { messages.clear(); }
        void add(String m) { messages.add(m); }
        boolean isEmpty() { return messages.isEmpty(); }
        @Override public void syntaxError(Recognizer<?, ?> r, Object sym, int line, int col,
                                          String msg, RecognitionException e) {
            messages.add("line " + line + ":" + col + " " + msg);
        }
    }
}
