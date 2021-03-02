#!/usr/bin/env python3
from lib.init_parse import InitParse


def main():
    init = InitParse("env.json")
    init.clean_all()
    init.apply_configs()
    init.update_buildroot()
    init.build_all()


if __name__ == "__main__":
    main()
