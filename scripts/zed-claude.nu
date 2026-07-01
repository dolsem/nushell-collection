def normalize_path [str: string] {
  mut parts = $str | path split
  mut first_part = $parts | get 0
  $parts = $parts | slice 1..
  if $nu.os-info.name == "windows" {
    let letter = first_part | str replace '\' ''
    $parts = [$letter, ...$parts]
  } else {
    $parts = ['', ...$parts]
  }
  $parts | str join '/'
}

def session_exists [session_id: string] {
    let config_dir = (
        $env.CLAUDE_CONFIG_DIR?
        | default ("~/.claude" | path expand)
    )
    let sessions_dir = ($config_dir | path join "projects")

    if ($sessions_dir | path exists) {
        let sessions_glob = normalize_path ($sessions_dir | path join $"**/($session_id)*")

        # Pull file paths, read json contents, and look for a matching sessionId
        (glob $sessions_glob | length) > 0
    } else {
        false
    }
}

let session_id = ($env.ZED_THREAD_ID? | default "")
if ($session_id | is-empty) {
    error make {msg: "ZED_THREAD_ID environment variable is missing or empty"}
}
if (session_exists $session_id) {
  ~/.local/bin/claude --resume $session_id
} else {
  ~/.local/bin/claude --session-id $session_id
}
