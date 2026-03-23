#!/usr/bin/env python3
"""Generate fish shell completions from the m3ugen argparse parser."""

from m3ugen import get_parser


def main():
    parser = get_parser()
    lines = []
    for action in parser._actions:
        if not action.option_strings:
            continue
        desc = (action.help or "").replace("'", "\\'")
        for flag in action.option_strings:
            short = flag.lstrip("-")
            if flag.startswith("--"):
                line = f"complete -c m3ugen -l {short} -d '{desc}'"
            else:
                line = f"complete -c m3ugen -s {short} -d '{desc}'"
            if action.choices:
                choices = " ".join(str(c) for c in action.choices)
                line += f" -x -a '{choices}'"
            lines.append(line)
    lines.append("complete -c m3ugen -f -a '(__fish_complete_directories)'")
    print("\n".join(lines))


if __name__ == "__main__":
    main()
