
import os
import sys
import shutil
import time


def prepend_to_file(file_path, data_to_prepend):
    try:
        with open(file_path, 'r') as file:
            existing_content = file.read()

        updated_content = data_to_prepend + existing_content

        with open(file_path, 'w') as file:
            file.write(updated_content)

        print("Data prepended successfully.")
    except IOError as e:
        print(f"Error while prepending data: {str(e)}")


def get_copy_number(destination_folder):
    """
    Assumes numbered files are of the form `filename_xyz.stuff`, where x, y, and z are digits.
    """

    files_in_destination = os.listdir(destination_folder)

    # Filter out non-numbered files (e.g., if other files are present)
    numbered_files = [
        os.path.splitext(f)[0] for f in files_in_destination if os.path.splitext(f)[0][-3:].isdigit()
    ]

    if not numbered_files:
        return 1

    max_number = max(int(f[-3:]) for f in numbered_files)
    return max_number + 1


def safe(inp): return inp.replace('\n', '\n% ')


def check_and_copy_file(source_file_path, destination_folder, dest_file_basename, dest_file_extension):
    PREPEND_INTERACTIVE = True
    THEORY = "RBT_Impl.thy"
    THEORY_PATH = "src/HOL/Library/"
    INFO = "Isabelle lemma/goal:"
    ADDITIONAL_INFO = False

    if not os.path.exists(source_file_path):
        print("Source file does not exist.")
        return

    initial_modification_time = os.path.getmtime(source_file_path)
    copy_number = get_copy_number(destination_folder)

    while True:
        current_modification_time = os.path.getmtime(source_file_path)

        if current_modification_time != initial_modification_time:
            print("File has been changed. Copying...")
            try:
                destination_file_name = f"{dest_file_basename}_{copy_number:03d}.{dest_file_extension}"
                destination_file_path = os.path.join(
                    destination_folder, destination_file_name)
                shutil.copy(source_file_path, destination_file_path)
                print(
                    f"File {copy_number} copied successfully to {destination_file_path}.")
                extra_info = ""
                if PREPEND_INTERACTIVE:
                    inp = safe(input(f"Original line number in {THEORY}:"))
                    extra_info += f"\n% {THEORY_PATH + THEORY}:{inp}\n% "
                    inp = safe(input(INFO))
                    extra_info += f"{INFO} {inp}\n% "
                    if ADDITIONAL_INFO:
                        inp = safe(input("More extra info (q to quit):"))
                        while inp != "q":
                            extra_info += "\n% " + inp
                            inp = safe(input("More extra info (q to quit):"))
                if extra_info:
                    prepend_to_file(destination_file_path,
                                    f"% Extra info: {extra_info}\n")
                copy_number += 1
            except IOError as e:
                print(f"Error copying file: {e}")
            finally:
                initial_modification_time = current_modification_time

        time.sleep(0.05)


def main():
    USE_ARGV = True

    if USE_ARGV:
        sys.argc = len(sys.argv)

    if USE_ARGV and sys.argc != 4 and sys.argc != 5:
        print(
            f"Usage: python3 {os.path.basename(__file__)} <source_file_path> <destination_folder> <dest_file_basename> <opt:dest_file_extension>",
            file=sys.stderr)
        return 1

    if not USE_ARGV:
        source_file_path = f"{os.environ.get('HOME')}/.isabelle/prob_zipperposition_1.p"
        destination_folder = "/tmp/infiles"
        dest_file_basename = "zip_input"
        dest_file_extension = "p"
    else:
        source_file_path = os.path.abspath(sys.argv[1])
        destination_folder = os.path.abspath(sys.argv[2])
        dest_file_basename = sys.argv[3]
        dest_file_extension = list(reversed(sys.argv[4].split(".", maxsplit=1)))[0] if sys.argc == 5 else\
            os.path.splitext(source_file_path)[1].split(".", maxsplit=1)[1]
        print(f"dest_file_extension {dest_file_extension}")

    print(f"Monitoring {source_file_path}, copying to {destination_folder}.")
    check_and_copy_file(source_file_path, destination_folder,
                        dest_file_basename, dest_file_extension)


if __name__ == "__main__":
    main()
