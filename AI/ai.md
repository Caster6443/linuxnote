# 使用Python调用AI

以openai库为例

创建工作环境

```shell
mkdir -pv ai_connect_test
```
 
```shell
cd ai_connect_test/
```
 
```shell
python -m venv venv
```
 
```shell
source venv/bin/activate.fish
```
 
```shell
pip install openai
```

编辑文件

```shell
vim ai_connect.py
```

写入如下内容

*ai_connect.py*

```python
from openai import OpenAI

client = OpenAI(
    api_key="输入模型提供商的api-key",
    base_url="输入模型提供商的接口地址",
)

print("Loading...")

# 发起网络请求,completions的作用是让ai补全对话(ai回复的本质是用户提供上文，ai补全下文)
# create方法会打包下面提供的参数成一个标准的JSON文件，然后通过网卡发送POST请求给服务器
response = client.chat.completions.create(
    model="模型的官方名",
    
    # 消息类型有四种，分别是不同用途，也可以单独使用
    messages = [
    # 第一行：最高级指令，定下基调 (ai预设)
    {"role": "system", "content": "你是一只企鹅，叫声是咕咕嘎嘎。"},
    
    # 历史记录1：用户第一句话
    {"role": "user", "content": "1+1等于几？"},
    
    # 历史记录2：AI 之前的回复 (如果不把这行发过去，AI 就会忘记它刚答过)
    {"role": "assistant", "content": "咕咕嘎嘎咕咕嘎嘎"},
    
    # 当下的提问：用户刚发的最新消息
    {"role": "user", "content": "那我刚才问了你什么数学题？"}
],
    stream=True,  # 开启流式输出
)

print("\n--- 收到回复 ---")
for chunk in response:
    # 每次服务器会传回来一个小碎片(通常包含1-2个字)
    content = chunk.choices[0].delta.content
    if content is not None:
        # 打印这个字并且不要换行(end=""),立刻刷新到屏幕上(flush=True)
        print(content, end="", flush=True)
print("\n------------------")

```








































