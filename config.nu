# ~/Library/Application Support/nushell/config.nu

use std *

$env.PATH = [
  /Users/benjaminforeman/bin
  /Users/benjaminforeman/go/bin
  "/Users/benjaminforeman/.fig/bin"
  "/Users/benjaminforeman/.deno/bin"
  "/Users/benjaminforeman/.cursor-server/bin"
  "/Users/benjaminforeman/.cargo/bin"
  "/Users/benjaminforeman/.local/bin"
  ...$env.PATH?
  /Library/Tex/texbin
  /opt/homebrew/opt/python@3.14/libexec/bin
  /opt/homebrew/sbin
  /opt/homebrew/bin
  /usr/local/sbin
  /usr/local/bin
  /usr/sbin
  /usr/bin
  /sbin
  /bin
] | uniq

$env.config.show_banner = false
$env.config.buffer_editor = 'hx'

$env.TOPIARY_HOME = ($nu.default-config-dir | path join topiary)

if not ($env.TOPIARY_HOME | path exists) {  
  ^gh repo clone blindFS/topiary-nushell $env.TOPIARY_HOME
}

$env.TOPIARY_CONFIG_FILE = ($env.TOPIARY_HOME | path join languages.ncl)
$env.TOPIARY_LANGUAGE_DIR = ($env.TOPIARY_HOME | path join languages)

const user_autoload_dir = $nu.default-config-dir | path join autoload
const vendor_autoload_dir = $nu.default-config-dir | path join vendor autoload

mkdir $user_autoload_dir $vendor_autoload_dir | ignore

for init in [
  'zoxide init nushell'
  'carapace _carapace nushell'
  'starship init nu'
] {
  nu -c $init | save -f (
    {
      parent: $vendor_autoload_dir
      stem: ($init | split words | first | path basename)
      extension: nu
    } | path join
  )
}

def nu-persist [...names] {
  let persist_file = $nu.default-config-dir | path join "persist.nu"
  
  $names | each {|name|
    let source = try { view source $name } catch { return }
    $"# persisted (date now | format date '%Y-%m-%d %H:%M')\n($source)\n" | save --append $persist_file
  }
  
  let config_file = $nu.default-config-dir | path join "config.nu"
  let source_line = $"source ($persist_file)"
  
  if not ($config_file | open | str contains $source_line) {
    $"\n($source_line)\n" | save --append $config_file
  }
}


def tokc [] { match ($in | to text) { "" => 0 $text => (http post -t application/json -H { 'x-api-key': (^security find-generic-password -s ANTHROPIC_API_KEY -w) 'anthropic-version': '2023-06-01' } https://api.anthropic.com/v1/messages/count_tokens { model: 'claude-sonnet-4-5-20250929' messages: [{role: user content: $text}] } | get input_tokens) } }

def most-recent [dir: path = .] { ls $dir | sort-by modified | last | get name }

def choose-starship-preset [] { ^starship preset --list | lines | input list | ^starship preset $in | save -f ~/.config/starship.toml }


def --env y [...args] {
	let tmp = (mktemp -t "yazi-cwd.XXXXXX")
	yazi ...$args --cwd-file $tmp
	let cwd = (open $tmp)
	if $cwd != "" and $cwd != $env.PWD {
		cd $cwd
	}
	rm -fp $tmp
}


alias wget = ^wget2

alias tree = ^eza --icons --tree




def fconv [from: string, to: string, cmd: closure] {
    ls $"*.($from)" 
    | get name 
    | each {|file| 
        let out = ($file | path parse | update extension $to | path join)
        do $cmd $file $out
    }
}


alias cdtemp = cd (mktemp -d)

def 'plugin install' [name: string] { cargo install --locked nu_plugin_($name); plugin add nu_plugin_($name); nu -c 'plugin use $name'; print 'You must reloads a new nushell session to have the plugin active.'}


