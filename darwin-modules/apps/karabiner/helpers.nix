{...}: rec {
  remap = {
    from,
    to,
    keyType ? "key_code",
  }: let
    fromBlock =
      if builtins.isString from
      then {key_code = from;}
      else from;
    toBlock =
      if builtins.isString to
      then [{${keyType} = to;}]
      else to;
  in {
    from = fromBlock;
    to = toBlock;
  };

  keyDef = {
    key_code,
    modifiers ? null,
  }:
    {
      inherit key_code;
    }
    // (
      if modifiers != null
      then {inherit modifiers;}
      else {}
    );

  manipulator = {
    from,
    to,
    to_if_alone ? null,
    type ? "basic",
    conditions ? null,
  }:
    {
      inherit from to type;
    }
    // (
      if to_if_alone != null
      then {inherit to_if_alone;}
      else {}
    )
    // (
      if conditions != null
      then {inherit conditions;}
      else {}
    );

  tapManipulator = {
    from,
    tap,
    hold,
    type ? "basic",
    conditions ? null,
  }:
    manipulator {
      from =
        if builtins.isString from
        then
          keyDef {
            key_code = from;
            modifiers = {
              optional = [
                "any"
              ];
            };
          }
        else from;
      to =
        if builtins.isString hold
        then [
          (keyDef {
            key_code = hold;
          })
        ]
        else hold;
      to_if_alone =
        if builtins.isString tap
        then [
          (keyDef {
            key_code = tap;
          })
        ]
        else tap;
      inherit type conditions;
    };
}
