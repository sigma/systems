{ ... }:
{
  enable = true;
  configFile = {
    text = ''
      $env.config = {
        show_banner: false,
        filesize: {
          metric: true
        }
        table: {
          mode: rounded
        }
        ls: {
          use_ls_colors: true
        }
        cursor_shape: {
          emacs: block
          vi_insert: block
          vi_normal: underscore
        }
      }
    '';
  };
}
