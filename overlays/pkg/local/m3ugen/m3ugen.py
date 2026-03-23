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


def find_audio_files(directory: Path) -> list[Path]:
    return [f for f in directory.iterdir() if f.is_file() and f.suffix.lower() in AUDIO_EXTENSIONS]


def sort_files(files: list[Path], order: str) -> list[Path]:
    reverse = order.startswith("-")
    key_name = order.lstrip("-")
    return sorted(files, key=SORT_KEYS[key_name], reverse=reverse)


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate .m3u8 playlists from audio files in a directory.")
    parser.add_argument("directory", nargs="?", default=".", help="directory containing audio files (default: .)")
    parser.add_argument("-n", "--name", default=None, help="playlist name without extension (default: directory name)")
    parser.add_argument(
        "-o",
        "--order",
        default="-date",
        choices=["name", "-name", "date", "-date"],
        help="sort order (default: -date, newest first)",
    )
    parser.add_argument("-r", "--recursive", action="store_true", help="scan subdirectories recursively")
    parser.add_argument("--stdout", action="store_true", help="write playlist to stdout instead of a file")
    args = parser.parse_args()

    directory = Path(args.directory).resolve()
    if not directory.is_dir():
        print(f"m3ugen: not a directory: {directory}", file=sys.stderr)
        return 1

    playlist_name = args.name if args.name else directory.name

    if args.recursive:
        files = [f for f in directory.rglob("*") if f.is_file() and f.suffix.lower() in AUDIO_EXTENSIONS]
    else:
        files = find_audio_files(directory)

    if not files:
        print(f"m3ugen: no audio files found in {directory}", file=sys.stderr)
        return 1

    files = sort_files(files, args.order)

    lines = [os.path.relpath(f, directory) for f in files]

    if args.stdout:
        print("\n".join(lines))
    else:
        out_path = directory / f"{playlist_name}.m3u8"
        out_path.write_text("\n".join(lines) + "\n")
        print(f"{out_path} ({len(lines)} tracks)")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
