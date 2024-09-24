{lib, ...}: let
  helpers = import ./helpers.nix {inherit lib;};
  internalID = {
    vendor_id = 1452;
    product_id = 835;
    is_keyboard = true;
  };
  kinesisPedalID = {
    vendor_id = 10730;
    product_id = 256;
    is_keyboard = true;
  };
  forInternalID = [
    {
      type = "device_if";
      identifiers = [internalID];
    }
  ];
  remap = from: to:
    helpers.remap {
      inherit from to;
    };
  remap_fn = from: to:
    helpers.remap {
      inherit from to;
      keyType = "consumer_key_code";
    };
  remap_vendor = from: to:
    helpers.remap {
      inherit from to;
      keyType = "apple_vendor_keyboard_key_code";
    };
in {
  profiles = [
    {
      name = "Default profile";
      selected = true;
      devices = [
        {
          identifiers = internalID;
          simple_modifications = [
            (remap "left_option" "left_command")
            (remap "left_command" "left_option")
            (remap "right_command" "right_option")
            (remap "right_option" "right_command")
          ];
          # because of the hack below, we need to remap the function keys for the internal keyboard.
          fn_function_keys = [
            (remap_fn "f1" "display_brightness_decrement")
            (remap_fn "f2" "display_brightness_increment")
            (remap_vendor "f3" "mission_control")
            (remap_vendor "f4" "spotlight")
            (remap_fn "f5" "dictation")
            (remap "f6" "f16") # "do not disturb" key is not supported natively by Karabiner. Remap to f16, and rely on the keyboard settings being aligned.
            (remap_fn "f7" "rewind")
            (remap_fn "f8" "play_or_pause")
            (remap_fn "f9" "fast_forward")
            (remap_fn "f10" "mute")
            (remap_fn "f11" "volume_decrement")
            (remap_fn "f12" "volume_increment")
          ];
        }
        {
          identifiers = kinesisPedalID;
          simple_modifications = [
            (remap_fn "left_option" "dictation")
          ];
        }
      ];

      # hack to prevent karabiner from remapping function keys in external keyboards
      fn_function_keys = let
        fKeys = map (n: "f${toString n}") (lib.range 1 12);
      in
        map (key: remap key key) fKeys;

      complex_modifications = {
        rules = [
          {
            description = "Make control a hyper key";
            manipulators = [
              {
                from = {
                  key_code = "left_control";
                  modifiers = {
                    optional = [
                      "any"
                    ];
                  };
                };
                to = [
                  {
                    key_code = "left_option";
                    modifiers = [
                      "left_command"
                      "left_control"
                    ];
                  }
                ];
                type = "basic";
                conditions = forInternalID;
              }
            ];
          }

          {
            description = "Shift_L tap -> '(', Shift_R tap -> ')'";
            manipulators = [
              (helpers.tapManipulator {
                from = "left_shift";
                tap = helpers.keyDef {
                  key_code = "9";
                  modifiers = ["left_shift"];
                };
                hold = "left_shift";
                conditions = forInternalID;
              })
              (helpers.tapManipulator {
                from = "right_shift";
                tap = helpers.keyDef {
                  key_code = "0";
                  modifiers = ["right_shift"];
                };
                hold = "right_shift";
                conditions = forInternalID;
              })
            ];
          }

          {
            description = "Caps Lock / Enter tap for Enter, hold for Control";
            manipulators = [
              (helpers.tapManipulator {
                from = "caps_lock";
                tap = "return_or_enter";
                hold = "left_control";
                conditions = forInternalID;
              })
              (helpers.tapManipulator {
                from = "return_or_enter";
                tap = "return_or_enter";
                hold = "right_control";
                conditions = forInternalID;
              })
            ];
          }
        ];
      };
    }
  ];
}
