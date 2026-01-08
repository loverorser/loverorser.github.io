# 关于ScrollView，几种实现

https://learn.unity.com/tutorial/optimizing-unity-ui?language=en&courseId=5c87de35edbc2a091bdae346#5c7f8528edbc2a002053b5a3

## 第一种，最傻逼

有多少个就多长，然后移动`RectTransform`。多了之后（几百个Image），batch暴增，帧率20-30

## 第二种，挺有用的

有上限，上限就是有多长里能塞多少个，前后用padder填充，每次移动的时候改内容

缺点，每次移动，由于是移动整体，都会强制重绘；或者哪怕只在后面加了一个，也要全部重绘

要么就每个item一个canvas，更傻逼

## 第三种

自己实现ScrollView，移动是移动item的RectTransform而不是上面的