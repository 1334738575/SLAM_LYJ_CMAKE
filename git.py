import subprocess
import sys
import argparse
import shutil
import os

current_file = os.path.abspath(__file__)
current_dir = os.path.dirname(os.path.abspath(__file__))
project_dir = os.path.join(current_dir, "..")

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
        
def get_sub_names():
    subFile = os.path.join(current_dir, "../.gitmodules")
    subDirs = []
    subGits = []
    # 读取源文件
    with open(subFile, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        for line in lines:
            if line.count("path = ") == 1:
                ss = line.split("path = ")
                sss = ss[1].split("\n")
                subDirs.append(sss[0])
            if line.count("url = ") == 1:
                ss2 = line.split("url = ")
                ss3 = ss2[1].split("\n")
                subGits.append(ss3[0])
    return subDirs, subGits
                
        



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
def init_sub():
    init_sub_command = ['git']
    init_sub_command.extend(['submodule', 'update', '--init'])
    run_terminal(init_sub_command)
def update_sub(bHead):
    if bHead:
        update_sub_command = ['git']
        update_sub_command.extend(['submodule', 'update', '--remote'])
        run_terminal(update_sub_command)
    else:
        subDirs, subGits = get_sub_names()
        # print(subDirs)
        # print(subGits)
        for d in subDirs:
            subPath = os.path.join(project_dir, d)
            print(subPath)
            # open_command = ['cd']
            # open_command.extend([subPath])
            # print(open_command)
            # run_terminal(open_command)
            os.chdir(subPath)
            fetch_command = ['git']
            fetch_command.extend(['fetch'])
            # print(fetch_command)
            run_terminal(fetch_command)
            pull_command = ['git']
            pull_command.extend(['pull'])
            # print(pull_command)
            run_terminal(pull_command)
    


def handle_init(args):
    init_git()
def handle_initsub(args):
    init_sub()
def handle_updatesub(args):
    update_sub(args.head)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(prog='git command', description="git parameters")
    subParser = parser.add_subparsers(dest='command', required=True)
    
    #init
    init_parser = subParser.add_parser('init', help='initial git repository')
    init_parser.set_defaults(func=handle_init)
    
    #submodules
    initsub_parser = subParser.add_parser('initsub', help='submodule')
    initsub_parser.set_defaults(func=handle_initsub)
    updatesub_parser = subParser.add_parser('updatesub', help='submodule')
    updatesub_parser.add_argument('--head', action='store_true', default=False)
    updatesub_parser.set_defaults(func=handle_updatesub)
    
    args = parser.parse_args()
    args.func(args)