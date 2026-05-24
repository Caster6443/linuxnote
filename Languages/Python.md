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

## 一

现在开始开发游戏《外星人入侵》。首先创建一个空的 Pygame 窗口,稍后将在其中绘制游戏元素,如飞船和外星人。之后,我们还将让这个游戏响应用户输入,设置背景色,以及加载飞船图像。

### 1.1 创建 **Pygame** 窗口及响应用户输入

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

- 赋给属性 self.screen 的对象是一个 surface。在 Pygame 中, **surface** 是屏幕的一部分, 个人理解surface是一个类，用于显示游戏元素。在这个游戏中,每个元素(如外星人或飞船)都是一个 surface。display.set\_mode() 返回的 surface 表示整个游戏窗口,激活游戏的动画循环后,每经过一次循环都将自动重绘这个 surface,将用户输入触发的所有变化都反映出来。

### 1.2 控制帧率

理想情况下,游戏在所有的系统中都应以相同的速度(帧率)运行。对于可在多种系统中运行的游戏,控制帧率是个复杂的问题,好在 Pygame 提供了一种相对简单的方式来达成这个目标。我们将创建一个时钟(clock),并确保它在主循环每次通过后都进行计时(tick)。当这个循环的通过速度超过我们定义的帧率时,Pygame 会计算需要暂停多长时间,以便游戏的运行速度保持一致。意思是，计算机性能全开时画一帧的用时可能太短，可能一秒画120帧，但出于资源占用考虑我希望它只画60帧，那么就需要通过每次循环画完一帧后停顿一会，让每次循环耗时是原来的两倍，这样就能控制总帧率从120降到60

我们在 \_\_init\_\_() 方法中定义这个时钟:

*alien\_invasion.py*

```python
    def __init__(self):
        """初始化游戏并创建游戏资源"""
        pygame.init()
        self.clock = pygame.time.Clock()

		--snip(省略)--
```

- 初始化 pygame 后,创建 pygame.time 模块中的 Clock 类的一个实例,然后在 run\_game() 的 while 循环末尾让这个时钟进行计时:

```python
    def run_game(self):
        """开始游戏主循环"""
        while True:

		--snip--
                pygame.display.flip()
                self.clock.tick(60)
```

- tick() 方法接受一个参数:游戏的帧率。这里使用的值为 60, Pygame 将尽可能确保这个循环每秒恰好运行 60 次。

### 1.3 设置背景色

Pygame 默认创建一个黑色屏幕,这太乏味了。下面在 \_\_init\_\_() 方法末尾将背景设置为另一种颜色:

*alien\_invasion.py*

```python
    def __init__(self):
        --snip--
        # 设置背景色
        self.bg_color = (230, 230, 230)

    def run_game(self):
        """开始游戏主循环"""
        while True:
            --snip--
                # 每次循环时都重绘屏幕
                self.screen.fill(self.bg_color)
                # 让最近绘制的屏幕可见
                --snip--

```

- 在 Pygame 中,颜色是以 RGB 值指定的。这种色彩模式由红色(R)、绿色(G)和蓝 色(B)值组成,其中每个值的可能取值范围都是 0~255。颜色值(255, 0, 0)表示红 色,(0, 255, 0)表示绿色,(0, 0, 255)表示蓝色。通过组合不同的 RGB 值,可创建超过 1600 万种颜色。在颜色值(230, 230, 230)中,红色、绿色和蓝色的量相同,呈现出一种 浅灰色。我们将这种颜色赋给 self.bg\_color, 然后调用 fill() 方法用这种背景色填充屏幕。fill() 方法用于处理 surface, 只接受一个表示颜色的实参

### 1.4 创建 **Settings** 类

每次给游戏添加新功能时, 通常会引入一些新设置。下面来编写一个名为 settings 的模块, 其中包含一个名为 Settings 的类, 用于将所有设置都存储在一个地方, 以免在代码中到处添加设置。这样, 每当需要访问设置时, 只需使用一个 settings 对象。在项目规模增大时, 这还让游戏的外观和行为修改起来更加容易: 在(接下来将 创建的)settings.py 中修改一些相关的值即可, 无须查找散布在项目中的各种设置。

