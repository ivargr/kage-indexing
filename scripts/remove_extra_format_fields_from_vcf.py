import logging
logging.basicConfig(level=logging.INFO)
import sys

for j, line in enumerate(sys.stdin):

    if j % 10000 == 0:
        logging.info(f"{j} lines processed")

    # only keep GT format
    if line.startswith("##FORMAT=<ID="):
        if not line.startswith("##FORMAT=<ID=GT"):
            continue

    if line.startswith("#"):
        print(line.strip())
        continue


    l = line.split("\t")

    l[8] = "GT"

    for i in range(9, len(l)):
        l[i] = l[i].split(":")[0]

    print("\t".join(l).strip())