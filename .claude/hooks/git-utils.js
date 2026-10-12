// Shared helpers for the project's git hooks.
const { execSync } = require("child_process");

function readStdinJson() {
  try {
    return JSON.parse(require("fs").readFileSync(0, "utf8") || "{}");
  } catch {
    return {};
  }
}

// Returns the `git status --porcelain` lines, or null if not a git repo.
function uncommittedChanges(cwd) {
  try {
    const out = execSync("git status --porcelain", { cwd, encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] });
    return out.split("\n").filter(Boolean);
  } catch {
    return null;
  }
}

module.exports = { readStdinJson, uncommittedChanges };
