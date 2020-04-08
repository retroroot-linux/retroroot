"""Retroroot docker build support"""
from support.linux.log import Log
from support.linux.shell import Shell


class RetrorootDocker:

    def __init__(self, args):
        self.logger = Log(__name__, args.verbose)
        self.shell = Shell(args.verbose)

    def build(self):
        self.logger.info("Building docker container in which to build retroroot")
        self.shell.run_command_verbose("docker-compose -f docker/docker-compose.yml build")
