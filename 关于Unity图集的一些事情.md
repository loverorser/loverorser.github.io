# 关于Unity图集的一些事情

> 主要包括图集合批和打包的一些事情。
>
> 前面是一些碎碎念和一些实验，不想看的话可以跳到总结那一章。

## SpritePacker的Mode

> 参见https://docs.unity3d.com/2022.2/Documentation/Manual/SpritePackerModes.html

## 条件准备

Mode选用`Sprite Atlas V2 - Enabled`，

现在有三张图片sp0,sp1,sp2，在一个图集tp中。

有一个图集tp，勾选`Include in Build`。

场景中有两个`Image`组件。

我把`sp0`打在一个AB包中`AB0`

我把`sp1`打在另一个AB包中`AB1`

我把`sp2`打在同一个AB包中`AB1`

## 第一种情况

现在我运行时加载AB包，`AB0`，从`AB0`中加载`Sprite`的`sp0`，赋给`Image0`组件。

现在我运行时加载AB包，`AB1`，从`AB1`中加载`Sprite`的`sp1`，赋给`Image1`组件。

会合批吗？

**不会**

## 第二种情况

现在我运行时加载AB包，`AB1`，从`AB1`中加载`Sprite`的`sp1`，赋给`Image0`组件。

继续从`AB1`中加载`Sprite`的`sp2`，赋给`Image1`组件。

会合批吗？

**会**

## 结论

在同一个图集中，如果图集里的图片分散在不同的AB包中，那么无法合批。只有在同一AB包中的才能合批。**原因下面会讲。**



## 分析一下打包的manifest文件

```
ClassTypes:
- Class: 28
  Script: {instanceID: 0}
- Class: 213
  Script: {instanceID: 0}
- Class: 687078895
  Script: {instanceID: 0}
SerializeReferenceClassIdentifiers: []
Assets:
- Assets/boss_skill_001.png
- Assets/boss_skill_002.png
Dependencies: []

```

