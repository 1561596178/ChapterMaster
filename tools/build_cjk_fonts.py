"""Rebuild every GameMaker font so it contains Chinese glyphs.

GameMaker stores each font as a .yy (glyph metrics, JSON with trailing commas)
plus a PNG texture.  This script renders Microsoft YaHei (and its bold face)
into new texture pages and rewrites the .yy glyph metrics, so the game shows
Chinese without any action in the GameMaker IDE.

Usage:
    python tools/build_cjk_fonts.py                 # rebuild all 18 fonts
    python tools/build_cjk_fonts.py --only fnt_40k_14
    python tools/build_cjk_fonts.py --chars 你好！  # charset membership report

How it works
------------
* Existing Latin glyphs (32..126) are copied verbatim from the old texture so
  the game's English look stays unchanged.
* Every other character in the charset is rendered from Microsoft YaHei and
  packed into the same texture page (1024 or 2048 squared).
* GameMaker draws each glyph bitmap top-aligned to the line top (the ascent
  line).  Glyphs are stored as tight horizontal crops with their top kept at
  the ascent line, so vertical alignment is automatic.
* .yy line metrics (ascender / lineHeight) are updated to match YaHei so
  multi-line text keeps a sane spacing.

The charset is ASCII + full-width punctuation + GB2312 level-1 (all 3755
common simplified Han characters) + CJK punctuation + every character used in
zh-CN.json today.
"""

import argparse
import json
import math
import os
import re
import sys
from PIL import Image, ImageDraw, ImageFont

BASE = r"C:\Users\o1561\Desktop\战团长\ChapterMaster-main-2026-08-05-1356"
FONTS_DIR = os.path.join(BASE, "fonts")
TRANSLATIONS = os.path.join(BASE, "datafiles", "main", "localization", "zh-CN.json")
MSYH = r"C:\Windows\Fonts\msyh.ttc"
MSYH_BOLD = r"C:\Windows\Fonts\msyhbd.ttc"
PAGE_SIZES = (1024, 2048, 4096)
PADDING = 2
ITALIC_SLANT = 0.21

_STRIP = re.compile(r",\s*([}\]])")


def read_tolerant(path):
    """Read a GameMaker .yy file (JSON with trailing commas)."""
    text = open(path, encoding="utf-8-sig").read()
    return json.loads(_STRIP.sub(r"\1", text))


def write_gamemaker(path, data):
    """Write JSON in GameMaker style: 2-space indent, trailing commas."""
    buf = []

    def emit(k, v, pad):
        if isinstance(v, dict) and v:
            buf.append(f'{pad}"{k}":{{')
            for ik, iv in v.items():
                emit(ik, iv, pad + "  ")
            buf.append(pad + "},")
        elif isinstance(v, list):
            items = []
            for it in v:
                if isinstance(it, dict):
                    items.append("{" + ", ".join(f'"{ik}":{_scalar(iv)}' for ik, iv in it.items()) + "}")
                else:
                    items.append(_scalar(it))
            buf.append(f'{pad}"{k}":[' + ", ".join(items) + "],")
        else:
            buf.append(f'{pad}"{k}":{_scalar(v)},')

    def _scalar(v):
        if isinstance(v, bool):
            return "true" if v else "false"
        if isinstance(v, str):
            return json.dumps(v)
        return str(v)

    for k, v in data.items():
        emit(k, v, "")
    with open(path, "w", encoding="utf-8-sig", newline="\n") as f:
        f.write("{\n" + "\n".join(buf) + "\n}")


def gb2312_level1():
    out = set()
    rows = list(range(0xA1, 0xA6)) + list(range(0xB0, 0xD8))
    for hi in rows:
        for lo in range(0xA1, 0xFF):
            try:
                ch = bytes([hi, lo]).decode("gb2312")
            except UnicodeDecodeError:
                continue
            if ch:
                out.add(ch)
    return out


def chars_from_translations():
    out = set()
    try:
        data = json.load(open(TRANSLATIONS, encoding="utf-8"))
    except Exception:
        return out
    if isinstance(data, dict):
        for k, v in data.items():
            for s in (k, v if isinstance(v, str) else ""):
                out.update(ch for ch in s if 32 <= ord(ch) <= 0xFFFF)
    return out


