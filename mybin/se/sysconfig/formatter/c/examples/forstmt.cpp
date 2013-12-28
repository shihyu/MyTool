void traverse(Node *root, std::vector<int> numbers)
{
    int ct;
    Node *n;

    for (ct = 0, n = root; n != null; ct++, n=n->next()) {
       do_something(n);
    }
    bork();
}
