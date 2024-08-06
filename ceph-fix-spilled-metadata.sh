#!/usr/bin/env bash

set -eu -o pipefail

ceph osd set noout
for OSD_NUM in $(ceph health detail --format json | jq --raw-output '.checks.BLUEFS_SPILLOVER.detail[].message' | grep -Po 'osd\.\K\d+'); do
  echo "Considering OSD $OSD_NUM";
  OSD_DIR="/var/lib/ceph/osd/ceph-${OSD_NUM}";
  if [ ! -d "$OSD_DIR" ]; then
    echo "$OSD_DIR does not exist on $(hostname), skipping"
    continue
  fi;
  echo "$OSD_DIR exists on $(hostname), running bluefs-bdev-migrate"
  set -x
  systemctl stop "ceph-osd-${OSD_NUM}.service"
  ceph-bluestore-tool bluefs-bdev-migrate --path "$OSD_DIR" --devs-source "$OSD_DIR/block" --dev-target "$OSD_DIR/block.db"
  systemctl start "ceph-osd-${OSD_NUM}.service";
  set +x
done
ceph osd unset noout
