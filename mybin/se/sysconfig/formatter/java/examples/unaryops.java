public int whut(int x, int y)
{
    int acc = 0;
    int rv = -x;

    if (!condition(x,y)) {
       acc = y++;
    }
    --acc;
    return acc;
}

