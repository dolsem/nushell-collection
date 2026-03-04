# VSCode helpers
# module

# list all commands for an extension
export def 'code command list' [extension: string] {
    let ext_dir = ("~/.vscode/extensions" | path expand)
    let folder = (ls $ext_dir | where name =~ $extension | first).name
    let pkg = (open ($folder | path join "package.json"))
    $pkg.contributes.commands | select command title
}

# runs a command, requires command server extension running on port 3131: https://marketplace.visualstudio.com/items?itemName=crimson206.vscode-command-server
export def 'code command run' [
  command: string
  ...args: any
] {
  let payload = {
    command: $command
    args: $args
  }

  try {
    http post --content-type application/json http://localhost:3131/execute ($payload | to json -r)
  } catch {|err|
    let msg = ($err | into string)
    if ($msg =~ 'Cannot make request') {
      print "❌ VSCode Command Server is not running."
      print "Install/enable the extension:"
      print "\e]8;;https://marketplace.visualstudio.com/items?itemName=crimson206.vscode-command-server\e\\Install VSCode Command Server\e]8;;\e\\"
    } else {
      error make {msg: $msg}
    }
  }
  
}

export def 'code command' [] {
  help code command
}


export def 'gitlens show' [sha: string] {
  let repoPath = (git rev-parse --show-toplevel | str trim | str replace -a '\' '/')
  code command run "gitlens.showInDetailsView" {
    ref: {
      repoPath: $repoPath
      refType: "revision"
      ref: $sha
      sha: $sha
    }
  }
}

export def --wrapped 'gitlens diff' [
  ref1?: string
  ref2?: string
  ...rest
] {
  let help = [
    "Usage:"
    "  gitlens diff <ref1> <ref2>"
    "  gitlens diff <ref1> <ref2> -- <file>"
  ] | str join "\n"

  if ($ref1 == null) or ($ref2 == null) or ($rest | any {|x| $x == "--help" or $x == "-h"}) {
    print $help
    return
  }

  let repoPath = (git rev-parse --show-toplevel | str trim | str replace -a '\' '/')

  let file = (
    if ($rest | is-empty) {
      null
    } else {
      if ($rest | length) != 2 or ($rest | first) != "--" {
        error make { msg: "Usage: gitlens diff <ref1> <ref2> [-- path/to/file]" }
      }
      $rest | get 1
    }
  )

  if ($file == null) {
    code command run "gitlens.compareWith" {
      ref1: $ref1
      ref2: $ref2
    }
  } else {
    let absFile = (
      if ($file | path type) == "absolute" {
        $file
      } else {
        $repoPath | path join $file
      }
      | str replace -a '\' '/'
    )

    code command run "gitlens.diffWith" {
      repoPath: $repoPath
      lhs: {
        sha: $ref2
        uri: {
          scheme: "file"
          fsPath: $absFile
          path: $"/($absFile)"
        }
      }
      rhs: {
        sha: $ref1
        uri: {
          scheme: "file"
          fsPath: $absFile
          path: $"/($absFile)"
        }
      }
    }
  }
}

export def gitlens [] {
  help gitlens
}