# ♦️ - Workflow command

export def ♦️ [
  ...args,
] {
  let msg = if ($args | is-empty) {
    "wip"
  } else if not ($args | get -o 0 | str ends-with ':') {
    $"wip: ($args | str join ' ')" | format_msg
  } else {
    $args | str join ' ' | format_msg
  }
  $msg

  ^git add .
  ^git commit -m $msg
  let hash = ^git rev-parse HEAD
  $hash | save -f (♦️_filepath)
}

export def ♦️♦️ [
  -k, # keep commit
] {
  if not (♦️_filepath | path exists) {
    error make { msg: "No saved workflow commit" }
  }
  let hash = (♦️_filepath | open)
  if $k {
    ^git cherry-pick $hash
  } else {
    ^git cherry-pick $hash --no-commit
  }
  rm (♦️_filepath)
}

def ♦️_filepath [] {
  let git_dir = ^git rev-parse --git-common-dir
  [$git_dir, '♦️'] | path join
}

def format_msg []: string -> string {
  $in | str replace --all --regex '(\[\[|\[|\]\]|\])' { |it|
    match $it {
      "[[" => "["
      "]]" => "]"
      "["  => "("
      "]"  => ")"
    }
  }
}
