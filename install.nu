def add_config [entry: string] {
  let config = open $nu.config-path
  if not ($config | str contains $entry) {
    if not ($config | split row (char newline) | last | str trim | is-empty) {
      char newline | save -a $nu.config-path
    }
    $entry + (char newline) | save -a $nu.config-path
  }
}

def install_functions [functions: list<string>] {
  mkdir ~/.functions
  touch ~/.functions/mod.nu
  for function in $functions {
    cp $"($env.FILE_PWD)/functions/($function)" ~/.functions
  }
  add_config (open $"($env.FILE_PWD)/source-functions.nu")
}

let functions_dir = $"($env.FILE_PWD)/functions"
let functions = ls --short-names $functions_dir | get name
let functions_prompt = 'Select what you would like to install. Use <Space> to select/unselect, <Enter> to submit.'
let function_descriptions = $functions | each { open $'($functions_dir)/($in)' | lines | get 0 | str substring 1.. | str trim }
let selected_functions = $function_descriptions | input list -m -i $functions_prompt | each {|ix| $functions | get $ix }
install_functions $selected_functions