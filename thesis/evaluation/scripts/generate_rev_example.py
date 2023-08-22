import sys


def printlist(n):
    print("rev [", end="")
    for i in range(n - 1):
        print(f"{i}, ", end="")
    print(f"{n-1}] = [", end="")
    for i in range(n - 1, 0, -1):
        print(f"{i}, ", end="")
    print(f"{0}]", end="")


if __name__ == "__main__":
    printlist(int(sys.argv[1]))
