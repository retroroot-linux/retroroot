import os
import subprocess
import multiprocessing
from shutil import rmtree
from typing import Dict, Union
from lib.logger import Logger
from lib.files import Files


class Buildroot:
    @staticmethod
    def parse_defconfig(
        defconfig_property: str, defconfig: str, buildroot_dir: str
    ) -> Union[str, None]:
        """Parse a defconfig for a given value.

        :param str defconfig_property: A given property of which to search.
        :param str defconfig: A path to the defconfig of which to search.
        :param buildroot_dir: A path to the buildroot directory.
        :returns: A string if the property is found, otherwise None.
        :rtype: bool
        """
        buff = {}
        with open(defconfig, encoding="utf-8") as _defconfig:
            for line in _defconfig:
                try:
                    line = line.strip()
                    if "is not set" in line:
                        continue
                    key_val = line.split("=")
                    key = key_val[0]
                    val = key_val[1]
                    buff[key] = val.replace('"', "").replace("$(TOPDIR)", buildroot_dir)
                except IndexError:
                    continue
        _defconfig.close()
        if defconfig_property in buff:
            return buff[defconfig_property]
        return None

    @staticmethod
    def legal_info(config_obj: Dict[str, Union[str, bool]]) -> bool:
        """Generate legal documentation."""
        logger = Logger("Buildroot")
        cmd = f"{config_obj['make']} BR2_DL_DIR={config_obj['dl_dir']} legal-info"
        board_name = config_obj["defconfig"].replace("_defconfig", "")
        legal_info_tarball = f"{board_name}-legal-info.tar.gz"
        legal_info_path = f"{config_obj['build_path']}/legal-info"
        os.chdir(config_obj["build_path"])
        if Files.exists(
            f"{config_obj['build_path']}/images/{board_name}-legal-info.tar.gz"
        ):
            logger.info("Legal info already generated.")
            return True
        logger.info(f"Generating legal-info for {config_obj['defconfig']}")
        if os.system(cmd):
            logger.error(
                f"ERROR: Failed to generate legal information for {config_obj['defconfig']}"
            )
            if config_obj["make"] == "brmake":
                log = Files.to_buffer(f"{config_obj['build_path']}/br.log", split=True)
                for line in log[-100:]:
                    print(line)
            return False
        # We don't want the sources bundled in the tarball.
        rmtree(f"{legal_info_path}/sources")
        rmtree(f"{legal_info_path}/host-sources")
        if os.system(f"tar -czf {legal_info_tarball} legal-info"):
            return False
        if os.makedirs("images", exist_ok=True):
            return False
        if os.system(f"mv {legal_info_tarball} images/"):
            return False
        return True

    @staticmethod
    def build(config_obj: Dict[str, Union[str, bool]]) -> bool:
        """Build all configs that have the build attribute set to true in env.json.

        :param Dict[str, Union[str, bool]] config_obj: An instantiated config object from the
                                                       config class.
        :returns: True on success, False on failure.
        :rtype: bool
        """
        logger = Logger("Buildroot")
        build_package = os.environ.get("BUILD_PACKAGE", None)
        os.chdir(config_obj["build_path"])
        with open(os.devnull, "wb") as null:
            subprocess.check_call(
                [config_obj["make"], "olddefconfig"],
                stdout=null,
                stderr=subprocess.STDOUT,
            )
        logger.info(f"Building {config_obj['defconfig']}")
        cmd = f"{config_obj['make']} BR2_DL_DIR={config_obj['dl_dir']}"
        # Check if per_package directories is set. If so, check if BR2_JLEVEL is set and divide
        # by the number of cores by JLEVEL.
        if config_obj["per_package"]:
            cores = multiprocessing.cpu_count()
            j_level = int(
                Buildroot.parse_defconfig(
                    "BR2_JLEVEL",
                    f"{config_obj['build_path']}/.config",
                    config_obj["buildroot_path"],
                )
            )
            if j_level:
                cores = max(int(cores / j_level), 1)
            cmd += f" -Otarget -j{str(cores)}"
            if build_package:
                cmd += f" {build_package}"

        logger.info(f"Running {cmd} for {config_obj['build_path']}")
        if os.system(cmd):
            print(f"ERROR: Failed to build {config_obj['defconfig']}")
            if config_obj["make"] == "brmake":
                log = Files.to_buffer(f"{config_obj['build_path']}/br.log", split=True)
                for line in log[-100:]:
                    print(line)
            return False
        return True

    @staticmethod
    def update(buildroot_dir: str) -> bool:
        """Update buildroot if it's a git repository.

        :param str buildroot_dir: The Buildroot directory of which to update.
        """
        logger = Logger("Buildroot")
        os.chdir(buildroot_dir)
        if not os.path.isdir(".git"):
            logger.warning("Buildroot is not from git, skipping update.")
            return True
        retval = os.system("git pull")
        if not retval:
            return False
        return True
