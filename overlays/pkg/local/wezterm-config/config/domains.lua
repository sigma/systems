return function(config, _opts)
   -- ref: https://wezfurlong.org/wezterm/config/lua/SshDomain.html
   config.ssh_domains = {}

   -- ref: https://wezfurlong.org/wezterm/multiplexing.html#unix-domains
   config.unix_domains = {}

   -- ref: https://wezfurlong.org/wezterm/config/lua/WslDomain.html
   config.wsl_domains = {}
end
