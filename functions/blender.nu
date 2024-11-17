# Blender version manager
const ENV_VAR = 'BLENDER_PATH'

export def --wrapped main [...args] {
  let blender_path = $env | get -i $ENV_VAR
  if ($blender_path | is-empty) {
    print -e $"BLENDER_PATH environment variable does not exist"
    return
  }

  let blender_args = $args | filter {|a| $a | str starts-with '-V:' | not $in}
  let version_args = $args | filter {|a| $a | str starts-with '-V:'}
  let version_key = if ($version_args | length) > 0 {
    $version_args | get 0 | str substring 3..
  } else {
    'default'
  }
  let blender_path_value = $blender_path | get -i $version_key
  if ($blender_path_value | is-empty) {
    print -e $"Key "($version_key)" not set in ($ENV_VAR)"
    return
  }

  let blender_exec = if (sys host | $in.name == 'Windows') { 'blender.exe' } else { 'blender' }
  ^$"([$blender_path_value, $blender_exec] | path join)" ...$blender_args
}