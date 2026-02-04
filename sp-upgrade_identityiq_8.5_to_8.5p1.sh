#!/bin/bash
set -e

#######################################
# PRE-UPGRADE NOTES & CONFIRMATION
#######################################
echo ""
echo "=================================================="
echo " SailPoint IdentityIQ 8.5 → 8.5p1 Upgrade"
echo "=================================================="
echo ""
echo "PRE-UPGRADE CHECKLIST:"
echo "1. Database backup has been taken"
echo "2. Tomcat is healthy"
echo "3. Patch directory exists:"
echo "   /home/ec2-user/sailpoint-iiq/iiq-8.5p1"
echo "4. Patch WAR exists:"
echo "   /home/ec2-user/sailpoint-iiq/iiq-8.5p1/identityiq.war"
echo ""
echo "This script will:"
echo "- Stop Tomcat"
echo "- Backup current IdentityIQ runtime"
echo "- Replace identityiq.war with 8.5p1"
echo "- Start Tomcat"
echo ""
read -p "Have you taken the DB backup and want to continue? (yes/no): " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
  echo ""
  echo "Upgrade aborted by user."
  exit 0
fi

#######################################
# VARIABLES (AUTHORITATIVE)
#######################################
USER_HOME=/home/ec2-user

TOMCAT_DIR=${USER_HOME}/apache-tomcat-9.0.115
WEBAPPS_DIR=${TOMCAT_DIR}/webapps

CURRENT_WAR=${WEBAPPS_DIR}/identityiq.war
CURRENT_APP=${WEBAPPS_DIR}/identityiq

IIQ_HOME=${USER_HOME}/sailpoint-iiq
PATCH_DIR=${IIQ_HOME}/iiq-8.5p1
PATCH_WAR_SRC=${PATCH_DIR}/identityiq.war

BACKUP_BASE=${USER_HOME}/backup
BACKUP_DIR=${BACKUP_BASE}/iiq-8.5_$(date +%Y%m%d_%H%M%S)

#######################################
# SAFETY CHECKS – FAIL FAST
#######################################
echo ""
echo "Validating upgrade prerequisites..."

[ -d "$CURRENT_APP" ] || {
  echo "ERROR: identityiq runtime directory not found:"
  echo "  $CURRENT_APP"
  exit 1
}

[ -f "$CURRENT_WAR" ] || {
  echo "ERROR: identityiq.war not found:"
  echo "  $CURRENT_WAR"
  exit 1
}

[ -d "$PATCH_DIR" ] || {
  echo "ERROR: Patch directory not found:"
  echo "  $PATCH_DIR"
  exit 1
}

[ -f "$PATCH_WAR_SRC" ] || {
  echo "ERROR: Patch WAR not found:"
  echo "  $PATCH_WAR_SRC"
  exit 1
}

echo "All validations passed."

#######################################
# STOP TOMCAT
#######################################
echo ""
echo "Stopping Tomcat..."
${TOMCAT_DIR}/bin/shutdown.sh || true
sleep 10

#######################################
# BACKUP CURRENT RUNTIME ONLY
#######################################
echo "Backing up current IdentityIQ runtime..."
mkdir -p "$BACKUP_DIR"

cp "$CURRENT_WAR" "$BACKUP_DIR/identityiq-8.5.war"
cp -r "$CURRENT_APP" "$BACKUP_DIR/identityiq-8.5"

echo "Backup completed:"
echo "  $BACKUP_DIR"

#######################################
# REMOVE CURRENT RUNTIME
#######################################
echo ""
echo "Removing current IdentityIQ runtime..."
rm -f "$CURRENT_WAR"
rm -rf "$CURRENT_APP"

#######################################
# DEPLOY PATCH WAR
#######################################
echo "Deploying IdentityIQ 8.5p1 WAR..."
cp "$PATCH_WAR_SRC" "$CURRENT_WAR"

#######################################
# START TOMCAT
#######################################
echo ""
echo "Starting Tomcat..."
${TOMCAT_DIR}/bin/startup.sh

#######################################
# POST-UPGRADE NOTES
#######################################
echo ""
echo "=================================================="
echo " Upgrade Initiated Successfully"
echo "=================================================="
echo ""
echo "Patch source used:"
echo "  $PATCH_WAR_SRC"
echo ""
echo "Monitor logs:"
echo "  ${TOMCAT_DIR}/logs/catalina.out"
echo ""
echo "Verify application:"
echo "  http://<EC2_PUBLIC_IP>:8080/identityiq"
echo ""
echo "Rollback available at:"
echo "  $BACKUP_DIR"
echo ""
echo "Upgrade script completed."
