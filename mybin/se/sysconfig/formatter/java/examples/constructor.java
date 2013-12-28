public class Foo extends Bar
{
    public Foo() {
        m_something = 12;
    }

    public Foo(int cap, bool resize = false) {
        if (resize) 
            m_something = cap;
        else 
            m_something = 12;
    }
}

