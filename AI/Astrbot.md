
# 使用Python调用AI












































# AstrBot 插件开发全流程（以 waifu.py 为例）

---

## 1. 项目结构

```
Waifu_plugin/
└── waifu.py          # 插件入口，唯一文件
```

部署到服务器后，路径约定为：
```
/AstrBot/data/plugins/waifu_fetcher/
└── main.py           # 服务器上必须叫 main.py
```

**关键点**：AstrBot 扫描 `data/plugins/` 下每个子目录找 `main.py`，类上的 `@register` 装饰器让框架发现你的插件。

---

## 2. 导入详解（waifu.py 第1-4行）

```python
import requests                              # 发 HTTP 请求，调 waifu.im API
from astrbot.api.event import (
    filter,          # 装饰器工厂：@filter.command("来张图") 注册指令
    AstrMessageEvent, # 事件对象：收到消息时 AstrBot 帮你构造好，包含发消息等方法
    MessageChain,     # 消息链：要发送的消息内容（文字+图片的"容器"）
)
from astrbot.api.star import (
    Context,  # 插件上下文：可以拿配置、调 LLM 等
    Star,     # 插件基类：所有插件必须继承它
    register, # 注册装饰器：告诉 AstrBot "这是个插件"
)
from astrbot.api.message_components import Image  # 图片组件：构造图片消息
```

**容易踩的坑**：
- `MessageChain` 从 `astrbot.api.event` 导入，不是 `message_components`
- `Image` 从 `astrbot.api.message_components` 导入
- 这两个在不同模块，别混

---

## 3. 注册插件（第7行）

```python
@register("waifu_fetcher", "YourName", "二次元动漫图片随机抓取插件", "1.0.0")
class WaifuPlugin(Star):
```

`@register` 四个参数：
| 参数 | 含义 | 你的值 |
|------|------|--------|
| `name` | 插件唯一标识（目录名要一致） | `"waifu_fetcher"` |
| `author` | 作者名 | `"YourName"` |
| `desc` | 插件描述 | `"二次元动漫图片随机抓取插件"` |
| `version` | 版本号 | `"1.0.0"` |

**`Star` 是基类**，所有 AstrBot 插件必须继承它。初始化要接 `Context`：

```python
def __init__(self, context: Context):
    super().__init__(context)   # 必须调用父类 __init__，否则框架不认
```

---

## 4. 注册指令（第12行）

```python
@filter.command("来张图")
async def get_anime_image(self, event: AstrMessageEvent):
```

**`@filter.command("来张图")`** 表示：当有人在群里发 `/来张图`（注意带斜杠）时，AstrBot 会调用这个函数。

其他常用 filter：
```python
@filter.regex(r"来[张只个].*[图照片]")       # 正则匹配
@filter.command_group("图片")                 # 指令组 /图片 xxx
@filter.event_message_type(EventMessageType.GROUP_MESSAGE)  # 只响应群消息
@filter.permission_type(PermissionType.ADMIN)  # 仅管理员可用
```

**`async def`** 是异步函数。AstrBot 内部用 asyncio 事件循环，你自己写的处理函数也必须是 `async`，这样不会阻塞其他消息。

**`event: AstrMessageEvent`** 是框架传进来的事件对象，你可以用它：
- `event.send(chain)` — 发消息（**用 send，不是 send_message！send_message 是内部 classmethod**）
- `event.get_sender_id()` — 获取发送者 QQ 号
- `event.get_group_id()` — 获取群号
- `event.get_message_str()` — 获取纯文本消息内容
- `event.is_admin()` — 判断是不是管理员
- `event.make_result()` — 创建一个空的 MessageEventResult

---

## 5. 调用外部 API（第16-19行）

```python
response = requests.get("https://api.waifu.im/images")
data = response.json()
image_url = data["items"][0]["url"]
```

- `requests.get(url)` — 发 GET 请求，返回 `Response` 对象
- `.json()` — 把返回的 JSON 字符串解析成 Python `dict`
- `data["items"][0]["url"]` — 按 API 返回结构逐层取到图片 URL

**注意**：`requests.get` 是同步的，会短暂阻塞事件循环。对于简单插件没问题，如果请求多应该用 `aiohttp`（异步 HTTP 库）。

API 返回结构示例：
```json
{
  "items": [
    {"url": "https://i.waifu.im/xxxx.jpg", "source": "pixiv", ...}
  ]
}
```

---

## 6. 构造消息链（第21行）

```python
chain = MessageChain().url_image(image_url)
```

这行拆开理解：

```python
# 1. 创建一个空的消息链（相当于一个空盒子）
chain = MessageChain()

# 2. 往盒子里放一张网络图片
chain.url_image("https://example.com/image.jpg")

# .url_image() 内部做的事：
# self.chain.append(Image.fromURL(url))
```

`MessageChain` 的链式调用方法：

| 方法 | 用途 | 示例 |
|------|------|------|
| `.message(text)` | 添加文字 | `.message("Hello")` |
| `.url_image(url)` | 网络图片 | `.url_image("https://...")` |
| `.file_image(path)` | 本地图片 | `.file_image("/tmp/img.jpg")` |
| `.at(qq, name)` | @某人 | `.at("12345", "小明")` |
| `.at_all()` | @所有人 | `.at_all()` |

**可以链式拼接**：
```python
chain = (
    MessageChain()
    .message("给你看张图：")
    .url_image("https://example.com/pic.jpg")
    .message("喜欢吗？")
)
```

---

## 7. 发送消息（第22行）

```python
await event.send(chain)
```

- `await` — 等待异步操作完成。`send` 是异步方法，必须 `await`
- `event.send()` — 把消息链发到当前聊天窗口（私聊/群聊自动判断）

**常见错误**：
```python
# ❌ 错误：send_message 是 @classmethod，需要传 bot 参数
await event.send_message(chain)

# ✅ 正确：用实例方法 send
await event.send(chain)
```

---

## 8. 异常处理（第24-25行）

```python
except Exception as e:
    await event.send(MessageChain().message(f"糟糕，进货失败了：{str(e)}"))
```

- `try/except` — 如果 API 挂了、超时、JSON 解析失败，不会让插件崩溃
- `f"..."` — f-string，花括号里的变量会被替换成值
- `str(e)` — 把异常对象转成可读的错误信息

---

## 9. 部署流程

你刚才用的两条命令：

```bash
# 1. 上传文件到服务器（覆盖旧的 main.py）
scp waifu.py root@Astrbot:/root/astrbot/data/plugins/waifu_fetcher/main.py

# 2. 重启 docker 容器让新代码生效
ssh root@Astrbot "docker restart astrbot"
```

**scp 可以直接覆盖**，不需要先删除旧文件。

完整开发循环：
```
本地写代码 → scp 上传 → docker restart → 群里测试 → 看日志 → 改代码 → 再来一遍
```

查看日志：
```bash
ssh root@Astrbot "docker logs --tail 50 astrbot"
```

---

## 10. 下一步建议

1. **添加更多命令**，比如 `/来张图 safebooru` 切换图源
2. **用了 `requests`（同步）**，可以考虑改成 `aiohttp`（异步），不阻塞其他消息
3. **使用 `event.get_extra()` / `event.set_extra()`** 在多个 handler 间传递数据
4. **用 `event.make_result().message(...).url_image(...)`** 替代手动构造 MessageChain（更简洁）
5. **加权限控制** `@filter.permission_type(PermissionType.ADMIN)` 只让管理员用某些命令