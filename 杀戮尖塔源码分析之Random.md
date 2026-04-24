# 杀戮尖塔源码分析之Random

> 杀戮尖塔2有一个特点就是确定性随机，比如你的随机卡牌奖励，在SL后，奖励是不会变的。
> 这篇文章写的很好。https://www.zhihu.com/question/432127454/answer/2377639313

## 从计算机随机说起

对于随机概念，我们分为三种随机：

- 真随机：真随机数发生器，利用电路中的噪音或量子原理产生真的随机数。*对于游戏开发中，一般没必要。其一是游戏中用伪随机已经足够能满足策划需求；其二是用伪随机执行效率更高；其三是用伪随机只需要同步种子和随机次数即可。*
- 伪随机：给定一个随机数种子，利用随机数算法给出随机序列（**PRNG**）。对于一般的游戏来说，已经足够能满足需求。
- 伪伪随机：位于应用层，由程序手动控制，一般用来保底/微调。比如原神抽卡，达到一定次数后手动提高概率。

## 杀戮尖塔2中的随机

### Chaotic随机

```
public static Rng Chaotic { get; } = new Rng((uint)DateTimeOffset.Now.ToUnixTimeSeconds());
```

以时间戳作为随机数种子，业界内常用的做法。主要用来生成与种子无关的随机数。比如特效随机扰动等。

### Seed随机

以自定义作为随机数种子。

- 随机数种子

杀戮尖塔随机数种子是`string`类型。

- 手动输入随机数种子

玩家开局的时候手动输入一串`string`

- 自动生成随机数种子

```
public static string GetRandomSeed(int length = 10)
{
	string text;
	do
	{
		StringBuilder stringBuilder = new StringBuilder();
		for (int i = 0; i < length; i++)
		{
			stringBuilder.Append(Rng.Chaotic.NextItem("0123456789ABCDEFGHJKLMNPQRSTUVWXYZ"));
		}
		text = stringBuilder.ToString();
	}
	while (BadWordChecker.ContainsBadWord(text));
	return text;
}
```

代码很简单，给定要生成的字符的个数，从0-1 a-z（注意不包含O和I）中随机取一个，依次拼接。

注意有一些`BadWord`不合法，可能是死种？待确认。

### 用的随机数算法

杀戮尖塔2用的随机数算法是`C#`的`Random`，`Random`初始化的需要传入一个`int`种子。

上文中杀戮尖塔2给的随机数种子的类型是`string`，需要手动将`string`转为`int`。

一种办法是直接用自带的`GetHashCode()`方法，但是存在不同平台的不确定性，因为实现的.Net版本不同。所以更明智的选择是手动实现。

```
public static int GetDeterministicHashCode(string str)
{
	int num = 352654597;
	int num2 = num;
	for (int i = 0; i < str.Length; i += 2)
	{
		num = ((num << 5) + num) ^ str[i];
		if (i == str.Length - 1)
		{
			break;
		}
		num2 = ((num2 << 5) + num2) ^ str[i + 1];
	}
	return num + num2 * 1566083941;
}
```

经典的取哈希算法。

### 不同的随机类型

杀戮尖塔2中针对不同的随机模块有对于的类型

```
public enum PlayerRngType
{
	Rewards,
	Shops,
	Transformations
}
```

```
public enum RunRngType
{
	UpFront,
	Shuffle,
	UnknownMapPoint,
	CombatCardGeneration,
	CombatPotionGeneration,
	CombatCardSelection,
	CombatEnergyCosts,
	CombatTargets,
	MonsterAi,
	Niche,
	CombatOrbs,
	TreasureRoomRelics
}
```

也就是说，改变A模块的结果不会改变B模块的概率。

对于每个不同的模块，都会通过模块的名字作为附加种子，生成对应的`Rng`实例。

```
public Rng(uint seed = 0u, int counter = 0)
{
	Counter = 0;
	Seed = seed;
	_random = new System.Random((int)seed);
	FastForwardCounter(counter);
}

public Rng(uint seed, string name)
	: this(seed + (uint)StringHelper.GetDeterministicHashCode(name))
{
}
```

### 如何保存游戏中的随机数

注意到一个函数

```
public void FastForwardCounter(int targetCount)
{
	if (Counter > targetCount)
	{
		throw new InvalidOperationException($"Cannot fast-forward an Rng counter to a lower number (current = {Counter}, target = {targetCount})");
	}
	while (Counter < targetCount)
	{
		Counter++;
		_random.Next();
	}
}
```

保存游戏的时候，我们只需要保存随机数种子和随机次数即可，原因在上文提及，随机序列是固定的。

加载游戏或者联机同步的时候，使用随机数种子和随机次数，就能保证一致性。

> 在帧同步里，同样可以用类似的方法。

## 小结

其实实现起来很简单，关键点在于种子的选取。注意杀戮尖塔2中的环境是单线程的。如果是多线程可以考虑每个线程存一个`Random`实例，一般服务器会用到。