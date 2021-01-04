#!/bin/bash
# Copyright (c) 2015 - 2020 DisplayLink (UK) Ltd.

export LC_ALL=C
SELF=$0
COREDIR=/opt/displaylink
LOGSDIR=/var/log/displaylink
PRODUCT="DisplayLink Linux Software"
VERSION=5.3.1.34
ACTION=install
XORG_RUNNING=true

install_evdi()
{
  TARGZ="$1"
  MODVER="$2"
  ERRORS="$3"

  local EVDI
  EVDI=$(mktemp -d)
  if ! tar xf "$TARGZ" -C "$EVDI"; then
    echo "Unable to extract $TARGZ to $EVDI" > "$ERRORS"
    return 1
  fi

  echo "[[ Installing EVDI DKMS module ]]"
  (
    dkms install "${EVDI}/module"
    local retval=$?

    if [ $retval == 3 ]; then
      echo "EVDI DKMS module already installed."
    elif [ $retval != 0 ] ; then
      echo "Failed to install evdi/$MODVER to the kernel tree." > "$ERRORS"
      return 1
    fi
  ) || return 1
  echo "[[ Installing module configuration files ]]"
  cat > /etc/modules-load.d/evdi.conf <<EOF
evdi
EOF
  cat > /etc/modprobe.d/evdi.conf <<EOF
options evdi initial_device_count=4
EOF



  echo "[[ Installing EVDI library ]]"
  (
    cd "${EVDI}/library" || return 1

    if ! make; then
      echo "Failed to build evdi/$MODVER library." > "$ERRORS"
      return 1
    fi

    if ! cp -f libevdi.so "$COREDIR"; then
      echo "Failed to copy evdi/$MODVER library to $COREDIR." > "$ERRORS"
      return 1
    fi

    chmod 0755 "$COREDIR/libevdi.so"
  ) || return 1
}

uninstall_evdi_module()
{
  TARGZ="$1"

  local EVDI
  EVDI=$(mktemp -d)
  if ! tar xf "$TARGZ" -C "$EVDI"; then
    echo "Unable to extract $TARGZ to $EVDI"
    return 1
  fi

  (
    cd "${EVDI}/module" || return 1
    make uninstall_dkms
  )
}

is_32_bit()
{
  [ "$(getconf LONG_BIT)" == "32" ]
}

is_armv7()
{
  grep -qi armv7 /proc/cpuinfo
}

add_upstart_script()
{
  cat > /etc/init/displaylink-driver.conf <<EOF
description "DisplayLink Driver Service"
# Copyright (c) 2015 - 2019 DisplayLink (UK) Ltd.

start on login-session-start
stop on desktop-shutdown

# Restart if process crashes
respawn

# Only attempt to respawn 10 times in 5 seconds
respawn limit 10 5

chdir /opt/displaylink

pre-start script
    . /opt/displaylink/udev.sh

    if [ "\$(get_displaylink_dev_count)" = "0" ]; then
        stop
        exit 0
    fi
end script

script
    [ -r /etc/default/displaylink ] && . /etc/default/displaylink
    modprobe evdi || (dkms install \$(ls -t /usr/src | grep evdi | head -n1  | sed -e "s:-:/:") && modprobe evdi)
    exec /opt/displaylink/DisplayLinkManager
end script
EOF

  chmod 0644 /etc/init/displaylink-driver.conf
}

add_systemd_service()
{
  cat > /lib/systemd/system/displaylink-driver.service <<EOF
[Unit]
Description=DisplayLink Driver Service
After=display-manager.service
Conflicts=getty@tty7.service

[Service]
ExecStartPre=/bin/sh -c 'modprobe evdi || (dkms install \$(ls -t /usr/src | grep evdi | head -n1  | sed -e "s:-:/:") && modprobe evdi)'
ExecStart=/opt/displaylink/DisplayLinkManager
Restart=always
WorkingDirectory=/opt/displaylink
RestartSec=5

EOF

  chmod 0644 /lib/systemd/system/displaylink-driver.service
}

