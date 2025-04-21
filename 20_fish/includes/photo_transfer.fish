# ======================================== Header ========================================
function impl_mixin_deps
   set -l this_dir (dirname (realpath (status current-filename)))
   echo $this_dir/json_settings.fish
   echo $this_dir/util.fish
end

# ============================================================================================================

function photo-get-canonical-filename --argument-names path
   set -l canonical_basename_prefix IMG
   set -l out       (exiftool -DateTimeOriginal -SubSecTimeOriginal -TimeZone -ImageUniqueID -dateFormat '%Y.%m.%d---%H:%M:%S' -json $path)
   set -l date_time (echo $out | jq -r '.[0] | select(.DateTimeOriginal   != null) | .DateTimeOriginal')
   set -l millisecs (echo $out | jq -r '.[0] | select(.SubSecTimeOriginal != null) | .SubSecTimeOriginal')
   set -l timezone  (echo $out | jq -r '.[0] | select(.TimeZone           != null) | .TimeZone')
   set -l unique_id (echo $out | jq -r '.[0] | select(.ImageUniqueID      != null) | .ImageUniqueID')
   if test -z "$date_time" -o -z "$millisecs" -o -z "$timezone" -o -z "$unique_id"
      return
   end

   echo $canonical_basename_prefix---$date_time.$millisecs$timezone---$unique_id.(impl_get_extension $path)
end

function photo-canonicalise-sinlge-file --argument-names path dst_dir
   set -l new_filename (photo-get-canonical-filename $path)
   if test -z "$new_filename"
      echo "Ignoring $path, could not read EXIF"
      return
   end
   if test -z "$dst_dir"
      set dst_dir (impl_get_path $path)
   end
   set -l new_path $dst_dir/$new_filename
   # Do not overwrite the destination if it already exists:
   RunVerbosely cp --update=none "$path" "$new_path"
   # RunVerbosely mv --no-clobber "$path" "$new_path"
   if test -f $path.xmp
      RunVerbosely cp --update=none "$path.xmp" "$new_path.xmp"
      # RunVerbosely mv --no-clobber "$path.xmp" "$new_path.xmp"
   end
end

function photo-canonicalise-incoming --argument-names src_dir dst_dir
   find $src_dir -type f -print0 | xargs -0 -P (nproc) -I {} fish -c "photo-canonicalise-sinlge-file '{}' $dst_dir"
end




function photo-format-sd
   argparse "dd" "dev=" -- $argv || return
   if not set -q _flag_dev
      echo "Specify dev. Exiting..."
      return
   end
   set -l dst_sd_label (json_settings::get_val --key "PhotoUtils.SDLabelDst")
   if test -z "$dst_sd_label"
      echo "PhotoUtils.SDLabelDst is not set"
      return
   end

   set part $_flag_dev"1"
   RunVerbosely sudo umount $part
   if set -q _flag_dd
      RunVerbosely sudo dd if=/dev/zero of=$_flag_dev bs=4M status=progress
   end
   RunVerbosely sudo sync
   RunVerbosely sudo parted --script $_flag_dev mklabel msdos
   RunVerbosely sudo parted --script -a opt $_flag_dev mkpart primary 0% 100%
   echo -e "t\n7\nw" | RunVerbosely sudo fdisk $_flag_dev
   RunVerbosely sudo mkfs.exfat -L $dst_sd_label $_flag_dev"1"
   RunVerbosely sudo sync
end



function photo-transfer
   argparse "format-only" "dd" -- $argv || return

   # Let's find the device with the label:
   set dev
   set part
   set -l src_sd_label (json_settings::get_val --key "PhotoUtils.SDLabelSrc")
   if test -z "$src_sd_label"
      echo "PhotoUtils.SDLabelSrc is not set"
      return
   end

   echo -e (set_color brblack)"Looking for /dev/sdX device with the label $src_sd_label..."(set_color normal)
   # set fish_trace 1
   for device in /dev/sd*
      # Check if the device is a disk and not a partition
      if test -z (string match -r '/dev/sd[a-z]+$' $device)
         continue
      end
      set -l actual_label (lsblk --json -f $device | jq -r '.blockdevices[0].children[0].label')
      if test "$actual_label" = "$src_sd_label"
         echo "Found device: "(set_color bryellow)$device(set_color normal)" with the label: "(set_color bryellow)$src_sd_label(set_color normal)
         read -P "Press 'y' key to continue, or any other key to exit: " answer || return
         if test "$answer" != "y"
            echo "exiting..."
            return
         end
         set dev $device
         set part $dev"1"
         break
      end
   end
   if test -z "$dev"
      echo "Failed to find a device with the label: $src_sd_label"
      return
   end
   echo -e "\nWorking with the device $dev...\n"

   # We were asked to transfer as well:
   if not set -q _flag_format_only
      set photo_incoming_dir (json_settings::get_val --key "PhotoUtils.IncomingDir")
      if test -z "$photo_incoming_dir"
         echo "PhotoUtils.IncomingDir is not set"
         return
      end

      RunVerbosely sudo mkdir -p $photo_incoming_dir || return 1
      RunVerbosely sudo chown -R (whoami):(whoami) $photo_incoming_dir
      InstallIfNeeded exiftool   exiftool
      InstallIfNeeded jq         jq
      InstallIfNeeded mkfs.exfat exfatprogs

      set tmp_dir (RunVerbosely sudo mktemp -d /media/photo-transfer-XXXXX)
      RunVerbosely sudo mount -o uid=(id -u) $part $tmp_dir

      echo (set_color bryellow)"Canonicalising filenames in the dir: $tmp_dir..."(set_color normal)
      photo-canonicalise-incoming $tmp_dir "$photo_incoming_dir"
      # echo (set_color bryellow)"Moving files from $tmp_dir to $photo_incoming_dir..."(set_color normal)
      # find $tmp_dir -type f -print0 | xargs -0 -P (nproc) -I {} mv --no-clobber "{}" "$photo_incoming_dir"
   end

   read -P "Check the dir: $tmp_dir and press 'y' key to umount and format, or any other key to exit: " answer || return
   if test "$answer" != "y"
      echo "exiting..."
      return
   end

   photo-format-sd $_flag_dd --dev $dev
end
