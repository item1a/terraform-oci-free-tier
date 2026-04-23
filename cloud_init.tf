locals {
  cloud_init_scripts = {
    for k, inst in var.instances : k => join("", [
      local.cloud_init_base,
      join("\n", [
        for pkg in inst.extra_packages :
        "dnf module install -y ${pkg} 2>/dev/null || dnf install -y ${pkg}"
      ]),
      "\n",
      inst.block_volume_gb > 0 ? templatestring(local.cloud_init_block_volume, {
        workspace_path = inst.workspace_path
        app_user       = inst.app_user
      }) : "",
      templatestring(local.cloud_init_service, {
        app_user = inst.app_user
        app_port = inst.app_port
      }),
      inst.extra_cloud_init != "" ? "\n# Extra cloud-init commands\n${inst.extra_cloud_init}\n" : "",
      "\necho \"=== Provisioning complete ===\"\n",
    ])
  }

  cloud_init_base = <<-SCRIPT
#!/bin/bash
set -euo pipefail
exec > /var/log/cloud-init-app.log 2>&1

echo "=== Starting provisioning ==="

# App directory
mkdir -p /opt/app

# Base packages
dnf install -y unzip git python3-oci-cli || {
  curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh | bash -s -- --accept-all-defaults
  ln -sf /root/bin/oci /usr/local/bin/oci
}

# Extra packages
SCRIPT

  cloud_init_block_volume = <<-SCRIPT

# Mount block volume
mkdir -p $${workspace_path}
BLOCK_DEV=""
for dev in /dev/oracleoci/oraclevdb /dev/sdb; do
  if [ -b "$dev" ]; then
    BLOCK_DEV="$dev"
    break
  fi
done

if [ -n "$BLOCK_DEV" ]; then
  if ! blkid "$BLOCK_DEV" | grep -q "TYPE="; then
    mkfs.xfs "$BLOCK_DEV"
  fi
  mount "$BLOCK_DEV" $${workspace_path}
  UUID=$(blkid -s UUID -o value "$BLOCK_DEV")
  echo "UUID=$UUID $${workspace_path} xfs defaults,_netdev,nofail 0 2" >> /etc/fstab
fi

chown $${app_user}:$${app_user} $${workspace_path}
SCRIPT

  cloud_init_service = <<-SCRIPT

# Firewall
firewall-cmd --permanent --add-port=$${app_port}/tcp
firewall-cmd --reload

# Systemd service
cat > /etc/systemd/system/webapp.service << 'UNIT'
[Unit]
Description=Web Application
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$${app_user}
Group=$${app_user}
WorkingDirectory=/opt/app
EnvironmentFile=/opt/app/.env
ExecStart=/opt/app/server
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable webapp.service

# Placeholder .env
cat > /opt/app/.env << 'ENV'
PORT=$${app_port}
ENV
chown $${app_user}:$${app_user} /opt/app/.env
chmod 600 /opt/app/.env
SCRIPT
}
