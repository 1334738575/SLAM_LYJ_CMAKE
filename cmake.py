import subprocess
import sys
import argparse
import shutil
import os

current_file = os.path.abspath(__file__)
current_dir = os.path.dirname(os.path.abspath(__file__))


def replace_and_copy(src_path, dst_path, replacements):
    """
    带内容替换的文件复制函数
    :param src_path: 源文件路径
    :param dst_path: 目标文件路径
    :param replacements: 替换字典 {旧内容: 新内容} 或正则模式
    """
    try:
        # 确保目标目录存在
        os.makedirs(os.path.dirname(dst_path), exist_ok=True)
        
        # 读取源文件
        with open(src_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # 执行替换（支持字符串或正则）
        if isinstance(replacements, dict):
            for old, new in replacements.items():
                content = content.replace(old, new)
        else:  # 假设是正则模式
            import re
            content = re.sub(replacements[0], replacements[1], content)

        # 写入目标文件
        with open(dst_path, 'w', encoding='utf-8') as f:
            f.write(content)

    except FileNotFoundError:
        print(f"错误：源文件 {src_path} 不存在")
    except PermissionError:
        print(f"错误：无权限写入 {dst_path}")

def init_project(project_name,
                target_dir = '.'):
    # # 使用示例 - 替换多个关键词
    # replacements = {
    #     "{{DATE}}": "2025-08-09",
    #     "old_version": "v2.3.1"
    # }
    # 替换日期格式：将 MM/DD/YYYY 改为 YYYY-MM-DD
    # regex_pattern = (r'(\d{2})/(\d{2})/(\d{4})', r'\3-\1-\2')
    if project_name == '':
        print("error! need project name to init.")
        return
    replacements = {
        "@NAME@": project_name
    }
    source_file = os.path.join(current_dir, "CMakeListsTemplate.txt")
    target_file = os.path.join(target_dir, project_name, "CMakeLists.txt")
    replace_and_copy(source_file, target_file, replacements)

def config_project(source_dir='.',
                buid_dir='build',
                generator_name='Visual Studio 17 2022',
                build_type="Release"):
    command = ['cmake']
    command.extend(['-S', source_dir])
    command.extend(['-B', buid_dir])
    command.extend(['-G', generator_name])
    command.extend(['-DCMAKE_BUILD_TYPE=' + build_type])
    # print(command)
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

def build_project(build_target = 'all',
                build_dir = 'build',
                build_type = 'Release'):
    command = ['cmake']
    command.extend(['--build', build_dir])
    # command.extend(['-j8'])
    command.extend(['--config', build_type])
    if build_target != 'all':
        command.extend(['--target', build_target])
    # print(command)
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

def install_project(install_dir = '',
                build_dir = 'build',
                build_type = 'Release'):
    command = ['cmake']
    command.extend(['--install', build_dir])
    command.extend(['--config', build_type])
    if install_dir != '':
        command.extend(['--prefix', install_dir])
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


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="cmake parameters")
    parser.add_argument('command', type=str, help='cmake command')
    parser.add_argument('--project_name', '-p', type=str, default='', help='project name to init')
    parser.add_argument('--gen', '-g', type=str, default='Visual Studio 17 2022', help='generator')
    parser.add_argument('--src_dir', '-s', type=str, default='.', help='source directory')
    parser.add_argument('--build_dir', '-b', type=str, default='build', help='build directory')
    parser.add_argument('--type', '-t', type=str, default='Release', help='build type')
    parser.add_argument('--build_target', type=str, default='all', help='build target')
    parser.add_argument('--install_dir', type=str, default='', help='install directory')
    args = parser.parse_args()
    if args.command == 'init':
        init_project(args.project_name)
    elif args.command == 'config':
        config_project(args.src_dir, args.build_dir, args.gen, args.type)
    elif args.command == 'build':
        build_project(args.build_target, args.build_dir, args.type)
    elif args.command == 'install':
        install_project(args.install_dir, args.build_dir, args.type)
    else:
        print('command error!')