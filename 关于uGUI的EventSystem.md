# 关于uGUI的EventSystem

先看几个概念

- `BaseRaycaster` :`UIBehaviour` 用来发射线 射线的发送是用`EventSystem::RaycastAll`
  - `GraphicRaycaster` 需要 `Canvas` 
    - 用来检测Canvas下的元素在不在，核心是
    - RectTransformUtility::RectangleContainsScreenPoint(RectTransform rect, Vector2 screenPoint, Camera cam)
    - 如果勾了`BlockingObjects` `TwoD`或者`ThreeD`，那么还会在此之前发物理射线判断距离
  - `PhysicsRaycast` 需要 `Camera`
  - `Physics2DRaycast` 需要 `Camera`
- `BaseInput`:`UIBehaviour`
  - 这个东西主要是给`BaseInputModule`用，作

- `EventSystem`:`UIBehaviour` 发射射线是用`BaseInputModule::GetMousePointerEventData`->`eventSystem::RaycastAll`
  - 在Update中让`BaseInputModule`进行`Tick`

- `BaseInputModule`:`UIBehaviour` 需要 `EventSystem` 是在`Process`中让`EventSystem`发射射线



在Update中，检测鼠标是否按下，如果按下，就进行射线检测。

找到所有之前注册进来的`BaseRayCaster`，把鼠标相关信息传过去，让他们进行射线检测，把结果添加到集合中。

集合进行排序，目的是找到最前方的射线结果。排序方法包括检查射线摄像机的`depth`，`BaseRayCaster`的`sortOrderPriority`和`renderOrderPriority`，检查射线结果的`SortingOrder`和`OrderInLayer`，`depth`和`distance`等。

把射线结果传过去，`Execute`的时候冒泡触发，往上找到第一个能触发的就触发并且结束。