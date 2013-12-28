public class Assoc<K,V> 
   where K:IEquatable<K> 
   where V:IEquatable<V>,new()
{
    private K key;
    private V value;
}
