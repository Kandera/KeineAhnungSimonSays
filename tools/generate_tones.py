# Spoken turn callouts (Windows SAPI) plus a tintable arrow PNG.
import os
import struct
import subprocess
import sys
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MEDIA = os.path.join(ROOT, "media")

WORDS = (
    ("left", "Left"),
    ("right", "Right"),
    ("forward", "Forward"),
    ("stay", "Stay"),
)


def find_ffmpeg():
    for cmd in ("ffmpeg", "ffmpeg.exe"):
        try:
            subprocess.check_output([cmd, "-version"], stderr=subprocess.STDOUT)
            return cmd
        except (OSError, subprocess.CalledProcessError):
            pass
    try:
        import imageio_ffmpeg
        return imageio_ffmpeg.get_ffmpeg_exe()
    except ImportError:
        return None


def speak_wav(path, word):
    script = """
Add-Type -AssemblyName System.Speech
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
$english = $synth.GetInstalledVoices() |
    Where-Object { $_.VoiceInfo.Culture.Name -like 'en-*' } |
    Select-Object -First 1
if ($english) {
    $synth.SelectVoice($english.VoiceInfo.Name)
}
$synth.Rate = 4
$synth.Volume = 100
$synth.SetOutputToWaveFile(%s)
$synth.Speak(%s)
$synth.Dispose()
""" % (ps_quote(path), ps_quote(word))
    subprocess.check_call(
        ["powershell", "-NoProfile", "-Command", script],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.PIPE,
    )


def ps_quote(value):
    return "'" + value.replace("'", "''") + "'"


def png_chunk(tag, data):
    crc = zlib.crc32(tag + data) & 0xFFFFFFFF
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", crc)


def write_png(path, width, height, pixels):
    raw = b"".join(b"\x00" + pixels[y * width * 4:(y + 1) * width * 4] for y in range(height))
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    payload = (
        b"\x89PNG\r\n\x1a\n"
        + png_chunk(b"IHDR", ihdr)
        + png_chunk(b"IDAT", zlib.compress(raw, 9))
        + png_chunk(b"IEND", b"")
    )
    with open(path, "wb") as handle:
        handle.write(payload)


def point_in_triangle(px, py, ax, ay, bx, by, cx, cy):
    v0x, v0y = cx - ax, cy - ay
    v1x, v1y = bx - ax, by - ay
    v2x, v2y = px - ax, py - ay
    dot00 = v0x * v0x + v0y * v0y
    dot01 = v0x * v1x + v0y * v1y
    dot02 = v0x * v2x + v0y * v2y
    dot11 = v1x * v1x + v1y * v1y
    dot12 = v1x * v2x + v1y * v2y
    denom = dot00 * dot11 - dot01 * dot01
    if denom == 0:
        return False
    u = (dot11 * dot02 - dot01 * dot12) / denom
    v = (dot00 * dot12 - dot01 * dot02) / denom
    return u >= 0 and v >= 0 and u + v <= 1


def write_arrow_png(path, size=64):
    pixels = bytearray(size * size * 4)
    tip_x, tip_y = size / 2.0, size * 0.10
    left_x, left_y = size * 0.12, size * 0.58
    right_x, right_y = size * 0.88, size * 0.58
    shaft_left = size * 0.38
    shaft_right = size * 0.62
    shaft_top = size * 0.48
    shaft_bottom = size * 0.90
    for y in range(size):
        for x in range(size):
            px, py = x + 0.5, y + 0.5
            in_head = point_in_triangle(px, py, tip_x, tip_y, left_x, left_y, right_x, right_y)
            in_shaft = shaft_left <= px <= shaft_right and shaft_top <= py <= shaft_bottom
            if in_head or in_shaft:
                i = (y * size + x) * 4
                pixels[i:i + 4] = b"\xff\xff\xff\xff"
    write_png(path, size, size, pixels)


def encode_ogg(ffmpeg, wav_path, ogg_path):
    subprocess.check_call([
        ffmpeg, "-y", "-i", wav_path,
        "-c:a", "libvorbis", "-q:a", "5",
        ogg_path,
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    os.remove(wav_path)


def main():
    os.makedirs(MEDIA, exist_ok=True)
    ffmpeg = find_ffmpeg()
    if not ffmpeg:
        sys.stderr.write("no ffmpeg; trying pip install imageio-ffmpeg\n")
        subprocess.check_call([sys.executable, "-m", "pip", "install", "--quiet", "imageio-ffmpeg"])
        import imageio_ffmpeg
        ffmpeg = imageio_ffmpeg.get_ffmpeg_exe()

    for name, word in WORDS:
        wav_path = os.path.join(MEDIA, "en-" + name + ".wav")
        ogg_path = os.path.join(MEDIA, "en-" + name + ".ogg")
        speak_wav(wav_path, word)
        encode_ogg(ffmpeg, wav_path, ogg_path)
        stale = os.path.join(MEDIA, name + ".ogg")
        if os.path.exists(stale):
            os.remove(stale)
        print("wrote", ogg_path, word)

    arrow_path = os.path.join(MEDIA, "arrow.png")
    write_arrow_png(arrow_path)
    print("wrote", arrow_path)


if __name__ == "__main__":
    main()
