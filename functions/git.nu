# Git wrapper with useful subcommands
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