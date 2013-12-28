import gdb
import itertools
import re

# Try to use the new-style pretty-printing if available.
_use_gdb_pp = True
try:
    import gdb.printing
except ImportError:
    _use_gdb_pp = False

################################################################################
# slickedit::SEString pretty printer
#
class SEStringPrinter:
    "Print a slickedit::SEString"
    def __init__ (self, val):
        self.val = val
    def to_string (self):
        if self.val['mUseInternalBuffer'] == 1:
            ptr = self.val['mInternalBuffer']
            len = self.val['mInternalLength']
            return ptr.string (length = len)
        if self.val['mpExternalBuffer'] != 0:
            ptr = self.val['mpExternalBuffer']
            len = self.val['mExternalLength']
            return ptr.string (length = len)
        if self.val['mpStringBuffer'] != 0:
           ptr = self.val['mpStringBuffer']['mTextBuffer']
           len = self.val['mpStringBuffer']['mTextLength']
           return ptr.string (length = len)
        length = 0;
        return NULL
    def display_hint (self):
        return 'string'

def sestring_lookup_function (val):
    lookup_tag = val.type.tag
    regex = re.compile ("^slickedit::SEString$")
    if lookup_tag == None:
        return None
    if regex.match (lookup_tag):
        return SEStringPrinter (val)
    return None

################################################################################
# slickedit::SEArray pretty printer
#
class SEArrayPrinter:
    "Print a slickedit::SEArray"

    class _iterator:
        def __init__ (self, start, numItems):
            self.item = start
            self.numItems = numItems
            self.count = 0
    
        def __iter__(self):
            return self
    
        def next(self):
            i = self.count
            self.count = self.count + 1
            if self.count > self.numItems:
                raise StopIteration
            if self.count >= 1000:
                raise StopIteration
            elt = self.item.dereference ()
            self.item = self.item + 1
            return ('[%d]' % i, elt)
    
    def __init__(self, typename, val):
        self.typename = typename
        self.val = val
    
    def children(self):
        itemtype = self.val.type.template_argument (0)
        firstItem = self.val['mArrayBuf']['mList'].address
        firstItem = firstItem.cast(itemtype.pointer ())
        numItems = self.val['mArrayBuf']['mNumItems']
        return self._iterator(firstItem, numItems)                     

    def to_string(self):
        if self.val['mArrayBuf'] == 0:
            return 'empty %s' % (self.typename)
        self.numItems = self.val['mArrayBuf']['mNumItems']
        return ('%s of length %d' % (self.typename, self.numItems))

    def display_hint(self):
        return 'array'

def searray_lookup_function (val):
    lookup_tag = val.type.tag
    regex = re.compile ("^slickedit::SEArray<.*>$")
    if lookup_tag == None:
        return None
    if regex.match (lookup_tag):
        return SEArrayPrinter (lookup_tag, val)
    return None

################################################################################
# slickedit::SEHashTable pretty printer
#
class SEHashTablePrinter:
    "Print a slickedit::SEHashTable"

    class _iterator:
        def __init__ (self, start, numItems, maxItems):
            self.item = start
            self.numItems = numItems
            self.maxItems = maxItems
            self.slotCount = 0
            self.itemCount = 0
            self.nextItem = 0
            self.pValue = 0;

        def __iter__(self):
            return self

        def next(self):
            # make sure we haven't printed everything already
            i = self.itemCount
            self.itemCount = self.itemCount + 1
            if self.itemCount > self.numItems*2:
                raise StopIteration
            if self.itemCount >= 1000:
                raise StopIteration
            # have to print out value pair
            if self.pValue != 0:
                elt = self.pValue.dereference()
                self.pValue = 0;
                return ('[%d]' % i, elt)
            # check for chained items
            if self.nextItem != 0:
                elt = self.nextItem.dereference();
                self.pValue  = elt['val'].address
                self.nextItem = elt['pnext']
                return ('[%d]' % i, elt['key'])
            # make sure we don't run past array bounds
            if self.slotCount >= self.maxItems:
                raise StopIteration
            if self.slotCount >= 1000:
                raise StopIteration
            # get the next element
            elt = self.item.dereference ()
            while elt == 0:
                self.slotCount = self.slotCount + 1
                if self.slotCount >= self.maxItems:
                    raise StopIteration
                if self.slotCount >= 1000:
                    raise StopIteration
                self.item = self.item + 1
                elt = self.item.dereference ()
            # set up for logging value and item
            self.item = self.item + 1
            self.slotCount = self.slotCount + 1
            self.pValue = elt['val'].address
            self.nextItem = elt['pnext']
            return ('[%d]' % i, elt['key'])

    def __init__(self, typename, val):
        self.typename = typename
        self.val = val

    def children(self):
        firstItem = self.val['_kvlist']
        numItems = self.val['_NofItems']
        maxItems = self.val['_NofAllocated']
        return self._iterator(firstItem, numItems, maxItems)                     

    def to_string(self):
        if self.val['_kvlist'] == 0:
            return 'empty %s' % (self.typename)
        self.numItems = self.val['_NofItems']
        self.maxItems = self.val['_NofAllocated']
        return ('%s of length %d, capacity %d' % (self.typename, self.numItems, self.maxItems))

    def display_hint(self):
        return 'array'

