// Workaround for anomalyco/opencode#49852: "pkg/subpath" plugin specs are
// parsed as GitHub repos, so "opencode-pty/v2" cannot be installed via config.
// This re-exports the package's V2 entrypoint instead.
export { Plugin as default } from "opencode-pty/v2"
