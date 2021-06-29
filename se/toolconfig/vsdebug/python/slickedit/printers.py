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
        if self.val['CMPRIVATE']['m_usingInternalBuffer'] == 1:
            ptr = self.val['CMPRIVATE']['m_internalBuffer']
            len = self.val['CMPRIVATE']['m_internalLength']
            return ptr.string (length = len)
        if self.val['CMPRIVATE']['m_externalpArray'] != 0:
            ptr = self.val['CMPRIVATE']['m_externalpArray']
            len = self.val['CMPRIVATE']['m_externalLength']
            return ptr.string (length = len)
        length = 0;
        return None
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
# slickedit::cmString pretty printer
#
class CMStringPrinter:
    "Print a cmStringT<>"
    def __init__ (self, val):
        self.val = val
    def to_string (self):
        if self.val['m_usingInternalBuffer'] == 1:
            ptr = self.val['m_internalBuffer']
            len = self.val['m_internalLength']
            return ptr.string (length = len)
        if self.val['m_externalpArray'] != 0:
            ptr = self.val['m_externalpArray']
            len = self.val['m_externalLength']
            return ptr.string (length = len)
        length = 0;
        return None
    def display_hint (self):
        return 'string'

def cmstring_lookup_function (val):
    lookup_tag = val.type.tag
    if lookup_tag == None:
        lookup_tag = val.type.name
    regex = re.compile ("^cm(Fat|)String(T<.*>|Utf8|Byte|WChar|Utf16|Acp)$")
    if lookup_tag == None:
        return None
    if regex.match (lookup_tag):
        return CMStringPrinter (val)
    return None

################################################################################
# slickedit::cmThinString pretty printer
#
class CMThinStringPrinter:
    "Print a cmThinStringT<>"
    def __init__ (self, val):
        self.val = val
    def to_string (self):
        if self.val['m_pRefBuf'] != 0:
            ptr = self.val['m_pRefBuf']['m_buffer']
            len = self.val['m_pRefBuf']['m_length']
            return ptr.string (length = len)
        length = 0;
        return None
    def display_hint (self):
        return 'string'

def cmthinstring_lookup_function (val):
    lookup_tag = val.type.tag
    if lookup_tag == None:
        lookup_tag = val.type.name
    regex = re.compile ("^cmThinString(T<.*>|Utf8|Byte|WChar|Utf16|Acp)$")
    if lookup_tag == None:
        return None
    if regex.match (lookup_tag):
        return CMThinStringPrinter (val)
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
    if lookup_tag == None:
        lookup_tag = val.type.name
    regex = re.compile ("^slickedit::SEArray<.*>$")
    if lookup_tag == None:
        return None
    if regex.match (lookup_tag):
        return SEArrayPrinter (lookup_tag, val)
    return None


################################################################################
# cmArray pretty printer
#
class CMArrayPrinter:
    "Print a cmArray<T>"

    class _iterator:
        def __init__ (self, start, numItems, maxItems):
            self.item = start
            self.numItems = numItems
            self.maxItems = maxItems
            self.count = 0

        def __iter__(self):
            return self

        def next(self):
            i = self.count
            self.count = self.count + 1
            if self.count > self.numItems:
                raise StopIteration
            if self.count > self.maxItems:
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
        firstItem = self.val['m_pArray']
        firstItem = firstItem.cast(itemtype.pointer ())
        numItems = self.val['m_ArrayLen']
        maxItems = self.val['m_Capacity']
        return self._iterator(firstItem, numItems, maxItems)                     

    def to_string(self):
        if self.val['m_pArray'] == 0:
            return 'empty %s' % (self.typename)
        self.numItems = self.val['m_ArrayLen']
        self.maxItems = self.val['m_Capacity']
        return ('%s of length %d, capacity %d' % (self.typename, self.numItems, self.maxItems))

    def display_hint(self):
        return 'array'

def cmarray_lookup_function (val):
    lookup_tag = val.type.tag
    if lookup_tag == None:
        lookup_tag = val.type.name
    regex = re.compile ("^cmArray<.*>$")
    if lookup_tag == None:
        return None
    if regex.match (lookup_tag):
        return CMArrayPrinter (lookup_tag, val)
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
    if lookup_tag == None:
        lookup_tag = val.type.name
    regex = re.compile ("^slickedit::SEHashTable<.*>$")
    if lookup_tag == None:
        return None
    if regex.match (lookup_tag):
        return SEHashTablePrinter (lookup_tag, val)
    return None