注意到`ClassTypes`有三种，`28`对应`Texture`，`213`对应`Sprite`，`687078895`对应`SpriteAtlas`。表示这个ab包确实有`SpriteAtlas`。[ClassType参见](https://docs.unity3d.com/6000.4/Documentation/Manual/ClassIDReference.html)

为什么会有`Texture`呢？因为图集包含`sprite`，而原始`sprite`的格式就是`Texture`

奇怪的是在`Assets`下只有进包的图片，但是没有*.spriteAtlasv2。**原因下面会讲。**

## 再来看一下不勾选Include in Build的情况

```
ClassTypes:
- Class: 213
  Script: {instanceID: 0}
SerializeReferenceClassIdentifiers: []
Assets:
- Assets/boss_skill_001.png
- Assets/boss_skill_002.png
Dependencies: []

```

可以看到只剩下一个类型213就是`Sprite`

比较两个AB包的大小，包含图集的AB包为19k，不包含的为3k。很正常，因为图集存储需要空间。

## 还有什么新发现，资源冗余

图集有三张图，0和1在一个AB包中，2在另一个AB包中。

不勾选`Include in Build`时，大小为3k，2k

勾选`Include in Build`时，大小为19k，19k

也就是说同一个图集同时进了两个AB包，**资源冗余**。

## 如何避免资源冗余：给图集单独打AB包

*勾选或者不勾选*`Include in Build`，同时给图集单独打一个AB包，发现两个图片的AB包大小又变回了3k，2k。图集的AB包的大小为18k。

```
ClassTypes:
- Class: 28
  Script: {instanceID: 0}
- Class: 213
  Script: {instanceID: 0}
- Class: 687078895
  Script: {instanceID: 0}
SerializeReferenceClassIdentifiers: []
Assets:
- Assets/New Sprite Atlas.spriteatlasv2
Dependencies:
- G:/AB/b1.ab
- G:/AB/b3.ab

```

分析`manifest`文件，发现这个图集AB包依赖于另两个图片AB包。

## 如果第一个AB包有两张图片，第二个AB包有一张图片和图集呢？

*勾选或者不勾选*`Include in Build`，发现第一个AB包3k，第二个AB包19k

```
ClassTypes:
- Class: 28
  Script: {instanceID: 0}
- Class: 213
  Script: {instanceID: 0}
- Class: 687078895
  Script: {instanceID: 0}
SerializeReferenceClassIdentifiers: []
Assets:
- Assets/boss_skill_003.png
- Assets/New Sprite Atlas.spriteatlasv2
Dependencies:
- G:/AB/b1.ab

```

分析第二个AB包的`manifest`文件，发现这个包依赖于第一个包。



## 使用Sprite的时候，他怎么知道我这个Sprite在哪个图集

生成图集的时候，Sprite也会生成信息，指向该`sprite`对应的图集；

# 总结

## 打包的时候

- 如果不勾选`Include in Build`，那么需要**显式**将图集打包。图集所在的AB包，会依赖于，图集包含的图片们所在的AB包。
- 如果勾选`Include in Build`，那么没有必要**显式**打包图集，如果**显式**打包图集了，那么情况和不勾选`Include in Build`一样。
- 如果勾选`Include in Build`，在打包AB包的时候，该AB包内的图片如果在某个图集中，那么会**隐式**把这个图集包含进AB包中。
- 如果勾选`Include in Build`，在打包AB包的时候，如果图片A在第一个AB包中，图片B在第二个AB包中，那么图集会**隐式**打两份，一份在第一个AB包中，一份在第二个AB包中。
- 如果勾选`Include in Build`，请把一个图集中的所有图片放在一个AB包下，否则会造成资源冗余。
- 如果勾选`Include in Build`，那么`manifest`中不会把`spriteatlasv2`包含进去，*隐式包含*。

## 使用的时候

### 如果不勾选`Include in Build`

- 如果通过图集取图片，那么可以手动加载AB包，然后`AssetBundle.LoadAsset<SpriteAtlas>`，然后取`SpriteAtlas.GetSprite`进行使用。
- 注意如果要取的图片和图集不在一个`Bundle`中，那么需要先加载好图片所在的`Bundle`。
- 如果直接从AB包中取`sprite`使用，大概率报错。因为该`sprite`索引到一个图集，我们需要把它所在的图集给它。
- 解决办法是，`SpriteAtlasManager.atlasRequested`添加一个回调，根据传入的图集名称，我们加载AB包，从AB包中加载图集，提供之。
- 两种办法都可以正常合批。

### 如果勾选`Include in Build`，并且没有手动把SpriteAtlas打进去

- 如果勾选`Include in Build`，那么`manifest`中不会把`spriteatlasv2`包含进去，*隐式包含*。因此无法通过`LoadAsset<SpriteAtlas>`找到图集。
- 因此，我们不需要也不在乎加载图集这件事，我们直接拿`sprite`用就是了，which正是`Include in Build`的目的。
- 如果图集中的图片A和图片B在同一个AB包中，加载图片A会**隐式**加载图集，加载图集B会用之前**隐式**加载好的图集，可以合批。
- 如果图集中的图片A和图片B在两个不同AB包中，加载图片A会**隐式**加载图集，加载的图集是第一个AB包中**隐式进包**的图集；加载图集B会**隐式**加载第二个图集，加载的图集是第二个AB包中**隐式进包**的图集。不会合批，并且内存会有两份一样的图集。*这是我们要极力避免的一种情况，方法一是打包的时候图片A和图片B打在一个AB包里，方法二是把图集**显式**打进AB包，然后通过`SpriteAtlasManager.atlasRequested`加载并且返回图集。*
- 可以通过`Resources.FindObjectsOfTypeAll<SpriteAtlas>`来确认当前内存有多少图集。

### 如果勾选`Include in Build`，并且把SpriteAtlas打进了AB包

- 其实基本上不可能用这种方法。
- 这样就退化成了不勾`Include in Build`了