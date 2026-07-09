# uGUI源码分析（一）：鼠标点击

> 前言：我想实现一个功能，给你一张图，鼠标点击这张图后，输出Hello World!，怎么实现？

## 如果我们自己来实现

如果要我们实现，怎么实现呢？



首先我们需要在Update中每帧获取鼠标的状态，缓存起来，大概逻辑是

```
void Update(){
    m_MouseData = UnityInternal.CaptureMouseData();
}
```

鼠标的状态包括，每帧，鼠标的位置，鼠标按下还是抬起，没了。



其次，我们需要在uGUI里Update中每帧判断鼠标的状态和鼠标当前**碰到**了哪个物体。

如果上一帧鼠标状态为抬起，并且这一帧鼠标状态为按下，那么表示鼠标点击了。

每帧从鼠标当前位置发射射线，根据对应的规则，找到碰撞的所有物体。

然后按照一定规则，把碰撞的所有物体排序，只取第一个。



最后，我们按照冒泡原则触发该物体的点击/悬浮/按下/抬起事件。

所谓冒泡原则就是，从该物体开始，查询是否有可触发事件的Handler，一直往parent查找。



我们给这张图片的点击事件添加Handler，然后添加回调，回调中输出HelloWorld。



好接下来我们看看uGUI怎么做的。

## 获取鼠标的状态

有一个继承自`UIBehaviour`的类`BaseInput`，里面定义了若干个鼠标的状态，例如`mousePosition`，`GetMouseButton`等。其内部的实现是基于`Unity`的`Input`类，没什么好说的。

> 值得一提的是，Unity推荐使用`Input System Package`来代替`Input Manager`

## 每帧判断之Input Module

有一个继承自`UIBehaviour`的抽象类`BaseInputModule`，有一个`Process`方法，uGUI正是在该方法里进行每帧判断的。

```
/// <summary>
/// Process the current tick for the module.
/// </summary>
public abstract void Process();
```

`BaseInputModule`有一个`BaseInput`字段，这个`BaseInput`会自动地随`BaseInputModule`创建。

```
/// <summary>
/// The current BaseInput being used by the input module.
/// </summary>
public BaseInput input
{
    get
    {
        if (m_InputOverride != null)
            return m_InputOverride;

        if (m_DefaultInput == null)
        {
            var inputs = GetComponents<BaseInput>();
            foreach (var baseInput in inputs)
            {
                // We dont want to use any classes that derrive from BaseInput for default.
                if (baseInput != null && baseInput.GetType() == typeof(BaseInput))
                {
                    m_DefaultInput = baseInput;
                    break;
                }
            }

            if (m_DefaultInput == null)
                m_DefaultInput = gameObject.AddComponent<BaseInput>();
        }

        return m_DefaultInput;
    }
}
```

有哪些类继承了`BaseInputModule`呢？有`PointerInputModule`继承了；然后`StandloneInputModule`和`TouchInputModule`又都分别继承了`PointerInputModule`，顾名思义，后者是给屏幕触摸用的。

> 如果输入系统为`Input System Package`，那么会有一个类`InputSystemUIInputModule`继承自`BaseInputModule`，并且该类中完全抛弃了`BaseInput`字段，转而用`Input System Package`的接口来获取鼠标状态。

## 获取鼠标状态

在`StandaloneInputModule`中重写了`Process`方法，里面调用了`ProcessMouseEvent`方法，这个方法会调用一个方法：

`GetMousePointerEventData`，返回一个类`MouseState`，这个类包含了鼠标的移动和点击状态，以及从鼠标位置发射射线碰撞的**第一个**`RaycastResult`信息。很重要。

```
protected virtual MouseState GetMousePointerEventData(int id)
{
    // Populate the left button...
    PointerEventData leftData;
    var created = GetPointerData(kMouseLeftId, out leftData, true);

    leftData.Reset();

    if (created)
        leftData.position = input.mousePosition;

    Vector2 pos = input.mousePosition;
    if (Cursor.lockState == CursorLockMode.Locked)
    {
        // We don't want to do ANY cursor-based interaction when the mouse is locked
        leftData.position = new Vector2(-1.0f, -1.0f);
        leftData.delta = Vector2.zero;
    }
    else
    {
        leftData.delta = pos - leftData.position;
        leftData.position = pos;
    }
    leftData.scrollDelta = input.mouseScrollDelta;
    leftData.button = PointerEventData.InputButton.Left;
    eventSystem.RaycastAll(leftData, m_RaycastResultCache);
    var raycast = FindFirstRaycast(m_RaycastResultCache);
    leftData.pointerCurrentRaycast = raycast;
    m_RaycastResultCache.Clear();

    // copy the apropriate data into right and middle slots
    PointerEventData rightData;
    GetPointerData(kMouseRightId, out rightData, true);
    CopyFromTo(leftData, rightData);
    rightData.button = PointerEventData.InputButton.Right;

    PointerEventData middleData;
    GetPointerData(kMouseMiddleId, out middleData, true);
    CopyFromTo(leftData, middleData);
    middleData.button = PointerEventData.InputButton.Middle;

    m_MouseState.SetButtonState(PointerEventData.InputButton.Left, StateForMouseButton(0), leftData);
    m_MouseState.SetButtonState(PointerEventData.InputButton.Right, StateForMouseButton(1), rightData);
    m_MouseState.SetButtonState(PointerEventData.InputButton.Middle, StateForMouseButton(2), middleData);

    return m_MouseState;
}
```

