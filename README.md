# nufmt - Nushell Code Formatter

AST-aware Nushell code formatter with intelligent line wrapping. Wraps long lines at semantically appropriate points (pipelines and assignments) before delegating to topiary for final formatting.

## Features

- ✅ **Pipeline wrapping**: Breaks long pipelines at `|` operators
- ✅ **Assignment wrapping**: Wraps long `let` assignments  
- ✅ **Indentation preservation**: Maintains original indentation
- ✅ **Topiary integration**: Uses topiary for final formatting
- ✅ **Configurable width**: Set custom max line width
- ⚠️ **Phase 1**: Heuristic approach (string detection not yet implemented)

## Installation

### Using nupm (recommended)

```nu
# Install from local directory
nupm install --path /path/to/nufmt

# Or install from git
nupm install --git https://github.com/youruser/nufmt
```

### Manual installation

```nu
# Add to your env.nu or config.nu
use /path/to/nufmt/nufmt *
```

## Usage

### As a Module

```nu
# Import the module
use nufmt

# Format a file with default width (100 chars)
nufmt format script.nu

# Format with custom max width
nufmt format script.nu --max-width 80

# Format from stdin
open script.nu | nufmt format-stdin

# Save formatted output
nufmt format script.nu | save formatted.nu
```

### As a Script

```nu
# Run directly as a script
nu /path/to/nufmt/nufmt/mod.nu script.nu --max-width 80
```

### Testing Without nupm

If you don't have nupm installed, you can still run tests manually:

```nu
# Run a specific test
use nufmt *
use tests *
test-pipeline-wrapping

# Run all tests (list them manually)
[
  test-pipeline-wrapping
  test-short-pipeline-no-wrap  
  test-assignment-wrapping
  test-indentation-preservation
  test-multiple-statements
  test-comment-preservation
  test-empty-file
  test-custom-max-width
  test-idempotence
  test-wrap-pipelines-function
  test-wrap-assignments-function
] | each {|test| 
  print $"Running ($test)..."
  do $test
  print "✓ Passed"
}
```

## Examples

**Before:**

```nu
let result = $data | filter {|x| $x > 10} | sort | first 5 | each {|item| $item * 2} | where $it > 100
```

**After (max-width 60):**

```nu
let result = $data
| filter {|x| $x > 10 }
| sort
| first 5
| each {|item| $item * 2 }
| where $it > 100
```

## Testing

Run the test suite:

```nu
nupm test
```

Tests cover:

- Pipeline wrapping
- Assignment wrapping  
- Indentation preservation
- Multiple statements
- Comment preservation
- Idempotence
- Edge cases

## Project Structure

```
nufmt/
├── nupm.nuon           # Package metadata
├── README.md           # This file
├── CLAUDE.md           # Design document
├── nufmt/              # Module directory
│   └── mod.nu          # Main formatter code
└── tests/              # Test suite
    └── mod.nu          # Test definitions
```

## Dependencies

- **Nushell** ≥0.90 (for stable `ast --json`)
- **topiary-cli** ≥0.6.0
- **topiary-nushell** (blindFS fork)

### Setting up topiary-nushell

```nu
# Clone the topiary-nushell repository
git clone https://github.com/blindFS/topiary-nushell ~/.config/topiary

# Set environment variables in your env.nu
$env.TOPIARY_CONFIG_FILE = (~/.config/topiary/languages.ncl)
$env.TOPIARY_LANGUAGE_DIR = (~/.config/topiary/languages)
```

## Current Limitations

⚠️ **Known Issues** (see TEST-RESULTS.md):

1. **Breaks inside strings**: The formatter currently wraps at `|` and `=` even inside strings
2. **Breaks inside string interpolations**: Pipes in `$"...($x | cmd)..."` get wrapped
3. **Assignment wrapping incomplete**: Logic exists but doesn't always trigger

**Status**: 🟡 Works for simple cases, but will corrupt code with strings containing `|` or `=`

## Development Status

- **Phase 1** (Heuristic): ✅ Partially complete
  - ✅ Pipeline wrapping
  - ✅ Assignment wrapping (needs fixes)
  - ❌ String detection (critical missing feature)
  
- **Phase 2** (AST-aware): 📋 Planned
  - Use AST spans for accurate string boundaries
  - Validate wrap points at statement boundaries
  - Smart break alignment

## Contributing

See CLAUDE.md for design details and implementation strategy.

## License

MIT
