# ======================================== Header ========================================
function impl_mixin_deps
   set -l this_dir (dirname (realpath (status current-filename)))
end
# ========================================================================================

abbr gb         'git branch -v'
abbr gc         'git checkout'
abbr gcb        'git checkout -b'
abbr gcp        'git cherry-pick'
abbr gp         "git push --set-upstream origin (git branch --show-current)"
abbr gs         'git status'
abbr gcm        "git commit"
# abbr gup-master 'gup master'
# abbr gup-main   'gup main'
# abbr gcms       "git commit -S -m"



# ============================================================================================================


function gup --argument-names branch --description 'Fetches upstream, merges changes from upstream/$branch to local $branch and pushes it'
   if test -z "$branch"
      set branch (git symbolic-ref --short refs/remotes/origin/HEAD | cut -d / -f 2) # origin/master or origin/main
   end
   git fetch upstream && git checkout $branch && git merge upstream/$branch && git push
end

function mycommits
   git log --author (git config user.email) $argv
end



# ============================================================================================================


function gbb --argument-names branch_regexp --description "Show branches status. Usage: gbb or gbb \"DS_SE2_master.*\" or gbb DS_SE2_master"
   # git log --decorate --simplify-by-decoration DS_YBD-21175-get-rid-of-memset --oneline
   # prints:
   # 8de3eb82c5c (DS_YBD-21175-get-rid-of-memset) Get rid of memset()                                              # <------ branch itself
   # 0b4ff222903 (origin/DS_SE2_master, DS_SE2_master) YBD-21175: Reland Use C++ user defined literals for sizes   # <------ first ancestor
   # ebbeb43cfc4 (HEAD -> master, origin/master, origin/HEAD) MANIFEST: [Jenkins CI] Update SW component versions  # <------ second ancestor
   # ffdb74fd3c9 (tag: 5.4.0-37286) Revert "YBD-21175: Use C++ user defined literals for sizes"                    # <------ third ancestor
   # 025a6364290 (tag: 5.4.0-37284, tag: 5.4.0-37283) YBD-21175: Use C++ user defined literals for sizes
   #
   # The idea is to filter out all tags, take first KNOWN ancestor (2nd line in the example above), and fetch the one without "origin/"
   #
   # git log --decorate --simplify-by-decoration --pretty=format:'%D'  DS_YBD-21175-get-rid-of-memset | grep -v "tag: " | grep -v "^\$"
   # DS_YBD-21175-get-rid-of-memset
   # origin/DS_SE2_master, DS_SE2_master
   # HEAD -> master, origin/master, origin/HEAD
   # origin/ybd-20548

   set -l all_branches (git branch --format='%(refname:short)' | grep -v "^dormant_DS_")
   if test -z "$branch_regexp"
      set branch_regexp ".*"
   end
   set iter_branches (string split ' ' -- $all_branches | grep -P "$branch_regexp")

   for branch in $iter_branches
      if test $branch = "master"
         continue
      end
      set -l index (contains -i -- $branch $all_branches)
      set -l all_branches_except_curent $all_branches
      set -e all_branches_except_curent[$index]
      # (^|[^\w-]) means either start of the string or (non word, non "-") character
      # (\$|[^\w-]) means either end of the string or (non word, non "-") character
      # {} - branch itself
      # We use the branches in grep to find to find first KNOWN ancestor.
      set -l all_branches_except_curent_ored (string join "|" (string split --no-empty ' ' -- $all_branches_except_curent | xargs -I {} echo "(^|[^\w-]){}(\$|[^\w-])"))
      set -l first_known_ancestor (git log -20 --decorate --decorate-refs-exclude="tags/" --simplify-by-decoration --pretty=format:'%D' $branch | grep -v "^\$" | grep -P "$all_branches_except_curent_ored" | head -n 1 | sed 's/, /\n/g' | grep -v "^origin/" | head -n 1 | sed 's/HEAD -> //g')
      if test -z "$first_known_ancestor"
         set first_known_ancestor "master"
         echo -e "$BYellow$branch$Color_Off: $Purple public $first_known_ancestor(?)$Color_Off {"
      else
         echo -e "$BYellow$branch$Color_Off: $Purple public $first_known_ancestor$Color_Off {"
      end
      # awk command below indents the files that --name-only gives (under the dash), colour them, limits their numer to 4 (max_files_to_print) and only for the 1st commit (first_n_commits_to_print_files) and prints how many were omitted (if any).
      git -c color.status=always -c color.ui=always --no-pager log -7 --name-only --no-merges --pretty=format:'   %Cblue%h%Creset %Cgreen(%cr)%Creset - %C(white bold)%s%Creset' $branch --not $first_known_ancestor | \
      awk 'BEGIN { max_files_to_print = 4; commit_n = 0; first_n_commits_to_print_files = 2; } { \
                      if($0 ~ /\(.+\).* - .+/) { dashpos = index($0," - ") + 2 - 16; print $0; num_of_files = 0; commit_n += 1; } \
                      else if($0 == "") { if(commit_n < first_n_commits_to_print_files && num_of_files > max_files_to_print) printf("%-"dashpos"s\\033[0;36m%s\\033[0m\n", "", "...(omitted: "(num_of_files - max_files_to_print)" files)..." ); } \
                      else { \
                         num_of_files += 1; \
                         if(commit_n < first_n_commits_to_print_files && num_of_files < max_files_to_print)        printf("%-"dashpos"s\\033[0;36m%s\\033[0m\n", "", $0); \
                      } \
                    } END { if(commit_n < first_n_commits_to_print_files && num_of_files > max_files_to_print) printf("%-"dashpos"s\\033[0;36m%s\\033[0m\n", "", "...(omitted: "(num_of_files - max_files_to_print)" files)..." ); }'
      # echo
      echo "}"
   end
   echo
   git branch -v
