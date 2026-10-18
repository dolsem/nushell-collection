# from - extensions to from built-in

export def 'from env' [] {
  $in | lines | split column "=" key value | transpose -r -d
}