通过`input`填充鼠标状态，传给`Raycast`进行射线检测；将排序后的结果只取第一个。把数据复制为三分：左键、右键和中键。

然后设置鼠标点击状态

```
/// <summary>
/// Given a mouse button return the current state for the frame.
/// </summary>
/// <param name="buttonId">Mouse button ID</param>
protected PointerEventData.FramePressState StateForMouseButton(int buttonId)
{
    var pressed = input.GetMouseButtonDown(buttonId);
    var released = input.GetMouseButtonUp(buttonId);
    if (pressed && released)
        return PointerEventData.FramePressState.PressedAndReleased;
    if (pressed)
        return PointerEventData.FramePressState.Pressed;
    if (released)
        return PointerEventData.FramePressState.Released;
    return PointerEventData.FramePressState.NotChanged;
}
```



## 射线检测

```
public void RaycastAll(PointerEventData eventData, List<RaycastResult> raycastResults)
{
    raycastResults.Clear();
    var modules = RaycasterManager.GetRaycasters();
    for (int i = 0; i < modules.Count; ++i)
    {
        var module = modules[i];
        if (module == null || !module.IsActive())
            continue;

        module.Raycast(eventData, raycastResults);
    }

    raycastResults.Sort(s_RaycastComparer);
}
```

没什么好说的

### 射线如何检测

有一个继承自`UIBehaviour`的抽象类`BaseRaycaster`，提供了也给抽象方法。

```
public abstract void Raycast(PointerEventData eventData, List<RaycastResult> resultAppendList);
```

其中`PointerEventData`就是上文提到的鼠标的状态，给定鼠标的状态信息，进行射线检测，把检测到的所有`Result`都添加到列表中。

具体实现包括`Physics(2D)Raycaster`和`GraphicRaycaster`，这里我们注重分析`GraphicRaycaster`。

### GraphicRaycaster的Raycast(PointEventData)方法