end
# Completion for gbb, taken from http://fishshell.com/docs/current/index.html#completion-own
complete -c gbb -f
complete -c gbb -a "(git branch --format='%(refname:short)')"



# ============================================================================================================


function gpl --description "Pull all branches and merge if can be fast-forwarded"
   # https://gist.github.com/mhl/936480

   set -l CURRENT_BRANCH (git symbolic-ref HEAD)
   # More info about @{u} see at https://mirrors.edge.kernel.org/pub/software/scm/git/docs/gitrevisions.html
   set -l CURRENT_BRANCH_UPSTREAM (git rev-parse --symbolic-full-name @{u} 2> /dev/null)

   # Update the remote-tracking branches for every remote for which
   # remote.<name>.skipDefaultUpdate is not true:
   git remote update default

   for entry in (git for-each-ref --shell --format="%(refname) %(upstream)" refs/heads)
      set -l REF (string trim --chars "'" -- (string split ' ' -- $entry)[1])
      set -l UPSTREAM (string trim --chars "'" -- (string split ' ' -- $entry))[2]

      # echo "$REF -> $UPSTREAM"
      # continue

      if test "$REF" = "$CURRENT_BRANCH"
         # echo "$REF -> $UPSTREAM: is the current branch => skipping for now"
         continue
      end
      if test -z "$UPSTREAM"
         # echo "$REF -> $UPSTREAM: upstream is absent => skipping for now"
         continue
      end

      set -l REF_HASH (git rev-parse --verify $REF)
      set -l UPSTREAM_HASH (git rev-parse --verify $UPSTREAM)
      set -l MERGE_BASES (git merge-base $REF $UPSTREAM)

      if test "$REF_HASH" = "$UPSTREAM_HASH"
         # echo "$REF -> $UPSTREAM: REF_HASH($REF_HASH) is the same as UPSTREAM_HASH => skipping..."
         continue
      end

      if test "$MERGE_BASES" = "$REF_HASH"
         echo -e (set_color -o brwhite)Fast-forwarding $REF(set_color normal) -\> $UPSTREAM
         git update-ref "$REF" "$UPSTREAM_HASH"
      else
         echo -e (set_color -o brwhite)Cannot fast-forward: $REF(set_color normal) -\> $UPSTREAM
      end
   end
   if test -z "$CURRENT_BRANCH_UPSTREAM"
      # echo "No upstream branch was found for the current branch ($CURRENT_BRANCH)"
   else
      echo -e (set_color -o brwhite)Merging $CURRENT_BRANCH(set_color normal) from $CURRENT_BRANCH_UPSTREAM
      git merge $CURRENT_BRANCH_UPSTREAM
   end
end



# ============================================================================================================



function glo  --argument-names branch --description 'Git Log Only: Show commits in the given (and only(!) given(!)) branch'
   if test -z "$branch"
      set branch (git branch --show-current)
   end
   # the last grep -v omits (from the black list => so effectively adds) origin version of the branch:
   # given branch = DS_YBD-20317_RowPacket_I_TestForWindowIndexer, it tells not filter out commits in:
   # refs/remotes/origin/DS_YBD-20317_RowPacket_I_TestForWindowIndexer
   git log --no-merges $branch --not (git for-each-ref --format="%(refname)" refs/remotes/origin | grep -Fv refs/heads/merge-only | grep -v "/$branch\$") --
end


function gbd --argument-names new old arguments --description 'Git Branch Diff: shows diff of the given (and only(!) given(!)) branch'
   echo "Useful additional args: --name-only"
   if test -n "$old"; and test (string sub --length=2 -- $old) != "--" # Not empty, and does NOT look like an option => use it
      set -e argv[1]
   else
      set old "remotes/origin/HEAD"
   end

   if test -n "$new"; and test (string sub --length=2 -- $new) != "--" # Not empty, and does NOT look like an option => use it
      set -e argv[1]
   else
      set new (git branch --show-current)
   end
   echo "Diff between: $old..$new, remaining args: $argv"

   git diff $argv (git merge-base $old $new) $new
end



# ============================================================================================================



function gmd --argument-names new old --description 'Git Merge Diff: shows diff as if new branch were to be merged to the old branch (the new branch might be already merged, in which case the diff will be empty)'
   if test -z "$old"
      set old "remotes/origin/HEAD"
   end
   if test -z "$new"
      set new (git branch --show-current)
   end
   git merge-tree (git merge-base $old $new) $old $new | colordiff
end

function gmerged
   for branch in (git branch --format='%(refname:short)' | grep -iP "^DS_YBD-\d+")
      # echo $branch
      set -l diff (gmd $branch)
      if test -z "$diff"
         echo $branch
      end
   end
end



# ============================================================================================================



function delete-branches --description 'Deletes git branches from both: local repo and remote repo'
   for local_branch in $argv
      # More info about @{upstream} see at https://mirrors.edge.kernel.org/pub/software/scm/git/docs/gitrevisions.html
      set remote_branch (git rev-parse --symbolic-full-name --abbrev-ref $local_branch@{upstream} | cut -d '/' -f 2- || echo "")
      echo "git branch -D $local_branch"
      git branch -D $local_branch
      if test -n "$remote_branch"
         echo "git push origin --delete $remote_branch"
         git push origin --delete $remote_branch
      end
   end
end
