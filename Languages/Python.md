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

## 一. 基础环境

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

## 二. 太空飞船

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

```python
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

```python
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

```python
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

```python
class Ship:
    """管理飞船的类"""

    def __init__(self, ai_game):
        """初始化飞船并设置其初始位置"""
        self.screen = ai_game.screen
        self.settings = ai_game.settings
        --snip--
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

    --snip--

```

#### 2.5.5 限制飞船的活动范围

当前,如果玩家按住方向键的时间足够长,飞船将移到屏幕之外,消失得无影无踪。下面来修复这个问题,让飞船到达屏幕边缘后停止移动。为此,将修改 Ship 类的 update() 方法:

*ship.py*

```python
    def update(self):
        """根据移动标志调整飞船的位置"""
        # 更新飞船的属性 x 的值,而不是其外接矩形的属性 x 的值
        if self.moving_right and self.rect.right < self.screen_rect.right:
            self.x += self.settings.ship_speed
        if self.moving_left and self.rect.left > 0:
            self.x -= self.settings.ship_speed
            # 根据self.x更新rect对象
        self.rect.x = int(self.x)

```


#### 2.5.6 重构 **\_check\_events()**

随着游戏的开发,\_check\_events() 方法将越来越长。因此我们将其部分代码放在两个方法中,其中一个处理 KEYDOWN 事件,另一个处理 KEYUP 事件:

*alien\_invasion.py*

```python
    def _check_events(self):
        """响应鼠标和键盘事件"""
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                sys.exit()
            elif event.type == pygame.KEYDOWN:
                self._check_keydown_events(event)
            elif event.type == pygame.KEYUP:
                self._check_keyup_events(event)

    def _check_keydown_events(self, event):
        if event.key == pygame.K_RIGHT:
            self.ship.moving_right = True
        elif event.key == pygame.K_LEFT:
            self.ship.moving_left = True

    def _check_keyup_events(self, event):
        if event.key == pygame.K_RIGHT:
            self.ship.moving_right = False
        elif event.key == pygame.K_LEFT:
            self.ship.moving_left = False
```

#### 2.5.7 按 **Q** 键退出

省的每次鼠标移到右上角按关闭，但我用的wm其实无所谓，还是当案例了(其实就是加两行代码而已)

*alien\_invasion.py*

```python
    def _check_keydown_events(self, event):
        if event.key == pygame.K_RIGHT:
            self.ship.moving_right = True
        elif event.key == pygame.K_LEFT:
            self.ship.moving_left = True
        elif event.key == pygame.K_q:
            sys.exit()

```


#### 2.5.8 在全屏模式下运行游戏

Pygame 支持全屏模式,相比于常规窗口,你可能更喜欢在这种模式下运行游戏。有些游戏在全屏模式下看起来更舒服,而且在一些系统中,游戏在全屏模式下可能有性能上的提升

要在全屏模式下运行这款游戏,可在 \_\_init\_\_() 中做如下修改(记得注释之前的绘制窗口代码):

*alien\_invasion.py*

```python
    def __init__(self):
        """初始化游戏并创建游戏资源"""
        --snip--
        self.settings = Settings()
        self.screen = pygame.display.set_mode((0, 0), pygame.FULLSCREEN)
        self.settings.screen_width = self.screen.get_rect().width
        self.settings.screen_height = self.screen.get_rect().height
        # 绘制窗口
        # self.screen = pygame.display.set_mode(
        #    (self.settings.screen_width, self.settings.screen_height)
        # )
        # 给窗口起名
        pygame.display.set_caption("Alien Invasion")
        --snip--

```

### 2.6 简单回顾

下一节将添加射击功能,为此需要新增一个名为 bullet.py 的文件,并修改一些既有的文件。当前有三个文件,其中包含很多类和方法。在添加其他功能前,先来回顾一下这些文件,以便对这个项目的组织结构有清楚的认识。

####  **2.6.1 alien\_invasion.py**

- 主文件 alien\_invasion.py 包含 AlienInvasion 类,这个类创建在游戏的很多地方会用到的一系列属性:赋给 settings 的设置,赋给 self.screen 的主显示 surface, 以及一个飞船实例。这个模块还包含游戏的主循环,即一个调用 \_check\_events()、ship.update() 和 \_update\_screen() 的 while 循环。它 还在每次通过循环后让时钟按键计时。

- \_check\_events() 方法检测相关的事件(如按下和释放),并通过调用 \_check\_keydown\_events() 方法和 \_check\_keyup\_events() 方法处理这些事件。当前,这些方法负责管理飞船的移动。AlienInvasion 类还包含 \_update\_screen() 方法,这个方法在每次主循环中重绘屏幕。

- 要开始游戏《外星人入侵》,只需运行文件 alien\_invasion.py,其他文件(settings.py 和 ship.py)包含的代码会被导入这个文件。

#### **2.6.2 settings.py**

- 文件 settings.py 包含 Settings 类,这个类只包含 \_\_init\_\_() 方法,用于初始化控制游戏外观和飞船速度的属性。

####  **2.6.3 ship.py**

- 文件 ship.py 包含 Ship 类,这个类包含 \_\_init\_\_() 方法、管理飞船位置的 update() 方法和在屏幕上绘制飞船的 blitme() 方法。表示飞船的图像 ship.bmp 存储在文件夹 images 中。


### 2.7 射击

- 下面来添加射击功能。我们将编写在玩家按空格键时发射子弹(用小矩形表示)的代码。子弹将在屏幕中直线上升,并在抵达屏幕上边缘后消失。

#### 2.7.1 添加子弹设置

首先,更新 settings.py,在 \_\_init\_\_() 方法末尾存储新类 Bullet 所需的值:

*settings.py*

```python
    def __init__(self):
        --snip--
        # 子弹设置
        self.bullet_speed = 2.0
        self.bullet_width = 3
        self.bullet_height = 15
        self.bullet_color = (60, 60, 60)

```

- 这些设置创建了宽 3 像素、高 15 像素的深灰色子弹。子弹的速度比飞船稍快。

#### 2.7.2 创建 **Bullet** 类

下面来创建存储 Bullet 类的文件 bullet.py,其前半部分如下:

*bullet.py*

```python
import pygame
from pygame.sprite import Sprite


