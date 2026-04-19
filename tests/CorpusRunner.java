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
