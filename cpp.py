import subprocess
import sys
import argparse
import os

current_file = os.path.abspath(__file__)
current_dir = os.path.dirname(os.path.abspath(__file__))

def create_class(class_name, suf, dir='.'):
    if class_name == '':
        print("error! need project name to init.")
        return
    
    # 确保目标目录存在
    os.makedirs(os.path.dirname(dir), exist_ok=True)
    fileName = class_name + "." + suf
    file_path = os.path.join(dir, fileName)
    # 读取源文件
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write("#pragma once")

    print(f"create class {class_name} in {dir} success.")

def handle_create_class(args):
    create_class(args.name, args.suffix, args.directory)
    return
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="cpp parameters")
    subParsers = parser.add_subparsers(dest='command', required=True)

    #create class
    createClass_parser = subParsers.add_parser('class', help='create name')
    createClass_parser.add_argument('--name', '-n', type=str, required=True, help='create class')
    createClass_parser.add_argument('--suffix', '-suf', type=str, required=True, help='suffix')
    createClass_parser.add_argument('--directory', '-dir', type=str, default='.', help='directory')
    createClass_parser.set_defaults(func=handle_create_class)

    args = parser.parse_args()
    args.func(args)