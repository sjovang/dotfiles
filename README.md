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

wireguard:
  enabled: true
  interface:
    address: "10.0.0.2/24"
    dns: "10.0.0.1"
  peers:
    - public_key: "peer_public_key_here"
      endpoint: "vpn.example.com:51820"
      allowed_ips: "10.0.0.0/24"
      persistent_keepalive: 25
```

### How to use

1. Ensure `user.email` is set (used as the SSH key comment in `ssh-keygen -C`).
2. Ensure `git.includes.private.ssh_key` points to the private SSH key path to create/use.
3. (Optional) Configure `wireguard` section if you want to set up WireGuard client connectivity:
   - Set `enabled: true` to activate WireGuard configuration
   - The WireGuard private key is automatically generated on first run (stored in `/opt/homebrew/etc/wireguard/.private.key`)
   - Configure your interface address(es) for IPv4 and/or IPv6
   - Add peer configurations with their public keys and endpoints
   - Run the setup and retrieve your public key from the output to add to your WireGuard server
4. Run `./init/macos.sh` (optionally with an HTTPS repo URL argument).
