// PreToolUse (Bash/PowerShell): block `git checkout` / `git switch` while there are uncommitted changes.
const { readStdinJson, uncommittedChanges } = require("./git-utils");

const input = readStdinJson();
const command = (input.tool_input && input.tool_input.command) || "";

// Only a git command at the start of the line or after a separator (&&, ;, |, newline), not text inside a string.
const CHECKOUT = /(^|[;&|\n(]\s*)git(\s+-C\s+\S+)?\s+(checkout|switch)\b/;

if (CHECKOUT.test(command)) {
  const changes = uncommittedChanges(input.cwd || process.cwd());
  if (changes && changes.length > 0) {
    const preview = changes.slice(0, 10).join("\n");
    process.stdout.write(JSON.stringify({
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason:
          `Blocked by project rule G1: ${changes.length} uncommitted change(s). ` +
          `Stop and ask the user to run /git-checkin first. Changes:\n${preview}`,
      },
    }));
  }
}
