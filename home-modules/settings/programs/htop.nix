{ config, ... }:
{
  enable = true;
  settings = {
    color_scheme = 5;
    cpu_count_from_one = 0;
    delay = 15;
    detailed_cpu_time = 1;
    fields = with config.lib.htop.fields; [
      NLWP
      PID
      USER
      PRIORITY
      NICE
      M_SIZE
      M_RESIDENT
      M_SHARE
      STATE
      PERCENT_CPU
      PERCENT_MEM
      TIME
      COMM
    ];
    header_margin = 1;
    hide_threads = 1;
    hide_kernel_threads = 1;
    highlight_base_name = 1;
    highlight_megabytes = 1;
    highlight_threads = 1;
    show_thread_names = 0;
    show_program_path = 1;
    tree_view = 1;
  }
  // (
    with config.lib.htop;
    leftMeters [
      (text "CPU")
      (bar "AllCPUs2")
    ]
  )
  // (
    with config.lib.htop;
    rightMeters [
      (text "Blank")
      (text "Uptime")
      (text "Tasks")
      (text "LoadAverage")
      (bar "Memory")
      (bar "Swap")
    ]
  );
}
