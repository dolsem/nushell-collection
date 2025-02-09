# j - Directory bookmarks

export def --env j [
  --add (-a) # add new bookmark
  --remove (-r) # remove bookmark
  name?: string # bookmark name
] {
  let config_dir = '~/.config' | path expand
  let config_file = $'($config_dir)/bookmarks'
  let default_bookmarks = {~: ('~' | path expand)}
  let errors = {
    name_arg_missing: 'Bookmark name missing'
    name_not_exists: 'Bookmark "name" does not exist'
    name_exists: 'Bookmark "name" exists'
  }

  mkdir $config_dir
  let bookmarks = if ($config_file | path exists) {
    open $config_file | from json | merge $default_bookmarks
  } else {
    $default_bookmarks | to json | save $config_file
    $default_bookmarks
  }

  if $add {
    if $name == null {
      print -e $errors.name_arg_missing
      return
    }
    try {
      $bookmarks | get $name
      print -e ($errors.name_exists | str replace name $name)
    } catch {
      $bookmarks | insert $name (pwd) | to json | save -f $config_file
    }
    return
  }

  if $remove {
    if $name == null {
      print -e $errors.name_arg_missing
    } else {
      let updated_bookmarks = try {
        $bookmarks | reject $name
      } catch {
        print -e ($errors.name_not_exists | str replace name $name)
        null
      }
      if $updated_bookmarks != null {
        $updated_bookmarks | to json | save -f $config_file
      }
    }
    return
  }

  let cd_path = if $name != null {
    try {
      $bookmarks | get $name
    } catch {
      print -e ($errors.name_not_exists | str replace name $name)
      null
    }
  } else {
    null
  }

  if $cd_path == null {
    return $bookmarks | transpose name path
  }
  cd $cd_path
}
