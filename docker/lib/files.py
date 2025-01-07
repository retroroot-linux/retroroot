import os
import sys
from lib.logger import Logger


class Files:
    """File tools."""

    @staticmethod
    def remove(file_path):
        """Perform the actual removal of a file.

        :param str file_path: The file to remove
        :returns: True on success, False if file_path is not a file.
        :rtype: bool
        """
        logger = Logger("Files")
        if os.path.isfile(file_path):
            logger.debug(f"rm -rf {file_path}")
            os.remove(file_path)
            return True
        return False

    @staticmethod
    def exists(path, fail: bool = False):
        """Check to see if a file exists.

        :param str path: A path to a file.
        :param bool fail: Exit if the file doesn't exist
        :return: True or False.
        :rtype: bool
        """
        logger = Logger("Files")
        if not os.path.isfile(path):
            if fail:
                logger.error(f"{path}: no such file")
                sys.exit(1)
            return False
        logger.debug(f"File {path} exists")
        return True

    @staticmethod
    def to_buffer(file_location, split=False, split_delim="\n", strip=False):
        """Open a file and read it line by line into a buffer.

        :param str file_location: The location of the file.
        :param bool split: return a split buffer.
        :param str split_delim: The delimiter to split.
        :param bool strip: Strip the buffer.
        :return: Failure if specified file is not a file, a buffer on success.
        :rtype: str
        """
        logger = Logger("Files")
        buff = ""
        try:
            with open(file_location, "rt", encoding="utf-8") as file_location_fd:
                for line in file_location_fd:
                    buff += line
            file_location_fd.close()
            if split:
                return buff.split(split_delim)
            if strip:
                return buff.strip()
            return buff
        except UnicodeDecodeError as err:
            logger.error(f"{file_location}:{err}")
            return None

    @staticmethod
    def save_buffer(file_location, buff, overwrite=False, append=False):
        """Take a buffer and write it to a file at a specified location.

        :param str file_location:   The location of the file.
        :param str buff:            Buffer to write to the file.
        :param bool overwrite:       Overwrite the file
        :param bool append:          Append to the file instead of overwriting it.
        :return: True on success
        :rtype: bool
        :raises FileExistsError: If the file exists and the overwrite flag is not set.
        :raises IsADirectoryError: If the specified file_location is a directory and not a file.
        """
        open_options = "wt" if not append else "a"
        if Files.exists(file_location) and not overwrite and not append:
            raise FileExistsError(f"{file_location} already exists")
        try:
            with open(
                file_location, open_options, encoding="utf-8"
            ) as file_location_fd:
                for line in buff.splitlines():
                    file_location_fd.write(f"{line}\n")
            file_location_fd.close()
            return True
        except IsADirectoryError as err:
            raise IsADirectoryError from err
