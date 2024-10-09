# ======================================== Header ========================================
function impl_get_install_fish_info
   set -l this_fn (basename (realpath (status current-filename)))
   set -l this_dir (dirname (realpath (status current-filename)))
   set -l REPO_ROOT_DIR $this_dir/..
   echo $REPO_ROOT_DIR/20_fish/install_fish.fish        # script to use for installation
   echo $REPO_ROOT_DIR/fish/$this_fn                    # env
   echo $REPO_ROOT_DIR/fish/env.json
end
function impl_mixin_deps
   set -l this_dir (dirname (realpath (status current-filename)))
   set -l REPO_ROOT_DIR $this_dir/..

   echo $REPO_ROOT_DIR/20_fish/includes/common_fish_setup.fish
   echo $REPO_ROOT_DIR/20_fish/includes/reinstall_fish_includes.fish
   echo $REPO_ROOT_DIR/20_fish/includes/bat.fish
   echo $REPO_ROOT_DIR/20_fish/includes/sysupgrade_simple.fish
   echo $REPO_ROOT_DIR/20_fish/includes/git_abbrs_functions.fish
   echo $REPO_ROOT_DIR/20_fish/includes/git_look_and_feel.fish
   echo $REPO_ROOT_DIR/20_fish/includes/docker_att.fish
   echo $REPO_ROOT_DIR/20_fish/includes/gpg_gen.fish
   echo $REPO_ROOT_DIR/20_fish/includes/photo_transfer.fish
end
function impl_config_fish
   set -l this_dir (dirname (realpath (status current-filename)))
   set -l REPO_ROOT_DIR $this_dir/..
   echo $REPO_ROOT_DIR/20_fish/config_add_rust_to_path.fish
end
function impl_fish_home_path
   echo $HOME
end
function impl_on_fish_install
end
function impl_env_prefix_in_cfg # This name will be prefixed to all --ns flag values
   echo ""
end
