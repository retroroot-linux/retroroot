import os
from typing import List, Dict, Tuple, Union
from lib.files import Files


class Buildroot:
    @staticmethod
    def parse_defconfig(
        _property, defconfig: str, buildroot_dir: str
    ) -> Union[str, None]:
        buff = {}
        with open(defconfig) as _defconfig:
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
        if _property in buff:
            return buff[_property]
        return None

    @staticmethod
    def overwrite_properties(config_path, _property):
        config_buff = Files.to_buffer(config_path, split=True)
        buff = ""
        for line in config_buff:
            if _property in line:
                buff += _property + "\n"
            else:
                buff += line + "\n"
        print(buff)
        Files.save_buffer(config_path, buff, True)

    @staticmethod
    def update(buildroot_dir) -> Union[bool, int]:
        os.chdir(buildroot_dir)
        if not os.path.isdir(".git"):
            print("Buildroot is not from git, skipping update.")
            return True
        else:
            return os.system("git pull")
