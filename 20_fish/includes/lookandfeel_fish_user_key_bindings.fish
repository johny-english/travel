# ======================================== Header ========================================
function impl_mixin_deps
   set -l this_dir (dirname (realpath (status current-filename)))
end


# ========================================================================================
function fish_user_key_bindings
   bind \cH backward-kill-path-component
   bind \e\[3\;5~ kill-word
end
