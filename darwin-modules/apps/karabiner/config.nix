{
  lib,
  cfg,
  machine,
  ...
}: let
  helpers = import ./helpers.nix {inherit lib;};
  internalKeyboardID = helpers.kbdToID cfg.internalKeyboard;
  forInternalID = [
    {
      type = "device_if";
      identifiers = [internalKeyboardID];
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
  virtual_hid_keyboard = {
    keyboard_type_v2 = "ansi";
  };
in {
  inherit virtual_hid_keyboard;
  profiles = [
    {
      name = "Default profile";
      selected = true;
      inherit virtual_hid_keyboard;
      devices =
        # on a laptop, remap modifiers for the internal keyboard.
        lib.optionals (machine.features.laptop) [
          {
            identifiers = internalKeyboardID;
            simple_modifications = [
              (remap "left_option" "left_command")
              (remap "left_command" "left_option")
              (remap "right_command" "right_option")
              (remap "right_option" "right_command")
            ];
            fn_function_keys = [
              (remap "f6" "f16") # "do not disturb" key is not supported natively by Karabiner. Remap to f16, and rely on the keyboard settings being aligned.
            ];
          }
        ]
        ++ lib.optionals (cfg.pedal != null) [
          {
            identifiers = helpers.kbdToID cfg.pedal;
            simple_modifications = [
              (remap_fn "left_option" "dictation")
            ];
          }
        ]
        ++ (map (kbd: {
            identifiers = helpers.kbdToID kbd;
            ignore = true;
          })
          cfg.ignoreKeyboards);

      complex_modifications = {
        # on a laptop, make control a hyper key.
        # Also setup some tap keys.
        rules = lib.optionals (machine.features.laptop) [
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