################################################################################
# cmDictionary pretty printer
#
class CMDictionaryPrinter:
    "Print a cmDictionary<K,V>"

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
                self.pValue = elt['m_kv']['m_value'].address
                self.nextItem = elt['m_pnext']
                return ('[%d]' % i, elt['m_kv']['m_key'])
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
            self.pValue = elt['m_kv']['m_value'].address
            self.nextItem = elt['m_pnext']
            return ('[%d]' % i, elt['m_kv']['m_key'])

    def __init__(self, typename, val):
        self.typename = typename
        self.val = val

    def children(self):
        firstItem = self.val['m_pArray']
        numItems = self.val['m_NofItems']
        maxItems = self.val['m_arrayLen']
        return self._iterator(firstItem, numItems, maxItems)                     

    def to_string(self):
        if self.val['m_pArray'] == 0:
            return 'empty %s' % (self.typename)
        self.numItems = self.val['m_NofItems']
        self.maxItems = self.val['m_arrayLen']
        return ('%s of length %d, capacity %d' % (self.typename, self.numItems, self.maxItems))

    def display_hint(self):
        return 'array'

def cmdictionary_lookup_function (val):
    lookup_tag = val.type.tag
    if lookup_tag == None:
        lookup_tag = val.type.name
    regex = re.compile ("^cmDictionary<.*>$")
    if lookup_tag == None:
        return None
    if regex.match (lookup_tag):
        return CMDictionaryPrinter (lookup_tag, val)
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
    if lookup_tag == None:
        lookup_tag = val.type.name
    regex = re.compile ("^slickedit::SEHashSet<.*>$")
    if lookup_tag == None:
        return None
    if regex.match (lookup_tag):
        return SEHashSetPrinter (lookup_tag, val)
    return None

################################################################################
# cmDictionarySet<T> pretty printer
#
class CMDictionarySetPrinter:
    "Print a cmDictionarySet<T>"

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
                self.nextItem = elt['m_pnext']
                self.itemCount = self.itemCount + 1
                return ('[%d]' % self.itemCount, elt['m_kv'])
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
            self.nextItem = elt['m_pnext']
            return ('[%d]' % self.itemCount, elt['m_kv'])

    def __init__(self, typename, val):
        self.typename = typename
        self.val = val

    def children(self):
        firstItem = self.val['m_pArray']
        numItems = self.val['m_NofItems']
        maxItems = self.val['m_arrayLen']
        return self._iterator(firstItem, numItems, maxItems)                     

    def to_string(self):
        if self.val['m_pArray'] == 0:
            return 'empty %s' % (self.typename)
        self.numItems = self.val['m_NofItems']
        self.maxItems = self.val['m_arrayLen']
        return ('%s of length %d, capacity %d' % (self.typename, self.numItems, self.maxItems))

    def display_hint(self):
        return 'array'

def cmdictionaryset_lookup_function (val):
    lookup_tag = val.type.tag
    if lookup_tag == None:
        lookup_tag = val.type.name
    regex = re.compile ("^cmDictionarySet<.*>$")
    if lookup_tag == None:
        return None
    if regex.match (lookup_tag):
        return CMDictionarySetPrinter (lookup_tag, val)
    return None


################################################################################
# slickedit pretty printers
#
def register_slickedit_printers (obj):
    global _use_gdb_pp
    global cmstring_lookup_function
    global sestring_lookup_function
    global searray_lookup_function
    if _use_gdb_pp:
        gdb.printing.register_pretty_printer(obj, cmstring_lookup_function)
        gdb.printing.register_pretty_printer(obj, cmthinstring_lookup_function)
        gdb.printing.register_pretty_printer(obj, sestring_lookup_function)
        gdb.printing.register_pretty_printer(obj, searray_lookup_function)
        gdb.printing.register_pretty_printer(obj, cmarray_lookup_function)
        gdb.printing.register_pretty_printer(obj, sehashtable_lookup_function)
        gdb.printing.register_pretty_printer(obj, sehashset_lookup_function)
        gdb.printing.register_pretty_printer(obj, cmdictionary_lookup_function)
        gdb.printing.register_pretty_printer(obj, cmdictionaryset_lookup_function)
    else:
        if obj is None:
            obj = gdb
        obj.pretty_printers.append(cmstring_lookup_function)
        obj.pretty_printers.append(cmthinstring_lookup_function)
        obj.pretty_printers.append(sestring_lookup_function)
        obj.pretty_printers.append(searray_lookup_function)
        obj.pretty_printers.append(cmarray_lookup_function)
        obj.pretty_printers.append(sehashtable_lookup_function)
        obj.pretty_printers.append(sehashset_lookup_function)
        obj.pretty_printers.append(cmdictionary_lookup_function)
        obj.pretty_printers.append(cmdictionaryset_lookup_function)

