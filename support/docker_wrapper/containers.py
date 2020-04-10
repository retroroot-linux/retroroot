"""Container wrappers."""
import sys
import threading
import time
import queue
from linux.log import Log, logging
from linux.shell import Shell
import docker
from docker import errors as docker_errors


# pylint: disable=too-few-public-methods
class StreamQueue:
    """A class used to print the stream generator.

    Using this class prevents the stream from blocking the stream thread.
    """

    @staticmethod
    def monitor_stream(exe_start, line_prefix):
        """Monitor a streams generator in a non-blocking manner.

        :param exe_start: The stream generator.
        :param line_prefix: The prefix of which to attach to the output.
        """
        buff_prefix = str(line_prefix) + ":"
        for line in exe_start:
            try:
                line = buff_prefix + line.decode('utf-8').strip()
            except UnicodeDecodeError:
                line = buff_prefix + str(line)
            if line:
                print(line)

    def __init__(self):
        """Initialize the class."""
        self.queue = queue.Queue()


# pylint: disable=too-many-instance-attributes
class StreamWatchDog:
    """A simple watch dog class of which a exec_run thread uses to keep track of a stream."""

    def stop_stream(self):
        """Set self.stop to true, this should stop a stream."""
        self.stop = True

    def watch(self, container_class, stream, thread_id):
        """Watch a thread.

        :param container_class: The class of which the container was created.
        :param stream: The stream thread of which to monitor.
        :param thread_id: The id of the thread of which to monitor.
        :returns: False on not ok, True on clean stop.
        """
        while True:
            if not stream.is_ok:
                container_class.stop_running_stream(thread_id, stream)
                return False
            if stream.stop:
                return True
            if stream.process_stopped:
                return True
            if self.timeout:
                if int(time.time()) >= self.timeout:
                    self.stop = True
            time.sleep(.5)

    def __init__(self, kill_signal="SIGINT", max_runtime=None, expected_exit_code=0,
                 container_name=None):
        """Initialize the class."""
        self.is_ok = True
        self.stop = False
        self.exit_code = 0
        self.expected_exit_code = expected_exit_code
        self.exec_pid = 0
        self.kill_signal = kill_signal  # Equivalent to ctrl+c
        self.timeout = None
        self.container_name = container_name
        self.process_name = None
        self.process_stopped = False
        if max_runtime:
            self.timeout = int(time.time()) + max_runtime


