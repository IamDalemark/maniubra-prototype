"""Generate the original looping placeholder sounds used by the first lesson."""

from math import pi, sin
from pathlib import Path
from random import Random
from struct import pack
import wave

OUT = Path(__file__).resolve().parents[1] / "assets" / "audio"
OUT.mkdir(parents=True, exist_ok=True)
RATE = 22_050
SAMPLES = RATE * 2


def write(name: str, samples: list[float]) -> None:
    with wave.open(str(OUT / name), "wb") as sound:
        sound.setnchannels(1)
        sound.setsampwidth(2)
        sound.setframerate(RATE)
        sound.writeframes(b"".join(pack("<h", round(max(-1, min(1, value)) * 32767)) for value in samples))


engine = []
for index in range(SAMPLES):
    seconds = index / RATE
    pulse = 0.58 * sin(2 * pi * 72 * seconds)
    pulse += 0.25 * sin(2 * pi * 144 * seconds)
    pulse += 0.12 * sin(2 * pi * 216 * seconds)
    engine.append(pulse * 0.34)
write("engine_idle.wav", engine)

rng = Random(21)
partials = [(260 + 17 * i, rng.uniform(0, 2 * pi), rng.uniform(0.003, 0.018)) for i in range(60)]
road = []
for index in range(SAMPLES):
    seconds = index / RATE
    sample = sum(amplitude * sin(2 * pi * frequency * seconds + phase) for frequency, phase, amplitude in partials)
    road.append(sample * 0.45)
write("road_noise.wav", road)
