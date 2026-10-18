#!/usr/bin/env python3
"""새 파일을 IndonesianSmallTalk.xcodeproj 에 등록한다. 여러 번 돌려도 안전하다(이미 있으면 건너뜀).

사용법 (레포 최상단에서):
    python3 scripts/pbx_add.py IndonesianSmallTalk/Models/Foo.swift IndonesianSmallTalk/Resources/Content/x.json
    python3 scripts/pbx_add.py --keyboard IndonesianSmallTalk/Models/Shared.swift   # 키보드 익스텐션에도 넣기

- IndonesianSmallTalk/<폴더>/... 의 <폴더> 가 Xcode 그룹이 된다(없으면 만든다). 그 아래 경로는 그대로 쓴다.
- .swift 는 Sources, .json/.xcstrings/.mp3 등은 Resources 에 들어간다. .plist/.entitlements 는 파일만 등록.
"""
import hashlib
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PBX = os.path.join(ROOT, "IndonesianSmallTalk.xcodeproj", "project.pbxproj")
APP_DIR = "IndonesianSmallTalk"

TYPES = {
    ".swift": "sourcecode.swift",
    ".json": "text.json",
    ".xcstrings": "text.json.xcstrings",
    ".plist": "text.plist.xml",
    ".entitlements": "text.plist.entitlements",
    ".mp3": "audio.mp3",
    ".m4a": "file",
    ".caf": "file",
    ".png": "image.png",
    ".xcassets": "folder.assetcatalog",
}
NO_PHASE = {".plist", ".entitlements"}


def uid(*parts):
    return "F" + hashlib.md5("|".join(parts).encode()).hexdigest()[:23].upper()


def insert_before(s, marker, text):
    i = s.index(marker)
    return s[:i] + text + s[i:]


def add_to_list(s, owner_id, key, entry):
    """owner_id 블록의 key = ( ... ); 목록 끝에 entry 를 넣는다."""
    m = re.search(r"(?<![A-Za-z0-9_])" + re.escape(owner_id) + r" (/\*.*?\*/ )?= \{", s)
    if not m:
        raise SystemExit(f"블록을 못 찾음: {owner_id}")
    start = s.index(key + " = (", m.end())
    end = s.index(");", start)
    return s[:end] + f"\t{entry},\n\t\t\t" + s[end:]


def ensure_group(s, folder):
    gid = "GRP_" + re.sub(r"[^A-Z0-9]", "_", folder.upper())
    if re.search(re.escape(gid) + r" /\*", s):
        return s, gid
    block = (f"\t\t{gid} /* {folder} */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t);\n"
             f"\t\t\tpath = {folder};\n\t\t\tsourceTree = \"<group>\";\n\t\t}};\n")
    s = insert_before(s, "/* End PBXGroup section */", block)
    s = add_to_list(s, "SRCGRP", "children", f"{gid} /* {folder} */")
    return s, gid


def main():
    args = sys.argv[1:]
    keyboard = "--keyboard" in args
    paths = [a for a in args if not a.startswith("--")]
    s = open(PBX, encoding="utf-8").read()
    for p in paths:
        p = os.path.relpath(os.path.abspath(p), ROOT) if os.path.isabs(p) else p
        parts = p.split("/")
        if parts[0] != APP_DIR or len(parts) < 3:
            raise SystemExit(f"{p}: {APP_DIR}/<폴더>/<파일> 형식이어야 함")
        folder, sub = parts[1], "/".join(parts[2:])
        name = os.path.basename(p)
        ext = os.path.splitext(name)[1]
        ftype = TYPES.get(ext, "file")
        ref = uid("ref", p)
        if ref in s:
            print(f"이미 있음: {p}")
            continue
        s, gid = ensure_group(s, folder)
        s = insert_before(s, "/* End PBXFileReference section */",
                          f"\t\t{ref} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = {ftype}; "
                          f"path = \"{sub}\"; sourceTree = \"<group>\"; }};\n")
        s = add_to_list(s, gid, "children", f"{ref} /* {name} */")
        if ext not in NO_PHASE:
            phases = [("SRCPHASE", "Sources")] if ext == ".swift" else [("RESPHASE", "Resources")]
            if keyboard and ext == ".swift":
                phases.append(("KEXT_SRCPHASE", "Sources"))
            for phase, label in phases:
                bf = uid("build", p, phase)
                s = insert_before(s, "/* End PBXBuildFile section */",
                                  f"\t\t{bf} /* {name} in {label} */ = {{isa = PBXBuildFile; fileRef = {ref} /* {name} */; }};\n")
                s = add_to_list(s, phase, "files", f"{bf} /* {name} in {label} */")
        print(f"추가: {p}")
    open(PBX, "w", encoding="utf-8").write(s)


if __name__ == "__main__":
    main()
