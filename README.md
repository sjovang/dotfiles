# dotfiles

Making machines nice

> [!WARNING]
> You should probably not use this without understanding what it does. It's made for my own preferences and you probably disagree on a bunch of stuff

## `.chezmoidata.yaml` setup

The bootstrap script and templates read user- and git-identity data from:

`~/.local/share/chezmoi/.chezmoidata.yaml`

You can let `./init/macos.sh` generate this file interactively, or create it manually.

### Example

```yaml
---
user:
  name: Your Name
  email: your.email@example.com

git:
  includes:
    - private:
        path: ~/Developer/Private
        ssh_key: ~/.ssh/id_ed25519
```

### How to use

1. Ensure `user.email` is set (used as the SSH key comment in `ssh-keygen -C`).
2. Ensure `git.includes.private.ssh_key` points to the private SSH key path to create/use.
3. Run `./init/macos.sh` (optionally with an HTTPS repo URL argument).
