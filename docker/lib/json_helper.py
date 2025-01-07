import sys
from lib.logger import Logger
from typing import Any, Dict, Tuple, Union


class JSONHelper:
    @staticmethod
    def parse_attr(
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

        NOTE: This method is used to parse a json attribute against a given type.
        """
        logger = Logger("json_helper")
        retval = False
        attribute_val = None
        if attribute in config:
            if isinstance(config[attribute], attribute_type):
                attribute_val = config[attribute]
                return True, attribute_val
            logger.error(
                "%s is supposed to be %s, got %s instead!",
                attribute,
                str(attribute_type).split("'")[1],
                str(type(config[attribute])).split("'")[1],
            )
            sys.exit(1)
        if fail:
            logger.critical(f"Mandatory attribute: {attribute} not defined!")
            sys.exit(1)
        if default_value or isinstance(default_value, bool):
            return True, default_value
        return retval, attribute_val
