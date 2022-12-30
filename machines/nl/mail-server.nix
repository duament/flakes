{ config, lib, pkgs, ... }:
let
  domain = "rvf6.com";
  hostname = "${config.networking.hostName}.${domain}";
  certificatePath = "${config.security.acme.certs.${hostname}.directory}/fullchain.pem";
  keyPath = "${config.security.acme.certs.${hostname}.directory}/key.pem";
  opendmarcSocket = "/run/opendmarc/opendmarc";
in
{
  sops.secrets = {
    "dovecot/passwd".owner = config.services.dovecot2.user;
    "dkim".owner = config.services.opendkim.user;
  };

  services.postfix = {
    enable = true;
    enableSmtp = true;
    enableSubmissions = true;
    hostname = hostname;
    networksStyle = "host";
    config = {
      mydestination = "";

      virtual_mailbox_domains = domain;
      virtual_transport = "lmtp:unix:/run/dovecot2/dovecot-lmtp";

      smtpd_sasl_auth_enable = true;
      smtpd_sasl_type = "dovecot";
      smtpd_sasl_path = "/run/dovecot2/auth";
      smtpd_sasl_local_domain = "$mydomain";
      smtpd_relay_restrictions = [ "permit_sasl_authenticated" "reject_unauth_destination" ];
      smtpd_sender_restrictions = "reject_sender_login_mismatch";
      smtpd_tls_auth_only = true;
      smtpd_tls_security_level = "may";
      smtpd_tls_received_header = true;
      smtpd_tls_chain_files = [ keyPath certificatePath ];
      smtpd_tls_loglevel = "1";

      smtp_tls_security_level = "may";
      smtp_tls_loglevel = "1";

      smtpd_milters = [
        "unix:${lib.removePrefix "local:" config.services.opendkim.socket}"
        "unix:${opendmarcSocket}"
      ];
      non_smtpd_milters = "$smtpd_milters";
    };
  };

  services.dovecot2 = rec {
    enable = true;
    enableLmtp = true;
    enablePAM = false;
    mailUser = "vmail";
    mailGroup = "vmail";
    mailLocation = "maildir:/var/mail";
    sslServerCert = certificatePath;
    sslServerKey = keyPath;
    extraConfig = ''
      ssl = required
      ssl_min_protocol = TLSv1.2

      passdb {
        driver = passwd-file
        args = ${config.sops.secrets."dovecot/passwd".path}
      }

      userdb {
        driver = static
        args = uid=${mailUser} gid=${mailGroup} home=/var/mail allow_all_users=yes
      }

      auth_mechanisms = plain login

      service imap-login {
        inet_listener imap {
          port=0
        }
      }

      service lmtp {
        unix_listener dovecot-lmtp {
          user = ${config.services.postfix.user}
          group = ${config.services.postfix.group}
          mode = 0600
        }
      }

      service auth {
        unix_listener auth {
          user = ${config.services.postfix.user}
          group = ${config.services.postfix.group}
          mode = 0600
        }
      }
    '';
  };

  services.opendkim = {
    enable = true;
    domains = "csl:${domain}";
    selector = "dkim";
    group = config.services.postfix.group;
    configFile = pkgs.writeText "opendkim-config" "UMask 007";
  };
  systemd.services.opendkim.preStart = lib.mkBefore "ln -sf ${config.sops.secrets.dkim.path} ${config.services.opendkim.keyPath}/${config.services.opendkim.selector}.private";

  systemd.services.opendmarc =
    let
      opendmarcConfig = pkgs.writeText "opendmarc-config" ''
        AuthservID ${hostname}
        IgnoreAuthenticatedClients true
        Socket unix:${opendmarcSocket}
        SPFSelfValidate true
        UMask 007
      '';
    in
    {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = import ../../lib/systemd-harden.nix // {
        ExecStart = "${pkgs.opendmarc}/bin/opendmarc -f -c ${opendmarcConfig}";
        Group = config.services.postfix.group;
        RuntimeDirectory = "opendmarc";
        RuntimeDirectoryMode = "0750";
        PrivateNetwork = false;
      };
    };

  security.acme.certs.${hostname}.reloadServices = [
    "postfix.service"
    "dovecot2.service"
  ];
}
