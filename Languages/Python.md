# 外星人入侵

注意:游戏《外星人入侵》包含很多不同的文件,因此请在系统中新建一个名为 alien\_invasion 的文件夹,并将这个项目的所有文件都存储到该文件夹中。这样, 相关的 import 语句才能正确工作。

环境部署:

我使用的是linux所以python环境基本开箱即用，只需要创建虚拟环境并安装需要的包即可

创建工作目录(linux)

```
mkdir -pv ~/Code/Python/alien_invasion/
cd ~/Code/Python/alien_invasion/
```

在当前目录下创建虚拟环境，目录名venv

```
python -m venv venv
```

激活环境

```
source venv/bin/activate
```

如果shell为fish的话则需要使用提供的另一个文件，执行命令

```
source venv/bin/activate.fish 
```

安装 Pygame

```
python -m pip install pygame
```

如果你在运行程序或启动终端会话时使用的命令不是 python,而是 python3,务必 将上述命令中的 python 替换为 python3。

现在开始开发游戏《外星人入侵》。首先创建一个空的 Pygame 窗口,稍后将在其中绘制游戏元素,如飞船和外星人。之后,我们还将让这个游戏响应用户输入,设置背景色,以及加载飞船图像。

## 一. 创建 **Pygame** 窗口及响应用户输入

下面创建一个表示游戏的类,以创建空的 Pygame 窗口。在文本编辑器中新建一个文件,将其保存为 `alien\_invasion.py`,再在其中输入如下代码:

*alien\_invasion.py*

```python
import sys
import pygame


class AlienInvasion:
    """管理游戏资源和行为的类"""

    def __init__(self):
        """初始化游戏并创建游戏资源"""
        pygame.init()
        # 绘制窗口
        self.screen = pygame.display.set_mode((1200, 800))
        # 给窗口起名
        pygame.display.set_caption("Alien Invasion")

    def run_game(self):
        """开始游戏主循环"""
        while True:
            # 侦听键盘和鼠标事件
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    sys.exit()
                    # 让最近绘制的屏幕可见
                    # 只要不点退出按键，就不断重绘刷新画面以实现动态效果
                pygame.display.flip()


if __name__ == "__main__":
    # 这行判断是在判断程序是否为直接运行还是被导入的
    # 因为这个文件中不仅有类和方法，还有顶层缩进的可执行代码
    # 如果import引用的话，这些顶层缩进代码会被直接执行，显然这不是期望效果
    # 如果是被import或者from导入的，__name__的值就是文件名(去掉后缀py)
    # 如果是本地直接python file.py直接执行，那么__name__的值就是__main__
    # 创建游戏实例并运行游戏
    ai = AlienInvasion()
    ai.run_game()

```
