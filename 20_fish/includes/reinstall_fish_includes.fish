# ======================================== Header ========================================
function impl_mixin_deps
   set -l this_dir (dirname (realpath (status current-filename)))
end


# ========================================================================================

function reinstall-fish-includes
   set -l script_and_env (impl_get_install_fish_info)
   set -l script $script_and_env[1]
   set -l env_path $script_and_env[2]
   if test -z "$script" -o -z "$env_path"
      echo "Check that impl_get_install_fish_info outputs two lines: 1st with path to installation script and 2nd - path to environment to install"
      return
   end
   rm -rf (impl_fish_home_path)/.config/fish
   $script --env $env_path
   omf reload
end
