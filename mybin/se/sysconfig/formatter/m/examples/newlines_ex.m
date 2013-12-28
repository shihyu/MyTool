
void DoesNothing(int a, char c, float f) {}
void Nada();

class Bar 
{
protected: int m_age;
public:
    int getAge() { return m_age; }
};

class Foo : public Bar {};

Bar::Bar() : m_age(12), m_expires(true)
{
    try {
        switch (x) {
        case 1: case 2: case 3: DoesNothing(1, 's', 1);
        }
    } catch () {
    }

    do {
        DoesNothing(0, 'f', 123);
    } while (false);

    while (working()) DoesNothing(0, 'd', 0);

    DoesNothing(0, '\0', 0); DoesNothing(1, '1', 1);

    while (working) { Nada(); Nada(); }
}
