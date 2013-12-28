class Foo
{
public:
    int DoSomething(const char* s, int l);
}

typedef int (Foo::*ExecFn)(const char* str, int lev);

void boid(Foo& f, const char* s)
{
    Foo* fp = &f;

    f.DoSomething(s, 1);
    fp->DoSomething(s, 2);

    ExecFn efn = &Foo::DoSomething;

    f.*efn(str, 3);
    fp->*efn(str, 4);
}