在文件夹 alien\_invasion 中,新建一个名为 settings.py 的文件,并在其中添加如下 Settings 类:

*settings.py*

```python
class Settings:
    """存储游戏<<外星人入侵>> 中所有设置的类"""

    def __init__(self):
        """初始化游戏的设置"""
        self.screen_width = 1080
        self.screen_height = 1350
        self.bg_color = (230, 230, 230)


```

为了在项目中创建 Settings 实例,并使用它来访问设置,需要将 alien\_invasion.py 修改成下面这样:

*alien\_invasion.py*

```python
--snip--
import pygame
from settings import Settings


class AlienInvasion:
    """管理游戏资源和行为的类"""

    def __init__(self):
        """初始化游戏并创建游戏资源"""
        pygame.init()
        self.clock = pygame.time.Clock()
        self.settings = Settings()
        # 绘制窗口
        self.screen = pygame.display.set_mode(
            (self.settings.screen_width, self.settings.screen_height)
        )
        # 给窗口起名
        pygame.display.set_caption("Alien Invasion")

    def run_game(self):
        """开始游戏主循环"""
        while True:
            --snip--
                # 每次循环时都重绘屏幕
                self.screen.fill(self.settings.bg_color)
                # 让最近绘制的屏幕可见
                pygame.display.flip()
                self.clock.tick(60)
                --snip--

```

## 二

### 2.1 添加飞船图像

**创建一个目录用于存放飞船素材，图片命名为ship.bmp**

### 2.2 创建 **Ship** 类

选择好用于表示飞船的图像后, 需要将其显示到屏幕上。我们创建一个名为 ship 的 模块, 其中包含 Ship 类, 负责管理飞船的大部分行为:

*ship.py*

```python
import pygame


class Ship:
    """管理飞船的类"""

    def __init__(self, ai_game):
        """初始化飞船并设置其初始位置"""
        self.screen = ai_game.screen
        self.screen_rect = ai_game.screen.get_rect()
        # 加载飞船图像并获取其外接矩形
        self.image = pygame.image.load("images/ship.bmp")
        # 调整飞船尺寸
        self.image = pygame.transform.scale(self.image, (56, 72))
        self.rect = self.image.get_rect()
        # 每艘新飞船都放在屏幕底部的中央
        # 让飞船图片的底部中心点，对齐整个游戏窗口（屏幕）的底部中心点
        self.rect.midbottom = self.screen_rect.midbottom

    def blitme(self):
        """在指定位置绘制飞船"""
        self.screen.blit(self.image, self.rect)

```

### 2.3 在屏幕上绘制飞船

下面更新 alien\_invasion.py,创建一艘飞船并调用其方法 blitme():

*alien\_invasion.py*

```python
--snip--
from settings import Settings
from ship import Ship


class AlienInvasion:
    """管理游戏资源和行为的类"""

    def __init__(self):
        --snip--
        # 给窗口起名
        pygame.display.set_caption("Alien Invasion")
        self.ship = Ship(self)

    def run_game(self):
        --snip--
                # 每次循环时都重绘屏幕
                self.screen.fill(self.settings.bg_color)
                self.ship.blitme()
                # 让最近绘制的屏幕可见
                pygame.display.flip()
				--snip--

```

### 2.4 重构:**\_check\_events()** 方法和 **\_update\_screen()** 方法

在大型项目中,经常需要在添加新代码前重构既有的代码。重构旨在简化既有代码的结构,使其更容易扩展。我们在这里将把越来越长的 run\_game() 方法拆分成两个辅助方法。辅助方法(helper method)一般只在类中调用,不会在类外调用。在 Python 中, 辅助方法的名称以单下划线打头。

#### 2.4.1 \_check\_events() 方法

我们将把管理事件的代码移到一个名为 \_check\_events() 的方法中,以简化 run\_game() 并隔离事件循环。通过隔离事件循环,可将事件管理与游戏的其他方面 (如更新屏幕)分离。

下面是新增 \_check\_events() 方法后的 AlienInvasion 类,只有 run\_game() 的代码受到了影响:

