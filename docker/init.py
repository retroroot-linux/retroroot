#!/usr/bin/env python3
import os
import sys
import signal
from typing import List
from lib.files import Files
from lib.init_parse import InitParse
from lib.logger import Logger


def signal_handler(sig, _):
    """Handle signals.

    :param int sig: The signal of which to handle.
    :param object _: unused frame stack.
    """
    if sig == signal.SIGINT:
        print("\n## Exiting. ##\n")
        sys.exit(0)


class Init:
    def run(self):
        for env_file in self.env_files:
            init = InitParse(
                env_file, self.apply_configs, self.nb, self.clean_after_build
            )
            if not init.run():
                sys.exit(-1)
            os.chdir(self.cwd)

    def check_env_files(self):
        env_files: List[str] = os.environ.get("ENV_FILES", "x86_64.json").split(":")
        if not env_files:
            self.logger.error("No environment files defined!")
            sys.exit(-1)

        for i, _ in enumerate(env_files):
            env_file = env_files[i].replace('"', "")
            self.env_files.append(f"/mnt/docker/{env_file}")
            if not Files.exists(self.env_files[i]):
                self.logger.error(f"{self.env_files[i]}: No such file")
                sys.exit(-1)

    def parse_env(self):
        self.apply_configs = os.environ.get("APPLY_CONFIGS", False)
        self.clean_after_build = (
            True
            if os.environ.get("CLEAN_AFTER_BUILD", "false").lower() == "true"
            else False
        )
        # NO_BUILD
        self.nb = (
            True if os.environ.get("NO_BUILD", "false").lower() == "true" else False
        )
        if self.nb:
            self.logger.info("NO_BUILD environment variable set. Skipping build step!")
        self.check_env_files()

    def __init__(self):
        self.logger = Logger(__name__)
        self.cwd: str = os.getcwd()
        self.env_files: List[str] = []
        self.apply_configs: bool = False
        self.clean_after_build: bool = False
        self.nb: bool = False


def main():
    signal.signal(signal.SIGINT, signal_handler)
    init = Init()
    init.parse_env()
    init.run()
    sys.exit(0)


if __name__ == "__main__":
    main()
