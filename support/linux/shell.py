"""Copyright (C) 2019 Zeco Systems Pte. Ltd. All rights reserved.

All information contained herein is, and remains the property of
Zeco Systems Pte. Ltd. The intellectual and technical concepts contained
herein are proprietary to Zeco Systems Pte. Ltd. and may be covered by U.S.
and Foreign Patents, patents in process, and are protected by trade secret
or copyright law. Dissemination of this information or reproduction of this
material is strictly forbidden unless prior written permission is obtained
from Zeco Systems Pte. Ltd.
"""
import sys
import io
from contextlib import redirect_stderr
from subprocess import Popen, PIPE
from linux.log import Log, logging

try:
    import pexpect
except ImportError:
    print("pexpect not installed, please install linux[shell]")
    exit(1)


class Shell:
    """Shell tools."""

    def run_command_verbose(self, command, timeout=600, return_output=False, raise_on_error=True):
        """Run a shell command with more verbose output.

        :param command: The command to run
        :param timeout: The timeout of the command
        :param return_output: Return all of the output from the command.
        :param raise_on_error: Raise an IOError if the command fails, else return the output.
        :return: If return_output: The output of the command
                 0 otherwise.
        :raises IOError: If the command fails to run
        :raises OSError: If the command fails to run
        """
        self.log.info("Running: %s", command)
        output = []
        process = pexpect.spawn(command, timeout=timeout, encoding='utf-8')
        while True:
            try:
                index = process.expect(['\r', '\n'])
                message = \
                    process.before.replace('\n', '').encode('utf-8').decode('ascii', 'ignore')
                if not index:
                    sys.stdout.write("\r" + message)
                if index == 1:
                    sys.stdout.write(message + "\n")
                    sys.stdout.flush()
                output_buffer = process.before.rstrip().replace('\n', '')
                if output_buffer:
                    output.append(output_buffer)
            except pexpect.EOF:
                message = \
                    process.before.replace('\n', '').replace("b'", '').replace('\\n', "\n")
                sys.stdout.write(message + "\n")
                sys.stdout.flush()
                output_buffer = process.before.rstrip().replace('\n', '')
                if output_buffer:
                    output.append(output_buffer)
                break
        process.close()
        if process.exitstatus and raise_on_error:
            raise IOError("Failed to run command: " + command)
        if return_output:
            return output
        return 0

    def run_command_pipe(self, command, return_output=False, raise_on_error=True):
        """Run a given command and checks the output.

        :rtype: bool
        :rtype: string
        :param command: The command to run.
        :param return_output: Return all of the output of the command.
        :param raise_on_error: Raise an IOError if the command fails, else return the output.
        :return:
            True on success.
            False on error.
            All output if return_output is set.
            Last line of output if return_last_output is set.
        :raises IOError: If the command fails to run
        :raises OSError: If the command fails to run
        """
        file_io = io.StringIO()
        with redirect_stderr(file_io):
            try:
                cmd = Popen(command, shell=True, stdout=PIPE, stderr=PIPE)
                output, errors = cmd.communicate()
                cmd.wait()
                lines = output.decode('utf-8').splitlines()
                error_lines = errors.decode('utf-8').splitlines()

                if cmd.returncode or error_lines and raise_on_error:
                    self.log.error(error_lines)
                    raise IOError("Failed to run command: " + command)
                if return_output:
                    return lines
                return True
            except OSError as err:
                if raise_on_error:
                    raise OSError(str(err) + ":" + " ".join(error_lines))
                if return_output:
                    return error_lines

    def run_command(self, command, return_output=False, timeout=600, raise_on_error=True):
        """Run a shell command."""
        if self.verbose:
            return self.run_command_verbose(command, timeout, return_output, raise_on_error)
        return self.run_command_pipe(command, return_output, raise_on_error)

    def __init__(self, verbose):
        """Initialize the shell class.

        :param verbose: Print the shell commands before running them.
        :param logging_level: The level of which to log.
        """
        logging_level = logging.DEBUG if verbose else logging.INFO
        self.verbose = bool(verbose)
        self.log = Log(__name__, logging_level)
