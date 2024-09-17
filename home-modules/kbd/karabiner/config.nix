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
        }
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
