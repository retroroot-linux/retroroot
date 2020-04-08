#!/usr/bin/env python3
"""Use this file to setup a build environment."""
import os
import argparse
from support.linux.log import Log
from support.docker_wrapper.retroroot import RetrorootDocker
CWD = os.getcwd()


def parse_args(args):
    """Parse arguments.

    :return: The argument object.
    """
    parser = argparse.ArgumentParser()

    parser.add_argument("-b", "--build",
                        default=False,
                        action="store_true",
                        help="Build")

    parser.add_argument("-s", "--setup",
                        default=False,
                        action="store_true",
                        help="setup")

    parser.add_argument("--verbose",
                        default=False,
                        action="store_true",
                        help="Prepare verbosely")

    return parser.parse_args(args)


def main(args=None):
    # logger = Log("retroroot", args.verbose)
    args = parse_args(args)
    if args.build:
        retroroot_docker = RetrorootDocker(args)
        retroroot_docker.build()


if __name__ == '__main__':
    main()
