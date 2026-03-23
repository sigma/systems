"""Tests for m3ugen."""

import os
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
def second_dir(tmp_path):
    """Create a second directory with different audio files."""
    d = tmp_path / "second"
    d.mkdir()
    for i, name in enumerate(["xray.wav", "yankee.mp3", "zulu.flac"]):
        p = d / name
        p.write_text("")
        os.utime(p, (2000 + i, 2000 + i))
    return d


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

    def test_recursive(self, nested_dir):
        found = find_audio_files(nested_dir, recursive=True)
        names = {f.name for f in found}
        assert "nested.wav" in names
        assert len(found) == 5

    def test_non_recursive_skips_subdirs(self, nested_dir):
        found = find_audio_files(nested_dir, recursive=False)
        names = {f.name for f in found}
        assert "nested.wav" not in names


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
    def test_playlist_created_in_cwd(self, music_dir, monkeypatch, tmp_path):
        """Playlist file is written to cwd, not the source directory."""
        cwd = tmp_path / "output"
        cwd.mkdir()
        monkeypatch.chdir(cwd)
        monkeypatch.setattr("sys.argv", ["m3ugen", str(music_dir)])
        assert main() == 0
        playlist = cwd / f"{music_dir.name}.m3u8"
        assert playlist.exists()
        # nothing created in the source directory
        assert not list(music_dir.glob("*.m3u8"))

    def test_default_name_from_first_directory(self, music_dir, monkeypatch, tmp_path):
        monkeypatch.chdir(tmp_path)
        monkeypatch.setattr("sys.argv", ["m3ugen", str(music_dir)])
        assert main() == 0
        playlist = tmp_path / f"{music_dir.name}.m3u8"
        assert playlist.exists()
        lines = playlist.read_text().splitlines()
        assert len(lines) == 4

    def test_default_sort_is_name(self, music_dir, monkeypatch, capsys):
        """Default sort order is by name (ascending)."""
        monkeypatch.setattr("sys.argv", ["m3ugen", str(music_dir), "--stdout"])
        main()
        lines = capsys.readouterr().out.strip().split("\n")
        basenames = [os.path.basename(l) for l in lines]
        assert basenames == sorted(basenames, key=str.lower)

    def test_custom_name(self, music_dir, monkeypatch, tmp_path):
        monkeypatch.chdir(tmp_path)
        monkeypatch.setattr("sys.argv", ["m3ugen", str(music_dir), "-n", "my-mix"])
        assert main() == 0
        assert (tmp_path / "my-mix.m3u8").exists()

    def test_stdout(self, music_dir, monkeypatch, capsys):
        monkeypatch.setattr("sys.argv", ["m3ugen", str(music_dir), "--stdout"])
        assert main() == 0
        output = capsys.readouterr().out
        lines = output.strip().split("\n")
        assert len(lines) == 4

    def test_recursive(self, nested_dir, monkeypatch, capsys):
        monkeypatch.setattr("sys.argv", ["m3ugen", str(nested_dir), "-r", "--stdout"])
        assert main() == 0
        lines = capsys.readouterr().out.strip().split("\n")
        assert len(lines) == 5

    def test_paths_are_relative_to_cwd(self, music_dir, monkeypatch, capsys, tmp_path):
        monkeypatch.chdir(tmp_path)
        monkeypatch.setattr("sys.argv", ["m3ugen", str(music_dir), "--stdout"])
        main()
        lines = capsys.readouterr().out.strip().split("\n")
        assert not any(line.startswith("/") for line in lines)

    def test_multiple_directories(self, music_dir, second_dir, monkeypatch, capsys):
        monkeypatch.setattr("sys.argv", ["m3ugen", str(music_dir), str(second_dir), "--stdout"])
        main()
        lines = capsys.readouterr().out.strip().split("\n")
        # 4 from music_dir + 3 from second_dir
        assert len(lines) == 7

    def test_multiple_directories_preserve_order(self, music_dir, second_dir, monkeypatch, capsys):
        """Files from the first directory come before files from the second."""
        monkeypatch.setattr("sys.argv", ["m3ugen", str(music_dir), str(second_dir), "--stdout"])
        main()
        lines = capsys.readouterr().out.strip().split("\n")
        basenames = [os.path.basename(l) for l in lines]
        # first dir files (sorted by name): alpha, beta, delta, gamma
        # second dir files (sorted by name): xray, yankee, zulu
        first_batch = basenames[:4]
        second_batch = basenames[4:]
        assert first_batch == sorted(first_batch, key=str.lower)
        assert second_batch == sorted(second_batch, key=str.lower)
        assert second_batch[0] == "xray.wav"

    def test_multiple_dirs_name_from_first(self, music_dir, second_dir, monkeypatch, tmp_path):
        """Playlist name defaults to the first directory's name."""
        monkeypatch.chdir(tmp_path)
        monkeypatch.setattr("sys.argv", ["m3ugen", str(music_dir), str(second_dir)])
        main()
        assert (tmp_path / f"{music_dir.name}.m3u8").exists()

    def test_not_a_directory(self, tmp_path, monkeypatch, capsys):
        monkeypatch.setattr("sys.argv", ["m3ugen", str(tmp_path / "nope")])
        assert main() == 1
        assert "not a directory" in capsys.readouterr().err

    def test_no_audio_files(self, tmp_path, monkeypatch, capsys):
        (tmp_path / "readme.txt").write_text("")
        monkeypatch.setattr("sys.argv", ["m3ugen", str(tmp_path)])
        assert main() == 1
        assert "no audio files" in capsys.readouterr().err

    def test_overwrites_existing_playlist(self, music_dir, monkeypatch, tmp_path):
        monkeypatch.chdir(tmp_path)
        playlist = tmp_path / f"{music_dir.name}.m3u8"
        playlist.write_text("old content\n")
        monkeypatch.setattr("sys.argv", ["m3ugen", str(music_dir)])
        main()
        assert "old content" not in playlist.read_text()
