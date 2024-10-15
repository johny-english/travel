# ======================================== Header ========================================
function impl_mixin_deps
   set -l this_dir (dirname (realpath (status current-filename)))
   echo $this_dir/util.fish
end


# ============================================================================================================

set PREFIX      eph
set PARENT_VG   ubuntu-vg # list them with sudo vgs
set MOUNT_POINT /home

function eph-umount
   argparse "name=" "size=" -- $argv || return 1
   if not set -q _flag_name
      echo "Specify --name <name of your storge>"
      return 1
   end
   set -l lvname $PREFIX-$_flag_name
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
   argparse "name=" -- $argv || return 1
   if not set -q _flag_name
      echo "Specify --name <name of your storge>"
      return 1
   end
   set -l lvname $PREFIX-$_flag_name
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
   set -l lvname $PREFIX-$_flag_name
   if not set -q _flag_size
      echo "Specify --size 100G"
      return 1
   end
   RunVerbosely sudo lvcreate -L $_flag_size -n $lvname $PARENT_VG || return 1
   RunVerbosely sudo        /dev/$PARENT_VG/$lvname  || return 1
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
   set -l lvname $PREFIX-$_flag_name
   eph-umount --name $_flag_name
   RunVerbosely sudo dd if=/dev/zero of=/dev/$PARENT_VG/$lvname bs=1M count=16 status=progress
   # RunVerbosely sudo cryptsetup luksErase /dev/$PARENT_VG/$lvname
   RunVerbosely sudo lvremove /dev/$PARENT_VG/$lvname
end


function eph-list
   InstallIfNeeded rg ripgrep
   # InstallIfNeeded jq jq
   # sudo lvs --reportformat json | jq -r ".report[] | .lv[] | select(.vg_name == \"$PARENT_VG\") | .lv_name" | rg "^$PREFIX-"
   sudo lvs | rg "(^ *$PREFIX-)([^ ]+)( .*)" -or '$2: $1$2$3'
end
