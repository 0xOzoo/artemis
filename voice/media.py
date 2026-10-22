"""Rend un vocal/une vidéo Telegram lisible par Claude : transcription + planche d'images.

Usage : media.py <fichier>  → JSON {"transcript": str, "sheet": chemin|null} sur stdout.
"""
import json
import os
import subprocess
import sys
from pathlib import Path

from faster_whisper import WhisperModel

MODEL = os.environ.get("WHISPER_MODEL", "small")  # small int8 sur CPU ; "medium" si la transcription déçoit (plus lent)


def duration(path: str) -> float:
    out = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", path],
        capture_output=True, text=True,
    ).stdout.strip()
    try:
        return float(out)
    except ValueError:
        return 0.0


def has_stream(path: str, kind: str) -> bool:
    out = subprocess.run(
        ["ffprobe", "-v", "error", "-select_streams", kind, "-show_entries", "stream=index", "-of", "csv=p=0", path],
        capture_output=True, text=True,
    ).stdout
    return bool(out.strip())


def contact_sheet(path: str, dur: float) -> str | None:
    """6 images réparties sur la vidéo, en une seule planche 3x2."""
    if not has_stream(path, "v") or dur <= 0:
        return None
    sheet = str(Path(path).with_suffix(".sheet.jpg"))
    r = subprocess.run(
        ["ffmpeg", "-v", "error", "-y", "-i", path,
         "-vf", f"fps=6/{dur:.3f},scale=480:-2,tile=3x2", "-frames:v", "1", sheet],
        capture_output=True,
    )
    return sheet if r.returncode == 0 and Path(sheet).exists() else None


def transcribe(path: str) -> str:
    if not has_stream(path, "a"):
        return ""
    model = WhisperModel(MODEL, device="cpu", compute_type="int8", cpu_threads=4)
    segments, _ = model.transcribe(path, vad_filter=True)
    return " ".join(s.text.strip() for s in segments).strip()


if __name__ == "__main__":
    f = sys.argv[1]
    print(json.dumps({"transcript": transcribe(f), "sheet": contact_sheet(f, duration(f))}, ensure_ascii=False))
