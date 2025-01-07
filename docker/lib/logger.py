from inspect import getframeinfo, stack
import logging


class MyFormatter(logging.Formatter):
    """Easy format changing for the logger."""

    def __init__(self, fmt):
        """Initialize the class."""
        logging.Formatter.__init__(self, fmt)

    def format(self, record):
        """Set the log format.

        :param record: A log record format.
        :return: The new message format.
        """
        message = logging.Formatter.format(self, record)
        check = "\n".join([x for x in message.split("\n")])
        return check


class Logger:
    """Handle logging in a reproducible format."""

    @staticmethod
    def __parse_stack_info(stack_info):
        """Get the filename and line number for stack output.

        :param stack_info: The stack info function return.
        :return: filename:lineno
        """
        caller = getframeinfo(stack_info[1][0])
        return f"{caller.filename}:{str(caller.lineno)}"

    def __set_formatter(self, log_format=None, default=False):
        """Set the formatter to either a custom format or the default format.

        :param log_format: The format for the log message.
        :param default: If set, the default log format will be used.
        """
        if not default:
            self.stream_handler.setFormatter(MyFormatter(log_format))
            if self.file_path:
                self.file_handler.setFormatter(MyFormatter(log_format))
        else:
            self.stream_handler.setFormatter(MyFormatter(self.log_format))
            if self.file_path:
                self.file_handler.setFormatter(MyFormatter(self.log_format))

    def debug(self, message, *args, **kwargs):
        """Pass-through convenience function to print an debug message.

        :param message: The message to print.
        :param args: The args to pass
        :param kwargs: optional kwargs
        """
        stack_info = self.__parse_stack_info(stack())
        log_format = f"{stack_info} {self.log_format}"
        self.__set_formatter(log_format)
        self.logger.debug(message, *args, **kwargs)
        self.__set_formatter(default=True)

    def info(self, message, *args, **kwargs):
        """Pass-through convenience function to print an info message.

        :param message: The message to print.
        :param args: The args to pass
        :param kwargs: optional kwargs
        """
        self.logger.info(message, *args, **kwargs)

    def warning(self, message, *args, **kwargs):
        """Pass-through convenience function to print an warning message.

        :param message: The message to print.
        :param args: The args to pass
        :param kwargs: optional kwargs
        """
        self.logger.warning(message, *args, **kwargs)

    def error(self, message, *args, **kwargs):
        """Pass-through convenience function to print an error message.

        :param message: The message to print.
        :param args: The args to pass
        :param kwargs: optional kwargs
        """
        if self.level == logging.DEBUG:
            log_format = f"{self.__parse_stack_info(stack())} {self.log_format}"
            self.__set_formatter(log_format)
        self.logger.error(message, *args, **kwargs)
        if self.level == logging.DEBUG:
            self.__set_formatter(default=True)

    def exception(self, message, *args, **kwargs):
        """Pass-through convenience function to print an error with exception information.

        :param message: The message to print.
        :param args: The args to pass
        :param kwargs: optional kwargs
        """
        if self.level == logging.DEBUG:
            log_format = f"{self.__parse_stack_info(stack())} {self.log_format}"
            self.__set_formatter(log_format)
        self.logger.exception(message, *args, **kwargs)
        if self.level == logging.DEBUG:
            self.__set_formatter(default=True)

    def critical(self, message, *args, **kwargs):
        """Pass-through convenience function to print a critical error message.

        :param message: The message to print.
        :param args: The args to pass
        :param kwargs: optional kwargs
        """
        if self.level == logging.DEBUG:
            log_format = f"{self.__parse_stack_info(stack())} {self.log_format}"
            self.__set_formatter(log_format)
        self.logger.critical(message, *args, **kwargs)
        if self.level == logging.DEBUG:
            self.__set_formatter(default=True)

    def __init__(
        self,
        name,
        stream_level=logging.INFO,
        custom_log_format=None,
        file_path=None,
        file_level=logging.INFO,
        clear_log_file=False,
    ):
        """Initialize the log class."""
        self.level = stream_level
        self.file_name = file_path
        self.log_format = "%(asctime)s:%(levelname)s:%(message)s"
        self.file_path = file_path
        if self.level == logging.DEBUG:
            self.log_format = "%(asctime)s:%(levelname)s:%(name)s %(message)s"
        if custom_log_format:
            self.log_format = custom_log_format

        # Create the logger with the given name and level
        self.logger = logging.getLogger(name)
        self.logger.setLevel(logging.DEBUG)

        if self.logger.hasHandlers():
            self.logger.handlers.clear()

        # Create the stream logger for output handling
        self.stream_handler = logging.StreamHandler()
        self.stream_handler.setLevel(stream_level)
        self.stream_handler.setFormatter(MyFormatter(self.log_format))
        self.logger.addHandler(self.stream_handler)

        if self.file_path:
            self.file_handler = logging.FileHandler(
                file_path, "w" if clear_log_file else "a"
            )
            self.file_handler.setLevel(file_level)
            self.file_handler.setFormatter(MyFormatter(self.log_format))
            self.logger.addHandler(self.file_handler)
