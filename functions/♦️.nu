# ♦️ - Workflow command

export def ♦️ [
  -u, # add tracked files only
  -r, # add staged files only
  -s, # commit currently staged files without running git add
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

  if $u {
    ^git add -u
  } else if $r {
    ^git add (^git diff --name-only --cached)
  } else if $s {
    if (git diff --cached --quiet | complete | $in.exit_code == 0) {
      error make { msg: "Nothing is staged for commit" }
    }
  } else {
    ^git add .
  }
  ^git commit -m $msg
  let hash = ^git rev-parse HEAD
  $hash | save -f (♦️_filepath)
}

export def ♦️♦️ [
  -k, # keep commit
  -m, # use main worktree
  ...args,
] {
  let hash = if ($args | is-empty) {
    if not (♦️_filepath | path exists) {
      error make { msg: "No saved workflow commit" }
    }
    ♦️_filepath | open
  } else if ($args | length) == 1 {
    $args | get 0
  } else if ($args | length) == 2 {
    $"($args | get 0)^..($args | get 1)"
  } else {
    error make { msg: $"Wrong number of arguments: ($args | length)" }
  }

  let wt = if $m {
    ['-C' (^git rev-parse --git-common-dir | path dirname)]
  } else {
    []
  }
  if $k {
    ^git ...$wt cherry-pick $hash
  } else {
    ^git ...$wt cherry-pick --no-commit $hash
  }

  if ($args | is-empty) {
    rm -f (♦️_filepath)
  }
}

export def ♦️♦️♦️ [] {
  if not (git status --porcelain | is-empty) {
    error make { msg: 'Working directory is not clean' }
  }

  let main_dir = (^git rev-parse --git-common-dir | path dirname)
  let sha = ^git -C $main_dir rev-parse HEAD
  git reset --hard $sha
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
