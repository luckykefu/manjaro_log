# Jupyter 魔法命令使用示例

本 Notebook 演示了 Jupyter/IPython 中常用的魔法命令。

魔法命令是以 `%` 或 `%%` 开头的特殊命令，它们不是 Python 语言的一部分，但可以在 Jupyter Notebook 中增强其功能。

- **行魔法命令**: 以单个 `%` 开头，作用于整行。
- **单元格魔法命令**: 以两个 `%%` 开头，作用于整个单元格。

使用 `%lsmagic` 可以查看所有可用的魔法命令。
```python
# 查看所有可用的魔法命令
%lsmagic

```

## 1. 代码执行与性能分析
### `%time`

执行一行代码，并报告其总执行时间。
```python
# 计算一个列表推导式的执行时间
%time result = [i**2 for i in range(1000000)]

```

### `%%time`

执行整个单元格的代码，并报告其总执行时间。
```python
%%time
import numpy as np

# 创建一个大矩阵并进行计算
a = np.random.rand(1000, 1000)
b = np.random.rand(1000, 1000)
c = np.dot(a, b)

```

### `%timeit`

多次执行一行代码以获得更精确的平均执行时间。它会自动选择最佳运行次数。
```python
# 多次执行列表推导式，计算平均时间
%timeit [i**2 for i in range(1000)]

```

### `%%timeit`

多次执行整个单元格的代码以获得更精确的平均执行时间。
```python
%%timeit
# 定义一个简单的函数
def square(x):
    return x * x

# 调用函数
total = 0
for i in range(100):
    total += square(i)

```

### `%prun`

使用 Python 的性能分析器 `cProfile` 来执行代码，并显示每个函数的调用次数和耗时。
```python
# 定义一些函数
def func_a():
    return sum(range(100))

def func_b():
    return [i**2 for i in range(100)]

def main():
    func_a()
    func_b()

# 使用 %prun 分析 main() 函数
%prun main()

```

### `%run`

执行一个外部的 Python 脚本。脚本中定义的变量和函数可以在当前的 Notebook 会话中使用。
```python
# 首先，使用 %%writefile 创建一个名为 my_script.py 的文件
%%writefile my_script.py

import sys

# 定义一个变量
my_variable = "Hello from my_script.py!"

# 定义一个函数
def greet(name):
    print(f"Greetings, {name}!")

# 打印一些信息
print(f"Script name: {sys.argv[0]}")
print(f"Script is running.")

```

```python
# 运行刚刚创建的脚本
%run my_script.py

```

```python
# 现在，我们可以访问脚本中定义的变量和函数
print(my_variable)
greet("Jupyter User")

```

## 2. 环境与信息查询
### `%pwd`

返回当前工作目录。
```python
# 打印当前工作目录
%pwd

```

### `%ls` 或 `!ls` (on Unix/macOS) / `!dir` (on Windows)

列出当前目录下的文件和文件夹。`%ls` 是魔法命令，`!` 前缀允许你执行 shell 命令。
```python
# 列出当前目录下的文件
%ls

```

### `%who` / `%whos`

列出当前交互式命名空间中定义的所有变量。`%whos` 提供更详细的信息（类型、大小等）。
```python
# 定义一些不同类型的变量
a_string = "hello"
a_number = 123
a_list = [1, 2, 3]
import numpy as np
an_array = np.array([4, 5, 6])

```

```python
# 显示所有变量名
%who

```

```python
# 显示所有变量的详细信息
%whos

```

### `%reset` / `%reset -f`

清除当前命名空间中定义的所有变量和名称。`-f` 选项表示强制执行，无需确认。
```python
# 在重置前查看变量
%whos

```

```python
# 强制重置命名空间 (不会弹出确认框)
%reset -f

```

```python
# 再次查看变量，应该为空
%whos

```

### `%pinfo` / `?`

显示对象的详细信息（即 `obj.__doc__` 的内容）。`?` 是 `%pinfo` 的快捷方式。
```python
# 使用 %pinfo 查看 len 函数的帮助信息
%pinfo len

```

```python
# 使用 ? 查看 list 的帮助信息 (效果相同)
list?

```

### `%pinfo2` / `??`

显示对象的更详细的源代码信息（如果可用）。`??` 是 `%pinfo2` 的快捷方式。
```python
# 使用 ?? 查看 numpy.arange 函数的源代码
import numpy as np
np.arange??

```

### `%history`

显示之前执行过的命令历史。
```python
# 显示最近3条输入历史
%history -n 3

```

## 3. 开发与调试
### `%load`

将一个脚本、文件或 URL 的内容加载到当前单元格中。
```python
# %load 

```

### `%%writefile`

将整个单元格的内容写入到一个文件中。
```python
%%writefile new_module.py
def multiply(x, y):
    """This function multiplies two numbers."""
    return x * y

if __name__ == '__main__':
    print(f"5 * 10 = {multiply(5, 10)}")

```

### `%debug`

如果在代码执行后发生异常，可以在一个新的单元格中输入 `%debug` 来进入一个交互式调试器，可以检查堆栈和变量的值。
```python
# 故意制造一个错误
def cause_error(x):
    y = x + 1
    # 这里会发生一个 ZeroDivisionError
    return y / 0

cause_error(10)

```

```python
# 在上面的单元格执行出错后，运行此单元格进入调试模式
# 在调试器中，你可以使用 'u' (up), 'd' (down) 在堆栈中移动，
# 使用 'p variable_name' 打印变量值，使用 'q' 退出调试器。
# %debug

```

