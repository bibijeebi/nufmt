#!/usr/bin/env nu

# Format Nushell code with intelligent line wrapping from a file
#
# This command formats Nushell code by wrapping long lines at semantically
# appropriate points (pipelines and assignments) before applying topiary formatting.
#
# Examples:
#   # Format a file
#   nufmt format my-script.nu
#
#   # Format with custom max width
#   nufmt format --max-width 80 my-script.nu
#
#   # When used as a script
#   nu nufmt/mod.nu my-script.nu
export def --env main [
  file: path # Path to the Nushell file to format
  --max-width: int = 100 # Maximum line width before wrapping (default: 100)
] {
  format $file --max-width $max_width
}

# Format Nushell code with intelligent line wrapping from a file
#
# This is the main formatting function that wraps long lines and applies topiary.
export def format [
  file: path # Path to the Nushell file to format
  --max-width: int = 100 # Maximum line width before wrapping (default: 100)
] {
  let code = open $file

  # Parse AST to identify wrappable structures
  let ast_data = ($code | default "" | ast --json $in)

  # Extract pipeline locations, let statements, etc
  # Insert strategic breaks based on AST nodes

  $code | wrap-pipelines $max_width
  | wrap-assignments $max_width
  | topiary format -l nu -t
}

# Format Nushell code with intelligent line wrapping from stdin
#
# This command formats Nushell code by wrapping long lines at semantically
# appropriate points (pipelines and assignments) before applying topiary formatting.
#
# Examples:
#   # Format from stdin
#   cat script.nu | nufmt format-stdin
#
#   # Format with custom max width
#   open script.nu | nufmt format-stdin --max-width 80
export def format-stdin [
  --max-width: int = 100 # Maximum line width before wrapping (default: 100)
]: string -> string {
  let code = $in

  # Parse AST to identify wrappable structures
  let ast_data = ($code | default "" | ast --json $in)

  # Extract pipeline locations, let statements, etc
  # Insert strategic breaks based on AST nodes

  $code | wrap-pipelines $max_width
  | wrap-assignments $max_width
  | topiary format -l nu -t
}

# Wrap long lines at pipeline operators
#
# Takes text input and breaks lines that exceed max_width at pipeline operators (|).
# Preserves the original indentation of each line and adds it to wrapped continuations.
#
# Examples:
#   # Wrap a long pipeline
#   'let x = $data | filter {|x| $x > 10} | sort | first 5' | wrap-pipelines 40
#
#   # Process multiple lines
#   $code | wrap-pipelines 80
export def wrap-pipelines [
  max_width: int # Maximum character width before wrapping at pipes
]: string -> string {
  lines
  | each {|line|
    if ($line | str length) > $max_width and ($line | str contains ' | ') {
      # Break at pipes, preserve indentation
      let indent = $line | parse -r '^(\s*)' | get capture0.0
      $line
      | str replace -a ' | ' $"\n($indent)| "
    } else {
      $line
    }
  }
  | str join "\n"
}

# Wrap long lines at assignment operators
#
# Takes text input and breaks lines that exceed max_width at assignment operators (=).
# Preserves the original indentation and adds extra indentation to the wrapped value.
#
# Examples:
#   # Wrap a long assignment
#   'let my_var = some_function arg1 arg2 arg3 arg4 arg5' | wrap-assignments 40
#
#   # Process multiple lines
#   $code | wrap-assignments 80
export def wrap-assignments [
  max_width: int # Maximum character width before wrapping at assignments
]: string -> string {
  lines
  | each {|line|
    if ($line | str length) > $max_width and ($line | str contains ' = ') {
      # Break at assignments, preserve indentation
      let indent = $line | parse -r '^(\s*)' | get capture0.0
      $line
      | str replace ' = ' $"\n($indent)  = "
    } else {
      $line
    }
  }
  | str join "\n"
}
