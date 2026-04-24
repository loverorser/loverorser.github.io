# 深入理解AssetBundle

> 引言：Unity的资源加载挺有意思的，没了。



class AssetBundle{

Head head

byte[] cachedBytes;

LoadFromMemory(byte[] bytes){

cachedBytes=bytes.Clone();

}

public T LoadAsset<T>(string name){

读取head

找到偏移

加载cachedBytes size个

转为T

}

}

