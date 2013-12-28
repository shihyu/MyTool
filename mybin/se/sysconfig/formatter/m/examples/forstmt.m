void traverse(id* handler, Node *root, std::vector<int> numbers)
{
    int ct;
    Node *n;

    for (ct = 0, n = root; n != null; ct++, n=n->next()) {
       [handler doSomethingWith: n];
    }
	[handler bork];
}
