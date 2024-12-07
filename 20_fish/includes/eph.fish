# ======================================== Header ========================================
function impl_mixin_deps
   set -l this_dir (dirname (realpath (status current-filename)))
   echo $this_dir/util.fish
end


# ============================================================================================================

set PREFIX eph
set STORAGE_PREFIX $PREFIX"s"
# set USER_PREFIX    ephu
set PARENT_VG      ubuntu-vg # list them with sudo vgs
set MOUNT_POINT    /home

function eph-umount
   argparse "name=" -- $argv || return 1
   if not set -q _flag_name
      echo "Specify --name <name of your storge>"
      return 1
   end
   set -l lvname $STORAGE_PREFIX-$_flag_name
   set -l to_kill (sudo lsof +f -- $MOUNT_POINT/$lvname | awk 'NR>1 {print $2}' | sort -u)
   if test -n "$to_kill"
      sudo kill -15 $to_kill
   end
   sleep 1
   set -l to_kill (sudo lsof +f -- $MOUNT_POINT/$lvname | awk 'NR>1 {print $2}' | sort -u)
   if test -n "$to_kill"
      sudo kill -9 $to_kill
   end
   RunVerbosely sudo umount /dev/mapper/$lvname
   sudo cryptsetup close $lvname
end


function eph-mount
   argparse "name=" "size=" -- $argv || return 1
   if not set -q _flag_name
      echo "Specify --name <name of your storge>"
      return 1
   end
   set -l lvname $STORAGE_PREFIX-$_flag_name
   RunVerbosely sudo cryptsetup open /dev/$PARENT_VG/$lvname $lvname
   RunVerbosely sudo mkdir -p $MOUNT_POINT/$lvname
   RunVerbosely sudo mount /dev/mapper/$lvname $MOUNT_POINT/$lvname
end


function eph-create
   argparse "name=" "size=" -- $argv || return 1
   if not set -q _flag_name
      echo "Specify --name <name of your storge>"
      return 1
   end
   set -l lvname $STORAGE_PREFIX-$_flag_name
   if not set -q _flag_size
      echo "Specify --size 100g"
      return 1
   end
   RunVerbosely sudo lvcreate -L $_flag_size -n $lvname $PARENT_VG || return 1
   RunVerbosely sudo cryptsetup luksFormat --verify-passphrase -q /dev/$PARENT_VG/$lvname  || return 1
   RunVerbosely sudo cryptsetup open /dev/$PARENT_VG/$lvname $lvname  || return 1
   RunVerbosely sudo mkfs.ext4 /dev/mapper/$lvname  || return 1
   RunVerbosely sudo mkdir -p $MOUNT_POINT/$lvname  || return 1
   RunVerbosely sudo mount /dev/mapper/$lvname $MOUNT_POINT/$lvname  || return 1
   RunVerbosely sudo chown -R (whoami):(whoami) $MOUNT_POINT/$lvname  || return 1
   echo "Done, umounting it..."
   eph-umount --name $_flag_name
end


function eph-eradicate
   argparse "name=" -- $argv || return 1
   if not set -q _flag_name
      echo "Specify --name <name of your storge>"
      return 1
   end
   set -l lvname $STORAGE_PREFIX-$_flag_name
   eph-umount --name $_flag_name
   RunVerbosely sudo dd if=/dev/zero of=/dev/$PARENT_VG/$lvname bs=1M count=16 status=progress
   # RunVerbosely sudo cryptsetup luksErase /dev/$PARENT_VG/$lvname
   RunVerbosely sudo lvremove --yes /dev/$PARENT_VG/$lvname
end


function eph-list
   InstallIfNeeded rg ripgrep
   # InstallIfNeeded jq jq
   # sudo lvs --reportformat json | jq -r ".report[] | .lv[] | select(.vg_name == \"$PARENT_VG\") | .lv_name" | rg "^$STORAGE_PREFIX-"
   sudo lvs | rg "(^ *eph[a-zA-Z]*-)([^ ]+)( .*)" -or '$2: $1$2$3'
   echo
   awk -F: '$3 >= 1000 {print $1}' /etc/passwd
end



function ephu-create
   argparse "name=" "size=" -- $argv || return 1
   if not set -q _flag_name
      echo "Specify --name <name of your storge>"
      return 1
   end
   set -l lvname $STORAGE_PREFIX-$_flag_name
   if not set -q _flag_size
      set size "10g"
   else
      set size $_flag_size
   end
   eph-create --name $_flag_name --size $size                                 || return 1
   eph-mount  --name $_flag_name                                              || return 1
   RunVerbosely sudo useradd -d $MOUNT_POINT/$lvname -s /bin/bash $_flag_name || return 1
   RunVerbosely echo $_flag_name:$_flag_name | sudo chpasswd
   RunVerbosely sudo cp -r /etc/skel/. $MOUNT_POINT/$lvname
   RunVerbosely sudo chown -R $_flag_name:$_flag_name $MOUNT_POINT/$lvname    || return 1
   eph-umount  --name $_flag_name                                             || return 1
end

function ephu-eradicate
   argparse "name=" "size=" -- $argv || return 1
   if not set -q _flag_name
      echo "Specify --name <name of your storge>"
      return 1
   end
   RunVerbosely loginctl terminate-user $_flag_name
   RunVerbosely sudo userdel $_flag_name
   eph-eradicate --name $_flag_name
end


function ephu-login
   argparse "name=" -- $argv || return 1
   if not set -q _flag_name
      echo "Specify --name <name of your storge>"
      return 1
   end
   eph-mount  --name $_flag_name   || return 1
   RunVerbosely sudo passwd -u $_flag_name
   /usr/lib/qt6/bin/qdbus org.kde.ksmserver /KSMServer org.kde.KSMServerInterface.openSwitchUserDialog
end


function ephu-logout
   argparse "name=" -- $argv || return 1
   if not set -q _flag_name
      echo "Specify --name <name of your storge>"
      return 1
   end
   RunVerbosely sudo loginctl kill-user --signal=15 $_flag_name
   RunVerbosely sudo loginctl terminate-user $_flag_name
   RunVerbosely sudo passwd -l $_flag_name
   eph-umount --name $_flag_name
end

# Resize volumes:
# sudo cryptsetup open /dev/ubuntu-vg/ephs-devel ephs-devel
# sudo lvresize --size 10G --resizefs ubuntu-vg/ephs-devel
# sudo lvresize --size +120g --resizefs ubuntu-vg/ephs-ph
