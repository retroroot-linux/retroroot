"""Retroroot docker build support"""
import os
from support.linux.log import Log
from support.linux.shell import Shell
from support.docker_wrapper.containers import PyDockerContainers


class RetrorootDocker:

    def __init__(self, args):
        self.cwd = os.getcwd()
        self.logger = Log(__name__, args.verbose)
        self.shell = Shell(args.verbose)
        self.containers = PyDockerContainers(args.verbose)
        self.builder_name = 'retroroot-builder'

    def env_check(self):
        output_dir = self.cwd + '/build/output'
        if not os.path.isdir(output_dir):
            os.makedirs(output_dir)

    def build(self):
        container_name="retroroot-builder"
        if self.containers.search(self.builder_name):
            self.containers.stop(self.builder_name)
        self.logger.info("Setting up docker container: %s.", self.builder_name)
        self.env_check()
        self.shell.run_command_verbose("docker-compose -f .docker-compose.yml build")
        self.logger.info("Running %s.", self.builder_name)
        self.shell.run_command_verbose("docker-compose -f .docker-compose.yml up -d")
        self.containers.exec_run(container_name, "cp utils/brmake /usr/bin/brmake", detach=False, workdir="/home/br-user/buildroot", stream=True)
        self.containers.exec_run(container_name, "make retroroot_x86_64_KMS_defconfig BR2_EXTERNAL=retroarch/package  O=output/x86_64/KMS", user="br-user", detach=False, workdir="/home/br-user/buildroot", stream=True)
        self.containers.exec_run(container_name, "brmake", user="br-user", detach=False, workdir="/home/br-user/buildroot/output/x86_64/KMS", stream=True)
