# SSH - SSH helpers like ssh-copy-id

export def ssh-copy-id [
    remote: string,                   # Target destination (e.g., user@hostname)
    --identity_file (-i): path = ([$nu.home-dir, '.ssh/id_ed25519.pub'] | path join) # Path to your public key
] {
    # Open the local public key and pipe it through standard SSH
    open $identity_file | ssh $remote "mkdir -p ~/.ssh; chmod 700 ~/.ssh; cat >> ~/.ssh/authorized_keys; chmod 600 ~/.ssh/authorized_keys"
}

