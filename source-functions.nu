def load_dir [dir: string] {
  let expanded_dir = $dir | path expand
  let mod_file = $'($expanded_dir)/mod.nu'
  let mod_content = open $mod_file
  '' | save -f $mod_file
  ls --short-names $expanded_dir | filter { $in.name != 'mod.nu' } | each {
    $"export use ($in.name) *\n" | save --append $mod_file
  }
  if $mod_content != (open $mod_file) {
    exec $nu.current-exe
  }
}
load_dir ~/.functions
source ~/.functions/mod.nu
