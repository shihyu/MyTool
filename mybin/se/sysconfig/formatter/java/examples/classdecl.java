public class FBD extends Foo {
    public FBD(int x) {
        m_on(false);
        bar(x);
    }
    private bool loaded = false;
    private FooProxy otherFoo = null;
}
