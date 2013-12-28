
void populate(std::string& s, size_t sz);
void init();


int boid(std::string& s, float& fw)
{
    size_t sz = s.size();

    init();
    s.resize(256, '@');
    populate(s,sz);
   
    return operator+(sz, 12); 
}

template<class K, class V>
map<K,V> make_map();

void munge()
{
    map<int, float> tvals = make_map<int,float>();

    map_munge(tvals);
}
