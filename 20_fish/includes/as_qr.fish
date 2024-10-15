# ======================================== Header ========================================
function impl_mixin_deps
   set -l this_dir (dirname (realpath (status current-filename)))
   echo $this_dir/util.fish
end
# ========================================================================================

function as_qr
   InstallIfNeeded feh feh
   InstallIfNeeded qrencode qrencode

   qrencode -o - | feh -FZ --force-aliasing -
end
