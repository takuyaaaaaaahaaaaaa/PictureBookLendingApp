#!/usr/bin/env python3
"""手書きの変異リストでテストの検出力を確認する簡易ミューテーションテスト。

使い方（プロジェクトルートから）:
    python3 scripts/mutation_probe.py PictureBookLendingDomain
    python3 scripts/mutation_probe.py PictureBookLendingDomain --only ISBN

scripts/mutants/<モジュール名>.json の各変異（file / from / to / note）を
ソースへ1件ずつ適用し、`swift test` が失敗すれば killed、
全部通れば survived（テストの穴）として報告する。survived があれば終了コード1。

変異は終了時に必ず元へ戻す（例外・Ctrl-C でも復元する）。
新しい境界条件や定数テーブルを実装したら、対応する変異を追記すること。
"""

import argparse
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
APP = ROOT / "PictureBookLendingAdminApp"


def run_tests(module_dir: Path) -> bool:
    result = subprocess.run(
        ["swift", "test"], cwd=module_dir, capture_output=True, text=True
    )
    return result.returncode == 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("module", help="例: PictureBookLendingDomain")
    parser.add_argument("--only", help="note / file にこの文字列を含む変異だけ実行")
    args = parser.parse_args()

    module_dir = APP / args.module
    mutants_path = ROOT / "scripts" / "mutants" / f"{args.module}.json"
    mutants = json.loads(mutants_path.read_text(encoding="utf-8"))
    if args.only:
        mutants = [m for m in mutants if args.only in m["file"] or args.only in m["note"]]

    if not run_tests(module_dir):
        print("ベースライン（変異なし）のテストが失敗しています。先に直してください。")
        return 2

    survived = []
    for mutant in mutants:
        path = module_dir / mutant["file"]
        original = path.read_text(encoding="utf-8")
        if mutant["from"] not in original:
            print(f"NOT FOUND: {mutant['file']} :: {mutant['from']}（変異リストが古い可能性）")
            survived.append(mutant)
            continue
        try:
            path.write_text(original.replace(mutant["from"], mutant["to"], 1), encoding="utf-8")
            killed = not run_tests(module_dir)
        finally:
            path.write_text(original, encoding="utf-8")
        print(f"{'killed  ' if killed else 'SURVIVED'}: {mutant['note']}")
        if not killed:
            survived.append(mutant)

    print(f"\n{len(mutants) - len(survived)}/{len(mutants)} killed")
    return 1 if survived else 0


if __name__ == "__main__":
    sys.exit(main())
