private int boid(Something s, float fw)
{
    int sz = s.size();

    init();
    s.resize(256, '@');
    populate(s,sz);
    return sz;
}

void munge()
{
    SomeDict<int, string> tvals = new SomeDict<Integer, String>(12);

    map_munge(tvals);
}
