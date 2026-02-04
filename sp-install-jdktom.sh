#!/bin/bash
set -e

#######################################
# 1. HOSTNAME SETUP
#######################################
read -p "Enter hostname to set: " NEW_HOSTNAME

if [ -z "$NEW_HOSTNAME" ]; then
  echo "ERROR: Hostname cannot be empty"
  exit 1
fi

echo "Setting hostname to: $NEW_HOSTNAME"
sudo hostnamectl set-hostname "$NEW_HOSTNAME"

echo "Updating /etc/hosts..."
sudo tee /etc/hosts > /dev/null <<EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
127.0.0.1   $NEW_HOSTNAME
::1         $NEW_HOSTNAME
EOF

#######################################
# 2. JAVA INSTALLATION (PINNED JDK 21)
#######################################
JAVA_MAJOR=21
JDK_RPM_VERSION="21.0.2.0.13-2.el9"   # 🔒 PIN THIS VERSION

echo "Installing Java ${JAVA_MAJOR} (${JDK_RPM_VERSION})..."
sudo dnf install -y \
  java-${JAVA_MAJOR}-openjdk-${JDK_RPM_VERSION} \
  java-${JAVA_MAJOR}-openjdk-devel-${JDK_RPM_VERSION}

echo "Configuring JAVA_HOME..."
sudo tee /etc/profile.d/java.sh <<'EOF'
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
export PATH=$JAVA_HOME/bin:$PATH
EOF

sudo chmod +x /etc/profile.d/java.sh
source /etc/profile.d/java.sh

#######################################
# 3. TOMCAT INSTALLATION (PINNED)
#######################################
TOMCAT_VERSION=9.0.115
USER_HOME=/home/ec2-user
TOMCAT_DIR=apache-tomcat-${TOMCAT_VERSION}
TAR_FILE=${TOMCAT_DIR}.tar.gz

echo "Installing utilities..."
sudo dnf install -y wget tar

cd $USER_HOME

if [ ! -f "$TAR_FILE" ]; then
  echo "Downloading Tomcat ${TOMCAT_VERSION}..."
  wget https://downloads.apache.org/tomcat/tomcat-9/v${TOMCAT_VERSION}/bin/${TAR_FILE}
fi

if [ ! -d "$TOMCAT_DIR" ]; then
  echo "Extracting Tomcat..."
  tar -xvzf $TAR_FILE
fi

echo "Setting execute permissions..."
chmod +x $TOMCAT_DIR/bin/*.sh

echo "Starting Tomcat..."
$USER_HOME/$TOMCAT_DIR/bin/startup.sh

#######################################
# 4. VALIDATION / TESTS
#######################################
echo ""
echo "===== VALIDATION ====="

echo "Hostname:"
hostname

echo ""
echo "Java version:"
java -version

echo ""
echo "Installed Java RPMs:"
rpm -qa | grep java-${JAVA_MAJOR}-openjdk || true

echo ""
echo "Tomcat process:"
ps -ef | grep -i tomcat | grep -v grep || echo "Tomcat not running"

echo ""
echo "Tomcat port check (8080):"
ss -lntp | grep 8080 || echo "Port 8080 not listening"

echo ""
echo "Setup complete."
echo "Access Tomcat at: http://<EC2_PUBLIC_IP>:8080"


echo "IMPORTANT:IMPORTANT:IMPORTANT:IMPORTANT:IMPORTANT:IMPORTANT:IMPORTANT:
When this script is executed multiple times on the same system with different
hostnames, /etc/hosts should be reviewed to confirm that only the intended
hostname is present. Stale or duplicate hostname entries should be removed to
avoid name resolution issues."
