"""Rebuild Affinity Photo's docked panel layout from a plain text spec.

Usage: affinity-layout [SPEC]   (default: ~/.config/affinity/photo-layout.txt)

Affinity must be closed: it rewrites WindowProfile.xml when it quits.
"""
import shutil
import subprocess
import sys
import time
import xml.etree.ElementTree as ET
from pathlib import Path

XSI = "http://www.w3.org/2001/XMLSchema-instance"
ET.register_namespace("xsi", XSI)
ET.register_namespace("xsd", "http://www.w3.org/2001/XMLSchema")
TYPE = f"{{{XSI}}}type"

ROAMING = Path.home() / ".local/share/affinity/drive_c/users" / Path.home().name / "AppData/Roaming"
PROFILE = ROAMING / "Affinity/Photo/2.0/Workspaces/Custom/Photo/Windows_Docked/WindowProfile.xml"
SPEC = Path.home() / ".config/affinity/photo-layout.txt"


def parse_spec(path):
    """-> {"left": [[page ids]], "right": [[page ids]]}"""
    sides, side = {"left": [], "right": []}, None
    for n, line in enumerate(path.read_text().splitlines(), 1):
        line = line.split("#", 1)[0].strip()
        if not line:
            continue
        if line.rstrip(":") in sides and line.endswith(":"):
            side = line.rstrip(":")
        elif side is None:
            sys.exit(f"{path}:{n}: tabs listed before a 'left:' or 'right:' header")
        else:
            sides[side].append([t + "Page" for t in line.split()])
    return sides


def main():
    spec = Path(sys.argv[1]) if len(sys.argv) > 1 else SPEC
    if subprocess.run(["pgrep", "-f", "photo.exe"], capture_output=True).returncode == 0:
        sys.exit("Affinity Photo is running; quit it first (it overwrites the layout on exit).")
    if not PROFILE.exists():
        sys.exit(f"{PROFILE} not found; launch and quit Affinity Photo once to create it.")

    tree = ET.parse(PROFILE)
    root = tree.getroot()
    main_site = root.find(f"Objects/WndProfObject[@{TYPE}='MainSite']")
    float_site = root.find(f"Objects/WndProfObject[@{TYPE}='FloatSite']")
    row = main_site.find("Roots/DockRoot/Shelves/Shelf/Objects")
    shelves = [o for o in row if o.get(TYPE) == "Shelf"]
    if len(shelves) != 2:
        sys.exit(f"expected a left and right studio, found {len(shelves)} shelves; try Window > Studio > Reset Studio")
    shelf_for = {"left": shelves[0], "right": shelves[1]}

    # every tab Affinity knows about, wherever it currently lives (docked or floating)
    pages, book_height = {}, {}
    for book in root.iter("WndProfObject"):
        if book.get(TYPE) != "Book":
            continue
        for page in book.find("Pages"):
            pages[page.get("Id")] = page
            book_height[page.get("Id")] = book.get("DockedHeightValue")
    template = next(b for b in root.iter("WndProfObject") if b.get(TYPE) == "Book")
    book_attrs = {k: v for k, v in template.attrib.items() if k != TYPE}

    layout = parse_spec(spec)
    listed = [p for groups in layout.values() for g in groups for p in g]
    dupes = sorted({p for p in listed if listed.count(p) > 1})
    if dupes:
        sys.exit(f"tabs listed more than once: {' '.join(d.removesuffix('Page') for d in dupes)}")
    unknown = sorted(set(listed) - pages.keys())
    if unknown:
        known = " ".join(sorted(p.removesuffix("Page") for p in pages))
        sys.exit(f"unknown tabs: {' '.join(u.removesuffix('Page') for u in unknown)}\nknown tabs: {known}")
    leftover = [p for p in pages if p not in listed]
    if leftover:
        # keep them in the layout but hidden, so the Window menu can still show them
        if not layout["right"]:
            layout["right"].append([])
        layout["right"][-1] += leftover

    for side, groups in layout.items():
        objects = shelf_for[side].find("Objects")
        objects.clear()
        for group in groups:
            book = ET.SubElement(objects, "WndProfObject", {TYPE: "Book", **book_attrs})
            book.set("DockedHeightValue", book_height.get(group[0]) or "220")
            book.set("FloatingLeft", "NaN")
            book.set("FloatingTop", "NaN")
            book_pages = ET.SubElement(book, "Pages")
            for i, pid in enumerate(group):
                page = pages[pid]
                page.set("IsSelected", "true" if i == 0 else "false")
                page.set("IsVisible", "false" if pid in leftover else "true")
                book_pages.append(page)
    float_site.find("Objects").clear()

    backup = PROFILE.with_name(f"WindowProfile.{time.strftime('%Y%m%d-%H%M%S')}.xml.bak")
    shutil.copy2(PROFILE, backup)
    ET.indent(tree, "\t")
    xml = ET.tostring(root, encoding="unicode")
    # ElementTree drops the unused xsd namespace; keep the header identical to Affinity's own
    if "xmlns:xsd" not in xml.split(">", 1)[0]:
        xml = xml.replace("<WindowProfile ", '<WindowProfile xmlns:xsd="http://www.w3.org/2001/XMLSchema" ', 1)
    with open(PROFILE, "w", encoding="utf-8-sig") as out:
        out.write('<?xml version="1.0" encoding="utf-8"?>\n')
        out.write(xml)
    print(f"layout written from {spec} (backup: {backup.name})")
    if leftover:
        print("hidden (not in spec): " + " ".join(p.removesuffix("Page") for p in leftover))


if __name__ == "__main__":
    main()