def build_charset():
    chars = set()
    chars.update(chr(c) for c in range(32, 127))
    chars.update(gb2312_level1())
    chars.update(chr(c) for c in range(0x3000, 0x3040))
    chars.update(chr(c) for c in range(0x2013, 0x2028))
    chars.update(chars_from_translations())
    return sorted(chars, key=ord)


class Renderer:
    def __init__(self, size_pt, bold, italic, antialias):
        self.em = size_pt * 96.0 / 72.0
        px = int(round(self.em))
        face = MSYH_BOLD if bold else MSYH
        self.font = ImageFont.truetype(face, px, index=0)
        self.italic = italic
        self.antialias = antialias
        self.ascent, self.descent = self.font.getmetrics()
        self.line = self.ascent + self.descent
        self.pad = 32  # canvas margin for baseline-anchored drawing

    def glyph(self, ch):
        """Render one character.

        Returns (ink RGBA Image, offset, shift, y_top, bitmap_h) where
        y_top is the row of the ink inside the bitmap (bitmap row 0 is the
        ascent line) and bitmap_h is the total height to reserve.
        """
        w = int(math.ceil(self.font.getlength(ch))) + 2 * self.pad
        h = self.line + 2 * self.pad
        shift = int(round(self.font.getlength(ch)))
        canvas = Image.new("L", (w, h), 0)
        d = ImageDraw.Draw(canvas)
        d.text((self.pad, self.pad + self.ascent), ch, font=self.font, anchor="ls", fill=255)
        bbox = canvas.getbbox()
        if bbox is None:
            blank = Image.new("RGBA", (max(2, shift), self.line + 2), (255, 255, 255, 0))
            return blank, 0, shift, 0, self.line, self.line
        x0, y0, x1, y1 = bbox
        ink = canvas.crop(bbox)
        if not self.antialias:
            ink = ink.point(lambda a, _t=0: 255 if a >= 128 else 0)
        offset = x0 - self.pad               # signed left bearing
        ink_top_abs = self.ascent - (y0 - self.pad)   # ink top above baseline
        ink_bottom_abs = (y1 - self.pad) - self.ascent  # ink bottom below baseline
        ink_row = self.ascent - ink_top_abs            # ink top row in line space
        h_total = self.ascent + max(0, ink_bottom_abs)  # ascent line -> ink bottom
        h_total = max(h_total, ink_row + (y1 - y0))
        ink_h = y1 - y0
        if self.italic:
            k = ITALIC_SLANT
            ih = ink.height
            iw = ink.width
            new_w = iw + int(k * ih) + 2
            slanted = ink.transform((new_w, ih), Image.AFFINE, (1, -k, k * ih, 0, 1, 0),
                                    resample=Image.BILINEAR)
            nb = slanted.getbbox()
            if nb:
                offset += nb[0]
                slanted = slanted.crop(nb)
            ink = slanted
        img = Image.new("RGBA", ink.size, (255, 255, 255, 0))
        img.putalpha(ink)
        return img, offset, shift, max(0, ink_row), h_total, ink_h


def pack_new(items, page_size, pad):
    """Shelf-pack glyphs into one texture page.

    items: list of (cp, img, offset, shift, top_row, h_total) where top_row is
    the row of the ink inside the glyph bitmap.
    Returns (page, dict cp -> (x, y)) or None if it does not fit.
    """
    page = Image.new("RGBA", (page_size, page_size), (255, 255, 255, 0))
    boxes = {}
    items = sorted(items, key=lambda it: -it[5])
    y = pad
    while items:
        row_h = 0
        x = pad
        placed = []
        leftover = []
        for it in items:
            w = it[1].size[0]
            h = it[5]
            if x + w + pad <= page_size:
                placed.append((it, x))
                x += w + pad
                row_h = max(row_h, h)
            else:
                leftover.append(it)
        if not placed:
            return None
        for it, px in placed:
            page.paste(it[1], (px, y + it[4]))
            boxes[it[0]] = (px, y)
        y += row_h + pad
        if y > page_size:
            return None
        items = leftover
    return page, boxes
    page = Image.new("RGBA", (page_size, page_size), (255, 255, 255, 0))
    boxes = {}
    items = sorted(items, key=lambda it: -it[5])
    y = pad
    while items:
        row_h = 0
        x = reserved_x + pad
        placed = []
        leftover = []
        for it in items:
            w = it[1].size[0]
            h = it[5]
            if x + w + pad <= page_size:
                placed.append((it, x))
                x += w + pad
                row_h = max(row_h, h)
            else:
                leftover.append(it)
        if not placed:
            return None
        for it, px in placed:
            page.paste(it[1], (px, y + it[4]))
            boxes[it[0]] = (px, y)
        y += row_h + pad
        if y > page_size:
            return None
        items = leftover
    return page, boxes


