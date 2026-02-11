import subprocess
import sys
import argparse
import shutil
import os

current_file = os.path.abspath(__file__)
current_dir = os.path.dirname(os.path.abspath(__file__))

def run_terminal(command):
    try:
        # 方案1：显式指定编码
        result = subprocess.run(
            command,
            check=True,
            text=True,
            encoding='utf-8',
            errors='replace',
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        print("构建成功！输出如下：")
        print(result.stdout)
        if result.stderr:
            print("[警告] 编译过程中的错误信息：")
            print(result.stderr)
    except subprocess.CalledProcessError as e:
        print(f"构建失败！退出码：{e.returncode}")
        print("错误信息：")
        print(e.stderr if e.stderr else e.stdout)
        sys.exit(1)

def init_git():
    init_command = ['git']
    init_command.extend(['init'])
    run_terminal(init_command)
    cmake_sub_command = ['git']
    cmake_sub_command.extend(['submodule', 'add', 'https://github.com/1334738575/SLAM_LYJ_CMAKE.git', 'cmake'])
    run_terminal(cmake_sub_command)
    with open("./.gitignore", 'w', encoding='utf-8') as f:
        f.write("build/\noutput/\ninstall/\n")
    f.close()
    


def handle_init(args):
    init_git()



if __name__ == "__main__":
    parser = argparse.ArgumentParser(prog='git command', description="git parameters")
    subParser = parser.add_subparsers(dest='command', required=True)
    
    #init
    init_parser = subParser.add_parser('init', help='initial git repository')
    init_parser.set_defaults(func=handle_init)
    
    args = parser.parse_args()
    args.func(args)