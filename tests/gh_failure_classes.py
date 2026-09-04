"""Ce que gh() retient comme panne, et ce qu'il laisse passer.

Charge le vrai bin/aikit-sync et appelle gh() avec un faux subprocess : c'est
la branche elle-meme qui est testee, pas une copie de sa condition.
"""
import importlib.util
import pathlib
from importlib.machinery import SourceFileLoader
from types import SimpleNamespace

# bin/aikit-sync n'a pas d'extension .py : il faut nommer le chargeur.
ROOT = pathlib.Path(__file__).resolve().parent.parent
loader = SourceFileLoader("aikit_sync", str(ROOT / "bin" / "aikit-sync"))
sync = importlib.util.module_from_spec(importlib.util.spec_from_loader("aikit_sync", loader))
loader.exec_module(sync)


def classify(stderr):
    """"panne" si gh() a retenu ce message, "ignore" sinon."""
    sync.LAST_ERROR = ""
    sync.subprocess.run = lambda *a, **k: SimpleNamespace(returncode=1, stderr=stderr, stdout="")
    sync.gh(["api", "whatever"])
    return "panne" if sync.LAST_ERROR else "ignore"


print(classify("gh api: HTTP 500"),
      classify("the 'phmatray/BodyRocky' repository has disabled issues"))
