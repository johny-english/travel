# ======================================== Header ========================================
function impl_mixin_deps
   set -l this_dir (dirname (realpath (status current-filename)))
end

# ========================================================================================

function att --argument-names name uid
   if test -n "$uid"
      set u_arg -u $uid
      if test $uid -eq 0
         # Add --privileged: https://unix.stackexchange.com/questions/136690/how-can-i-substitute-lsof-inside-a-docker-native-not-lxc-based
         set u_arg $u_arg --privileged
      end
   end

   docker exec -it $u_arg $name /bin/fish
   if test $status -ne 0
      echo "Retrying with /bin/bash..."
      docker exec -it $u_arg $name /bin/bash
   end
end


function att_latest --argument-names uid
   set name (docker ps -l --format '{{ .Names }}')
   att $name $uid
end

# Completion for att, taken from http://fishshell.com/docs/current/index.html#completion-own
complete -c att -f
complete -c att -a "(docker ps --format '{{ .Names }}')"
