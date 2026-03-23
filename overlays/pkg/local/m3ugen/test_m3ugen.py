"""Tests for m3ugen."""

import os
import time
from pathlib import Path

import pytest

from m3ugen import AUDIO_EXTENSIONS, find_audio_files, main, sort_files


@pytest.fixture
def music_dir(tmp_path):
    """Create a temp directory with audio files of varying types and mtimes."""
    files = ["alpha.flac", "beta.mp3", "gamma.ogg", "delta.mkv"]
    for i, name in enumerate(files):
        p = tmp_path / name
        p.write_text("")
        # stagger mtimes so date sorting is deterministic
        os.utime(p, (1000 + i, 1000 + i))
    return tmp_path


@pytest.fixture
def nested_dir(music_dir):
    """Extend music_dir with a subdirectory containing more files."""
    sub = music_dir / "subdir"
    sub.mkdir()
    p = sub / "nested.wav"
    p.write_text("")
    os.utime(p, (999, 999))
    return music_dir


class TestFindAudioFiles:
    def test_finds_audio_only(self, music_dir):
        (music_dir / "readme.txt").write_text("")
        (music_dir / "cover.jpg").write_text("")
        found = find_audio_files(music_dir)
        assert all(f.suffix.lower() in AUDIO_EXTENSIONS for f in found)
        assert len(found) == 4

    def test_case_insensitive(self, music_dir):
        (music_dir / "LOUD.FLAC").write_text("")
        found = find_audio_files(music_dir)
        names = {f.name for f in found}
        assert "LOUD.FLAC" in names

    def test_empty_dir(self, tmp_path):
        assert find_audio_files(tmp_path) == []


class TestSortFiles:
    def test_name_ascending(self, music_dir):
        files = find_audio_files(music_dir)
        result = sort_files(files, "name")
        names = [f.name for f in result]
        assert names == sorted(names, key=str.lower)

    def test_name_descending(self, music_dir):
        files = find_audio_files(music_dir)
        result = sort_files(files, "-name")
        names = [f.name for f in result]
        assert names == sorted(names, key=str.lower, reverse=True)

    def test_date_ascending(self, music_dir):
        files = find_audio_files(music_dir)
        result = sort_files(files, "date")
        mtimes = [f.stat().st_mtime for f in result]
        assert mtimes == sorted(mtimes)

    def test_date_descending(self, music_dir):
        files = find_audio_files(music_dir)
        result = sort_files(files, "-date")
        mtimes = [f.stat().st_mtime for f in result]
        assert mtimes == sorted(mtimes, reverse=True)


class TestMain:
    def test_default_name_from_directory(self, music_dir, monkeypatch):
        monkeypatch.setattr("sys.argv", ["m3ugen", str(music_dir)])
        assert main() == 0
        playlist = music_dir / f"{music_dir.name}.m3u8"
        assert playlist.exists()
        lines = playlist.read_text().splitlines()
        assert len(lines) == 4

    def test_custom_name(self, music_dir, monkeypatch):
        monkeypatch.setattr("sys.argv", ["m3ugen", str(music_dir), "-n", "my-mix"])
        assert main() == 0
        assert (music_dir / "my-mix.m3u8").exists()

    def test_stdout(self, music_dir, monkeypatch, capsys):
        monkeypatch.setattr("sys.argv", ["m3ugen", str(music_dir), "--stdout"])
        assert main() == 0
        output = capsys.readouterr().out
        lines = output.strip().split("\n")
        assert len(lines) == 4
        # should not create a file
        assert not list(music_dir.glob("*.m3u8"))

    def test_recursive(self, nested_dir, monkeypatch):
        monkeypatch.setattr("sys.argv", ["m3ugen", str(nested_dir), "-r", "--stdout"])
        assert main() == 0

    def test_recursive_uses_relative_paths(self, nested_dir, monkeypatch, capsys):
        monkeypatch.setattr("sys.argv", ["m3ugen", str(nested_dir), "-r", "--stdout"])
        main()
        output = capsys.readouterr().out
        lines = output.strip().split("\n")
        assert any("subdir/" in line or "subdir\\" in line for line in lines)
        assert not any(line.startswith("/") for line in lines)

    def test_sort_order_applied(self, music_dir, monkeypatch, capsys):
        monkeypatch.setattr("sys.argv", ["m3ugen", str(music_dir), "--stdout", "-o", "name"])
        main()
        lines = capsys.readouterr().out.strip().split("\n")
        assert lines == sorted(lines, key=str.lower)

    def test_not_a_directory(self, tmp_path, monkeypatch, capsys):
        monkeypatch.setattr("sys.argv", ["m3ugen", str(tmp_path / "nope")])
        assert main() == 1
        assert "not a directory" in capsys.readouterr().err

    def test_no_audio_files(self, tmp_path, monkeypatch, capsys):
        (tmp_path / "readme.txt").write_text("")
        monkeypatch.setattr("sys.argv", ["m3ugen", str(tmp_path)])
        assert main() == 1
        assert "no audio files" in capsys.readouterr().err

    def test_overwrites_existing_playlist(self, music_dir, monkeypatch):
        playlist = music_dir / f"{music_dir.name}.m3u8"
        playlist.write_text("old content\n")
        monkeypatch.setattr("sys.argv", ["m3ugen", str(music_dir)])
        main()
        assert "old content" not in playlist.read_text()