# 类的继承 class 子类名(父类名):
class Bullet(Sprite):
    """管理飞船所发射子弹的类"""

    def __init__(self, ai_game):
        """在飞船的当前位置创建一个子弹对象"""
        # 这里可以理解为调用执行父类sprite()里面的def __init__初始化流程
        super().__init__()
        
        self.screen = ai_game.screen
        self.settings = ai_game.settings
        self.color = self.settings.bullet_color
        # 在(0,0)处创建一个表示子弹的矩形，再设置正确的位置
        self.rect = pygame.Rect(
            0, 0, self.settings.bullet_width, self.settings.bullet_height
        )
        self.rect.midtop = ai_game.ship.rect.midtop
        # 存储用浮点数表示的子弹位置
        self.y = float(self.rect.y)


```

下面是 bullet.py 的后半部分,包括 update() 方法和 draw\_bullet() 方法:

*bullet.py*

```python
    def update(self):
        """向上移动子弹"""
        # 更新子弹的准确位置
        self.y -= self.settings.bullet_speed
        # 更新表示子弹的rect的位置
        self.rect.y = self.y

    def draw_bullet(self):
        """在屏幕上绘制子弹"""
        pygame.draw.rect(self.screen, self.color, self.rect)

```

- update() 方法管理子弹的位置。发射之后,子弹向上移动,这意味着 *y* 坐标将不断减小(坐标系原点在左上角)。为了更新子弹的位置,从 self.y 中减去 settings.bullet\_speed 的值。接下来,将 self.rect.y 设置为 self.y 的值。
- 属性 bullet\_speed 让我们能够随着游戏的进行或根据需要加快子弹的速度,以调整游戏的行为。子弹发射后,其 *x* 坐标始终不变,因此子弹将沿直线垂直上升。
- 在需要绘制子弹时,我们调用 draw\_bullet()。draw.rect() 使用存储在 self.color 中的颜色值,填充表示子弹的 rect 占据的那部分屏幕。

#### 2.7.3 将子弹存储到编组中

在定义 Bullet 类和必要的设置后,便可编写代码在玩家每次按空格键时都发射一颗子弹了。我们将在 AlienInvasion 中创建一个编组(group),用于存储所有有效的子弹,以便管理发射出去的所有子弹。这个编组是 Group 类(来自 pygame.sprite 模块)的一个实例。Group 类类似于列表,但提供了有助于开发游戏的额外功能。在主循环中,将使用这个编组在屏幕上绘制子弹,以及更新每颗子弹的位置。

首先,导入新的 Bullet 类:

*alien\_invasion.py*

```python
--snip--
from ship import Ship
from bullet import Bullet
```

接下来,在 \_\_init\_\_() 中创建用于存储子弹的编组:

*alien\_invasion.py*

```python
    def __init__(self):
        """初始化游戏并创建游戏资源"""
        --snip--
        self.ship = Ship(self)
        self.bullets = pygame.sprite.Group()

```

然后在 while 循环中更新子弹的位置:

*alien\_invasion.py*

```python
    def run_game(self):
        """开始游戏主循环"""
        while True:
            self._check_events()
            self.ship.update()
            self.bullets.update()
            self._update_screen()
            self.clock.tick(60)

```

在对编组调用 update() 时,编组会自动对其中的每个精灵调用 update(),因此 self.bullets.update() 将为 bullets 编组中的每颗子弹调用 bullet.update()。

#### 2.7.4 开火

在 AlienInvasion 中,需要修改 \_check\_keydown\_events(),以便在玩家按空格键时发射一颗子弹。无须修改 \_check\_keyup\_events(),因为在玩家释放空格键时不需要做任何操作。还需修改 \_update\_screen(),确保在调用 flip() 前在屏幕上重绘每颗子弹。

为了发射子弹,需要做的工作不少,因此编写一个新方法 \_fire\_bullet() 来完成 这项任务:

*alien\_invasion.py*

```python
    def _check_keydown_events(self, event):
        --snip--
        elif event.key == pygame.K_q:
            sys.exit()
        elif event.key == pygame.K_SPACE:
            self._fire_bullet()

    def _check_keyup_events(self, event):
        --snip--

    def _fire_bullet(self):
        """创建一颗子弹,并将其加入编组 bullets"""
        new_bullet = Bullet(self)
        self.bullets.add(new_bullet)

    def _update_screen(self):
        """更新屏幕上的图像，并切换到新屏幕"""
        self.screen.fill(self.settings.bg_color)
        for bullet in self.bullets.sprites():
            bullet.draw_bullet()
        self.ship.blitme()
        # 让最近绘制的屏幕可见
        pygame.display.flip()

```

当玩家按空格键时,我们调用 \_fire\_bullet()。在 \_fire\_bullet() 中,创建一个 Bullet 实例并将其赋给 new\_bullet再使用 add() 方法 将其加入编组 bullets。add() 方法类似于列表的 append() 方法,不过是专门为 Pygame 编组编写的。

bullets.sprites() 方法返回一个列表,其中包含 bullets 编组中的所有精灵。为了在屏幕上绘制发射出的所有子弹,遍历 bullets 编组中的精灵,并对每个精灵都调用 draw\_bullet()。我们将这个循环放在绘制飞船的代码行前面,以防子弹出现在飞船上。

如果此时运行 alien\_invasion.py,将能够左右移动飞船,并发射任意数量的子弹。子弹在屏幕上直线上升,抵达屏幕上边缘后消失,如图所示。子弹的尺寸、颜色和速度可以在 settings.py 中修改。

![627](_resources/Python/8cc05a96a0024a6e72f7f746b4c0f5fa_MD5.jpg)


#### 2.7.5 删除已消失的子弹

当前,虽然子弹会在抵达屏幕上边缘后消失,但这仅仅是因为 Pygame 无法在屏幕外绘制它们。这些子弹实际上依然存在,它们的 *y* 坐标为负数且越来越小。这是个问题, 因为它们将继续消耗系统的内存和处理能力。

我们需要将这些已消失的子弹删除,否则游戏所做的无谓工作将越来越多,进而变得越来越慢。为此,需要检测表示子弹的 rect 的 bottom 属性是否为零。如果是,就表明子弹已飞过屏幕上边缘:

*alien\_invasion.py*

```python
    def run_game(self):
        """开始游戏主循环"""
        while True:
            self._check_events()
            self.ship.update()
            self.bullets.update()
            # 删除已消失的子弹
            for bullet in self.bullets.copy():
                if bullet.rect.bottom <= 0:
                    self.bullets.remove(bullet)
                    print(len(self.bullets))
            self._update_screen()
            self.clock.tick(60)

