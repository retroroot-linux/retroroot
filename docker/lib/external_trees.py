from typing import Any, List, Dict
from lib.json_helper import JSONHelper


# pylint: disable=R0903
class ExternalTrees:
    @staticmethod
    def parse(config: Dict[str, Any]) -> str:
        external_tree_string: str = ""
        external_tree: Dict[str, Any]
        JSONHelper.parse_attr(config, "external_trees", list, fail=True)
        external_trees: List[str] = config["external_trees"]

        for external_tree in external_trees:
            external_tree_string += (
                f"{JSONHelper.parse_attr(external_tree, 'name')[1]}:"
            )
        return external_tree_string[:-1]
