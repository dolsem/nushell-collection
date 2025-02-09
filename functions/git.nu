# Git wrapper with useful subcommands
# module

export def 'git s' [...git_args] {
  ^git status -s ...$git_args
}

export def 'git dc' [...git_args] {
  ^git diff --cached ...$git_args
}

export def 'git rbi' [...git_args] {
  ^git rebase -i ...$git_args
}

export def 'git rbc' [...git_args] {
  ^git rebase --continue ...$git_args
}

export def 'git +x' [...git_args] {
  ^git update-index --chmod=+x ...$git_args
}

export def 'git unstash' [
  --index = 0,
  ...git_args
] {
  ^git checkout $'stash@{($index)}' '--' ...$git_args
}

def with-file [str: string, fn: closure] {
  let file = $nu.temp-path | path join $"(random uuid).tmp"
  $str | save $file
  let cleanup = { rm $file }
  try {
    let val = (do $fn $file)
    do $cleanup
    return $val
  } catch {
    do $cleanup
    $in.raw
  }
}

def print_conflict_diff [file_a: string, file_b: string] {
  let unchanged_fmt = '%='
  let old_fmt = "<<<<<<< Old%c'\\12'%<=======%c'\\12'>>>>>>> New%c'\\12'"
  let new_fmt = "<<<<<<< Old%c'\\12'=======%c'\\12'%>>>>>>>> New%c'\\12'"
  let changed_fmt = "<<<<<<< Old%c'\\12'%<=======%c'\\12'%>>>>>>>> New%c'\\12'"
  git show $"HEAD:($file_a)" | with-file $in {|f| (
    diff $f $file_b
      $"--unchanged-group-format=($unchanged_fmt)"
      $"--old-group-format=($old_fmt)"
      $"--new-group-format=($new_fmt)"
      $"--changed-group-format=($unchanged_fmt)"
  )}
}

def retrospect_list [retrospect_dir: string] {
  if ($retrospect_dir | path exists) {
    let file_glob = $"($retrospect_dir)/**/*" | into glob
    let files = ls -a $file_glob | filter { $in.type == 'file' } | get name | path relative-to $retrospect_dir
    if not ($files | is-empty) {
      return $files
    }
  }
  print -e 'No files are being retrospected'
}

def retrospect_cleanup [file: string] {
  let split_path = $file | path split
  for $i in ($split_path | length | $in - 1)..0 {
    let path_to_rm = $split_path | range 0..$i | path join
    if ($path_to_rm | path type) == 'dir' and (ls -a $path_to_rm | length) > 0 {
      break
    }
    try { rm $path_to_rm } catch {}
  }
}

def get_retrospect_editor [config_key: string] {
  mut editor = (git config --get $config_key)
  if ($editor | is-empty) { $editor = (git config --get core.editor) }
  if ($editor | is-empty) { $editor = ($env | get -i GIT_EDITOR) }
  if ($editor | is-empty) { $editor = ($env | get -i EDITOR) }
  return $editor
}

