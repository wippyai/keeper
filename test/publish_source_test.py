import os
import subprocess
import tempfile
import unittest
from pathlib import Path


MAKEFILE = Path(__file__).resolve().parents[1] / "Makefile"


class PublishSourceTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="keeper-publish-source-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.env = dict(os.environ, GIT_AUTHOR_NAME="Rodrigo Delduca",
                        GIT_AUTHOR_EMAIL="rodrigo@delduca.org",
                        GIT_COMMITTER_NAME="Rodrigo Delduca",
                        GIT_COMMITTER_EMAIL="rodrigo@delduca.org")
        self.origin = self.root / "origin.git"
        self.source = self.root / "source"
        self.working = self.root / "working"
        self.git(self.root, "init", "--bare", "--initial-branch=release", str(self.origin))
        self.git(self.root, "init", "--initial-branch=release", str(self.source))
        (self.source / "keeper/static").mkdir(parents=True)
        (self.source / "keeper/static/app.js").write_text("built")
        self.git(self.source, "add", "keeper/static/app.js")
        self.commit(self.source, "return 'initial'\n")
        self.git(self.source, "remote", "add", "origin", str(self.origin))
        self.git(self.source, "push", "origin", "release")
        self.git(self.root, "clone", str(self.origin), str(self.working))

    def git(self, directory, *arguments):
        return subprocess.run(["git", *arguments], cwd=directory, env=self.env,
                              capture_output=True, text=True, check=True).stdout

    def commit(self, directory, content):
        (directory / "source.lua").write_text(content)
        self.git(directory, "add", "source.lua")
        self.git(directory, "commit", "-m", "Update source")

    def check_source(self):
        return subprocess.run(["make", "-f", str(MAKEFILE), "publish-source-check"],
                              cwd=self.working, env=self.env, capture_output=True, text=True)

    def test_fresh_clean_source_can_publish(self):
        result = self.check_source()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_stale_source_cannot_publish(self):
        self.commit(self.source, "return 'fixed'\n")
        self.git(self.source, "push", "origin", "release")
        result = self.check_source()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("source is behind", result.stdout + result.stderr)

    def test_dirty_tracked_source_cannot_publish(self):
        (self.working / "source.lua").write_text("return 'uncommitted'\n")
        result = self.check_source()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("tracked files", result.stdout + result.stderr)

    def test_staged_source_cannot_publish(self):
        (self.working / "source.lua").write_text("return 'staged'\n")
        self.git(self.working, "add", "source.lua")
        result = self.check_source()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("tracked files", result.stdout + result.stderr)

    def test_release_commit_on_fresh_source_can_publish(self):
        self.commit(self.working, "return 'release'\n")
        result = self.check_source()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_untracked_build_output_does_not_block_publication(self):
        (self.working / "bundle.js").write_text("built")
        result = self.check_source()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_generated_frontend_output_does_not_block_publication(self):
        (self.working / "keeper/static/app.js").write_text("rebuilt")
        result = self.check_source()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_every_publish_target_checks_source_before_publication(self):
        self.commit(self.source, "return 'fixed'\n")
        self.git(self.source, "push", "origin", "release")
        for name in ["keeper", "usage"]:
            (self.working / name).mkdir(exist_ok=True)
        marker = self.root / "published"
        publisher = self.root / "publisher"
        publisher.write_text("#!/bin/sh\nprintf published > \"$PUBLISH_TEST_MARKER\"\n")
        publisher.chmod(0o700)
        override = self.root / "publish.mk"
        override.write_text("include " + str(MAKEFILE) + "\n" + "\n".join(
            name + ":\n\t@:" for name in ["build-keeper-frontend", "build-keeper-git-frontend",
                                           "build-wippy-monaco-frontend", "build-usage-frontend"]))
        for target in ["publish-keeper", "publish-usage", "publish-keeper-dry-run", "publish-usage-dry-run"]:
            with self.subTest(target=target):
                result = subprocess.run(["make", "-f", str(override), target,
                                         "WIPPY=" + str(publisher), "KEEPER_VERSION=1.0.0", "USAGE_VERSION=1.0.0"],
                                        cwd=self.working, env=dict(self.env, PUBLISH_TEST_MARKER=str(marker)),
                                        capture_output=True, text=True)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("source is behind", result.stdout + result.stderr)
                self.assertFalse(marker.exists())


if __name__ == "__main__":
    unittest.main()
