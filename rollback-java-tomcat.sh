#!/bin/bash

TOMCAT_VERSION=9.0.115
TOMCAT_DIR=/home/ec2-user/apache-tomcat-${TOMCAT_VERSION}

echo "Stopping Tomcat (if running)..."
if [ -d "$TOMCAT_DIR/bin" ]; then
  $TOMCAT_DIR/bin/shutdown.sh || true
fi

echo "Removing Tomcat..."
rm -rf $TOMCAT_DIR
rm -f /home/ec2-user/apache-tomcat-${TOMCAT_VERSION}.tar.gz

echo "Removing Java..."
sudo dnf remove -y java-21-openjdk java-21-openjdk-devel || true

echo "Removing JAVA_HOME config..."
sudo rm -f /etc/profile.d/java.sh

echo "Rollback complete."
echo "NOTE: Hostname and /etc/hosts must be reset manually if changed."
