def normalize_path [str: string] {
  mut parts = $str | path split
  if $nu.os-info.name == "windows" {
    let letter = $parts | get 0 | str replace '\' ''
    $parts = [$letter, ...($parts | slice 1..)]
  }
  $parts | str join '/'
}

def session_exists [session_id: string] {
    let config_dir = (
        $env.CLAUDE_CONFIG_DIR?
        | default ("~/.claude" | path expand)
    )
    let sessions_dir = ($config_dir | path join "sessions")

    if ($sessions_dir | path exists) {
        let sessions_glob = normalize_path ($sessions_dir | path join "*.json")

        # Pull file paths, read json contents, and look for a matching sessionId
        (glob $sessions_glob
          | each { |file| open $file | get -o sessionId }
          | any { |id| $id == $session_id }
        )
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