export def 'git retrospect' [
  file?: string,
  --abort,
  --done,
  --edit,
  --set-editor, # Set custom editor command for git retrospect --edit
] {
  let editor_config_key = 'retrospect.editor'
  let git_dir = git rev-parse --git-dir
  if ($git_dir | is-empty) { return }
  let retrospect_dir = [$git_dir, 'retrospect'] | path join

  # $ git retrospect --set-editor [<program>]
  if $set_editor {
    mut editor = $file
    if ($editor | is-empty) {
      let prev_editor = get_retrospect_editor $editor_config_key
      mut prompt = 'Enter command to be used as retrospect editor'
      if not ($prev_editor | is-empty) {
        $prompt = $prompt + $" \(default: ($prev_editor)\)"
      }
      $prompt = $prompt + ': '
      $editor = (input $prompt | str trim)
    }
    if not ($editor | is-empty) {
      git config --global --add $editor_config_key $editor
      print $"Set editor to '($editor)'"
    }
    return
  }

  if ($file | is-empty) { # list pending files: $ git retrospect
    return (retrospect_list $retrospect_dir)
  }

  if not ($file | try { path exists } catch { false }) {
    print -e $"'($file)' does not exist"
    return
  }

  if ($file | path type | $in == 'dir') {
    print -e 'git retrospect does not work with directories'
    return
  }

  let git_blame = (git blame $file | complete)
  if $git_blame.exit_code != 0 {
    print -ne $git_blame.stderr
    return
  }

  # $ git retrospect <file> [--edit|--abort|--done]
  let relative_dir = $file | path expand | path dirname | path relative-to (git rev-parse --show-toplevel)
  let depth = $relative_dir | path split | length
  let new_dir = $retrospect_dir + (if $depth > 0 { char path_sep | into string } else { '' }) + $relative_dir
  let new_file = $file | path basename | [$new_dir, $in] | path join
  mkdir $new_dir

  # cancel and revert changes: $ git retrospect <file> --abort
  if $abort {
    if not ($new_file | path exists) {
      print -e $'($file) is not found in retrospect cache'
      return
    }
    mv $new_file $file
    retrospect_cleanup $new_file
    return
  }

  # other commands: $ git retropect <file> [--edit|--done]

  # make sure we're using GNU diff
  if (diff --version | str starts-with 'Apple diff') {
    print -e 'GNU diff not installed. Install with `brew install diffutils`'
    rm $new_dir
    return
  }

  let file_lines = open $file | lines
  let check = {|fn| $file_lines | any $fn }
  if (do $check { str starts-with '<<<<<<< ' }) and (do $check { $in == '=======' }) and (do $check { str starts-with '>>>>>>> ' }) {
    print -e $"'($file)' has unresolved conflicts that have to be resolved first"
    return
  }

  # add selected changes to commit and restore file: $ git retrospect <file> --done
  if $done {
    git add $file
    mv $new_file $file
    retrospect_cleanup $new_file
    return
  }

  # start retrospection: $ git retrospect <file>
  if (git status --porcelain=v1 $file | length) == 0 {
    print -e $"'($file)' has no unstaged changes"
    return
  }

  if ($new_file | path exists) {
    mut answer = ''
    print -n $"Overwrite ($file) in retrospect cache \(all changes will be lost\)? \(y/n\): "
    while not ($answer in ['y', 'n']) {
      $answer = (input -s -n 1 | str downcase)
      # print -n $"\r(ansi erase_line)"
    }
    print $answer
    if $answer == 'n' { return }
  }

  cp $file $new_file
  print_conflict_diff $file $new_file | save -f $file

  # $ git retrospect <file> --edit
  if not ($edit | is-empty) {
    let $editor = (get_retrospect_editor $editor_config_key)
    if ($editor | is-empty) {
      print -e 'No editor set. Run `git retrospect --set-editor` to set an editor first.'
      return
    }
    ^$editor $file
  }
}

def find_commit [
  --grep: string,
  --after: string,
] {
  mut query = []
  if ($grep | is-not-empty) {
    $query = $query | append $"--grep=($grep)"
  }
  if ($after | is-not-empty) {
    $query = $query | append $"--after=($after)"
  }

  if ($query | length) < 1 {
    return
  }

  let commit_hashes = (git log --all --reverse --pretty=format:'%H' ...$query | lines)
  let count = $commit_hashes | length
  if $count < 1 {
    print -e $"No commit found matching ($query)"
    return
  }
  if $count > 1 and ($after | is-empty) {
    print -e ($"(ansi red)Multiple commits matching ($query):(ansi reset)")
    $commit_hashes | each {
      print -e (git log --color=always -1 $in)
    }
    return
  }
  return ($commit_hashes | first)
}

export alias 'git find c' = find_commit