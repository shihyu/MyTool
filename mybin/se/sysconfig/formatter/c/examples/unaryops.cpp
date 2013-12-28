int* whut(int x, int* y)
{
    static int acc = 0;
    int rv = -x;

    acc = *y++;
    --acc;
    return &acc;
}

typedef void (*ActionFn)(int);
void call(ActionFn fn, int x)
{
    (*fn)(x);
}
