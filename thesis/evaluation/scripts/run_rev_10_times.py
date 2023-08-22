import json
import os
import re
import signal
import subprocess
import sys
import time

stop = False
N_RUNS = 10


def sigint_handler(sig, frame):
    global stop
    stop = True


def run_command(command, filename):
    start_time = time.time()
    command = [command, filename]
    try:
        completed_process = subprocess.run(
            command, check=True, capture_output=True, text=True)
        runtime = time.time() - start_time
        exit_code = completed_process.returncode
        output = completed_process.stdout
    except subprocess.CalledProcessError as e:
        runtime = time.time() - start_time
        exit_code = e.returncode
        output = e.stdout

    self_time = ""
    outsp = output.split("\n")
    pattern = r'\d+\.\d+s'
    match = re.search(pattern, output)
    self_time = float(re.search(r'\d+\.\d+', match.group()
                                ).group()) if match else "Error"

    return {"runtime": runtime, "exit_code": exit_code, "output": output, "self_time": self_time}


def main():

    signal.signal(signal.SIGINT, sigint_handler)

    if len(sys.argv) < 3:
        print(
            f"Usage: python3 {os.path.basename(__file__)} <command> <directory>")
        sys.exit(1)

    command = os.path.abspath(sys.argv[1])
    directory = os.path.abspath(sys.argv[2])

    if not os.path.exists(directory) or not os.path.isdir(directory):
        print("Invalid directory provided.")
        sys.exit(1)

    results = {}
    for filename in sorted(os.listdir(directory)):
        print(f"Running on file {filename}.")
        f = os.path.join(directory, filename)
        file_results = []
        print("Run ", end="", flush=True)
        for i in range(N_RUNS):
            print(f"{i} ", end="", flush=True)
            result = run_command(command, f)
            file_results.append(result)
            if stop:
                break

        rsum = 0.0
        e = False
        for res in file_results:
            if str(res["self_time"]) == "Error":
                e = True
                break
            rsum += float(res["self_time"])

        avg = round(rsum / N_RUNS, 3) if not e else "Error"

        results[filename] = {"results": file_results, "average_self_time": avg}
        print("\n")
        if stop:
            break

    output_filename = os.path.join(directory, f"rev_results.json")
    with open(output_filename, 'w') as f:
        json.dump(results, f, indent=4)
    print(f"Results saved to {output_filename}")


if __name__ == "__main__":
    main()
