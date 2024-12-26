{
  lib,
  cfg,
  machine,
  ...
}: let
  helpers = import ./helpers.nix {inherit lib;};
  internalKeyboardID = helpers.kbdToID cfg.internalKeyboard;
  forID = id: [
    {
      type = "device_if";
      identifiers = [id];
    }
  ];
  remap = from: to:
    helpers.remap {
      inherit from to;
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
            identifiers = helpers.pointerToID cfg.pedal;
            simple_modifications = let
              dictation = [{consumer_key_code = "dictation";}];
            in [
              (remap {pointing_button = "button1";} dictation)
              (remap {pointing_button = "button2";} "return_or_enter")
              (remap {pointing_button = "button3";} "left_command")
            ];
            ignore = false;
          }
        ]
        ++ (map (kbd: {
            identifiers = helpers.kbdToID kbd;
            ignore = true;
          })
          cfg.ignoreKeyboards);

      complex_modifications = let
        hyper = [
          {
            key_code = "left_option";
            modifiers = [
              "left_command"
              "left_control"
            ];
          }
        ];
      in {
        # on a laptop, make control a hyper key.
        # Also setup some tap keys.
        rules =
          lib.optionals (machine.features.laptop) [
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
                  to = hyper;
                  type = "basic";
                  conditions = forID internalKeyboardID;
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
                  conditions = forID internalKeyboardID;
                })
                (helpers.tapManipulator {
                  from = "right_shift";
                  tap = helpers.keyDef {
                    key_code = "0";
                    modifiers = ["right_shift"];
                  };
                  hold = "right_shift";
                  conditions = forID internalKeyboardID;
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
                  conditions = forID internalKeyboardID;
                })
                (helpers.tapManipulator {
                  from = "return_or_enter";
                  tap = "return_or_enter";
                  hold = "right_control";
                  conditions = forID internalKeyboardID;
                })
              ];
            }
          ]
          ++ lib.optionals (cfg.pedal != null) [
            {
              description = "Make pedalbutton 3 a hyper key";
              manipulators = [
                {
                  from = {
                    pointing_button = "button3";
                    modifiers = {
                      optional = [
                        "any"
                      ];
                    };
                  };
                  to = hyper;
                  type = "basic";
                  conditions = forID (helpers.kbdToID cfg.pedal);
                }
              ];
            }
          ];
      };
    }
  ];
}
