#!/bin/bash
set -e

#######################################
# VARIABLES
#######################################
USER_HOME=/home/ec2-user
TOMCAT_DIR=${USER_HOME}/apache-tomcat-9.0.115
WEBAPPS_DIR=${TOMCAT_DIR}/webapps

IIQ_VERSION=8.5
IIQ_WAR_SRC=${USER_HOME}/identityiq-${IIQ_VERSION}.war
IIQ_WAR_DEST=${WEBAPPS_DIR}/identityiq.war

IIQ_HOME=${USER_HOME}/sailpoint-iiq

#######################################
# SAFETY CHECK – DO NOT OVERWRITE
#######################################
if [ -d "${WEBAPPS_DIR}/identityiq" ] || [ -f "${WEBAPPS_DIR}/identityiq.war" ]; then
  echo ""
  echo "ERROR:"
  echo "IdentityIQ webapp already exists."
  echo "Stopping the process to prevent overwrite."
  echo ""
  exit 1
fi

#######################################
# PRE-CHECKS
#######################################
echo "Validating prerequisites..."

[ -d "$TOMCAT_DIR" ] || { echo "Tomcat not found"; exit 1; }
command -v java >/dev/null || { echo "Java not found"; exit 1; }
[ -f "$IIQ_WAR_SRC" ] || { echo "WAR not found: $IIQ_WAR_SRC"; exit 1; }

echo "Prerequisites OK."

#######################################
# STOP TOMCAT
#######################################
echo "Stopping Tomcat..."
${TOMCAT_DIR}/bin/shutdown.sh || true
sleep 5

#######################################
# CREATE DEV-STANDARD IIQ DIRECTORIES
#######################################
echo "Creating sailpoint-iiq directory structure..."

mkdir -p ${IIQ_HOME}/{database,accessHistory,arcsightDataExport,cefDataExport,dataExport,JdbcExecutor,plugins}

#######################################
# DEPLOY WAR
#######################################
echo "Deploying IdentityIQ ${IIQ_VERSION}..."
cp "$IIQ_WAR_SRC" "$IIQ_WAR_DEST"

#######################################
# START TOMCAT
#######################################
echo "Starting Tomcat..."
${TOMCAT_DIR}/bin/startup.sh

#######################################
# VALIDATION
#######################################
echo ""
echo "===== VALIDATION ====="
java -version
ps -ef | grep -i tomcat | grep -v grep || echo "Tomcat not running"
ls -ld "$IIQ_HOME"
ls -l "$IIQ_WAR_DEST"

#######################################
# NEXT STEPS
#######################################
echo ""
echo "===== NEXT STEPS ====="
echo "1. Wait for Tomcat to explode the WAR:"
echo "   ${WEBAPPS_DIR}/identityiq"
echo ""
echo "2. Configure database (next script)"
echo "3. Update endpoints & credentials"
echo ""
echo "Access URL:"
echo "http://<EC2_PUBLIC_IP>:8080/identityiq"
echo ""
echo "IdentityIQ 8.5 installation completed."
