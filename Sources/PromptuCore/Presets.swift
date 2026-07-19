import Foundation

/// The block-list pages beside blocks.json: every *.json in the config
/// directory is a page in the same schema, so each one also loads in
/// Emacs promptu. blocks.json is the first page; the rest follow
/// alphabetically.
public enum Presets {
    public static let configDirectory = BlocksConfig.defaultURL.deletingLastPathComponent()

    /// The page files: blocks.json first (whether or not it exists yet
    /// — the caller seeds it), then every other .json alphabetically.
    public static func pageURLs(in directory: URL = configDirectory) -> [URL] {
        let others =
            ((try? FileManager.default.contentsOfDirectory(
                at: directory, includingPropertiesForKeys: nil)) ?? [])
            .filter { $0.pathExtension == "json" && $0.lastPathComponent != "blocks.json" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        return [directory.appendingPathComponent("blocks.json")] + others
    }

    /// Write the bundled preset pages that don't exist yet; existing
    /// files are never touched. The caller decides when (the app seeds
    /// only once, so a deleted page stays deleted).
    public static func seed(into directory: URL = configDirectory) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for (fileName, blocksJSON) in defaults {
            let url = directory.appendingPathComponent(fileName)
            if !FileManager.default.fileExists(atPath: url.path) {
                try Data((blocksJSON + "\n").utf8).write(to: url, options: .atomic)
            }
        }
    }

    /// The bundled preset pages, adapted from the Claude Code prompt
    /// library <https://code.claude.com/docs/en/prompt-library>, in the
    /// same house style as `BlocksConfig.defaultBlocksJSON`.
    public static let defaults: [(fileName: String, blocksJSON: String)] = [
        (
            "understand.json",
            """
            [
              { "key": "o", "desc": "overview", "text": "give me an overview of this codebase: architecture, key directories, and how the pieces connect" },
              { "key": "e", "desc": "explain", "text": "explain what {path} does and how data flows through it", "placeholders": ["path"] },
              { "key": "w", "desc": "where do we", "text": "where do we {behavior}?", "placeholders": ["behavior"] },
              { "key": "d", "desc": "what breaks deleting", "text": "what would break if I deleted {target}?", "placeholders": ["target"] },
              { "key": "h", "desc": "history of", "text": "look through the commit history of {path} and summarize how it evolved and why", "placeholders": ["path"] },
              { "key": "s", "desc": "files to touch", "text": "which files would I need to touch to {change}?", "placeholders": ["change"] }
            ]
            """
        ),
        (
            "build.json",
            """
            [
              { "key": "p", "desc": "plan refactor", "text": "plan how to refactor {target} to {goal}. list the files you would change, but don't edit anything yet", "placeholders": ["target", "goal"] },
              { "key": "f", "desc": "follow pattern", "text": "look at how {example} is implemented to understand the pattern, then build {new} the same way", "placeholders": ["example", "new"] },
              { "key": "a", "desc": "add endpoint", "text": "add a {endpoint} endpoint that returns {payload}", "placeholders": ["endpoint", "payload"] },
              { "key": "i", "desc": "work issue", "text": "read issue #{issue}, implement the fix, and run the tests", "placeholders": ["issue"] },
              { "key": "t", "desc": "write tests", "text": "write tests for {path}, run them, and fix any failures", "placeholders": ["path"] },
              { "key": "T", "desc": "tests first", "text": "write tests for {feature} first, then implement it until they pass", "placeholders": ["feature"] },
              { "key": "m", "desc": "migrate", "text": "migrate everything from {from} to {to}: identify every place that needs to change, then make the changes", "placeholders": ["from", "to"] }
            ]
            """
        ),
        (
            "ship.json",
            """
            [
              { "key": "r", "desc": "review changes", "text": "review my uncommitted changes and flag anything that looks risky before I commit" },
              { "key": "p", "desc": "review PR", "text": "review PR #{pr} and summarize what changed, then list any concerns", "placeholders": ["pr"] },
              { "key": "s", "desc": "security review", "text": "use a subagent to review {path} for security issues and report what it finds", "placeholders": ["path"] },
              { "key": "m", "desc": "merge conflicts", "text": "resolve the merge conflicts in this branch and explain what you kept from each side" },
              { "key": "c", "desc": "commit", "text": "commit these changes with a message that summarizes what I did" },
              { "key": "n", "desc": "release notes", "text": "compare {from} to {to} and draft release notes grouped by feature, fix, and breaking change", "placeholders": ["from", "to"] }
            ]
            """
        ),
        (
            "fix.json",
            """
            [
              { "key": "t", "desc": "failing test", "text": "the {test} test is failing, find out why and fix it", "placeholders": ["test"] },
              { "key": "e", "desc": "users see", "text": "users are seeing {symptom} on {where}. investigate and tell me what is going on", "placeholders": ["symptom", "where"] },
              { "key": "b", "desc": "build error", "text": "the build is failing. find the root cause, fix it, and verify the build succeeds" },
              { "key": "i", "desc": "incident", "text": "{symptom}. check the logs, recent deploys, and config changes, then tell me the most likely cause", "placeholders": ["symptom"] },
              { "key": "w", "desc": "not right:", "text": "that is not right: {feedback}. try a different approach", "placeholders": ["feedback"] },
              { "key": "s", "desc": "keep only", "text": "that is too much. keep only the changes to {scope} and undo your other edits", "placeholders": ["scope"] },
              { "key": "r", "desc": "make a rule", "text": "you keep {mistake}. add a rule to CLAUDE.md so this stops happening", "placeholders": ["mistake"] }
            ]
            """
        ),
    ]
}