def sehashtable_lookup_function (val):
    lookup_tag = val.type.tag
    regex = re.compile ("^slickedit::SEHashTable<.*>$")
    if lookup_tag == None:
        return None
    if regex.match (lookup_tag):
        return SEHashTablePrinter (lookup_tag, val)
    return None

################################################################################
# slickedit::SEHashSet pretty printer
#
class SEHashSetPrinter:
    "Print a slickedit::SEHashSet"

    class _iterator:
        def __init__ (self, start, numItems, maxItems):
            self.item = start
            self.numItems = numItems
            self.maxItems = maxItems
            self.slotCount = 0
            self.itemCount = 0
            self.nextItem = 0

        def __iter__(self):
            return self

        def next(self):
            if self.itemCount > self.numItems:
                raise StopIteration
            if self.itemCount >= 1000:
                raise StopIteration
            if self.slotCount >= self.maxItems:
                raise StopIteration
            if self.slotCount >= 1000:
                raise StopIteration
            if self.nextItem != 0:
                elt = self.nextItem.dereference();
                self.nextItem = elt['pnext']
                self.itemCount = self.itemCount + 1
                return ('[%d]' % self.itemCount, elt['val'])
            elt = self.item.dereference ()
            while elt == 0:
                self.item = self.item + 1
                self.slotCount = self.slotCount + 1
                if self.itemCount > self.numItems:
                    raise StopIteration
                if self.itemCount >= 1000:
                    raise StopIteration
                if self.slotCount >= self.maxItems:
                    raise StopIteration
                if self.slotCount >= 1000:
                    raise StopIteration
                elt = self.item.dereference ()
            self.item = self.item + 1
            self.slotCount = self.slotCount + 1
            self.nextItem = elt['pnext']
            return ('[%d]' % self.itemCount, elt['val'])

    def __init__(self, typename, val):
        self.typename = typename
        self.val = val

    def children(self):
        firstItem = self.val['_kvlist']
        numItems = self.val['_NofItems']
        maxItems = self.val['_NofAllocated']
        return self._iterator(firstItem, numItems, maxItems)                     

    def to_string(self):
        if self.val['_kvlist'] == 0:
            return 'empty %s' % (self.typename)
        self.numItems = self.val['_NofItems']
        self.maxItems = self.val['_NofAllocated']
        return ('%s of length %d, capacity %d' % (self.typename, self.numItems, self.maxItems))

    def display_hint(self):
        return 'array'

def sehashset_lookup_function (val):
    lookup_tag = val.type.tag
    regex = re.compile ("^slickedit::SEHashSet<.*>$")
    if lookup_tag == None:
        return None
    if regex.match (lookup_tag):
        return SEHashSetPrinter (lookup_tag, val)
    return None

################################################################################
# slickedit pretty printers
#
def register_slickedit_printers (obj):
    global _use_gdb_pp
    global sestring_lookup_function
    global searray_lookup_function
    if _use_gdb_pp:
        gdb.printing.register_pretty_printer(obj, sestring_lookup_function)
        gdb.printing.register_pretty_printer(obj, searray_lookup_function)
        gdb.printing.register_pretty_printer(obj, sehashtable_lookup_function)
        gdb.printing.register_pretty_printer(obj, sehashset_lookup_function)
    else:
        if obj is None:
            obj = gdb
        obj.pretty_printers.append(sestring_lookup_function)
        obj.pretty_printers.append(searray_lookup_function)
        obj.pretty_printers.append(sehashtable_lookup_function)
        obj.pretty_printers.append(sehashset_lookup_function)
