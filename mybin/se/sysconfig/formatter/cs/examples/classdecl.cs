public class FBD:Foo,IDisposable {
    public FBD(int x) {
        m_on(false);
        bar(x);
    }
    private bool loaded = false;
    private IDisposable other_ref = null;
}