```

- 在使用 for 循环遍历列表(或 Pygame 编组)时,Python 要求该列表的长度在整个循环中保持不变。这意味着不能从 for 循环遍历的列表或编组中删除元素,因此必须遍历编组的副本。使用方法 copy() 来作为 for 循环的遍历对象,让我们能够在循环中修改原始编组 bullets。我们检查每颗子弹,看看它是否从屏幕上边缘消失了。如果是,就将其从 bullets 中删除。最后使用函数调用 print() 显示当前还有多少颗子弹,以核实确实删除了已消失的子弹。

- 如果这些代码没有问题,我们在发射子弹后查看终端窗口时,将发现随着子弹一颗颗地在屏幕上边缘消失,子弹数将逐渐降为零。运行这个游戏并确认子弹被正确地删除后,请将 print() 删除。如果不删除,游戏的速度将大大减慢,因为将输出写入终端 的时间比将图形绘制到游戏窗口的时间还多。

#### 2.7.6 限制子弹数量

*settings.py*

```python
		--snip--
        self.bullet_color = (60, 60, 60)
        self.bullet_allowed = 3

```

这将未消失的子弹数限制为三颗。在 AlienInvasion 的 \_fire\_bullet() 中,会 在创建新子弹前检查未消失的子弹数是否小于该设置:

*alien\_invasion.py*

```python
    def _fire_bullet(self):
        """创建一颗子弹,并将其加入编组 bullets"""
        if len(self.bullets) < self.settings.bullet_allowed:
            new_bullet = Bullet(self)
            self.bullets.add(new_bullet)
```

#### 2.7.7 创建 **\_update\_bullets()** 方法

编写并检查子弹管理代码后,可将这些代码移到一个独立的方法中,以确保 AlienInvasion 类整洁。为此,创建一个名为 \_update\_bullets() 的新方法, 并将其放在 \_update\_screen() 前面:

*alien\_invasion.py*

```python
    def _fire_bullet(self):
        """创建一颗子弹,并将其加入编组 bullets"""
        --snip--

    def _update_bullets(self):
        """更新子弹的位置并删除已消失的子弹"""
        # 更新子弹的位置
        self.bullets.update()
        # 删除已消失的子弹
        for bullet in self.bullets.copy():
            if bullet.rect.bottom <= 0:
                self.bullets.remove(bullet)

    def _update_screen(self):
		--snip--
```

_update\_bullets() 的代码是从 run\_game() 剪切粘贴而来的,这里只是添加了清晰注释。

run\_game() 中的 while 循环又变得简单了:

*alien\_invasion.py*

```python
    def run_game(self):
        """开始游戏主循环"""
        while True:
            self._check_events()
            self.ship.update()
            self._update_bullets()
            self._update_screen()
            self.clock.tick(60)
```

- 我们让主循环包含尽可能少的代码,这样只要看方法名就能迅速知道游戏中发生的情况了。主循环检查玩家的输入,并更新飞船的位置和所有未消失的子弹的位置。然后,在每次循环末尾,都使用更新后的位置来绘制新屏幕,并让时钟计时。

请再次运行 alien\_invasion.py,确认发射子弹时没有错误。


## 三. 太空鲨鱼

我突然想做飞船大战太空鲨鱼了，所以前面的注意将alien相关修改为shark，虚拟环境也重新创建刷新一下

### 3.1 项目回顾

在开发大型项目时,进入每个开发阶段前都要回顾一下开发计划,牢记接下来要通过编写代码完成哪些任务。本章将完成以下开发计划。

- 在屏幕左上角添加一个太空鲨,并指定合适的边距。
- 沿屏幕上边缘添加一行太空鲨,再不断地添加成行的外星人,直到填满屏幕的上半部分。
- 让外星人向两侧和向下移动,直到太空鲨舰队被全部击落、有太空鲨撞到飞船或有太空鲨抵达屏幕的下边缘。如果太空鲨舰队都被击落,将再创建一个太空鲨舰队;如果有太空鲨撞到飞船或抵达屏幕的下边缘,就销毁太空鲨并再创建一个太空鲨舰队。
- 限制玩家可用的飞船数量,分配的飞船被用完后,游戏将结束。

我们将在实现功能的同时完善这个计划,但就目前而言,计划已足够详尽,可以开始编写代码了。

在项目中添加新功能前,还应审核既有的代码。每进入一个新阶段,项目通常会更复杂,因此最好对混乱或低效的代码进行清理。因为我们一直在不断重构,所以当前没有需要重构的代码。



### 3.2 创建第一个太空鲨鱼

自行寻找素材并保存为images/shark.bmp

#### 3.2.1 创建Shark类

*shark.py*

```python
import pygame
from pygame.sprite import Sprite


class Shark(Sprite):
    """表示单个太空鲨的类"""

    def __init__(self, ai_game):
        """初始化太空鲨鱼并设置其起始位置"""
        super().__init__()
        self.screen = ai_game.screen
        # 加载太空鲨图像并设置其rect属性
        self.image = pygame.image.load("images/shark.png")
        self.rect = self.image.get_rect()
        # 每个太空鲨最初都在屏幕左上角生成
        self.rect.x = self.rect.width
        self.rect.y = self.rect.height
        # 储存太空鲨的精确水平位置
        self.x = float(self.rect.x)

```

- 除了位置不同以外,这个类的大部分代码与 Ship 类相似。每个太空鲨最初都位于屏幕的左上角附近。将每个太空鲨的左边距都设置为太空鲨的宽度,并将上边距设置为太空鲨的高度,这样较为美观。我们主要关心的是太空鲨的水平移动速度,因此精确地记录了每个太空鲨的水平位置。

- Shark类不需要在屏幕上绘制外星人的方法,因为我们将使用一个 Pygame 编组方法,自动地在屏幕上绘制编组中的所有元素。


#### 3.2.2 创建 **Shark** 实例

要让第一个太空鲨在屏幕上现身,需要创建一个 Shark 实例。这属于初始化工作之一,因此需要把这些代码放在 SharkInvasion 类的 \_\_init\_\_() 方法末尾。我们最终会创建一个太空鲨舰队,涉及的工作量不少,因此将新建一个名为 \_create\_fleet() 的辅助方法。

在类中,方法的定义顺序无关紧要,只要按统一的标准排列就行。我们将把 \_create\_fleet() 放在 \_update\_screen() 前面,但其实放在 SharkInvasion 类的任何地方都行。首先,需要导入 Shark 类。

*shark_invasion.py*

```python
--snip--
from bullet import Bullet
from shark import Shark
```

下面是修改后的\_\_init\_\_方法:

*shark_invasion.py*

```python
    def __init__(self):
        """初始化游戏并创建游戏资源"""
        --snip--
        self.bullets = pygame.sprite.Group()
        self.sharks = pygame.sprite.Group()
        self._create_fleet()

