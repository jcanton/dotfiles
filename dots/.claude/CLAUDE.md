# Attribution

Anything written on jcanton's behalf that another human will read — GitHub comments, PR
descriptions, issue bodies, commit messages — ends with this footer as its last line:

```
🤖 Written by an agent on behalf of @jcanton
```

A footer, never a prefix. The reader should see the content first and the provenance last.

On commits it **replaces** the default `Co-Authored-By:` / `Claude-Session:` trailers rather than
sitting alongside them. On GitHub text it replaces the "🤖 Generated with Claude Code" footer.

**Exception:** comments whose text is parsed by a machine must stay bare. CSCS CI trigger comments
must begin with `cscs-ci run`, so they carry neither prefix nor footer.

# Writing

Write code comments, docstrings, commit messages, PR descriptions and review comments following
the `house-style` skill.

# Verification

In icon4py, run the `icon4py-verify` skill right before committing (not for docs-only or
tests-only commits).