### `%load_ext`

加载一个 IPython 扩展。一个非常有用的扩展是 `autoreload`。
```python
# 加载 autoreload 扩展
%load_ext autoreload

```

```python
# 设置 autoreload 模式：2 表示在执行任何代码前都重新加载所有模块
%autoreload 2

```

```python
# 再次写入 new_module.py，这次修改函数内容
%%writefile new_module.py
def multiply(x, y):
    """This function multiplies two numbers and adds 1."""
    return x * y + 1

```

```python
# 导入模块并调用函数
import new_module
new_module.multiply(5, 10)

```

## 4. Shell 命令与系统交互
### `!` (Shell 命令前缀)

在行首使用 `!` 可以执行任何 shell 命令。
```python
# 在 Unix/Linux/macOS 上使用 echo
!echo "Hello from the shell!"

```

```python
# 在 Windows 上使用 echo
# !echo "Hello from the Windows shell!"

```

```python
# 将 Python 变量传递给 shell 命令
message = "This is a variable from Python."
!echo {message}

```

### `%%bash` / `%%script`

将整个单元格的内容作为 bash 脚本（或其他指定的脚本）执行。
```python
%%bash
echo "Running a multi-line bash script."
for i in 1 2 3
do
  echo "Loop iteration $i"
done

```

### `%cd`

更改当前工作目录。
```python
# 查看当前目录
print(f"Current directory: %pwd")

```

```python
# 创建一个新目录并进入它
!mkdir -p temp_jupyter_dir
%cd temp_jupyter_dir

```

```python
# 查看当前目录，应该已经改变
print(f"Current directory: %pwd")

```

```python
# 返回上一级目录
%cd ..

```

```python
# 清理创建的目录
!rm -rf temp_jupyter_dir

```

## 5. 富媒体与可视化
### `%matplotlib`

配置 matplotlib 的集成方式。最常用的选项是 `inline`，它将图表直接嵌入到 Notebook 中。
```python
# 设置 matplotlib 为 inline 模式
%matplotlib inline

import matplotlib.pyplot as plt
import numpy as np

x = np.linspace(0, 10, 100)
y = np.sin(x)

plt.plot(x, y)
plt.title("Sine Wave")
plt.xlabel("X-axis")
plt.ylabel("Y-axis")
plt.show()

```

### `%%html`

将整个单元格的内容渲染为 HTML。
```python
%%html
<div style="border: 2px solid blue; padding: 10px;">
    <h2>This is an HTML heading</h2>
    <p>This is a <strong>paragraph</strong> with some <em>emphasized</em> text.</p>
    <a href="https://jupyter.org" target="_blank">Link to Jupyter.org</a>
</div>

```

### `%%svg`

将整个单元格的内容渲染为 SVG 图像。
```python
%%svg
<svg height="100" width="100">
  <circle cx="50" cy="50" r="40" stroke="green" stroke-width="4" fill="yellow" />
  Sorry, your browser does not support inline SVG.
</svg>

```

### `%%latex`

将整个单元格的内容使用 LaTeX 渲染。这对于显示数学公式非常有用。
```python
%%latex
\begin{align}
\nabla \times \vec{\mathbf{B}} -\, \frac1c\, \frac{\partial\vec{\mathbf{E}}}{\partial t} & = \frac{4\pi}{c}\vec{\mathbf{j}} \\
\nabla \cdot \vec{\mathbf{E}} & = 4 \pi \rho \\
\nabla \times \vec{\mathbf{E}}\, +\, \frac1c\, \frac{\partial\vec{\mathbf{B}}}{\partial t} & = \vec{\mathbf{0}} \\
\nabla \cdot \vec{\mathbf{B}} & = 0
\end{align}

```

## 6. 其他有用的魔法命令
### `%pip` / `%conda`

在 Notebook 内部直接安装 Python 包。这比使用 `!pip install` 更可靠，因为它能确保将包安装到当前内核正在使用的 Python 环境中。
```python
# 使用 %pip 安装一个包 (例如，line_profiler)
# %pip install line_profiler

```

### `%memit`

测量代码执行所消耗的内存。需要先安装 `memory_profiler` 包 (`pip install memory_profiler`)。
```python
# 首先需要安装 memory_profiler
# %pip install memory_profiler

# 加载扩展
%load_ext memory_profiler

# 使用 %memit 测量内存消耗
%memit big_list = list(range(1000000))

```

### `%store`

在变量和 IPython 数据库之间传递变量。可以在不同的 Notebook 会话之间共享变量。
```python
# 创建一个变量并存储它
my_shared_variable = {"name": "Jupyter", "version": "1.0"}
%store my_shared_variable

```

```python
# 删除这个变量
del my_shared_variable
try:
    print(my_shared_variable)
except NameError:
    print("Variable has been deleted.")

```

```python
# 从存储中恢复变量
%store -r my_shared_variable
print(my_shared_variable)

```

### `%capture`

捕获单元格的输出（stdout, stderr）并将其存储在一个变量中。
```python
# 捕获所有输出
%%capture captured_output
print("This is standard output.")
print("This is also standard output.")
# 引发一个错误来捕获 stderr
# print(1 / 0)

```

```python
# 查看捕获的输出
print("--- Captured stdout ---")
print(captured_output.stdout)

print("--- Captured stderr ---")
print(captured_output.stderr)

```

