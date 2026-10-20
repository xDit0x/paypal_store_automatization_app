"""Genera los recursos de icono de la app Restock a partir del logo maestro.

El logo maestro es assets/images/restock_logo.png (fondo oscuro + carro). A
partir de el se derivan:

  assets/images/restock_logo.png              -> logo completo (fondo oscuro + carro).
  assets/images/restock_logo_foreground.png   -> solo el carro con transparencia, capa foreground adaptativa.
  assets/images/restock_logo_background.png   -> fondo azul marino con degradado, capa background adaptativa.
  web/icons/Icon-maskable-*.png              -> iconos maskable de web con la zona segura respetada.

Los iconos de cada plataforma los genera flutter_launcher_icons (ver
pubspec.yaml). Ejecuta tool/generate_app_icons.sh para regenerarlo todo.

Uso:
  python3 tool/build_app_icons.py [ruta/al/logo.png] [carpeta/de/salida]
"""

from __future__ import annotations

import os
import sys

from PIL import Image, ImageFilter

DEFAULT_SOURCE = os.path.join("assets", "images", "restock_logo.png")
DEFAULT_OUT_DIR = os.path.join("assets", "images")

CANVAS = 1024
# Porcentaje del lienzo que ocupa el carro en la capa foreground adaptativa.
# Android recorta las capas adaptativas, asi que el carro se deja con margen.
FOREGROUND_SCALE = 0.80
# Porcentaje del lienzo que ocupa el carro en los iconos maskable de web.
# El lienzo foreground ya deja el carro al 80%, asi que al escalarlo al 90%
# el carro queda al 72% del icono, dentro de la zona segura circular del 80%.
MASKABLE_SCALE = 0.90
# Color plano de reserva para la capa background adaptativa.
FALLBACK_NAVY = (2, 6, 40)


def flatten(image: Image.Image):
    """Devuelve los pixeles en orden de lectura, sin depender de la API antigua."""
    getter = getattr(image, "get_flattened_data", None)
    if getter is not None:
        return getter()
    return image.getdata()


def build_background(image: Image.Image) -> Image.Image:
    """Estima el fondo (degradado azul marino) tapando el carro y difuminando."""
    blue = image.getchannel("B")
    mark = blue.point(lambda v: 255 if v > 85 else 0)

    # Parte solo con los pixeles del carro para que el desenfoque difumine
    # el fondo hacia dentro de la silueta del carro.
    estimate = Image.new("RGB", image.size, FALLBACK_NAVY)
    estimate.paste(image, (0, 0), mark)
    # Rellena el hueco del carro con el fondo mas cercano y repite con radios
    # decrecientes: es una difusion que reconstruye el degradado original.
    for radius in (120, 80, 50, 30, 18, 10, 6, 3):
        blurred = estimate.filter(ImageFilter.GaussianBlur(radius))
        estimate = Image.composite(blurred, image, mark)
    return estimate


