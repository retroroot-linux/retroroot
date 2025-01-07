import os
import subprocess
from typing import Any, List, Dict, Union
from lib.files import Files
from lib.logger import Logger
from lib.json_helper import JSONHelper


class Fragments:
    def parse(self, external_trees: str, config: Dict[str, Any]) -> None:
        """Parse all defined fragment files."""
        ndx = 0
        fragments_temp: List[str] = []
        self.fragments.clear()
        for external_tree in external_trees.split(":"):
            extern_tree_base = f"{self.buildroot_path}/{external_tree}"
            extern_tree = config["external_trees"][ndx]
            ndx += 1
            if JSONHelper.parse_attr(extern_tree, "fragments", list)[0]:
                fragments = list(extern_tree["fragments"])
                retval = JSONHelper.parse_attr(extern_tree, "fragment_dir", str)
                if retval[0]:
                    self.fragment_dir = f"{extern_tree_base}/{retval[1]}"
                else:
                    self.fragment_dir = f"{self.config_obj['config_dir_path']}/configs"
                for fragment in fragments:
                    fragment_path = f"{self.fragment_dir}/{fragment}"
                    Files.exists(fragment_path, fail=True)
                    fragments_temp.append(fragment_path)
        self.fragments = fragments_temp

    def apply(self) -> None:
        """Apply the config fragments defined in env.json for a given config.

        Note: We run "make olddefconfig" to force the kconfig system to rebuild the .config
              with the default dependencies selected for the added fragments.
        """
        for fragment in self.fragments:
            self.logger.info(f"Applying fragment: {fragment}")
            fragment_buff = Files.to_buffer(file_location=fragment)
            Files.save_buffer(
                f"{self.config_obj['build_path']}/.config", fragment_buff, append=True
            )
        os.chdir(self.config_obj["build_path"])
        with open(os.devnull, "wb") as null:
            subprocess.check_call(
                [self.config_obj["make"], "olddefconfig"],
                stdout=null,
                stderr=subprocess.STDOUT,
            )
        os.chdir(self.buildroot_path)

    def __init__(
        self,
        buildroot_path: str,
        config_obj: Dict[str, Union[str, bool]],
    ):
        self.buildroot_path = buildroot_path
        self.config_obj = config_obj
        self.fragments: List[str] = []
        self.fragment_dir = ""
        self.logger = Logger(__name__)
