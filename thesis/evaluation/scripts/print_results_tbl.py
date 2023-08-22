import json
import os
import sys

from optparse import OptionParser
from tabulate import tabulate


class ResultsOut:
    class InnerTbl:
        class InnerTblElement:
            def __init__(self, value: str, should_print: bool):
                self.value = value
                self.should_print = should_print
                self.once = False

            def __repr__(self):
                s = self.value if self.should_print else ""
                if self.once:
                    self.should_print = False
                    self.once = False
                return s

            def __getitem__(self, item):
                return self.value[item]

            def __eq__(self, obj):
                return self.value == obj

            def __ne__(self, obj):
                return self.value != obj

            def set_to_print(self):
                self.should_print = True

            def __del__(self):
                del self.value
                del self.should_print
                del self.once
                del self

            def __hash__(self):
                return self.value.__hash__()

            def is_empty(self):
                return not self.should_print or self.value == ""

        def __init__(self):
            self.tbl = []

        def __len__(self):
            return len(self.tbl)

        def append(self, element, should_print: bool = True):
            """
            Args:
                `element` (Any): The element to append.
                `should_print` (bool): Whether the element should be printed.
            """
            self.tbl.append(self.InnerTblElement(element, should_print))

        def set_print_all(self):
            """ Sets all inner elements to print. """
            for el in self.tbl:
                el.set_to_print()

        def set_print_all_once(self):
            """ Sets all inner elements to print. """
            for el in self.tbl:
                if not el.should_print:
                    el.set_to_print()
                    el.once = True

        def __repr__(self):
            self.set_print_all_once()
            return str(self.tbl)

        def __eq__(self, obj):
            return self.tbl == obj

        def __ne__(self, obj):
            return self.tbl != obj

        def __del__(self):
            del self.tbl

        def __getitem__(self, item) -> InnerTblElement:
            return self.tbl[item]

        def __setitem__(self, item, new):
            self.tbl[item].value = new

        def __delitem__(self, key):
            del self.tbl[key]

    def __init__(self) -> None:
        """
        Raises `Exception` if opts or args are not set correctly.

        Args:
            `file_ending` (str, optional): 
                    Desired file ending for json files to inspect results in.  
                    Defaults to "_results.json".
            `dirs_exactly_equal` (bool, optional): 
                    Whether directory contents need to be exactly equal.  
                    If False, only files present in the first directory will be used.  
                    Defaults to True.
        """
        self._init_constants()

        self.directories = []
        self.files = []

        self._handle_opts_args()

        self._current_file_basename = ""
        self._current_dir = self.directories[0]
        self.results_tbl = []
        self._headers = []

    class _filters:
        BOTH_SUCC = "both_succ"
        BOTH_OUT = "both_out"
        NOT_BOTH_SUCC = "not_both_succ"
        NOT_BOTH_OUT = "not_both_out"
        DIFF = "diff"

    class _results:
        BOTH_SUCC = "both_succ"
        BOTH_OUT = "both_out"
        ISA_FAIL = "isa_fail"
        ISA_WIN = "isa_win"

    def _init_constants(self):
        # if self.filter is not in filterlist, result will not print
        self.result_map = {
            self._results.BOTH_SUCC: {
                "filterlist": [self._filters.BOTH_SUCC, self._filters.NOT_BOTH_OUT],
                "result": "both Refutation",
                "append_speedup": True,
                "append_rt_true": True,
                "append_rt_false": True
            },
            self._results.BOTH_OUT: {
                "filterlist": [self._filters.BOTH_OUT, self._filters.NOT_BOTH_SUCC],
                "result": "both ResourceOut",
                "append_speedup": False,
                "append_rt_true": False,
                "append_rt_false": False
            },
            self._results.ISA_FAIL: {
                "filterlist": [self._filters.DIFF, self._filters.NOT_BOTH_SUCC, self._filters.NOT_BOTH_OUT],
                "result": "IsaSimp Failed",
                "append_speedup": False,
                "append_rt_true": False,
                "append_rt_false": True
            },
            self._results.ISA_WIN: {
                "filterlist": [self._filters.DIFF, self._filters.NOT_BOTH_SUCC, self._filters.NOT_BOTH_OUT],
                "result": "IsaSimp Won",
                "append_speedup": False,
                "append_rt_true": True,
                "append_rt_false": False
            }
        }

    def get_results(self) -> None:
        """
        Get all results and write them to this instance's `results_tbl`.
        """
        for file in self.files:
            inner_tbl = self.InnerTbl()
            inner_tbl.append(f"file {file.strip('_results.json')}")
            if self.options.filenumber_only:
                inner_tbl[0] = inner_tbl[0][-3:]
            self._current_file_basename = os.path.basename(file)
            self._get_all_file_results(inner_tbl)

            if not self.has_filter or self._has_content(inner_tbl):
                self.results_tbl.append(inner_tbl)

    def _has_content(self, inner_tbl: InnerTbl) -> bool:
        if len(inner_tbl) < 2:
            return False
        for i in range(1, len(inner_tbl)):
            if inner_tbl[i].should_print and inner_tbl[i].value != "":
                return True
        return False

    def print_results(self) -> None:
        """
        Print all results stored in this instance's `results_tbl` in tabulated form.
        """
        self._construct_headers()
        self._filter_cols()
        self._filter_rows()
        print(tabulate(self.results_tbl, headers=self._headers))

    def _construct_headers(self):
        self._headers = [
            "Filename"] if not self.options.filenumber_only else ["File"]
        for d in self.directories:
            self._headers.append(f"{os.path.basename(d)} result")
            self._headers.append(f"speedup")
            self._headers.append(f"isa_runtime")
            self._headers.append(f"no_isa_runtime")

    def _filter_cols(self):
        if not self.options.print_rt:
            self._remove_runtime_cols()

        if self.options.print_whole_row and (not self.options.filter_all or self.options.filter_inverse):
            for row in self.results_tbl:
                row.set_print_all()

        self._remove_empty_cols()

    def _filter_rows(self):
        if self.has_filter and self.options.filter_all:
            results_cols = [i for i, v in enumerate(
                self._headers) if "result" in v]
            to_keep = []
            to_discard = []

            for row in self.results_tbl:
                results = [row[i] for i in results_cols]
                desired = self._desired_results()
                if all(result in desired for result in results):
                    to_keep.append(row)
                else:
                    to_discard.append(row)

            if not self.options.filter_inverse:
                self.results_tbl = to_keep
            else:
                self.results_tbl = to_discard

    def _desired_results(self):
        results = set()
        for entry in self.result_map:
            if self.options.filter in self.result_map[entry]["filterlist"]:
                results.add(self.result_map[entry]["result"])
        return results

    def _get_col_indices(self, keywords):
        return [i for i, v in enumerate(self._headers) if v in keywords]

    def _get_col_indices_inverse(self, keywords):
        return [i for i, v in enumerate(self._headers) if v not in keywords]

    def _remove_empty_cols(self):
        empty_cols = []

        for i in range(len(self._headers)):
            if self._is_empty_col(i):
                empty_cols.append(i)

        self._remove_cols(empty_cols)

    def _is_empty_col(self, index):
        for row in self.results_tbl:
            if not row[index].is_empty():
                return False
        return True

    def _remove_runtime_cols(self):
        rt_indices = self._get_col_indices(["isa_runtime", "no_isa_runtime"])
        self._remove_cols(rt_indices)

    def _remove_cols(self, indices):
        self._headers = [h for i, h in enumerate(
            self._headers) if i not in indices]
        self._remove_multicol(indices)

    def _remove_multicol(self, indices):
        indices = reversed(sorted(indices))
        for i in indices:
            self._remove_col(i)

    def _remove_col(self, index):
        for row in self.results_tbl:
            del row[index]

    def _get_all_file_results(self, inner_tbl: InnerTbl) -> None:
        """
        Get results for the current file in every directory, saving them to `inner_tbl`.
        """
        for dir in self.directories:
            self._current_dir = dir
            self._get_file_results(inner_tbl)

    def _filter_helper(self, result: str):
        """
        Args:
            `result` (str): One of self._results.
        """
        ret = not self.options.filter in self.result_map[result]["filterlist"]
        ret = ret if not self.options.filter_inverse else not ret
        return ret

    def _write_result(self, inner_tbl: InnerTbl, result: str, runtime: 'dict[bool, int]'):
        should_print = self.has_filter and not self._filter_helper(result)

        inner_tbl.append(self.result_map[result]["result"], should_print)

        speedup = f"{((runtime[False] / runtime[True]) * 100) - 100:.2f}%" if self.result_map[result][
            "append_speedup"] else ""
        rt_true = f"{runtime[True]:.5f}s" if self.result_map[result]["append_rt_true"] else ""
        rt_false = f"{runtime[False]:.5f}s" if self.result_map[result]["append_rt_false"] else ""

        inner_tbl.append(speedup, should_print)
        inner_tbl.append(rt_true, should_print)
        inner_tbl.append(rt_false, should_print)

    def _get_file_results(self, inner_tbl: InnerTbl) -> None:
        """
        Get results for the current file in the current directory, saving them to `inner_tbl`.
        """

        current_absfile = os.path.join(
            self._current_dir, self._current_file_basename)

        if not self._dirs_exactly_equal and not os.path.isfile(current_absfile):
            return

        with open(current_absfile, 'r') as opened_file:
            results = json.load(opened_file)

        isasimp_index = 0 if results[0]['isabelle_simp'] else 1
        noisasimp_index = 1 if results[0]['isabelle_simp'] else 0

        isasimp_refuted = "yes" in results[isasimp_index]['refuted']
        noisasimp_refuted = "yes" in results[noisasimp_index]['refuted']

        both_succ = isasimp_refuted and noisasimp_refuted
        both_out = not isasimp_refuted and not noisasimp_refuted

        runtime = {True: results[isasimp_index]['runtime'],
                   False: results[noisasimp_index]['runtime']}

        if both_succ:
            self._write_result(inner_tbl, self._results.BOTH_SUCC, runtime)
        elif both_out:
            self._write_result(inner_tbl, self._results.BOTH_OUT, runtime)
        elif not isasimp_refuted and noisasimp_refuted:
            self._write_result(inner_tbl, self._results.ISA_FAIL, runtime)
        elif isasimp_refuted and not noisasimp_refuted:
            self._write_result(inner_tbl, self._results.ISA_WIN, runtime)

    def _handle_opts_args(self) -> None:
        parser = OptionParser()
        parser.add_option("-f", "--filter", action="store",
                          type="string", dest="filter")
        parser.add_option("-e",
                          "--file_ending",
                          action="store",
                          type="string",
                          dest="file_ending",
                          default="_results.json")
        parser.add_option("-p", "--print_runtimes",
                          action="store_true", dest="print_rt", default=False)
        parser.add_option("-d", "--dirs_not_equal",
                          action="store_false", dest="dir_eq", default=True)
        parser.add_option("-w",
                          "--whole_row_print",
                          action="store_true",
                          dest="print_whole_row",
                          default=False)
        parser.add_option("-a", "--filter_all_rows",
                          action="store_true", dest="filter_all", default=False)
        parser.add_option("-i", "--filter_inverse",
                          action="store_true", dest="filter_inverse", default=False)
        parser.add_option("-s", "--stacktrace",
                          action="store_true", dest="stacktrace", default=False)
        parser.add_option("-n", "--filenumber_only",
                          action="store_true", dest="filenumber_only", default=False)

        (options, args) = parser.parse_args()
        self._dirs_exactly_equal = options.dir_eq
        self._CORRECT_FILE_ENDING = options.file_ending
        self.has_filter = bool(options.filter)
        options.print_whole_row = options.print_whole_row or not self.has_filter

        filter_map = {
            self._filters.BOTH_OUT: f"show only {'rows with ' if options.print_whole_row else ''}results for which both options returned ResourceOut",
            self._filters.BOTH_SUCC: f"show only {'rows with ' if options.print_whole_row else ''}results for which both options returned Refutation",
            self._filters.NOT_BOTH_OUT: f"show only {'rows with ' if options.print_whole_row else ''}results for which not both options returned ResourceOut",
            self._filters.NOT_BOTH_SUCC: f"show only {'rows with ' if options.print_whole_row else ''}results for which not both options returned Refutation",
            self._filters.DIFF: f"show only {'rows with ' if options.print_whole_row else ''}results for which not both options returned the same result"
        }

        self.directories = [os.path.abspath(dir) for dir in args]
        for dir in self.directories:
            if not os.path.isdir(dir):
                raise Exception(f"Not a valid directory: {dir}.")

        if options.filter and options.filter not in filter_map:
            estring = f"Possible filters:\n"
            for k, v in filter_map.items():
                estring += f"\t{k}: {v}\n"
            raise Exception(estring)

        self.files = sorted(os.listdir(self.directories[0]))
        if self._dirs_exactly_equal and len(self.directories) > 1:
            for dir in self.directories[1:]:
                if self.files != sorted(os.listdir(dir)):
                    raise Exception(
                        f"Directories need to have the same contents.")

        self.files = filter(
            lambda file: self._has_correct_file_ending(file), self.files)

        if bool(options.filter):
            print(
                f"Filtering to {'not ' if options.filter_inverse else ''}{filter_map[options.filter]}."
            )

        self.options = options
        self.args = args

    def _has_correct_file_ending(self, filename: str) -> bool:
        return filename.endswith(self._CORRECT_FILE_ENDING)


def main() -> int:
    try:
        this = ResultsOut()
        this.get_results()
        this.print_results()
    except Exception as e:
        print(f"An error occurred:\n\t{e}")
        if this.options.stacktrace:
            import traceback
            print(f"Stacktrace:")
            print(traceback.format_exc())
        return 1
    return 0


if __name__ == "__main__":
    exit(main())
