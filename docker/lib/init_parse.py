"""Init file parsing"""
import os
import sys
import json
import logging
from shutil import move
import tempfile
from typing import Any, List, Dict, Tuple, Union
from lib.dirs import Dirs
from lib.files import Files
from lib.buildroot import Buildroot


class InitParse:
    """Init file parsing class."""

    @staticmethod
    def __print_step(step: str):
        """Print the step."""
        print("######## {} ########".format(step))

    @staticmethod
    def __parse_config_attr(
        config: Dict[str, Any],
        attribute: str,
        attribute_type: Union[type, Tuple[Union[type, Tuple[Any, ...]], ...]] = str,
        default_value: Union[str, bool] = None,
        fail: bool = False,
    ) -> Tuple[bool, Union[None, str, bool]]:
        """Parse a config file attribute.

        :param dict config: The config file of which to parse.
        :param str attribute: The attribute of which to check.
        :param object attribute_type: The proper attribute type of the attribute.
        :param default_value: A default value to return if the attribute doesn't exist.
        :param bool fail: Exit 1 if the attribute doesn't exist.
        :returns: True or False and a value
        :rtype: tuple
        """
        retval = False
        attribute_val = None
        if attribute in config:
            if isinstance(config[attribute], attribute_type):
                attribute_val = config[attribute]
                return True, attribute_val
            logging.error(
                "%s is supposed to be %s, got %s instead!",
                attribute,
                str(attribute_type).split("'")[1],
                str(type(config[attribute])).split("'")[1],
            )
            sys.exit(1)
        if fail:
            logging.error("%s attribute missing in env.json", attribute)
            sys.exit(1)
        if default_value:
            return True, default_value
        return retval, attribute_val

    def __parse_paths(self, config) -> None:
        defconfig = str(config["defconfig"])
        self.defconfig = defconfig.replace("_defconfig", "") + "_defconfig"
        self.defconfig_path = "{}/{}".format(self.config_dir, self.defconfig)

        if self.__parse_config_attr(config, "name", str)[0]:
            self.build_path = "{}/{}".format(self.output_dir, config["name"])
        else:
            self.build_path = "{}/{}".format(
                self.output_dir, self.defconfig.replace("_defconfig", "")
            )

        if not os.path.isfile(self.defconfig_path):
            logging.error("%s: no such file!", format(self.defconfig_path))
            sys.exit(1)

    def __parse_fragments(self, config: Dict[str, Any]) -> None:
        extern_tree_base = "{}/{}".format(self.buildroot_path, self.external_tree_name)
        if self.__parse_config_attr(config, "fragments", list)[0]:
            fragments = list(config["fragments"])
            retval = self.__parse_config_attr(config, "fragment_dir", str)
            if retval[0]:
                self.fragment_dir = "{}/{}".format(extern_tree_base, retval[1])
            else:
                self.fragment_dir = "{}/configs".format(self.config_dir)
            for fragment in fragments:
                fragment_path = "{}/{}".format(self.fragment_dir, fragment)
                Files.exists(fragment_path, fail=True)
                self.fragments.append(fragment_path)
        else:
            self.fragments.clear()

    def _parse_config_settings(self, config: Dict[str, Union[str, bool]]) -> None:
        self.make = "make"
        self.__parse_config_attr(config, "defconfig", str, fail=True)
        self.build = self.__parse_config_attr(config, "build", bool, False)[1]
        self.clean = self.__parse_config_attr(config, "clean", bool, False)[1]
        self.remove = self.__parse_config_attr(config, "remove", bool, False)[1]
        if self.__parse_config_attr(config, "verbose", bool, False)[0]:
            self.make = "brmake"

        self.external_tree_name = self.__parse_config_attr(
            config, "external_tree_name", str, fail=True
        )[1]
        self.output_dir = "{}/{}/{}".format(
            self.buildroot_path,
            self.external_tree_name,
            self.__parse_config_attr(
                config, "output_dir", str, "{}/output".format(self.buildroot_path)
            )[1],
        )
        extern_tree_base = "{}/{}".format(self.buildroot_path, self.external_tree_name)
        config_dir = self.__parse_config_attr(
            config, "config_dir", str, default_value="configs"
        )[1]
        self.config_dir = "{}/{}".format(extern_tree_base, config_dir)
        self.__parse_paths(config)
        self.__parse_fragments(config)

    def apply_configs(self) -> None:
        """Apply all configs defined in env.json."""
        for config in self.env["configs"]:
            self.fragments.clear()
            self._parse_config_settings(config)
            Dirs.exists(self.buildroot_path, fail=True)
            Dirs.exists(self.output_dir, make=True, fail=True)
            dl_dir = Buildroot.parse_defconfig(
                "BR2_DL_DIR", self.defconfig_path, self.buildroot_path
            )
            if not dl_dir:
                dl_dir = "{}/{}/dl".format(self.buildroot_path, self.external_tree_name)
            Dirs.exists(dl_dir, make=True, fail=True)

            if not Dirs.exists(self.build_path):
                if self.fragments:
                    tmp_defconfig, tmp_defconfig_path = tempfile.mkstemp(dir="/tmp")
                    defconfig_buff = Files.to_buffer(self.defconfig_path)
                    Files.save_buffer(
                        tmp_defconfig_path, defconfig_buff, overwrite=True
                    )
                    for fragment in self.fragments:
                        fragment_buff = Files.to_buffer(file_location=fragment)
                        Files.save_buffer(
                            tmp_defconfig_path,
                            fragment_buff,
                            append=True,
                        )
                    os.close(tmp_defconfig)
                    new_defconfig_name = "{}_defconfig".format(
                        os.path.basename(tmp_defconfig_path)
                    )
                    new_defconfig_path = "{}/configs/{}".format(
                        self.buildroot_path, new_defconfig_name
                    )
                    move(tmp_defconfig_path, new_defconfig_path)
                    self.defconfig = new_defconfig_name
                cmd = "BR2_EXTERNAL={}/{} BR2_DL_DIR={} BR2_DEFCONFIG={} {} {} O={}".format(
                    self.buildroot_path,
                    self.external_tree_name,
                    dl_dir,
                    self.defconfig_path,
                    self.make,
                    self.defconfig,
                    self.build_path,
                )
                os.chdir(self.buildroot_path)
                self.__print_step("Applying {}".format(self.defconfig_path))
                os.system(cmd)
                if self.fragments:
                    os.system(
                        'sed s%BR2_DEFCONFIG=.*%BR2_DEFCONFIG=\\"{}\\"%g -i {}'.format(
                            self.defconfig_path, self.build_path + "/.config"
                        )
                    )
                    os.remove(
                        "{}/configs/{}".format(self.buildroot_path, self.defconfig)
                    )

    def clean_all(self) -> None:
        """Clean all configs that have the clean boolean set to true."""
        for config in self.env["configs"]:
            self._parse_config_settings(config)
            if self.remove:
                if Dirs.exists(self.build_path):
                    self.__print_step("Removing directory {}".format(self.build_path))
                    Dirs.remove(self.build_path)
            elif self.clean:
                if Dirs.exists(self.build_path):
                    os.chdir(self.build_path)
                    cmd = "{} clean".format(self.make)
                    self.__print_step("Cleaning {}".format(self.defconfig))
                    os.system(cmd)

    def update_buildroot(self) -> Union[bool, int]:
        """Update buildroot if set to true."""
        if self.update:
            return Buildroot.update(self.buildroot_path)
        return True

    def _parse_env(self):
        self.user = "br-user" if "user" not in self.env else self.env["user"]
        self.update = (
            False
            if "update_buildroot" not in self.env
            else self.env["update_buildroot"]
        )
        self.buildroot_path = (
            "/home/" + self.user + "/buildroot"
            if "buildroot_dir" not in self.env
            else "/home/" + self.user + "/" + self.env["buildroot_dir"]
        )
        self.exit = (
            True if "exit_after_build" not in self.env else self.env["exit_after_build"]
        )

    def build_all(self):
        """Build all configs that have the build attribute set to true in env.json"""
        for config in self.env["configs"]:
            self._parse_config_settings(config)
            if self.build:
                os.chdir(self.build_path)
                self.__print_step("Building {}".format(self.defconfig))
                os.system(self.make)
            else:
                self.__print_step("{}: Skip build step".format(self.defconfig))

    def __init__(self, env_file):
        with open(env_file) as env_fd:
            self.env = json.load(env_fd)
        self._parse_env()
        self.build: bool = False
        self.build_path: str = ""
        self.buildroot_path: str = "/home/{}/buildroot".format(self.user)
        self.clean: bool = False
        self.config_dir: str = "configs"
        self.defconfig: str = ""
        self.defconfig_path: str = ""
        self.exit: bool = False
        self.external_tree_name: str = ""
        self.fragment_dir: str = ""
        self.fragments: List[str] = []
        self.make: str = "make"
        self.output_name: str = ""
        self.output_dir: str = ""
        self.remove: bool = False
        self.update: bool = False
        self.user: str = "br-user"
        self.verbose: bool = False
