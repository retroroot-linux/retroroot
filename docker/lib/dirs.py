import os
import sys
from shutil import rmtree
from lib.logger import Logger


class Dirs:
    """Directory tools."""

    @staticmethod
    def remove(path: str) -> bool:
        """Remove a directory or symlink to a directory if it exists.

        :param str path: The path of the directory to remove.
        :return: True on success, otherwise failure message.
        :rtype: bool
        """
        logger = Logger("Dirs")
        if os.path.isdir(path) or os.path.islink(path) and not os.path.exists(path):
            logger.debug(f"removing dir {path}")
            try:
                rmtree(path)
                return True
            except OSError:
                if os.path.islink(path):
                    os.remove(path)
                    return True
        return False

    @staticmethod
    def make_symlink(source: str, destination: str) -> bool:
        """Create a symlink from source to destination.

        :param source: The source
        :param destination:  The destination
        :return: Success on success, failure message on failure.
        """
        logger = Logger("Dirs")
        if not os.path.isdir(source):
            logger.error(f"{source} is not a directory")
            return False
        if os.path.exists(destination):
            logger.error(f"{destination} already exists!")
            return False
        logger.info(f"Creating symlink from {source} to {destination}")
        logger.debug(f"ln -sf {source} {destination}")
        os.symlink(source, destination)
        return True

    @staticmethod
    def make(path: str, remake: bool = False, fail: bool = False) -> bool:
        """Make a directory.

        :param str path: A directory of which to make.
        :param bool remake: Remove and remake the directory even if it exists.
        :param bool fail: Exit if making the directory fails.
        :return: True on success, False on failure
        :rtype: bool
        """
        logger = Logger("Dirs")
        try:
            if os.path.isdir(path):
                if not remake:
                    return False
                Dirs.remove(path)
            logger.debug(f"Making directory: {path}")
            os.makedirs(path)
            return True
        except FileExistsError as err:
            logger.debug(str(err))
            if fail:
                sys.exit(1)
            return False

    @staticmethod
    def exists(path, make: bool = False, fail: bool = False) -> bool:
        """Check to see if a directory exists.

        :param str path: A path to a directory.
        :param bool make: Make the directory if it doesn't exist.
        :param bool fail: Fail if the path does not exist.
        :return: True or False.
        :rtype: bool
        """
        logger = Logger("Dirs")
        if not os.path.isdir(path):
            logger.debug(f"Directory {path} does not exist")
            if make:
                return Dirs.make(path, fail=fail)
            if fail:
                sys.exit(1)
            return False
        logger.debug(f"Directory {path} exists")
        return True