add_runit_service()
{
  mkdir -p /etc/sv/displaylink-driver/log /var/log/displaylink
  cat > /etc/sv/displaylink-driver/run <<EOF
#!/bin/sh
cd /opt/displaylink
modprobe evdi || (dkms install \$(ls -t /usr/src | grep evdi | head -n1  | sed -e "s:-:/:") && modprobe evdi)
exec /opt/displaylink/DisplayLinkManager

EOF

cat > /etc/sv/displaylink-driver/log/run <<EOF
#!/bin/sh
exec svlogd -tt /var/log/displaylink

EOF

  chmod -R 0755 /etc/sv/displaylink-driver
  chmod 0755 /var/log/displaylink
}

remove_upstart_service()
{
  driver_name="displaylink-driver"
  if grep -sqi displaylink /etc/init/dlm.conf; then
    driver_name="dlm"
  fi
  echo "Stopping displaylink-driver upstart job"
  stop ${driver_name}
  rm -f /etc/init/${driver_name}.conf
}

remove_systemd_service()
{
  driver_name="displaylink-driver"
  if grep -sqi displaylink /lib/systemd/system/dlm.service; then
    driver_name="dlm"
  fi
  echo "Stopping ${driver_name} systemd service"
  systemctl stop ${driver_name}.service
  systemctl disable ${driver_name}.service
  rm -f /lib/systemd/system/${driver_name}.service
}

remove_runit_service()
{
  driver_name="displaylink-driver"
  echo "Stopping ${driver_name} runit service"
  sv stop displaylink-driver
  rm -f /var/service/${driver_name}
  rm -rf /etc/sv/${driver_name}
}

add_pm_script()
{
  cat > $COREDIR/suspend.sh <<EOF
#!/bin/bash
# Copyright (c) 2015 - 2019 DisplayLink (UK) Ltd.

suspend_displaylink-driver()
{
  #flush any bytes in pipe
  while read -n 1 -t 1 SUSPEND_RESULT < /tmp/PmMessagesPort_out; do : ; done;

  #suspend DisplayLinkManager
  echo "S" > /tmp/PmMessagesPort_in

  if [ -p /tmp/PmMessagesPort_out ]; then
    #wait until suspend of DisplayLinkManager finish
    read -n 1 -t 10 SUSPEND_RESULT < /tmp/PmMessagesPort_out
  fi
}

resume_displaylink-driver()
{
  #resume DisplayLinkManager
  echo "R" > /tmp/PmMessagesPort_in
}

EOF

  if [ "$1" = "upstart" ]
  then
    cat >> $COREDIR/suspend.sh <<EOF
case "\$1" in
  thaw)
    resume_displaylink-driver
    ;;
  hibernate)
    suspend_displaylink-driver
    ;;
  suspend)
    suspend_displaylink-driver
    ;;
  resume)
    resume_displaylink-driver
    ;;
esac

EOF
  elif [ "$1" = "systemd" ]
  then
    cat >> $COREDIR/suspend.sh <<EOF
