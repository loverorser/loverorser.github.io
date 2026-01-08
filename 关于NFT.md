# 关于NFT

## 船只物品的操作

- 船只物品使用
- 船只物品上架
- 船只物品分享
  - 先看看船只怎么分享的
  - 应该走物品分享，现在有问题，点发送就断线

## 船只系统的详细操作

- 船只分解
  - 分解界面绑定标识 NFT标识

## 先看有哪些Tips

- `SlotEquipPropertyPZ`装备
- `ItemProperty` 物品道具
- `Common_BoxTips` 礼包
- `ShipDetailsTips` 船只
- `Navigator_Tips`航海士

## 拆

- 物品图标NTF显示

- 背包界面 原**装备**分页改成**NFT**分页



`TipsModule.lua` 633行

背包的物品类型 `ItemUtil` 100行

ItemProperty 如果有NFT两行 高度 +<del>55</del> 75



Bag->BagCell->Sprite_bg->加一个Spr_NFTBg

Bag->offset->CharacterEquip->EquipCell0-5->Sprite_bg->加一个Spr_NFTBg

Depot->Cell_Group->Cell_01 BankCell->Sprite_bg->加一个Spr_NFTBg



# 比如航海士Tips

```lua
function NavigatorTipsUI:OnEvent(p_event, p_param)
    if(p_event == LuaEvent.ShowNavigatorTipsUI) then
        self:Show(p_param)
    end
end
```

p_param加一个IsBagItem

如果是，就是说明是背包的**航海士道具**，虽然也走这个Tips，但是可以用背包来看是不是NFT，然后弹出那些操作啥的

如果不是，走数据，直接拿NFTMetaData

船只同理



- 航海士Tips，等改C#代码
- 船装图标加NFT，要加蛮多
- 航海士物品、船只物品，等后端，先做一点