```
/// <summary>
/// Perform the raycast against the list of graphics associated with the Canvas.
/// </summary>
/// <param name="eventData">Current event data</param>
/// <param name="resultAppendList">List of hit objects to append new results to.</param>
public override void Raycast(PointerEventData eventData, List<RaycastResult> resultAppendList)
{
    if (canvas == null)
        return;

    var canvasGraphics = GraphicRegistry.GetGraphicsForCanvas(canvas);
    if (canvasGraphics == null || canvasGraphics.Count == 0)
        return;

    int displayIndex;
    var currentEventCamera = eventCamera; // Propery can call Camera.main, so cache the reference

    if (canvas.renderMode == RenderMode.ScreenSpaceOverlay || currentEventCamera == null)
        displayIndex = canvas.targetDisplay;
    else
        displayIndex = currentEventCamera.targetDisplay;

    var eventPosition = Display.RelativeMouseAt(eventData.position);
    if (eventPosition != Vector3.zero)
    {
        // We support multiple display and display identification based on event position.

        int eventDisplayIndex = (int)eventPosition.z;

        // Discard events that are not part of this display so the user does not interact with multiple displays at once.
        if (eventDisplayIndex != displayIndex)
            return;
    }
    else
    {
        // The multiple display system is not supported on all platforms, when it is not supported the returned position
        // will be all zeros so when the returned index is 0 we will default to the event data to be safe.
        eventPosition = eventData.position;

        // We dont really know in which display the event occured. We will process the event assuming it occured in our display.
    }

    // Convert to view space
    Vector2 pos;
    if (currentEventCamera == null)
    {
        // Multiple display support only when not the main display. For display 0 the reported
        // resolution is always the desktops resolution since its part of the display API,
        // so we use the standard none multiple display method. (case 741751)
        float w = Screen.width;
        float h = Screen.height;
        if (displayIndex > 0 && displayIndex < Display.displays.Length)
        {
            w = Display.displays[displayIndex].systemWidth;
            h = Display.displays[displayIndex].systemHeight;
        }
        pos = new Vector2(eventPosition.x / w, eventPosition.y / h);
    }
    else
        pos = currentEventCamera.ScreenToViewportPoint(eventPosition);

    // If it's outside the camera's viewport, do nothing
    if (pos.x < 0f || pos.x > 1f || pos.y < 0f || pos.y > 1f)
        return;

    float hitDistance = float.MaxValue;

    Ray ray = new Ray();

    if (currentEventCamera != null)
        ray = currentEventCamera.ScreenPointToRay(eventPosition);

    if (canvas.renderMode != RenderMode.ScreenSpaceOverlay && blockingObjects != BlockingObjects.None)
    {
        float distanceToClipPlane = 100.0f;

        if (currentEventCamera != null)
        {
            float projectionDirection = ray.direction.z;
            distanceToClipPlane = Mathf.Approximately(0.0f, projectionDirection)
                ? Mathf.Infinity
                : Mathf.Abs((currentEventCamera.farClipPlane - currentEventCamera.nearClipPlane) / projectionDirection);
        }

        if (blockingObjects == BlockingObjects.ThreeD || blockingObjects == BlockingObjects.All)
        {
            if (ReflectionMethodsCache.Singleton.raycast3D != null)
            {
                var hits = ReflectionMethodsCache.Singleton.raycast3DAll(ray, distanceToClipPlane, (int)m_BlockingMask);
                if (hits.Length > 0)
                    hitDistance = hits[0].distance;
            }
        }

        if (blockingObjects == BlockingObjects.TwoD || blockingObjects == BlockingObjects.All)
        {
            if (ReflectionMethodsCache.Singleton.raycast2D != null)
            {
                var hits = ReflectionMethodsCache.Singleton.getRayIntersectionAll(ray, distanceToClipPlane, (int)m_BlockingMask);
                if (hits.Length > 0)
                    hitDistance = hits[0].distance;
            }
        }
    }

    m_RaycastResults.Clear();
    Raycast(canvas, currentEventCamera, eventPosition, canvasGraphics, m_RaycastResults);

    int totalCount = m_RaycastResults.Count;
    for (var index = 0; index < totalCount; index++)
    {
        var go = m_RaycastResults[index].gameObject;
        bool appendGraphic = true;

        if (ignoreReversedGraphics)
        {
            if (currentEventCamera == null)
            {
                // If we dont have a camera we know that we should always be facing forward
                var dir = go.transform.rotation * Vector3.forward;
                appendGraphic = Vector3.Dot(Vector3.forward, dir) > 0;
            }
            else
            {
                // If we have a camera compare the direction against the cameras forward.
                var cameraFoward = currentEventCamera.transform.rotation * Vector3.forward;
                var dir = go.transform.rotation * Vector3.forward;
                appendGraphic = Vector3.Dot(cameraFoward, dir) > 0;
            }
        }

        if (appendGraphic)
        {
            float distance = 0;

            if (currentEventCamera == null || canvas.renderMode == RenderMode.ScreenSpaceOverlay)
                distance = 0;
            else
            {
                Transform trans = go.transform;
                Vector3 transForward = trans.forward;
                // http://geomalgorithms.com/a06-_intersect-2.html
                distance = (Vector3.Dot(transForward, trans.position - ray.origin) / Vector3.Dot(transForward, ray.direction));

                // Check to see if the go is behind the camera.
                if (distance < 0)
                    continue;
            }

            if (distance >= hitDistance)
                continue;

            var castResult = new RaycastResult
            {
                gameObject = go,
                module = this,
                distance = distance,
                screenPosition = eventPosition,
                index = resultAppendList.Count,
                depth = m_RaycastResults[index].depth,
                sortingLayer = canvas.sortingLayerID,
                sortingOrder = canvas.sortingOrder
            };
            resultAppendList.Add(castResult);
        }
    }
}
```

前置一些条件判断，

1.如果该Canvas下没有可供检测的`Graphic`，那么不执行；

2.如果当前鼠标点击所在的屏幕和当前`Canvas`所在的屏幕不一致，那么不执行；

3.如果超出了摄像机的`viewport`，那么不执行；

4.如果有遮挡需求，那么找到命中的第一个物体的距离；

5.进行射线检测

6.如果忽略反向`Graphic`，那么会剔除反向的`Graphic`
7.剔除距离<0或者>`hitDistance`的结果

8.将结果保存

### GraphicRaycaster的进一步Raycast方法

