# 关于新项目的UI框架

## 核心思想 数据和显示分离

数据改变 AttrChange -> 显示改变 Text.text=value

显示改变 onValueChanged -> 数据改变 data=value



- `UIBase_Data`存数据用`Dic<string,System.Object> data`，装箱拆箱？
- 



客户端的EventSystem有两种Register的方法

第一种 `EventSystem.Register<T>`

第二种直接加`AEventAttribute`特性

## 增加空白点击控件

## 关于不同分辨率适配

首先确定一个基准分辨率，`1920*1080`，在此基础上获得设备的实际分辨率，计算二者的Ratio。

在`CanvasScaler`组件中有几种模式，我们选择`ScaleWithScreenSize`。把基础分辨率填进去。

在`ScreenMatchMode`属性中有三种模式，`MatchWidthOrHeight` `Shrink`和`Expand`

```
case ScreenMatchMode.MatchWidthOrHeight:
{
    // We take the log of the relative width and height before taking the average.
    // Then we transform it back in the original space.
    // the reason to transform in and out of logarithmic space is to have better behavior.
    // If one axis has twice resolution and the other has half, it should even out if widthOrHeight value is at 0.5.
    // In normal space the average would be (0.5 + 2) / 2 = 1.25
    // In logarithmic space the average is (-1 + 1) / 2 = 0
    float logWidth = Mathf.Log(screenSize.x / m_ReferenceResolution.x, kLogBase);
    float logHeight = Mathf.Log(screenSize.y / m_ReferenceResolution.y, kLogBase);
    float logWeightedAverage = Mathf.Lerp(logWidth, logHeight, m_MatchWidthOrHeight);
    scaleFactor = Mathf.Pow(kLogBase, logWeightedAverage);
    break;
}
case ScreenMatchMode.Expand:
{
    scaleFactor = Mathf.Min(screenSize.x / m_ReferenceResolution.x, screenSize.y / m_ReferenceResolution.y);
    break;
}
case ScreenMatchMode.Shrink:
{
    scaleFactor = Mathf.Max(screenSize.x / m_ReferenceResolution.x, screenSize.y / m_ReferenceResolution.y);
    break;
}
```



## 关于异型屏适配

大概意思就是说，在UI的根节点上，设置它的`RectTransform`的`sizeDelta`的x值。

- 自动适配，获取safeArea，设置。安卓和iOS可能要用原生方法来获取。
- 手动适配，让用户手动设置。

## 关于红点

提供红点枚举。

### 父子节点

红点存在这种需求：我的父节点下有若干子节点，只要有子节点发生变化需要同步到父节点，父节点检测完自己后也要检测子节点。常见的应用场景是，最外面有一个活动按钮，活动界面有一个特殊活动入口，特殊活动入口有一关，这就有三层了。



标签类提供了添加父节点绑定的参数

```c#
public RedPointAttribute(RedPointType pointType, RedPointType baseType = RedPointType.None, RedPointParamsType paramsType = RedPointParamsType.NoParams)
```

如果是None，表示没有父节点，如果非None，表示有。

管理器会收集两次红点类型，第一次收集，简单地遍历所有红点枚举，生成单例储存；第二次收集，遍历所有带父节点的红点枚举，找到对应的父节点，把子节点加入到它的子节点列表中，同时把子节点的父节点设为之。

### 添加监听

红点标脏触发有两种，通过事件触发和通过玩家数据库变化触发。

每个红点类可以重写`OnInit`方法，在这个方法里添加要监听的事件枚举。当事件触发后，会调用

```c#
protected virtual bool CheckEventSetDirty(Entity receiver, Entity sender, EventParamBase e)
{
    return true;
}
```

来判断是否要标脏，可以重载这个函数做自己功能的逻辑。

同时我们也支持监听数据库玩家数据是否变化

```c#
protected void AddServerDataRegister(int poolType, int index)
```

参数包括数据库类型和数据库字段索引，效果同上，同样可以重载数据库检查是否需要标脏逻辑。

### 标脏逻辑

标脏就是设置`IsDirty`的值，如果发现有父红点，那么也会设置父红点的值，层层往上。同时会把对应的红点枚举标脏，加入到待检查列表中。

### 检查逻辑

在管理类的`OnUpdate`方法里，每次会遍历所有标了脏的需要`Check`的红点类型，是一个列表，遍历完后清空。

调用红点类型对应的单例类的`Check`方法，然后调用单例类所有子红点的`Check`方法，最终获得本红点类型下的红点情况，显示还是隐藏。最后遍历绑定的所有`RedPoint`物体，把本红点类型和状态传过去。

### 显隐逻辑

在`RedPoint`中，每次外面传了红点类型和状态之后，自己这边会做一个检查，遍历所有的传过来了的红点类型，只要有一个状态为`true`，那么就把物体显示，如果所有的状态都为`false`，那么就把物体隐藏。

### 绑定逻辑

管理类提供`BindTarget(type,obj)`接口，用来将需要显示的obj绑定到对应的红点枚举中。管理类会先通过红点类型找到对应的单例，然后把obj绑定到单例里去。绑定后，会给obj添加一个辅助`MonoBehaviour`，RedPoint。

注意绑定的时候如果有脏标记会刷新一次。



**Control**：每个红点枚举有对应的子类，在子类编写你的Check逻辑，Check返回bool，表示是否有红点。Check逻辑用到的数据是通过全局拿的。

**View**：管理类提供`BindTarget(type,obj)`接口，用来将需要显示的obj绑定到对应的红点枚举中。绑定后，会给obj添加一个辅助`MonoBehaviour`，RedPoint。

红点类检测时机：绑定obj，初始化，事件监听等。当时机到了后，会将对应红点子类标脏。在Update逻辑中，遍历脏红点子类，判断红点状态，分发到红点子类绑定的Obj中。

绑定的Obj的RedPoint组件根据传过来的红点状态，设置红点的显隐。如果由多个红点枚举控制，那么根据规则，（仅当全部，任意一个），设置红点的显隐。

拓展：在绑定obj时，可以传入自定义的数据作为参数。



## 关于UI上显示特效

- 用RenterTexture抓，费，要摄像机，一般用来试衣间
- 用两个Camera叠
- 用UIParticle组件

## 关于引导



## 关于滚动列表

