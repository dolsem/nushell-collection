const REPO_URL = "https://github.com/dolsem/nushell-collection.git" 
const INSTALL_DIR = '.collection'

def add_to_config [entry: string] {
  let config = open $nu.config-path
  if not ($config | str contains $entry) {
    if not ($config | split row (char newline) | last | str trim | is-empty) {
      char newline | save -a $nu.config-path
    }
    $entry + (char newline) | save -a $nu.config-path
  }
}

def function_info [function_path: string] {
  let lines = open $function_path | lines
  {
    description: ($lines | get 0 | str substring 1.. | str trim),
    module: (($lines | get 1) == '# module'),
  }
}

def install_functions [functions_dir: string, functions: list<string>] {
  let functions_install_fullpath = [$nu.default-config-dir, $INSTALL_DIR, 'functions'] | path join
  let mod_file_fullpath = [$nu.default-config-dir, $INSTALL_DIR, 'mod.nu'] | path join

  mkdir $functions_install_fullpath
  for function in $functions {
    let function_path = [$functions_dir, $function] | path join
    cp $function_path $functions_install_fullpath
    if (function_info $function_path).module {
      $"export use functions/($function) *\n" | save -a $mod_file_fullpath
    } else {
      $"source functions/($function)\n" | save -a $mod_file_fullpath
    }
  }
  add_to_config $"source \([$nu.default-config-dir, '($INSTALL_DIR)', 'mod.nu'] | path join\)"
}

def local_install [root_path: string] {
  let functions_dir = [$root_path, 'functions'] | path join
  let functions = ls --short-names $functions_dir | get name
  let functions_prompt = 'Select what you would like to install. Use <Space> to select/unselect, <Enter> to submit.'
  let function_descriptions = $functions | each { (function_info $'($functions_dir)/($in)').description }
  let selected_functions = $function_descriptions | input list -m -i $functions_prompt | each {|ix| $functions | get $ix }

  if ($selected_functions | length) > 0 {
    let install_fullpath = [$nu.default-config-dir, $INSTALL_DIR, 'functions'] | path join
    let mod_file_fullpath = [$nu.default-config-dir, $INSTALL_DIR, 'mod.nu'] | path join
    rm -rf $install_fullpath
    mkdir $install_fullpath
    rm -rf $mod_file_fullpath
    install_functions $functions_dir $selected_functions
  }
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