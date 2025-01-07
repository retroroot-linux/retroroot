import os
import sys
from typing import Any, Dict, Union
from lib.dirs import Dirs
from lib.buildroot import Buildroot
from lib.external_trees import ExternalTrees
from lib.fragments import Fragments
from lib.json_helper import JSONHelper
from lib.logger import Logger


class Config:
    def apply(self) -> bool:
        """Apply all configs defined in env.json."""
        Dirs.exists(self.buildroot_path, fail=True)
        Dirs.exists(self.config["output_dir"], make=True, fail=True)
        if not Dirs.exists(self.config["build_path"]) or self.config["apply_configs"]:
            cmd = (
                f"BR2_EXTERNAL={self.buildroot_path}/{self.config['external_trees']} "
                f"BR2_DEFCONFIG={self.config['defconfig_path']} "
                f"{self.config['make']} {self.config['defconfig']} "
                f"O={self.config['build_path']}"
            )
            os.chdir(self.buildroot_path)
            self.logger.info(f"Applying {self.config['defconfig_path']}")
            if self.config["make"] == "make":
                self.logger.info(cmd)
            if os.system(cmd):
                print(f"ERROR: Failed to apply {self.config['defconfig_path']}")
                return False
            self.fragments.apply()
        return True

    def clean(self, force: bool = False) -> bool:
        """Clean all configs that have the clean boolean set to true."""
        if self.config["remove"]:
            if Dirs.exists(self.config["build_path"]):
                self.logger.info(f"Removing directory {self.config['build_path']}")
                return Dirs.remove(self.config["build_path"])
        elif self.config["clean"] or force:
            if Dirs.exists(self.config["build_path"]):
                os.chdir(self.config["build_path"])
                cmd = f"{self.config['make']} clean"
                self.logger.info(f"Cleaning {self.config['defconfig']}")
                if os.system(cmd):
                    print(f"ERROR: Failed to clean {self.config['defconfig_path']}")
                    return False
                os.chdir(self.buildroot_path)
                return True
        return True

    def __parse_paths(self, config: Dict[str, Any]) -> bool:
        """Parse all paths from a given config.

        :param config: A config json object.
        :returns: True if all paths are parsed, otherwise False.
        """
        defconfig = str(config["defconfig"])
        output_tree = JSONHelper.parse_attr(config, "output_tree", str)[1]
        if not output_tree:
            output_tree = self.config["external_trees"].split(":", maxsplit=1)[0]
        output_dir_base = f"{self.buildroot_path}/{output_tree}"
        output_dir_name = JSONHelper.parse_attr(
            config,
            "output_dir_name",
            str,
            "output",
        )[1]
        self.config["output_dir"] = f"{output_dir_base}/{output_dir_name}"
        config_dir_name = JSONHelper.parse_attr(
            config, "config_dir_name", str, default_value="configs"
        )[1]
        if not self.config["config_dir_tree"]:
            self.config["config_dir_tree"] = self.config["external_trees"].split(
                ":", maxsplit=1
            )[0]
        self.config[
            "config_dir_path"
        ] = f"{self.buildroot_path}/{self.config['config_dir_tree']}/{config_dir_name}"
        self.config["defconfig"] = defconfig.replace("_defconfig", "") + "_defconfig"
        self.config[
            "defconfig_path"
        ] = f"{self.config['config_dir_path']}/{self.config['defconfig']}"

        if JSONHelper.parse_attr(config, "name", str)[0]:
            self.config["build_path"] = f"{self.config['output_dir']}/{config['name']}"
        else:
            self.config[
                "build_path"
            ] = f"{self.config['output_dir']}/{self.config['defconfig'].replace('_defconfig', '')}"

        if not os.path.isfile(self.config["defconfig_path"]):
            self.logger.error(f"{self.config['defconfig_path']}: no such file!")
            sys.exit(1)

        self.config["dl_dir"] = Buildroot.parse_defconfig(
            "BR2_DL_DIR", self.config["defconfig_path"], self.buildroot_path
        )
        per_package = Buildroot.parse_defconfig(
            "BR2_PER_PACKAGE_DIRECTORIES",
            self.config["defconfig_path"],
            self.buildroot_path,
        )
        if per_package == "y":
            self.config["per_package"] = True
        if not self.config["dl_dir"]:
            self.config[
                "dl_dir"
            ] = f"{self.buildroot_path}/{self.config['external_trees'].split(':', maxsplit=1)[0]}/dl"
        if not Dirs.exists(self.config["dl_dir"], make=True, fail=True):
            return False
        return True

    def parse(
        self, config: Dict[str, Union[str, bool]]
    ) -> Union[None, Dict[str, Union[str, bool]]]:
        """Parse an env.json file.

        :param Dict[str, Union[str, bool]] config: A config object.
        :returns: None on error, a dictionary on success.
        :rtype: Union[None, Dict[str, Union[str, bool]]]
        """
        JSONHelper.parse_attr(config, "defconfig", str, fail=True)
        self.config["build"] = JSONHelper.parse_attr(config, "build", bool, True)[1]
        self.config["clean"] = JSONHelper.parse_attr(config, "clean", bool, False)[1]
        self.config["legal_info"] = JSONHelper.parse_attr(
            config, "legal_info", bool, False
        )[1]
        self.config["remove"] = JSONHelper.parse_attr(config, "remove", bool, False)[1]
        self.config["skip"] = JSONHelper.parse_attr(config, "skip", bool, False)[1]
        if JSONHelper.parse_attr(config, "verbose", bool, False)[1]:
            self.config["make"] = "make"
        verbose = bool(os.environ.get("VERBOSE", "false").lower() == "true")
        if verbose:
            self.config["make"] = "make"
        self.config["config_dir_tree"] = JSONHelper.parse_attr(
            config, "config_dir_tree", str
        )[1]
        self.config["external_trees"] = ExternalTrees.parse(config)
        if not self.__parse_paths(config):
            return None
        self.fragments = Fragments(self.buildroot_path, self.config)
        self.fragments.parse(self.config["external_trees"], config)
        return self.config

    def __init__(self, buildroot_path: str, apply_configs: bool):
        self.logger = Logger(__name__)
        self.buildroot_path = buildroot_path
        self.fragments = None
        self.config = {
            "build": True,
            "buildroot_path": self.buildroot_path,
            "build_path": "",
            "clean": False,
            "config_dir_path": "configs",
            "config_dir_tree": "",
            "defconfig": "",
            "defconfig_path": "",
            "dl_dir": "dl",
            "external_trees": "external",
            "make": "brmake",
            "output_dir": "output",
            "per_package": False,
            "apply_configs": apply_configs,
            "remove": False,
            "skip": False,
        }
