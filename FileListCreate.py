#! /usr/bin python3
# -*- coding: utf-8 -*-

"""
解决 modelsim 仿真数据名称带中文名称的问题
该脚本提取有效文件，并重命名到新的文件夹，整理提取好的文件名到 .f 文件中，方便直接使用
"""

import os
import re
import shutil

FILE_SUFFIX = '.txt'

SRC_DATA_DIR = r"F:\FPGA_Proj\BTM_1FPGA\BTM300H_RCV_v1.2.3.1a_tamp\Simulation\testbench_202010\tb_data\
                jingzhang_1207"
DST_DATA_DIR = r"F:\FPGA_Proj\BTM_1FPGA\BTM300H_RCV_v1.2.3.1a_tamp\Simulation\testbench_202010\tb_data\
                jingzhang_test_data"
FILE_LIST_DIR = r"F:\FPGA_Proj\BTM_1FPGA\BTM300H_RCV_v1.2.3.1a_tamp\Simulation\testbench_202010\filelist.f"


# 按照文件名和文件后缀获取有效文件，并重命名复制到新的文件夹中
def extract_data(file_dir):
    # 获取当前文件夹下的所有文件
    for root, dirs, files in os.walk(file_dir):
        for file in files:
            # 提取符合后缀名的文件
            if os.path.splitext(file)[1] == FILE_SUFFIX:
                # 按照名称是否含有某字段提取文件
                if '无效数据' in os.path.splitext(file)[0]:
                    pass
                else:
                    # 提取有效文件名
                    filename = re.findall(r'[(](.*?)[)]', os.path.splitext(file)[0])
                    filename = filename[0] + 'afterAGC.txt_resample.txt'
                    # 拷贝符合要求文件并重命名
                    shutil.copy(root + '\\' + file, root + '\\test_data\\' + filename)


# 从新的文件夹中获取所有文件名称到file list文件
def creat_file_list(file_dir):
    file_list = []
    for root, dirs, files in os.walk(file_dir):
        for file in files:
            file_list.append(file+'\n')
            # print(file)
    return file_list


if __name__ == "__main__":
    extract_data(SRC_DATA_DIR)
    file_f = creat_file_list(DST_DATA_DIR)
    # print(file_f)
    with open(FILE_LIST_DIR, 'w') as f:
        f.writelines(file_f)
