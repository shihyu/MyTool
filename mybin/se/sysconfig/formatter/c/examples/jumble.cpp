void herk(const char* c, float n, Bar[] bars)
{
    int ni = (int)n;
    char *mc = const_cast<char*>(c);

    mc[5] = '\0';
    delete[] bars;
}

const char* MEMBASE = 0x8000;
class Foo;

void init()
{
    new (MEMBASE) Foo(0x1C);
}