*alien\_invasion.py*

```python
    def run_game(self):
        """开始游戏主循环"""
        while True:
            self._check_events()
            # 每次循环时都重绘屏幕
            self.screen.fill(self.settings.bg_color)
            self.ship.blitme()
            # 让最近绘制的屏幕可见
            pygame.display.flip()
            self.clock.tick(60)

    def _check_events(self):
        # 侦听键盘和鼠标事件
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                sys.exit()

```

#### 2.4.2 \_update\_screen() 方法

为了进一步简化 run\_game(),我们把更新屏幕的代码移到一个名为 \_update\_screen() 的方法中:

```
    def run_game(self):
        """开始游戏主循环"""
        while True:
            self._check_events()
            self._update_screen()
            self.clock.tick(60)

    def _check_events(self):
        # 侦听键盘和鼠标事件
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                sys.exit()

    def _update_screen(self):
        # 每次循环时都重绘屏幕
        self.screen.fill(self.settings.bg_color)
        self.ship.blitme()
        # 让最近绘制的屏幕可见
        pygame.display.flip()

```

### 2.5 驾驶飞船

#### 2.5.1 响应按键

在 Pygame 中,事件都是通过 pygame.event.get() 方法获取的,因此需要在 \_check\_events() 方法中指定要检查的事件类型。每当用户按键时,都将在 Pygame 中产生一个 KEYDOWN 事件。

在检测到 KEYDOWN 事件时,需要检查按下的是否是触发行动的键。如果玩家按下的是右方向键,就增大飞船的 rect.x 值,使飞船向右移动:

*alien\_invasion.py*

```python
    def _check_events(self):
        # 侦听键盘和鼠标事件
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                sys.exit()
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_RIGHT:
                    self.ship.rect.x += 1

```

- 如果现在运行 alien\_invasion.py,那么每按一次右方向键,飞船都将向右移动 1 像素。 这只是一个开端,并非控制飞船的高效方式。下面来改进控制方式,允许飞船持续移动。

#### 2.5.2 允许持续移动

当玩家按住右方向键不放时,我们希望飞船持续向右移动,直到玩家释放该键为止。 我们将让游戏检测 pygame.KEYUP 事件,以便知道玩家何时释放右方向键。然后,将结合使用 KEYDOWN 和 KEYUP 事件以及一个名为 moving\_right 的标志来实现持续移动。

当标志 moving\_right 为 False 时,飞船不会移动。当玩家按下右方向键时,我们将这个标志设置为 True;当玩家释放该键时,将这个标志重新设置为 False。

飞船的属性都由 Ship 类控制,因此要给这个类添加一个名为 moving\_right 的属性 和一个名为 update() 的方法。update() 方法检查标志 moving\_right 的状态。 如果这个标志为 True,就调整飞船的位置。我们将在每次通过 while 循环时调用一次这个方法,以更新飞船的位置。

下面是对 Ship 类所做的修改:

*ship.py*

```python
class Ship:
    --snip--
        # 每艘新飞船都放在屏幕底部的中央
        # 让飞船图片的底部中心点，对齐整个游戏窗口（屏幕）的底部中心点
        self.rect.midbottom = self.screen_rect.midbottom
        # 移动标志
        self.moving_right = False

    def update(self):
        if self.moving_right:
            self.rect.x += 1

    def blitme(self):
	    --snip--

```

接下来,需要修改 \_check\_events(),使其在玩家按下右方向键时将 moving\_right 设置为 True,并在玩家释放时将 moving\_right 设置为 False:

*alien\_invasion.py*

```python
    def _check_events(self):
        --snip--
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_RIGHT:
                    self.ship.moving_right = True
            elif event.type == pygame.KEYUP:
                if event.key == pygame.K_RIGHT:
                    self.ship.moving_right = False

```

最后,需要修改 run\_game() 中的 while 循环,以便在每次执行循环时都调用飞船 的 update() 方法:

*alien\_invasion.py*

```python
    def run_game(self):
        """开始游戏主循环"""
        while True:
            self._check_events()
            self.ship.update()
            self._update_screen()
            self.clock.tick(60)

```