```

这创建了一个用于存储鲨鱼舰队的编组,还调用了接下来将编写的 \_create\_fleet() 方法。

下面是新编写的 \_create\_fleet() 方法:

*shark\_invasion.py*

```python
    def _update_bullets(self):
        --snip--

    def _create_fleet(self):
        """创建一个太空鲨舰队"""
        # 创建一个太空鲨
        shark = Shark(self)
        self.sharks.add(shark)

    def _update_screen(self):
	    --snip--
```

在这个方法中,先创建一个 Shark 实例,再将其添加到用于存储鲨鱼舰队的编组中。 太空鲨默认被放在屏幕的左上角附近。

要让太空鲨现身,需要在 \_update\_screen() 中对太空鲨编组调用 draw() 方法:

*shark\_invasion.py*

```python
    def _update_screen(self):
        """更新屏幕上的图像，并切换到新屏幕"""
        --snip--
        self.ship.blitme()
        self.sharks.draw(self.screen)
        # 让最近绘制的屏幕可见
        pygame.display.flip()

```

这时运行程序，屏幕上就会出现鲨鱼了。我们在这里不妨为游戏添加一个背景美观

依旧自己找素材，另存为images/bg.png

*shark\_invasion.py*

```python
class SharkInvasion:
    """管理游戏资源和行为的类"""

    def __init__(self):
        """初始化游戏并创建游戏资源"""
        --snip--
        # 绘制窗口
        self.screen = pygame.display.set_mode(
            (self.settings.screen_width, self.settings.screen_height)
        )
        self.background = pygame.image.load("images/bg.png").convert()
        # 给窗口起名
        pygame.display.set_caption("Shark Invasion")

```

- 这里注意到调用了convert()方法对图片进行优化，不然游戏帧会不稳定，可能会有疑问，为什么让万年不变且图层不同的背景也参与进帧重画中呢？这不是资源浪费吗？因为pygame的每帧重画无法实现图层独立刷新

然后我们把它画出来

*shark\_invasion.py*

```python
    def _update_screen(self):
        """更新屏幕上的图像，并切换到新屏幕"""
        self.screen.fill(self.settings.bg_color)
        self.screen.blit(self.background, (0, 0))
        for bullet in self.bullets.sprites():
        --snip--
```

- 考虑到图层问题所以要注意先后画出的顺序

效果图:

![621](_resources/Python/66935c8e2fab304187435087e7c6f6f9_MD5.jpg)

- 可以注意到我偷偷改了子弹的素材，感兴趣的可以自己修改，逻辑都是一样的


### 3.3 创建鲨鱼舰队

- 要绘制鲨鱼舰队,需要确定如何使用太空鲨填充屏幕的上半部分,同时避免游戏窗口过于拥挤。实现这个目标的方式有很多,我们将采取如下方法:沿屏幕上边缘水平向右不断地添加太空鲨,直到填满一整行;然后重复这个过程,直到没有足够的垂直空间供我们再添加一行为止。

#### 3.3.1 创建一行太空鲨鱼

*shark\_invasion.py*

```python
    def _create_fleet(self):
        """创建一个太空鲨舰队"""
        # 创建一个太空鲨, 再不断添加，直到没有空间添加太空鲨为止
        # 太空鲨的间距为太空鲨的宽度
        shark = Shark(self)
        shark_width = shark.rect.width
        current_x = shark_width
        while current_x < (self.settings.screen_width - 2 * shark_width):
            new_shark = Shark(self)
            new_shark.x = current_x
            new_shark.rect.x = current_x
            self.sharks.add(new_shark)
            current_x += 2 * shark_width

```

#### 3.3.2 重构 **\_create\_fleet()**

倘若只需使用前面的代码就能创建一个鲨鱼舰队,也许应该让 \_create\_fleet() 保持原样,但鉴于创建鲨鱼舰队的工作还未完成,我们稍微整理一下这个方法。为此,添加辅助方法 \_create\_alien(),并在 \_create\_fleet() 中调用它:

*shark\_invasion.py*

```python
    def _create_fleet(self):
        """创建一个太空鲨舰队"""
        --snip--
        while current_x < (self.settings.screen_width - 2 * shark_width):
            self._create_shark(current_x)
            current_x += 2 * shark_width

    def _create_shark(self, x_position):
        """创建一个太空鲨鱼并将其放在当前行中"""
        new_shark = Shark(self)
        new_shark.x = x_position
        new_shark.rect.x = x_position
        self.sharks.add(new_shark)
```

#### 3.3.3 添加多行太空鲨鱼

- 为了创建一个太空鲨鱼舰队,我们需要不断添加太空鲨,直到没有足够的空间再添加一行为止。我们将使用一个嵌套循环:将当前循环放在另一个 while 循环中。里面的循环负责沿水平方向添加太空鲨,关注的是太空鲨的 *x* 值;而外面的循环沿垂直方向添加太空鲨,关注的是太空鲨的 *y* 值。我们将在到达屏幕底部附近后停止添加太空鲨,以避免覆盖飞船,并且在飞船和太空鲨舰队之间留下一些空间,让玩家有足够的时间去击落外星人。

下面演示了如何在 \_create\_fleet() 中嵌套两个 while 循环:

*shark\_invasion.py*

```python
    def _create_fleet(self):
        """创建一个太空鲨舰队"""
        # 创建一个太空鲨, 再不断添加，直到没有空间添加太空鲨为止
        # 太空鲨的间距为太空鲨的宽度
        shark = Shark(self)
        shark_width, shark_height = shark.rect.size
        current_x, current_y = shark_width, shark_height
        while current_y < (self.settings.screen_height - 3 * shark_height):
            while current_x < (self.settings.screen_width - 2 * shark_width):
                self._create_shark(current_x, current_y)
                current_x += 2 * shark_width
            # 添加一行鲨鱼后，重置x值并递增y值
            current_x = shark_width
            current_y += 2 * shark_height

