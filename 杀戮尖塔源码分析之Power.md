# 杀戮尖塔源码分析之Power

所谓的**Power**，也就是我们常说的**Buff**。我们着重讲解生命周期。

**Power**可以挂在人或者怪物身上，实际上，二者都为**Creature**，之后文章会有介绍。

## Power如何添加

```
public static class PowerCmd
{
	public static async Task Apply(PowerModel power, Creature target, decimal amount, Creature? applier, CardModel? cardSource, bool silent = false)
{
	if (CombatManager.Instance.IsEnding || amount == 0m || !target.CanReceivePowers)
	{
		return;
	}
	CombatState combatState = target.CombatState;
	if (combatState == null)
	{
		return;
	}
	if (!power.IsInstanced && target.HasPower(power.Id))
	{
		PowerModel power2 = target.GetPower(power.Id);
		if (power2 == null)
		{
			throw new InvalidOperationException("Creature missing expected power.");
		}
		await ModifyAmount(power2, amount, applier, cardSource);
		return;
	}
	power.AssertMutable();
	power.Applier = applier;
	await Hook.BeforePowerAmountChanged(combatState, power, amount, target, applier, cardSource);
	decimal modifiedAmount = amount;
	IEnumerable<AbstractModel> givenModifiers = null;
	if (applier != null && combatState.ContainsCreature(applier))
	{
		modifiedAmount = Hook.ModifyPowerAmountGiven(combatState, power, applier, modifiedAmount, target, cardSource, out givenModifiers);
	}
	modifiedAmount = Hook.ModifyPowerAmountReceived(combatState, power, target, modifiedAmount, applier, out IEnumerable<AbstractModel> receivedModifiers);
	await power.BeforeApplied(target, modifiedAmount, applier, cardSource);
	if (modifiedAmount != 0m)
	{
		CombatManager.Instance.History.PowerReceived(combatState, power, modifiedAmount, applier);
	}
	power.ApplyInternal(target, modifiedAmount, silent);
	if (power.IsVisible && CombatManager.Instance.IsInProgress)
	{
		await Cmd.CustomScaledWait(0.1f, 0.25f);
	}
	if (target.Side == CombatSide.Player && power.Type == PowerType.Debuff)
	{
		power.SkipNextDurationTick = true;
	}
	if (givenModifiers != null)
	{
		await Hook.AfterModifyingPowerAmountGiven(combatState, givenModifiers, power);
	}
	await Hook.AfterModifyingPowerAmountReceived(combatState, receivedModifiers, power);
	if (modifiedAmount != 0m)
	{
		await power.AfterApplied(applier, cardSource);
		await Hook.AfterPowerAmountChanged(combatState, power, modifiedAmount, applier, cardSource);
	}
}
}
```

代码其实清晰明了，如果有同名**Power**则叠层，否则新增。中间有很多**Hook**，此处按下不表。

- 注意并不是所有**Power**都能叠加。

- ```
  public virtual bool IsInstanced => false;
  ```

- 如果`IsInstanced`为`true`则表示该**Power**不叠层。

我们看具体的`Apply`函数

```
public abstract class PowerModel:AbstractModel
{
	public void ApplyInternal(Creature owner, decimal amount, bool silent = false)
	{
        if (!(amount == 0m))
        {
            AssertMutable();
            Owner = owner;
            SetAmount((int)amount, silent);
            Owner.ApplyPowerInternal(this);
        }
	}
}
```

很好理解，设好`Owner`和`Amount`，然后通知`Owner`把自己加进去，此处`Owner`是`Creature`。

```
public class Creature
{
	public void ApplyPowerInternal(PowerModel power)
	{
        if (power.Owner != this)
        {
            throw new InvalidOperationException("ONLY CALL THIS FROM PowerModel.ApplyInternal!");
        }
        if (!power.IsInstanced && _powers.Any((PowerModel p) => p.GetType() == power.GetType()))
        {
            throw new InvalidOperationException("Trying to add multiple instances of a non-instanced power to a creature.");
        }
        _powers.Add(power);
        this.PowerApplied?.Invoke(power);
	}
}
```

同样很好理解，先进行有效性判断，`Owner`要一致；非`IsInstanced`的**Power**为叠层，不可存在多个。

把**Power**加到列表中，发送一个事件，值得一提的是，在杀戮尖塔2中，类似的事件大部分用来作为**GUI**显示逻辑，后面文章会详细论述。

## Power如何生效

这个就简单了，在上文**Hook**中提到的，每个**Power**重写需要的**时机**并进行对应的**行为**。在**Hook**中遍历`Creature`的**Power**列表即可。

这里举个简单例子：

**Dexterity**

> Dexterity improves Block gained from cards.

重写了`ModifyBlockAdditive`函数，返回对应层数的护甲。

## Power如何删除

一般地，`PowerCmd`提供了`Remove`接口

```
public static class PowerCmd
{
	public static async Task Remove(PowerModel? power)
	{
        if (power != null)
        {
            power.RemoveInternal();
            await Cmd.CustomScaledWait(0.2f, 0.4f);
            await power.AfterRemoved(power.Owner);
        }
	}
}
public abstract class PowerModel : AbstractModel
{
	public void RemoveInternal()
	{
        AssertMutable();
        this.Removed?.Invoke();
        Owner.RemovePowerInternal(this);
	}
}
public class Creature
{
	public void RemovePowerInternal(PowerModel power)
	{
        if (power.Owner != this)
        {
            throw new InvalidOperationException("ONLY CALL THIS FROM PowerModel.RemoveInternal!");
        }
        _powers.Remove(power);
        this.PowerRemoved?.Invoke(power);
	}
}
```

就是把`Power`从列表中删除，触发事件通知订阅者。

在杀戮尖塔2中，有几种自动删除类型的**Power**。

第一种，每回合**Power**层数自动-1，当**Power**层数为0时，删除。

这种实现可以在`AfterTurnEnd`时候，手动`PowerCmd.Decrement`，让层数-1，然后判断层数为0时是否要删除。

## 小结

总体来说，**Power**的实现比较简单，注意叠层逻辑即可。