def build_foreground(image: Image.Image, background: Image.Image) -> Image.Image:
    """Extrae el carro con canal alfa, dejando el fondo transparente."""
    obs = list(flatten(image))
    bg = list(flatten(background))

    rgba = bytearray(image.width * image.height * 4)
    min_x, min_y = image.width, image.height
    max_x = max_y = -1

    for index, (o, b) in enumerate(zip(obs, bg)):
        # La cobertura se deduce del canal azul: el carro es mucho mas
        # saturado que el fondo, y el azul del carro llega a 255.
        alpha = (o[2] - b[2]) / float(255 - b[2])
        if alpha <= 0.02:
            continue
        if alpha > 1.0:
            alpha = 1.0

        # Deshace la mezcla con el fondo para recuperar el color puro del carro.
        r = (o[0] - b[0] * (1.0 - alpha)) / alpha
        g = (o[1] - b[1] * (1.0 - alpha)) / alpha
        bl = (o[2] - b[2] * (1.0 - alpha)) / alpha

        rgba[index * 4 + 0] = max(0, min(255, int(r + 0.5)))
        rgba[index * 4 + 1] = max(0, min(255, int(g + 0.5)))
        rgba[index * 4 + 2] = max(0, min(255, int(bl + 0.5)))
        rgba[index * 4 + 3] = int(alpha * 255 + 0.5)

        x = index % image.width
        y = index // image.width
        if x < min_x:
            min_x = x
        if y < min_y:
            min_y = y
        if x > max_x:
            max_x = x
        if y > max_y:
            max_y = y

    if max_x < 0:
        raise SystemExit("No se ha detectado el carro en la imagen de origen")

    mask = Image.frombytes("RGBA", image.size, bytes(rgba))
    cropped = mask.crop((min_x, min_y, max_x + 1, max_y + 1))

    # Escala el carro para que ocupe FOREGROUND_SCALE del lienzo y lo centra.
    side = int(CANVAS * FOREGROUND_SCALE)
    scale = side / float(max(cropped.width, cropped.height))
    resized = cropped.resize(
        (max(1, int(cropped.width * scale)), max(1, int(cropped.height * scale))),
        Image.LANCZOS,
    )

    canvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    canvas.paste(
        resized,
        ((CANVAS - resized.width) // 2, (CANVAS - resized.height) // 2),
        resized,
    )
    return canvas


def main() -> None:
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    source = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.join(root, DEFAULT_SOURCE)
    out_dir = os.path.abspath(sys.argv[2]) if len(sys.argv) > 2 else os.path.join(root, DEFAULT_OUT_DIR)

    image = Image.open(source).convert("RGB")
    print(f"Origen: {source} {image.size}")

    background = build_background(image)
    foreground = build_foreground(image, background)

    os.makedirs(out_dir, exist_ok=True)

    logo = image.resize((CANVAS, CANVAS), Image.LANCZOS)
    logo.save(os.path.join(out_dir, "restock_logo.png"))
    print(f"-> {out_dir}/restock_logo.png")

    foreground.save(os.path.join(out_dir, "restock_logo_foreground.png"))
    print(f"-> {out_dir}/restock_logo_foreground.png")

    bg = background.resize((CANVAS, CANVAS), Image.LANCZOS)
    bg.save(os.path.join(out_dir, "restock_logo_background.png"))
    print(f"-> {out_dir}/restock_logo_background.png")

    # Vista previa: como se vera el icono adaptativo (fondo + carro).
    preview = bg.convert("RGBA")
    preview.alpha_composite(foreground)
    preview_dir = os.path.join(root, "build")
    os.makedirs(preview_dir, exist_ok=True)
    preview.save(os.path.join(preview_dir, "icon_preview.png"))
    print("-> build/icon_preview.png (vista previa)")

    build_maskable_web_icons(bg, foreground, root)


def build_maskable_web_icons(
    background: Image.Image, foreground: Image.Image, root: str
) -> None:
    """Genera los iconos maskable de web con el carro dentro de la zona segura.

    Los iconos maskable se recortan con una mascara circular: solo el 80%
    central del icono queda garantizado, asi que el carro se encoge.
    """
    for size in (192, 512):
        icon = background.convert("RGBA").resize((size, size), Image.LANCZOS)
        scale = (size * MASKABLE_SCALE) / float(foreground.width)
        mark = foreground.resize(
            (max(1, int(foreground.width * scale)), max(1, int(foreground.height * scale))),
            Image.LANCZOS,
        )
        icon.alpha_composite(
            mark, ((size - mark.width) // 2, (size - mark.height) // 2)
        )
        path = os.path.join(root, "web", "icons", f"Icon-maskable-{size}.png")
        os.makedirs(os.path.dirname(path), exist_ok=True)
        icon.convert("RGB").save(path)
        print(f"-> {path}")


if __name__ == "__main__":
    main()
