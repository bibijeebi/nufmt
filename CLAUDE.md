# nuwrap - Intelligent Line Wrapper for Nushell

**Bottom line**: AST-aware Nushell formatter that adds intelligent line wrapping before delegating to topiary for indentation/spacing. Solves the "nufmt is broken, topiary doesn't wrap" problem.

## Problem Statement

**nufmt**: Pre-alpha, deletes comments, breaks functionality, formats to single lines
**topiary-nushell**: Stable, but only handles indentation/whitespace, no line-width control by design
**Need**: Intelligent line wrapping that respects Nushell syntax and preserves author intent

## Technical Approach

**Pipeline**: `source → AST analysis → strategic line breaks → topiary format -l nu → output`

### Why This Works

Topiary's design: "if code spans multiple lines, that decision is preserved"
- We insert breaks at syntax boundaries
- Topiary handles indentation and spacing
- Result: properly formatted, width-controlled code

### Architecture
```
┌─────────────┐
│ Nu Source   │
└──────┬──────┘
       │
       ▼
┌─────────────┐    ┌──────────────┐
│ ast --json  │───▶│ Span Mapping │
└─────────────┘    └──────┬───────┘
                          │
                          ▼
                   ┌──────────────┐
                   │ Break Insert │
                   │ • Pipelines  │
                   │ • Let stmts  │
                   │ • Call args  │
                   └──────┬───────┘
                          │
                          ▼
                   ┌──────────────┐
                   │ topiary -l nu│
                   └──────┬───────┘
                          │
                          ▼
                   ┌──────────────┐
                   │ Formatted Nu │
                   └──────────────┘
```

## Key Constraints

### Nushell Syntax Rules
- No backslash line continuations
- Pipeline `|` is primary break point
- `let var = value` (no parens needed)
- Prefer `http` commands over `curl`
- Closures: `{|param| body }`

### Topiary Limitations
- No max-line-width config (by design)
- Only configurable via `.ncl` files: indent, extensions, grammar
- Format behavior controlled by query files (nu.scm)
- Preserves multi-line author decisions

### Wrapping Priorities (by construct)
1. **Pipelines**: Break at ` | ` operators (most common, safest)
2. **Let assignments**: Break after `=` if RHS is complex expression
3. **Function calls**: Break at commas in argument lists
4. **List literals**: Break at commas (preserve `[...]` on one line if short)
5. **Record literals**: Break at commas in `{key: value, ...}`
6. **Binary expressions**: Break at lowest-precedence operators

## AST Command Output
```nu
# Basic usage
$code | ast --json | from json

# Key AST node types for wrapping
- PipelineElement: Each stage in a pipeline
- Call: Function/command invocations with spans
- Expression: All expressions with type and span
- Block: Code blocks (closures, etc)
- Assignment: Let/mut statements
```

**AST span format**: `{start: int, end: int}` - byte offsets into source

## Implementation Strategy

### Phase 1: Heuristic (Simple, Fast)
Regex-based wrapping without AST parsing:
- Detect `|` outside strings
- Break long pipelines
- Handle common patterns

### Phase 2: AST-Aware (Accurate, Robust)
Parse AST to:
- Map spans to source positions
- Identify wrappable constructs by type
- Calculate actual rendered widths
- Validate breaks don't violate syntax

### Phase 3: Style Options
- `--compact`: Minimal breaks (120 chars)
- `--readable`: More breaks (80 chars)
- `--one-liner`: Collapse to single line where valid

## Current Topiary Integration
```nu
# Stdin formatting
cat script.nu | topiary format -l nu

# File formatting (in-place)
topiary format script.nu

# With custom query rules
topiary format -l nu -q custom.scm < script.nu

# Tolerate parsing errors (useful during preprocessing)
topiary format -l nu -t
```

**Environment setup for topiary-nushell**:
```nu
# Clone blindFS/topiary-nushell
git clone https://github.com/blindFS/topiary-nushell ~/.config/topiary

$env.TOPIARY_CONFIG_FILE = (~/.config/topiary/languages.ncl)
$env.TOPIARY_LANGUAGE_DIR = (~/.config/topiary/languages)
```

## Edge Cases & Gotchas

**String detection**: Must not break inside strings
- Single-quoted strings: `'...'`
- Double-quoted strings: `"..."`
- Raw strings: `r#'...'#`
- String interpolation: `$"...($expr)..."`

**Comment preservation**: Topiary handles this, but preprocessor must not mangle
- Line comments: `# ...`
- Preserve alignment with code

**Operator precedence**: Don't break in ways that change semantics
- Pipeline `|` binds loosely (safe to break)
- Math operators bind tightly (careful with breaks)

**Closure syntax**: `{|param| body }` - don't break param list

## Testing Strategy
```nu
# Idempotence check (topiary built-in)
nuwrap script.nu | nuwrap  # Should be identical

# Validation
nuwrap script.nu | nu -c 'complete'  # Parse check

# Round-trip
nuwrap script.nu | save formatted.nu
nu formatted.nu  # Should execute identically
```

## Performance Notes

**AST parsing cost**: `ast --json` adds ~10-50ms per file
- Acceptable for editor integration
- Batch mode: process multiple files in parallel

**Topiary cost**: ~5-20ms per file
- Fast enough for format-on-save

**Total latency budget**: <100ms for good UX

## Future Enhancements

1. **Smart break alignment**: Align pipeline stages visually
2. **Comment-aware wrapping**: Preserve inline comment positions
3. **Table literal formatting**: Multi-line table syntax
4. **LSP integration**: Real-time format-on-type
5. **Config file**: `.nuwrap.toml` for per-project settings

## Pro Tips

- Start with pipeline wrapping only (80% of value)
- Use `topiary format -l nu -t` during development (tolerates temp errors)
- Test on nushell stdlib scripts for real-world validation
- Don't wrap short pipelines just because they *can* wrap
- Preserve blank lines between logical sections (topiary's `@allow_blank_line_before`)

## Dependencies

- Nushell ≥0.90 (for stable `ast --json`)
- topiary-cli ≥0.6.0
- topiary-nushell (blindFS fork)

## Non-Goals

- Don't replicate full topiary query system
- Don't implement Nushell parser from scratch
- Don't support ancient Nu versions (<0.80)
- Don't make it configurable beyond width (opinionated is fine)

## Reality Check

**Best case**: 90% of code formats beautifully, 10% needs manual tweaking
**No perfect solution**: Some constructs will always look better hand-formatted
**Pragmatic goal**: "Good enough" uniform style, not perfection
</markdown>