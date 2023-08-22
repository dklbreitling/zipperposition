import json
import os
import signal
import subprocess
import sys
import time

from optparse import OptionParser


def sigint_handler(sig, frame):
    print(flush=True)
    sys.exit(0)


def query_yes_no(question, default="yes"):  # https://code.activestate.com/recipes/577058/
    """Ask a yes/no question via raw_input() and return their answer.

    "question" is a string that is presented to the user.
    "default" is the presumed answer if the user just hits <Enter>.
            It must be "yes" (the default), "no" or None (meaning
            an answer is required of the user).

    The "answer" return value is True for "yes" or False for "no".
    """
    valid = {"yes": True, "y": True, "ye": True, "no": False, "n": False}
    if default is None:
        prompt = " [y/n] "
    elif default == "yes":
        prompt = " [Y/n] "
    elif default == "no":
        prompt = " [y/N] "
    else:
        raise ValueError("invalid default answer: '%s'" % default)

    while True:
        sys.stdout.write(question + prompt)
        choice = input().lower()
        if default is not None and choice == "":
            return valid[default]
        elif choice in valid:
            return valid[choice]
        else:
            sys.stdout.write(
                "Please respond with 'yes' or 'no' " "(or 'y' or 'n').\n")


def handle_opts_args():
    OUTDIR_DEFAULT = "/tmp/results"

    parser = OptionParser()
    parser.add_option("-i", "--input_directory",
                      action="store", type="string", dest="in_dir")
    parser.add_option("-o", "--output_directory",
                      action="store", type="string", dest="out_dir")
    parser.add_option("-e", "--executable", action="store",
                      type="string", dest="exe")

    (options, args) = parser.parse_args()

    if not options.exe:
        if len(args) != 1:
            print("No script to run supplied.", file=sys.stderr)
            sys.exit(1)
        options.exe = args[0]

    if not options.in_dir:
        print(f"Error: No input directory specified.", file=sys.stderr)
        sys.exit(1)

    if not options.out_dir:
        print(
            f"Warning: No output directory specified, defaulting to {OUTDIR_DEFAULT}", file=sys.stderr)
        options.out_dir = OUTDIR_DEFAULT
        if not os.path.exists(OUTDIR_DEFAULT):
            os.makedirs(OUTDIR_DEFAULT)

    if options.in_dir == options.out_dir:
        print(f"Error: Input directory and output directory need to be distinct.", file=sys.stderr)
        sys.exit(1)

    if not os.path.exists(options.in_dir):
        print(
            f"Error: Input directory does not exist: {options.in_dir}", file=sys.stderr)
        sys.exit(1)

    if not os.path.exists(options.out_dir):
        if not query_yes_no(f"Output directory does not exist.\nMake directory {options.out_dir}?"):
            sys.exit(1)
        os.makedirs(options.out_dir)

    exe_abspath = os.path.abspath(options.exe)

    if not os.path.isfile(exe_abspath):
        print(f"Error: Script does not exist: {exe_abspath}", file=sys.stderr)
        return 1

    if not os.access(exe_abspath, os.X_OK):
        print(
            f"Error: Script is not executable: {exe_abspath}", file=sys.stderr)
        return 1

    return options, args


def run_program(input_file, output_directory, program_filename):
    flags = [("--rw_isabelle_simp=true", True),
             ("--rw_isabelle_simp=false", False)]
    results = []

    infile_basename = os.path.basename(input_file)
    infile_cleanname = os.path.splitext(infile_basename)[0]
    print(f"==> {infile_basename} <==")

    for flag, flag_value in flags:
        command = [program_filename, input_file, flag]
        start_time = time.time()
        try:
            completed_process = subprocess.run(command, check=True, capture_output=True, text=True)
            runtime = time.time() - start_time
            exit_code = completed_process.returncode
            output = completed_process.stdout
        except subprocess.CalledProcessError as e:
            runtime = time.time() - start_time
            exit_code = e.returncode
            output = e.stdout

        result = {
            "input_file": infile_cleanname,
            "isabelle_simp": flag_value,
            "runtime": runtime,
            "exit_code": exit_code,
            "refuted": "yes, output contains \"Refutation\"" if "Refutation" in output\
                        else "no, output contains \"ResourceOut\"" if "ResourceOut" in output\
                        else "unclear, something went wrong"
        }

        results.append(result)

        print(f"Result with isabelle_simp {flag_value}\t   refuted: {result['refuted']}.")

        filename_addon = 'isa_simp' if flag_value else 'no_isa_simp'
        output_file = os.path.join(
            output_directory, f"{infile_cleanname}_output_{filename_addon}.txt")
        with open(output_file, 'w') as f:
            print(f"Writing output to {output_file}.")
            f.write(
                f"% Output for {infile_cleanname} with isabelle_simp {flag_value}:\n{output}")

    print()

    return results


def main():
    signal.signal(signal.SIGINT, sigint_handler)

    (options, args) = handle_opts_args()

    input_directory = options.in_dir
    output_directory = options.out_dir
    program = options.exe if options.exe else args[0]
    program_filename = os.path.basename(program)
    program_abspath = os.path.abspath(program)

    print(f"Running {program_filename}, abspath {program_abspath}.")

    for file in sorted(os.listdir(input_directory)):
        input_file = os.path.abspath(os.path.join(input_directory, file))
        results = run_program(input_file, output_directory, program_abspath)
        result_file = os.path.join(
            output_directory, f"{os.path.splitext(file)[0]}_results.json")

        with open(result_file, 'w') as f:
            json.dump(results, f, indent=2)


if __name__ == "__main__":
    main()
