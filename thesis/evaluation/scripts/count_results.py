import json
import os
import sys

from optparse import OptionParser
from tabulate import tabulate


def count_results(directory, print_unclear):
    refuted_counts = {"True": 0, "False": 0}
    resource_out_counts = {"True": 0, "False": 0}
    unclear_counts = {"True": 0, "False": 0}

    unclear_tbl = []

    for filename in sorted(os.listdir(directory)):
        if filename.endswith("_results.json"):
            file_path = os.path.join(directory, filename)

            with open(file_path, 'r') as f:
                results = json.load(f)

            for result in results:
                flag_value = str(result["isabelle_simp"])
                if "refuted" in result and "yes" in result["refuted"]:
                    refuted_counts[flag_value] += 1
                elif "refuted" in result and "ResourceOut" in result["refuted"]:
                    resource_out_counts[flag_value] += 1
                else:
                    unclear_counts[flag_value] += 1

                    if not print_unclear:
                        continue

                    out = ""
                    filename_addon = 'isa_simp' if bool(
                        flag_value) else 'no_isa_simp'
                    outfile = os.path.abspath(
                        os.path.join(
                            directory,
                            f"{os.path.splitext(os.path.basename(filename.strip('_results.json')))[0]}_output_{filename_addon}.txt"
                        ))
                    if os.path.isfile(outfile):
                        with open(outfile, 'r') as f:
                            out = f.read()
                    unclear_tbl.append(
                        [filename, str(flag_value), out, result["runtime"]])

    return refuted_counts, resource_out_counts, unclear_counts, unclear_tbl


def main():
    parser = OptionParser()
    parser.add_option("-p", "--print_unclear",
                      action="store_true", dest="print_unclear", default=False)
    parser.add_option("-a", "--aggregate_counts",  # run on all dirs with the same basename
                      action="store_true", dest="aggregate_counts", default=False)
    (options, args) = parser.parse_args()

    if len(args) != 1:
        print(f"Usage: python3 {os.path.basename(__file__)} <directory>")
        sys.exit(1)

    results_directory = args[0]

    if options.aggregate_counts:
        from pathlib import Path as P
        name = os.path.basename(os.path.normpath(results_directory))
        gramps = P(results_directory).parent.absolute().parent.absolute()
        refuted_counts = {}
        resource_out_counts = {}
        unclear_counts = {}
        for dir in os.listdir(gramps):
            next = os.path.abspath(os.path.join(
                os.path.join(gramps, dir), name))
            print(f"next {next}")
            if name in os.listdir(os.path.abspath(os.path.join(gramps, dir))):
                refuted_counts_tmp, resource_out_counts_tmp, unclear_counts_tmp, unclear_tbl_tmp = count_results(
                    next, options.print_unclear)
                for k in refuted_counts_tmp.keys():
                    if k not in refuted_counts.keys():
                        refuted_counts[k] = 0
                    refuted_counts[k] += refuted_counts_tmp[k]
                for k in resource_out_counts_tmp.keys():
                    if k not in resource_out_counts.keys():
                        resource_out_counts[k] = 0
                    resource_out_counts[k] += resource_out_counts_tmp[k]
                for k in unclear_counts_tmp.keys():
                    if k not in unclear_counts.keys():
                        unclear_counts[k] = 0
                    unclear_counts[k] += unclear_counts_tmp[k]
        unclear_tbl = []
    else:
        refuted_counts, resource_out_counts, unclear_counts, unclear_tbl = count_results(
            results_directory, options.print_unclear)

    print("Performance when --rw_isabelle_simp=true:")
    print(
        f"Number of files with successful refutations: {refuted_counts['True']}")
    print(f"Number of files with resource out: {resource_out_counts['True']}")
    print(
        f"Number of files with unclear result (likely ulimit timeout): {unclear_counts['True']}")

    print("\nPerformance when --rw_isabelle_simp=false:")
    print(
        f"Number of files with successful refutations: {refuted_counts['False']}")
    print(f"Number of files with resource out: {resource_out_counts['False']}")
    print(
        f"Number of files with unclear result (likely ulimit timeout): {unclear_counts['False']}")

    if unclear_tbl:
        print("\nUnclear results:")
        print(tabulate(unclear_tbl, headers=[
              "filename", "rw_isabelle_simp", "output", "runtime"]))


if __name__ == "__main__":
    main()