飞船的位置将在检测到键盘事件后(但在更新屏幕前)更新。这样能让飞船的位置根据玩家输入进行更新,并确保使用更新后的位置将飞船绘制到屏幕上。

如果现在运行 alien\_invasion.py 并按下右方向键,飞船将持续向右移动,直到释放右方向键为止。总之就是将键盘输入这个动作拆分成了 *按下按键*  和 *按键回弹* 两个过程处理


#### 2.5.3 左右移动

在飞船能够持续向右移动后,添加向左移动的逻辑很容易。我们再次修改 Ship 类和 \_check\_events() 方法。下面显示了对 Ship 类的 \_\_init\_\_() 方法和 update() 方法所做的相关修改:

```
class Ship:
    """管理飞船的类"""

    def __init__(self, ai_game):
        --snip--
        # 移动标志
        self.moving_right = False
        self.moving_left = False

    def update(self):
        if self.moving_right:
            self.rect.x += 1
        if self.moving_left:
            self.rect.x -= 1
	--snip--
```

在 \_\_init\_\_() 方法中,添加标志 self.moving\_left。在 update() 方法中,添加一个 if 代码块,而不是 elif 代码块。这样,如果玩家同时按下左右方向键,将先增大再减小飞船的 rect.x 值,即飞船的位置保持不变。如果使用一个 elif 代码块来处理向左移动的情况,右方向键将始终处于优先地位。在改变飞船的移动方向时, 玩家可能会同时按住左右方向键,此时使用两个 if 块能让移动更准确。

还需对 \_check\_events() 做两处调整:

*alien\_invasion.py*

```
    def _check_events(self):
        # 侦听键盘和鼠标事件
        for event in pygame.event.get():
            --snip--
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_RIGHT:
                    self.ship.moving_right = True
                elif event.key == pygame.K_LEFT:
                    self.ship.moving_left = True
            elif event.type == pygame.KEYUP:
                if event.key == pygame.K_RIGHT:
                    self.ship.moving_right = False
                elif event.key == pygame.K_LEFT:
                    self.ship.moving_left = False

```



#### 2.5.4 调整飞船的速度

当前,每次执行 while 循环时,飞船都移动 1 像素。但是,可以在 Settings 类中添加属性 ship\_speed,用于控制飞船的速度。我们将根据这个属性决定飞船在每次循环时最多移动多远。下面演示了如何在 settings.py 中添加这个新属性:

*settings.py*

```
class Settings:
    """存储游戏<<外星人入侵>> 中所有设置的类"""

    def __init__(self):
        --snip--
        # 飞船的设置
        self.ship_speed = 1.5

```

这里将 ship\_speed 的初始值设置成 1.5。现在在移动飞船时,每次循环将移动 1.5 像素而不是 1 像素。

通过将速度设置指定为浮点数,可在稍后加快游戏的节奏时更细致地控制飞船的速度。然而,rect 的 x 等属性只能存储整数值,因此需要对 Ship 类做些修改:

*ship.py*

```
class Ship:
    """管理飞船的类"""

    def __init__(self, ai_game):
        """初始化飞船并设置其初始位置"""
        self.screen = ai_game.screen
        self.settings = ai_game.settings
        --snip-
        # 每艘新飞船都放在屏幕底部的中央
        # 让飞船图片的底部中心点，对齐整个游戏窗口（屏幕）的底部中心点
        self.rect.midbottom = self.screen_rect.midbottom
        # 在飞船的属性x中存储一个浮点数
        self.x = float(self.rect.x)
        # 移动标志
        self.moving_right = False
        self.moving_left = False

    def update(self):
        """根据移动标志调整飞船的位置"""
        # 更新飞船的属性 x 的值,而不是其外接矩形的属性 x 的值
        if self.moving_right:
            self.x += self.settings.ship_speed
        if self.moving_left:
            self.x -= self.settings.ship_speed
            # 根据self.x更新rect对象
        self.rect.x = int(self.x)

    def blitme(self):
        """在指定位置绘制飞船"""
        self.screen.blit(self.image, self.rect)

```