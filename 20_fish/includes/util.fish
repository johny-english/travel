# ======================================== Header ========================================
function impl_mixin_deps
   set -l this_dir (dirname (realpath (status current-filename)))
end


# ========================================================================================
function impl_omit_first_n_args --argument-names n arguments
   if test (count $argv) -ge (math $n + 2)
      for arg in $argv[(math $n + 2)..(count $argv)]
         echo $arg
      end
   end
end



function impl_set_dict_key --argument-names dict_name key arguments
   set key (string replace --all / _ $key)
   set key (string replace --all - _ $key)
   set -g __dict__{$dict_name}__{$key} $argv[3..]
end
function impl_set_dict_key_U --argument-names dict_name key arguments
   set key (string replace --all / _ $key)
   set key (string replace --all - _ $key)
   set -U __dict__{$dict_name}__{$key} $argv[3..]
end
function impl_erase_dict_key --argument-names dict_name key
   set key (string replace --all / _ $key)
   set key (string replace --all - _ $key)
   set --erase __dict__{$dict_name}__{$key}
end
function impl_get_dict_key --argument-names dict_name key
   set key (string replace --all / _ $key)
   set key (string replace --all - _ $key)
   string split ' ' --  (eval echo \$__dict__{$dict_name}__{$key})
end



function RunVerbosely
   echo -e (set_color brblack)(string escape -- $argv)(set_color normal) 1>&2
   $argv
end

function InstallIfNeeded --argument-names cmd package
   if command -v $cmd >/dev/null
      return
   end
   echo -e (set_color brblack)"$cmd not found, installing $package..."(set_color normal)
   RunVerbosely sudo apt install -y $package
end


function impl_get_path_info --argument-names path -d 'Returns directory, basename, ext from the path'
    echo $path | sed 's/\(.*\)\/\(.*\)\.\(.*\)$/\1\n\2\n\3/'
end
function impl_get_extension --argument-names path -d 'Returns filename'
   set -l info (impl_get_path_info $path)
   echo "$info[3]"
end
function impl_get_filename --argument-names path -d 'Returns filename'
    set -l info (impl_get_path_info $path)
    echo "$info[2].$info[3]"
end
function impl_get_basename --argument-names path -d 'Returns basename'
    set -l info (impl_get_path_info $path)
    echo "$info[2]"
end
function impl_get_path --argument-names path -d 'Returns path'
    set -l info (impl_get_path_info $path)
    echo "$info[1]"
end



# Reset
set Color_Off   '\033[0m'
# Regular Colors
set Gray        '\033[0;90m'
set BrightGray  '\033[38;5;248m'
set Black       '\033[0;30m'
set Red         '\033[0;31m'
set Green       '\033[0;32m'
set Yellow      '\033[0;33m'
set Blue        '\033[0;34m'
set Purple      '\033[0;35m'
set Cyan        '\033[0;36m'
set White       '\033[0;37m'
# Bold
set BBlack      '\033[1;30m'
set BBrightGray '\033[1;38;5;248m'
set BGray       '\033[1;30m'
set BRed        '\033[1;31m'
set BGreen      '\033[1;32m'
set BYellow     '\033[1;33m'
set BBlue       '\033[1;34m'
set BPurple     '\033[1;35m'
set BCyan       '\033[1;36m'
set BWhite      '\033[1;37m'
# Underline
set UBlack      '\033[4;30m'
set URed        '\033[4;31m'
set UGreen      '\033[4;32m'
set UYellow     '\033[4;33m'
set UBlue       '\033[4;34m'
set UPurple     '\033[4;35m'
set UCyan       '\033[4;36m'
set UWhite      '\033[4;37m'
