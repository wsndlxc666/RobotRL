#!/usr/bin/env python
"""Add RoboCasa bbox sites to objaverse model.xml files that lack them.

The HF `robocasa/robocasa-assets` objaverse.zip ships models with a `reg_bbox`
box geom (half-extents in `size`, center in `pos`) but without the three sites
that RoboCasa's sampler expects. The official generator derives those sites
from the same bounding box, so we reproduce that here.
"""
import argparse
import glob
import os
import xml.etree.ElementTree as ET


def fmt(v):
    return f"{v:.9g}"


def patch_model(path, dry_run=False):
    tree = ET.parse(path)
    root = tree.getroot()
    worldbody = root.find("worldbody")
    if worldbody is None:
        return "no-worldbody"
    outer_body = worldbody.find("body")
    if outer_body is None:
        return "no-body"

    names = {s.get("name") for s in outer_body.findall("site")}
    needed = {"bottom_site", "top_site", "horizontal_radius_site"}
    if needed.issubset(names):
        return "already"

    reg = None
    for geom in outer_body.iter("geom"):
        if geom.get("name") == "reg_bbox":
            reg = geom
            break
    if reg is None:
        return "no-reg_bbox"
    px, py, pz = [float(x) for x in (reg.get("pos") or "0 0 0").split()]
    sx, sy, sz = [float(x) for x in (reg.get("size") or "0 0 0").split()]

    specs = [
        ("bottom_site", px, py, pz - sz),
        ("top_site", px, py, pz + sz),
        ("horizontal_radius_site", px + sx, py + sy, pz),
    ]
    for name, x, y, z in specs:
        if name in names:
            continue
        site = ET.SubElement(outer_body, "site")
        site.set("rgba", "0 0 0 0")
        site.set("size", "0.005")
        site.set("pos", f"{fmt(x)} {fmt(y)} {fmt(z)}")
        site.set("name", name)
    if not dry_run:
        tree.write(path, encoding="utf-8", xml_declaration=True)
    return "patched"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", required=True)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()
    counts = {}
    for path in glob.glob(os.path.join(args.root, "**", "model.xml"), recursive=True):
        try:
            status = patch_model(path, args.dry_run)
        except Exception as e:  # noqa: BLE001
            status = f"error:{type(e).__name__}"
        counts[status] = counts.get(status, 0) + 1
    print(counts)


if __name__ == "__main__":
    main()
