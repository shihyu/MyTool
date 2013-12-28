class FBD : public Foo, private Bar
{
public:
    FBD(int x) : Foo(), Bar(x), m_on(false) 
    {
    }
    bool loaded;
    FooBarProxy fb_proxy;
};

struct Both : public Foo, public Bar
{
    Both();
    const char* id;
};

union Any
{
    int i;
    char c;
    float f;
};
