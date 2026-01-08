# 关于NPC交互对话

## 先梳理一下流程吧

- 首先，玩家走到哪里，走到靠近某个NPC，弹出F交互
- 点击交互按钮，然后呢？发一个消息包给服务器，我点击了某某ID的【NPC】*注意不是物体*
- 服务器收到消息后，balabala，发个回包
- 客户端收到回包后，【1】打开对话UI开始对话？【2】切镜头？



所以我现在需要一个索引

ServerID -> 在场景中的配置Id -> 对话表的唯一ID

- 每次进游戏，注册好VirtualCamera和EmptyGameObject
- 每次进入新场景中，先注册好serverID和transform到camera里，还有Player的ServerID



表有Guid是种怪表的从1->10的，怎么知道是哪个场景的那张表呢

subtable用group获取

服务器创建了一个NPC 这边客户端注册的时候应该知道是哪个场景哪个Index的怪 唯一标识！

因为要对上StoryDialogue的表



点击交互按钮->发包给服务器->服务器发回包->走StoryDialogue



先测测镜头

关于位置的变换
