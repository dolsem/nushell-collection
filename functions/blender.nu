# Blender version manager
const ENV_VAR = 'BLENDER_PATH'

export def --wrapped blender [...raw_args] {
  let args = parse_args $raw_args
  let blender_path = get_blender_path $args.version

  let blender_exec = if (sys host | $in.name == 'Windows') { 'blender.exe' } else { 'blender' }
  ^$"([$blender_path, $blender_exec] | path join)" ...$args.blender
}

export def --wrapped 'blender py' [...raw_args] {
  let args = parse_args $raw_args
  let blender_path = get_blender_path $args.version

  let python_path = get_python_path $blender_path
  let python_exec = if (sys host | $in.name == 'Windows') { 'python.exe' } else { 'python' }
  ^$"([$python_path, $python_exec] | path join)" ...$args.blender
}

def parse_args [args: list<string>] {
  let blender_args = $args | filter {|a| $a | str starts-with '-V:' | not $in}
  let version_args = $args | filter {|a| $a | str starts-with '-V:'}
  { blender: $blender_args, version: $version_args }
}

def get_blender_path [version_args: list<string>] {
  let blender_path = $env | get -i $ENV_VAR
  if ($blender_path | is-empty) {
    print -e $"BLENDER_PATH environment variable does not exist"
    return null
  }

  let version_key = if ($version_args | length) > 0 {
    $version_args | get 0 | str substring 3..
  } else {
    'default'
  }
  let blender_path_value = $blender_path | get -i $version_key
  if ($blender_path_value | is-empty) {
    print -e $"Key "($version_key)" not set in ($ENV_VAR)"
    return null
  }

  $blender_path_value
}

def get_python_path [blender_path: string] {
  let dir = (ls $blender_path | where type == 'dir' | get name | filter { ($in | path basename | str substring 0..0 | try { $in | into int | true } | default false) } | get 0)
  [$blender_path, $dir, 'python', 'bin'] | path join
}