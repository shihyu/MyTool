void herk(const char* c, float n, Bar[] bars, id* obj)
{
    int ni = (int)n;
    char *mc = const_cast<char*>(c);

    [obj munge: mc[5]];
    delete[] bars;
}

const char* MEMBASE = 0x8000;
class Foo;

void init()
{
    new (MEMBASE) Foo(0x1C);
}
