# ======================================== Header ========================================
function impl_mixin_deps
   set -l this_dir (dirname (realpath (status current-filename)))
end

# ============================================================================================================

function json_settings::get_dir
   set -l default_path $HOME/.config/fish/conf.d
   if test -z "$FISH_JSON_SETTINGS_DIR"
      echo $default_path
   else
      echo "$FISH_JSON_SETTINGS_DIR"
   end
end

function json_settings::get_path --argument-names file_name
   if test -z "$file_name"
      set file_name "settings.json"
   end
   echo (json_settings::get_dir)/$file_name
end


function json_settings::get_val_from_file # --argument-names file namespace key
   argparse --ignore-unknown "path=" "env_prefix=" "ns=" "key=" "multiple" -- $argv || return
   # json_settings::get_val_from_file --path asdf --env_prefix aa.bb.cc --ns mm.nn.oo --key yy.zz
   # .aa.bb.cc.mm.nn.oo.yy.zz
   # .aa.bb.cc.mm.nn.yy.zz
   # .aa.bb.cc.mm.yy.zz
   # .aa.bb.cc.yy.zz

   # .aa.bb.mm.nn.oo.yy.zz
   # .aa.bb.mm.nn.yy.zz
   # .aa.bb.mm.yy.zz
   # .aa.bb.yy.zz

   # .aa.mm.nn.oo.yy.zz
   # .aa.mm.nn.yy.zz
   # .aa.mm.yy.zz
   # .aa.yy.zz

   # .mm.nn.oo.yy.zz
   # .mm.nn.yy.zz
   # .mm.yy.zz
   # .yy.zz


   # Normalise the parts:
   # set fish_trace 1
   set -l env_prefix (string replace -r '^\.+' '' -- $_flag_env_prefix)
   set -l env_prefix (string replace -r '\.+$' '' -- $env_prefix)
   set -l initial_ns  (string replace -r '^\.+' '' -- $_flag_ns)
   set -l initial_ns (string replace -r '\.+$' '' -- $initial_ns)
   set -l key  (string replace -r '^\.+' '' -- $_flag_key)
   set -l key (string replace -r '\.+$' '' -- $key)
   if test -n "$initial_ns"
      set initial_ns "."$initial_ns
   end
   if test -n "$env_prefix"
      set env_prefix "."$env_prefix
   end
   if test -n "$key"
      set key "."$key
   end


   # Create composite query that looks like this:
   # '(.Imp.Docs.ImageKile.HostWorkDirs, .Imp.ImageKile.HostWorkDirs, .Docs.ImageKile.HostWorkDirs, .ImageKile.HostWorkDirs) | select(. != null) | limit(1; .)'
   set query

   while true
      set ns $initial_ns
      while true
         set -l full_key $env_prefix$ns$key
         # echo $full_key
         if test -z "$query"
            set query "$full_key"
         else
            set query "$query, $full_key"
         end

         if test -z "$ns"
            break
         end
         set ns (string replace -r '\.[^.]+$' '' -- $ns) # Chop off the last segment
      end

      if test -z "$env_prefix"
         break
      end
      set env_prefix (string replace -r '\.[^.]+$' '' -- $env_prefix) # Chop off the last segment
   end

   set query "($query) | select(. != null) | limit(1; .)"
   if set -q _flag_multiple
      # Expand array into raw lines:
      set query "$query | .[]"
   end

   # jq -r "$query" $_flag_path
   set -l res (jq -r "$query" $_flag_path | string split '\n')
   # count $res
   # echo -e "$res"
   printf "%s\n" $res
   # echo -n "Looked up the keys: $query in $_flag_path: result: $res" >> /dev/stderr
end


function json_settings::get_val # --argument-names defaults_file_path namespace key
   argparse --ignore-unknown "def=" "ns=" "key=" -- $argv || return
   # Example:
   # Given:
   #  * namespace: Personal
   #  * key: HiDpi.QT_FONT_DPI
   #  * assuming impl_env_prefix_in_cfg prints "Imp"
   #  * and a file,
   # we will try to get
   # jq ".Imp.QtCreator.HiDpi.QT_FONT_DPI" file_path, in case it is empty:
   # jq ".Imp.HiDpi.QT_FONT_DPI" file_path, in case it is empty:
   # jq ".HiDpi.QT_FONT_DPI" file_path
   # and the same with the default settings.json
   # In other words, we prepend the value of impl_env_prefix_in_cfg
   # which give us the most specific key, and then we go to "parent" scopes, looking for
   # the given key (HiDpi.QT_FONT_DPI)

   # set fish_trace 1

   set -l env_prefix (impl_env_prefix_in_cfg)
   # set -l env_prefix (string replace -r '\.+$' '' -- $env_prefix)
   # if test -n "$env_prefix" -a -n "$_flag_ns"
   #    set _flag_ns $env_prefix"."$_flag_ns
   # else if test -n "$env_prefix"
   #    set _flag_ns $env_prefix
   # end


   if test -e (json_settings::get_path)
      set -l res (json_settings::get_val_from_file --path (json_settings::get_path) --env_prefix "$env_prefix" --ns "$_flag_ns" --key $_flag_key | head -n 1)
      if test -n "$res"
         eval "echo $res"
         return
      end
   end

   set -l res (json_settings::get_val_from_file --path $_flag_def --env_prefix "$env_prefix" --ns "$_flag_ns" --key $_flag_key)
   eval "echo $res"
end


function json_settings::get_vals # --argument-names defaults_file_path namespace key
   argparse --ignore-unknown "def=" "ns=" "key=" -- $argv || return
   set -l env_prefix (impl_env_prefix_in_cfg)
   if test -e (json_settings::get_path)
      set -l res (json_settings::get_val_from_file --path (json_settings::get_path) --env_prefix "$env_prefix" --ns "$_flag_ns" --key $_flag_key --multiple | string split '\n')
      if test -n "$res"
         for r in $res
            eval "echo \"$r\""
         end
         return
      end
   end

   for r in (json_settings::get_val_from_file --path $_flag_def --env_prefix "$env_prefix" --ns "$_flag_ns" --key $_flag_key --multiple)
      eval "echo \"$r\""
   end
end