main_systemd()
{
  case "\$1/\$2" in
  pre/*)
    suspend_displaylink-driver
    ;;
  post/*)
    resume_displaylink-driver
    ;;
  esac
}
main_pm()
{
  case "\$1" in
    suspend|hibernate)
      suspend_displaylink-driver
      ;;
    resume|thaw)
      resume_displaylink-driver
      ;;
  esac
  true
}

DIR="\$(cd \$(dirname "\$0") && pwd)"

if [[ "\$DIR" =~ "systemd" ]]; then
  main_systemd "\$@"
elif [[ "\$DIR" =~ "pm" ]]; then
  main_pm "\$@"
fi

EOF
  elif [ "$1" = "runit" ]
  then
    cat >> $COREDIR/suspend.sh <<EOF
case "\$ZZZ_MODE" in
  noop)
    suspend_displaylink-driver
    ;;
  standby)
    suspend_displaylink-driver
    ;;
  suspend)
    suspend_displaylink-driver
    ;;
  hibernate)
    suspend_displaylink-driver
    ;;
  resume)
    resume_displaylink-driver
    ;;
  *)
    echo "Unknown ZZZ_MODE \$ZZZ_MODE" >&2
    exit 1
    ;;
esac

EOF
  fi

  chmod 0755 $COREDIR/suspend.sh
  if [ "$1" = "upstart" ]
  then
    ln -sf $COREDIR/suspend.sh /etc/pm/sleep.d/displaylink.sh
  elif [ "$1" = "systemd" ]
  then
    ln -sf $COREDIR/suspend.sh /lib/systemd/system-sleep/displaylink.sh
    if [ -d "/etc/pm/sleep.d" ];
    then
      ln -sf $COREDIR/suspend.sh /etc/pm/sleep.d/10_displaylink
    fi
  elif [ "$1" = "runit" ]
  then
    if [ -d "/etc/zzz.d" ]
    then
      ln -sf $COREDIR/suspend.sh /etc/zzz.d/suspend/displaylink.sh
      cat >> /etc/zzz.d/resume/displaylink.sh <<EOF
#!/bin/sh
ZZZ_MODE=resume $COREDIR/suspend.sh

EOF
      chmod 0755 /etc/zzz.d/resume/displaylink.sh
    fi
  fi
}

remove_pm_scripts()
{
  rm -f /etc/pm/sleep.d/displaylink.sh
  rm -f /etc/pm/sleep.d/10_displaylink
  rm -f /lib/systemd/system-sleep/displaylink.sh
  rm -f /etc/zzz.d/suspend/displaylink.sh /etc/zzz.d/resume/displaylink.sh
}

cleanup()
{
  rm -rf $COREDIR
  rm -rf $LOGSDIR
  rm -f /usr/bin/displaylink-installer
  rm -f ~/.dl.xml
  rm -f /root/.dl.xml
  rm -f /etc/modprobe.d/evdi.conf
  rm -rf /etc/modules-load.d/evdi.conf
}

binary_location()
{
  if is_armv7; then
    echo "arm-linux-gnueabihf"
  else
    local PREFIX="x64"
    local POSTFIX="ubuntu-1604"

    is_32_bit && PREFIX="x86"
    echo "$PREFIX-$POSTFIX"
  fi
}

install()
{
  echo -e "\nInstalling\n"

  mkdir -p $COREDIR
  mkdir -p $LOGSDIR
  chmod 0755 $COREDIR
  chmod 0755 $LOGSDIR

  cp -f "$SELF" "$COREDIR"
  ln -sf "$COREDIR/$(basename "$SELF")" /usr/bin/displaylink-installer
  chmod 0755 /usr/bin/displaylink-installer

  echo "[ Installing EVDI ]"

  local ERRORS
  ERRORS=$(mktemp)
  finish() {
    rm -f "$ERRORS"
  }
  trap finish EXIT

  if ! install_evdi "evdi.tar.gz" "$VERSION" "$ERRORS"; then
    echo "ERROR: "$(< "$ERRORS") >&2
    cleanup
    exit 1
  fi

  local BINS
  BINS=$(binary_location)
  local DLM
  DLM="$BINS/DisplayLinkManager"
  local LIBUSB
  LIBUSB="$BINS/libusb-1.0.so.0.1.0"

  cp -f 'evdi.tar.gz' "$COREDIR"

  echo "[ Installing $DLM ]"
  [ -x "$DLM" ] && cp -f "$DLM" "$COREDIR"

  echo "[ Installing libraries ]"
  [ -f "$LIBUSB" ] && cp -f "$LIBUSB" "$COREDIR"
  ln -sf "$COREDIR/libusb-1.0.so.0.1.0" "$COREDIR/libusb-1.0.so.0"
  ln -sf "$COREDIR/libusb-1.0.so.0.1.0" "$COREDIR/libusb-1.0.so"

  chmod 0755 $COREDIR/DisplayLinkManager
  chmod 0755 $COREDIR/libusb*.so*

  echo "[ Installing firmware packages ]"
  cp -f ./*.spkg $COREDIR
  chmod 0644 $COREDIR/*.spkg

  echo "[ Installing licence file ]"
  cp -f LICENSE $COREDIR
  chmod 0644 $COREDIR/LICENSE
  if [ -f 3rd_party_licences.txt ]; then
    cp -f 3rd_party_licences.txt $COREDIR
    chmod 0644 $COREDIR/3rd_party_licences.txt
  fi

  source udev-installer.sh
  displaylink_bootstrap_script="$COREDIR/udev.sh"
  create_bootstrap_file "$SYSTEMINITDAEMON" "$displaylink_bootstrap_script"

  echo "[ Adding udev rule for DisplayLink DL-3xxx/4xxx/5xxx/6xxx devices ]"
  create_udev_rules_file /etc/udev/rules.d/99-displaylink.rules
  $XORG_RUNNING || udevadm control -R
  $XORG_RUNNING || udevadm trigger

  echo "[ Adding upstart and powermanager sctripts ]"
  if [ "upstart" == "$SYSTEMINITDAEMON" ]; then
    add_upstart_script
    add_pm_script "upstart"
  elif [ "systemd" == "$SYSTEMINITDAEMON" ]; then
    add_systemd_service
    add_pm_script "systemd"
  elif [ "runit" == "$SYSTEMINITDAEMON" ]; then
    add_runit_service
    add_pm_script "runit"
  fi

  $XORG_RUNNING || trigger_udev_if_devices_connected

  $XORG_RUNNING || $displaylink_bootstrap_script START

  echo -e "\nPlease read the FAQ"
  echo "http://support.displaylink.com/knowledgebase/topics/103927-troubleshooting-ubuntu"

  echo -e "\nInstallation complete!"
  echo -e "\nPlease reboot your computer if intending to use Xorg."
  $XORG_RUNNING || exit 0
  read -p 'Xorg is running. Do you want to reboot now? (Y/n)' CHOICE
  [[ ${CHOICE:-Y} =~ ^[Nn]$ ]] && exit 0
  reboot
}

uninstall()
{
  echo -e "\nUninstalling\n"

  echo "[ Removing EVDI from kernel tree, DKMS, and removing sources. ]"
  cd "$(dirname $(realpath "${BASH_SOURCE[0]}"))"
  uninstall_evdi_module "evdi.tar.gz"
  cd -

  if [ "upstart" == "$SYSTEMINITDAEMON" ]; then
    remove_upstart_service
  elif [ "systemd" == "$SYSTEMINITDAEMON" ]; then
    remove_systemd_service
  elif [ "runit" == "$SYSTEMINITDAEMON" ]; then
    remove_runit_service
  fi

  echo "[ Removing suspend-resume hooks ]"
  remove_pm_scripts

  echo "[ Removing udev rule ]"
  rm -f /etc/udev/rules.d/99-displaylink.rules
  udevadm control -R
  udevadm trigger

  echo "[ Removing Core folder ]"
  cleanup

  echo -e "\nUninstallation steps complete."
  if [ -f /sys/devices/evdi/version ]; then
    echo "Please note that the evdi kernel module is still in the memory."
    echo "A reboot is required to fully complete the uninstallation process."
  fi
}

missing_requirement()
{
  echo "Unsatisfied dependencies. Missing component: $1." >&2
  echo "This is a fatal error, cannot install $PRODUCT." >&2
  exit 1
}

version_lt()
{
  local left
  left=$(echo "$1" | cut -d. -f-2)
  local right
  right=$(echo "$2" | cut -d. -f-2)

  local greater
  greater=$(echo -e "$left\n$right" | sort -Vr | head -1)

  [ "$greater" != "$left" ]
}

install_dependencies()
{
  hash apt 2>/dev/null || return
  install_dependencies_apt
}

check_libdrm()
{
  hash apt 2>/dev/null || return
  apt list -qq --installed libdrm-dev 2>/dev/null | grep -q libdrm-dev
}

apt_ask_for_dependencies()
{
  apt --simulate install dkms libdrm-dev 2>&1 |  grep  "^E: " > /dev/null && return 1
  apt --simulate install dkms libdrm-dev | grep -v '^Inst\|^Conf'
}

apt_ask_for_update()
{
  echo "Need to update package list."
  read -p 'apt update? [Y/n] ' CHOICE
  [[ "${CHOICE:-Y}" == "${CHOICE#[Yy]}" ]] && return 1
  apt update
}

install_dependencies_apt()
{
  hash dkms 2>/dev/null
  local install_dkms=$?
  apt list -qq --installed libdrm-dev 2>/dev/null | grep -q libdrm-dev
  local install_libdrm=$?

  if [ "$install_dkms" != 0 ] || [ "$install_libdrm" != 0 ]; then
    echo "[ Installing dependencies ]"
    apt_ask_for_dependencies || (apt_ask_for_update && apt_ask_for_dependencies) || check_requirements
    read -p 'Do you want to continue? [Y/n] ' CHOICE
    [[ "${CHOICE:-Y}" == "${CHOICE#[Yy]}" ]] && exit 0

    apt install -y dkms libdrm-dev || check_requirements
  fi
}

check_requirements()
{
  # DKMS
  hash dkms 2>/dev/null || missing_requirement "DKMS"

  # libdrm
  check_libdrm || missing_requirement "libdrm"

  # Required kernel version
  KVER=$(uname -r)
  KVER_MIN="4.15"
  version_lt "$KVER" "$KVER_MIN" && missing_requirement "Kernel version $KVER is too old. At least $KVER_MIN is required"

  # Linux headers
  [ ! -d "/lib/modules/$KVER/build" ] && missing_requirement "Linux headers for running kernel, $KVER"
}

usage()
{
  echo
  echo "Installs $PRODUCT, version $VERSION."
  echo "Usage: $SELF [ install | uninstall ]"
  echo
  echo "The default operation is install."
  echo "If unknown argument is given, a quick compatibility check is performed but nothing is installed."
  exit 1
}

detect_init_daemon()
{
    INIT=$(readlink /proc/1/exe)
    if [ "$INIT" == "/sbin/init" ]; then
        INIT=$(/sbin/init --version)
    fi

    [ -z "${INIT##*upstart*}" ] && SYSTEMINITDAEMON="upstart"
    [ -z "${INIT##*systemd*}" ] && SYSTEMINITDAEMON="systemd"
    [ -z "${INIT##*runit*}" ] && SYSTEMINITDAEMON="runit"

    if [ -z "$SYSTEMINITDAEMON" ]; then
        echo "ERROR: the installer script is unable to find out how to start DisplayLinkManager service automatically on your system." >&2
        echo "Please set an environment variable SYSTEMINITDAEMON to 'upstart', 'systemd' or 'runit' before running the installation script to force one of the options." >&2
        echo "Installation terminated." >&2
        exit 1
    fi
}

detect_distro()
{
  if hash lsb_release 2>/dev/null; then
    local R
    R=$(lsb_release -d -s)

    echo "Distribution discovered: $R"
    [ -z "${R##Ubuntu 14.*}" ] && return
    [ -z "${R##Ubuntu 15.*}" ] && return
    [ -z "${R##Ubuntu 16.04*}" ] && return
  else
    echo "WARNING: This is not an officially supported distribution." >&2
    echo "Please use DisplayLink Forum for getting help if you find issues." >&2
  fi
}

check_preconditions()
{
  local SESSION_NO=$(loginctl | awk "/$(logname)/ {print \$1; exit}")
  XORG_RUNNING=$(loginctl show-session "$SESSION_NO" -p Type | awk -F '=' '{if ($2 == "x11") {print "true"} else {print "false"}}')
  local DL_CONNECTED=false
  lsusb | grep DisplayLink > /dev/null && DL_CONNECTED=true
  if "$DL_CONNECTED" && "$XORG_RUNNING"; then
    echo "Detected running Xorg session and connected docking station" >&2
    echo "Please disconnect the dock before continuing" >&2
    echo "Installation terminated." >&2
    exit 1
  fi
  if [ -f /sys/devices/evdi/version ]; then
    local V
    V=$(< /sys/devices/evdi/version)

    echo "WARNING: Version $V of EVDI kernel module is already running." >&2
    if [ -d $COREDIR ]; then
      echo "Please uninstall all other versions of $PRODUCT before attempting to install." >&2
    else
      echo "Please reboot before attempting to re-install $PRODUCT." >&2
    fi
    echo "Installation terminated." >&2
    exit 1
  fi
}

if [ "$(id -u)" != "0" ]; then
  echo "You need to be root to use this script." >&2
  exit 1
fi

echo "$PRODUCT $VERSION install script called: $*"
[ -z "$SYSTEMINITDAEMON" ] && detect_init_daemon || echo "Trying to use the forced init system: $SYSTEMINITDAEMON"
detect_distro

while [ -n "$1" ]; do
  case "$1" in
    install)
      ACTION="install"
      ;;

    uninstall)
      ACTION="uninstall"
      ;;
    *)
      usage
      ;;
  esac
  shift
done

if [ "$ACTION" == "install" ]; then
  install_dependencies
  check_requirements
  check_preconditions
  install
elif [ "$ACTION" == "uninstall" ]; then
  check_requirements
  uninstall
fi
