// SessionStart: warn if the working tree has uncommitted changes (e.g. a previous session ended without /git-checkin).
const { readStdinJson, uncommittedChanges } = require("./git-utils");

const input = readStdinJson();
const changes = uncommittedChanges(input.cwd || process.cwd());

if (changes && changes.length > 0) {
  const message = `There are ${changes.length} uncommitted change(s) from a previous session. Run /git-checkin before starting new work or switching branches.`;
  process.stdout.write(JSON.stringify({
    systemMessage: message,
    hookSpecificOutput: { hookEventName: "SessionStart", additionalContext: message },
  }));
}