```
private static void Raycast(Canvas canvas, Camera eventCamera, Vector2 pointerPosition, IList<Graphic> foundGraphics, List<Graphic> results)
{
    // Debug.Log("ttt" + pointerPoision + ":::" + camera);
    // Necessary for the event system
    int totalCount = foundGraphics.Count;
    for (int i = 0; i < totalCount; ++i)
    {
        Graphic graphic = foundGraphics[i];

        // -1 means it hasn't been processed by the canvas, which means it isn't actually drawn
        if (graphic.depth == -1 || !graphic.raycastTarget || graphic.canvasRenderer.cull)
            continue;

        if (!RectTransformUtility.RectangleContainsScreenPoint(graphic.rectTransform, pointerPosition, eventCamera))
            continue;

        if (eventCamera != null && eventCamera.WorldToScreenPoint(graphic.rectTransform.position).z > eventCamera.farClipPlane)
            continue;

        if (graphic.Raycast(pointerPosition, eventCamera))
        {
            s_SortedGraphics.Add(graphic);
        }
    }

    s_SortedGraphics.Sort((g1, g2) => g2.depth.CompareTo(g1.depth));
    //      StringBuilder cast = new StringBuilder();
    totalCount = s_SortedGraphics.Count;
    for (int i = 0; i < totalCount; ++i)
        results.Add(s_SortedGraphics[i]);
    //      Debug.Log (cast.ToString());

    s_SortedGraphics.Clear();
}
```

遍历所有的`Graphic`



1.如果`depth`为-1，或者`raycastTarget`为`false`，或者其下的`canvasRenderer`被`cull`了，那么不执行；

2.如果点击的位置在`RectTransform`外面，那么不执行；

3.如果`graphic`的`z`位置超出了摄像机的`farClipPlane`，那么不执行*（仅针对于`eventCamera`不为`null`的情况）*；

4.执行`Graphic`的`Raycast`方法；

5.根据`depth`排序；

### 然后进一步执行`Graphic`的`Raycast`方法：

```
public virtual bool Raycast(Vector2 sp, Camera eventCamera)
{
    if (!isActiveAndEnabled)
        return false;

    var t = transform;
    var components = ListPool<Component>.Get();

    bool ignoreParentGroups = false;
    bool continueTraversal = true;

    while (t != null)
    {
        t.GetComponents(components);
        for (var i = 0; i < components.Count; i++)
        {
            var canvas = components[i] as Canvas;
            if (canvas != null && canvas.overrideSorting)
                continueTraversal = false;

            var filter = components[i] as ICanvasRaycastFilter;

            if (filter == null)
                continue;

            var raycastValid = true;

            var group = components[i] as CanvasGroup;
            if (group != null)
            {
                if (ignoreParentGroups == false && group.ignoreParentGroups)
                {
                    ignoreParentGroups = true;
                    raycastValid = filter.IsRaycastLocationValid(sp, eventCamera);
                }
                else if (!ignoreParentGroups)
                    raycastValid = filter.IsRaycastLocationValid(sp, eventCamera);
            }
            else
            {
                raycastValid = filter.IsRaycastLocationValid(sp, eventCamera);
            }

            if (!raycastValid)
            {
                ListPool<Component>.Release(components);
                return false;
            }
        }
        t = continueTraversal ? t.parent : null;
    }
    ListPool<Component>.Release(components);
    return true;
}
```

其实`Graphic`的`Raycast`主要是为了判断是否有组件导致不可点击。注意到中间有`ICanvasRaycastFilter.IsRaycastLocationValid`，这个主要是给遮罩和透明材质用的。

### ICanvasRaycastFilter.IsRaycastLocationValid的实现

其中`Mask`和`RectMask2D`的实现都为

```
public virtual bool IsRaycastLocationValid(Vector2 sp, Camera eventCamera)
{
    if (!isActiveAndEnabled)
        return true;

    return RectTransformUtility.RectangleContainsScreenPoint(rectTransform, sp, eventCamera);
}
```

其中`Image`的实现为

