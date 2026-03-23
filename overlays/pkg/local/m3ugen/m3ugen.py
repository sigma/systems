#!/usr/bin/env python3
"""Generate .m3u8 playlists from a directory of audio files."""

import argparse
import os
import sys
from pathlib import Path

AUDIO_EXTENSIONS = {".flac", ".mp3", ".mp4", ".wav", ".aac", ".ogg", ".m4a", ".opus", ".wma", ".mkv"}

SORT_KEYS = {
    "name": lambda p: p.name.lower(),
    "date": lambda p: p.stat().st_mtime,
}


def find_audio_files(directory: Path, recursive: bool = False) -> list[Path]:
    if recursive:
        return [f for f in directory.rglob("*") if f.is_file() and f.suffix.lower() in AUDIO_EXTENSIONS]
    return [f for f in directory.iterdir() if f.is_file() and f.suffix.lower() in AUDIO_EXTENSIONS]


def sort_files(files: list[Path], order: str) -> list[Path]:
    reverse = order.startswith("-")
    key_name = order.lstrip("-")
    return sorted(files, key=SORT_KEYS[key_name], reverse=reverse)


def get_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Generate .m3u8 playlists from audio files in a directory.")
    parser.add_argument("directories", nargs="*", default=["."], help="directories containing audio files (default: .)").complete = {"bash": "directory", "fish": "directory", "zsh": "directory"}
    parser.add_argument("-n", "--name", default=None, help="playlist name without extension (default: first directory name)")
    parser.add_argument(
        "-o",
        "--order",
        default="name",
        choices=["name", "-name", "date", "-date"],
        help="sort order (default: name)",
    )
    parser.add_argument("-r", "--recursive", action="store_true", help="scan subdirectories recursively")
    parser.add_argument("--stdout", action="store_true", help="write playlist to stdout instead of a file")
    return parser


def main() -> int:
    parser = get_parser()
    args = parser.parse_args()

    cwd = Path.cwd()
    directories = [Path(d).resolve() for d in args.directories]

    for d in directories:
        if not d.is_dir():
            print(f"m3ugen: not a directory: {d}", file=sys.stderr)
            return 1

    playlist_name = args.name if args.name else directories[0].name

    # Collect files in directory order; sort within each directory
    all_files: list[str] = []
    for d in directories:
        files = find_audio_files(d, recursive=args.recursive)
        files = sort_files(files, args.order)
        all_files.extend(os.path.relpath(f, cwd) for f in files)

    if not all_files:
        dirs = ", ".join(str(d) for d in directories)
        print(f"m3ugen: no audio files found in {dirs}", file=sys.stderr)
        return 1

    if args.stdout:
        print("\n".join(all_files))
    else:
        out_path = cwd / f"{playlist_name}.m3u8"
        out_path.write_text("\n".join(all_files) + "\n")
        print(f"{out_path} ({len(all_files)} tracks)")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
