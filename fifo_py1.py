# Python Script for FIFO Verification
#
# Function:
# - Check for overflow and underflow conditions
# - Analyze simulation log data from a .txt file

# TODO: This script is designed for log post-processing, and in the future,
# it could integrate with cocotb or simulation output generated from Verilog testbenches.

import collections

# check the txt file


def check_file(file_path):
    data_lines = []
    with open(file_path, "r") as f:
        for line in f:
            data = [line.strip() for line in line.split("|")]
            if len(data) != 10 or data[0].isalpha():
                continue
            else:
                mydict = {
                    "time": data[0],
                    "ct": data[1],
                    "wt_p": data[2],
                    "rd_p": data[3],
                    "din": data[4],
                    "dout": data[5],
                    "full": data[6],
                    "empty": data[7],
                    "wt_en": data[8],
                    "rd_en": data[9]
                }
                data_lines.append(mydict)
    return data_lines

# check the data


def check_fifo_data(data_lines):
    errors = []

    for item in data_lines:
        time = item["time"]
        count = item["ct"]
        write_p = item["wt_p"]
        read_p = item["rd_p"]
        data_in = item["din"]
        data_out = item["dout"]
        full = item["full"]
        empty = item["empty"]
        write_en = item["wt_en"]
        read_en = item["rd_en"]

        if empty == "1" and read_en == "1":
            errors.append(f"Underflow at time:{time}")

        if full == "1" and write_en == "1":
            errors.append(f"Overflow at time:{time}")

    if errors:
        for err in errors:
            print(err)
    else:
        print("---All pass---")


fifo_data1 = check_file("fifo_py1.txt")
check_fifo_data(fifo_data1)
