# ======================================== Header ========================================
function impl_mixin_deps
   set -l this_dir (dirname (realpath (status current-filename)))
end

# ============================================================================================================



function gpg-gen-pass-1  --argument-names len
   # Uses only 1 source of entropy: /dev/random
   tr -dc 'A-Za-z0-9!"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~' </dev/random | head -c $len
   echo
end

function gpg-gen-pass-2  --argument-names len
   # Combines 2 sources of entropy: /dev/random + card
   python3 -c "import sys; a=open(sys.argv[1], 'rb').read(); b=open(sys.argv[2], 'rb').read(); sys.stdout.buffer.write(bytes(x ^ y for x, y in zip(a, b)))" \
           (cat /dev/random | head -c 16384 | psub) \
           (gpg-connect-agent 'SCD RANDOM 16384' /bye | psub) | \
      tr -dc 'A-Za-z0-9!"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~' | \
      head -c $len
   echo
end

function gpg-gen-pass-2-printable  --argument-names len
   # Combines 2 sources of entropy: /dev/random + card
   python3 -c "import sys; a=open(sys.argv[1], 'rb').read(); b=open(sys.argv[2], 'rb').read(); sys.stdout.buffer.write(bytes(x ^ y for x, y in zip(a, b)))" \
           (cat /dev/random | head -c 16384 | psub) \
           (gpg-connect-agent 'SCD RANDOM 16384' /bye | psub) | \
      tr -dc 'A-Za-z0-9_' | \
      head -c $len
   echo
end

function gpg-gen-pass-from-seed --argument-names seed len_kb
   python3 -c "
import hashlib
import hmac
length = $len_kb
key = \"$seed\"
length *= 1024
result = []
alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
alphabet_length = len(alphabet)
max_value = 256 - (256 % alphabet_length)  # Largest multiple of alphabet_length below 256
i = 0
while len(result) < length:
   hmac_result = hmac.new(key.encode(), f'{key}-{i}'.encode(), hashlib.sha256).digest()
   result.extend([b for b in hmac_result if b < max_value])
   i += 1
print(''.join(alphabet[b % alphabet_length] for b in result)[:length])
"
end



function gpg-gen-username --argument-names len substr charset
   if test -z "$charset"
      set charset "A-Za-z0-9"
   end
   if test -z "$len"
      echo "Specify len. For example 8"
      return
   end
   if test -z "$substr"
      echo "Specify substr. For example asdf"
      return
   end
   # set fish_trace 1
   set -l pattern (string join ".*?" (string split '' --  $substr))
   while true
      for candidate in (tr -dc $charset </dev/urandom | head -c 1000 | grep -oiP $pattern)
         set -l actual_len (string length $candidate)
         if test "$actual_len" = "$len"
            echo $candidate | grep -iP $pattern
         else if test "$actual_len" -lt "$len"
            set -l leeway (math "$len - $actual_len")
            set -l filling (tr -dc $charset < /dev/urandom | head -c $leeway)
            # echo "leeway is: $leeway, filling: $filling"
            set -l result
            for i in (seq 0 (math "$leeway"))
               set result $result (string sub --start 1 --length $i -- $filling)$candidate(string sub --start (math "$i + 1") --length (math "$leeway - $i") -- $filling)
            end
            echo $result | grep -iP $pattern
         end
      end
   end
end
