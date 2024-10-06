# ======================================== Header ========================================
function impl_mixin_deps
   set -l this_dir (dirname (realpath (status current-filename)))
end
# ========================================================================================




# From https://github.com/oh-my-fish/oh-my-fish/blob/master/docs/Themes.md#bobthefish
set -g theme_display_git yes
set -g theme_display_git_dirty_verbose yes
set -g theme_display_git_stashed_verbose yes
set -g theme_display_git_default_branch yes
set -g theme_git_default_branches master main


# Set to yes to make it slower (but more feature-rich):
set -g theme_display_git_dirty no
set -g theme_git_worktree_support no
set -g theme_display_git_untracked no
set -g theme_display_git_ahead_verbose yes