```
public virtual bool IsRaycastLocationValid(Vector2 screenPoint, Camera eventCamera)
{
    if (alphaHitTestMinimumThreshold <= 0)
        return true;

    if (alphaHitTestMinimumThreshold > 1)
        return false;

    if (activeSprite == null)
        return true;

    Vector2 local;
    if (!RectTransformUtility.ScreenPointToLocalPointInRectangle(rectTransform, screenPoint, eventCamera, out local))
        return false;

    Rect rect = GetPixelAdjustedRect();

    // Convert to have lower left corner as reference point.
    local.x += rectTransform.pivot.x * rect.width;
    local.y += rectTransform.pivot.y * rect.height;

    local = MapCoordinate(local, rect);

    // Normalize local coordinates.
    Rect spriteRect = activeSprite.textureRect;
    Vector2 normalized = new Vector2(local.x / spriteRect.width, local.y / spriteRect.height);

    // Convert to texture space.
    float x = Mathf.Lerp(spriteRect.x, spriteRect.xMax, normalized.x) / activeSprite.texture.width;
    float y = Mathf.Lerp(spriteRect.y, spriteRect.yMax, normalized.y) / activeSprite.texture.height;

    try
    {
        return activeSprite.texture.GetPixelBilinear(x, y).a >= alphaHitTestMinimumThreshold;
    }
    catch (UnityException e)
    {
        Debug.LogError("Using alphaHitTestMinimumThreshold greater than 0 on Image whose sprite texture cannot be read. " + e.Message + " Also make sure to disable sprite packing for this sprite.", this);
        return true;
    }
}
```

主要是判断图片某个像素点的透明度`a`和`alphaHitTestMinimumThreshold`的大小。

### `RaycastResult`排序

```
private static int RaycastComparer(RaycastResult lhs, RaycastResult rhs)
{
    if (lhs.module != rhs.module)
    {
        var lhsEventCamera = lhs.module.eventCamera;
        var rhsEventCamera = rhs.module.eventCamera;
        if (lhsEventCamera != null && rhsEventCamera != null && lhsEventCamera.depth != rhsEventCamera.depth)
        {
            // need to reverse the standard compareTo
            if (lhsEventCamera.depth < rhsEventCamera.depth)
                return 1;
            if (lhsEventCamera.depth == rhsEventCamera.depth)
                return 0;

            return -1;
        }

        if (lhs.module.sortOrderPriority != rhs.module.sortOrderPriority)
            return rhs.module.sortOrderPriority.CompareTo(lhs.module.sortOrderPriority);

        if (lhs.module.renderOrderPriority != rhs.module.renderOrderPriority)
            return rhs.module.renderOrderPriority.CompareTo(lhs.module.renderOrderPriority);
    }

    if (lhs.sortingLayer != rhs.sortingLayer)
    {
        // Uses the layer value to properly compare the relative order of the layers.
        var rid = SortingLayer.GetLayerValueFromID(rhs.sortingLayer);
        var lid = SortingLayer.GetLayerValueFromID(lhs.sortingLayer);
        return rid.CompareTo(lid);
    }


    if (lhs.sortingOrder != rhs.sortingOrder)
        return rhs.sortingOrder.CompareTo(lhs.sortingOrder);

    if (lhs.depth != rhs.depth)
        return rhs.depth.CompareTo(lhs.depth);

    if (lhs.distance != rhs.distance)
        return lhs.distance.CompareTo(rhs.distance);

    return lhs.index.CompareTo(rhs.index);
}
```

没什么好说的，通过各种排序来找到**第一个**射线碰撞的结果。

## 处理鼠标事件

在`StandaloneInputModule`中有一个`ProcessMouseEvent`方法，用来每帧处理鼠标事件

```
protected void ProcessMouseEvent(int id)
{
    var mouseData = GetMousePointerEventData(id);
    var leftButtonData = mouseData.GetButtonState(PointerEventData.InputButton.Left).eventData;

    m_CurrentFocusedGameObject = leftButtonData.buttonData.pointerCurrentRaycast.gameObject;

    // Process the first mouse button fully
    ProcessMousePress(leftButtonData);
    ProcessMove(leftButtonData.buttonData);
    ProcessDrag(leftButtonData.buttonData);

    // Now process right / middle clicks
    ProcessMousePress(mouseData.GetButtonState(PointerEventData.InputButton.Right).eventData);
    ProcessDrag(mouseData.GetButtonState(PointerEventData.InputButton.Right).eventData.buttonData);
    ProcessMousePress(mouseData.GetButtonState(PointerEventData.InputButton.Middle).eventData);
    ProcessDrag(mouseData.GetButtonState(PointerEventData.InputButton.Middle).eventData.buttonData);

    if (!Mathf.Approximately(leftButtonData.buttonData.scrollDelta.sqrMagnitude, 0.0f))
    {
        var scrollHandler = ExecuteEvents.GetEventHandler<IScrollHandler>(leftButtonData.buttonData.pointerCurrentRaycast.gameObject);
        ExecuteEvents.ExecuteHierarchy(scrollHandler, leftButtonData.buttonData, ExecuteEvents.scrollHandler);
    }
}
```

首先是通过`GetMousePointerEventData`获取必要数据，然后分别处理诸如鼠标点击、移动和拖拽。

### 处理鼠标点击

