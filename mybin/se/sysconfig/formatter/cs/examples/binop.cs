public float Dot(Vector v1, Vector v2)
{
    return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z;
}

public boolean Test(Vector a, Vector b, short flags)
{
    float d = Dot(a,b);

    if (d > k::neg_epsilon && d < k::epsilon) {
        flags = flags | FLG_PRK;
        return true;
    }

    if (flags & FLG_CMPLT) {
        internalFlags &= ~FLG_PRK;
    }
    return false;
}
