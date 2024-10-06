# ======================================== Header ========================================
function impl_mixin_deps
   set -l this_dir (dirname (realpath (status current-filename)))
   echo $this_dir/lookandfeel_dracula_colours.fish
   echo $this_dir/lookandfeel_fish_user_key_bindings.fish
   echo $this_dir/lookandfeel_short_paths_in_prompt.fish
   echo $this_dir/lookandfeel_show_hostname.fish
   echo $this_dir/omf.fish
   echo $this_dir/util.fish
end
# ========================================================================================
