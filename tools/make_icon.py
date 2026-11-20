"""Genera el icono de VozTranslate 360 (1024x1024, opaco)."""
import sys
from PIL import Image, ImageDraw

S = 2048  # se dibuja al doble y se reduce para suavizar bordes
OUT = sys.argv[1]

# Fondo: degradado diagonal índigo -> cian
top = (89, 87, 242)
bottom = (33, 184, 219)
bg = Image.new("RGB", (S, S))
px = bg.load()
for y in range(S):
    for x in range(S):
        t = (x + y) / (2 * (S - 1))
        px[x, y] = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))

layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
d = ImageDraw.Draw(layer)

# Burbuja trasera (la otra persona): blanca translúcida, arriba a la derecha
d.rounded_rectangle((820, 430, 1720, 1100), radius=230, fill=(255, 255, 255, 110))
d.polygon([(1450, 1080), (1640, 1080), (1620, 1280)], fill=(255, 255, 255, 110))

# Burbuja delantera (yo): blanca, abajo a la izquierda
d.rounded_rectangle((330, 820, 1350, 1580), radius=250, fill=(255, 255, 255, 255))
d.polygon([(470, 1550), (700, 1550), (420, 1790)], fill=(255, 255, 255, 255))

# Onda de voz dentro de la burbuja delantera
bars = [150, 300, 430, 260, 380, 200, 110]
cx0, cy = 520, 1200
w, gap = 64, 42
for i, h in enumerate(bars):
    x = cx0 + i * (w + gap)
    d.rounded_rectangle((x, cy - h // 2, x + w, cy + h // 2), radius=w // 2, fill=(89, 87, 242, 255))

icon = Image.alpha_composite(bg.convert("RGBA"), layer).convert("RGB")
icon = icon.resize((1024, 1024), Image.LANCZOS)
icon.save(OUT, "PNG")
print("ok", OUT)
