
class Foo : public Bar
{
public:
    Foo();
    Foo(int cap, bool resize = false);
    virtual char* baz() = 0;
};

Foo::Foo()
{
}

Foo::Foo(int cap, bool resize) : m_cap(cap), m_resize(resize)
{
}
