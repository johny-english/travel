# ======================================== Header ========================================
function impl_mixin_deps
   set -l this_dir (dirname (realpath (status current-filename)))
end


# ========================================================================================
function sysupgrade
   sudo apt update && sudo apt full-upgrade
end
