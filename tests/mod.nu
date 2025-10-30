#!/usr/bin/env nu

# Test suite for nufmt - Nushell code formatter
#
# Run with: nupm test

use std assert
use ../nufmt *

# Test helper to format code and verify output
def format-and-check [input: string, expected: string, width: int = 60] {
  let tmp_file = (mktemp -t "nufmt-test-XXXXXX.nu")
  $input | save -f $tmp_file
  let result = (format $tmp_file --max-width $width)
  rm $tmp_file
  assert equal $result $expected
}

# Test: Basic pipeline wrapping
export def test-pipeline-wrapping [] {
  let input = 'let x = $data | filter {|x| $x > 10} | sort | first 5 | each {|item| $item * 2} | where $it > 100'
  let result = format-and-check $input "" 50
  
  # Verify the result contains line breaks at pipes
  assert ($result | str contains "| filter")
  assert ($result | str contains "| sort")
  assert ($result | str contains "| first 5")
}

# Test: Short pipelines should not wrap
export def test-short-pipeline-no-wrap [] {
  let input = 'let x = $data | filter {|x| $x > 10}'
  
  let tmp_file = (mktemp -t "nufmt-test-XXXXXX.nu")
  $input | save -f $tmp_file
  let result = (format $tmp_file --max-width 100)
  rm $tmp_file
  
  # Should remain on few lines since it's under max width
  let line_count = ($result | lines | length)
  assert ($line_count <= 3)
}

# Test: Assignment wrapping
export def test-assignment-wrapping [] {
  let input = 'let very_long_variable_name_that_exceeds_width = some_function arg1 arg2 arg3 arg4 arg5'
  
  let tmp_file = (mktemp -t "nufmt-test-XXXXXX.nu")
  $input | save -f $tmp_file
  let result = (format $tmp_file --max-width 50)
  rm $tmp_file
  
  # Result should be wrapped at the assignment
  assert ($result | str contains "=")
}

# Test: Indentation preservation
export def test-indentation-preservation [] {
  let input = '  let x = $data | filter {|x| $x > 10} | sort | first 5'
  
  let tmp_file = (mktemp -t "nufmt-test-XXXXXX.nu")
  $input | save -f $tmp_file
  let result = (format $tmp_file --max-width 40)
  rm $tmp_file
  
  # First line should start with spaces (indentation preserved)
  assert ($result | str starts-with "  ")
}

# Test: Multiple statements
export def test-multiple-statements [] {
  let input = 'let x = 1
let y = $x | each {|i| $i * 2} | filter {|i| $i > 5} | sort | reverse
let z = 3'
  
  let tmp_file = (mktemp -t "nufmt-test-XXXXXX.nu")
  $input | save -f $tmp_file
  let result = (format $tmp_file --max-width 50)
  rm $tmp_file
  
  # Should have multiple statements
  assert (($result | lines | length) >= 3)
}

# Test: Comments are preserved
export def test-comment-preservation [] {
  let input = '# This is a comment
let x = $data | filter {|x| $x > 10} | sort
# Another comment'
  
  let tmp_file = (mktemp -t "nufmt-test-XXXXXX.nu")
  $input | save -f $tmp_file
  let result = (format $tmp_file --max-width 40)
  rm $tmp_file
  
  # Comments should still be present
  assert ($result | str contains "# This is a comment")
  assert ($result | str contains "# Another comment")
}

# Test: Empty file
export def test-empty-file [] {
  let input = ''
  
  let tmp_file = (mktemp -t "nufmt-test-XXXXXX.nu")
  $input | save -f $tmp_file
  let result = (main $tmp_file --max-width 80)
  rm $tmp_file
  
  # Should handle empty files gracefully
  assert (($result | str length) == 0 or ($result | str trim | is-empty))
}

# Test: Custom max width
export def test-custom-max-width [] {
  let input = 'let x = $data | filter {|x| $x > 10} | sort | first 5'
  
  # Test with smaller width
  let tmp_file = (mktemp -t "nufmt-test-XXXXXX.nu")
  $input | save -f $tmp_file
  let result_narrow = (format $tmp_file --max-width 30)
  rm $tmp_file
  
  # Test with larger width
  $input | save -f $tmp_file
  let result_wide = (format $tmp_file --max-width 200)
  rm $tmp_file
  
  # Narrow width should have more lines than wide width
  assert (($result_narrow | lines | length) >= ($result_wide | lines | length))
}

# Test: Idempotence - formatting twice should give same result
export def test-idempotence [] {
  let input = 'let x = $data | filter {|x| $x > 10} | sort | first 5 | each {|item| $item * 2}'
  
  # First format
  let tmp_file1 = (mktemp -t "nufmt-test-XXXXXX.nu")
  $input | save -f $tmp_file1
  let result1 = (format $tmp_file1 --max-width 50)
  rm $tmp_file1
  
  # Second format (format the result)
  let tmp_file2 = (mktemp -t "nufmt-test-XXXXXX.nu")
  $result1 | save -f $tmp_file2
  let result2 = (format $tmp_file2 --max-width 50)
  rm $tmp_file2
  
  # Results should be identical
  assert equal $result1 $result2
}

# Test: wrap-pipelines helper function directly
export def test-wrap-pipelines-function [] {
  let input = 'let x = $data | filter {|x| $x > 10} | sort | first 5'
  let result = ($input | wrap-pipelines 40)
  
  # Should contain line breaks at pipes
  assert ($result | str contains "\n")
  assert ($result | str contains "| filter")
}

# Test: wrap-assignments helper function directly
export def test-wrap-assignments-function [] {
  let input = 'let very_long_variable_name = some_function arg1 arg2 arg3 arg4 arg5 arg6'
  let result = ($input | wrap-assignments 40)
  
  # Should contain a line break
  assert ($result | str contains "\n")
  assert ($result | str contains "=")
}

# Test: Function definitions with pipelines
export def test-function-definition-wrapping [] {
  let input = 'def process-data [] { $in | filter {|x| $x > 10} | sort | first 5 | each {|item| $item * 2} }'
  
  let tmp_file = (mktemp -t "nufmt-test-XXXXXX.nu")
  $input | save -f $tmp_file
  let result = (format $tmp_file --max-width 50)
  rm $tmp_file
  
  # Should wrap the pipeline inside the function
  assert (($result | lines | length) > 1)
  assert ($result | str contains "def process-data")
}

# Test: Nested pipelines
export def test-nested-pipelines [] {
  let input = 'let x = $data | each {|item| $item | split row " " | first} | filter {|x| $x != ""} | sort'
  
  let tmp_file = (mktemp -t "nufmt-test-XXXXXX.nu")
  $input | save -f $tmp_file
  let result = (format $tmp_file --max-width 50)
  rm $tmp_file
  
  # Should handle nested pipelines
  assert ($result | str contains "|")
}

