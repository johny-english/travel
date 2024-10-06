# ======================================== Header ========================================
function impl_get_install_fish_info
   set -l this_basename (basename (realpath (status current-filename)))
   echo "" # script to use for installation
   echo "" # env
   echo "" # json
end
function impl_mixin_deps
   set -l this_dir (dirname (realpath (status current-filename)))
   echo $this_dir/includes/common_fish_setup.fish
end
function impl_config_fish
end
function impl_fish_home_path
   echo $HOME # Run only from within docker, hence $HOME
end



# =======================================================================================
