const REPO_URL = "https://github.com/dolsem/nushell-collection.git" 

def add_config [entry: string] {
  let config = open $nu.config-path
  if not ($config | str contains $entry) {
    if not ($config | split row (char newline) | last | str trim | is-empty) {
      char newline | save -a $nu.config-path
    }
    $entry + (char newline) | save -a $nu.config-path
  }
}

def install_functions [functions_dir: string, functions: list<string>] {
  mkdir ~/.functions
  touch ~/.functions/mod.nu
  for function in $functions {
    cp ([$functions_dir, $function] | path join) ~/.functions
  }
  add_config ([$functions_dir, '..', 'source-functions.nu'] | path join | open $in)
}

def local_install [root_path: string] {
  let functions_dir = [$root_path, 'functions'] | path join
  let functions = ls --short-names $functions_dir | get name
  let functions_prompt = 'Select what you would like to install. Use <Space> to select/unselect, <Enter> to submit.'
  let function_descriptions = $functions | each { open $'($functions_dir)/($in)' | lines | get 0 | str substring 1.. | str trim }
  let selected_functions = $function_descriptions | input list -m -i $functions_prompt | each {|ix| $functions | get $ix }
  install_functions $functions_dir $selected_functions
}

def remote_install [] {
  print "Installing from the remote repository"
  print $"Cloning ($REPO_URL)..."
  let clone_dir = mktemp -d
  print -n (ansi black_dimmed)
  git clone $REPO_URL $clone_dir
  print -n (ansi reset)
  try {
    local_install $clone_dir
  } catch { |err| 
    print -e $err
  }
  rm -rf $clone_dir
}

if ($env | get -i FILE_PWD | is-empty) {
  remote_install
} else {
  local_install $env.FILE_PWD
}