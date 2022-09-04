config: port: server: {
  server = config.sops.placeholder."shadowsocks/${server}/server";
  server_port = config.sops.placeholder."shadowsocks/${server}/server_port";
  password = config.sops.placeholder."shadowsocks/${server}/password";
  method = config.sops.placeholder."shadowsocks/${server}/method";
  local_address = "0.0.0.0";
  local_port = port;
  timeout = 300;
  mode = "tcp_and_udp";
}
