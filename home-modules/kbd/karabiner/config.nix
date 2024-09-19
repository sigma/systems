{...}: let
  internalID = {
    vendor_id = 1452;
    product_id = 835;
    is_keyboard = true;
  };
  forInternalID = [
    {
      type = "device_if";
      identifiers = [internalID];
    }
  ];
  remap = from: to: {
    from = {
      key_code = from;
    };
    to = [
      {
        key_code = to;
      }
    ];
  };
  remap_fn = from: to: {
    from = {
      key_code = from;
    };
    to = [
      {
        consumer_key_code = to;
      }
    ];
  };
  remap_vendor = from: to: {
    from = {
      key_code = from;
    };
    to = [
      {
        apple_vendor_keyboard_key_code = to;
      }
    ];
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
      ];

      # hack to prevent karabiner from remapping function keys in external keyboards
      fn_function_keys = [
        (remap "f1" "f1")
        (remap "f2" "f2")
        (remap "f3" "f3")
        (remap "f4" "f4")
        (remap "f5" "f5")
        (remap "f6" "f6")
        (remap "f7" "f7")
        (remap "f8" "f8")
        (remap "f9" "f9")
        (remap "f10" "f10")
        (remap "f11" "f11")
        (remap "f12" "f12")
      ];

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
              {
                from = {
                  key_code = "right_control";
                  modifiers = {
                    optional = [
                      "any"
                    ];
                  };
                };
                to = [
                  {
                    key_code = "right_option";
                    modifiers = [
                      "right_command"
                      "right_control"
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
              {
                from = {
                  key_code = "left_shift";
                  modifiers = {
                    optional = [
                      "any"
                    ];
                  };
                };
                to = {
                  key_code = "left_shift";
                };
                to_if_alone = [
                  {
                    key_code = "9";
                    modifiers = [
                      "left_shift"
                    ];
                  }
                ];
                type = "basic";
                conditions = forInternalID;
              }
              {
                from = {
                  key_code = "right_shift";
                  modifiers = {
                    optional = [
                      "any"
                    ];
                  };
                };
                to = {
                  key_code = "right_shift";
                };
                to_if_alone = [
                  {
                    key_code = "0";
                    modifiers = [
                      "right_shift"
                    ];
                  }
                ];
                type = "basic";
                conditions = forInternalID;
              }
            ];
          }

          {
            description = "Caps Lock / Enter tap for Enter, hold for Control";
            manipulators = [
              {
                from = {
                  key_code = "caps_lock";
                  modifiers = {
                    optional = ["any"];
                  };
                };
                to = [
                  {
                    key_code = "left_control";
                  }
                ];
                to_if_alone = {
                  key_code = "return_or_enter";
                };
                type = "basic";
                conditions = forInternalID;
              }

              {
                from = {
                  key_code = "return_or_enter";
                  modifiers = {
                    optional = ["any"];
                  };
                };
                to = {
                  key_code = "right_control";
                };

                to_if_alone = {
                  key_code = "return_or_enter";
                };
                type = "basic";
                conditions = forInternalID;
              }
            ];
          }
        ];
      };
    }
  ];
}