```

注意到我们传给辅助方法两个参数，但目前只支持一个，因此需要修改 \_create\_shark(),以正确地设置太空鲨的垂直位置:

```python
    def _create_shark(self, x_position, y_position):
        """创建一个太空鲨鱼并将其放在当前行中"""
        new_shark = Shark(self)
        new_shark.x = x_position
        new_shark.rect.x = x_position
        new_shark.rect.y = y_position
        self.sharks.add(new_shark)

```

此时运行程序，多行太空鲨已经被画出来了

#### 3.4 让太空鲨舰队移动

下面来让太空鲨舰队在屏幕上向右移动,到达屏幕右边缘后下移一定的距离,再向左移动,依此类推。这样不断地移动所有的太空鲨,直到太空鲨都被击落、有太空鲨撞上飞船或有太空鲨抵达屏幕的下边缘。下面先来让太空鲨向右移动。

#### 3.4.1 向右移动太空鲨舰队

移动太空鲨舰队需要使用 shark.py 中的 update() 方法。对于太空鲨舰队中的每个太空鲨,都要调用它。首先,添加一个控制太空鲨速度的设置:

*settings.py*

```python
    def __init__(self):
        """初始化游戏的设置"""
        --snip--
        # 太空鲨设置
        self.shark_speed = 1.0
```

然后,在 shark.py 中使用这个设置来实现 update():

*shark.py*

```python
    def __init__(self, ai_game):
        --snip--
        self.screen = ai_game.screen
        self.settings = ai_game.settings
        # 加载太空鲨图像并设置其rect属性
        self.image = pygame.image.load("images/shark.png")
        --snip--

    def update(self):
        """向右移动外星人"""
        self.x += self.settings.shark_speed
        self.rectx = self.x

```

在 \_\_init\_\_() 中添加属性 settings,以便能够在 update() 中获取太空鲨鱼的速度。每次更新太空鲨时,都将它向右移动,移动量为 shark_speed 的值。我们使用属性 self.x 跟踪每个太空鲨的精确位置,这个属性可存储浮点数。然后, 使用 self.x 的值来更新太空鲨的 rect 的水平位置。

在主 while 循环中,我们已调用了更新飞船和子弹的方法,现在还要调用更新每个太空鲨位置的方法。

需要编写一些代码来管理太空鲨舰队的移动,因此新建一个名为 \_update\_sharks() 的方法。我们在更新子弹后更新太空鲨的位置,因为稍后要检查是否有子弹击中了太空鲨:

*shark\_invasion.py*

```python
    def run_game(self):
        """开始游戏主循环"""
        while True:
            self._check_events()
            self.ship.update()
            self._update_bullets()
            self._update_sharks()
            self._update_screen()
            self.clock.tick(60)

```

只要缩进正确,将这个方法定义在模块的什么地方无关紧要,但为了确保代码有条理,我将它放在 \_update\_bullets() 方法的后面,以便与 while 循环中的调用顺序保持一致。下面是我们编写的第一版 \_update\_aliens():

*shark\_invasion.py*

```python
    def _update_sharks(self):
        """更新太空鲨舰队中所有太空鲨的位置"""
        self.sharks.update()
```

- 对 sharks 编组调用 update() 方法,将自动对每个太空鲨调用 update() 方法。现在运行这个游戏,将看到太空鲨舰队向右移动,并在屏幕右边缘处消失。


#### 3.4.2 创建表示太空鲨舰队移动方向的设置

下面来创建让太空鲨鱼到达屏幕右边缘后先向下移动、再向左移动的设置。实现这种行为的代码如下:

*settings.py*

```
        # 太空鲨设置
        self.shark_speed = 1.0
        self.fleet_drop_speed = 10
        # fleet_direction 为 1 表示向右移动，为 -1 表示向左移动
        self.fleet_direction = 1
```

- 设置 fleet\_drop\_speed 来指定当有太空鲨到达屏幕边缘时,太空鲨舰队向下移动的速度。将这个速度与水平速度分开是有好处的,便于分别调整。
- 要实现设置 fleet\_direction,可将其设置为文本值,如 'left' 或 'right', 但这样必须编写 if-elif 语句来检查太空鲨舰队的移动方向。鉴于只有两个可能的方向,我们使用值 1 和 -1 来表示它们,并在太空鲨舰队改变方向时在这两个值之间切换。 (鉴于向右移动时需要增大每个太空鲨的 *x* 坐标,而向左移动时需要减小每个太空鲨的 *x* 坐标,因此使用这两个数字来表示方向也十分合理。)

#### 3.4.3 检查太空鲨是否到达了屏幕边缘

现在需要编写一个方法来检查太空鲨是否到达了屏幕边缘,还需要修改 update() 让 每个太空鲨都沿正确的方向移动。这些代码位于 Shark 类中:

*shark.py*

```python
    def check_edges(self):
        """如果外星人位于屏幕边缘，就返回True"""
        screen_rect = self.screen.get_rect()
        return (self.rect.right >= screen_rect.right) or (self.rect.left <= 0)

    def update(self):
        """向左或向右移动外星人"""
        self.x += self.settings.shark_speed * self.settings.fleet_direction
        self.rect.x = self.x

```

#### 3.4.4 向下移动太空鲨舰队并改变移动方向

当有太空鲨到达屏幕(右/左)边缘时,需要让整个太空鲨舰队向下移动,并改变它们的移动方向(向左/向右)。因此,需要在 SharkInvasion 中添加一些代码,检查是否有太空鲨到达了左边缘或右边缘。为此,编写方法 \_check\_fleet\_edges() 和 \_change\_fleet\_direction(),并修改 \_update\_sharks()。我把这些新方法 放在 \_create\_shark() 后面,不过将其放在 SharkInvasion 类中的什么位置其实也是无关紧要的(只要缩进正确):

*shark\_invasion.py*

```python
    def _check_fleet_edges(self):
        """在有太空鲨到达边缘时采取相应的措施"""
        for shark in self.sharks.sprites():
            if shark.check.edges():
                self._change_fleet_direction()
                break

    def _change_fleet_direction(self):
        """将整个太空鲨舰队向下移动，并改变它们的方向"""
        for shark in self.sharks.sprites():
            shark.rect.y += self.settings.fleet_drop_speed
        self.settings.fleet_direction *= -1