def build_font(name):
    yy_path = os.path.join(FONTS_DIR, name, name + ".yy")
    png_path = os.path.join(FONTS_DIR, name, name + ".png")
    yy = read_tolerant(yy_path)
    size_pt = float(yy.get("size", 14))
    bold = bool(yy.get("bold", False)) or yy.get("styleName") == "Bold"
    italic = bool(yy.get("italic", False))
    antialias = bool(yy.get("AntiAlias", 1))

    charset = build_charset()
    r = Renderer(size_pt, bold, italic, antialias)

    def make_items(chars):
        out = []
        for ch in chars:
            img, offset, shift, y_top, h_total, ink_h = r.glyph(ch)
            h_total = max(h_total, 0)
            out.append((ord(ch), img, offset, shift, y_top, h_total))
        return out

    items = make_items(charset)

    result = None
    for page_size in PAGE_SIZES:
        result = pack_new(items, page_size, PADDING)
        if result is not None:
            break
    if result is None:
        print(f"  !! {name}: {len(charset)} chars do not fit on {PAGE_SIZES[-1]}^2; "
              f"dropping least-common hanzi until it fits")
        essential = [c for c in charset
                     if not (0x4E00 <= ord(c) <= 0x9FFF)]  # ascii + punct + translation chars
        hanzi = sorted(chars_from_translations(), key=ord)
        hanzi = [c for c in hanzi if 0x4E00 <= ord(c) <= 0x9FFF]
        gb_l1 = sorted(gb2312_level1() - set(hanzi))
        for frac in (0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1):
            keep_n = int(len(gb_l1) * frac)
            subset = essential + hanzi + gb_l1[:keep_n]
            items = make_items(sorted(subset, key=ord))
            result = None
            for page_size in PAGE_SIZES:
                result = pack_new(items, page_size, PADDING)
                if result is not None:
                    break
            if result is not None:
                print(f"      -> fitted {len(subset)} glyphs at {frac:.0%} of L1")
                break
        if result is None:
            raise SystemExit(f"  !! {name}: still does not fit")
    page, boxes = result

    new_glyph_map = {}
    for cp, img, offset, shift, y_top, h_total in items:
        w, h = img.size
        if h_total <= 0:
            h_total = r.line
        new_glyph_map[str(cp)] = {
            "character": cp, "h": h_total, "offset": offset, "shift": shift,
            "w": w, "x": boxes[cp][0], "y": boxes[cp][1],
        }

    yy["glyphs"] = new_glyph_map
    yy["ascender"] = r.ascent
    yy["ascenderOffset"] = 0
    yy["lineHeight"] = r.line
    yy["regenerateBitmap"] = False

    write_gamemaker(yy_path, yy)
    page.save(png_path)
    print(f"  {name}: size={size_pt}pt em={r.em:.1f}px asc={r.ascent} desc={r.descent} "
          f"line={r.line} glyphs={len(new_glyph_map)} "
          f"page={page.size[0]}^2 png={os.path.getsize(png_path) // 1024}KB")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", default=None)
    ap.add_argument("--chars", default="")
    args = ap.parse_args()

    charset = build_charset()
    if args.chars:
        print("charset size:", len(charset))
        for ch in args.chars:
            print(f"  {ch!r} U+{ord(ch):04X} present={ch in charset}")
        return

    fonts = []
    for entry in os.scandir(FONTS_DIR):
        if not entry.is_dir():
            continue
        if os.path.exists(os.path.join(entry.path, entry.name + ".yy")):
            fonts.append(entry.name)
    fonts.sort()
    if args.only:
        fonts = [args.only] if args.only in fonts else []
    if not fonts:
        print("no fonts to build")
        return

    for name in fonts:
        build_font(name)


if __name__ == "__main__":
    main()