"""
Example implementing debug in a CumulusCI Task:

def _debug(self, value, title=None, show_list_index=True):
    debug(
        value, title=title, show_list_index=show_list_index, logger=self.logger.info
    )
"""


def debug(
    value, title=None, indent=0, tab="  ", show_list_index=True, logger=print,
):
    indentation = tab * (indent)
    prefix = "" if title is None else str(title) + " : "
    if isinstance(value, dict):
        logger(indentation + prefix + "{")
        for key, dict_value in value.items():
            debug(
                dict_value,
                title=key,
                indent=(indent + 1),
                tab=tab,
                show_list_index=show_list_index,
                logger=logger,
            )
        logger(indentation + "}" + ("," if indent else ""))
    elif isinstance(value, list):
        logger(indentation + prefix + "[")
        for index, list_item in enumerate(value):
            title = index if show_list_index else None
            debug(
                list_item,
                title=title,
                indent=(indent + 1),
                tab=tab,
                show_list_index=show_list_index,
                logger=logger,
            )
        logger(indentation + "]" + ("," if indent else ""))
    elif isinstance(value, set):
        logger(indentation + prefix + "set(")
        for index, list_item in enumerate(value):
            debug(
                list_item,
                title=index,
                indent=(indent + 1),
                tab=tab,
                show_list_index=show_list_index,
                logger=logger,
            )
        logger(indentation + ")" + ("," if indent else ""))
    else:
        logger(indentation + prefix + str(value) + ("," if indent else ""))


"""
Example implementing log_title in a CumulusCI Task:

    def _log_title(self, title):
        log_title(
            title, logger=self.logger.info
        )
"""


def log_title(title, logger=print):
    if title:
        logger("")
        logger(title)
        logger("─" * len(title))


def _get_padded_log_columns(column_max_lengths, column_range, row):
    log_row = []
    for index in column_range:
        column = row[index] if index < len(row) else ""
        log_row.append(
            "{}{}".format(column, " " * (column_max_lengths[index] - len(column)))
        )
    return log_row


def _get_log_column_separators(
    columnBorders=True, padColumns=True,
):
    column_separators = {
        "value": "{}",
        "space": " " if padColumns else "",
        "pad─": "─" if padColumns else "",
        "┌": "┌" if columnBorders else "─",
        "┐": "┐" if columnBorders else "─",
        "└": "└" if columnBorders else "─",
        "┘": "┘" if columnBorders else "─",
        "├": "├",
        "┼": "┼",
        "┤": "┤",
        "┬": "┬",
        "┴": "┴",
        "│": "│",
    }

    if not columnBorders:
        column_separators.update({"├": "", "┼": "", "┤": "", "┬": "", "┴": "", "│": ""})

    return column_separators


def _get_table_borders(
    column_max_lengths, columnBorders=True, padColumns=True,
):
    table_borders = {}
    table_borders["borders"] = []

    column_separators = _get_log_column_separators(columnBorders, padColumns)

    for i in range(0, len(column_max_lengths) + 1):
        columns = []
        for index, length in enumerate(column_max_lengths):
            columns.append((" " if index < i else "─") * length)

        if i == 0:
            border_format = "".join(
                [
                    "{├}{pad─}{value}{pad─}".format(**column_separators),
                    ("{┼}{pad─}{value}{pad─}" * (len(column_max_lengths) - 1)).format(
                        **column_separators
                    ),
                    "{┤}".format(**column_separators),
                ]
            )

            table_borders["header_border"] = "".join(
                [
                    "{├}{pad─}{value}{pad─}".format(**column_separators),
                    ("{┼}{pad─}{value}{pad─}" * (len(column_max_lengths) - 1)).format(
                        **column_separators
                    ),
                    "{┤}".format(**column_separators),
                ]
            ).format(*columns)

            if columnBorders:
                table_borders["header"] = "".join(
                    [
                        "{┌}{pad─}{value}{pad─}".format(**column_separators),
                        (
                            "{┬}{pad─}{value}{pad─}" * (len(column_max_lengths) - 1)
                        ).format(**column_separators),
                        "{┐}".format(**column_separators),
                    ]
                ).format(*columns)

                table_borders["footer"] = "".join(
                    [
                        "{└}{pad─}{value}{pad─}".format(**column_separators),
                        (
                            "{┴}{pad─}{value}{pad─}" * (len(column_max_lengths) - 1)
                        ).format(**column_separators),
                        "{┘}".format(**column_separators),
                    ]
                ).format(*columns)
            else:
                table_borders["header"] = table_borders["header_border"]
                table_borders["footer"] = table_borders["header_border"]

        elif i < len(column_max_lengths):
            border_format = "".join(
                [
                    ("{│}{space}{value}{space}" * i).format(**column_separators),
                    "{├}{pad─}{value}{pad─}".format(**column_separators),
                    (
                        "{┼}{pad─}{value}{pad─}" * (len(column_max_lengths) - 1 - i)
                    ).format(**column_separators),
                    "{┤}".format(**column_separators),
                ]
            )
        else:
            border_format = "".join(
                [
                    ("{│}{space}{value}{space}" * len(column_max_lengths)).format(
                        **column_separators
                    ),
                    "{│}".format(**column_separators),
                ]
            )
            table_borders["row_format"] = border_format

        table_borders["borders"].append(border_format.format(*columns))

    return table_borders


def _format_log_rows(raw_rows):
    formatted_rows = {}
    formatted_rows["rows"] = []
    column_max_lengths = []
    formatted_rows["column_max_lengths"] = column_max_lengths

    if raw_rows:
        for raw_row in raw_rows:
            row = []
            formatted_rows["rows"].append(row)
            for index, raw_column in enumerate(raw_row):
                column = str(raw_column) if raw_column else ""
                row.append(column)
                if index < len(column_max_lengths):
                    column_max_lengths[index] = max(
                        column_max_lengths[index], len(column)
                    )
                else:
                    column_max_lengths.append(len(column))
    return formatted_rows


"""
Example implementing log_table in a CumulusCI Task:

    def _log_table(
        self,
        raw_rows,
        groupByBlankColumns=False,
        rowBorders=True,
        columnBorders=True,
        padColumns=True,
        addHeaderBorder=True,
    ):
        log_table(
            raw_rows,
            groupByBlankColumns=False,
            rowBorders=True,
            columnBorders=True,
            padColumns=True,
            addHeaderBorder=True,
            logger=self.logger.info
        )
"""


def log_table(
    raw_rows,
    groupByBlankColumns=False,
    rowBorders=True,
    columnBorders=True,
    padColumns=True,
    addHeaderBorder=True,
    logger=print,
):
    formatted_rows = _format_log_rows(raw_rows)
    rows = formatted_rows.get("rows")
    column_max_lengths = formatted_rows.get("column_max_lengths")

    if column_max_lengths:
        column_range = range(0, len(column_max_lengths))

        table_borders = _get_table_borders(
            column_max_lengths, columnBorders, padColumns,
        )

        logger(table_borders.get("header"))

        # last_group_index = -1
        for index, row in enumerate(rows):
            # log border
            if addHeaderBorder and index == 1:
                logger(table_borders.get("header_border"))
            elif rowBorders and 0 < index:
                border_index = 0
                if groupByBlankColumns:
                    border_index = len(column_max_lengths)
                    for i in column_range:
                        if row[i]:
                            border_index = i
                            break
                logger(table_borders.get("borders")[border_index])

            # log row
            logger(
                table_borders.get("row_format").format(
                    *_get_padded_log_columns(column_max_lengths, column_range, row)
                )
            )

        logger(table_borders.get("footer"))
