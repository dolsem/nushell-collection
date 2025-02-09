# kq - simple K8S templating using yq

export def kq [
  file?: string,
  --image: string,
  --pull-secret: string,
] {
  mut result = if ($file | is-empty) { $in } else { open -r $file }

  if ($image | is-not-empty) {
    let images = $image | split row ',' | each { str trim }
    for ix in 0..($images | length | $in - 1) {
      let image = $images | get $ix
      if ($image | is-not-empty) {
        $result = $result | yq $".spec.template.spec.containers[($ix)].image = "($image)""
      }
    }
  }

  if ($pull_secret | is-not-empty) {
    let pull_secrets = $pull_secret | split row ',' | each { str trim }
    for ix in 0..($pull_secrets | length | $in - 1) {
      let secret = $pull_secrets | get $ix
      if ($secret | is-not-empty) {
        $result = $result | yq $".spec.template.spec.imagePullSecrets[($ix)].name = "($secret)""
      }
    }
  }

  $result
}
