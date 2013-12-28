public class Foo : Bar
{
    public Foo(int cap, bool resize = false):base(cap){
        if (resize) 
            m_something = cap;
        else 
            m_something = 12;
    }

    public void Frob(int n=0) {
       _intern_frob(n, CHK); 
    }
}