```

原理简单易懂，通过循环遍历每只太空鲨，如果有触碰到边缘的太空鲨，就调用函数执行它的下一步逻辑，往下移动然后横向反方向继续跑

下面显示了对 \_update\_aliens() 所做的修改:

*shark\_invasion.py*

```python
    def _update_sharks(self):
        """检查是否有太空鲨位于屏幕边缘，并更新整个太空鲨舰队的位置"""
        self._check_fleet_edges()
        self.sharks.update()

```

- 我们将方法 \_update\_sharks() 修改成了这样:先调用 \_check\_fleet\_edges(),再更新每个太空鲨的位置。

如果现在运行这个游戏，太空鲨舰队将在屏幕上左右来回移动,并在到达屏幕边缘后向下移动。现在可以开始向太空鲨射击了,并检查是否有太空鲨撞到飞船或抵达屏幕的下边缘。

### 3.5 击落太空鲨鱼

- 我们创建了飞船和太空鲨舰队,但子弹在击中太空鲨时,将穿过太空鲨,因为还没有检查碰撞。在游戏编程中,碰撞指的是游戏元素有重叠。为了让子弹能够击落太空鲨, 我们将使用函数 sprite.groupcollide() 检测两个编组的成员之间的碰撞。

#### 3.5.1 检测子弹和太空鲨鱼的碰撞

当子弹击中太空鲨时,我们需要马上知道,以便在碰撞发生后让子弹立即消失。为此,将在更新所有子弹的位置后(绘制子弹前)立即检测碰撞。

sprite.groupcollide() 函数将一个编组中每个元素的 rect 与另一个编组中每个元素的 rect 进行比较。在这里,是将每颗子弹的 rect 与每个太空鲨的 rect 进行比较,并返回一个字典,其中包含发生了碰撞的子弹和太空鲨。在这个字典中,键表示特定的子弹,而关联的值表示被该子弹击中的太空鲨(在后面实现记分系统时, 也将使用这个字典)。

在 \_update\_bullets() 方法末尾,添加如下检查子弹和太空鲨碰撞的代码:

*shark\_invasion.py*

```python
    def _update_bullets(self):
        """更新子弹的位置并删除已消失的子弹"""
        # 更新子弹的位置
        self.bullets.update()
        # 删除已消失的子弹
        for bullet in self.bullets.copy():
            if bullet.rect.bottom <= 0:
                self.bullets.remove(bullet)
        # 检查是否有子弹击中了太空鲨
        # 如果是，就删除对应的子弹和太空鲨
        collisions = pygame.sprite.groupcollide(self.bullets, self.sharks, True, True)

```

- 这些新增的代码将 self.bullets 中的所有子弹与 self.sharks 中的所有太空鲨进行比较,看它们是否重叠了在一起。每当有子弹和太空鲨的 rect 重叠时, groupcollide() 就在返回的字典中添加一个键值对。两个值为 True 的实参告诉 Pygame 在发生碰撞时删除对应的子弹和外星人。[要模拟能够飞到屏幕上边缘的高能子弹(它会消灭击中的每个太空鲨,但自己不受影响),可将第一个布尔实参设置为 False,并保留第二个布尔实参为 True。这样被击中的太空鲨将消失,但所有的子弹始终有效,直到抵达屏幕的上边缘后消失。]

- 此时运行这个游戏,被击中的太空鲨将消失

#### 3.5.2 生成新的太空鲨舰队

这个游戏的一个重要特点是,邪恶的太空鲨无穷无尽:一个太空鲨舰队被击落后,又会出现另一个太空鲨舰队。

要在一个太空鲨舰队被击落后显示另一个太空鲨舰队,首先需要检查编组 sharks 是否为空。如果是,就调用 \_create\_fleet()。我们将在 \_update\_bullets() 末尾执行这项任务,因为太空鲨都是在这里被击落的:

*shark\_invasion.py*

```python
    def _update_bullets(self):
        --snip--
        collisions = pygame.sprite.groupcollide(self.bullets, self.sharks, True, True)
        if not self.sharks:
            self.bullets.empty()
            self._create_fleet()
```

#### 3.5.3 重构 **\_update\_bullets()**

下面来重构 \_update\_bullets(),使其不再执行那么多任务。为此,将处理子弹和太空鲨碰撞的代码移到一个独立的方法中:

*shark\_invasion.py*

```python
    def _update_bullets(self):
        """更新子弹的位置并删除已消失的子弹"""
        # 更新子弹的位置
        self.bullets.update()
        # 删除已消失的子弹
        for bullet in self.bullets.copy():
            if bullet.rect.bottom <= 0:
                self.bullets.remove(bullet)

        self._check_bullet_shark_collisions()

    def _check_bullet_shark_collisions(self):
        """响应子弹和外星人的碰撞"""
        # 删除发生碰撞的子弹和外星人
        collisions = pygame.sprite.groupcollide(self.bullets, self.sharks, True, True)

        if not self.sharks:
            self.bullets.empty()
            self._create_fleet()

```

- 这里创建了一个新方法 \_check\_bullet\_shark\_collisions(),用于检测子弹和太空鲨之间的碰撞,以及在整个太空鲨舰队被全部击落时采取相应的措施。这能避免 \_update\_bullets() 过长,简化后续的开发工作。

### 3.6 结束游戏

- 如果玩家根本不会输,游戏还有什么趣味和挑战性可言?因此,如果玩家没能在足够短的时间内将整个太空鲨舰队全部击落,导致有太空鲨撞到了飞船或到达屏幕的下边缘,飞船将被摧毁。与此同时,我们还会限制玩家可使用的飞船数。在玩家用光所有的飞船后,游戏将结束。

#### 3.6.1 检测太空鲨和飞船的碰撞

首先检查太空鲨和飞船之间的碰撞,以便能够在太空鲨撞上飞船时做出合适的响应。 为此,在 SharkInvasion 中更新每个太空鲨的位置后,立即检测太空鲨和飞船之间的碰撞。

*shark\_invasion.py*

```
    def _update_sharks(self):
        """检查是否有太空鲨位于屏幕边缘，并更新整个太空鲨舰队的位置"""
        self._check_fleet_edges()
        self.sharks.update()
        # 检测太空鲨和飞船之间的碰撞
        if pygame.sprite.spritecollideany(self.ship, self.sharks):
            print("Ship hit!!!")

