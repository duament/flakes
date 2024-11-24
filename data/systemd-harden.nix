{
  ProtectProc = "invisible";
  ProcSubset = "pid";
  DynamicUser = true;
  CapabilityBoundingSet = "";
  AmbientCapabilities = "";
  NoNewPrivileges = true;
  ProtectSystem = "strict";
  ProtectHome = true;
  PrivateTmp = true;
  PrivateDevices = true;
  PrivateNetwork = true;
  PrivateIPC = true;
  PrivateUsers = true;
  ProtectHostname = true;
  ProtectClock = true;
  ProtectKernelTunables = true;
  ProtectKernelModules = true;
  ProtectKernelLogs = true;
  ProtectControlGroups = true;
  RestrictAddressFamilies = [
    "AF_UNIX"
    "AF_INET"
    "AF_INET6"
  ];
  RestrictNamespaces = true;
  LockPersonality = true;
  MemoryDenyWriteExecute = true;
  RestrictRealtime = true;
  RestrictSUIDSGID = true;
  PrivateMounts = true;
  SystemCallFilter = "@system-service";
  SystemCallArchitectures = "native";
}
