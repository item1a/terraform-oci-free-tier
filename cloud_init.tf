locals {
  extra_packages_cmds = join("\n", [
    for pkg in var.extra_packages :
    "dnf module install -y ${pkg} 2>/dev/null || dnf install -y ${pkg}"
  ])

  cloud_init_script = <<-SCRIPT
#!/bin/bash
set -euo pipefail
exec > /var/log/cloud-init-app.log 2>&1

echo "=== Starting provisioning ==="

# App directory
mkdir -p /opt/app
chown -R ${var.app_user}:${var.app_user} /opt/app

# Base packages
dnf install -y unzip git python3-oci-cli || {
  curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh | bash -s -- --accept-all-defaults
  ln -sf /root/bin/oci /usr/local/bin/oci
}

# Extra packages
${local.extra_packages_cmds}

# Mount block volume
%{if var.block_volume_size_gb > 0}
mkdir -p ${var.workspace_path}
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
  mount "$BLOCK_DEV" ${var.workspace_path}
  UUID=$(blkid -s UUID -o value "$BLOCK_DEV")
  echo "UUID=$UUID ${var.workspace_path} xfs defaults,_netdev,nofail 0 2" >> /etc/fstab
fi

chown ${var.app_user}:${var.app_user} ${var.workspace_path}
%{endif}

# Firewall
firewall-cmd --permanent --add-port=${var.app_port}/tcp
firewall-cmd --reload

# Systemd service
cat > /etc/systemd/system/webapp.service << 'UNIT'
[Unit]
Description=Web Application
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=${var.app_user}
Group=${var.app_user}
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
PORT=${var.app_port}
ENV
chown ${var.app_user}:${var.app_user} /opt/app/.env
chmod 600 /opt/app/.env

# Extra cloud-init commands
${var.extra_cloud_init}

echo "=== Provisioning complete ==="
SCRIPT
}
