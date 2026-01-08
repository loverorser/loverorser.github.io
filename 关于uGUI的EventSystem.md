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