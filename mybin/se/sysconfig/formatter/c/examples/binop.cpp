float Dot(vector& v1, vector& v2)
{
    return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z;
}

bool Test(vector& a, vector& b, short& flags)
{
    float d = Dot(a,b);

    if (d > k::neg_epsilon && d < k::epsilon) {
        flags = flags | FLG_PRK;
        return true;
    }

    if (flags & FLG_CMPLT) {
        flags &= ~FLG_PRK;
    }
    return false;
}
