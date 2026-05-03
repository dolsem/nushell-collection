# Zed editor helpers

export def zlog [
  ref?: string,
  --cleanup,
] {
  if $cleanup {
    rm ([(^git rev-parse --git-dir), 'zlog*'] | path join)
    return
  }

  let result = ^git log --decorate --oneline $ref | complete
  if $result.exit_code != 0 {
    print -e $result.stderr
    return
  }

  let filepath = (zlog_filepath $ref)
  $result.stdout | save -f $filepath
  ^zed $filepath
}

def zlog_filepath [ref: string] {
  [(^git rev-parse --git-dir), $"zlog[($ref)]"] | path join
}
