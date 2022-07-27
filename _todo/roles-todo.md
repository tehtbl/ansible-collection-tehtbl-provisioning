# Roles

- docker_install
  - depends: geerlingguy.docker

- ssh-keys deploying
- ssh-hardening
- ping (win && linux)

- wireguard
- backup borgbase

# Collection "Services"

- proxmox:
  - start stop snapshot vm
- docker-compose apps
- services enabled, started, stopped
- nginx_rev_proxy
  - acme.sh role
  - depends: - geerlingguy.nginx

# Collection "Maintenance"

- ssh-keys deploying
- sshd-keys renewal
- sudoers
- clean up (???)
- motd warning
- docker-ufw
- system-packages, allg., vllt meta pkg?!
- general packages like terraform, azure cli, etc pp
- install
- sysctl

# Collection "Logging"
