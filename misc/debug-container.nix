pkgs:
{
  debug-container = pkgs.dockerTools.buildImage {
    name = "debug-container";
    tag = "0.1.0";
    copyToRoot = [
      (pkgs.buildEnv {
        name = "image-root";
        paths = with pkgs; [
          bashInteractive
          btop
          coreutils
          curl
          docker-client
          fish
          gdb
          git
          git-lfs
          gnugrep
          gnused
          htop
          iotop
          iproute2
          jo
          jq
          kubectl
          kubevirt
          less
          lsof
          ltrace
          openssh
          (python3.withPackages (p: with p; [
            pyyaml
            requests
          ]))
          procs
          ps
          shadow
          sshpass
          strace
          tcpdump
          util-linux
          neovim
          yq-go
        ];
        pathsToLink = [ "/bin" ];
      })
      pkgs.dockerTools.caCertificates
      pkgs.dockerTools.usrBinEnv
      (pkgs.writeTextFile {
        name = "sshd_config";
        text = ''
          AuthenticationMethods publickey
          Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
          KbdInteractiveAuthentication no
          KexAlgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org
          Macs hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com
          PasswordAuthentication no
          PermitRootLogin yes
          PrintMotd no
          StrictModes yes
          UseDns no
          UsePAM no
          X11Forwarding no
          Banner none
          AddressFamily any
          Port 64222
          Subsystem sftp ${pkgs.openssh}/libexec/sftp-server
          AuthorizedKeysFile %h/.ssh/authorized_keys /etc/ssh/authorized_keys.d/%u
          HostKey /etc/ssh/ssh_host_ed25519_key
        '';
        destination = "/etc/ssh/sshd_config";
      })
      (pkgs.writeTextFile {
        name = "root-authorized_keys";
        text = ''
          ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFkJYJCkj7fPff31pDkGULXhgff+jaaj4BKu1xzL/DeZ
        '';
        destination = "/etc/ssh/authorized_keys.d/root";
      })
      (pkgs.writeTextFile {
        name = "root-bashrc";
        text = ''
          if [[ $(ps --no-header --pid=$PPID --format=comm 2>/dev/null) != "fish" && -z ''${BASH_EXECUTION_STRING} && ''${SHLVL} == 1 ]]
          then
            shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION='''
            exec fish $LOGIN_OPTION
          fi
        '';
        destination = "/root/.bashrc";
      })
    ];
    runAsRoot = ''
      ${pkgs.dockerTools.shadowSetup}

      mkdir -p /usr
      ln -sf /bin /usr/bin

      mkdir -p /etc/ssh
      mkdir -p /var/empty
      ssh-keygen -t "ed25519" -f "/etc/ssh/ssh_host_ed25519_key" -N ""
      groupadd -r sshd
      useradd -r -g sshd sshd
      passwd -u root
    '';
    created = "2024-11-18T00:00:00Z";
  };
}