```

- 第六行的第一个参数可能会报错，因为ship并不是精灵，不必理会，它不干扰程序正常运行，后续会进行改写

#### 3.6.2 响应太空鲨和飞船的碰撞

现在需要确定,当太空鲨与飞船发生碰撞时,该做些什么。我们不是销毁 Ship 实例 再创建一个新的,而是通过跟踪游戏的统计信息来记录飞船被撞了多少次(跟踪统计信息还有助于记分)。

下面来编写一个用于跟踪游戏统计信息的新类 GameStats,并将其保存为文件 game\_stats.py:

*game\_stats.py*

```python
class GameStats:
    """跟踪游戏的统计信息"""
    def __init__(self, ai_game):
        """初始化统计信息"""
        self.settings = ai_game.settings
        self.reset_stats()

    def reset_stats(self):
        """初始化在游戏运行期间可能变化的统计信息"""
        self.ships_left = self.settings.ship_limit
```

- 在游戏运行期间,只创建一个 GameStats 实例,但每当玩家开始新游戏时,都需要重置一些统计信息。为此,在 reset\_stats() 方法中初始化大部分统计信息,而不 是在 \_\_init\_\_() 中直接初始化。然后在 \_\_init\_\_() 中调用这个方法,这样在创建 GameStats 实例时将妥善地设置这些统计信息。在玩家开始新游戏时, 也能调用 reset\_stats()。

当前,只有一项统计信息 ships\_left,其值将在游戏运行期间不断变化。玩家在一开始拥有的飞船数存储在 settings 类的 ship\_limit 属性中:

*settings.py*

```python
 # 飞船设置
 self.ship_speed = 1.5
 self.ship_limit = 3
```

还需对 shark\_invasion.py 做些修改,以创建一个 GameStats 实例。首先,更新这个文件开头的 import 语句:

*shark\_invasion.py*

```python
import sys
from time import sleep
import pygame
from settings import Settings
from game_stats import GameStats
from ship import Ship
--snip--
```

从 Python 标准库的模块 time 中导入 sleep() 函数,以便能够在飞船被太空鲨撞到后让游戏暂停一会儿。此外,还导入了 GameStats。

接下来,在 \_\_init\_\_() 中创建一个 GameStats 实例:

*shark\_invasion.py*

```python
    def __init__(self):
        """初始化游戏并创建游戏资源"""
        --snip--
        # 给窗口起名
        pygame.display.set_caption("Shark Invasion")
        # 创建一个用于存储游戏统计信息的实例
        self.stats = GameStats(self)

        self.ship = Ship(self)
        --snip--
```

在创建游戏窗口后(但在定义诸如飞船等其他游戏元素之前),创建一个 GameStats 实例。

当有太空鲨撞到飞船时,将余下的飞船数减 1,创建一个新的太空鲨舰队,并将飞船重新放在屏幕底部的中央。另外,让游戏暂停一会儿,让玩家意识到发生了碰撞,并在创建新的太空鲨舰队前重整旗鼓。

下面将实现这些功能的大部分代码都放到新方法 \_ship\_hit() 中(我们会在 \_update\_aliens() 中调用它,在有太空鲨撞到飞船时执行其中的代码):

*shark\_invasion.py*

```python
    def _ship_hit(self):
        """响应飞船和太空鲨的碰撞"""
        # 将 ships_left 减1
        self.stats.ships_left -= 1
        # 清空太空鲨列表和子弹列表
        self.bullets.empty()
        self.sharks.empty()
        # 创建一个新的太空鲨舰队，并将飞船放在屏幕底部的中央
        self._create_fleet()
        self.ship.center_ship()
        # 暂停
        sleep(0.5)

```

在 \_update\_aliens() 中,在有外星人撞到飞船时,不调用 print() 函数,而是 调用 \_ship\_hit():

*shark\_invasion.py*

```python
    def _update_sharks(self):
        --snip--
        # 检测太空鲨和飞船之间的碰撞
        if pygame.sprite.spritecollideany(self.ship, self.sharks):
            self._ship_hit()
```

下面是新方法 center\_ship(),请将其添加到 ship.py 中:

*ship.py*

```python
    def center_ship(self):
        """将飞船放在屏幕底部的中央"""
        self.rect.midbottom = self.screen_rect.midbottom
        self.x = float(self.rect.x)
```

然后可以运行游戏进行测试，飞船碰到太空鲨会短暂暂停后重新开始游戏

#### 3.6.3 有太空鲨到达屏幕下边缘

如果有太空鲨到达屏幕的下边缘,游戏应该像有太空鲨撞到飞船那样做出响应。为了检测这种情况,在 shark\_invasion.py 中添加一个新方法:

*shark\_invasion.py*

```python
    def _check_sharks_bottom(self):
        """检查是否有太空鲨到达了屏幕的下边缘"""
        for shark in self.sharks.sprites():
            if shark.rect.bottom >= self.settings.screen_height:
                # 像飞船被撞到一样进行处理
                self._ship_hit()
                break
```

我们在 \_update\_sharks() 中调用 \_check\_sharks\_bottom():

```python
    def _update_sharks(self):
        --snip--
        # 检测太空鲨和飞船之间的碰撞
        if pygame.sprite.spritecollideany(self.ship, self.sharks):
            self._ship_hit()
        # 检查是否有太空鲨到达了屏幕的下边缘
        self._check_sharks_bottom()
```

#### 3.6.4 游戏结束

现在这个游戏看起来更完整了,但它永远都不会结束——ships\_left 只会不断地变成越来越小的负数。下面添加标志 game\_active,以便在玩家的飞船用完后结束游戏。首先,在 SharkInvasion 类的方法 \_\_init\_\_() 末尾设置这个标志:

*shark\_invasion.py*

```python
    def __init__(self):
        """初始化游戏并创建游戏资源"""
        --snip--
        # 游戏启动后处于活动状态
        self.game_active = True
```

接下来在 \_ship\_hit() 中添加代码,在玩家的飞船用完后将 game\_active 设置为 False:

```python
    def _ship_hit(self):
        """响应飞船和太空鲨的碰撞"""
        if self.stats.ships_left > 0:
            # 将 ships_left 减1
            self.stats.ships_left -= 1
            # 清空太空鲨列表和子弹列表
            self.bullets.empty()
            self.sharks.empty()
            # 创建一个新的太空鲨舰队，并将飞船放在屏幕底部的中央
            self._create_fleet()
            self.ship.center_ship()
            # 暂停
            sleep(0.5)
        else:
            self.game_active = False

