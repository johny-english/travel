# ======================================== Header ========================================
function impl_mixin_deps
   set -l this_dir (dirname (realpath (status current-filename)))
end

# ============================================================================================================

function kde-setup
   kwriteconfig6 --file kcminputrc --group Keyboard --key RepeatDelay 250

   kwriteconfig6 --file kwinrc --group NightColor --key "Active"           "true"
   kwriteconfig6 --file kwinrc --group NightColor --key "Mode"             "Constant"
   kwriteconfig6 --file kwinrc --group NightColor --key "NightTemperature" "5000"
   kwriteconfig6 --file kwinrc --group Desktops   --key "Id_1"             "61c6bef4-9cf7-4cef-ab06-2a8fd4aae57f"
   kwriteconfig6 --file kwinrc --group Desktops   --key "Id_2"             "4dbdd471-e460-4795-864d-ad135a978e7b"
   kwriteconfig6 --file kwinrc --group Desktops   --key "Id_3"             "451c6097-b868-48b9-98d2-673dcffa324d"
   kwriteconfig6 --file kwinrc --group Desktops   --key "Id_4"             "d4309e3d-2c8e-4816-8747-1bfdb6341f0c"
   kwriteconfig6 --file kwinrc --group Desktops   --key "Number"           "4"
   kwriteconfig6 --file kwinrc --group Desktops   --key "Rows"             "2"

   kwriteconfig6 --file kxkbrc --group Layout --key "DisplayNames"    ","
   kwriteconfig6 --file kxkbrc --group Layout --key "LayoutList"      "us,ru"
   kwriteconfig6 --file kxkbrc --group Layout --key "Options"         "grp:caps_toggle,compose:ralt"
   kwriteconfig6 --file kxkbrc --group Layout --key "ResetOldOptions" "true"
   kwriteconfig6 --file kxkbrc --group Layout --key "SwitchMode"      "Window"
   kwriteconfig6 --file kxkbrc --group Layout --key "Use"             "true"

   kwriteconfig6 --file plasma-localerc --group Formats --key "LANG"           "en_US.UTF-8"
   kwriteconfig6 --file plasma-localerc --group Formats --key "LC_MEASUREMENT" "C"
   kwriteconfig6 --file plasma-localerc --group Formats --key "LC_TIME"        "C"

   kwriteconfig6 --file krusaderrc --group General --key "Move To Trash"          "false"
   kwriteconfig6 --file krusaderrc --group Startup --key "Left Side Is Active"    "false"
   kwriteconfig6 --file krusaderrc --group Startup --key "Show Cmd Line"          "true"
   kwriteconfig6 --file krusaderrc --group Startup --key "Show FN Keys"           "false"
   kwriteconfig6 --file krusaderrc --group Startup --key "Show Terminal Emulator" "false"
   kwriteconfig6 --file krusaderrc --group Startup --key "Show status bar"        "false"
end
