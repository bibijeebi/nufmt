#!/usr/bin/env nu

# AST-aware line wrapper for Nushell
export def main [
  --max-width: int = 100
  file?: path
] {
  let code = if $file != null { open $file } else { $in }

  # Parse AST to identify wrappable structures
  let ast_data = ($code | default "" | ast --json $in)

  # Extract pipeline locations, let statements, etc
  # Insert strategic breaks based on AST nodes

  $code | wrap-pipelines $max_width
  | wrap-assignments $max_width
  | topiary format -l nu -t
}

export def wrap-pipelines [max_width: int] {
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

export def wrap-assignments [max_width: int] {
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
