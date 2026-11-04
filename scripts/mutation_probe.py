#!/usr/bin/env python3
"""手書きの変異リストでテストの検出力を確認する簡易ミューテーションテスト。

使い方（プロジェクトルートから）:
    python3 scripts/mutation_probe.py PictureBookLendingDomain
    python3 scripts/mutation_probe.py PictureBookLendingDomain --only ISBN

scripts/mutants/<モジュール名>.json の各変異（file / from / to / note）を
ソースへ1件ずつ適用し、`swift test` が失敗すれば killed、
全部通れば survived（テストの穴）として報告する。survived があれば終了コード1。

変異は例外・Ctrl-C では元へ戻す（SIGKILL 等の強制終了では戻らないため、
実行前に対象ファイルが未コミットの変更を持たないことを要求し、
万一残っても `git checkout -- <file>` で復元できるようにしている）。
ビルドが通らない変異は killed ではなく BUILD ERROR として扱い、失敗終了にする。
新しい境界条件や定数テーブルを実装したら、対応する変異を追記すること。
"""

import argparse
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
APP = ROOT / "PictureBookLendingAdminApp"


def run(module_dir: Path, *command: str) -> bool:
    return subprocess.run(
        command, cwd=module_dir, capture_output=True, text=True
    ).returncode == 0


def builds(module_dir: Path) -> bool:
    return run(module_dir, "swift", "build", "--build-tests")


def passes_tests(module_dir: Path) -> bool:
    return run(module_dir, "swift", "test")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("module", help="例: PictureBookLendingDomain")
    parser.add_argument("--only", help="note / file にこの文字列を含む変異だけ実行")
    args = parser.parse_args()

    module_dir = APP / args.module
    mutants_path = ROOT / "scripts" / "mutants" / f"{args.module}.json"
    if not mutants_path.exists():
        print(f"{mutants_path.relative_to(ROOT)} がありません。変異リストを作成してください。")
        return 2
    mutants = json.loads(mutants_path.read_text(encoding="utf-8"))
    if args.only:
        mutants = [m for m in mutants if args.only in m["file"] or args.only in m["note"]]

    if not mutants:
        print("対象の変異が0件です（--only の指定を確認してください）。")
        return 2

    dirty = subprocess.run(
        ["git", "status", "--porcelain", "--", *{m["file"] for m in mutants}],
        cwd=module_dir, capture_output=True, text=True,
    ).stdout.strip()
    if dirty:
        print(f"変異対象に未コミットの変更があります。先にコミットしてください:\n{dirty}")
        return 2

    if not passes_tests(module_dir):
        print("ベースライン（変異なし）のテストが失敗しています。先に直してください。")
        return 2

    problems = []
    for mutant in mutants:
        path = module_dir / mutant["file"]
        original = path.read_text(encoding="utf-8")
        occurrences = original.count(mutant["from"])
        if occurrences != 1:
            print(f"BAD PATTERN ({occurrences}件一致): {mutant['note']} :: {mutant['from']}")
            problems.append(mutant)
            continue
        try:
            path.write_text(original.replace(mutant["from"], mutant["to"]), encoding="utf-8")
            if not builds(module_dir):
                print(f"BUILD ERROR: {mutant['note']}（変異がコンパイルできない。to を見直す）")
                problems.append(mutant)
                continue
            killed = not passes_tests(module_dir)
        finally:
            path.write_text(original, encoding="utf-8")
        print(f"{'killed  ' if killed else 'SURVIVED'}: {mutant['note']}")
        if not killed:
            problems.append(mutant)

    print(f"\n{len(mutants) - len(problems)}/{len(mutants)} killed")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