class PyDockerContainers:
    """Functions to cleanly handle docker containers."""

    def search(self, container_name, filters=None):
        """Search for a docker container.

        :param container_name: The name of the container.
        :param filters: A dictionary of filters
        :return: The container object on success, None if not found.
        """
        if not filters:
            filters = {}
        containers = self.client.containers.list(all=True, filters=filters)
        for container in containers:
            if container.name == container_name:
                return container
        return None

    def start(self, image_name, tag="latest", **kwargs):
        """Start a container.

        :param image_name: The name of the image of which to use.
        :param tag: The tag of the image of which to use.
        :param kwargs: Optional arguments.
        args:
           init_string: An initialization string used in place of the default CMD in the
           DockerFile.

           detach: Detach the docker image (same as docker -d)
           container_name: An optional name to give the container.

           remove_if_in_use: If a container with the same name already exists, remove it before
           running. Default is False.

           kill_if_in_use: Same as above, except kill the container.

           tty: (Bool) Allocate a pseudo-TTY
        :return: The container object on success.
        :raises ImageNotFound: If the image is not found.
        :raises APIError: If the container fails to start.
        :raises ContainerError: If the container name is already in use and the remove_if_in_use
                                flag is not set.

        """
        init_string = kwargs.get("init_string", None)
        detach = kwargs.get("detach", True)
        container_name = kwargs.get("container_name", None)
        remove = kwargs.get("remove_if_in_use", False)
        tty = kwargs.get("tty", False)
        kill = kwargs.get("kill", False)
        name = image_name + ':' + tag
        try:
            image = self.client.images.get(name=name)
        except docker_errors.ImageNotFound:
            raise docker_errors.ImageNotFound("Image %s not found!" % name)

        try:
            container = self.search(container_name)
            if container and not remove:
                raise docker_errors.ContainerError(
                    container, 409, "Conflict", image,
                    "Container name " + image_name +
                    " is already in use and the remove_if_in_use flag is not set.")
            if container and remove:
                self.search_and_remove(container.name, kill=kill)
            container = self.client.containers.run(
                image, init_string, detach=detach, name=container_name, tty=tty)
            return container
        except docker_errors.APIError as err:
            raise docker_errors.APIError(err)

    def stop(self, container_name, remove=False):
        """Stop a container if it's running."""
        container = self.search(container_name)
        if container:
            container.stop()
        if remove:
            container.remove()

    def search_and_remove(self, container_name, kill=False):
        """Search for a container, and if found, stop and remove it.

        :param container_name: The name of the container.
        :param kill: kill a container instead of stopping it.
        :return: True on success, False if not found.
        """
        container = self.search(container_name)
        if container:
            if kill:
                self.logger.info("Container %s is running, killing and removing", container.name)
                container.kill()
            else:
                self.logger.info("Container %s is running, stopping and removing", container.name)
                container.stop()
            container.remove()
            return True
        return False

    def kill_process(self, container_name, process_name, level=9, warn=True):
        """Kill a process on a given container using the killall command.

        :param container_name: The name of the container of which to use.
        :param process_name: The name of the process of which to kill.
        :param level: The level of which to kill the process.
        :param warn: If true, a warning will be printed of the command failed.
        :returns: True on success, false on failure.
        """
        kill_command = "killall -{} {}".format(str(level), process_name)
        container = self.search(container_name)
        if container:
            retval, _ = self.exec_run(container_name, kill_command, detach=False)
            if retval:
                kill_command = "pkill -{} {}".format(str(level), process_name)
                retval, _ = self.exec_run(container_name, kill_command, detach=False)
                if retval:
                    if warn:
                        self.logger.warning("Failed to kill process %s", process_name)
                    return False
            return True
        return False

    @staticmethod
    def __check_pid(container, exec_info):
        """Check if a pid exists.

        :param container: The container of which to check.
        :param exec_info: Exec info from the exec_run method.
        :returns: True on running, otherwise False.

        Note:
            This is used because exec_info may say a process is running when it's not.

        """
        macos = bool(sys.platform == "darwin")
        if not exec_info['Running']:
            return False
        pid_num = str(exec_info['Pid'])
        entrypoint = exec_info['ProcessConfig']['entrypoint']
        running = False
        processes = container.top(ps_args="aux")['Processes']
        for process in processes:
            process_pid = process[1]
            process_string = process[0] if macos else process[10]
            if pid_num == process_pid and entrypoint in process_string:
                running = True
                break
        if not running:
            exec_info['Running'] = False
        return running

    def __exec_run_stream(self, container, command, user, workdir, environment, line_prefix,
                          stream_watchdog=None, startup_wait=1):
        """Execute a command on a container using a stream as output.

        :param container: The container of which to run the command on.
        :param command: The command of which to run.
        :param user: The user of which to run the command as.
        :param workdir: The working directory of which to run the command in.
        :param environment: Dictionary or list of strings.
        :param line_prefix: A log prefix.
        :param stream_watchdog: A thread watchdog class of which to subscribe.
            If None, container_name will be used.
        :param startup_wait: The time of which to wait in seconds before checking if a command ran.
        :returns: The exit code of exec_info
        """
        exec_id = self.cli.exec_create(
            container.id, command, tty=True, user=user, workdir=workdir, environment=environment
        )['Id']
        self.logger.info("Executing command: %s as user %s in workdir %s on container %s",
                         command, user, workdir, container.name)
        exe_start = self.cli.exec_start(exec_id, stream=True, tty=True)
        # We must wait for the process to start.
        time.sleep(startup_wait)
        exec_info = self.cli.exec_inspect(exec_id)
        stream_watchdog.exec_pid = exec_info['Pid']
        stream_watchdog.process_name = exec_info['ProcessConfig']['entrypoint']
        stream_queue = threading.Thread(
            target=StreamQueue.monitor_stream, daemon=True, args=(exe_start, line_prefix,))
        stream_queue.start()
        while not stream_watchdog.stop and \
                self.__check_pid(container, exec_info):
            time.sleep(0.5)
        if exec_info['Running']:
            kill_command = "kill -{} {}".format(
                str(stream_watchdog.kill_signal), str(stream_watchdog.exec_pid)
            )
            self.logger.info("Stopping process %s", stream_watchdog.process_name)
            self.shell.run_command(kill_command)
            # wait for the command to finish
            while self.__check_pid(container, exec_info):
                time.sleep(1)
        stream_watchdog.exit_code = self.cli.exec_inspect(exec_id)['ExitCode']
        if stream_watchdog.exit_code != stream_watchdog.expected_exit_code:
            self.logger.error(
                "Exit code: %s did not match expected exit code: %s for command: %s",
                str(stream_watchdog.exit_code), stream_watchdog.expected_exit_code,
                stream_watchdog.process_name
            )
            stream_watchdog.is_ok = False
        self.logger.debug(
            "Process %s exited on container %s with exit code %s",
            stream_watchdog.process_name, container.name, str(stream_watchdog.exit_code)
        )
        stream_watchdog.process_stopped = True
        return stream_watchdog.exit_code

    def __run_stream(self, container, command, user, workdir, environment, block, startup_wait=1,
                     line_prefix=None, kill_signal="SIGINT", max_runtime=None,
                     expected_exit_code=0):
        """Run a command in a docker container using a stream.

        :param container: The container of which to run the command on.
        :param command: The command of which to run.
        :param user: The user of which to run the command as.
        :param workdir: The working directory of which to run the command in.
        :param environment: Dictionary or list of strings.
        :param block: Set the stream as blocking or not.
        :param startup_wait: The time of which to wait in seconds before checking if a command ran.
        :param line_prefix: A prefix of which to log.
        :param kill_signal: A signal of which to use when killing the process.
            Default: SIGINT
        :param max_runtime: Set a maximum runtime for a given command.
            If None, the command will run forever or until it quits.
        :param expected_exit_code: The expected exit code when the process exits. Default 0.
        :returns:
            The exit code of the command if block is True.
            The Thread ID if block is False on success.
            None if block is False on failure.

        If blocking is set, a stream id will be returned. To stop the stream, the
        stop_running_stream method should be called.
        """
        stream_watchdog = StreamWatchDog(
            kill_signal, max_runtime, expected_exit_code, container.name)

        stream_thread = threading.Thread(
            target=self.__exec_run_stream, daemon=True,
            args=(container, command, user, workdir, environment, line_prefix, stream_watchdog,
                  startup_wait,)
        )
        stream_thread.start()
        self.streams.update({stream_thread: stream_watchdog})
        if not stream_watchdog.is_ok:
            self.logger.error("Failed to start stream with command: %s", command)
            self.stop_running_stream(stream_thread, stream_watchdog)
            return None

        stream_watchdog_thread = threading.Thread(
            target=stream_watchdog.watch, daemon=True, args=(
                self, self.streams[stream_thread], stream_thread,)
        )
        stream_watchdog_thread.start()
        if block:
            while not stream_watchdog.stop and not stream_watchdog.process_stopped:
                time.sleep(1)
            return stream_watchdog
        return stream_thread, stream_watchdog

    @staticmethod
    def stop_running_stream(thread_id, stream_monitor):
        """Stop a running stream.

        :param thread_id: The thread id of which to stop.
        :param stream_monitor: The stream monitor which belongs to the thread_id.
        :returns: True on clean stop, otherwise False.
        """
        retval = True
        if thread_id.is_alive():
            stream_monitor.stop = True
            thread_id.join()
        if not stream_monitor.is_ok:
            retval = False
        return retval

    @staticmethod
    def __exec_run(container, command, user="root", detach=True, workdir="/",
                   environment=None, line_prefix=None):
        """Execute a command in a container and return the output.

        :param container: The container object.
        :param command: The command of which to run.
        :param user: Run as a given user.
        :param detach: If true, detach from the exec command.
                Note: Detaching will not return a return code!
        :param workdir: Path to working directory for this exec session
        :param environment: Dictionary or list of strings.
        :param line_prefix: A prefix of which to log.
        :return: A tuple consisting of retval, stdout and stderr if detach is false, otherwise
                 A tuple of None, None.
        """
        retval, output = container.exec_run(
            command, stdout=True, stderr=True, user=user, detach=detach, workdir=workdir,
            environment=environment, stream=False, demux=True, tty=True
        )
        if not detach:
            stdout = output[0]
            stderr = output[1]
            if stdout:
                stdout = line_prefix + ":" + stdout.decode("ascii", "ignore")
            if stderr:
                stderr = line_prefix + ":" + stderr.decode("ascii", "ignore")
            retout = (stdout, stderr)
            return retval, retout
        return None, None

    # pylint: disable=too-many-locals
    def exec_run(self, container_name, command, user="root", detach=True, workdir="/",
                 environment=None, stream=False, block=True, startup_wait=1, log_prefix=None,
                 kill_signal="SIGINT", max_runtime=None, expected_exit_code=0):
        """Exec a command for a given container.

        :param container_name: The name of the container.
        :param command: The command of which to run.
        :param user: Run as a given user.
        :param detach: If true, detach from the exec command.
                Note: Detaching will not return a return code!
        :param workdir: Path to working directory for this exec session
        :param environment: Dictionary or list of strings.
        :param stream: If set to true, a generator is created instead of a tuple.
        :param block:
            True: The stream will block.
            False: A thread is generated and the thread_id is returned.
        :param startup_wait: The time of which to wait in seconds before checking if a command ran.
        :param log_prefix: A prefix of which to log.
            If None, container_name will be used.
        :param kill_signal: A signal of which to use when killing the process.
            Default: SIGINT
        :param max_runtime: Set a maximum runtime for a given command.
            If None, the command will run forever or until it quits.
        :param expected_exit_code: The expected exit code when the process exits. Default 0.

        :return: 1 on error, 0 on success, and output of command.
        """
        if not environment:
            environment = []
        container = self.search(container_name)
        if container:
            logging.info("Running command %s for container %s", command, container_name)
            line_prefix = container.name if not log_prefix else log_prefix
            if stream:
                return self.__run_stream(
                    container, command, user, workdir, environment, block, startup_wait,
                    line_prefix, kill_signal, max_runtime, expected_exit_code
                )
            return self.__exec_run(
                container, command, user, detach, workdir, environment, line_prefix)
        self.logger.error("Container with name: %s not found", container_name)
        return None, None

    def safe_prune(self, filters):
        """Stop and remove all containers returned with a given filter.

        :param filters: A dictionary of filters used for removing containers.
        :return: The number of destroyed containers.
        """
        destroyed_containers = []
        containers = self.client.containers.list(all=True, filters=filters)
        for container in containers:
            destroyed_containers.append(container.name)
            container.stop()
            container.remove()
        return destroyed_containers

    def __init__(self, verbose):
        """Initialize the class."""
        self.cli = docker.APIClient(base_url='unix://var/run/docker.sock')
        logging_level = logging.DEBUG if verbose else logging.INFO
        self.client = docker.from_env()
        self.logger = Log(__name__, logging_level)
        self.shell = Shell(logging_level)
        self.stop_stream = False
        self.streams = {}

    def __del__(self):
        """Close the client."""
        if self.client:
            self.client.close()