```

### 3.7 确定应运行游戏的哪些部分

我们需要确定游戏的哪些部分在所有情况下都应运行,哪些部分仅在游戏处于活动状态时才运行:

*shark\_invasion.py*

```python
    def run_game(self):
        """开始游戏主循环"""
        while True:
            self._check_events()
            if self.game_active:
                self.ship.update()
                self._update_bullets()
                self._update_sharks()
                self._update_screen()
                self.clock.tick(60)
```

在主循环中,在所有情况下都需要调用 \_check\_events(),即便游戏处于非活动状态也是如此。例如,程序需要知道玩家是否按了 Q 键以退出游戏或单击了关闭窗口的按钮;还需要在等待玩家重新开始游戏时持续更新屏幕,以便显示这期间的更改(比如提供一个等待动画)。其他的方法仅在游戏处于活动状态时才需要调用,因为当游戏处于非活动状态时,不用更新游戏元素的位置。

现在运行这个游戏时,它将在飞船用完后停止不动。





## 四. 记分

本节将添加一个 Play 按钮,它在游戏开始前出现,并在游戏结束后再次出现,让玩家能够开始新游戏。

当前,这个游戏在玩家运行 shark\_invasion.py 时就开始了。下面让游戏在一开始处于非活动状态,并提示玩家单击 Play 按钮来开始游戏。为此,像下面这样修改 SharkInvasion 类的 \_\_init\_\_() 方法:

*shark\_invasion.py*

```python
class SharkInvasion:
    """管理游戏资源和行为的类"""

    --snip--
        # 游戏启动后处于非活动状态
        self.game_active = False

    def run_game(self):
```

现在,游戏在一开始处于非活动状态,等玩家单击我们创建的 Play 按钮后,才能开始游戏。

### 4.1 创建 **Button** 类

由于 Pygame 没有内置创建按钮的方法,我们将编写一个 Button 类,用于创建带标签的实心矩形。你可在游戏中使用这些代码来创建任意按钮。下面是 Button 类的第一部分,请将这个类保存为文件 button.py:

*button.py*

```python
import pygame.font


class Button:
    """为游戏创建按钮的类"""

    def __init__(self, ai_game, msg):
        """初始化按钮的属性"""
        self.screen = ai_game.screen
        self.screen_rect = self.screen.get_rect()
        # 设置按钮的尺寸和其他属性
        self.width, self.height = 200, 50
        self.button_color = (0, 135, 0)
        self.text_color = (255, 255, 255)
        self.font = pygame.font.SysFont(None, 48)
        # 创建按钮的rect对象，并使其居中
        self.rect = pygame.Rect(0, 0, self.width, self.height)
        self.rect.center = self.screen_rect.center
        # 按钮的标签只需创建一次
        self._prep_msg(msg)

    def _prep_msg(self, msg):
        """将msg渲染为图像，并使其在按钮上居中"""
        self.msg_image = self.font.render(msg, True, self.text_color, self.button_color)
        self.msg_image_rect = self.msg_image.get_rect()
        self.msg_image_rect.center = self.rect.center

    def draw_button(self):
        """绘制一个用颜色填充的按钮，再绘制文本"""
        self.screen.fill(self.button_color, self.rect)
        self.screen.blit(self.msg_image, self.msg_image_rect)

```

### 4.2 在屏幕上绘制按钮

将在 SharkInvasion 中使用 Button 类来创建一个 Play 按钮。首先,更新 import 语句:

*shark\_invasion.py*

```python
--snip--
from game_stats import GameStats
from button import Button
```

由于只需要一个 Play 按钮,因此在 SharkInvasion 类的 \_\_init\_\_() 方法中创建它。可以将这些代码放在 \_\_init\_\_() 方法的末尾:

*shark\_invasion.py*

```python
    def __init__(self):
        --snip--
        # 游戏启动后处于活动状态
        self.game_active = False

        # 创建Play按钮
        self.play_button = Button(self, "Play")

```

这些代码创建一个标签为 Play 的 Button 实例,但没有将它显示到屏幕上。要显示这个按钮,在 \_update\_screen() 中对这个按钮调用 draw\_button() 方法:

*shark\_invasion.py*

```python
    def _update_screen(self):
        --snip--
        self.sharks.draw(self.screen)
        # 如果游戏处于非活动状态，就绘制Play按钮
        if not self.game_active:
            self.play_button.draw_button()
        pygame.display.flip()

```

为了让 Play 按钮显示在屏幕上其他所有元素之上,要在绘制其他所有元素后再绘制这个按钮,然后切换到新屏幕。将这些代码放在一个 if 代码块中,让按钮仅在游戏处于非活动状态时才出现。

现在运行这个游戏,将在屏幕中央看到一个 Play 按钮。


### 4.3 开始游戏

为了在玩家单击 Play 按钮时开始新游戏,在 \_check\_events() 末尾添加如下 elif 代码块,以监视与这个按钮相关的鼠标事件:

*shark\_invasion.py*

```python
    def _check_events(self):
        """响应鼠标和键盘事件"""
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
            --snip--
            elif event.type == pygame.MOUSEBUTTONDOWN:
                mouse_pos = pygame.mouse.get_pos()
                self._check_play_button(mouse_pos)

    def _check_play_button(self, mouse_pos):
        """在玩家单击Play按钮时开始新游戏"""
        if self.play_button.rect.collidepoint(mouse_pos):
            self.game_active = True

```

- 无论玩家单击屏幕的什么地方,Pygame 都将检测到一个 MOUSEBUTTONDOWN 事件,但我们只想让这个游戏在玩家单击 Play 按钮时做出响应。为此,使用 pygame.mouse.get\_pos(),它返回一个元组,其中包含玩家单击鼠标时光标的 *x* 坐标和 *y* 坐标。我们将这个元组传递给新方法 \_check\_play\_button() 。
- 然后在新方法中使用 rect 的 collidepoint() 方法检查鼠标的单击位置是否在 Play 按钮的 rect 内。如果是,就将 game\_active 设置为 True,让游戏开始。

至此,现在应该能够开始这个游戏了。游戏结束时,game\_active 会被设置为 False,从而重新显示 Play 按钮。


### 4.4 重置游戏

前面编写的代码只处理了玩家第一次单击Play按钮的




























