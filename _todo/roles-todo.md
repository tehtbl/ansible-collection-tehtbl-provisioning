# Roles

- tehtbl.base_packages
- tehtbl.bootstrap
- tehtbl.ntp
- tehtbl.reboot
- tehtbl.swap
- tehtbl.ufw
- tehtbl.update
- tehtbl.cron
- tehtbl.dotfiles
- tehtbl.ssh_server
- tehtbl.swap
- tehtbl.reboot

- tehtbl.base_packages
- tehtbl.bootstrap
- tehtbl.ntp
- tehtbl.reboot
- tehtbl.ufw
- tehtbl.update
- tehtbl.ssh_server

- docker_install
  - depends: geerlingguy.docker

- ssh-keys deploying
- ssh-hardening
- ping (win && linux)
- tbl.dotfiles

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

- update/upgrade
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
