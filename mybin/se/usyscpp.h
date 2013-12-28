#define _ATTRIBUTE(attrs)

#define __attribute(p)

#define __attribute__(p)

#define	__BEGIN_DECLS	extern "C" {

#define	__END_DECLS	}

#define __block

#define __cdecl

#define __CONCAT__(A,B) A##B

#define	__CONCAT1(x,y)	x##y

#define	__CONCAT(x,y)	__CONCAT1(x,y)

#define __const const

#define __cplusplus

#define __DARWIN_ALIAS(sym)
#define __DARWIN_ALIAS_C(sym)
#define __DARWIN_ALIAS_I(sym)
#define __DARWIN_INODE64(sym)

#define __DARWIN_1050(sym)
#define __DARWIN_1050ALIAS(sym)
#define __DARWIN_1050ALIAS_C(sym)
#define __DARWIN_1050ALIAS_I(sym)
#define __DARWIN_1050INODE64(sym)

#define __DARWIN_EXTSN(sym)
#define __DARWIN_EXTSN_C(sym)

#define _EXFUN(name, proto) name proto

#define __EXCEPTIONS

#define __intN_t(N, MODE) typedef int int##N##_t __attribute__ ((__mode__ (MODE)))

#define	__inline	inline

#define __MATHCALL(function, args) __MATHDECL (_Mdouble_complex_,function, args)

#define __MATHCALL(function,suffix, args) __MATHDECL (_Mdouble_,function,suffix, args)

#define __MATHCALLX(function,suffix, args, attrib) __MATHDECLX (_Mdouble_,function,suffix, args, attrib)

#define __MATHDECL(type, function, args) __MATHDECL_1(type, function, args); \
  __MATHDECL_1(type, __CONCAT(__,function), args)

#define __MATHDECL(type, function,suffix, args) __MATHDECL_1(type, function,suffix, args); \
  __MATHDECL_1(type, __CONCAT(__,function),suffix, args)

#define __MATHDECL_1(type, function, args) extern type __MATH_PRECNAME(function) args

#define __MATHDECL_1(type, function,suffix, args) extern type __MATH_PRECNAME(function,suffix) args

#define __MATHDECLX(type, function,suffix, args, attrib) __MATHDECL_1(type, function,suffix, args) __attribute__ (attrib); \
  __MATHDECL_1(type, __CONCAT(__,function),suffix, args) __attribute__ (attrib)

#define _ANSI_ARGS_(args) args

#define _ARGUMENTS(args) args

#define __(args) args

#define __P(args) args

#define _PROTO(args) args

#define __PARAMS(protos) protos

#define _P(protos) protos

#define P(protos) protos

#define _PARAMS(protos) protos

#define __REDIRECT(name, proto, alias) name proto __asm__ (__ASMNAME (#alias))

#define	__signed	signed

#define __SOCKADDR_ALLTYPES __SOCKADDR_ONETYPE (sockaddr) \
__SOCKADDR_ONETYPE (sockaddr_at) \
__SOCKADDR_ONETYPE (sockaddr_ax25) \
__SOCKADDR_ONETYPE (sockaddr_dl) \
__SOCKADDR_ONETYPE (sockaddr_eon) \
__SOCKADDR_ONETYPE (sockaddr_in) \
__SOCKADDR_ONETYPE (sockaddr_in6) \
__SOCKADDR_ONETYPE (sockaddr_inarp) \
__SOCKADDR_ONETYPE (sockaddr_ipx) \
__SOCKADDR_ONETYPE (sockaddr_iso) \
__SOCKADDR_ONETYPE (sockaddr_ns) \
__SOCKADDR_ONETYPE (sockaddr_un) \
__SOCKADDR_ONETYPE (sockaddr_x25)

#define __SOCKADDR_ONETYPE(type) struct type *__##type##__;

#define __u_intN_t(N, MODE) typedef unsigned int u_int##N##_t __attribute__ ((__mode__ (MODE)))

#define __dead2
#define __pure2
#define __unused

#undef __WIN32__

#define _ElfW_1(e,w,t) e##w##t

#define _GM2H_(p) ((struct gm_to_host_comm_s *)(p))

#define _H2GM_(p) ((struct host_to_gm_comm_s *)(p))

#define _IBMR2

#define _INCLUDE__STDC__

#define _NAMESPACE_STD_START

#define _NAMESPACE_STD_END

#undef _NO_PROTO

#undef _NONSTD_TYPES

#define __packed

#define __packed__

#define _PARAMS(protos) __P(protos)

#define _POSIX_C_SOURCE

#define _PROTOTYPES

#define _SIZEOF(x) sz_##x

#define __STDC__ 1

#define	__STRING(x)	#x

#define __THROW throw

#define	__volatile	 volatile
#define __volatile__ volatile

#define	__XSTRING(x) __STRING(x)

#define _Xconst const

#define _XFUNCPROTOBEGIN extern "C" {

#define _XFUNCPROTOEND }

#define _XLockMutex_fn (*_XLockMutex_fn_p)

#define _XOPEN_SOURCE

#define _XtShell_h_Const const

#define _XtStringDefs_h_Const const

#define _XUnlockMutex_fn (*_XUnlockMutex_fn_p)

#define ARCHDR struct ar_hdr

#define BUGVDEF(bugvar,lev) int bugvar = (lev);

#define BUGXDEF(bugvar) extern bugvar;

#define BZ_API(func) func

#define BZ_EXPORT

#define BZ_EXTERN extern

#define EXTERN_API(_type)                       extern _type
#define EXTERN_API_C(_type)                     extern _type
#define EXTERN_API_STDCALL(_type)               extern _type
#define EXTERN_API_C_STDCALL(_type)             extern _type
    
#define DEFINE_API(_type)                       _type 
#define DEFINE_API_C(_type)                     _type
#define DEFINE_API_STDCALL(_type)               _type
#define DEFINE_API_C_STDCALL(_type)             _type

#define CALLBACK_API(_type,_name)              _type (*_name)
#define CALLBACK_API_C(_type,_name)            _type (*_name)
#define CALLBACK_API_STDCALL(_type,_name)      _type (*_name)
#define CALLBACK_API_C_STDCALL(_type,_name)    _type (*_name)

#define AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER
#define AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER
#define AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER
#define AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER
#define AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER
#define AVAILABLE_MAC_OS_X_VERSION_10_5_AND_LATER
#define AVAILABLE_MAC_OS_X_VERSION_10_6_AND_LATER
#define AVAILABLE_MAC_OS_X_VERSION_10_7_AND_LATER
#define AVAILABLE_MAC_OS_X_VERSION_10_8_AND_LATER

#define DEPRECATED_ATTRIBUTE
#define WEAK_IMPORT_ATTRIBUTE
#define UNAVAILABLE_ATTRIBUTE

#define AVAILABLE_MAC_OS_X_VERSION_10_0_AND_LATER_BUT_DEPRECATED
#define AVAILABLE_MAC_OS_X_VERSION_10_1_AND_LATER_BUT_DEPRECATED
#define AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER_BUT_DEPRECATED
#define AVAILABLE_MAC_OS_X_VERSION_10_3_AND_LATER_BUT_DEPRECATED
#define AVAILABLE_MAC_OS_X_VERSION_10_4_AND_LATER_BUT_DEPRECATED
#define AVAILABLE_MAC_OS_X_VERSION_10_5_AND_LATER_BUT_DEPRECATED
#define AVAILABLE_MAC_OS_X_VERSION_10_6_AND_LATER_BUT_DEPRECATED
#define AVAILABLE_MAC_OS_X_VERSION_10_7_AND_LATER_BUT_DEPRECATED
#define AVAILABLE_MAC_OS_X_VERSION_10_8_AND_LATER_BUT_DEPRECATED

#define DEPRECATED_IN_MAC_OS_X_VERSION_10_0_AND_LATER
#define DEPRECATED_IN_MAC_OS_X_VERSION_10_1_AND_LATER
#define DEPRECATED_IN_MAC_OS_X_VERSION_10_2_AND_LATER
#define DEPRECATED_IN_MAC_OS_X_VERSION_10_3_AND_LATER
#define DEPRECATED_IN_MAC_OS_X_VERSION_10_4_AND_LATER
#define DEPRECATED_IN_MAC_OS_X_VERSION_10_5_AND_LATER
#define DEPRECATED_IN_MAC_OS_X_VERSION_10_6_AND_LATER
#define DEPRECATED_IN_MAC_OS_X_VERSION_10_7_AND_LATER
#define DEPRECATED_IN_MAC_OS_X_VERSION_10_8_AND_LATER

#define CAT(a,b) a##b

#define CAT3(a,b,c) a##b##c

#define CAT4(a,b,c,d) a##b##c##d

#define CIRCLEQ_ENTRY(type) struct {								 \
	struct type *cqe_next;

#define CIRCLEQ_HEAD(name, type) struct name {								 \
	struct type *cqh_first;

#define COMPUNIT struct compilation_unit

#define CONST const

#define CONST_DECL const

#define DEFSTRING(v,s) rep_ALIGN_CELL(const static rep_string v) = { \
	((sizeof(s) - 1) << rep_STRING_LEN_SHIFT) \
	| rep_CELL_STATIC_BIT | rep_String, \
	(u_char *)s \
    }

#define DEFSYM(x, name) repv Q ## x; DEFSTRING(str_ ## x, name)

#define DEFUN(name, arglist, args) name arglist args;

#define DEFUN(name,fsym,ssym,args,type) DEFSTRING(rep_CONCAT(ssym, __name), name);				 \
    extern repv fsym args;						 \
    rep_ALIGN_CELL(rep_xsubr ssym) = { type, fsym,			 \
					rep_VAL(&rep_CONCAT(ssym, __name)), \
					rep_NULL };			 \
    repv fsym args

#define DEFUN_INT(name,fsym,ssym,args,type,interactive) DEFSTRING(rep_CONCAT(ssym, __name), name);				 \
    DEFSTRING(rep_CONCAT(ssym, __int), interactive);			 \
    extern repv fsym args;						 \
    rep_ALIGN_CELL(rep_xsubr ssym) = { type, fsym,			 \
					rep_VAL(&rep_CONCAT(ssym, __name)), \
					rep_VAL(&rep_CONCAT(ssym, __int)) }; \
    repv fsym args

#define DEFUN_VOID(name) name()

#define DLLEXPORT

#define Enter(type, w, dev, chan, a, b, c) type Func;								 \
    dev_t Dev;								 \
    chan_t Chan;							 \
    int Flag1;								 \
    int Flag2;								 \
    int Line;								 \
    int Which = !TRC_ISON(0) ? (Flag1 = Flag2 = 0) :			 \
	((Dev = dev),							 \
	 (Chan = chan),							 \
	 (Flag1 = TTY_TRCMK[0]&(1<<w)),					 \
	 (Flag2 = TTY_TRCMK[1]&(1<<w)),					 \
	 (Flag1 && (TRCHKGT(_TTYHKID(w), Dev, Chan, a, b, c), 0)), w)

#define export

#define far

#define FARDATA

#define FILHDR struct header

#define G_GNUC_CONST const

#define G_GNUC_FORMAT

#define G_GNUC_FORMAT(format_idx,arg_idx)

#define G_GNUC_PRINTF

#define G_GNUC_PRINTF(format_idx,arg_idx)

#define G_GNUC_SCANF

#define G_GNUC_SCANF(format_idx,arg_idx)

#define G_GNUC_UNUSED __attribute__((unused))

#define g_string(x) #x

#define GLCALLBACKP __stdcall *

#define GLUAPI

#define GLUTAPI extern

#define GLUTAPIENTRY

#define GLUTAPIENTRYV

#define GLUTCALLBACK

#define GUTILS_C_VAR extern

#define IDMASTER(xx) IDCAT2(xx,_CNTLS),	 \
		IDCAT2(xx,_UNITS),	 \
		IDCAT2(xx,_CHAN),	 \
		IDCAT2(xx,_TYPE)

#define IDSYSTEM(xx,ctlr) IDCAT3(xx,_,ctlr),		 \
		IDCAT4(xx,_,ctlr,_VECT),	 \
		IDCAT4(xx,_,ctlr,_SIOA),	 \
		IDCAT4(xx,_,ctlr,_EIOA),	 \
		IDCAT4(xx,_,ctlr,_SCMA),	 \
		IDCAT4(xx,_,ctlr,_ECMA)

#define INITPTR struct init_pointer_record

#define JOIN(a,b) a##b

#define jpeg_common_fields struct jpeg_error_mgr * err;

#define LDRFIX struct loader_fixup

#define LIST_ENTRY(type) struct {								 \
	struct type *le_next;  \
    }

#define LIST_HEAD(name, type) struct name {								 \
	struct type *lh_first; \
    }

#define LOCAL(type) static type

#undef MACOS

#define METHODDEF(type) static type

#undef MSDOS

#define NeedFunctionPrototyes

#define NeedWidePrototypes 0

#define NETSPL_DECL(s) int s;

#define NETSPL_MPDECL(s)

#define NETSPL_SPDECL(s)

#define OBJC_EXPORT  extern

#define OBJC_DECLARE

#define PNG_EXTERN

#define RELOC struct fixup_request_record

#define rep_ALIGN_CELL(d) d

#define rep_CONCAT__(x, y) x##y

#define rep_QUOTE__(x) #x

#define CIRCLEQ_HEAD(name, type)					\
    struct name {								\
	    struct type *cqh_first;	\
	    struct type *cqh_last;	\
    }

#define CIRCLEQ_ENTRY(type)						\
    struct {								\
	    struct type *cqe_next;	\
	    struct type *cqe_prev;	\
    }

#define OF(args) args

#define _RE_ARGS(args) args

#define SLIST_HEAD(name, type)						\
    struct name {								\
	    struct type *slh_first;	\
    }

#define SLIST_ENTRY(type)						\
struct {						\
	struct type *sle_next;	\
}

#define SP_WRITE_DECL struct strioctl lpwrite_str   ;

#define SPAHDR struct space_dictionary_record

#define StandardLocalRecord int attr; \
  int archived; \
  int secret

#define StandardSyncAbs int (*MatchRecord)(SyncAbs*, LocalRecord**, PilotRecord*); \
  int (*FreeMatch)(SyncAbs*, LocalRecord**); \
  int (*ArchiveLocal)(SyncAbs*, LocalRecord*); \
  int (*ArchiveRemote)(SyncAbs*,LocalRecord*,PilotRecord*); \
  int (*StoreRemote)(SyncAbs*,PilotRecord*); \
  int (*ClearStatusArchiveLocal)(SyncAbs*,LocalRecord*); \
  int (*Iterate)(SyncAbs*,LocalRecord**); \
  int (*IterateSpecific)(SyncAbs*,LocalRecord**, int flag, int archived); \
  int (*Purge)(SyncAbs*); \
  int (*SetStatus)(SyncAbs*,LocalRecord*,int status); \
  int (*SetArchived)(SyncAbs*,LocalRecord*, int); \
  unsigned long (*GetPilotID)(SyncAbs*,LocalRecord*); \
  int (*SetPilotID)(SyncAbs*,LocalRecord*,unsigned long); \
  int (*Compare)(SyncAbs*,LocalRecord*,PilotRecord*); \
  int (*CompareBackup)(SyncAbs*,LocalRecord*,PilotRecord*); \
  int (*FreeTransmit)(SyncAbs*,LocalRecord*,PilotRecord*); \
  int (*DeleteAll)(SyncAbs*); \
  PilotRecord * (*Transmit)(SyncAbs*,LocalRecord*)

#define START_FSM {						 \
			iob->markstack = NULL;				 \
			iob->timeflag = FALSE;				 \
			iob->in_fsm = TRUE;				 \
			if (!(iob->intloc.proc > (int (*)()) 1 )) {

#define STAILQ_HEAD(name, type)						\
    struct name {								\
	    struct type *stqh_first;	\
	    struct type **stqh_last;	\
    }

#define STAILQ_ENTRY(type)						\
    struct {								\
	    struct type *stqe_next;	*/			\
    }


#define STRINGIFY(x) #x

#define TAILQ_ENTRY(type) struct {								 \
	struct type *tqe_next;\
    }

#define TAILQ_HEAD(name, type) struct name {								 \
	struct type *tqh_first; \
    }

#define TIX_DECLARE_CMD(func) int func _ANSI_ARGS_((ClientData clientData, \
	Tcl_Interp *interp, int argc, char ** argv))

#define TIX_DECLARE_SUBCMD(func) int func _ANSI_ARGS_((ClientData clientData, \
	Tcl_Interp *interp, int argc, char ** argv))

#define TIX_DEFINE_CMD(func) int func(clientData, interp, argc, argv) \
    ClientData clientData;

#define UINT32_C(c) c ## U

#define UINT8_C(c) c ## U

#define VERBATIM(x) x

#define vsema(sema) {

#undef WIN32

#undef WIN32_LEAN_AND_MEAN

#define WINDOW struct _win_st

#define WINDOW struct _win_st

#define WINGDIAPI

#define ZEXPORT

#define ZEXPORTVA

#define ZEXTERN extern

#undef notdef

/////////////////////////////////////////////////////////////////////////////
// #defines for Nokia's Qt GUI toolkit, version 4.x
/////////////////////////////////////////////////////////////////////////////

#define QT_NAMESPACE qt
#define QT_BEGIN_NAMESPACE
#define QT_END_NAMESPACE
#define QT_PREPEND_NAMESPACE(name) ::name
#define QT_USE_NAMESPACE using namespace ::QT_NAMESPACE;

#define QT_BEGIN_INCLUDE_NAMESPACE }
#define QT_END_INCLUDE_NAMESPACE namespace QT_NAMESPACE {

#define QT_BEGIN_MOC_NAMESPACE QT_USE_NAMESPACE
#define QT_END_MOC_NAMESPACE

#define QT_FORWARD_DECLARE_CLASS(name) \
    QT_BEGIN_NAMESPACE class name; QT_END_NAMESPACE \
    using QT_PREPEND_NAMESPACE(name);

#define QT_FORWARD_DECLARE_STRUCT(name) \
    QT_BEGIN_NAMESPACE struct name; QT_END_NAMESPACE \
    using QT_PREPEND_NAMESPACE(name);

#define QT_MANGLE_NAMESPACE0(x) x
#define QT_MANGLE_NAMESPACE1(a, b) a##_##b
#define QT_MANGLE_NAMESPACE2(a, b) QT_MANGLE_NAMESPACE1(a,b)
#define QT_MANGLE_NAMESPACE(name) QT_MANGLE_NAMESPACE2( \
        QT_MANGLE_NAMESPACE0(name), QT_MANGLE_NAMESPACE0(QT_NAMESPACE))

#define QT_BEGIN_HEADER extern "C++" {
#define QT_END_HEADER }
#define QT_BEGIN_INCLUDE_HEADER }
#define QT_END_INCLUDE_HEADER extern "C++" {

#define QAXAGG_IUNKNOWN \
    HRESULT WINAPI QueryInterface(REFIID iid, LPVOID *iface) { \
    return controllingUnknown()->QueryInterface(iid, iface); } \
    ULONG WINAPI AddRef() {return controllingUnknown()->AddRef(); } \
    ULONG WINAPI Release() {return controllingUnknown()->Release(); } \

#define QAXFACTORY_EXPORT(IMPL, TYPELIB, APPID)	\
    QT_BEGIN_NAMESPACE \
    QAxFactory *qax_instantiate()		\
    {							\
        IMPL *impl = new IMPL(QUuid(TYPELIB), QUuid(APPID));	\
        return impl;					\
    } \
    QT_END_NAMESPACE

#define QAXFACTORY_DEFAULT(Class, IIDClass, IIDInterface, IIDEvents, IIDTypeLib, IIDApp) \
    QT_BEGIN_NAMESPACE \
    class QAxDefaultFactory : public QAxFactory \
    { \
    public: \
        QAxDefaultFactory(const QUuid &app, const QUuid &lib) \
        : QAxFactory(app, lib), className(QLatin1String(#Class)) {} \
        QStringList featureList() const \
        { \
            QStringList list; \
            list << className; \
            return list; \
        } \
        const QMetaObject *metaObject(const QString &key) const \
        { \
            if (key == className) \
            return &Class::staticMetaObject; \
            return 0; \
        } \
        QObject *createObject(const QString &key) \
        { \
            if (key == className) \
                return new Class(0); \
            return 0; \
        } \
        QUuid classID(const QString &key) const \
        { \
            if (key == className) \
                return QUuid(IIDClass); \
            return QUuid(); \
        } \
        QUuid interfaceID(const QString &key) const \
        { \
            if (key == className) \
                return QUuid(IIDInterface); \
            return QUuid(); \
        } \
        QUuid eventsID(const QString &key) const \
        { \
            if (key == className) \
                return QUuid(IIDEvents); \
            return QUuid(); \
        } \
    private: \
        QString className; \
    }; \
    QT_END_NAMESPACE \
    QAXFACTORY_EXPORT(QAxDefaultFactory, IIDTypeLib, IIDApp) \

#define QAXFACTORY_BEGIN(IDTypeLib, IDApp) \
    QT_BEGIN_NAMESPACE \
    class QAxFactoryList : public QAxFactory \
    { \
        QStringList factoryKeys; \
        QHash<QString, QAxFactory*> factories; \
        QHash<QString, bool> creatable; \
    public: \
        QAxFactoryList() \
        : QAxFactory(IDTypeLib, IDApp) \
        { \
            QAxFactory *factory = 0; \
            QStringList keys; \
            QStringList::Iterator it; \

#define QAXCLASS(Class) \
            factory = new QAxClass<Class>(typeLibID(), appID()); \
            qRegisterMetaType<Class*>(#Class"*"); \
            keys = factory->featureList(); \
            for (it = keys.begin(); it != keys.end(); ++it) { \
                factoryKeys += *it; \
                factories.insert(*it, factory); \
                creatable.insert(*it, true); \
            }\

#define QAXTYPE(Class) \
            factory = new QAxClass<Class>(typeLibID(), appID()); \
            qRegisterMetaType<Class*>(#Class"*"); \
            keys = factory->featureList(); \
            for (it = keys.begin(); it != keys.end(); ++it) { \
                factoryKeys += *it; \
                factories.insert(*it, factory); \
                creatable.insert(*it, false); \
            }\

#define QAXFACTORY_END() \
        } \
        ~QAxFactoryList() { qDeleteAll(factories); } \
        QStringList featureList() const {  return factoryKeys; } \
        const QMetaObject *metaObject(const QString&key) const { \
            QAxFactory *f = factories[key]; \
            return f ? f->metaObject(key) : 0; \
        } \
        QObject *createObject(const QString &key) { \
            if (!creatable.value(key)) \
                return 0; \
            QAxFactory *f = factories[key]; \
            return f ? f->createObject(key) : 0; \
        } \
        QUuid classID(const QString &key) { \
            QAxFactory *f = factories.value(key); \
            return f ? f->classID(key) : QUuid(); \
        } \
        QUuid interfaceID(const QString &key) { \
            QAxFactory *f = factories.value(key); \
            return f ? f->interfaceID(key) : QUuid(); \
        } \
        QUuid eventsID(const QString &key) { \
            QAxFactory *f = factories.value(key); \
            return f ? f->eventsID(key) : QUuid(); \
        } \
        void registerClass(const QString &key, QSettings *s) const { \
            QAxFactory *f = factories.value(key); \
            if (f) f->registerClass(key, s); \
        } \
        void unregisterClass(const QString &key, QSettings *s) const { \
            QAxFactory *f = factories.value(key); \
            if (f) f->unregisterClass(key, s); \
        } \
        QString exposeToSuperClass(const QString &key) const { \
            QAxFactory *f = factories.value(key); \
            return f ? f->exposeToSuperClass(key) : QString(); \
        } \
        bool stayTopLevel(const QString &key) const { \
            QAxFactory *f = factories.value(key); \
            return f ? f->stayTopLevel(key) : false; \
        } \
        bool hasStockEvents(const QString &key) const { \
            QAxFactory *f = factories.value(key); \
            return f ? f->hasStockEvents(key) : false; \
        } \
    }; \
    QAxFactory *qax_instantiate()		\
    {							\
        QAxFactoryList *impl = new QAxFactoryList();	\
        return impl;					\
    } \
    QT_END_NAMESPACE

#define PHONON_TEMPLATE_CLASS_EXPORT
#define PHONON_TEMPLATE_CLASS_MEMBER_EXPORT
#define PHONON_EXPORT
#define PHONON_EXPORT_DEPRECATED

#define K_DECLARE_PRIVATE(Class) \
    inline Class##Private* k_func() { return reinterpret_cast<Class##Private *>(k_ptr); } \
    inline const Class##Private* k_func() const { return reinterpret_cast<const Class##Private *>(k_ptr); } \
    friend class Class##Private;

#define PHONON_ABSTRACTBASE(classname) \
protected: \
    /**
     * \internal
     * Constructor that is called from derived classes.
     *
     * \param parent Standard QObject parent.
     */ \
    classname(classname ## Private &dd, QObject *parent); \
       private:

#define PHONON_OBJECT(classname) \
public: \
    /**
     * Constructs an object with the given \p parent.
     */ \
    classname(QObject *parent = 0); \
       private:

#define PHONON_HEIR(classname) \
public: \
    /**
     * Constructs an object with the given \p parent.
     */ \
    classname(QObject *parent = 0); \

#define Q_PRIVATE_SLOT(d, signature)

#define Q_AUTOTEST_EXPORT
#define Q_CORE_EXPORT_INLINE inline
#define Q_DECL_ALIGN(n)
#define Q_DECLARATIVE_EXPORT Q_DECL_EXPORT

#define Q_DECLARE_METATYPE(TYPE)                                        \
    QT_BEGIN_NAMESPACE                                                  \
    template <>                                                         \
    struct QMetaTypeId< TYPE >                                          \
    {                                                                   \
        enum { Defined = 1 };                                           \
        static int qt_metatype_id()                                     \
            {                                                           \
                static QBasicAtomicInt metatype_id = Q_BASIC_ATOMIC_INITIALIZER(0); \
                if (!metatype_id)                                       \
                    metatype_id = qRegisterMetaType< TYPE >(#TYPE,      \
                               reinterpret_cast< TYPE *>(quintptr(-1))); \
                return metatype_id;                                     \
            }                                                           \
    };                                                                  \
    QT_END_NAMESPACE

#define Q_DECLARE_BUILTIN_METATYPE(TYPE, NAME) \
    QT_BEGIN_NAMESPACE \
    template<> struct QMetaTypeId2<TYPE> \
    { \
        enum { Defined = 1, MetaType = QMetaType::NAME }; \
        static inline int qt_metatype_id() { return QMetaType::NAME; } \
    }; \
    QT_END_NAMESPACE

#define Q_DECLARE_CONTACTFILTER_PRIVATE(Class) \
    inline Class##Private* d_func(); \
    inline const Class##Private* d_func() const; \
    friend class Class##Private;

#define Q_DECLARE_CUSTOM_CONTACT_DETAIL(className, definitionNameString) \
    className() : QContactDetail(DefinitionName.latin1()) {} \
    className(const QContactDetail& field) : QContactDetail(field, DefinitionName.latin1()) {} \
    className& operator=(const QContactDetail& other) {assign(other, DefinitionName.latin1()); return *this;} \
    \
    Q_DECLARE_LATIN1_CONSTANT(DefinitionName, definitionNameString);

#define Q_IMPLEMENT_CUSTOM_CONTACT_DETAIL(className, definitionNameString) \
    Q_DEFINE_LATIN1_CONSTANT(className::DefinitionName, definitionNameString)

#define Q_IMPLEMENT_CONTACTFILTER_PRIVATE(Class) \
    Class##Private* Class::d_func() { return reinterpret_cast<Class##Private *>(d_ptr.data()); } \
    const Class##Private* Class::d_func() const { return reinterpret_cast<const Class##Private *>(d_ptr.constData()); } \
    Class::Class(const QContactFilter& other) : QContactFilter() { Class##Private::copyIfPossible(d_ptr, other); }

#define Q_IMPLEMENT_CONTACTFILTER_VIRTUALCTORS(Class, Type) \
    QContactFilterPrivate* clone() const { return new Class##Private(*this); } \
    virtual QContactFilter::FilterType type() const {return Type;} \
    static void copyIfPossible(QSharedDataPointer<QContactFilterPrivate>& d_ptr, const QContactFilter& other) \
    { \
        if (other.type() == Type) \
            d_ptr = extract_d(other); \
        else \
            d_ptr = new Class##Private; \
    }

#define Q_DECLARE_CUSTOM_ORGANIZER_DETAIL(className, definitionNameString) \
    className() : QOrganizerItemDetail(DefinitionName.latin1()) {} \
    className(const QOrganizerItemDetail& field) : QOrganizerItemDetail(field, DefinitionName.latin1()) {} \
    className& operator=(const QOrganizerItemDetail& other) {assign(other, DefinitionName.latin1()); return *this;} \
    \
    Q_DECLARE_LATIN1_CONSTANT(DefinitionName, definitionNameString);

#define Q_IMPLEMENT_CUSTOM_ORGANIZER_DETAIL(className, definitionNameString) \
    Q_DEFINE_LATIN1_CONSTANT(className::DefinitionName, definitionNameString)

#define Q_DECLARE_CUSTOM_ORGANIZER_ITEM(className, typeConstant) \
    className() : QOrganizerItem(typeConstant.latin1()) {} \
    className(const QOrganizerItem& other) : QOrganizerItem(other, typeConstant.latin1()) {} \
    className& operator=(const QOrganizerItem& other) {assign(other, typeConstant.latin1()); return *this;}

#define Q_DECLARE_LATIN1_CONSTANT(varname, str) static const QLatin1Constant<sizeof(str)> varname
#define Q_DEFINE_LATIN1_CONSTANT(varname, str) const QLatin1Constant<sizeof(str)> varname = {str}

#define Q_ORGANIZER_EXPORT
#define Q_ORGANIZER_MEMORYENGINE_EXPORT

#define Q_DECLARE_CUSTOM_ORGANIZER_REMINDER_DETAIL(className, definitionNameString) \
    className() : QOrganizerItemReminder(DefinitionName.latin1()) {} \
    className(const QOrganizerItemDetail& field) : QOrganizerItemReminder(field, DefinitionName.latin1()) {} \
    className& operator=(const QOrganizerItemDetail& other) {assign(other, DefinitionName.latin1()); return *this;} \
    \
    Q_DECLARE_LATIN1_CONSTANT(DefinitionName, definitionNameString);

#define Q_IMPLEMENT_CUSTOM_ORGANIZER_REMINDER_DETAIL(className, definitionNameString) \
    Q_DEFINE_LATIN1_CONSTANT(className::DefinitionName, definitionNameString)

#define QTM_PREPEND_NAMESPACE(name) ::name
#define QTM_BEGIN_NAMESPACE
#define QTM_END_NAMESPACE
#define QTM_USE_NAMESPACE

#define QVALUESPACE_AUTO_INSTALL_LAYER(name) \
QAbstractValueSpaceLayer * _qvaluespaceauto_layercreate_ ## name() \
{ \
  return name::instance(); \
} \
static QValueSpace::AutoInstall _qvaluespaceauto_ ## name(_qvaluespaceauto_layercreate_ ## name);

#define QWEBKIT_EXPORT

#define Q_DECLARE_EXTENSION_INTERFACE(IFace, IId) \
const char * const IFace##_iid = IId; \
Q_DECLARE_INTERFACE(IFace, IId) \
template <> inline IFace *qt_extension<IFace *>(QAbstractExtensionManager *manager, QObject *object) \
{ QObject *extension = manager->extension(object, Q_TYPEID(IFace)); return extension ? static_cast<IFace *>(extension->qt_metacast(IFace##_iid)) : static_cast<IFace *>(0); }


#define Q_DECLARE_INCOMPATIBLE_FLAGS(Flags) \
inline QIncompatibleFlag operator|(Flags::enum_type f1, int f2) \
{ return QIncompatibleFlag(int(f1) | f2); }
#endif

#define Q_DECLARE_OPERATORS_FOR_FLAGS(Flags) \
inline QFlags<Flags::enum_type> operator|(Flags::enum_type f1, Flags::enum_type f2) \
{ return QFlags<Flags::enum_type>(f1) | f2; } \
inline QFlags<Flags::enum_type> operator|(Flags::enum_type f1, QFlags<Flags::enum_type> f2) \
{ return f2 | f1; } Q_DECLARE_INCOMPATIBLE_FLAGS(Flags)

#define Q_DECLARE_LANDMARKFILTER_PRIVATE(Class) \
    inline Class##Private* d_func(); \
    inline const Class##Private* d_func() const; \
    friend class Class##Private;

#define Q_IMPLEMENT_LANDMARKFILTER_PRIVATE(Class) \
    Class##Private* Class::d_func() { return reinterpret_cast<Class##Private *>(d_ptr.data()); } \
    const Class##Private* Class::d_func() const { return reinterpret_cast<const Class##Private *>(d_ptr.constData()); } \
    Class::Class(const QLandmarkFilter& other) : QLandmarkFilter() { Class##Private::copyIfPossible(d_ptr, other); }

#define Q_IMPLEMENT_LANDMARKFILTER_VIRTUALCTORS(Class, Type) \
    virtual QLandmarkFilterPrivate* clone() const { return new Class##Private(*this); } \
    static void copyIfPossible(QSharedDataPointer<QLandmarkFilterPrivate>& d_ptr, const QLandmarkFilter& other) \
    { \
        if (other.type() == Type) \
            d_ptr = extract_d(other); \
        else \
            d_ptr = new Class##Private(); \
    }

#define Q_IMPLEMENT_LANDMARKSORTORDER_PRIVATE(Class) \
    Class##Private* Class::d_func() { return reinterpret_cast<Class##Private *>(d_ptr.data()); } \
    const Class##Private* Class::d_func() const { return reinterpret_cast<const Class##Private *>(d_ptr.constData()); } \
    Class::Class(const QLandmarkSortOrder& other) : QLandmarkSortOrder() { Class##Private::copyIfPossible(d_ptr, other); }

#define Q_IMPLEMENT_LANDMARKSORTORDER_VIRTUALCTORS(Class, Type) \
    virtual QLandmarkSortOrderPrivate* clone() const { return new Class##Private(*this); } \
    static void copyIfPossible(QSharedDataPointer<QLandmarkSortOrderPrivate>& d_ptr, const QLandmarkSortOrder& other) \
    { \
        if (other.type() == Type) \
            d_ptr = extract_d(other); \
        else \
            d_ptr = new Class##Private(); \
    }

#define Q_IMPLEMENT_ORGANIZERITEMFILTER_PRIVATE(Class) \
    Class##Private* Class::d_func() { return reinterpret_cast<Class##Private *>(d_ptr.data()); } \
    const Class##Private* Class::d_func() const { return reinterpret_cast<const Class##Private *>(d_ptr.constData()); } \
    Class::Class(const QOrganizerItemFilter& other) : QOrganizerItemFilter() { Class##Private::copyIfPossible(d_ptr, other); }

#define Q_IMPLEMENT_ORGANIZERITEMFILTER_VIRTUALCTORS(Class, Type) \
    QOrganizerItemFilterPrivate* clone() const { return new Class##Private(*this); } \
    virtual QOrganizerItemFilter::FilterType type() const {return Type;} \
    static void copyIfPossible(QSharedDataPointer<QOrganizerItemFilterPrivate>& d_ptr, const QOrganizerItemFilter& other) \
    { \
        if (other.type() == Type) \
            d_ptr = extract_d(other); \
        else \
            d_ptr = new Class##Private; \
    }

#define Q_DECLARE_LANDMARKSORTORDER_PRIVATE(Class) \
    inline Class##Private* d_func(); \
    inline const Class##Private* d_func() const; \
    friend class Class##Private;

#define Q_DECLARE_NON_CONST_PUBLIC(Class) \
    inline Class* q_func() { return static_cast<Class *>(q_ptr); } \
    friend class Class;

#define Q_DECLARE_ORGANIZERITEMFILTER_PRIVATE(Class) \
    inline Class##Private* d_func(); \
    inline const Class##Private* d_func() const; \
    friend class Class##Private;

#define Q_DECLARE_PRIVATE_D(Dptr, Class) \
    inline Class##Private* d_func() { return reinterpret_cast<Class##Private *>(Dptr); } \
    inline const Class##Private* d_func() const { return reinterpret_cast<const Class##Private *>(Dptr); } \
    friend class Class##Private;


#define Q_DECLARE_USER_METATYPE_NO_OPERATORS(TYPE) \
    Q_DECLARE_METATYPE(TYPE) \
    template<> \
    struct QMetaTypeRegister< TYPE > \
    { \
        static int registerType() \
        { \
            _QATOMIC_ONCE(); \
            int id = qMetaTypeId( reinterpret_cast<TYPE *>(0) ); \
            if ( id >= static_cast<int>(QMetaType::User) ) \
                qRegisterMetaTypeStreamOperators< TYPE >( #TYPE ); \
            return 1; \
        } \
        static int __init_variable__; \
    };

#define Q_DECLARE_USER_METATYPE(TYPE) \
    Q_DECLARE_USER_METATYPE_NO_OPERATORS(TYPE) \
    QMF_EXPORT QDataStream &operator<<(QDataStream &stream, const TYPE &var); \
    QMF_EXPORT QDataStream &operator>>( QDataStream &stream, TYPE &var );

#define Q_DECLARE_USER_METATYPE_TYPEDEF(TAG,TYPE)       \
    template <typename T> \
    struct QMetaTypeRegister##TAG \
    { \
        static int registerType() { return 1; } \
    }; \
    template<> struct QMetaTypeRegister##TAG< TYPE > { \
        static int registerType() { \
            _QATOMIC_ONCE(); \
            qRegisterMetaType< TYPE >( #TYPE ); \
            qRegisterMetaTypeStreamOperators< TYPE >( #TYPE ); \
            return 1; \
        } \
        static int __init_variable__; \
    };

#define Q_DECLARE_USER_METATYPE_ENUM(TYPE)      \
    Q_DECLARE_USER_METATYPE(TYPE)

#define Q_IMPLEMENT_USER_METATYPE_NO_OPERATORS(TYPE) \
    int QMetaTypeRegister< TYPE >::__init_variable__ = \
        QMetaTypeRegister< TYPE >::registerType();

#define Q_IMPLEMENT_USER_METATYPE(TYPE) \
    QDataStream &operator<<(QDataStream &stream, const TYPE &var) \
    { \
        var.serialize(stream); \
        return stream; \
    } \
    \
    QDataStream &operator>>( QDataStream &stream, TYPE &var ) \
    { \
        var.deserialize(stream); \
        return stream; \
    } \
    Q_IMPLEMENT_USER_METATYPE_NO_OPERATORS(TYPE)

#define Q_IMPLEMENT_USER_METATYPE_TYPEDEF(TAG,TYPE)     \
    int QMetaTypeRegister##TAG< TYPE >::__init_variable__ = \
        QMetaTypeRegister##TAG< TYPE >::registerType();

#define Q_IMPLEMENT_USER_METATYPE_ENUM(TYPE)    \
    QDataStream& operator<<( QDataStream& stream, const TYPE &v ) \
    { \
        stream << static_cast<qint32>(v); \
        return stream; \
    } \
    QDataStream& operator>>( QDataStream& stream, TYPE& v ) \
    { \
        qint32 _v; \
        stream >> _v; \
        v = static_cast<TYPE>(_v); \
        return stream; \
    } \
    Q_IMPLEMENT_USER_METATYPE_NO_OPERATORS(TYPE)

#define Q_DEFINE_GALLERY_PROPERTY(scope, name) const QGalleryProperty scope::name = {#name, sizeof(#name) - 1};
#define Q_DEFINE_GALLERY_TYPE(scope, name) const QGalleryType scope::name = {#name, sizeof(#name) - 1};

#define Q_DESTRUCTOR_FUNCTION0(AFUNC) \
    class AFUNC ## __dest_class__ { \
    public: \
       inline AFUNC ## __dest_class__() { } \
       inline ~ AFUNC ## __dest_class__() { AFUNC(); } \
    } AFUNC ## __dest_instance__;
#define Q_DESTRUCTOR_FUNCTION(AFUNC) Q_DESTRUCTOR_FUNCTION0(AFUNC)

#define Q_IMPORT_PLUGIN(PLUGIN) \
        extern QT_PREPEND_NAMESPACE(QObject) *qt_plugin_instance_##PLUGIN(); \
        class Static##PLUGIN##PluginInstance{ \
        public: \
                Static##PLUGIN##PluginInstance() { \
                qRegisterStaticPluginInstanceFunction(qt_plugin_instance_##PLUGIN); \
                } \
        }; \
       static Static##PLUGIN##PluginInstance static##PLUGIN##Instance;

#define Q_PLUGIN_INSTANCE(IMPLEMENTATION) \
        { \
            static QT_PREPEND_NAMESPACE(QPointer)<QT_PREPEND_NAMESPACE(QObject)> _instance; \
            if (!_instance)      \
                _instance = new IMPLEMENTATION; \
            return _instance; \
        }

#define Q_EXPORT_PLUGIN(PLUGIN) \
            Q_EXPORT_PLUGIN2(PLUGIN, PLUGIN)

#define Q_EXPORT_STATIC_PLUGIN(PLUGIN) \
            Q_EXPORT_STATIC_PLUGIN2(PLUGIN, PLUGIN)

#define Q_EXPORT_PLUGIN2(PLUGIN, PLUGINCLASS) \
            QT_PREPEND_NAMESPACE(QObject) \
                *qt_plugin_instance_##PLUGIN() \
            Q_PLUGIN_INSTANCE(PLUGINCLASS)

#define Q_EXPORT_STATIC_PLUGIN2(PLUGIN, PLUGINCLASS) \
            Q_EXPORT_PLUGIN2(PLUGIN, PLUGINCLASS)

#  define Q_PLUGIN_VERIFICATION_DATA \
    static const char qt_plugin_verification_data[] = \
      "pattern=""QT_PLUGIN_VERIFICATION_DATA""\n" \
      "version="QT_VERSION_STR"\n" \
      "debug="QPLUGIN_DEBUG_STR"\n" \
      "buildkey="QT_BUILD_KEY;

#define Q_EXPORT_SQLDRIVER_DB2
#define Q_EXPORT_SQLDRIVER_MYSQL
#define Q_EXPORT_SQLDRIVER_OCI
#define Q_EXPORT_SQLDRIVER_ODBC
#define Q_EXPORT_SQLDRIVER_PSQL
#define Q_EXPORT_SQLDRIVER_SQLITE
#define Q_EXPORT_SQLDRIVER_TDS

#define Q_FEEDBACK_EXPORT
#define Q_GALLERY_EXPORT

#define Q_EMIT
#define Q_FLAGS(x)

#define Q_FOREACH(variable, container)                                \
for (QForeachContainer<__typeof__(container)> _container_(container); \
     !_container_.brk && _container_.i != _container_.e;              \
     __extension__  ({ ++_container_.brk; ++_container_.i; }))                       \
    for (variable = *_container_.i;; __extension__ ({--_container_.brk; break;}))

#define Q_GLOBAL_STATIC_WITH_INITIALIZER(TYPE, NAME, INITIALIZER) \
    static TYPE *NAME()                                           \
    {                                                             \
        static TYPE this_##NAME;                                  \
        static QGlobalStatic<TYPE > global_##NAME(0);             \
        if (!global_##NAME.pointer) {                             \
            TYPE *x = global_##NAME.pointer = &this_##NAME;       \
            INITIALIZER;                                          \
        }                                                         \
        return global_##NAME.pointer;                             \
    }

#define Q_GUI_EXPORT_INLINE inline

#define Q_GUI_EXPORT_STYLE_MAC

#define Q_HASH_DECLARE_INT_NODES(key_type) \
    template <class T> \
    struct QHashDummyNode<key_type, T> { \
        QHashDummyNode *next; \
        union { uint h; key_type key; }; \
\
        inline QHashDummyNode(key_type /* key0 */) {} \
    }; \
\
    template <class T> \
    struct QHashNode<key_type, T> { \
        QHashNode *next; \
        union { uint h; key_type key; }; \
        T value; \
\
        inline QHashNode(key_type /* key0 */) {} \
        inline QHashNode(key_type /* key0 */, const T &value0) : value(value0) {} \
        inline bool same_key(uint h0, key_type) { return h0 == h; } \
    }

#define Q_INT64_C(c) static_cast<long long>(c ## LL)
#define Q_UINT64_C(c) static_cast<unsigned long long>(c ## ULL)

#define Q_INTERFACES(x)

#define Q_SCRIPTABLE
#define Q_INVOKABLE

#define Q_MAEMO5_EXPORT

#define Q_GADGET

#define Q_MEDIA_DECLARE_CONTROL(Class, IId) \
    template <> inline const char *qmediacontrol_iid<Class *>() { return IId; }

#define Q_CANVAS_EXPORT
#define Q_COMPAT_EXPORT
#define Q_CORE_EXPORT
#define Q_DBUS_EXPORT
#define Q_DECLARATIVE_EXPORT
#define Q_GUI_EXPORT
#define Q_MULTIMEDIA_EXPORT
#define Q_NETWORK_EXPORT
#define Q_OPENGL_EXPORT
#define Q_OPENVG_EXPORT
#define Q_SCRIPT_EXPORT
#define Q_SCRIPTTOOLS_EXPORT
#define Q_SQL_EXPORT
#define Q_SVG_EXPORT
#define Q_TEMPLATEDLL
#define Q_XML_EXPORT
#define Q_XMLPATTERNS_EXPORT

#define Q_PRIVATE_PROPERTY(d, text)
#define Q_PRIVATE_SLOT(d, signature)

#define Q_BEARER_EXPORT
#define Q_PUBLISHSUBSCRIBE_EXPORT
#define Q_CONTACTS_EXPORT
#define Q_VERSIT_EXPORT
#define Q_VERSIT_ORGANIZER_EXPORT
#define Q_LOCATION_EXPORT
#define Q_MESSAGING_EXPORT
#define Q_MOBILITYSIMULATOR_EXPORT
#define Q_SENSORS_EXPORT
#define Q_SYSINFO_EXPORT
#define Q_SERVICEFW_EXPORT

#define Q_SCOPED_STATIC_DECLARE(TYPE, NAME)                      \
    static TYPE *NAME();

#define Q_SCOPED_STATIC_DEFINE(TYPE, SCOPE, NAME)              \
    TYPE *SCOPE::NAME()                                          \
    {                                                            \
        static TYPE this_##NAME;                                 \
        static QGlobalStatic<TYPE > global_##NAME(&this_##NAME); \
        return global_##NAME.pointer;                            \
    }

#define Q_SIGNALS protected
#define Q_SLOTS
#define Q_SLOT
#define Q_SIGNAL

#define Q_STANDARD_CALL
#define Q_TEMPLATE_EXTERN extern
#define Q_TESTLIB_EXPORT

#define Q_TYPEID(IFace) QLatin1String(IFace##_iid)

#define QT_TRY try
#define QT_CATCH(A) catch (A)
#define QT_THROW(A) throw A
#define QT_RETHROW throw

#define QT_DEPRECATED
#define QT_DEPRECATED_VARIABLE
#define QT_DEPRECATED_CONSTRUCTOR explicit

#define QT_ENSURE_STACK_ALIGNED_FOR_SSE
#define QT_FASTCALL

#define QT_FORWARD_DECLARE_CLASS(name) \
    QT_BEGIN_NAMESPACE class name; QT_END_NAMESPACE \
    using QT_PREPEND_NAMESPACE(name);

#define QT_FORWARD_DECLARE_STRUCT(name) \
    QT_BEGIN_NAMESPACE struct name; QT_END_NAMESPACE \
    using QT_PREPEND_NAMESPACE(name);

#define QT_MANGLE_NAMESPACE0(x) x
#define QT_MANGLE_NAMESPACE1(a, b) a##_##b
#define QT_MANGLE_NAMESPACE2(a, b) QT_MANGLE_NAMESPACE1(a,b)
#define QT_MANGLE_NAMESPACE(name) QT_MANGLE_NAMESPACE2( \
        QT_MANGLE_NAMESPACE0(name), QT_MANGLE_NAMESPACE0(QT_NAMESPACE))

#define QT_INTERLOCKED_CONCAT_I(prefix, suffix) \
    prefix ## suffix
#define QT_INTERLOCKED_CONCAT(prefix, suffix) \
    QT_INTERLOCKED_CONCAT_I(prefix, suffix)

#define QT_INTERLOCKED_FUNCTION(name) \
    QT_INTERLOCKED_CONCAT( \
        QT_INTERLOCKED_CONCAT(QT_INTERLOCKED_PREFIX, Interlocked), name)

#define QT_INTERLOCKED_VOLATILE volatile
#define QT_INTERLOCKED_REMOVE_VOLATILE(a) a
#define QT_INTERLOCKED_PREFIX
#define QT_INTERLOCKED_PROTOTYPE

#define QT_TYPENAME typename

/////////////////////////////////////////////////////////////////////////////
// #defines for Trolltech's Qt GUI toolkit
/////////////////////////////////////////////////////////////////////////////

#define Q_GUI_EXPORT
#define Q_DECLARE_FLAGS(Flags, Enum)\
typedef QFlags<Enum> Flags;
#define Q_DECLARE_OPERATORS_FOR_FLAGS(Flags) \
inline QFlags<Flags::enum_type> operator|(Flags::enum_type f1, Flags::enum_type f2) \
{ return QFlags<Flags::enum_type>(f1) | f2; } \
inline QFlags<Flags::enum_type> operator|(Flags::enum_type f1, QFlags<Flags::enum_type> f2) \
{ return f2 | f1; }
#undef Q_MOC_RUN

#define Q_EXTERN_C extern "C"
#define Q_PACKED
#define Q_EXPORT
#define Q_CORE_EXPORT
#define Q_DECL_EXPORT
#define Q_CORE_IMPORT
#define Q_DECL_IMPORT
#define Q_GUI_EXPORT Q_DECL_IMPORT
#define Q_SQL_EXPORT Q_DECL_IMPORT
#define Q_NETWORK_EXPORT Q_DECL_IMPORT
#define Q_CANVAS_EXPORT Q_DECL_IMPORT
#define Q_OPENGL_EXPORT Q_DECL_IMPORT
#define Q_XML_EXPORT Q_DECL_IMPORT
#define Q_COMPAT_EXPORT Q_DECL_IMPORT
#define QM_EXPORT_WORKSPACE
#define Q_CLASSINFO( name, value )
#define Q_PROPERTY(x)
#define Q_OVERRIDE(x)
#define Q_ENUMS( x )
#define Q_SETS( x )
#define QT_FASTCALL
#define QT_UI4_EXPORT
#define QT_UILIB_EXPORT
//#define slots
//#define signals protected

#define QT_TR_FUNCTIONS

#define QT_PROP_FUNCTIONS \
    virtual bool qt_property( int id, int f, QVariant* v); \
    static bool qt_static_property( QObject* , int, int, QVariant* );

#define Q_OBJECT							\
public:									\
    virtual QMetaObject *metaObject() const { 				\
         return staticMetaObject();					\
    }									\
    virtual const char *className() const;				\
    virtual void* qt_cast( const char* ); 				\
    virtual bool qt_invoke( int, QUObject* ); 				\
    virtual bool qt_emit( int, QUObject* ); 				\
    QT_PROP_FUNCTIONS							\
    static QMetaObject* staticMetaObject();				\
    QObject* qObject() { return (QObject*)this; } 			\
    QT_TR_FUNCTIONS							\
private:								\
    static QMetaObject *metaObj;

#define Q_OBJECT_FAKE Q_OBJECT

#define Q_DECLARE_TYPEINFO(TYPE, FLAGS) \
template <> \
class QTypeInfo<TYPE> \
{ \
public: \
    enum { \
        isComplex = (((FLAGS) & Q_PRIMITIVE_TYPE) == 0), \
        isStatic = (((FLAGS) & (Q_MOVABLE_TYPE | Q_PRIMITIVE_TYPE)) == 0), \
        isLarge = (sizeof(TYPE)>sizeof(void*)), \
        isPointer = false, \
        isDummy = (((FLAGS) & Q_DUMMY_TYPE) != 0) \
    }; \
    static inline const char *name() { return #TYPE; } \
}

#define Q_GLOBAL_STATIC(TYPE, NAME)                              \
    static TYPE *NAME()                                          \
    {                                                            \
        static TYPE this_##NAME;                                 \
        static QGlobalStatic<TYPE > global_##NAME(&this_##NAME); \
        return global_##NAME.pointer;                            \
    }

#define Q_GLOBAL_STATIC_WITH_ARGS(TYPE, NAME, ARGS)              \
    static TYPE *NAME()                                          \
    {                                                            \
        static TYPE this_##NAME ARGS;                            \
        static QGlobalStatic<TYPE > global_##NAME(&this_##NAME); \
        return global_##NAME.pointer;                            \
    }

#define QT_STATIC_CONST static const
#define QT_STATIC_CONST_IMPL const

#define Q_DECLARE_SHARED(TYPE) \
template <> inline bool qIsDetached<TYPE>(TYPE &t) { return t.isDetached(); }

#define Q_DECLARE_HANDLE(name) typedef HANDLE name

#define QT_FT_EXPORT_VAR( x )  extern x

#define Q_DECLARE_INTERFACE(IFace, IId) \
template <> inline IFace *qobject_cast<IFace *>(QObject *object) \
{ return reinterpret_cast<IFace *>((object ? object->qt_metacast(IId) : 0)); } \
template <> inline IFace *qobject_cast<IFace *>(const QObject *object) \
{ return reinterpret_cast<IFace *>((object ? const_cast<QObject *>(object)->qt_metacast(IId) : 0)); }

#define Q_DECLARE_METATYPE(TYPE) \
template <> \
struct QMetaTypeId< TYPE > \
{ \
    static int qt_metatype_id() \
    { \
       static int id = qRegisterMetaType< TYPE >(#TYPE); \
       return id; \
    } \
};

#define Q_OUTOFLINE_TEMPLATE
#define Q_INLINE_TEMPLATE inline
#define Q_TYPENAME typename

#define Q_DECLARE_PRIVATE(Class) \
    inline Class##Private* d_func() { return reinterpret_cast<Class##Private *>(d_ptr); } \
    inline const Class##Private* d_func() const { return reinterpret_cast<const Class##Private *>(d_ptr); } \
    friend class Class##Private;

#define Q_DECLARE_PUBLIC(Class) \
    inline Class* q_func() { return static_cast<Class *>(q_ptr); } \
    inline const Class* q_func() const { return static_cast<const Class *>(q_ptr); } \
    friend class Class;

#define Q_D(Class) Class##Private * const d = d_func()
#define Q_Q(Class) Class * const q = q_func()

#define QT_TR_NOOP(x) (x)
#define QT_TRANSLATE_NOOP(scope, x) (x)
#define QDOC_PROPERTY(text)

#define Q_DUMMY_COMPARISON_OPERATOR(C) \
    bool operator==(const C&) const { \
        qWarning(#C"::operator==(const "#C"&) was called"); \
        return false; \
    }

#define QT3_SUPPORT 
#define Q_DECL_DEPRECATED
#define Q_DECL_VARIABLE_DEPRECATED
#define Q_DECL_CONSTRUCTOR_DEPRECATED

#define QT_LICENSED_MODULE(x) \
    enum QtValidLicenseFor##x##Module { Licensed##x = true };
#define QT_MODULE(x) \
    typedef QtValidLicenseFor##x##Module Qt##x##Module;

#define Q_CONSTRUCTOR_FUNCTION(AFUNC) \
   static const int AFUNC_init_var = AFUNC();

#define Q_DISABLE_COPY(Class) \
    Class(const Class &); \
    Class &operator=(const Class &);

#define Q_DECLARE_SEQUENTIAL_ITERATOR(C) \
\
template <class T> \
class Q##C##Iterator \
{ \
    typedef typename Q##C<T>::const_iterator const_iterator; \
    Q##C<T> c; \
    const_iterator i; \
public: \
    inline Q##C##Iterator(const Q##C<T> &container) \
        : c(container), i(c.constBegin()) {} \
    inline Q##C##Iterator &operator=(const Q##C<T> &container) \
    { c = container; i = c.constBegin(); return *this; } \
    inline void toFront() { i = c.constBegin(); } \
    inline void toBack() { i = c.constEnd(); } \
    inline bool hasNext() const { return i != c.constEnd(); } \
    inline const T &next() { return *i++; } \
    inline const T &peekNext() const { return *i; } \
    inline bool hasPrevious() const { return i != c.constBegin(); } \
    inline const T &previous() { return *--i; } \
    inline const T &peekPrevious() const { const_iterator p = i; return *--p; } \
    inline bool findNext(const T &t) \
    { while (i != c.constEnd()) if (*i++ == t) return true; return false; } \
    inline bool findPrevious(const T &t) \
    { while (i != c.constBegin()) if (*(--i) == t) return true; \
      return false;  } \
};

#define Q_DECLARE_MUTABLE_SEQUENTIAL_ITERATOR(C) \
\
template <class T> \
class QMutable##C##Iterator \
{ \
    typedef typename Q##C<T>::iterator iterator; \
    Q##C<T> *c; \
    iterator i, n; \
    inline bool item_exists() const { return n != c->constEnd(); } \
public: \
    inline QMutable##C##Iterator(Q##C<T> &container) \
        : c(&container) \
    { c->setSharable(false); i = c->begin(); n = c->end(); } \
    inline ~QMutable##C##Iterator() \
    { c->setSharable(true); } \
    inline QMutable##C##Iterator &operator=(Q##C<T> &container) \
    { c->setSharable(true); c = &container; c->setSharable(false); \
      i = c->begin(); n = c->end(); return *this; } \
    inline void toFront() { i = c->begin(); n = c->end(); } \
    inline void toBack() { i = c->end(); n = i; } \
    inline bool hasNext() const { return c->constEnd() != i; } \
    inline T &next() { n = i++; return *n; } \
    inline T &peekNext() const { return *i; } \
    inline bool hasPrevious() const { return c->constBegin() != i; } \
    inline T &previous() { n = --i; return *n; } \
    inline T &peekPrevious() const { iterator p = i; return *--p; } \
    inline void remove() \
    { if (c->constEnd() != n) { i = c->erase(n); n = c->end(); } } \
    inline void setValue(const T &t) const { if (c->constEnd() != n) *n = t; } \
    inline const T &value() const { Q_ASSERT(item_exists()); return *n; } \
    inline void insert(const T &t) { n = i = c->insert(i, t); ++i; } \
    inline bool findNext(const T &t) \
    { while (c->constEnd() != (n = i)) if (*i++ == t) return true; return false; } \
    inline bool findPrevious(const T &t) \
    { while (c->constBegin() != i) if (*(n = --i) == t) return true; \
      n = c->end(); return false;  } \
};

#define Q_DECLARE_ASSOCIATIVE_ITERATOR(C) \
\
template <class Key, class T> \
class Q##C##Iterator \
{ \
    typedef typename Q##C<Key,T>::const_iterator const_iterator; \
    typedef const_iterator Item; \
    Q##C<Key,T> c; \
    const_iterator i, n; \
    inline bool item_exists() const { return n != c.constEnd(); } \
public: \
    inline Q##C##Iterator(const Q##C<Key,T> &container) \
        : c(container), i(c.constBegin()), n(c.constEnd()) {} \
    inline Q##C##Iterator &operator=(const Q##C<Key,T> &container) \
    { c = container; i = c.constBegin(); n = c.constEnd(); return *this; } \
    inline void toFront() { i = c.constBegin(); n = c.constEnd(); } \
    inline void toBack() { i = c.constEnd(); n = c.constEnd(); } \
    inline bool hasNext() const { return i != c.constEnd(); } \
    inline Item next() { n = i++; return n; } \
    inline Item peekNext() const { return i; } \
    inline bool hasPrevious() const { return i != c.constBegin(); } \
    inline Item previous() { n = --i; return n; } \
    inline Item peekPrevious() const { const_iterator p = i; return --p; } \
    inline const T &value() const { Q_ASSERT(item_exists()); return *n; } \
    inline const Key &key() const { Q_ASSERT(item_exists()); return n.key(); } \
    inline bool findNext(const T &t) \
    { while ((n = i) != c.constEnd()) if (*i++ == t) return true; return false; } \
    inline bool findPrevious(const T &t) \
    { while (i != c.constBegin()) if (*(n = --i) == t) return true; \
      n = c.constEnd(); return false; } \
};

#define Q_DECLARE_MUTABLE_ASSOCIATIVE_ITERATOR(C) \
\
template <class Key, class T> \
class QMutable##C##Iterator \
{ \
    typedef typename Q##C<Key,T>::iterator iterator; \
    typedef iterator Item; \
    Q##C<Key,T> *c; \
    iterator i, n; \
    inline bool item_exists() const { return n != c->constEnd(); } \
public: \
    inline QMutable##C##Iterator(Q##C<Key,T> &container) \
        : c(&container) \
    { c->setSharable(false); i = c->begin(); n = c->end(); } \
    inline ~QMutable##C##Iterator() \
    { c->setSharable(true); } \
    inline QMutable##C##Iterator &operator=(Q##C<Key,T> &container) \
    { c->setSharable(true); c = &container; c->setSharable(false); i = c->begin(); n = c->end(); return *this; } \
    inline void toFront() { i = c->begin(); n = c->end(); } \
    inline void toBack() { i = c->end(); n = c->end(); } \
    inline bool hasNext() const { return i != c->constEnd(); } \
    inline Item next() { n = i++; return n; } \
    inline Item peekNext() const { return i; } \
    inline bool hasPrevious() const { return i != c->constBegin(); } \
    inline Item previous() { n = --i; return n; } \
    inline Item peekPrevious() const { iterator p = i; return --p; } \
    inline void remove() \
    { if (n != c->constEnd()) { i = c->erase(n); n = c->end(); } } \
    inline void setValue(const T &t) { if (n != c->constEnd()) *n = t; } \
    inline const T &value() const { Q_ASSERT(item_exists()); return *n; } \
    inline const Key &key() const { Q_ASSERT(item_exists()); return n.key(); } \
    inline bool findNext(const T &t) \
    { while ((n = i) != c->constEnd()) if (*i++ == t) return true; return false; } \
    inline bool findPrevious(const T &t) \
    { while (i != c->constBegin()) if (*(n = --i) == t) return true; \
      n = c->end(); return false; } \
};

#define FT_DEFINE_SERVICE( name )            \
  typedef struct FT_Service_ ## name ## Rec_ \
    FT_Service_ ## name ## Rec ;             \
  typedef struct FT_Service_ ## name ## Rec_ \
    const * FT_Service_ ## name ;            \
  struct FT_Service_ ## name ## Rec_


/////////////////////////////////////////////////////////////////////////////
// Trolltech freetype library
/////////////////////////////////////////////////////////////////////////////
#define FT_BEGIN_HEADER  extern "C" {
#define FT_END_HEADER  }
#define FT_UNUSED( arg )  ( (arg) = (arg) )
#define FT_BEGIN_STMNT  do {
#define FT_END_STMNT    } while ( 0 )
#define FT_DUMMY_STMNT  FT_BEGIN_STMNT FT_END_STMNT
#define FT_LOCAL( x )      extern "C"  x
#define FT_LOCAL_DEF( x )  extern "C"  x
#define FT_BASE( x )  extern "C"  x
#define FT_BASE_DEF( x )  extern "C"  x
#define FT_EXPORT( x )  extern "C"  x
#define FT_EXPORT_DEF( x )  extern "C"  x
#define FT_EXPORT_VAR( x )  extern "C"  x
#define FT_CALLBACK_DEF( x )  extern "C"  x
#define FT_CALLBACK_TABLE      extern "C"
#define FT_CALLBACK_TABLE_DEF  extern "C"
#define FT_ERR_XCAT( x, y )  x ## y
#define FT_ERR_CAT( x, y )   FT_ERR_XCAT( x, y )
#define FT_ERR_PREFIX  FT_Err_
#define FT_ERRORDEF( e, v, s )  e = v,
#define FT_ERROR_START_LIST     enum {
#define FT_ERROR_END_LIST       FT_ERR_CAT( FT_ERR_PREFIX, Max ) };
#define FT_NOERRORDEF_( e, v, s ) FT_ERRORDEF( FT_ERR_CAT( FT_ERR_PREFIX, e ), v, s )

/////////////////////////////////////////////////////////////////////////////
// Boost library
/////////////////////////////////////////////////////////////////////////////

#undef BOOST_NO_EXPLICIT_FUNCTION_TEMPLATE_ARGUMENTS
#define BOOST_APPEND_EXPLICIT_TEMPLATE_NON_TYPE(t, v)
#define BOOST_APPEND_EXPLICIT_TEMPLATE_NON_TYPE_SPEC(t, v)
#define BOOST_APPEND_EXPLICIT_TEMPLATE_TYPE(t)
#define BOOST_APPEND_EXPLICIT_TEMPLATE_TYPE_SPEC(t)

#define BOOST_ARCHIVE_CUSTOM_IARCHIVE_TYPES portable_binary_iarchive
#define BOOST_ARCHIVE_CUSTOM_OARCHIVE_TYPES portable_binary_oarchive

#define BOOST_ARCHIVE_DECL
#define BOOST_ARCHIVE_DECL(T) T
#define BOOST_ARCHIVE_OR_WARCHIVE_DECL(T) T

#define BOOST_ARG_DEPENDENT_TYPENAME typename

#define BOOST_ASSIGN_PARAMS1(n) BOOST_PP_ENUM_PARAMS(n, class T)
#define BOOST_ASSIGN_PARAMS2(n) BOOST_PP_ENUM_BINARY_PARAMS(n, T, const& t)
#define BOOST_ASSIGN_PARAMS2_NO_REF(n) BOOST_PP_ENUM_BINARY_PARAMS(n,U,u)
#define BOOST_ASSIGN_PARAMS3(n) BOOST_PP_ENUM_PARAMS(n, t)
#define BOOST_ASSIGN_PARAMS4(n) BOOST_PP_ENUM_PARAMS(n, U)

#define BOOST_AUTO_TC_INVOKER(test_name) BOOST_JOIN(test_name,_invoker)

#define BOOST_AUTO_TC_REGISTRAR( test_name )	\
    static boost::unit_test::ut_detail::auto_test_unit_registrar BOOST_JOIN( test_name, _registrar )

#define BOOST_AUTO_TC_UNIQUE_ID(test_name) BOOST_JOIN(test_name,_id)

#define BOOST_AUTO_TEST_CASE( test_name )	\
struct BOOST_AUTO_TC_UNIQUE_ID( test_name ) {};	\
	\
static void test_name();	\
BOOST_AUTO_TC_REGISTRAR( test_name )( BOOST_TEST_CASE( test_name ),	\
    boost::unit_test::ut_detail::auto_tc_exp_fail<	\
        BOOST_AUTO_TC_UNIQUE_ID( test_name )>::value );	\
static void test_name()	\
/**/

#define BOOST_AUTO_TEST_CASE_EXPECTED_FAILURES( test_name, n )	\
struct BOOST_AUTO_TC_UNIQUE_ID( test_name );	\
namespace boost { namespace unit_test { namespace ut_detail {	\
	\
template<>	\
struct auto_tc_exp_fail<BOOST_AUTO_TC_UNIQUE_ID( test_name ) > {	\
    enum { value = n };	\
};	\
	\
}}}	\
/**/

#define BOOST_AUTO_TEST_CASE_TEMPLATE( test_name, type_name, TL )	\
template<typename type_name>	\
void test_name( boost::type<type_name>* );	\
	\
struct BOOST_AUTO_TC_INVOKER( test_name ) {	\
    template<typename TestType>	\
    static void run( boost::type<TestType>* frwrd = 0 );	\
};	\
	\
BOOST_AUTO_TC_REGISTRAR( test_nase )(	\
    boost::unit_test::ut_detail::template_test_case_gen<	\
        BOOST_AUTO_TC_INVOKER( test_name ),TL >(	\
          BOOST_STRINGIZE( test_name ) ) );	\
	\
template<typename type_name>	\
void test_name( boost::type<type_name>* )	\
/**/

#define BOOST_AUTO_TEST_SUITE( suite_name )	\
BOOST_AUTO_TC_REGISTRAR( suite_name )( BOOST_TEST_SUITE(	\
    BOOST_STRINGIZE( suite_name ) ) )	\
/**/

#define BOOST_AUTO_TEST_SUITE_END()	\
BOOST_AUTO_TC_REGISTRAR( BOOST_JOIN( end_suite, __LINE__ ) )( 1 )	\
/**/

#define BOOST_AUTO_UNIT_TEST(f) BOOST_AUTO_TEST_CASE(f)

#define BOOST_HAS_NRVO

#define BOOST_BINARY_OPERATOR( NAME, OP )	\
template <class T, class U, class B = ::boost::detail::empty_base>	\
struct NAME##2 : B	\
{	\
  friend T operator OP( T lhs, const U& rhs );	\
};	\
	\
template <class T, class B = ::boost::detail::empty_base>	\
struct NAME##1 : B	\
{	\
  friend T operator OP( T lhs, const T& rhs );	\
};

#define BOOST_BINARY_OPERATOR_COMMUTATIVE( NAME, OP )	\
template <class T, class U, class B = ::boost::detail::empty_base>	\
struct NAME##2 : B	\
{	\
  friend T operator OP( T lhs, const U& rhs );	\
  friend T operator OP( const U& lhs, T rhs );	\
};	\
	\
template <class T, class B = ::boost::detail::empty_base>	\
struct NAME##1 : B	\
{	\
  friend T operator OP( T lhs, const T& rhs );	\
};

#define BOOST_BINARY_OPERATOR_NON_COMMUTATIVE( NAME, OP )	\
template <class T, class U, class B = ::boost::detail::empty_base>	\
struct NAME##2 : B	\
{	\
  friend T operator OP( T lhs, const U& rhs );	\
};	\
	\
template <class T, class U, class B = ::boost::detail::empty_base>	\
struct BOOST_OPERATOR2_LEFT(NAME) : B	\
{	\
  friend T operator OP( const U& lhs, const T& rhs );	\
};	\
	\
template <class T, class B = ::boost::detail::empty_base>	\
struct NAME##1 : B	\
{	\
  friend T operator OP( T lhs, const T& rhs );	\
};

#define BOOST_BIND bind

#define BOOST_BIND_CC

#define BOOST_BIND_MF_CC

#define BOOST_BIND_MF_NAME(X) X

#define BOOST_BIND_OPERATOR( op, name )	\
struct name	\
{	\
    template<class V, class W> bool operator()(V const & v, W const & w) const;	\
};	\
template<class R, class F, class L, class A2>	\
    bind_t< bool, name, list2< bind_t<R, F, L>, typename add_value<A2>::type > >	\
    operator op (bind_t<R, F, L> const & f, A2 a2);

#define BOOST_BIND_RETURN return

#define BOOST_BIND_ST

#define BOOST_BROKEN_COMPILER_TYPE_TRAITS_SPECIALIZATION(T)

#define BOOST_CATCH(x) catch(x)

#define BOOST_CATCH_END }

#define BOOST_CLASS_EXPORT(T)	\
    BOOST_CLASS_EXPORT_GUID_ARCHIVE_LIST(	\
        T,	\
        BOOST_PP_STRINGIZE(T),	\
        boost::archive::detail::known_archive_types::type	\
    )	\
    /**/

#define BOOST_CLASS_EXPORT_ARCHIVE_LIST(T, ASEQ)	\
    BOOST_CLASS_EXPORT_GUID_ARCHIVE_LIST(T, BOOST_PP_STRINGIZE(T), A)

#define BOOST_CLASS_EXPORT_CHECK(T)	\
    BOOST_STATIC_WARNING(	\
        boost::serialization::type_info_implementation< T >	\
            ::type::is_polymorphic::value	\
    );	\
    /**/

#define BOOST_CLASS_EXPORT_GUID(T, K)	\
    BOOST_CLASS_EXPORT_GUID_ARCHIVE_LIST(	\
        T,	\
        K,	\
        boost::archive::detail::known_archive_types::type	\
    )	\
    /**/

#define BOOST_CLASS_EXPORT_GUID_ARCHIVE_LIST(T, K, ASEQ)	\
    namespace boost {	\
    namespace archive {	\
    namespace detail {	\
    template<>	\
    const guid_initializer< T >	\
        guid_initializer< T >::instance(K);	\
    template	\
    BOOST_DLLEXPORT	\
    std::pair<const export_generator<T, ASEQ> *, const guid_initializer< T > *>	\
    export_archives_invoke<T, ASEQ>(T &, ASEQ &);	\
    } } }	\
    /**/

#define BOOST_CLASS_IMPLEMENTATION(T, E)	\
    namespace boost {	\
    namespace serialization {	\
    template <>	\
    struct implementation_level< T >	\
    {	\
        typedef mpl::integral_c_tag tag;	\
        typedef mpl::int_< E > type;	\
        BOOST_STATIC_CONSTANT(	\
            int,	\
            value = implementation_level::type::value	\
        );	\
    };	\
    }	\
    }
    /**/

#define BOOST_CLASS_REQUIRE(type_var, ns, concept)	\
  typedef void (ns::concept <type_var>::* func##type_var##concept)();	\
  template <func##type_var##concept Tp1_>	\
  struct concept_checking_##type_var##concept { };	\
  typedef concept_checking_##type_var##concept<	\
    BOOST_FPTR ns::concept<type_var>::constraints>	\
    concept_checking_typedef_##type_var##concept

#define BOOST_CLASS_REQUIRE2(type_var1, type_var2, ns, concept)	\
  typedef void (ns::concept <type_var1,type_var2>::*	\
     func##type_var1##type_var2##concept)();	\
  template <func##type_var1##type_var2##concept Tp1_>	\
  struct concept_checking_##type_var1##type_var2##concept { };	\
  typedef concept_checking_##type_var1##type_var2##concept<	\
    BOOST_FPTR ns::concept<type_var1,type_var2>::constraints>	\
    concept_checking_typedef_##type_var1##type_var2##concept

#define BOOST_CLASS_REQUIRE3(tv1, tv2, tv3, ns, concept)	\
  typedef void (ns::concept <tv1,tv2,tv3>::*	\
     func##tv1##tv2##tv3##concept)();	\
  template <func##tv1##tv2##tv3##concept Tp1_>	\
  struct concept_checking_##tv1##tv2##tv3##concept { };	\
  typedef concept_checking_##tv1##tv2##tv3##concept<	\
    BOOST_FPTR ns::concept<tv1,tv2,tv3>::constraints>	\
    concept_checking_typedef_##tv1##tv2##tv3##concept

#define BOOST_CLASS_REQUIRE4(tv1, tv2, tv3, tv4, ns, concept)	\
  typedef void (ns::concept <tv1,tv2,tv3,tv4>::*	\
     func##tv1##tv2##tv3##tv4##concept)();	\
  template <func##tv1##tv2##tv3##tv4##concept Tp1_>	\
  struct concept_checking_##tv1##tv2##tv3##tv4##concept { };	\
  typedef concept_checking_##tv1##tv2##tv3##tv4##concept<	\
    BOOST_FPTR ns::concept<tv1,tv2,tv3,tv4>::constraints>	\
    concept_checking_typedef_##tv1##tv2##tv3##tv4##concept

#define BOOST_CLASS_REQUIRES(type_var, concept)	\
  typedef void (concept <type_var>::* func##type_var##concept)();	\
  template <func##type_var##concept Tp1_>	\
  struct concept_checking_##type_var##concept { };	\
  typedef concept_checking_##type_var##concept<	\
    BOOST_FPTR concept <type_var>::constraints>	\
    concept_checking_typedef_##type_var##concept

#define BOOST_CLASS_REQUIRES2(type_var1, type_var2, concept)	\
  typedef void (concept <type_var1,type_var2>::* func##type_var1##type_var2##concept)();	\
  template <func##type_var1##type_var2##concept Tp1_>	\
  struct concept_checking_##type_var1##type_var2##concept { };	\
  typedef concept_checking_##type_var1##type_var2##concept<	\
    BOOST_FPTR concept <type_var1,type_var2>::constraints>	\
    concept_checking_typedef_##type_var1##type_var2##concept

#define BOOST_CLASS_REQUIRES3(type_var1, type_var2, type_var3, concept)	\
  typedef void (concept <type_var1,type_var2,type_var3>::* func##type_var1##type_var2##type_var3##concept)();	\
  template <func##type_var1##type_var2##type_var3##concept Tp1_>	\
  struct concept_checking_##type_var1##type_var2##type_var3##concept { };	\
  typedef concept_checking_##type_var1##type_var2##type_var3##concept<	\
    BOOST_FPTR concept <type_var1,type_var2,type_var3>::constraints>	\
  concept_checking_typedef_##type_var1##type_var2##type_var3##concept

#define BOOST_CLASS_REQUIRES4(type_var1, type_var2, type_var3, type_var4, concept)	\
  typedef void (concept <type_var1,type_var2,type_var3,type_var4>::* func##type_var1##type_var2##type_var3##type_var4##concept)();	\
  template <func##type_var1##type_var2##type_var3##type_var4##concept Tp1_>	\
  struct concept_checking_##type_var1##type_var2##type_var3##type_var4##concept { };	\
  typedef concept_checking_##type_var1##type_var2##type_var3##type_var4##concept<	\
    BOOST_FPTR concept <type_var1,type_var2,type_var3,type_var4>::constraints>	\
    concept_checking_typedef_##type_var1##type_var2##type_var3##type_var4##concept

#define BOOST_CLASS_TRACKING(T, E)	\
namespace boost {	\
namespace serialization {	\
template<>	\
struct tracking_level< T >	\
{	\
    typedef mpl::integral_c_tag tag;	\
    typedef mpl::int_< E> type;	\
    BOOST_STATIC_CONSTANT(	\
        int,	\
        value = tracking_level::type::value	\
    );	\
    /* tracking for a class  */	\
    BOOST_STATIC_ASSERT((	\
        mpl::greater<	\
            /* that is a prmitive */	\
            implementation_level< T >,	\
            mpl::int_<primitive_type>	\
        >::value	\
    ));	\
};	\
}}

#define BOOST_CLASS_TYPE_INFO(T, ETI)	\
namespace boost {	\
namespace serialization {	\
template<>	\
struct type_info_implementation< T > {	\
    typedef ETI type;	\
};	\
template<>	\
struct type_info_implementation< const T > {	\
    typedef ETI type;	\
};	\
}	\
}	\
/**/

#define BOOST_CLASS_VERSION(T, N)	\
namespace boost {	\
namespace serialization {	\
template<>	\
struct version<T >	\
{	\
    typedef mpl::int_<N> type;	\
    typedef mpl::integral_c_tag tag;	\
    BOOST_STATIC_CONSTANT(unsigned int, value = version::type::value);	\
    /* require that class info saved when versioning is used */	\
    /*	\
    BOOST_STATIC_ASSERT((	\
        mpl::or_<	\
            mpl::equal_to<	\
                mpl::int_<0>,	\
                mpl::int_<N>	\
            >,	\
            mpl::equal_to<	\
                implementation_level<T>,	\
                mpl::int_<object_class_info>	\
            >	\
        >::value	\
    ));	\
    */	\
};	\
}	\
}

#define BOOST_CODECVT_DO_LENGTH_CONST const

#define BOOST_CONFIG_DECL

#define BOOST_CONTAINER_SELECTOR(NAME)	\
  template <> struct container_selector<NAME>  {	\
    typedef NAME type;	\
  }

#define BOOST_CRC_DUMMY_PARM_TYPE
#define BOOST_CRC_DUMMY_INIT
#define BOOST_ACRC_DUMMY_PARM_TYPE
#define BOOST_ACRC_DUMMY_INIT

#define BOOST_CRC_OPTIMAL_NAME crc_optimal<Bits,TruncPoly,InitRem,FinalXor,ReflectIn,ReflectRem>

#define BOOST_CSTD_ std

#define BOOST_DATE_TIME_DECL

#define BOOST_DECL_TRANSFORM_TEST(name, type, from, to) void name();
#define BOOST_DECL_TRANSFORM_TEST3(name, type, from)    void name();
#define BOOST_DECL_TRANSFORM_TEST2(name, type, to)      void name();
#define BOOST_DECL_TRANSFORM_TEST0(name, type)          void name();

#define BOOST_DEDUCED_TYPENAME typename

#define BOOST_DEF_PROPERTY(KIND, NAME)	\
  enum KIND##_##NAME##_t { KIND##_##NAME };	\
  BOOST_INSTALL_PROPERTY(KIND, NAME)

#define BOOST_DEFINE_BINARY_OPERATOR_ARCHETYPE(OP, NAME)	\
  template <class Return, class Base = null_archetype<> >	\
  class NAME##_first_archetype : public Base {	\
  public:	\
    NAME##_first_archetype(detail::dummy_constructor x) : Base(x) { }	\
  };	\
	\
  template <class Return, class Base = null_archetype<> >	\
  class NAME##_second_archetype : public Base {	\
  public:	\
    NAME##_second_archetype(detail::dummy_constructor x) : Base(x) { }	\
  };	\
	\
  template <class Return, class BaseFirst, class BaseSecond>	\
  Return	\
  operator OP (const NAME##_first_archetype<Return, BaseFirst>&,	\
               const NAME##_second_archetype<Return, BaseSecond>&);

#define BOOST_DEFINE_BINARY_OPERATOR_CONSTRAINT(OP,NAME)	\
  template <class Ret, class First, class Second>	\
  struct NAME {	\
    void constraints();	\
    Ret constraints_();
    First a;	\
    Second b;	\
  }

#define BOOST_DEFINE_BINARY_PREDICATE_ARCHETYPE(OP, NAME)	\
  template <class Base = null_archetype<>, class Tag = optag1 >	\
  class NAME##_first_archetype : public Base {	\
  public:	\
    NAME##_first_archetype(detail::dummy_constructor x) : Base(x) { }	\
  };	\
	\
  template <class Base = null_archetype<>, class Tag = optag1 >	\
  class NAME##_second_archetype : public Base {	\
  public:	\
    NAME##_second_archetype(detail::dummy_constructor x) : Base(x) { }	\
  };	\
	\
  template <class BaseFirst, class BaseSecond, class Tag>	\
  boolean_archetype	\
  operator OP (const NAME##_first_archetype<BaseFirst, Tag>&,	\
               const NAME##_second_archetype<BaseSecond, Tag>&);

#define BOOST_DEFINE_BINARY_PREDICATE_OP_CONSTRAINT(OP,NAME)	\
  template <class First, class Second>	\
  struct NAME {	\
    void constraints();	\
    bool constraints_();	\
    First a;	\
    Second b;	\
  }

#define BOOST_DEFINE_INPLACE_FACTORY_CLASS(z,n,_)	\
template< BOOST_PP_ENUM_PARAMS(BOOST_PP_INC(n),class A) >	\
class BOOST_PP_CAT(in_place_factory, BOOST_PP_INC(n) ) : public in_place_factory_base	\
{	\
public:	\
\
  BOOST_PP_CAT(in_place_factory, BOOST_PP_INC(n) ) ( BOOST_PP_ENUM_BINARY_PARAMS(BOOST_PP_INC(n),A,const& a) )	\
    :	\
    BOOST_PP_ENUM( BOOST_PP_INC(n), BOOST_DEFINE_INPLACE_FACTORY_CLASS_MEMBER_INIT, _ )	\
  {}	\
\
  template<class T>	\
  void apply ( void* address BOOST_APPEND_EXPLICIT_TEMPLATE_TYPE(T) ) const;	\
\
  BOOST_PP_REPEAT( BOOST_PP_INC(n), BOOST_DEFINE_INPLACE_FACTORY_CLASS_MEMBER_DECL, _)	\
} ;	\
\
template< BOOST_PP_ENUM_PARAMS(BOOST_PP_INC(n),class A) >	\
BOOST_PP_CAT(in_place_factory, BOOST_PP_INC(n) ) < BOOST_PP_ENUM_PARAMS( BOOST_PP_INC(n), A ) >	\
in_place ( BOOST_PP_ENUM_BINARY_PARAMS(BOOST_PP_INC(n),A, const& a) )	\
;


#define BOOST_DEFINE_INPLACE_FACTORY_CLASS_MEMBER_ARG(z, n, _) BOOST_PP_CAT(m_a,n)

#define BOOST_DEFINE_INPLACE_FACTORY_CLASS_MEMBER_DECL(z, n, _) BOOST_PP_CAT(A,n) const &BOOST_PP_CAT(m_a,n);

#define BOOST_DEFINE_INPLACE_FACTORY_CLASS_MEMBER_INIT(z, n, _) BOOST_PP_CAT(m_a,n) BOOST_PP_LPAREN() BOOST_PP_CAT(a,n) BOOST_PP_RPAREN()

#define BOOST_DEFINE_OPERATOR_ARCHETYPE(OP, NAME)	\
  template <class Base = null_archetype<> >	\
  class NAME##_archetype : public Base {	\
  public:	\
    NAME##_archetype(detail::dummy_constructor x) : Base(x) { }	\
    NAME##_archetype(const NAME##_archetype&)	\
      : Base(static_object<detail::dummy_constructor>::get()) { }	\
    NAME##_archetype& operator=(const NAME##_archetype&);	\
  };	\
  template <class Base>	\
  NAME##_archetype<Base>	\
  operator OP (const NAME##_archetype<Base>&,\
               const NAME##_archetype<Base>&);

#define BOOST_DEFINE_TYPED_INPLACE_FACTORY_CLASS(z,n,_)	\
template< class T, BOOST_PP_ENUM_PARAMS(BOOST_PP_INC(n),class A) >	\
class BOOST_PP_CAT(typed_in_place_factory, BOOST_PP_INC(n) ) : public typed_in_place_factory_base	\
{	\
public:	\
\
  typedef T value_type ;	\
\
  BOOST_PP_CAT(typed_in_place_factory, BOOST_PP_INC(n) ) ( BOOST_PP_ENUM_BINARY_PARAMS(BOOST_PP_INC(n),A,const& a) )	\
    :	\
    BOOST_PP_ENUM( BOOST_PP_INC(n), BOOST_DEFINE_INPLACE_FACTORY_CLASS_MEMBER_INIT, _ )	\
  {}	\
\
  void apply ( void* address ) const	\
  {	\
    new ( address ) T ( BOOST_PP_ENUM_PARAMS( BOOST_PP_INC(n), m_a ) ) ;	\
  }	\
\
  BOOST_PP_REPEAT( BOOST_PP_INC(n), BOOST_DEFINE_INPLACE_FACTORY_CLASS_MEMBER_DECL, _)	\
} ;	\
\
template< class T, BOOST_PP_ENUM_PARAMS(BOOST_PP_INC(n),class A) >	\
BOOST_PP_CAT(typed_in_place_factory, BOOST_PP_INC(n) ) < T , BOOST_PP_ENUM_PARAMS( BOOST_PP_INC(n), A ) >	\
in_place ( BOOST_PP_ENUM_BINARY_PARAMS(BOOST_PP_INC(n),A, const& a) )	\
;	\

#define BOOST_DETAIL_IS_XXX_DEF(name, qualified_name, nargs)	\
template <class T>	\
struct is_##name : mpl::false_	\
{	\
};	\
	\
template < BOOST_PP_ENUM_PARAMS_Z(1, nargs, class T) >	\
struct is_##name<	\
   qualified_name< BOOST_PP_ENUM_PARAMS_Z(1, nargs, T) >	\
>	\
   : mpl::true_	\
{	\
};

#define BOOST_DLLEXPORT

#define BOOST_DO_JOIN(X, Y) BOOST_DO_JOIN2(X,Y)
#define BOOST_DO_JOIN2(X, Y) X##Y
#define BOOST_DO_STRINGIZE(X) #X

#define BOOST_DYNAMIC_BITSET_CTYPE_FACET(ch, name, loc)
#define BOOST_DYNAMIC_BITSET_PRIVATE public
#define BOOST_DYNAMIC_BITSET_PRIVATE private

#define BOOST_EXPLICIT_TEMPLATE_NON_TYPE(t, v)
#define BOOST_EXPLICIT_TEMPLATE_NON_TYPE_SPEC(t, v)
#define BOOST_EXPLICIT_TEMPLATE_TYPE(t)
#define BOOST_EXPLICIT_TEMPLATE_TYPE_SPEC(t)

#define BOOST_FILESYSTEM_DECL

#define BOOST_FIXTURE_TEST_CASE( test_name, F )	\
struct test_name : public F { void test_method(); };	\
	\
void BOOST_AUTO_TC_INVOKER( test_name )();	\
	\
struct BOOST_AUTO_TC_UNIQUE_ID( test_name ) {};	\
	\
BOOST_AUTO_TC_REGISTRAR( test_name )(	\
    boost::unit_test::make_test_case(	\
        &BOOST_AUTO_TC_INVOKER( test_name ), #test_name ),	\
    boost::unit_test::ut_detail::auto_tc_exp_fail<	\
        BOOST_AUTO_TC_UNIQUE_ID( test_name )>::value  );	\
	\
void test_name::test_method()	\
/**/

#define BOOST_FPTR &

#define BOOST_FUNCTION_ARG_TYPE(J,I,D)	\
  typedef BOOST_PP_CAT(T,I) BOOST_PP_CAT(arg, BOOST_PP_CAT(BOOST_PP_INC(I),_type));

#define BOOST_FUNCTION_ARG_TYPES BOOST_PP_REPEAT(BOOST_FUNCTION_NUM_ARGS,BOOST_FUNCTION_ARG_TYPE,BOOST_PP_EMPTY)

#define BOOST_FUNCTION_ARGS BOOST_PP_ENUM_PARAMS(BOOST_FUNCTION_NUM_ARGS,a)

#define BOOST_FUNCTION_COMMA ,

#define BOOST_FUNCTION_ENABLE_IF_NOT_INTEGRAL(Functor,Type)	\
      ::boost::enable_if_c<(::boost::type_traits::ice_not<	\
                   (::boost::is_integral<Functor>::value)>::value),	\
                       Type>::type

#define BOOST_FUNCTION_FUNCTION BOOST_JOIN(function,BOOST_FUNCTION_NUM_ARGS)

#define BOOST_FUNCTION_FUNCTION_INVOKER BOOST_JOIN(function_invoker,BOOST_FUNCTION_NUM_ARGS)

#define BOOST_FUNCTION_FUNCTION_OBJ_INVOKER BOOST_JOIN(function_obj_invoker,BOOST_FUNCTION_NUM_ARGS)

#define BOOST_FUNCTION_GET_FUNCTION_INVOKER BOOST_JOIN(get_function_invoker,BOOST_FUNCTION_NUM_ARGS)

#define BOOST_FUNCTION_GET_FUNCTION_OBJ_INVOKER BOOST_JOIN(get_function_obj_invoker,BOOST_FUNCTION_NUM_ARGS)

#define BOOST_FUNCTION_GET_STATELESS_FUNCTION_OBJ_INVOKER BOOST_JOIN(get_stateless_function_obj_invoker,BOOST_FUNCTION_NUM_ARGS)

#define BOOST_FUNCTION_NUM_ARGS 0

#define BOOST_FUNCTION_PARM(J, I, D) BOOST_PP_CAT(T,I) BOOST_PP_CAT(a,I)

#define BOOST_FUNCTION_PARMS BOOST_PP_ENUM(BOOST_FUNCTION_NUM_ARGS,BOOST_FUNCTION_PARM,BOOST_PP_EMPTY)

#define BOOST_FUNCTION_PARTIAL_SPEC R (void)

#define BOOST_FUNCTION_RETURN(X) X

#define BOOST_FUNCTION_STATELESS_FUNCTION_OBJ_INVOKER BOOST_JOIN(stateless_function_obj_invoker,BOOST_FUNCTION_NUM_ARGS)

#define BOOST_FUNCTION_STATELESS_VOID_FUNCTION_OBJ_INVOKER BOOST_JOIN(stateless_void_function_obj_invoker,BOOST_FUNCTION_NUM_ARGS)

#define BOOST_FUNCTION_TARGET_FIX(x)

#define BOOST_FUNCTION_TEMPLATE_ARGS BOOST_PP_ENUM_PARAMS(BOOST_FUNCTION_NUM_ARGS,T)

#define BOOST_FUNCTION_TEMPLATE_PARMS BOOST_PP_ENUM_PARAMS(BOOST_FUNCTION_NUM_ARGS,typename T)

#define BOOST_FUNCTION_VOID_FUNCTION_INVOKER BOOST_JOIN(void_function_invoker,BOOST_FUNCTION_NUM_ARGS)

#define BOOST_FUNCTION_VOID_FUNCTION_OBJ_INVOKER BOOST_JOIN(void_function_obj_invoker,BOOST_FUNCTION_NUM_ARGS)

#define BOOST_GRAPH_ADAPT_MATRIX_TO_GRAPH(Matrix)	\
namespace boost {	\
  template <>	\
  struct graph_traits< Matrix > {	\
    typedef Matrix::OneD::const_iterator Iter;	\
    typedef Matrix::size_type V;	\
    typedef V vertex_descriptor;	\
    typedef Iter E;	\
    typedef E edge_descriptor;	\
    typedef boost::matrix_incidence_iterator<Iter, V> out_edge_iterator;	\
    typedef boost::matrix_adj_iterator<Iter, V> adjacency_iterator;	\
    typedef Matrix::size_type size_type;	\
    typedef boost::int_iterator<size_type> vertex_iterator;	\
	\
    friend std::pair<vertex_iterator, vertex_iterator>	\
    vertices(const Matrix& g);	\
	\
    friend std::pair<out_edge_iterator, out_edge_iterator>	\
    out_edges(V v, const Matrix& g);	\
    friend std::pair<adjacency_iterator, adjacency_iterator>	\
    adjacent_vertices(V v, const Matrix& g);	\
    friend vertex_descriptor	\
    source(E e, const Matrix& g);	\
    friend vertex_descriptor	\
    target(E e, const Matrix& g);	\
    friend size_type	\
    num_vertices(const Matrix& g);	\
    friend size_type	\
    num_edges(const Matrix& g);	\
    friend size_type	\
    out_degree(V i, const Matrix& g);	\
  };	\
}

#define BOOST_GRAPH_EVENT_STUB(Event,Kind)	\
    typedef ::boost::Event Event##_type;	\
    template<typename Visitor>	\
    Kind##_visitor<std::pair<detail::functor_to_visitor<Event##_type,	\
                                                     Visitor>, Visitors> >	\
    do_##Event(Visitor visitor);

#define BOOST_IMPORT_TEMPLATE1(template_name) using::template_name;
#define BOOST_IMPORT_TEMPLATE2(template_name) using::template_name;
#define BOOST_IMPORT_TEMPLATE3(template_name) using::template_name;
#define BOOST_IMPORT_TEMPLATE4(template_name)

#define BOOST_INSTALL_PROPERTY(KIND, NAME)	\
  template <> struct property_kind<KIND##_##NAME##_t> {	\
    typedef KIND##_property_tag type;	\
  }

#define BOOST_IO_STD std::

#define BOOST_IOS std::ios

#define BOOST_IOS_BASE ::std::ios

#define BOOST_IOSTREAMS_ARRAY(name, mode)	\
    template<typename Ch>	\
    struct BOOST_PP_CAT(basic_, name) : detail::array_adapter<mode, Ch> {	\
    private:	\
        typedef detail::array_adapter<mode, Ch>  base_type;	\
    public:	\
        typedef typename base_type::char_type    char_type;	\
        typedef typename base_type::category     category;	\
        BOOST_PP_CAT(basic_, name)(char_type* begin, char_type* end)	\
            : base_type(begin, end) { }	\
        BOOST_PP_CAT(basic_, name)(char_type* begin, std::size_t length)	\
            : base_type(begin, length) { }	\
        BOOST_PP_CAT(basic_, name)(const char_type* begin, const char_type* end)	\
            : base_type(begin, end) { }	\
        BOOST_PP_CAT(basic_, name)(const char_type* begin, std::size_t length)	\
            : base_type(begin, length) { }	\
        BOOST_IOSTREAMS_ARRAY_CTOR(name, Ch)	\
    };	\
    typedef BOOST_PP_CAT(basic_, name)<char>     name;	\
    typedef BOOST_PP_CAT(basic_, name)<wchar_t>  BOOST_PP_CAT(w, name);	\
    /**/

#define BOOST_IOSTREAMS_ARRAY_CTOR(name, ch)

#define BOOST_IOSTREAMS_BASIC_FILEBUF(Ch) std::filebuf

#define BOOST_IOSTREAMS_BASIC_IFSTREAM(Ch, Tr) std::ifstream

#define BOOST_IOSTREAMS_BASIC_IOS(ch, tr) std::ios

#define BOOST_IOSTREAMS_BASIC_IOSTREAM(ch, tr) std::iostream

#define BOOST_IOSTREAMS_BASIC_ISTREAM(ch, tr) std::istream

#define BOOST_IOSTREAMS_BASIC_OFSTREAM(Ch, Tr) std::ofstream

#define BOOST_IOSTREAMS_BASIC_OSTREAM(ch, tr) std::ostream

#define BOOST_IOSTREAMS_BASIC_STREAMBUF(ch, tr) std::streambuf

#define BOOST_IOSTREAMS_BASIC_STREAMBUF(ch, tr) std::streambuf

#define BOOST_IOSTREAMS_BOOL_TRAIT_DEF(trait, type, arity)	\
    namespace BOOST_PP_CAT(trait, _impl_) {	\
      BOOST_IOSTREAMS_TEMPLATE_PARAMS(arity, T)	\
      type_traits::yes_type helper	\
          (const volatile type BOOST_IOSTREAMS_TEMPLATE_ARGS(arity, T)*);	\
      type_traits::no_type helper(...);	\
      template<typename T>	\
      struct impl {	\
           BOOST_STATIC_CONSTANT(bool, value =	\
           (sizeof(BOOST_IOSTREAMS_TRAIT_NAMESPACE(trait)	\
              helper(static_cast<T*>(0))) ==	\
                sizeof(type_traits::yes_type)));	\
      };	\
    }	\
    template<typename T>	\
    struct trait	\
        : mpl::bool_<BOOST_PP_CAT(trait, _impl_)::impl<T>::value>	\
    { BOOST_MPL_AUX_LAMBDA_SUPPORT(1, trait, (T)) };	\
    /**/

#define BOOST_IOSTREAMS_CHAR_TRAITS(ch) std::char_traits<ch>

#define BOOST_IOSTREAMS_CHARACTER_CLASS(class)	\
    struct BOOST_JOIN(is_, class) {	\
        template<typename Ch>	\
        static bool test(Ch event, const std::locale& loc);	\
    };	\
    /**/

#define BOOST_IOSTREAMS_CODECVT_CV_QUALIFIER const

#define BOOST_IOSTREAMS_CODECVT_SPEC(state)

#define BOOST_IOSTREAMS_CONVERTER_PARAMS ,int buffer_size=-1

#define BOOST_IOSTREAMS_DECL

#define BOOST_IOSTREAMS_DECL_CHAIN(name_, default_char_)	\
    template< typename Mode, typename Ch = default_char_,	\
              typename Tr = BOOST_IOSTREAMS_CHAR_TRAITS(Ch),	\
              typename Alloc = std::allocator<Ch> >	\
    class name_ : public boost::iostreams::detail::chain_base<	\
                            name_<Mode, Ch, Tr, Alloc>,	\
                            Ch, Tr, Alloc, Mode	\
                         >	\
    {	\
    public:	\
        struct category : device_tag, Mode { };	\
        typedef Mode                                   mode;	\
    private:	\
        typedef boost::iostreams::detail::chain_base<	\
                    name_<Mode, Ch, Tr, Alloc>,	\
                    Ch, Tr, Alloc, Mode	\
                >                                      base_type;	\
    public:	\
        typedef Ch                                     char_type;	\
        typedef Tr                                     traits_type;	\
        typedef typename traits_type::int_type         int_type;	\
        typedef typename traits_type::off_type         off_type;	\
        name_();	\
        name_(const name_& rhs);	\
        name_& operator=(const name_& rhs);	\
    };	\
    /**/

#define BOOST_IOSTREAMS_DEFAULT_ARG(arg) arg

#define BOOST_IOSTREAMS_DEFINE_FILTER_STREAM(name_, chain_type_, default_char_)	\
    template< typename Mode,	\
              typename Ch = default_char_,	\
              typename Tr = BOOST_IOSTREAMS_CHAR_TRAITS(Ch),	\
              typename Alloc = std::allocator<Ch>,	\
              typename Access = public_ >	\
    class name_	\
        : public boost::iostreams::detail::filtering_stream_base<	\
                     chain_type_<Mode, Ch, Tr, Alloc>, Access	\
                 >	\
    {	\
    public:	\
        typedef Ch                                char_type;	\
        BOOST_IOSTREAMS_STREAMBUF_TYPEDEFS(Tr)	\
        typedef Mode                              mode;	\
        typedef chain_type_<Mode, Ch, Tr, Alloc>  chain_type;	\
        name_();	\
        BOOST_IOSTREAMS_DEFINE_PUSH_CONSTRUCTOR(name_, mode, Ch, push_impl)	\
        ~name_();	\
            if (this->is_complete())	\
                 this->rdbuf()->BOOST_IOSTREAMS_PUBSYNC();	\
        }	\
    private:	\
        typedef access_control<	\
                    boost::iostreams::detail::chain_client<	\
                        chain_type_<Mode, Ch, Tr, Alloc>	\
                    >,	\
                    Access	\
                > client_type;	\
        template<typename T>	\
        void push_impl(const T& t BOOST_IOSTREAMS_PUSH_PARAMS());	\
    };	\
    /**/

#define BOOST_IOSTREAMS_DEFINE_FILTER_STREAMBUF(name_, chain_type_, default_char_)	\
    template< typename Mode, typename Ch = default_char_,	\
              typename Tr = BOOST_IOSTREAMS_CHAR_TRAITS(Ch),	\
              typename Alloc = std::allocator<Ch>, typename Access = public_ >	\
    class name_ : public boost::iostreams::detail::chainbuf<	\
                             chain_type_<Mode, Ch, Tr, Alloc>, Mode, Access	\
                         >	\
    {	\
    public:	\
        typedef Ch                                             char_type;	\
        BOOST_IOSTREAMS_STREAMBUF_TYPEDEFS(Tr)	\
        typedef Mode                                           mode;	\
        typedef chain_type_<Mode, Ch, Tr, Alloc>               chain_type;	\
        name_();	\
        BOOST_IOSTREAMS_DEFINE_PUSH_CONSTRUCTOR(name_, mode, Ch, push_impl)	\
        ~name_();	\
    };	\
    /**/

#define BOOST_IOSTREAMS_DEFINE_PUSH(name, mode, ch, helper)	\
    BOOST_IOSTREAMS_DEFINE_PUSH_IMPL(name, mode, ch, helper, 1, void)	\
    /**/

#define BOOST_IOSTREAMS_DEFINE_PUSH_CONSTRUCTOR(name, mode, ch, helper)	\
    BOOST_IOSTREAMS_DEFINE_PUSH_IMPL(name, mode, ch, helper, 0, ?)	\
    /**/

#define BOOST_IOSTREAMS_DEFINE_PUSH_IMPL(name, mode, ch, helper, has_return, result)	\
    BOOST_PP_IF(has_return, result, explicit)	\
    name(::std::streambuf& sb BOOST_IOSTREAMS_PUSH_PARAMS());	\
    BOOST_PP_IF(has_return, result, explicit)	\
    name(::std::istream& is BOOST_IOSTREAMS_PUSH_PARAMS());	\
    BOOST_PP_IF(has_return, result, explicit)	\
    name(::std::ostream& os BOOST_IOSTREAMS_PUSH_PARAMS());	\
    BOOST_PP_IF(has_return, result, explicit)	\
    name(::std::iostream& io BOOST_IOSTREAMS_PUSH_PARAMS());	\
    template<typename Iter>	\
    BOOST_PP_IF(has_return, result, explicit)	\
    name(const iterator_range<Iter>& rng BOOST_IOSTREAMS_PUSH_PARAMS());	\
    template<typename Pipeline, typename Concept>	\
    BOOST_PP_IF(has_return, result, explicit)	\
    name(const ::boost::iostreams::pipeline<Pipeline, Concept>& p);	\
    template<typename T>	\
    BOOST_PP_EXPR_IF(has_return, result)	\
    name(const T& t BOOST_IOSTREAMS_PUSH_PARAMS() BOOST_IOSTREAMS_DISABLE_IF_STREAM(T));	\
    /**/

#define BOOST_IOSTREAMS_DISABLE_IF_STREAM(T)
#define BOOST_IOSTREAMS_ENABLE_IF_STREAM(T)

#define BOOST_IOSTREAMS_FAILURE std::ios::failure

#define BOOST_IOSTREAMS_FORWARD(class, impl, policy, params, args)	\
    class(const policy& t params());	\
    class(policy& t params());	\
    class(const ::boost::reference_wrapper<policy>& ref params());	\
    void open(const policy& t params());	\
    void open(policy& t params());	\
    void open(const ::boost::reference_wrapper<policy>& ref params());	\
    BOOST_PP_REPEAT_FROM_TO(	\
        1, BOOST_PP_INC(BOOST_IOSTREAMS_MAX_FORWARDING_ARITY),	\
        BOOST_IOSTREAMS_FORWARDING_CTOR, (class, impl, policy)	\
    )	\
    BOOST_PP_REPEAT_FROM_TO(	\
        1, BOOST_PP_INC(BOOST_IOSTREAMS_MAX_FORWARDING_ARITY),	\
        BOOST_IOSTREAMS_FORWARDING_FN, (class, impl, policy)	\
    )	\
    /**/

#define BOOST_IOSTREAMS_FORWARDING_CTOR(z, n, tuple)	\
    template<BOOST_PP_ENUM_PARAMS_Z(z, n, typename U)>	\
    BOOST_PP_TUPLE_ELEM(3, 0, tuple)	\
    (BOOST_PP_ENUM_BINARY_PARAMS_Z(z, n, const U, &u));	\
    BOOST_IOSTREAMS_FORWARDING_CTOR_I(z, n, tuple)	\
    /**/

#define BOOST_IOSTREAMS_FORWARDING_CTOR_I(z, n, tuple)

#define BOOST_IOSTREAMS_FORWARDING_FN(z, n, tuple)	\
    template<BOOST_PP_ENUM_PARAMS_Z(z, n, typename U)>	\
    void open(BOOST_PP_ENUM_BINARY_PARAMS_Z(z, n, const U, &u));	\
    BOOST_IOSTREAMS_FORWARDING_FN_I(z, n, tuple)	\
    /**/

#define BOOST_IOSTREAMS_FORWARDING_FN_I(z, n, tuple)

#define BOOST_IOSTREAMS_FSM(fsm)	\
    void push(char c);	\
    void push(wchar_t c);	\
    void skip(char c);	\
    void skip(wchar_t c);	\
    /**/

#define BOOST_IOSTREAMS_MODE_HELPER(tag_, id_)	\
    case_<id_> io_mode_impl_helper(tag_);	\
    template<> struct io_mode_impl<id_> { typedef tag_ type; };	\
    /**/

#define BOOST_IOSTREAMS_PIPABLE(filter, arity)	\
    template< BOOST_PP_ENUM_PARAMS(arity, typename T)	\
              BOOST_PP_COMMA_IF(arity) typename Component>	\
    ::boost::iostreams::pipeline<	\
        ::boost::iostreams::detail::pipeline_segment<	\
            filter BOOST_IOSTREAMS_TEMPLATE_ARGS(arity, T)	\
        >,	\
        Component	\
    > operator|( const filter BOOST_IOSTREAMS_TEMPLATE_ARGS(arity, T)& f,	\
                 const Component& c )	\
    {	\
        typedef ::boost::iostreams::detail::pipeline_segment<	\
                    filter BOOST_IOSTREAMS_TEMPLATE_ARGS(arity, T)	\
                > segment;	\
        return ::boost::iostreams::pipeline<segment, Component>	\
                   (segment(f), c);	\
    }	\
    /**/

#define BOOST_IOSTREAMS_PUSH_ARGS ,buffer_size,pback_size

#define BOOST_IOSTREAMS_PUSH_PARAMS ,int buffer_size=-1,int pback_size=-1

#define BOOST_IOSTREAMS_STREAMBUF_TYPEDEFS(Tr)	\
    typedef Tr                              traits_type;	\
    typedef typename traits_type::int_type  int_type;	\
    typedef typename traits_type::off_type  off_type;	\
    typedef typename traits_type::pos_type  pos_type;	\
    /**/

} } // End namespaces iostreams, boost.

#define BOOST_IOSTREAMS_TEMPLATE_ARGS(arity, param)	\
    BOOST_PP_EXPR_IF(arity, <)	\
    BOOST_PP_ENUM_PARAMS(arity, param)	\
    BOOST_PP_EXPR_IF(arity, >)	\
    /**/

#define BOOST_IOSTREAMS_TEMPLATE_PARAMS(arity, param)	\
    BOOST_PP_EXPR_IF(arity, template<)	\
    BOOST_PP_ENUM_PARAMS(arity, typename param)	\
    BOOST_PP_EXPR_IF(arity, >)	\
    /**/

#define BOOST_IOSTREAMS_TRAIT_NAMESPACE(trait)

#define BOOST_IOSTREAMS_USING_PROTECTED_STREAMBUF_MEMBERS(base)	\
    using base::eback; using base::gptr; using base::egptr;	\
    using base::setg; using base::gbump; using base::pbase;	\
    using base::pptr; using base::epptr; using base::setp;	\
    using base::pbump; using base::underflow; using base::pbackfail;	\
    using base::xsgetn; using base::overflow; using base::sputc;	\
    using base::xsputn; using base::sync; using base::seekoff;	\
    using base::seekpos;	\
    /**/

#define BOOST_IS_ABSTRACT(T)	\
namespace boost {	\
namespace serialization {	\
template<>	\
struct is_abstract< T > {	\
    typedef mpl::bool_<true> type;	\
    BOOST_STATIC_CONSTANT(bool, value = true);	\
};	\
}	\
}	\

#define BOOST_ISTREAM std::istream

#define BOOST_ITERATOR_FACADE_INTEROP(op, result_type, return_prefix, base_op)	\
  BOOST_ITERATOR_FACADE_INTEROP_HEAD(inline, op, result_type);

#define BOOST_ITERATOR_FACADE_INTEROP_HEAD(prefix, op, result_type)	\
    template <	\
        class Derived1, class V1, class TC1, class R1, class D1	\
      , class Derived2, class V2, class TC2, class R2, class D2	\
    >	\
    prefix typename detail::enable_if_interoperable<	\
        Derived1, Derived2	\
      , typename mpl::apply2<result_type,Derived1,Derived2>::type	\
    >::type	\
    operator op(	\
        iterator_facade<Derived1, V1, TC1, R1, D1> const& lhs	\
      , iterator_facade<Derived2, V2, TC2, R2, D2> const& rhs)

#define BOOST_ITERATOR_FACADE_PLUS(args)	\
  BOOST_ITERATOR_FACADE_PLUS_HEAD(inline, args);

#define BOOST_ITERATOR_FACADE_PLUS_HEAD(prefix,args)	\
    template <class Derived, class V, class TC, class R, class D>	\
    prefix Derived operator+ args

#define BOOST_ITERATOR_FACADE_RELATION(op)	\
      BOOST_ITERATOR_FACADE_INTEROP_HEAD(friend,op, detail::always_bool2);

#define BOOST_ITERATOR_FACADE_RELATION(op, return_prefix, base_op)	\
  BOOST_ITERATOR_FACADE_INTEROP(	\
      op	\
    , detail::always_bool2	\
    , return_prefix	\
    , base_op	\
  )


#define BOOST_JOIN(X, Y) BOOST_DO_JOIN(X,Y)

#define BOOST_LAMBDA_A_I(z, i, A)	\
   BOOST_PP_COMMA_IF(i) BOOST_PP_CAT(A,i)

#define BOOST_LAMBDA_A_I_B(z, i, T)	\
   BOOST_PP_COMMA_IF(i) BOOST_PP_CAT(BOOST_PP_TUPLE_ELEM(2,0,T),i) BOOST_PP_TUPLE_ELEM(2,1,T)

#define BOOST_LAMBDA_A_I_B_LIST(i, A, B)	\
   BOOST_PP_REPEAT(i,BOOST_LAMBDA_A_I_B, (A,B))

#define BOOST_LAMBDA_A_I_LIST(i, A)	\
   BOOST_PP_REPEAT(i,BOOST_LAMBDA_A_I, A)

#define BOOST_LAMBDA_ARG(z, N, A) BOOST_PP_COMMA_IF(N) A##N

#define BOOST_LAMBDA_ARG_LIST(n, NAME) BOOST_PP_REPEAT(n,BOOST_LAMBDA_ARG,NAME)

#define BOOST_LAMBDA_BE(OPER_NAME, ACTION, CONSTA, CONSTB, CONST_CONVERSION)	\
BOOST_LAMBDA_BE1(OPER_NAME, ACTION, CONSTA, CONSTB, CONST_CONVERSION)	\
BOOST_LAMBDA_BE2(OPER_NAME, ACTION, CONSTA, CONSTB, CONST_CONVERSION)	\
BOOST_LAMBDA_BE3(OPER_NAME, ACTION, CONSTA, CONSTB, CONST_CONVERSION)

#define BOOST_LAMBDA_BE1(OPER_NAME, ACTION, CONSTA, CONSTB, CONVERSION)	\
template<class Arg, class B>	\
inline const	\
lambda_functor<	\
  lambda_functor_base<	\
    ACTION,	\
    tuple<lambda_functor<Arg>, typename CONVERSION <CONSTB>::type>	\
  >	\
>	\
OPER_NAME (const lambda_functor<Arg>& a, CONSTB& b);

#define BOOST_LAMBDA_BE2(OPER_NAME, ACTION, CONSTA, CONSTB, CONVERSION)	\
template<class A, class Arg>	\
inline const	\
lambda_functor<	\
  lambda_functor_base<	\
    ACTION,	\
    tuple<typename CONVERSION <CONSTA>::type, lambda_functor<Arg> >	\
  >	\
>	\
OPER_NAME (CONSTA& a, const lambda_functor<Arg>& b);

#define BOOST_LAMBDA_BE3(OPER_NAME, ACTION, CONSTA, CONSTB, CONVERSION)	\
template<class ArgA, class ArgB>	\
inline const	\
lambda_functor<	\
  lambda_functor_base<	\
    ACTION,	\
    tuple<lambda_functor<ArgA>, lambda_functor<ArgB> >	\
  >	\
>	\
OPER_NAME (const lambda_functor<ArgA>& a, const lambda_functor<ArgB>& b);

#define BOOST_LAMBDA_BINARY_ACTION(SYMBOL, ACTION_CLASS)	\
template<class Args>	\
class lambda_functor_base<ACTION_CLASS, Args> {	\
public:	\
  Args args;	\
public:	\
  explicit lambda_functor_base(const Args& a) : args(a) {}	\
	\
  template<class RET, CALL_TEMPLATE_ARGS>	\
  RET call(CALL_FORMAL_ARGS) const;	\
  template<class SigArgs> struct sig {	\
    typedef typename	\
      detail::binary_rt<ACTION_CLASS, Args, SigArgs>::type type;	\
  };	\
};

#define BOOST_LAMBDA_CLASS(z, N, A) BOOST_PP_COMMA_IF(N) class

#define BOOST_LAMBDA_CLASS_ARG(z, N, A) BOOST_PP_COMMA_IF(N) class A##N

#define BOOST_LAMBDA_CLASS_ARG_LIST(n, NAME) BOOST_PP_REPEAT(n,BOOST_LAMBDA_CLASS_ARG,NAME)

#define BOOST_LAMBDA_CLASS_LIST(n, NAME) BOOST_PP_REPEAT(n,BOOST_LAMBDA_CLASS,NAME)

#define BOOST_LAMBDA_COMMA_OPERATOR_NAME operator,

#define BOOST_LAMBDA_EMPTY

#define BOOST_LAMBDA_HELPER(z, N, A) BOOST_LAMBDA_IS_INSTANCE_OF_TEMPLATE( BOOST_PP_INC(N) )

#define BOOST_LAMBDA_IS_INSTANCE_OF_TEMPLATE(INDEX)	\
	\
namespace detail {	\
	\
template <template<BOOST_LAMBDA_CLASS_LIST(INDEX,T)> class F>	\
struct BOOST_PP_CAT(conversion_tester_,INDEX) {	\
  template<BOOST_LAMBDA_CLASS_ARG_LIST(INDEX,A)>	\
  BOOST_PP_CAT(conversion_tester_,INDEX)	\
    (const F<BOOST_LAMBDA_ARG_LIST(INDEX,A)>&);	\
};	\
	\
} /* end detail */	\
	\
template <class From, template <BOOST_LAMBDA_CLASS_LIST(INDEX,T)> class To>	\
struct BOOST_PP_CAT(is_instance_of_,INDEX)	\
{	\
 private:	\
   typedef ::boost::is_convertible<	\
     From,	\
     BOOST_PP_CAT(detail::conversion_tester_,INDEX)<To>	\
   > helper_type;	\
	\
public:	\
  BOOST_STATIC_CONSTANT(bool, value = helper_type::value);	\
};

#define BOOST_LAMBDA_LAMBDA_FUNCTOR_BASE_FIRST_PART(ARITY)	\
template<class Act, class Args>	\
class lambda_functor_base<action<ARITY, Act>, Args>	\
{	\
public:	\
  Args args;	\
	\
  explicit lambda_functor_base(const Args& a) : args(a) {}	\
	\
  template<class SigArgs> struct sig {	\
    typedef typename	\
    detail::deduce_non_ref_argument_types<Args, SigArgs>::type rets_t;	\
  public:	\
    typedef typename	\
      return_type_N_prot<Act, rets_t>::type type;	\
  };	\
	\
	\
  template<class RET, CALL_TEMPLATE_ARGS>	\
  RET call(CALL_FORMAL_ARGS) const {

#define BOOST_LAMBDA_POSTFIX_UE(OPER_NAME, ACTION)	\
template<class Arg>	\
inline const	\
lambda_functor<lambda_functor_base<ACTION, tuple<lambda_functor<Arg> > > >	\
OPER_NAME (const lambda_functor<Arg>& a, int);	\

#define BOOST_LAMBDA_POSTFIX_UNARY_ACTION(SYMBOL, ACTION_CLASS)	\
template<class Args>	\
class lambda_functor_base<ACTION_CLASS, Args> {	\
public:	\
  Args args;	\
public:	\
  explicit lambda_functor_base(const Args& a) : args(a) {}	\
	\
  template<class RET, CALL_TEMPLATE_ARGS>	\
  RET call(CALL_FORMAL_ARGS) const;	\
  template<class SigArgs> struct sig {	\
    typedef typename	\
      detail::unary_rt<ACTION_CLASS, Args, SigArgs>::type type;	\
  };	\
};

#define BOOST_LAMBDA_PREFIX_UNARY_ACTION(SYMBOL, ACTION_CLASS)	\
template<class Args>	\
class lambda_functor_base<ACTION_CLASS, Args> {	\
public:	\
  Args args;	\
public:	\
  explicit lambda_functor_base(const Args& a) : args(a) {}	\
	\
  template<class RET, CALL_TEMPLATE_ARGS>	\
  RET call(CALL_FORMAL_ARGS) const;	\
  template<class SigArgs> struct sig {	\
    typedef typename	\
      detail::unary_rt<ACTION_CLASS, Args, SigArgs>::type type;	\
  };	\
};

#define BOOST_LAMBDA_PTR_ARITHMETIC_E1(OPER_NAME, ACTION, CONSTB)	\
template<class Arg, int N, class B>	\
inline const	\
lambda_functor<	\
  lambda_functor_base<ACTION, tuple<lambda_functor<Arg>, CONSTB(&)[N]> >	\
>	\
OPER_NAME (const lambda_functor<Arg>& a, CONSTB(&b)[N]);

#define BOOST_LAMBDA_PTR_ARITHMETIC_E2(OPER_NAME, ACTION, CONSTA)	\
template<int N, class A, class Arg>	\
inline const	\
lambda_functor<	\
  lambda_functor_base<ACTION, tuple<CONSTA(&)[N], lambda_functor<Arg> > >	\
>	\
OPER_NAME (CONSTA(&a)[N], const lambda_functor<Arg>& b);

#define BOOST_LAMBDA_SWITCH(N)	\
BOOST_LAMBDA_SWITCH_NO_DEFAULT_CASE(N)	\
BOOST_LAMBDA_SWITCH_WITH_DEFAULT_CASE(N)

#define BOOST_LAMBDA_SWITCH_HELPER(z, N, A)	\
   BOOST_LAMBDA_SWITCH( BOOST_PP_INC(N) )

#define BOOST_LAMBDA_SWITCH_NO_DEFAULT_CASE(N)	\
template<class Args, BOOST_LAMBDA_A_I_LIST(N, int Case)>	\
class	\
lambda_functor_base<	\
      switch_action<BOOST_PP_INC(N),	\
        BOOST_LAMBDA_A_I_B_LIST(N, detail::case_label<Case,>)	\
      >,	\
  Args	\
>	\
{	\
public:	\
  Args args;	\
  template <class SigArgs> struct sig { typedef void type; };	\
public:	\
  explicit lambda_functor_base(const Args& a) : args(a) {}	\
	\
  template<class RET, CALL_TEMPLATE_ARGS>	\
  RET call(CALL_FORMAL_ARGS) const;	\
};

#define BOOST_LAMBDA_SWITCH_STATEMENT(N)	\
template <class TestArg,	\
          BOOST_LAMBDA_A_I_LIST(N, class TagData),	\
          BOOST_LAMBDA_A_I_LIST(N, class Arg)>	\
inline const	\
lambda_functor<	\
  lambda_functor_base<	\
        switch_action<BOOST_PP_INC(N),	\
          BOOST_LAMBDA_A_I_LIST(N, TagData)	\
        >,	\
    tuple<lambda_functor<TestArg>, BOOST_LAMBDA_A_I_LIST(N, Arg)>	\
  >	\
>	\
switch_statement(	\
  const lambda_functor<TestArg>& ta,	\
  HELPER_LIST(N)	\
);	\

#define BOOST_LAMBDA_SWITCH_STATEMENT_HELPER(z, N, A)	\
BOOST_LAMBDA_SWITCH_STATEMENT(BOOST_PP_INC(N))

#define BOOST_LAMBDA_SWITCH_WITH_DEFAULT_CASE(N)	\
template<	\
  class Args BOOST_PP_COMMA_IF(BOOST_PP_DEC(N))	\
  BOOST_LAMBDA_A_I_LIST(BOOST_PP_DEC(N), int Case)	\
>	\
class	\
lambda_functor_base<	\
      switch_action<BOOST_PP_INC(N),	\
        BOOST_LAMBDA_A_I_B_LIST(BOOST_PP_DEC(N),	\
                                detail::case_label<Case, >)	\
        BOOST_PP_COMMA_IF(BOOST_PP_DEC(N))	\
        detail::default_label	\
      >,	\
  Args	\
>	\
{	\
public:	\
  Args args;	\
  template <class SigArgs> struct sig { typedef void type; };	\
public:	\
  explicit lambda_functor_base(const Args& a) : args(a) {}	\
	\
  template<class RET, CALL_TEMPLATE_ARGS>	\
  RET call(CALL_FORMAL_ARGS) const;	\
};

#define BOOST_LAMBDA_UE(OPER_NAME, ACTION)	\
template<class Arg>	\
inline const	\
lambda_functor<lambda_functor_base<ACTION, tuple<lambda_functor<Arg> > > >	\
OPER_NAME (const lambda_functor<Arg>& a);

#define BOOST_LOW_BITS_MASK_SPECIALIZE( Type )	\
  template <  >  struct low_bits_mask_t< std::numeric_limits<Type>::digits >  {	\
      typedef std::numeric_limits<Type>           limits_type;	\
      typedef uint_t<limits_type::digits>::least  least;	\
      typedef uint_t<limits_type::digits>::fast   fast;	\
      BOOST_STATIC_CONSTANT( least, sig_bits = (~( least(0u) )) );	\
      BOOST_STATIC_CONSTANT( fast, sig_bits_fast = fast(sig_bits) );	\
      BOOST_STATIC_CONSTANT( std::size_t, bit_count = limits_type::digits );	\
  }

#define BOOST_MEM_FN_CC
#define BOOST_MEM_FN_CLASS_F
#define BOOST_MEM_FN_NAME(X) inner_##X
#define BOOST_MEM_FN_NAME2(X) inner_##X
#define BOOST_MEM_FN_RETURN return
#define BOOST_MEM_FN_TYPEDEF(X) typedef X;

#define BOOST_MPL_ALGORITM_TRAITS_LAMBDA_SPEC(i, trait)	\
template<> struct trait<void_>	\
{	\
    template< BOOST_MPL_PP_PARAMS(i, typename T) > struct apply	\
    {	\
    };	\
};	\
template<> struct trait<int>	\
{	\
    template< BOOST_MPL_PP_PARAMS(i, typename T) > struct apply	\
    {	\
        typedef int type;	\
    };	\
};	\
/**/

#define BOOST_MPL_ASSERT(pred)	\
enum {	\
    BOOST_PP_CAT(mpl_assertion_in_line_,__LINE__) = sizeof(	\
          boost::mpl::assertion_failed<false>(	\
              boost::mpl::assert_arg( (void (*) pred)0, 1 )	\
            )	\
        )	\
}\
/**/

#define BOOST_MPL_ASSERT_MSG( c, msg, types_ )	\
    struct msg;	\
    typedef struct BOOST_PP_CAT(msg,__LINE__) : boost::mpl::assert_	\
    {	\
        static boost::mpl::failed ************ (msg::************ assert_arg()) types_;	\
    } BOOST_PP_CAT(mpl_assert_arg,__LINE__);	\
    enum {	\
        BOOST_PP_CAT(mpl_assertion_in_line_,__LINE__) = sizeof(	\
            boost::mpl::assertion_failed<(c)>( BOOST_PP_CAT(mpl_assert_arg,__LINE__)::assert_arg() )	\
            )	\
    }\
/**/

#define BOOST_MPL_ASSERT_NOT(pred)	\
enum {	\
    BOOST_PP_CAT(mpl_assertion_in_line_,__LINE__) = sizeof(	\
          boost::mpl::assertion_failed<false>(	\
              boost::mpl::assert_not_arg( (void (*) pred)0, 1 )	\
            )	\
        )	\
}\
/**/

#define BOOST_MPL_ASSERT_RELATION(x, rel, y)	\
enum {	\
      BOOST_PP_CAT(mpl_assertion_in_line_,__LINE__) = sizeof(	\
        boost::mpl::assertion_failed<(x rel y)>(	\
            (boost::mpl::failed ************ ( boost::mpl::assert_relation<	\
                  boost::mpl::assert_::relations( sizeof(	\
                      boost::mpl::assert_::arg rel boost::mpl::assert_::arg	\
                    ) )	\
                , x	\
                , y	\
                >::************)) 0 )	\
        )	\
}	\
/**/

#define BOOST_MPL_AUX_ADL_BARRIER_DECL(type)
#define BOOST_MPL_AUX_ADL_BARRIER_NAMESPACE boost::mpl
#define BOOST_MPL_AUX_ADL_BARRIER_NAMESPACE_CLOSE }}
#define BOOST_MPL_AUX_ADL_BARRIER_NAMESPACE_OPEN namespace boost { namespace mpl {
#define BOOST_MPL_AUX_ARG_ADL_BARRIER_DECL(type)

#define BOOST_MPL_AUX_ARG_TYPEDEF(T, name) typedef T name;

#define BOOST_MPL_AUX_ARITY_SPEC(i, name) BOOST_MPL_AUX_NONTYPE_ARITY_SPEC(i,typename,name)

#define BOOST_MPL_AUX_ASSERT_NOT_NA(x)	\
    BOOST_STATIC_ASSERT(!boost::mpl::is_na<x>::value)	\
/**/

#define BOOST_MPL_AUX_ASSERT_RELATION(x, y, r) assert_relation<x,y,r>

#define BOOST_MPL_AUX_COMMON_NAME_WKND(name)

#define BOOST_MPL_AUX_HAS_XXX_TRAIT_SPEC(trait, T)	\
template<> struct trait<T>	\
{	\
    BOOST_STATIC_CONSTANT(bool, value = false);	\
    typedef boost::mpl::bool_<false> type;	\
};	\
/**/

#define BOOST_MPL_AUX_INSERTER_ALGORITHM_DEF(arity, name)	\
BOOST_MPL_AUX_COMMON_NAME_WKND(name)	\
template<	\
      BOOST_MPL_PP_PARAMS(BOOST_PP_DEC(arity), typename P)	\
    >	\
struct def_##name##_impl	\
    : if_< has_push_back<P1>	\
        , aux::name##_impl<	\
              BOOST_MPL_PP_PARAMS(BOOST_PP_DEC(arity), P)	\
            , back_inserter< typename clear<P1>::type >	\
            >	\
        , aux::reverse_##name##_impl<	\
              BOOST_MPL_PP_PARAMS(BOOST_PP_DEC(arity), P)	\
            , front_inserter< typename clear<P1>::type >	\
            >	\
        >::type	\
{	\
};	\
\
template<	\
      BOOST_MPL_PP_DEFAULT_PARAMS(arity, typename P, na)	\
    >	\
struct name	\
{	\
    typedef typename eval_if<	\
          is_na<BOOST_PP_CAT(P, arity)>	\
        , def_##name##_impl<BOOST_MPL_PP_PARAMS(BOOST_PP_DEC(arity), P)>	\
        , aux::name##_impl<BOOST_MPL_PP_PARAMS(arity, P)>	\
        >::type type;	\
};	\
\
template<	\
      BOOST_MPL_PP_PARAMS(BOOST_PP_DEC(arity), typename P)	\
    >	\
struct def_reverse_##name##_impl	\
    : if_< has_push_back<P1>	\
        , aux::reverse_##name##_impl<	\
              BOOST_MPL_PP_PARAMS(BOOST_PP_DEC(arity), P)	\
            , back_inserter< typename clear<P1>::type >	\
            >	\
        , aux::name##_impl<	\
              BOOST_MPL_PP_PARAMS(BOOST_PP_DEC(arity), P)	\
            , front_inserter< typename clear<P1>::type >	\
            >	\
        >::type	\
{	\
};	\
template<	\
      BOOST_MPL_PP_DEFAULT_PARAMS(arity, typename P, na)	\
    >	\
struct reverse_##name	\
{	\
    typedef typename eval_if<	\
          is_na<BOOST_PP_CAT(P, arity)>	\
        , def_reverse_##name##_impl<BOOST_MPL_PP_PARAMS(BOOST_PP_DEC(arity), P)>	\
        , aux::reverse_##name##_impl<BOOST_MPL_PP_PARAMS(arity, P)>	\
        >::type type;	\
};	\
BOOST_MPL_AUX_NA_SPEC(arity, name)	\
BOOST_MPL_AUX_NA_SPEC(arity, reverse_##name)	\
/**/

#define BOOST_MPL_AUX_LAMBDA_ARITY_PARAM(param)
#define BOOST_MPL_AUX_LAMBDA_SUPPORT(i, name, params)
#define BOOST_MPL_AUX_LAMBDA_SUPPORT_HAS_REBIND(i, name, params)
#define BOOST_MPL_AUX_LAMBDA_SUPPORT_SPEC(i, name, params)

#define BOOST_MPL_AUX_MAP0_OVERLOAD(R, f, X, T)	\
    static R BOOST_PP_CAT(BOOST_MPL_AUX_OVERLOAD_,f)(X const&, T)	\
/**/

#define BOOST_MPL_AUX_MAP_OVERLOAD(R, f, X, T)	\
    BOOST_MPL_AUX_MAP0_OVERLOAD(R, f, X, T);	\
    using Base::BOOST_PP_CAT(BOOST_MPL_AUX_OVERLOAD_,f)	\
/**/

#define BOOST_MPL_AUX_MSVC_VALUE_WKND(C) C

#define BOOST_MPL_AUX_NA_PARAM(param) param=na

#define BOOST_MPL_AUX_NA_PARAMS(i) BOOST_MPL_PP_ENUM(i,na)

#define BOOST_MPL_AUX_NA_SPEC(i, name)	\
BOOST_MPL_AUX_NA_SPEC_NO_ETI(i, name)	\
BOOST_MPL_AUX_NA_SPEC_ETI(i, name)	\
/**/

#define BOOST_MPL_AUX_NA_SPEC2(i, j, name)	\
BOOST_MPL_AUX_NA_SPEC_MAIN(i, name)	\
BOOST_MPL_AUX_NA_SPEC_ETI(i, name)	\
BOOST_MPL_AUX_NA_SPEC_LAMBDA(i, name)	\
BOOST_MPL_AUX_NA_SPEC_ARITY(i, name)	\
BOOST_MPL_AUX_NA_SPEC_TEMPLATE_ARITY(i, j, name)	\
/**/

#define BOOST_MPL_AUX_NA_SPEC_ARITY(i, name)

#define BOOST_MPL_AUX_NA_SPEC_ETI(i, name)

#define BOOST_MPL_AUX_NA_SPEC_LAMBDA(i, name)	\
template< typename Tag >	\
struct lambda<	\
      name< BOOST_MPL_AUX_NA_PARAMS(i) >	\
    , Tag	\
    BOOST_MPL_AUX_LAMBDA_ARITY_PARAM(int_<-1>)	\
    >	\
{	\
    typedef false_ is_le;	\
    typedef name< BOOST_MPL_AUX_NA_PARAMS(i) > result_;	\
    typedef name< BOOST_MPL_AUX_NA_PARAMS(i) > type;	\
};	\
/**/

#define BOOST_MPL_AUX_NA_SPEC_MAIN(i, name)	\
template<>	\
struct name< BOOST_MPL_AUX_NA_PARAMS(i) >	\
{	\
    template<	\
          BOOST_MPL_PP_PARAMS(i, typename T)	\
        BOOST_MPL_PP_NESTED_DEF_PARAMS_TAIL(i, typename T, na)	\
        >	\
    struct apply	\
        : name< BOOST_MPL_PP_PARAMS(i, T) >	\
    {	\
    };	\
};	\
/**/

#define BOOST_MPL_AUX_NA_SPEC_NO_ETI(i, name)	\
BOOST_MPL_AUX_NA_SPEC_MAIN(i, name)	\
BOOST_MPL_AUX_NA_SPEC_LAMBDA(i, name)	\
BOOST_MPL_AUX_NA_SPEC_ARITY(i, name)	\
BOOST_MPL_AUX_NA_SPEC_TEMPLATE_ARITY(i, i, name)	\
/**/

#define BOOST_MPL_AUX_NA_SPEC_TEMPLATE_ARITY(i, j, name)

#define BOOST_MPL_AUX_NESTED_TYPE_WKND(T) T::type

#define BOOST_MPL_AUX_NESTED_VALUE_WKND(T, C) BOOST_MPL_AUX_STATIC_CAST(T,C::value)

#define BOOST_MPL_AUX_NONTYPE_ARITY_SPEC(i, type, name)

#define BOOST_MPL_AUX_NTTP_DECL(T, x) T x

#define BOOST_MPL_AUX_NUMERIC_CAST numeric_cast

#define BOOST_MPL_AUX_OVERLOAD_CALL_IS_MASKED(T, x) BOOST_MPL_AUX_PTR_TO_REF(T)%x

#define BOOST_MPL_AUX_OVERLOAD_CALL_ITEM_BY_ORDER(T, x) BOOST_MPL_AUX_PTR_TO_REF(T)|x

#define BOOST_MPL_AUX_OVERLOAD_CALL_ORDER_BY_KEY(T, x) BOOST_MPL_AUX_PTR_TO_REF(T)||x

#define BOOST_MPL_AUX_OVERLOAD_CALL_VALUE_BY_KEY(T, x) BOOST_MPL_AUX_PTR_TO_REF(T)/x

#define BOOST_MPL_AUX_OVERLOAD_IS_MASKED operator%

#define BOOST_MPL_AUX_OVERLOAD_ITEM_BY_ORDER operator|

#define BOOST_MPL_AUX_OVERLOAD_ORDER_BY_KEY operator||

#define BOOST_MPL_AUX_OVERLOAD_VALUE_BY_KEY operator/

#define BOOST_MPL_AUX_PASS_THROUGH_LAMBDA_SPEC(i, name)

#define BOOST_MPL_AUX_PTR_TO_REF(X) *BOOST_MPL_AUX_STATIC_CAST(X *,0)

#define BOOST_MPL_AUX_SET0_OVERLOAD(R, f, X, T)	\
    friend R BOOST_PP_CAT(BOOST_MPL_AUX_OVERLOAD_,f)(X const&, T)	\
/**/

#define BOOST_MPL_AUX_SET_OVERLOAD(R, f, X, T)	\
    BOOST_MPL_AUX_SET0_OVERLOAD(R, f, X, T)	\
/**/

#define BOOST_MPL_AUX_STATIC_CAST(T, expr) static_cast<T>(expr)

#define BOOST_MPL_AUX_TEMPLATE_ARITY_SPEC(i, name)

#define BOOST_MPL_AUX_VALUE_WKND(C) C

#define BOOST_MPL_HAS_XXX_TRAIT_DEF(name)	\
    BOOST_MPL_HAS_XXX_TRAIT_NAMED_DEF(BOOST_PP_CAT(has_,name), name, false)	\
/**/

#define BOOST_MPL_HAS_XXX_TRAIT_NAMED_DEF(trait, name, default_)	\
template< typename T, typename U = void >	\
struct BOOST_PP_CAT(trait,_impl_)	\
{	\
    BOOST_STATIC_CONSTANT(bool, value = false);	\
    typedef boost::mpl::bool_<value> type;	\
};	\
\
template< typename T >	\
struct BOOST_PP_CAT(trait,_impl_)<	\
      T	\
    , typename boost::mpl::aux::msvc71_sfinae_helper< typename T::name >::type	\
    >	\
{	\
    BOOST_STATIC_CONSTANT(bool, value = true);	\
    typedef boost::mpl::bool_<value> type;	\
};	\
\
template< typename T, typename fallback_ = boost::mpl::bool_<default_> >	\
struct trait	\
    : BOOST_PP_CAT(trait,_impl_)<T>	\
{	\
};	\
/**/

#define BOOST_MPL_LIMIT_METAFUNCTION_ARITY 5

#define BOOST_MPL_PP_ADD(i, j) BOOST_PP_ADD(i,j)
#define BOOST_MPL_PP_ADD_0 (0,1,2,3,4,5,6,7,8,9,10)
#define BOOST_MPL_PP_ADD_1 (1,2,3,4,5,6,7,8,9,10,0)
#define BOOST_MPL_PP_ADD_2 (2,3,4,5,6,7,8,9,10,0,0)
#define BOOST_MPL_PP_ADD_3 (3,4,5,6,7,8,9,10,0,0,0)
#define BOOST_MPL_PP_ADD_4 (4,5,6,7,8,9,10,0,0,0,0)
#define BOOST_MPL_PP_ADD_5 (5,6,7,8,9,10,0,0,0,0,0)
#define BOOST_MPL_PP_ADD_6 (6,7,8,9,10,0,0,0,0,0,0)
#define BOOST_MPL_PP_ADD_7 (7,8,9,10,0,0,0,0,0,0,0)
#define BOOST_MPL_PP_ADD_8 (8,9,10,0,0,0,0,0,0,0,0)
#define BOOST_MPL_PP_ADD_9 (9,10,0,0,0,0,0,0,0,0,0)
#define BOOST_MPL_PP_ADD_10 (10,0,0,0,0,0,0,0,0,0,0)

#define BOOST_MPL_PP_ADD_DELAY(i,j)	\
    BOOST_PP_CAT(BOOST_MPL_PP_TUPLE_11_ELEM_##i,BOOST_MPL_PP_ADD_##j)	\
    /**/

#define BOOST_MPL_PP_AUX_DEFAULT_PARAM_FUNC(unused, i, pv)	\
    BOOST_PP_COMMA_IF(i)	\
    BOOST_PP_CAT( BOOST_PP_TUPLE_ELEM(2,0,pv), BOOST_PP_INC(i) )	\
        = BOOST_PP_TUPLE_ELEM(2,1,pv)	\
    /**/

#define BOOST_MPL_PP_AUX_ENUM_FUNC(unused, i, param)	\
    BOOST_PP_COMMA_IF(i) param	\
    /**/

#define BOOST_MPL_PP_AUX_EXT_PARAM_FUNC(unused, i, op)	\
    BOOST_PP_COMMA_IF(i)	\
    BOOST_PP_CAT(	\
          BOOST_PP_TUPLE_ELEM(2,1,op)	\
        , BOOST_PP_ADD_D(1, i, BOOST_PP_TUPLE_ELEM(2,0,op))	\
        )	\
    /**/

#define BOOST_MPL_PP_AUX_PARAM_FUNC(unused, i, param)	\
    BOOST_PP_COMMA_IF(i)	\
    BOOST_PP_CAT(param, BOOST_PP_INC(i))	\
    /**/

#define BOOST_MPL_PP_AUX_TAIL_PARAM_FUNC(unused, i, op)	\
    , BOOST_PP_CAT(	\
          BOOST_PP_TUPLE_ELEM(3, 1, op)	\
        , BOOST_PP_ADD_D(1, i, BOOST_PP_INC(BOOST_PP_TUPLE_ELEM(3, 0, op)))	\
        ) BOOST_PP_TUPLE_ELEM(3, 2, op)()	\
    /**/

#define BOOST_MPL_PP_DEF_PARAMS_TAIL(i, param, value)	\
    BOOST_MPL_PP_DEF_PARAMS_TAIL_IMPL(i, param, BOOST_PP_IDENTITY(=value))	\
    /**/

#define BOOST_MPL_PP_DEF_PARAMS_TAIL_0(i,p,v) BOOST_MPL_PP_FILTER_PARAMS_##i(p##1 v(),p##2 v(),p##3 v(),p##4 v(),p##5 v(),p##6 v(),p##7 v(),p##8 v(),p##9 v())
#define BOOST_MPL_PP_DEF_PARAMS_TAIL_1(i,p,v) BOOST_MPL_PP_FILTER_PARAMS_##i(p##2 v(),p##3 v(),p##4 v(),p##5 v(),p##6 v(),p##7 v(),p##8 v(),p##9 v(),p1)
#define BOOST_MPL_PP_DEF_PARAMS_TAIL_2(i,p,v) BOOST_MPL_PP_FILTER_PARAMS_##i(p##3 v(),p##4 v(),p##5 v(),p##6 v(),p##7 v(),p##8 v(),p##9 v(),p1,p2)
#define BOOST_MPL_PP_DEF_PARAMS_TAIL_3(i,p,v) BOOST_MPL_PP_FILTER_PARAMS_##i(p##4 v(),p##5 v(),p##6 v(),p##7 v(),p##8 v(),p##9 v(),p1,p2,p3)
#define BOOST_MPL_PP_DEF_PARAMS_TAIL_4(i,p,v) BOOST_MPL_PP_FILTER_PARAMS_##i(p##5 v(),p##6 v(),p##7 v(),p##8 v(),p##9 v(),p1,p2,p3,p4)
#define BOOST_MPL_PP_DEF_PARAMS_TAIL_5(i,p,v) BOOST_MPL_PP_FILTER_PARAMS_##i(p##6 v(),p##7 v(),p##8 v(),p##9 v(),p1,p2,p3,p4,p5)
#define BOOST_MPL_PP_DEF_PARAMS_TAIL_6(i,p,v) BOOST_MPL_PP_FILTER_PARAMS_##i(p##7 v(),p##8 v(),p##9 v(),p1,p2,p3,p4,p5,p6)
#define BOOST_MPL_PP_DEF_PARAMS_TAIL_7(i,p,v) BOOST_MPL_PP_FILTER_PARAMS_##i(p##8 v(),p##9 v(),p1,p2,p3,p4,p5,p6,p7)
#define BOOST_MPL_PP_DEF_PARAMS_TAIL_8(i,p,v) BOOST_MPL_PP_FILTER_PARAMS_##i(p##9 v(),p1,p2,p3,p4,p5,p6,p7,p8)
#define BOOST_MPL_PP_DEF_PARAMS_TAIL_9(i,p,v) BOOST_MPL_PP_FILTER_PARAMS_##i(p1,p2,p3,p4,p5,p6,p7,p8,p9)

#define BOOST_MPL_PP_DEF_PARAMS_TAIL_DELAY_1(i, n, param, value_func)	\
    BOOST_MPL_PP_DEF_PARAMS_TAIL_DELAY_2(i,n,param,value_func)	\
    /**/

#define BOOST_MPL_PP_DEF_PARAMS_TAIL_DELAY_2(i, n, param, value_func)	\
    BOOST_PP_COMMA_IF(BOOST_PP_AND(i,n))	\
    BOOST_MPL_PP_DEF_PARAMS_TAIL_##i(n,param,value_func)	\
    /**/

#define BOOST_MPL_PP_DEF_PARAMS_TAIL_IMPL(i, param, value_func)	\
    BOOST_MPL_PP_DEF_PARAMS_TAIL_DELAY_1(	\
          i	\
        , BOOST_MPL_PP_SUB(BOOST_MPL_LIMIT_METAFUNCTION_ARITY,i)	\
        , param	\
        , value_func	\
        )	\
    /**/

#define BOOST_MPL_PP_DEFAULT_PARAMS(n,p,v)	\
    BOOST_PP_CAT(BOOST_MPL_PP_DEFAULT_PARAMS_,n)(p,v)	\
    /**/

#define BOOST_MPL_PP_DEFAULT_PARAMS_0(p,v)
#define BOOST_MPL_PP_DEFAULT_PARAMS_1(p,v) p##1=v
#define BOOST_MPL_PP_DEFAULT_PARAMS_2(p,v) p##1=v,p##2=v
#define BOOST_MPL_PP_DEFAULT_PARAMS_3(p,v) p##1=v,p##2=v,p##3=v
#define BOOST_MPL_PP_DEFAULT_PARAMS_4(p,v) p##1=v,p##2=v,p##3=v,p##4=v
#define BOOST_MPL_PP_DEFAULT_PARAMS_5(p,v) p##1=v,p##2=v,p##3=v,p##4=v,p##5=v
#define BOOST_MPL_PP_DEFAULT_PARAMS_6(p,v) p##1=v,p##2=v,p##3=v,p##4=v,p##5=v,p##6=v
#define BOOST_MPL_PP_DEFAULT_PARAMS_7(p,v) p##1=v,p##2=v,p##3=v,p##4=v,p##5=v,p##6=v,p##7=v
#define BOOST_MPL_PP_DEFAULT_PARAMS_8(p,v) p##1=v,p##2=v,p##3=v,p##4=v,p##5=v,p##6=v,p##7=v,p##8=v
#define BOOST_MPL_PP_DEFAULT_PARAMS_9(p,v) p##1=v,p##2=v,p##3=v,p##4=v,p##5=v,p##6=v,p##7=v,p##8=v,p##9=v

#define BOOST_MPL_PP_ENUM(n, param)	\
    BOOST_PP_CAT(BOOST_MPL_PP_ENUM_,n)(param)	\
    /**/

#define BOOST_MPL_PP_ENUM_0(p)
#define BOOST_MPL_PP_ENUM_1(p) p
#define BOOST_MPL_PP_ENUM_2(p) p,p
#define BOOST_MPL_PP_ENUM_3(p) p,p,p
#define BOOST_MPL_PP_ENUM_4(p) p,p,p,p
#define BOOST_MPL_PP_ENUM_5(p) p,p,p,p,p
#define BOOST_MPL_PP_ENUM_6(p) p,p,p,p,p,p
#define BOOST_MPL_PP_ENUM_7(p) p,p,p,p,p,p,p
#define BOOST_MPL_PP_ENUM_8(p) p,p,p,p,p,p,p,p
#define BOOST_MPL_PP_ENUM_9(p) p,p,p,p,p,p,p,p,p

#define BOOST_MPL_PP_EXT_PARAMS(i,j,p)	\
    BOOST_MPL_PP_EXT_PARAMS_DELAY_1(i,BOOST_MPL_PP_SUB(j,i),p)	\
    /**/

#define BOOST_MPL_PP_EXT_PARAMS_1(i,p) BOOST_MPL_PP_FILTER_PARAMS_##i(p##1,p##2,p##3,p##4,p##5,p##6,p##7,p##8,p##9)
#define BOOST_MPL_PP_EXT_PARAMS_2(i,p) BOOST_MPL_PP_FILTER_PARAMS_##i(p##2,p##3,p##4,p##5,p##6,p##7,p##8,p##9,p1)
#define BOOST_MPL_PP_EXT_PARAMS_3(i,p) BOOST_MPL_PP_FILTER_PARAMS_##i(p##3,p##4,p##5,p##6,p##7,p##8,p##9,p1,p2)
#define BOOST_MPL_PP_EXT_PARAMS_4(i,p) BOOST_MPL_PP_FILTER_PARAMS_##i(p##4,p##5,p##6,p##7,p##8,p##9,p1,p2,p3)
#define BOOST_MPL_PP_EXT_PARAMS_5(i,p) BOOST_MPL_PP_FILTER_PARAMS_##i(p##5,p##6,p##7,p##8,p##9,p1,p2,p3,p4)
#define BOOST_MPL_PP_EXT_PARAMS_6(i,p) BOOST_MPL_PP_FILTER_PARAMS_##i(p##6,p##7,p##8,p##9,p1,p2,p3,p4,p5)
#define BOOST_MPL_PP_EXT_PARAMS_7(i,p) BOOST_MPL_PP_FILTER_PARAMS_##i(p##7,p##8,p##9,p1,p2,p3,p4,p5,p6)
#define BOOST_MPL_PP_EXT_PARAMS_8(i,p) BOOST_MPL_PP_FILTER_PARAMS_##i(p##8,p##9,p1,p2,p3,p4,p5,p6,p7)
#define BOOST_MPL_PP_EXT_PARAMS_9(i,p) BOOST_MPL_PP_FILTER_PARAMS_##i(p##9,p1,p2,p3,p4,p5,p6,p7,p8)

#define BOOST_MPL_PP_EXT_PARAMS_DELAY_1(i,n,p)	\
    BOOST_MPL_PP_EXT_PARAMS_DELAY_2(i,n,p)	\
    /**/

#define BOOST_MPL_PP_EXT_PARAMS_DELAY_2(i,n,p)	\
    BOOST_MPL_PP_EXT_PARAMS_##i(n,p)	\
    /**/

#define BOOST_MPL_PP_FILTER_PARAMS_0(p1,p2,p3,p4,p5,p6,p7,p8,p9)
#define BOOST_MPL_PP_FILTER_PARAMS_1(p1,p2,p3,p4,p5,p6,p7,p8,p9) p1
#define BOOST_MPL_PP_FILTER_PARAMS_2(p1,p2,p3,p4,p5,p6,p7,p8,p9) p1,p2
#define BOOST_MPL_PP_FILTER_PARAMS_3(p1,p2,p3,p4,p5,p6,p7,p8,p9) p1,p2,p3
#define BOOST_MPL_PP_FILTER_PARAMS_4(p1,p2,p3,p4,p5,p6,p7,p8,p9) p1,p2,p3,p4
#define BOOST_MPL_PP_FILTER_PARAMS_5(p1,p2,p3,p4,p5,p6,p7,p8,p9) p1,p2,p3,p4,p5
#define BOOST_MPL_PP_FILTER_PARAMS_6(p1,p2,p3,p4,p5,p6,p7,p8,p9) p1,p2,p3,p4,p5,p6
#define BOOST_MPL_PP_FILTER_PARAMS_7(p1,p2,p3,p4,p5,p6,p7,p8,p9) p1,p2,p3,p4,p5,p6,p7
#define BOOST_MPL_PP_FILTER_PARAMS_8(p1,p2,p3,p4,p5,p6,p7,p8,p9) p1,p2,p3,p4,p5,p6,p7,p8
#define BOOST_MPL_PP_FILTER_PARAMS_9(p1,p2,p3,p4,p5,p6,p7,p8,p9) p1,p2,p3,p4,p5,p6,p7,p8,p9

#define BOOST_MPL_PP_IS_SEQ(seq) BOOST_MPL_PP_IS_SEQ_(seq)
#define BOOST_MPL_PP_IS_SEQ_(seq) BOOST_PP_CAT(BOOST_MPL_PP_IS_SEQ_, BOOST_MPL_PP_IS_SEQ_0 seq BOOST_PP_RPAREN())
#define BOOST_MPL_PP_IS_SEQ_0(x) BOOST_MPL_PP_IS_SEQ_1(x
#define BOOST_MPL_PP_IS_SEQ_ALWAYS_0(unused) 0
#define BOOST_MPL_PP_IS_SEQ_BOOST_MPL_PP_IS_SEQ_0 BOOST_MPL_PP_IS_SEQ_ALWAYS_0(
#define BOOST_MPL_PP_IS_SEQ_BOOST_MPL_PP_IS_SEQ_1(unused) 1
#define BOOST_MPL_PP_IS_SEQ_SEQ_(x) (x)
#define BOOST_MPL_PP_IS_SEQ_SPLIT_(unused) unused)((unused)

#define BOOST_MPL_PP_NESTED_DEF_PARAMS_TAIL(i, param, value)	\
    BOOST_MPL_PP_DEF_PARAMS_TAIL_IMPL(i, param, BOOST_PP_EMPTY)	\
    /**/

#define BOOST_MPL_PP_PARAMS(n,p)	\
    BOOST_PP_CAT(BOOST_MPL_PP_PARAMS_,n)(p)	\
    /**/

#define BOOST_MPL_PP_PARAMS_0(p)
#define BOOST_MPL_PP_PARAMS_1(p) p##1
#define BOOST_MPL_PP_PARAMS_2(p) p##1,p##2
#define BOOST_MPL_PP_PARAMS_3(p) p##1,p##2,p##3
#define BOOST_MPL_PP_PARAMS_4(p) p##1,p##2,p##3,p##4
#define BOOST_MPL_PP_PARAMS_5(p) p##1,p##2,p##3,p##4,p##5
#define BOOST_MPL_PP_PARAMS_6(p) p##1,p##2,p##3,p##4,p##5,p##6
#define BOOST_MPL_PP_PARAMS_7(p) p##1,p##2,p##3,p##4,p##5,p##6,p##7
#define BOOST_MPL_PP_PARAMS_8(p) p##1,p##2,p##3,p##4,p##5,p##6,p##7,p##8
#define BOOST_MPL_PP_PARAMS_9(p) p##1,p##2,p##3,p##4,p##5,p##6,p##7,p##8,p##9

#define BOOST_MPL_PP_PARTIAL_SPEC_PARAMS(n, param, def)	\
BOOST_MPL_PP_PARAMS(n, param)	\
BOOST_PP_COMMA_IF(BOOST_MPL_PP_SUB(BOOST_MPL_LIMIT_METAFUNCTION_ARITY,n))	\
BOOST_MPL_PP_ENUM(	\
      BOOST_MPL_PP_SUB(BOOST_MPL_LIMIT_METAFUNCTION_ARITY,n)	\
    , def	\
    )	\
/**/

#define BOOST_MPL_PP_RANGE(first, length)	\
    BOOST_PP_SEQ_SUBSEQ((0)(1)(2)(3)(4)(5)(6)(7)(8)(9), first, length)	\
/**/

#define BOOST_MPL_PP_REPEAT(n,f,param)	\
    BOOST_PP_CAT(BOOST_MPL_PP_REPEAT_,n)(f,param)	\
    /**/

#define BOOST_MPL_PP_REPEAT_0(f,p)
#define BOOST_MPL_PP_REPEAT_1(f,p) f(0,0,p)
#define BOOST_MPL_PP_REPEAT_2(f,p) f(0,0,p) f(0,1,p)
#define BOOST_MPL_PP_REPEAT_3(f,p) f(0,0,p) f(0,1,p) f(0,2,p)
#define BOOST_MPL_PP_REPEAT_4(f,p) f(0,0,p) f(0,1,p) f(0,2,p) f(0,3,p)
#define BOOST_MPL_PP_REPEAT_5(f,p) f(0,0,p) f(0,1,p) f(0,2,p) f(0,3,p) f(0,4,p)
#define BOOST_MPL_PP_REPEAT_6(f,p) f(0,0,p) f(0,1,p) f(0,2,p) f(0,3,p) f(0,4,p) f(0,5,p)
#define BOOST_MPL_PP_REPEAT_7(f,p) f(0,0,p) f(0,1,p) f(0,2,p) f(0,3,p) f(0,4,p) f(0,5,p) f(0,6,p)
#define BOOST_MPL_PP_REPEAT_8(f,p) f(0,0,p) f(0,1,p) f(0,2,p) f(0,3,p) f(0,4,p) f(0,5,p) f(0,6,p) f(0,7,p)
#define BOOST_MPL_PP_REPEAT_9(f,p) f(0,0,p) f(0,1,p) f(0,2,p) f(0,3,p) f(0,4,p) f(0,5,p) f(0,6,p) f(0,7,p) f(0,8,p)
#define BOOST_MPL_PP_REPEAT_10(f,p) f(0,0,p) f(0,1,p) f(0,2,p) f(0,3,p) f(0,4,p) f(0,5,p) f(0,6,p) f(0,7,p) f(0,8,p) f(0,9,p)

#define BOOST_MPL_PP_REPEAT_IDENTITY_FUNC(unused1, unused2, x) x

#define BOOST_MPL_PP_SUB(i,j)	\
    BOOST_MPL_PP_SUB_DELAY(i,j)	\
    /**/

#define BOOST_MPL_PP_SUB_0 (0,1,2,3,4,5,6,7,8,9,10)
#define BOOST_MPL_PP_SUB_1 (0,0,1,2,3,4,5,6,7,8,9)
#define BOOST_MPL_PP_SUB_2 (0,0,0,1,2,3,4,5,6,7,8)
#define BOOST_MPL_PP_SUB_3 (0,0,0,0,1,2,3,4,5,6,7)
#define BOOST_MPL_PP_SUB_4 (0,0,0,0,0,1,2,3,4,5,6)
#define BOOST_MPL_PP_SUB_5 (0,0,0,0,0,0,1,2,3,4,5)
#define BOOST_MPL_PP_SUB_6 (0,0,0,0,0,0,0,1,2,3,4)
#define BOOST_MPL_PP_SUB_7 (0,0,0,0,0,0,0,0,1,2,3)
#define BOOST_MPL_PP_SUB_8 (0,0,0,0,0,0,0,0,0,1,2)
#define BOOST_MPL_PP_SUB_9 (0,0,0,0,0,0,0,0,0,0,1)
#define BOOST_MPL_PP_SUB_10 (0,0,0,0,0,0,0,0,0,0,0)

#define BOOST_MPL_PP_SUB_DELAY(i,j)	\
    BOOST_MPL_PP_TUPLE_11_ELEM_##i BOOST_MPL_PP_SUB_##j	\
    /**/

#define BOOST_MPL_PP_TUPLE_11_ELEM_0(e0, e1, e2, e3, e4, e5, e6, e7, e8, e9, e10) e0
#define BOOST_MPL_PP_TUPLE_11_ELEM_1(e0, e1, e2, e3, e4, e5, e6, e7, e8, e9, e10) e1
#define BOOST_MPL_PP_TUPLE_11_ELEM_2(e0, e1, e2, e3, e4, e5, e6, e7, e8, e9, e10) e2
#define BOOST_MPL_PP_TUPLE_11_ELEM_3(e0, e1, e2, e3, e4, e5, e6, e7, e8, e9, e10) e3
#define BOOST_MPL_PP_TUPLE_11_ELEM_4(e0, e1, e2, e3, e4, e5, e6, e7, e8, e9, e10) e4
#define BOOST_MPL_PP_TUPLE_11_ELEM_5(e0, e1, e2, e3, e4, e5, e6, e7, e8, e9, e10) e5
#define BOOST_MPL_PP_TUPLE_11_ELEM_6(e0, e1, e2, e3, e4, e5, e6, e7, e8, e9, e10) e6
#define BOOST_MPL_PP_TUPLE_11_ELEM_7(e0, e1, e2, e3, e4, e5, e6, e7, e8, e9, e10) e7
#define BOOST_MPL_PP_TUPLE_11_ELEM_8(e0, e1, e2, e3, e4, e5, e6, e7, e8, e9, e10) e8
#define BOOST_MPL_PP_TUPLE_11_ELEM_9(e0, e1, e2, e3, e4, e5, e6, e7, e8, e9, e10) e9
#define BOOST_MPL_PP_TUPLE_11_ELEM_10(e0, e1, e2, e3, e4, e5, e6, e7, e8, e9, e10) e10

#define BOOST_MSVC_TYPENAME typename

#define BOOST_MULTI_INDEX_CK_APPLY_METAFUNCTION_N(z,n,list)	\
  BOOST_DEDUCED_TYPENAME BOOST_PP_LIST_AT(list,0)<	\
    BOOST_PP_LIST_AT(list,1),n	\
  >::type

#define BOOST_MULTI_INDEX_CK_COMPLETE_COMP_OPS(t1,t2,a1,a2)	\
template<t1,t2> inline bool operator!=(const a1& x,const a2& y);	\
template<t1,t2> inline bool operator>(const a1& x,const a2& y);	\
template<t1,t2> inline bool operator>=(const a1& x,const a2& y);	\
template<t1,t2> inline bool operator<=(const a1& x,const a2& y);

#define BOOST_MULTI_INDEX_CK_CTOR_ARG(z,n,text)	\
  const BOOST_PP_CAT(text,n)& BOOST_PP_CAT(k,n) = BOOST_PP_CAT(text,n)()

#define BOOST_MULTI_INDEX_CK_ENUM(macro,data)	\
  BOOST_PP_ENUM(BOOST_MULTI_INDEX_COMPOSITE_KEY_SIZE,macro,data)

#define BOOST_MULTI_INDEX_CK_ENUM_PARAMS(param)	\
  BOOST_PP_ENUM_PARAMS(BOOST_MULTI_INDEX_COMPOSITE_KEY_SIZE,param)

#define BOOST_MULTI_INDEX_CK_IDENTITY_ENUM_MACRO(z, n, text) text

#define BOOST_MULTI_INDEX_CK_NTH_COMPOSITE_KEY_FUNCTOR(name,functor)	\
template<typename KeyFromValue>	\
struct BOOST_PP_CAT(key_,name)	\
{	\
  typedef functor<typename KeyFromValue::result_type> type;	\
};	\
	\
template<>	\
struct BOOST_PP_CAT(key_,name)<tuples::null_type>	\
{	\
  typedef tuples::null_type type;	\
};	\
	\
template<typename CompositeKey,BOOST_MPL_AUX_NTTP_DECL(int, N)>	\
struct BOOST_PP_CAT(nth_composite_key_,name)	\
{	\
  typedef typename nth_key_from_value<CompositeKey,N>::type key_from_value;	\
  typedef typename BOOST_PP_CAT(key_,name)<key_from_value>::type type;	\
};

#define BOOST_MULTI_INDEX_CK_RESULT_EQUAL_TO_SUPER	\
composite_key_equal_to<	\
    BOOST_MULTI_INDEX_CK_ENUM(	\
      BOOST_MULTI_INDEX_CK_APPLY_METAFUNCTION_N,	\
      /* the argument is a PP list */	\
      (detail::nth_composite_key_equal_to,	\
        (BOOST_DEDUCED_TYPENAME CompositeKeyResult::composite_key_type,	\
          BOOST_PP_NIL)))	\
  >

#define BOOST_MULTI_INDEX_CK_RESULT_GREATER_SUPER	\
composite_key_compare<	\
    BOOST_MULTI_INDEX_CK_ENUM(	\
      BOOST_MULTI_INDEX_CK_APPLY_METAFUNCTION_N,	\
      /* the argument is a PP list */	\
      (detail::nth_composite_key_greater,	\
        (BOOST_DEDUCED_TYPENAME CompositeKeyResult::composite_key_type,	\
          BOOST_PP_NIL)))	\
  >

#define BOOST_MULTI_INDEX_CK_RESULT_HASH_SUPER	\
composite_key_hash<	\
    BOOST_MULTI_INDEX_CK_ENUM(	\
      BOOST_MULTI_INDEX_CK_APPLY_METAFUNCTION_N,	\
      /* the argument is a PP list */	\
      (detail::nth_composite_key_hash,	\
        (BOOST_DEDUCED_TYPENAME CompositeKeyResult::composite_key_type,	\
          BOOST_PP_NIL)))	\
  >

#define BOOST_MULTI_INDEX_CK_RESULT_LESS_SUPER	\
composite_key_compare<	\
    BOOST_MULTI_INDEX_CK_ENUM(	\
      BOOST_MULTI_INDEX_CK_APPLY_METAFUNCTION_N,	\
      /* the argument is a PP list */	\
      (detail::nth_composite_key_less,	\
        (BOOST_DEDUCED_TYPENAME CompositeKeyResult::composite_key_type,	\
          BOOST_PP_NIL)))	\
  >

#define BOOST_MULTI_INDEX_CK_TEMPLATE_PARM(z,n,text)	\
   typename BOOST_PP_CAT(text,n) BOOST_PP_EXPR_IF(n,=tuples::null_type)

#define BOOST_MULTI_INDEX_CONST_MEM_FUN(Class,Type,MemberFunName)	\
   ::boost::multi_index::const_mem_fun<Class,Type,&Class::MemberFunName>

#define BOOST_MULTI_INDEX_HASHED_INDEX_CHECK_INVARIANT

#define BOOST_MULTI_INDEX_INDEXED_BY_TEMPLATE_PARM(z,n,var)	\
   typename BOOST_PP_CAT(var,n) BOOST_PP_EXPR_IF(n,=mpl::na)

#define BOOST_MULTI_INDEX_MEM_FUN(Class,Type,MemberFunName)	\
   ::boost::multi_index::mem_fun<Class,Type,&Class::MemberFunName>

#define BOOST_MULTI_INDEX_MEMBER(Class,Type,MemberName)	\
   ::boost::multi_index::member<Class,Type,&Class::MemberName>

#define BOOST_MULTI_INDEX_ORD_INDEX_CHECK_INVARIANT
#define BOOST_MULTI_INDEX_PRIVATE_IF_MEMBER_TEMPLATE_FRIENDS private
#define BOOST_MULTI_INDEX_PRIVATE_IF_USING_DECL_FOR_TEMPL_FUNCTIONS private
#define BOOST_MULTI_INDEX_PROTECTED_IF_MEMBER_TEMPLATE_FRIENDS protected

#define BOOST_NAMED_TEMPLATE_PARAM(TYPE)	\
    struct get_##TYPE##_from_named {	\
      template <class Base, class NamedParams, class Traits>	\
      struct select {	\
          typedef typename NamedParams::traits NamedTraits;	\
          typedef typename NamedTraits::TYPE TYPE;	\
          typedef typename resolve_default<TYPE,	\
            default_##TYPE, Base, NamedTraits>::type type;	\
      };	\
    };	\
    struct pass_thru_##TYPE {	\
      template <class Base, class Arg, class Traits> struct select {	\
          typedef typename resolve_default<Arg,	\
            default_##TYPE, Base, Traits>::type type;	\
      };\
    };	\
    template <int NamedParam>	\
    struct get_##TYPE##_dispatch { };	\
    template <> struct get_##TYPE##_dispatch<1> {	\
      typedef get_##TYPE##_from_named type;	\
    };	\
    template <> struct get_##TYPE##_dispatch<0> {	\
      typedef pass_thru_##TYPE type;	\
    };	\
    template <class Base, class X, class Traits>	\
    class get_##TYPE {	\
      enum { is_named = is_named_param_list<X>::value };	\
      typedef typename get_##TYPE##_dispatch<is_named>::type Selector;	\
    public:	\
      typedef typename Selector::template select<Base, X, Traits>::type type;	\
    };	\
    template <> struct default_generator<default_##TYPE> {	\
      typedef default_##TYPE type;	\
    }

#define BOOST_NESTED_TEMPLATE template

#define BOOST_NUMERIC_INTERVAL_new_func(f)	\
    T f##_down(const T& x);	\
    T f##_up  (const T& x);

#define BOOST_NUMERIC_INTERVAL_using_ahyp(a) using std::a

#define BOOST_NUMERIC_INTERVAL_using_math(a) using std::a

#define BOOST_NUMERIC_INTERVAL_using_max(a) using std::a

#define BOOST_OCTONION_ACCESSOR_GENERATOR(type)	\
            type                        real() const;	\
            octonion<type>                unreal() const;	\
            type                            R_component_1() const;	\
            type                            R_component_2() const;	\
            type                            R_component_3() const;	\
            type                            R_component_4() const;	\
            type                            R_component_5() const;	\
            type                            R_component_6() const;	\
            type                            R_component_7() const;	\
            type                            R_component_8() const;	\
            ::std::complex<type>            C_component_1() const;	\
            ::std::complex<type>            C_component_2() const;	\
            ::std::complex<type>            C_component_3() const;	\
            ::std::complex<type>            C_component_4() const;	\
            ::boost::math::quaternion<type>    H_component_1() const;	\
            ::boost::math::quaternion<type>    H_component_2() const;

#define BOOST_OCTONION_CONSTRUCTOR_GENERATOR(type)	\
            explicit                    octonion(   type const & requested_a = static_cast<type>(0),	\
                                                    type const & requested_b = static_cast<type>(0),	\
                                                    type const & requested_c = static_cast<type>(0),	\
                                                    type const & requested_d = static_cast<type>(0),	\
                                                    type const & requested_e = static_cast<type>(0),	\
                                                    type const & requested_f = static_cast<type>(0),	\
                                                    type const & requested_g = static_cast<type>(0),	\
                                                    type const & requested_h = static_cast<type>(0))	\
            :   a(requested_a),	\
                b(requested_b),	\
                c(requested_c),	\
                d(requested_d),	\
                e(requested_e),	\
                f(requested_f),	\
                g(requested_g),	\
                h(requested_h)	\
            {	\
            }	\
	\
            explicit                    octonion(   ::std::complex<type> const & z0,	\
                                                    ::std::complex<type> const & z1 = ::std::complex<type>(),	\
                                                    ::std::complex<type> const & z2 = ::std::complex<type>(),	\
                                                    ::std::complex<type> const & z3 = ::std::complex<type>())	\
            :   a(z0.real()),	\
                b(z0.imag()),	\
                c(z1.real()),	\
                d(z1.imag()),	\
                e(z2.real()),	\
                f(z2.imag()),	\
                g(z3.real()),	\
                h(z3.imag())	\
            {	\
            }	\
	\
            explicit                    octonion(   ::boost::math::quaternion<type> const & q0,	\
                                                    ::boost::math::quaternion<type> const & q1 = ::boost::math::quaternion<type>())	\
            :   a(q0.R_component_1()),	\
                b(q0.R_component_2()),	\
                c(q0.R_component_3()),	\
                d(q0.R_component_4()),	\
                e(q1.R_component_1()),	\
                f(q1.R_component_2()),	\
                g(q1.R_component_3()),	\
                h(q1.R_component_4())	\
            {	\
            }

#define BOOST_OCTONION_MEMBER_ADD_GENERATOR(type)	\
        BOOST_OCTONION_MEMBER_ADD_GENERATOR_1(type)	\
        BOOST_OCTONION_MEMBER_ADD_GENERATOR_2(type)	\
        BOOST_OCTONION_MEMBER_ADD_GENERATOR_3(type)	\
        BOOST_OCTONION_MEMBER_ADD_GENERATOR_4(type)

#define BOOST_OCTONION_MEMBER_ADD_GENERATOR_1(type)	\
            octonion<type> &            operator += (type const & rhs);

#define BOOST_OCTONION_MEMBER_ADD_GENERATOR_2(type)	\
            octonion<type> &            operator += (::std::complex<type> const & rhs);

#define BOOST_OCTONION_MEMBER_ADD_GENERATOR_3(type)	\
            octonion<type> &            operator += (::boost::math::quaternion<type> const & rhs);

#define BOOST_OCTONION_MEMBER_ADD_GENERATOR_4(type)	\
            template<typename X>	\
            octonion<type> &            operator += (octonion<X> const & rhs);

#define BOOST_OCTONION_MEMBER_ALGEBRAIC_GENERATOR(type)	\
        BOOST_OCTONION_MEMBER_ADD_GENERATOR(type)	\
        BOOST_OCTONION_MEMBER_SUB_GENERATOR(type)	\
        BOOST_OCTONION_MEMBER_MUL_GENERATOR(type)	\
        BOOST_OCTONION_MEMBER_DIV_GENERATOR(type)

#define BOOST_OCTONION_MEMBER_ASSIGNMENT_GENERATOR(type)	\
            template<typename X>	\
            octonion<type> &        operator = (octonion<X> const & a_affecter);	\
            octonion<type> &        operator = (octonion<type> const & a_affecter);	\
            octonion<type> &        operator = (type const & a_affecter);	\
            octonion<type> &        operator = (::std::complex<type> const & a_affecter);	\
            octonion<type> &        operator = (::boost::math::quaternion<type> const & a_affecter);

#define BOOST_OCTONION_MEMBER_DATA_GENERATOR(type)	\
            type    a;	\
            type    b;	\
            type    c;	\
            type    d;	\
            type    e;	\
            type    f;	\
            type    g;	\
            type    h;	\

#define BOOST_OCTONION_MEMBER_DIV_GENERATOR(type)	\
        BOOST_OCTONION_MEMBER_DIV_GENERATOR_1(type)	\
        BOOST_OCTONION_MEMBER_DIV_GENERATOR_2(type)	\
        BOOST_OCTONION_MEMBER_DIV_GENERATOR_3(type)	\
        BOOST_OCTONION_MEMBER_DIV_GENERATOR_4(type)

#define BOOST_OCTONION_MEMBER_DIV_GENERATOR_1(type)	\
            octonion<type> &            operator /= (type const & rhs);

#define BOOST_OCTONION_MEMBER_DIV_GENERATOR_2(type)	\
            octonion<type> &            operator /= (::std::complex<type> const & rhs);

#define BOOST_OCTONION_MEMBER_DIV_GENERATOR_3(type)	\
            octonion<type> &            operator /= (::boost::math::quaternion<type> const & rhs);

#define BOOST_OCTONION_MEMBER_DIV_GENERATOR_4(type)	\
            template<typename X>	\
            octonion<type> &            operator /= (octonion<X> const & rhs);

#define BOOST_OCTONION_MEMBER_MUL_GENERATOR(type)	\
        BOOST_OCTONION_MEMBER_MUL_GENERATOR_1(type)	\
        BOOST_OCTONION_MEMBER_MUL_GENERATOR_2(type)	\
        BOOST_OCTONION_MEMBER_MUL_GENERATOR_3(type)	\
        BOOST_OCTONION_MEMBER_MUL_GENERATOR_4(type)

#define BOOST_OCTONION_MEMBER_MUL_GENERATOR_1(type)	\
            octonion<type> &            operator *= (type const & rhs);

#define BOOST_OCTONION_MEMBER_MUL_GENERATOR_2(type)	\
            octonion<type> &            operator *= (::std::complex<type> const & rhs);

#define BOOST_OCTONION_MEMBER_MUL_GENERATOR_3(type)	\
            octonion<type> &            operator *= (::boost::math::quaternion<type> const & rhs);

#define BOOST_OCTONION_MEMBER_MUL_GENERATOR_4(type)	\
            template<typename X>	\
            octonion<type> &            operator *= (octonion<X> const & rhs);

#define BOOST_OCTONION_MEMBER_SUB_GENERATOR(type)	\
        BOOST_OCTONION_MEMBER_SUB_GENERATOR_1(type)	\
        BOOST_OCTONION_MEMBER_SUB_GENERATOR_2(type)	\
        BOOST_OCTONION_MEMBER_SUB_GENERATOR_3(type)	\
        BOOST_OCTONION_MEMBER_SUB_GENERATOR_4(type)

#define BOOST_OCTONION_MEMBER_SUB_GENERATOR_1(type)	\
            octonion<type> &            operator -= (type const & rhs);	\

#define BOOST_OCTONION_MEMBER_SUB_GENERATOR_2(type)	\
            octonion<type> &            operator -= (::std::complex<type> const & rhs);

#define BOOST_OCTONION_MEMBER_SUB_GENERATOR_3(type)	\
            octonion<type> &            operator -= (::boost::math::quaternion<type> const & rhs);

#define BOOST_OCTONION_MEMBER_SUB_GENERATOR_4(type)	\
            template<typename X>	\
            octonion<type> &            operator -= (octonion<X> const & rhs);

#define BOOST_OCTONION_NOT_EQUAL_GENERATOR ;

#define BOOST_OCTONION_OPERATOR_GENERATOR(op)	\
        BOOST_OCTONION_OPERATOR_GENERATOR_1_L(op)	\
        BOOST_OCTONION_OPERATOR_GENERATOR_1_R(op)	\
        BOOST_OCTONION_OPERATOR_GENERATOR_2_L(op)	\
        BOOST_OCTONION_OPERATOR_GENERATOR_2_R(op)	\
        BOOST_OCTONION_OPERATOR_GENERATOR_3_L(op)	\
        BOOST_OCTONION_OPERATOR_GENERATOR_3_R(op)	\
        BOOST_OCTONION_OPERATOR_GENERATOR_4(op)

#define BOOST_OCTONION_OPERATOR_GENERATOR_1_L(op)	\
        template<typename T>	\
        inline octonion<T>                        operator op (T const & lhs, octonion<T> const & rhs)	\
        BOOST_OCTONION_OPERATOR_GENERATOR_BODY(op)

#define BOOST_OCTONION_OPERATOR_GENERATOR_1_R(op)	\
        template<typename T>	\
        inline octonion<T>                        operator op (octonion<T> const & lhs, T const & rhs)	\
        BOOST_OCTONION_OPERATOR_GENERATOR_BODY(op)

#define BOOST_OCTONION_OPERATOR_GENERATOR_2_L(op)	\
        template<typename T>	\
        inline octonion<T>                        operator op (::std::complex<T> const & lhs, octonion<T> const & rhs)	\
        BOOST_OCTONION_OPERATOR_GENERATOR_BODY(op)

#define BOOST_OCTONION_OPERATOR_GENERATOR_2_R(op)	\
        template<typename T>	\
        inline octonion<T>                        operator op (octonion<T> const & lhs, ::std::complex<T> const & rhs)	\
        BOOST_OCTONION_OPERATOR_GENERATOR_BODY(op)

#define BOOST_OCTONION_OPERATOR_GENERATOR_3_L(op)	\
        template<typename T>	\
        inline octonion<T>                        operator op (::boost::math::quaternion<T> const & lhs, octonion<T> const & rhs)	\
        BOOST_OCTONION_OPERATOR_GENERATOR_BODY(op)

#define BOOST_OCTONION_OPERATOR_GENERATOR_3_R(op)	\
        template<typename T>	\
        inline octonion<T>                        operator op (octonion<T> const & lhs, ::boost::math::quaternion<T> const & rhs)	\
        BOOST_OCTONION_OPERATOR_GENERATOR_BODY(op)

#define BOOST_OCTONION_OPERATOR_GENERATOR_4(op)	\
        template<typename T>	\
        inline octonion<T>                        operator op (octonion<T> const & lhs, octonion<T> const & rhs)	\
        BOOST_OCTONION_OPERATOR_GENERATOR_BODY(op)

#define BOOST_OCTONION_OPERATOR_GENERATOR_BODY(op) ;

#define BOOST_OPERATOR2_LEFT(name) name##2##_##left

#define BOOST_OPERATOR_TEMPLATE(template_name)	\
template <class T	\
         ,class U = T	\
         ,class B = ::boost::detail::empty_base	\
         ,class O = typename is_chained_base<U>::value	\
         >	\
struct template_name : template_name##2<T, U, B> {};	\
	\
template<class T, class U, class B>	\
struct template_name<T, U, B, ::boost::detail::true_t>	\
  : template_name##1<T, U> {};	\
	\
template <class T, class B>	\
struct template_name<T, T, B, ::boost::detail::false_t>	\
  : template_name##1<T, B> {};	\
	\
template<class T, class U, class B, class O>	\
struct is_chained_base< ::boost::template_name<T, U, B, O> > {	\
  typedef ::boost::detail::true_t value;	\
};	\
	\
BOOST_OPERATOR_TEMPLATE2(template_name##2)	\
BOOST_OPERATOR_TEMPLATE1(template_name##1)

#define BOOST_OPERATOR_TEMPLATE1(template_name1)	\
        BOOST_IMPORT_TEMPLATE1(template_name1)

#define BOOST_OPERATOR_TEMPLATE2(template_name2)	\
        BOOST_IMPORT_TEMPLATE2(template_name2)

#define BOOST_OPERATOR_TEMPLATE3(template_name3)	\
        BOOST_IMPORT_TEMPLATE3(template_name3)

#define BOOST_OPERATOR_TEMPLATE4(template_name4)	\
        BOOST_IMPORT_TEMPLATE4(template_name4)

#define BOOST_OSTREAM std::ostream

#define BOOST_PARAMETER_arg_list(n)	\
    BOOST_PP_ENUM(N, BOOST_PARAMETER_open_list, _)	\
  , mpl::identity<aux::empty_arg_list>	\
    BOOST_PP_REPEAT(N, BOOST_PARAMETER_close_list, _)

#define BOOST_PARAMETER_build_arg_list(n, make, parameter_spec, argument_type)	\
  BOOST_PP_REPEAT(	\
      n, BOOST_PARAMETER_make_arg_list, (make)(parameter_spec)(argument_type))	\
  mpl::identity<aux::empty_arg_list>	\
  BOOST_PP_REPEAT(n, BOOST_PARAMETER_right_angle, _)

#define BOOST_PARAMETER_close_list(z, n, text) >

#define BOOST_PARAMETER_FUN(ret, name, lo, hi, parameters)	\
	\
    template<class Params>	\
    ret BOOST_PP_CAT(name, _with_named_params)(Params const&);	\
	\
    BOOST_PP_REPEAT_FROM_TO(	\
        lo, BOOST_PP_INC(hi), BOOST_PARAMETER_FUN_DECL, (ret, name, parameters))	\
	\
    template<class Params>	\
    ret BOOST_PP_CAT(name, _with_named_params)(Params const& p)

#define BOOST_PARAMETER_FUN_DECL(z, n, params)	\
	\
    BOOST_PP_CAT(BOOST_PARAMETER_FUN_TEMPLATE_HEAD, BOOST_PP_BOOL(n))(n)	\
	\
    BOOST_PP_TUPLE_ELEM(3, 0, params)	\
        BOOST_PP_TUPLE_ELEM(3, 1, params)(	\
            BOOST_PP_ENUM_BINARY_PARAMS(n, T, const& p)	\
            BOOST_PP_COMMA_IF(n)	\
            BOOST_PARAMETER_MATCH_TYPE(n,BOOST_PP_TUPLE_ELEM(3, 2, params))	\
            kw = BOOST_PP_TUPLE_ELEM(3, 2, params)()	\
        );

#define BOOST_PARAMETER_FUN_TEMPLATE_HEAD0(n)

#define BOOST_PARAMETER_FUN_TEMPLATE_HEAD1(n)	\
    template<BOOST_PP_ENUM_PARAMS(n, class T)>

#define BOOST_PARAMETER_KEYWORD(tag_namespace,name)	\
    namespace tag_namespace { struct name; }	\
    namespace	\
    {	\
       ::boost::parameter::keyword<tag_namespace::name>& name	\
       = ::boost::parameter::keyword<tag_namespace::name>::get();	\
    }

#define BOOST_PARAMETER_make_arg_list(z, n, names)	\
      BOOST_PP_SEQ_ELEM(0,names)<	\
          BOOST_PP_CAT(BOOST_PP_SEQ_ELEM(1,names), n),	\
          BOOST_PP_CAT(BOOST_PP_SEQ_ELEM(2,names), n),

#define BOOST_PARAMETER_MATCH(ParameterSpec, ArgTypes, name)	\
    typename ParameterSpec ::match<	\
        BOOST_PARAMETER_SEQ_ENUM(ArgTypes)	\
        BOOST_PARAMETER_MATCH_DEFAULTS(ArgTypes)	\
    >::type name = ParameterSpec ()

#define BOOST_PARAMETER_MATCH_DEFAULTS(ArgTypes)

#define BOOST_PARAMETER_MATCH_TYPE(n, param) param

#define BOOST_PARAMETER_MEMFUN(ret, name, lo, hi, parameters)	\
	\
    BOOST_PP_REPEAT_FROM_TO(	\
        lo, BOOST_PP_INC(hi), BOOST_PARAMETER_FUN_DECL, (ret, name, parameters))	\
	\
    template<class Params>	\
    ret BOOST_PP_CAT(name, _with_named_params)(Params const& p)

#define BOOST_PARAMETER_open_list(z, n, text)	\
    aux::make_arg_list<	\
        BOOST_PP_CAT(PS, n), BOOST_PP_CAT(A, n)	\

#define BOOST_PARAMETER_right_angle(z, n, text) >

#define BOOST_PARAMETER_satisfies(z, n, text)	\
            mpl::and_<	\
                aux::satisfies_requirements_of<NamedList, BOOST_PP_CAT(PS, n)> ,

#define BOOST_PARAMETER_SEQ_ENUM(seq) BOOST_PP_SEQ_ENUM(seq)

#define BOOST_PARAMETER_TEMPLATE_ARGS(z, n, text) class BOOST_PP_CAT(PS, n) = aux::void_

#define BOOST_PFTO_WRAPPER(T) T

#define BOOST_PP_ADD(x, y) BOOST_PP_TUPLE_ELEM(2, 0, BOOST_PP_WHILE(BOOST_PP_ADD_P, BOOST_PP_ADD_O, (x, y)))
#define BOOST_PP_ADD_D(d, x, y) BOOST_PP_ADD_D_I(d, x, y)
#define BOOST_PP_ADD_D_I(d, x, y) BOOST_PP_TUPLE_ELEM(2, 0, BOOST_PP_WHILE_ ## d(BOOST_PP_ADD_P, BOOST_PP_ADD_O, (x, y)))
#define BOOST_PP_ADD_O(d, xy) BOOST_PP_ADD_O_I(BOOST_PP_TUPLE_ELEM(2, 0, xy), BOOST_PP_TUPLE_ELEM(2, 1, xy))
#define BOOST_PP_ADD_O_I(x, y) (BOOST_PP_INC(x), BOOST_PP_DEC(y))
#define BOOST_PP_ADD_P(d, xy) BOOST_PP_TUPLE_ELEM(2, 1, xy)

#define BOOST_PP_AND(p, q) BOOST_PP_BITAND(BOOST_PP_BOOL(p), BOOST_PP_BOOL(q))

#define BOOST_PP_APPLY(x) BOOST_PP_EXPR_IIF(BOOST_PP_IS_UNARY(x), BOOST_PP_TUPLE_REM_1 x)

#define BOOST_PP_ARRAY_DATA(array) BOOST_PP_TUPLE_ELEM(2, 1, array)
#define BOOST_PP_ARRAY_ELEM(i, array) BOOST_PP_TUPLE_ELEM(BOOST_PP_ARRAY_SIZE(array), i, BOOST_PP_ARRAY_DATA(array))

#define BOOST_PP_ARRAY_INSERT(array, i, elem) BOOST_PP_ARRAY_INSERT_I(BOOST_PP_DEDUCE_D(), array, i, elem)
#define BOOST_PP_ARRAY_INSERT_D(d, array, i, elem) BOOST_PP_TUPLE_ELEM(5, 3, BOOST_PP_WHILE_ ## d(BOOST_PP_ARRAY_INSERT_P, BOOST_PP_ARRAY_INSERT_O, (0, i, elem, (0, ()), array)))
#define BOOST_PP_ARRAY_INSERT_I(d, array, i, elem) BOOST_PP_ARRAY_INSERT_D(d, array, i, elem)
#define BOOST_PP_ARRAY_INSERT_O(d, state) BOOST_PP_ARRAY_INSERT_O_I(BOOST_PP_TUPLE_ELEM(5, 0, state), BOOST_PP_TUPLE_ELEM(5, 1, state), BOOST_PP_TUPLE_ELEM(5, 2, state), BOOST_PP_TUPLE_ELEM(5, 3, state), BOOST_PP_TUPLE_ELEM(5, 4, state))
#define BOOST_PP_ARRAY_INSERT_O_I(n, i, elem, res, arr) (BOOST_PP_IIF(BOOST_PP_NOT_EQUAL(BOOST_PP_ARRAY_SIZE(res), i), BOOST_PP_INC(n), n), i, elem, BOOST_PP_ARRAY_PUSH_BACK(res, BOOST_PP_IIF(BOOST_PP_NOT_EQUAL(BOOST_PP_ARRAY_SIZE(res), i), BOOST_PP_ARRAY_ELEM(n, arr), elem)), arr)
#define BOOST_PP_ARRAY_INSERT_P(d, state) BOOST_PP_ARRAY_INSERT_P_I(nil, nil, nil, BOOST_PP_TUPLE_ELEM(5, 3, state), BOOST_PP_TUPLE_ELEM(5, 4, state))
#define BOOST_PP_ARRAY_INSERT_P_I(_i, _ii, _iii, res, arr) BOOST_PP_NOT_EQUAL(BOOST_PP_ARRAY_SIZE(res), BOOST_PP_INC(BOOST_PP_ARRAY_SIZE(arr)))

#define BOOST_PP_ARRAY_POP_BACK(array) BOOST_PP_ARRAY_POP_BACK_Z(BOOST_PP_DEDUCE_Z(), array)
#define BOOST_PP_ARRAY_POP_BACK_I(z, size, array) (BOOST_PP_DEC(size), (BOOST_PP_ENUM_ ## z(BOOST_PP_DEC(size), BOOST_PP_ARRAY_POP_BACK_M, array)))
#define BOOST_PP_ARRAY_POP_BACK_M(z, n, data) BOOST_PP_ARRAY_ELEM(n, data)
#define BOOST_PP_ARRAY_POP_BACK_Z(z, array) BOOST_PP_ARRAY_POP_BACK_I(z, BOOST_PP_ARRAY_SIZE(array), array)
#define BOOST_PP_ARRAY_POP_FRONT(array) BOOST_PP_ARRAY_POP_FRONT_Z(BOOST_PP_DEDUCE_Z(), array)
#define BOOST_PP_ARRAY_POP_FRONT_I(z, size, array) (BOOST_PP_DEC(size), (BOOST_PP_ENUM_ ## z(BOOST_PP_DEC(size), BOOST_PP_ARRAY_POP_FRONT_M, array)))
#define BOOST_PP_ARRAY_POP_FRONT_I(z, size, array) (BOOST_PP_DEC(size), (BOOST_PP_ENUM_ ## z(BOOST_PP_DEC(size), BOOST_PP_ARRAY_POP_FRONT_M, array)))
#define BOOST_PP_ARRAY_POP_FRONT_M(z, n, data) BOOST_PP_ARRAY_ELEM(BOOST_PP_INC(n), data)
#define BOOST_PP_ARRAY_POP_FRONT_Z(z, array) BOOST_PP_ARRAY_POP_FRONT_I(z, BOOST_PP_ARRAY_SIZE(array), array)

#define BOOST_PP_ARRAY_PUSH_BACK(array, elem) BOOST_PP_ARRAY_PUSH_BACK_I(BOOST_PP_ARRAY_SIZE(array), BOOST_PP_ARRAY_DATA(array), elem)
#define BOOST_PP_ARRAY_PUSH_BACK_I(size, data, elem) (BOOST_PP_INC(size), (BOOST_PP_TUPLE_REM(size) data BOOST_PP_COMMA_IF(size) elem))
#define BOOST_PP_ARRAY_PUSH_FRONT(array, elem) BOOST_PP_ARRAY_PUSH_FRONT_D(array, elem)
#define BOOST_PP_ARRAY_PUSH_FRONT_I(size, data, elem) (BOOST_PP_INC(size), (elem BOOST_PP_COMMA_IF(size) BOOST_PP_TUPLE_REM(size) data))

#define BOOST_PP_ARRAY_REMOVE(array, i) BOOST_PP_ARRAY_REMOVE_I(BOOST_PP_DEDUCE_D(), array, i)
#define BOOST_PP_ARRAY_REMOVE_D(d, array, i) BOOST_PP_TUPLE_ELEM(4, 2, BOOST_PP_WHILE_ ## d(BOOST_PP_ARRAY_REMOVE_P, BOOST_PP_ARRAY_REMOVE_O, (0, i, (0, ()), array)))
#define BOOST_PP_ARRAY_REMOVE_I(d, array, i) BOOST_PP_ARRAY_REMOVE_D(d, array, i)
#define BOOST_PP_ARRAY_REMOVE_O(d, st) BOOST_PP_ARRAY_REMOVE_O_I(BOOST_PP_TUPLE_ELEM(4, 0, st), BOOST_PP_TUPLE_ELEM(4, 1, st), BOOST_PP_TUPLE_ELEM(4, 2, st), BOOST_PP_TUPLE_ELEM(4, 3, st))
#define BOOST_PP_ARRAY_REMOVE_O_I(n, i, res, arr) (BOOST_PP_INC(n), i, BOOST_PP_IIF(BOOST_PP_NOT_EQUAL(n, i), BOOST_PP_ARRAY_PUSH_BACK, res BOOST_PP_TUPLE_EAT_2)(res, BOOST_PP_ARRAY_ELEM(n, arr)), arr)
#define BOOST_PP_ARRAY_REMOVE_P(d, st) BOOST_PP_NOT_EQUAL(BOOST_PP_TUPLE_ELEM(4, 0, st), BOOST_PP_ARRAY_SIZE(BOOST_PP_TUPLE_ELEM(4, 3, st)))

#define BOOST_PP_ARRAY_REPLACE(array, i, elem) BOOST_PP_ARRAY_REPLACE_I(BOOST_PP_DEDUCE_D(), array, i, elem)
#define BOOST_PP_ARRAY_REPLACE_D(d, array, i, elem) BOOST_PP_TUPLE_ELEM(5, 3, BOOST_PP_WHILE_ ## d(BOOST_PP_ARRAY_REPLACE_P, BOOST_PP_ARRAY_REPLACE_O, (0, i, elem, (0, ()), array)))
#define BOOST_PP_ARRAY_REPLACE_I(d, array, i, elem) BOOST_PP_ARRAY_REPLACE_D(d, array, i, elem)
#define BOOST_PP_ARRAY_REPLACE_O(d, state) BOOST_PP_ARRAY_REPLACE_O_I(BOOST_PP_TUPLE_ELEM(5, 0, state), BOOST_PP_TUPLE_ELEM(5, 1, state), BOOST_PP_TUPLE_ELEM(5, 2, state), BOOST_PP_TUPLE_ELEM(5, 3, state), BOOST_PP_TUPLE_ELEM(5, 4, state))
#define BOOST_PP_ARRAY_REPLACE_O_I(n, i, elem, res, arr) (BOOST_PP_INC(n), i, elem, BOOST_PP_ARRAY_PUSH_BACK(res, BOOST_PP_IIF(BOOST_PP_NOT_EQUAL(n, i), BOOST_PP_ARRAY_ELEM(n, arr), elem)), arr)
#define BOOST_PP_ARRAY_REPLACE_P(d, state) BOOST_PP_NOT_EQUAL(BOOST_PP_TUPLE_ELEM(5, 0, state), BOOST_PP_ARRAY_SIZE(BOOST_PP_TUPLE_ELEM(5, 4, state)))

#define BOOST_PP_ARRAY_REVERSE(array) (BOOST_PP_ARRAY_SIZE(array), BOOST_PP_TUPLE_REVERSE(BOOST_PP_ARRAY_SIZE(array), BOOST_PP_ARRAY_DATA(array)))

#define BOOST_PP_ARRAY_SIZE(array) BOOST_PP_TUPLE_ELEM(2, 0, array)

#define BOOST_PP_AUTO_REC(pred, n) BOOST_PP_NODE_ENTRY_ ## n(pred)

#define BOOST_PP_BITAND(x, y) BOOST_PP_BITAND_I(x,y)
#define BOOST_PP_BITAND_I(x, y) BOOST_PP_BITAND_##x##y
#define BOOST_PP_BITAND_00 0
#define BOOST_PP_BITAND_01 0
#define BOOST_PP_BITAND_10 0
#define BOOST_PP_BITAND_11 1

#define BOOST_PP_BITNOR(x, y) BOOST_PP_BITNOR_I(x,y)
#define BOOST_PP_BITNOR_I(x, y) BOOST_PP_BITNOR_##x##y
#define BOOST_PP_BITNOR_00 1
#define BOOST_PP_BITNOR_01 0
#define BOOST_PP_BITNOR_10 0
#define BOOST_PP_BITNOR_11 0

#define BOOST_PP_BITOR(x, y) BOOST_PP_BITOR_I(x,y)
#define BOOST_PP_BITOR_I(x, y) BOOST_PP_BITOR_##x##y
#define BOOST_PP_BITOR_00 0
#define BOOST_PP_BITOR_01 1
#define BOOST_PP_BITOR_10 1
#define BOOST_PP_BITOR_11 1

#define BOOST_PP_BITXOR(x, y) BOOST_PP_BITXOR_I(x,y)
#define BOOST_PP_BITXOR_I(x, y) BOOST_PP_BITXOR_##x##y
#define BOOST_PP_BITXOR_00 0
#define BOOST_PP_BITXOR_01 1
#define BOOST_PP_BITXOR_10 1
#define BOOST_PP_BITXOR_11 0

#define BOOST_PP_BOOL(x) BOOST_PP_BOOL_I(x)
#define BOOST_PP_BOOL_I(x) BOOST_PP_BOOL_##x
#define BOOST_PP_BOOL_0 0
#define BOOST_PP_BOOL_1 1
#define BOOST_PP_BOOL_2 1
#define BOOST_PP_BOOL_3 1
#define BOOST_PP_BOOL_4 1
#define BOOST_PP_BOOL_5 1
#define BOOST_PP_BOOL_6 1
#define BOOST_PP_BOOL_7 1
#define BOOST_PP_BOOL_8 1
#define BOOST_PP_BOOL_9 1
#define BOOST_PP_BOOL_10 1
#define BOOST_PP_BOOL_11 1
#define BOOST_PP_BOOL_12 1
#define BOOST_PP_BOOL_13 1
#define BOOST_PP_BOOL_14 1
#define BOOST_PP_BOOL_15 1
#define BOOST_PP_BOOL_16 1
#define BOOST_PP_BOOL_17 1
#define BOOST_PP_BOOL_18 1
#define BOOST_PP_BOOL_19 1
#define BOOST_PP_BOOL_20 1
#define BOOST_PP_BOOL_21 1
#define BOOST_PP_BOOL_22 1
#define BOOST_PP_BOOL_23 1
#define BOOST_PP_BOOL_24 1
#define BOOST_PP_BOOL_25 1
#define BOOST_PP_BOOL_26 1
#define BOOST_PP_BOOL_27 1
#define BOOST_PP_BOOL_28 1
#define BOOST_PP_BOOL_29 1
#define BOOST_PP_BOOL_30 1
#define BOOST_PP_BOOL_31 1
#define BOOST_PP_BOOL_32 1
#define BOOST_PP_BOOL_33 1
#define BOOST_PP_BOOL_34 1
#define BOOST_PP_BOOL_35 1
#define BOOST_PP_BOOL_36 1
#define BOOST_PP_BOOL_37 1
#define BOOST_PP_BOOL_38 1
#define BOOST_PP_BOOL_39 1
#define BOOST_PP_BOOL_40 1
#define BOOST_PP_BOOL_41 1
#define BOOST_PP_BOOL_42 1
#define BOOST_PP_BOOL_43 1
#define BOOST_PP_BOOL_44 1
#define BOOST_PP_BOOL_45 1
#define BOOST_PP_BOOL_46 1
#define BOOST_PP_BOOL_47 1
#define BOOST_PP_BOOL_48 1
#define BOOST_PP_BOOL_49 1
#define BOOST_PP_BOOL_50 1
#define BOOST_PP_BOOL_51 1
#define BOOST_PP_BOOL_52 1
#define BOOST_PP_BOOL_53 1
#define BOOST_PP_BOOL_54 1
#define BOOST_PP_BOOL_55 1
#define BOOST_PP_BOOL_56 1
#define BOOST_PP_BOOL_57 1
#define BOOST_PP_BOOL_58 1
#define BOOST_PP_BOOL_59 1
#define BOOST_PP_BOOL_60 1
#define BOOST_PP_BOOL_61 1
#define BOOST_PP_BOOL_62 1
#define BOOST_PP_BOOL_63 1
#define BOOST_PP_BOOL_64 1
#define BOOST_PP_BOOL_65 1
#define BOOST_PP_BOOL_66 1
#define BOOST_PP_BOOL_67 1
#define BOOST_PP_BOOL_68 1
#define BOOST_PP_BOOL_69 1
#define BOOST_PP_BOOL_70 1
#define BOOST_PP_BOOL_71 1
#define BOOST_PP_BOOL_72 1
#define BOOST_PP_BOOL_73 1
#define BOOST_PP_BOOL_74 1
#define BOOST_PP_BOOL_75 1
#define BOOST_PP_BOOL_76 1
#define BOOST_PP_BOOL_77 1
#define BOOST_PP_BOOL_78 1
#define BOOST_PP_BOOL_79 1
#define BOOST_PP_BOOL_80 1
#define BOOST_PP_BOOL_81 1
#define BOOST_PP_BOOL_82 1
#define BOOST_PP_BOOL_83 1
#define BOOST_PP_BOOL_84 1
#define BOOST_PP_BOOL_85 1
#define BOOST_PP_BOOL_86 1
#define BOOST_PP_BOOL_87 1
#define BOOST_PP_BOOL_88 1
#define BOOST_PP_BOOL_89 1
#define BOOST_PP_BOOL_90 1
#define BOOST_PP_BOOL_91 1
#define BOOST_PP_BOOL_92 1
#define BOOST_PP_BOOL_93 1
#define BOOST_PP_BOOL_94 1
#define BOOST_PP_BOOL_95 1
#define BOOST_PP_BOOL_96 1
#define BOOST_PP_BOOL_97 1
#define BOOST_PP_BOOL_98 1
#define BOOST_PP_BOOL_99 1
#define BOOST_PP_BOOL_100 1
#define BOOST_PP_BOOL_101 1
#define BOOST_PP_BOOL_102 1
#define BOOST_PP_BOOL_103 1
#define BOOST_PP_BOOL_104 1
#define BOOST_PP_BOOL_105 1
#define BOOST_PP_BOOL_106 1
#define BOOST_PP_BOOL_107 1
#define BOOST_PP_BOOL_108 1
#define BOOST_PP_BOOL_109 1
#define BOOST_PP_BOOL_110 1
#define BOOST_PP_BOOL_111 1
#define BOOST_PP_BOOL_112 1
#define BOOST_PP_BOOL_113 1
#define BOOST_PP_BOOL_114 1
#define BOOST_PP_BOOL_115 1
#define BOOST_PP_BOOL_116 1
#define BOOST_PP_BOOL_117 1
#define BOOST_PP_BOOL_118 1
#define BOOST_PP_BOOL_119 1
#define BOOST_PP_BOOL_120 1
#define BOOST_PP_BOOL_121 1
#define BOOST_PP_BOOL_122 1
#define BOOST_PP_BOOL_123 1
#define BOOST_PP_BOOL_124 1
#define BOOST_PP_BOOL_125 1
#define BOOST_PP_BOOL_126 1
#define BOOST_PP_BOOL_127 1
#define BOOST_PP_BOOL_128 1
#define BOOST_PP_BOOL_129 1
#define BOOST_PP_BOOL_130 1
#define BOOST_PP_BOOL_131 1
#define BOOST_PP_BOOL_132 1
#define BOOST_PP_BOOL_133 1
#define BOOST_PP_BOOL_134 1
#define BOOST_PP_BOOL_135 1
#define BOOST_PP_BOOL_136 1
#define BOOST_PP_BOOL_137 1
#define BOOST_PP_BOOL_138 1
#define BOOST_PP_BOOL_139 1
#define BOOST_PP_BOOL_140 1
#define BOOST_PP_BOOL_141 1
#define BOOST_PP_BOOL_142 1
#define BOOST_PP_BOOL_143 1
#define BOOST_PP_BOOL_144 1
#define BOOST_PP_BOOL_145 1
#define BOOST_PP_BOOL_146 1
#define BOOST_PP_BOOL_147 1
#define BOOST_PP_BOOL_148 1
#define BOOST_PP_BOOL_149 1
#define BOOST_PP_BOOL_150 1
#define BOOST_PP_BOOL_151 1
#define BOOST_PP_BOOL_152 1
#define BOOST_PP_BOOL_153 1
#define BOOST_PP_BOOL_154 1
#define BOOST_PP_BOOL_155 1
#define BOOST_PP_BOOL_156 1
#define BOOST_PP_BOOL_157 1
#define BOOST_PP_BOOL_158 1
#define BOOST_PP_BOOL_159 1
#define BOOST_PP_BOOL_160 1
#define BOOST_PP_BOOL_161 1
#define BOOST_PP_BOOL_162 1
#define BOOST_PP_BOOL_163 1
#define BOOST_PP_BOOL_164 1
#define BOOST_PP_BOOL_165 1
#define BOOST_PP_BOOL_166 1
#define BOOST_PP_BOOL_167 1
#define BOOST_PP_BOOL_168 1
#define BOOST_PP_BOOL_169 1
#define BOOST_PP_BOOL_170 1
#define BOOST_PP_BOOL_171 1
#define BOOST_PP_BOOL_172 1
#define BOOST_PP_BOOL_173 1
#define BOOST_PP_BOOL_174 1
#define BOOST_PP_BOOL_175 1
#define BOOST_PP_BOOL_176 1
#define BOOST_PP_BOOL_177 1
#define BOOST_PP_BOOL_178 1
#define BOOST_PP_BOOL_179 1
#define BOOST_PP_BOOL_180 1
#define BOOST_PP_BOOL_181 1
#define BOOST_PP_BOOL_182 1
#define BOOST_PP_BOOL_183 1
#define BOOST_PP_BOOL_184 1
#define BOOST_PP_BOOL_185 1
#define BOOST_PP_BOOL_186 1
#define BOOST_PP_BOOL_187 1
#define BOOST_PP_BOOL_188 1
#define BOOST_PP_BOOL_189 1
#define BOOST_PP_BOOL_190 1
#define BOOST_PP_BOOL_191 1
#define BOOST_PP_BOOL_192 1
#define BOOST_PP_BOOL_193 1
#define BOOST_PP_BOOL_194 1
#define BOOST_PP_BOOL_195 1
#define BOOST_PP_BOOL_196 1
#define BOOST_PP_BOOL_197 1
#define BOOST_PP_BOOL_198 1
#define BOOST_PP_BOOL_199 1
#define BOOST_PP_BOOL_200 1
#define BOOST_PP_BOOL_201 1
#define BOOST_PP_BOOL_202 1
#define BOOST_PP_BOOL_203 1
#define BOOST_PP_BOOL_204 1
#define BOOST_PP_BOOL_205 1
#define BOOST_PP_BOOL_206 1
#define BOOST_PP_BOOL_207 1
#define BOOST_PP_BOOL_208 1
#define BOOST_PP_BOOL_209 1
#define BOOST_PP_BOOL_210 1
#define BOOST_PP_BOOL_211 1
#define BOOST_PP_BOOL_212 1
#define BOOST_PP_BOOL_213 1
#define BOOST_PP_BOOL_214 1
#define BOOST_PP_BOOL_215 1
#define BOOST_PP_BOOL_216 1
#define BOOST_PP_BOOL_217 1
#define BOOST_PP_BOOL_218 1
#define BOOST_PP_BOOL_219 1
#define BOOST_PP_BOOL_220 1
#define BOOST_PP_BOOL_221 1
#define BOOST_PP_BOOL_222 1
#define BOOST_PP_BOOL_223 1
#define BOOST_PP_BOOL_224 1
#define BOOST_PP_BOOL_225 1
#define BOOST_PP_BOOL_226 1
#define BOOST_PP_BOOL_227 1
#define BOOST_PP_BOOL_228 1
#define BOOST_PP_BOOL_229 1
#define BOOST_PP_BOOL_230 1
#define BOOST_PP_BOOL_231 1
#define BOOST_PP_BOOL_232 1
#define BOOST_PP_BOOL_233 1
#define BOOST_PP_BOOL_234 1
#define BOOST_PP_BOOL_235 1
#define BOOST_PP_BOOL_236 1
#define BOOST_PP_BOOL_237 1
#define BOOST_PP_BOOL_238 1
#define BOOST_PP_BOOL_239 1
#define BOOST_PP_BOOL_240 1
#define BOOST_PP_BOOL_241 1
#define BOOST_PP_BOOL_242 1
#define BOOST_PP_BOOL_243 1
#define BOOST_PP_BOOL_244 1
#define BOOST_PP_BOOL_245 1
#define BOOST_PP_BOOL_246 1
#define BOOST_PP_BOOL_247 1
#define BOOST_PP_BOOL_248 1
#define BOOST_PP_BOOL_249 1
#define BOOST_PP_BOOL_250 1
#define BOOST_PP_BOOL_251 1
#define BOOST_PP_BOOL_252 1
#define BOOST_PP_BOOL_253 1
#define BOOST_PP_BOOL_254 1
#define BOOST_PP_BOOL_255 1
#define BOOST_PP_BOOL_256 1

#define BOOST_PP_CAT(a, b) BOOST_PP_CAT_I(a,b)
#define BOOST_PP_CAT_I(a, b) a##b

#define BOOST_PP_CHECK(x, type) BOOST_PP_CHECK_D(x, type)
#define BOOST_PP_CHECK_D(x, type) BOOST_PP_CHECK_1(type x)
#define BOOST_PP_CHECK_1(chk) BOOST_PP_CHECK_2(chk)
#define BOOST_PP_CHECK_2(chk) BOOST_PP_CHECK_3((BOOST_PP_CHECK_RESULT_ ## chk))
#define BOOST_PP_CHECK_3(im) BOOST_PP_CHECK_5(BOOST_PP_CHECK_4 im)
#define BOOST_PP_CHECK_4(res, _) res
#define BOOST_PP_CHECK_5(res) res

#define BOOST_PP_CHECK_RESULT_1 1, BOOST_PP_NIL
#define BOOST_PP_CHECK_RESULT_BOOST_PP_IS_BINARY_CHECK 0,BOOST_PP_NIL
#define BOOST_PP_CHECK_RESULT_BOOST_PP_IS_NULLARY_CHECK 0,BOOST_PP_NIL
#define BOOST_PP_CHECK_RESULT_BOOST_PP_IS_UNARY_CHECK 0,BOOST_PP_NIL

#define BOOST_PP_CONFIG_FLAGS() (BOOST_PP_CONFIG_STRICT())
#define BOOST_PP_CONFIG_STRICT() 0x0001
#define BOOST_PP_CONFIG_IDEAL() 0x0002
#define BOOST_PP_CONFIG_MSVC() 0x0004
#define BOOST_PP_CONFIG_MWCC() 0x0008
#define BOOST_PP_CONFIG_BCC() 0x0010
#define BOOST_PP_CONFIG_EDG() 0x0020
#define BOOST_PP_CONFIG_DMC() 0x0040

#define BOOST_PP_COMMA() ,

#define BOOST_PP_COMMA_IF(cond) BOOST_PP_IF(cond, BOOST_PP_COMMA, BOOST_PP_EMPTY)()

#define BOOST_PP_COMPL(x) BOOST_PP_COMPL_I(x)
#define BOOST_PP_COMPL_I(x) BOOST_PP_COMPL_ ## x
#define BOOST_PP_COMPL_0 1
#define BOOST_PP_COMPL_1 0

#define BOOST_PP_COUNTER BOOST_PP_FRAME_ITERATION(1)

#define BOOST_PP_DEC(x) BOOST_PP_DEC_I(x)
#define BOOST_PP_DEC_I(x) BOOST_PP_DEC_##x
#define BOOST_PP_DEC_0 0
#define BOOST_PP_DEC_1 0
#define BOOST_PP_DEC_2 1
#define BOOST_PP_DEC_3 2
#define BOOST_PP_DEC_4 3
#define BOOST_PP_DEC_5 4
#define BOOST_PP_DEC_6 5
#define BOOST_PP_DEC_7 6
#define BOOST_PP_DEC_8 7
#define BOOST_PP_DEC_9 8
#define BOOST_PP_DEC_10 9
#define BOOST_PP_DEC_11 10
#define BOOST_PP_DEC_12 11
#define BOOST_PP_DEC_13 12
#define BOOST_PP_DEC_14 13
#define BOOST_PP_DEC_15 14
#define BOOST_PP_DEC_16 15
#define BOOST_PP_DEC_17 16
#define BOOST_PP_DEC_18 17
#define BOOST_PP_DEC_19 18
#define BOOST_PP_DEC_20 19
#define BOOST_PP_DEC_21 20
#define BOOST_PP_DEC_22 21
#define BOOST_PP_DEC_23 22
#define BOOST_PP_DEC_24 23
#define BOOST_PP_DEC_25 24
#define BOOST_PP_DEC_26 25
#define BOOST_PP_DEC_27 26
#define BOOST_PP_DEC_28 27
#define BOOST_PP_DEC_29 28
#define BOOST_PP_DEC_30 29
#define BOOST_PP_DEC_31 30
#define BOOST_PP_DEC_32 31
#define BOOST_PP_DEC_33 32
#define BOOST_PP_DEC_34 33
#define BOOST_PP_DEC_35 34
#define BOOST_PP_DEC_36 35
#define BOOST_PP_DEC_37 36
#define BOOST_PP_DEC_38 37
#define BOOST_PP_DEC_39 38
#define BOOST_PP_DEC_40 39
#define BOOST_PP_DEC_41 40
#define BOOST_PP_DEC_42 41
#define BOOST_PP_DEC_43 42
#define BOOST_PP_DEC_44 43
#define BOOST_PP_DEC_45 44
#define BOOST_PP_DEC_46 45
#define BOOST_PP_DEC_47 46
#define BOOST_PP_DEC_48 47
#define BOOST_PP_DEC_49 48
#define BOOST_PP_DEC_50 49
#define BOOST_PP_DEC_51 50
#define BOOST_PP_DEC_52 51
#define BOOST_PP_DEC_53 52
#define BOOST_PP_DEC_54 53
#define BOOST_PP_DEC_55 54
#define BOOST_PP_DEC_56 55
#define BOOST_PP_DEC_57 56
#define BOOST_PP_DEC_58 57
#define BOOST_PP_DEC_59 58
#define BOOST_PP_DEC_60 59
#define BOOST_PP_DEC_61 60
#define BOOST_PP_DEC_62 61
#define BOOST_PP_DEC_63 62
#define BOOST_PP_DEC_64 63
#define BOOST_PP_DEC_65 64
#define BOOST_PP_DEC_66 65
#define BOOST_PP_DEC_67 66
#define BOOST_PP_DEC_68 67
#define BOOST_PP_DEC_69 68
#define BOOST_PP_DEC_70 69
#define BOOST_PP_DEC_71 70
#define BOOST_PP_DEC_72 71
#define BOOST_PP_DEC_73 72
#define BOOST_PP_DEC_74 73
#define BOOST_PP_DEC_75 74
#define BOOST_PP_DEC_76 75
#define BOOST_PP_DEC_77 76
#define BOOST_PP_DEC_78 77
#define BOOST_PP_DEC_79 78
#define BOOST_PP_DEC_80 79
#define BOOST_PP_DEC_81 80
#define BOOST_PP_DEC_82 81
#define BOOST_PP_DEC_83 82
#define BOOST_PP_DEC_84 83
#define BOOST_PP_DEC_85 84
#define BOOST_PP_DEC_86 85
#define BOOST_PP_DEC_87 86
#define BOOST_PP_DEC_88 87
#define BOOST_PP_DEC_89 88
#define BOOST_PP_DEC_90 89
#define BOOST_PP_DEC_91 90
#define BOOST_PP_DEC_92 91
#define BOOST_PP_DEC_93 92
#define BOOST_PP_DEC_94 93
#define BOOST_PP_DEC_95 94
#define BOOST_PP_DEC_96 95
#define BOOST_PP_DEC_97 96
#define BOOST_PP_DEC_98 97
#define BOOST_PP_DEC_99 98
#define BOOST_PP_DEC_100 99
#define BOOST_PP_DEC_101 100
#define BOOST_PP_DEC_102 101
#define BOOST_PP_DEC_103 102
#define BOOST_PP_DEC_104 103
#define BOOST_PP_DEC_105 104
#define BOOST_PP_DEC_106 105
#define BOOST_PP_DEC_107 106
#define BOOST_PP_DEC_108 107
#define BOOST_PP_DEC_109 108
#define BOOST_PP_DEC_110 109
#define BOOST_PP_DEC_111 110
#define BOOST_PP_DEC_112 111
#define BOOST_PP_DEC_113 112
#define BOOST_PP_DEC_114 113
#define BOOST_PP_DEC_115 114
#define BOOST_PP_DEC_116 115
#define BOOST_PP_DEC_117 116
#define BOOST_PP_DEC_118 117
#define BOOST_PP_DEC_119 118
#define BOOST_PP_DEC_120 119
#define BOOST_PP_DEC_121 120
#define BOOST_PP_DEC_122 121
#define BOOST_PP_DEC_123 122
#define BOOST_PP_DEC_124 123
#define BOOST_PP_DEC_125 124
#define BOOST_PP_DEC_126 125
#define BOOST_PP_DEC_127 126
#define BOOST_PP_DEC_128 127
#define BOOST_PP_DEC_129 128
#define BOOST_PP_DEC_130 129
#define BOOST_PP_DEC_131 130
#define BOOST_PP_DEC_132 131
#define BOOST_PP_DEC_133 132
#define BOOST_PP_DEC_134 133
#define BOOST_PP_DEC_135 134
#define BOOST_PP_DEC_136 135
#define BOOST_PP_DEC_137 136
#define BOOST_PP_DEC_138 137
#define BOOST_PP_DEC_139 138
#define BOOST_PP_DEC_140 139
#define BOOST_PP_DEC_141 140
#define BOOST_PP_DEC_142 141
#define BOOST_PP_DEC_143 142
#define BOOST_PP_DEC_144 143
#define BOOST_PP_DEC_145 144
#define BOOST_PP_DEC_146 145
#define BOOST_PP_DEC_147 146
#define BOOST_PP_DEC_148 147
#define BOOST_PP_DEC_149 148
#define BOOST_PP_DEC_150 149
#define BOOST_PP_DEC_151 150
#define BOOST_PP_DEC_152 151
#define BOOST_PP_DEC_153 152
#define BOOST_PP_DEC_154 153
#define BOOST_PP_DEC_155 154
#define BOOST_PP_DEC_156 155
#define BOOST_PP_DEC_157 156
#define BOOST_PP_DEC_158 157
#define BOOST_PP_DEC_159 158
#define BOOST_PP_DEC_160 159
#define BOOST_PP_DEC_161 160
#define BOOST_PP_DEC_162 161
#define BOOST_PP_DEC_163 162
#define BOOST_PP_DEC_164 163
#define BOOST_PP_DEC_165 164
#define BOOST_PP_DEC_166 165
#define BOOST_PP_DEC_167 166
#define BOOST_PP_DEC_168 167
#define BOOST_PP_DEC_169 168
#define BOOST_PP_DEC_170 169
#define BOOST_PP_DEC_171 170
#define BOOST_PP_DEC_172 171
#define BOOST_PP_DEC_173 172
#define BOOST_PP_DEC_174 173
#define BOOST_PP_DEC_175 174
#define BOOST_PP_DEC_176 175
#define BOOST_PP_DEC_177 176
#define BOOST_PP_DEC_178 177
#define BOOST_PP_DEC_179 178
#define BOOST_PP_DEC_180 179
#define BOOST_PP_DEC_181 180
#define BOOST_PP_DEC_182 181
#define BOOST_PP_DEC_183 182
#define BOOST_PP_DEC_184 183
#define BOOST_PP_DEC_185 184
#define BOOST_PP_DEC_186 185
#define BOOST_PP_DEC_187 186
#define BOOST_PP_DEC_188 187
#define BOOST_PP_DEC_189 188
#define BOOST_PP_DEC_190 189
#define BOOST_PP_DEC_191 190
#define BOOST_PP_DEC_192 191
#define BOOST_PP_DEC_193 192
#define BOOST_PP_DEC_194 193
#define BOOST_PP_DEC_195 194
#define BOOST_PP_DEC_196 195
#define BOOST_PP_DEC_197 196
#define BOOST_PP_DEC_198 197
#define BOOST_PP_DEC_199 198
#define BOOST_PP_DEC_200 199
#define BOOST_PP_DEC_201 200
#define BOOST_PP_DEC_202 201
#define BOOST_PP_DEC_203 202
#define BOOST_PP_DEC_204 203
#define BOOST_PP_DEC_205 204
#define BOOST_PP_DEC_206 205
#define BOOST_PP_DEC_207 206
#define BOOST_PP_DEC_208 207
#define BOOST_PP_DEC_209 208
#define BOOST_PP_DEC_210 209
#define BOOST_PP_DEC_211 210
#define BOOST_PP_DEC_212 211
#define BOOST_PP_DEC_213 212
#define BOOST_PP_DEC_214 213
#define BOOST_PP_DEC_215 214
#define BOOST_PP_DEC_216 215
#define BOOST_PP_DEC_217 216
#define BOOST_PP_DEC_218 217
#define BOOST_PP_DEC_219 218
#define BOOST_PP_DEC_220 219
#define BOOST_PP_DEC_221 220
#define BOOST_PP_DEC_222 221
#define BOOST_PP_DEC_223 222
#define BOOST_PP_DEC_224 223
#define BOOST_PP_DEC_225 224
#define BOOST_PP_DEC_226 225
#define BOOST_PP_DEC_227 226
#define BOOST_PP_DEC_228 227
#define BOOST_PP_DEC_229 228
#define BOOST_PP_DEC_230 229
#define BOOST_PP_DEC_231 230
#define BOOST_PP_DEC_232 231
#define BOOST_PP_DEC_233 232
#define BOOST_PP_DEC_234 233
#define BOOST_PP_DEC_235 234
#define BOOST_PP_DEC_236 235
#define BOOST_PP_DEC_237 236
#define BOOST_PP_DEC_238 237
#define BOOST_PP_DEC_239 238
#define BOOST_PP_DEC_240 239
#define BOOST_PP_DEC_241 240
#define BOOST_PP_DEC_242 241
#define BOOST_PP_DEC_243 242
#define BOOST_PP_DEC_244 243
#define BOOST_PP_DEC_245 244
#define BOOST_PP_DEC_246 245
#define BOOST_PP_DEC_247 246
#define BOOST_PP_DEC_248 247
#define BOOST_PP_DEC_249 248
#define BOOST_PP_DEC_250 249
#define BOOST_PP_DEC_251 250
#define BOOST_PP_DEC_252 251
#define BOOST_PP_DEC_253 252
#define BOOST_PP_DEC_254 253
#define BOOST_PP_DEC_255 254
#define BOOST_PP_DEC_256 255

#define BOOST_PP_DEDUCE_D BOOST_PP_AUTO_REC(BOOST_PP_WHILE_P,256)
#define BOOST_PP_DEDUCE_R BOOST_PP_AUTO_REC(BOOST_PP_FOR_P,256)
#define BOOST_PP_DEDUCE_Z BOOST_PP_AUTO_REC(BOOST_PP_REPEAT_P,4)

#define BOOST_PP_DIV(x, y) BOOST_PP_TUPLE_ELEM(3, 0, BOOST_PP_DIV_BASE(x, y))
#define BOOST_PP_DIV_BASE(x, y) BOOST_PP_WHILE(BOOST_PP_DIV_BASE_P, BOOST_PP_DIV_BASE_O, (0, x, y))
#define BOOST_PP_DIV_BASE_D(d, x, y) BOOST_PP_WHILE_ ## d(BOOST_PP_DIV_BASE_P, BOOST_PP_DIV_BASE_O, (0, x, y))
#define BOOST_PP_DIV_BASE_O(d, rxy) BOOST_PP_DIV_BASE_O_I(d, BOOST_PP_TUPLE_ELEM(3, 0, rxy), BOOST_PP_TUPLE_ELEM(3, 1, rxy), BOOST_PP_TUPLE_ELEM(3, 2, rxy))
#define BOOST_PP_DIV_BASE_O_I(d, r, x, y) (BOOST_PP_INC(r), BOOST_PP_SUB_D(d, x, y), y)
#define BOOST_PP_DIV_BASE_P(d, rxy) BOOST_PP_DIV_BASE_P_I(d, BOOST_PP_TUPLE_ELEM(3, 0, rxy), BOOST_PP_TUPLE_ELEM(3, 1, rxy), BOOST_PP_TUPLE_ELEM(3, 2, rxy))
#define BOOST_PP_DIV_BASE_P_I(d, r, x, y) BOOST_PP_LESS_EQUAL_D(d, y, x)
#define BOOST_PP_DIV_D(d, x, y) BOOST_PP_TUPLE_ELEM(3, 0, BOOST_PP_DIV_BASE_D(d, x, y))

#define BOOST_PP_EMPTY()

#define BOOST_PP_ENUM BOOST_PP_CAT(BOOST_PP_ENUM_, BOOST_PP_AUTO_REC(BOOST_PP_REPEAT_P, 4))
#define BOOST_PP_ENUM_1(c, m, d) BOOST_PP_REPEAT_1(c, BOOST_PP_ENUM_M_1, (m, d))
#define BOOST_PP_ENUM_2(c, m, d) BOOST_PP_REPEAT_2(c, BOOST_PP_ENUM_M_2, (m, d))
#define BOOST_PP_ENUM_3(c, m, d) BOOST_PP_REPEAT_3(c, BOOST_PP_ENUM_M_3, (m, d))
#define BOOST_PP_ENUM_M_1(z, n, md) BOOST_PP_ENUM_M_1_IM(z, n, BOOST_PP_TUPLE_REM_2 md)
#define BOOST_PP_ENUM_M_2(z, n, md) BOOST_PP_ENUM_M_2_IM(z, n, BOOST_PP_TUPLE_REM_2 md)
#define BOOST_PP_ENUM_M_3(z, n, md) BOOST_PP_ENUM_M_3_IM(z, n, BOOST_PP_TUPLE_REM_2 md)
#define BOOST_PP_ENUM_M_1_I(z, n, m, d) BOOST_PP_COMMA_IF(n) m(z, n, d)
#define BOOST_PP_ENUM_M_2_I(z, n, m, d) BOOST_PP_COMMA_IF(n) m(z, n, d)
#define BOOST_PP_ENUM_M_3_I(z, n, m, d) BOOST_PP_COMMA_IF(n) m(z, n, d)
#define BOOST_PP_ENUM_M_1_IM(z, n, im) BOOST_PP_ENUM_M_1_I(z, n, im)
#define BOOST_PP_ENUM_M_2_IM(z, n, im) BOOST_PP_ENUM_M_2_I(z, n, im)
#define BOOST_PP_ENUM_M_3_IM(z, n, im) BOOST_PP_ENUM_M_3_I(z, n, im)

#define BOOST_PP_ENUM_BINARY_PARAMS(count, p1, p2) BOOST_PP_REPEAT(count, BOOST_PP_ENUM_BINARY_PARAMS_M, (p1, p2))
#define BOOST_PP_ENUM_BINARY_PARAMS_M(z, n, pp) BOOST_PP_ENUM_BINARY_PARAMS_M_IM(z, n, BOOST_PP_TUPLE_REM_2 pp)
#define BOOST_PP_ENUM_BINARY_PARAMS_M_I(z, n, p1, p2) BOOST_PP_ENUM_BINARY_PARAMS_M_II(z, n, p1, p2)
#define BOOST_PP_ENUM_BINARY_PARAMS_M_II(z, n, p1, p2) BOOST_PP_COMMA_IF(n) p1 ## n p2 ## n
#define BOOST_PP_ENUM_BINARY_PARAMS_M_IM(z, n, im) BOOST_PP_ENUM_BINARY_PARAMS_M_I(z, n, im)
#define BOOST_PP_ENUM_BINARY_PARAMS_Z(z, count, p1, p2) BOOST_PP_REPEAT_ ## z(count, BOOST_PP_ENUM_BINARY_PARAMS_M, (p1, p2))

#define BOOST_PP_ENUM_PARAMS(count, param) BOOST_PP_REPEAT(count, BOOST_PP_ENUM_PARAMS_M, param)

#define BOOST_PP_ENUM_PARAMS_I(count, param) BOOST_PP_REPEAT(count,BOOST_PP_ENUM_PARAMS_M,param)
#define BOOST_PP_ENUM_PARAMS_M(z, n, param) BOOST_PP_COMMA_IF(n) param ## n
#define BOOST_PP_ENUM_PARAMS_WITH_A_DEFAULT(count, param, def) BOOST_PP_ENUM_BINARY_PARAMS(count, param, = def BOOST_PP_INTERCEPT)
#define BOOST_PP_ENUM_PARAMS_WITH_DEFAULTS(count, param, def) BOOST_PP_ENUM_BINARY_PARAMS(count, param, = def)
#define BOOST_PP_ENUM_PARAMS_Z(z, count, param) BOOST_PP_REPEAT_ ## z(count, BOOST_PP_ENUM_PARAMS_M, param)

#define BOOST_PP_ENUM_SHIFTED BOOST_PP_CAT(BOOST_PP_ENUM_SHIFTED_, BOOST_PP_AUTO_REC(BOOST_PP_REPEAT_P, 4))
#define BOOST_PP_ENUM_SHIFTED_1(c, m, d) BOOST_PP_REPEAT_1(BOOST_PP_DEC(c), BOOST_PP_ENUM_SHIFTED_M_1, (m, d))
#define BOOST_PP_ENUM_SHIFTED_2(c, m, d) BOOST_PP_REPEAT_2(BOOST_PP_DEC(c), BOOST_PP_ENUM_SHIFTED_M_2, (m, d))
#define BOOST_PP_ENUM_SHIFTED_3(c, m, d) BOOST_PP_REPEAT_3(BOOST_PP_DEC(c), BOOST_PP_ENUM_SHIFTED_M_3, (m, d))
#define BOOST_PP_ENUM_SHIFTED_4(c, m, d) BOOST_PP_ERROR(0x0003)
#define BOOST_PP_ENUM_SHIFTED_M_1(z, n, md) BOOST_PP_ENUM_SHIFTED_M_1_IM(z, n, BOOST_PP_TUPLE_REM_2 md)
#define BOOST_PP_ENUM_SHIFTED_M_2(z, n, md) BOOST_PP_ENUM_SHIFTED_M_2_IM(z, n, BOOST_PP_TUPLE_REM_2 md)
#define BOOST_PP_ENUM_SHIFTED_M_3(z, n, md) BOOST_PP_ENUM_SHIFTED_M_3_IM(z, n, BOOST_PP_TUPLE_REM_2 md)
#define BOOST_PP_ENUM_SHIFTED_M_1_IM(z, n, im) BOOST_PP_ENUM_SHIFTED_M_1_I(z, n, im)
#define BOOST_PP_ENUM_SHIFTED_M_2_IM(z, n, im) BOOST_PP_ENUM_SHIFTED_M_2_I(z, n, im)
#define BOOST_PP_ENUM_SHIFTED_M_3_IM(z, n, im) BOOST_PP_ENUM_SHIFTED_M_3_I(z, n, im)

#define BOOST_PP_ENUM_SHIFTED_PARAMS(count, param) BOOST_PP_REPEAT(BOOST_PP_DEC(count), BOOST_PP_ENUM_SHIFTED_PARAMS_M, param)
#define BOOST_PP_ENUM_SHIFTED_PARAMS_M(z, n, param) BOOST_PP_COMMA_IF(n) BOOST_PP_CAT(param, BOOST_PP_INC(n))
#define BOOST_PP_ENUM_SHIFTED_PARAMS_Z(z, count, param) BOOST_PP_REPEAT_ ## z(BOOST_PP_DEC(count), BOOST_PP_ENUM_SHIFTED_PARAMS_M, param)

#define BOOST_PP_ENUM_TRAILING BOOST_PP_CAT(BOOST_PP_ENUM_TRAILING_, BOOST_PP_AUTO_REC(BOOST_PP_REPEAT_P, 4))
#define BOOST_PP_ENUM_TRAILING_1(c, m, d) BOOST_PP_REPEAT_1(c, BOOST_PP_ENUM_TRAILING_M_1, (m, d))
#define BOOST_PP_ENUM_TRAILING_2(c, m, d) BOOST_PP_REPEAT_2(c, BOOST_PP_ENUM_TRAILING_M_2, (m, d))
#define BOOST_PP_ENUM_TRAILING_3(c, m, d) BOOST_PP_REPEAT_3(c, BOOST_PP_ENUM_TRAILING_M_3, (m, d))
#define BOOST_PP_ENUM_TRAILING_4(c, m, d) BOOST_PP_ERROR(0x0003)

#define BOOST_PP_ENUM_TRAILING_BINARY_PARAMS(count, p1, p2) BOOST_PP_REPEAT(count, BOOST_PP_ENUM_TRAILING_BINARY_PARAMS_M, (p1, p2))
#define BOOST_PP_ENUM_TRAILING_BINARY_PARAMS_M(z, n, pp) BOOST_PP_ENUM_TRAILING_BINARY_PARAMS_M_IM(z, n, BOOST_PP_TUPLE_REM_2 pp)
#define BOOST_PP_ENUM_TRAILING_BINARY_PARAMS_M_I(z, n, p1, p2) BOOST_PP_ENUM_TRAILING_BINARY_PARAMS_M_II(z, n, p1, p2)
#define BOOST_PP_ENUM_TRAILING_BINARY_PARAMS_M_II(z, n, p1, p2) , p1 ## n p2 ## n
#define BOOST_PP_ENUM_TRAILING_BINARY_PARAMS_M_IM(z, n, im) BOOST_PP_ENUM_TRAILING_BINARY_PARAMS_M_I(z, n, im)
#define BOOST_PP_ENUM_TRAILING_BINARY_PARAMS_Z(z, count, p1, p2) BOOST_PP_REPEAT_ ## z(count, BOOST_PP_ENUM_TRAILING_BINARY_PARAMS_M, (p1, p2))
#define BOOST_PP_ENUM_TRAILING_M_1(z, n, md) BOOST_PP_ENUM_TRAILING_M_1_IM(z, n, BOOST_PP_TUPLE_REM_2 md)
#define BOOST_PP_ENUM_TRAILING_M_2(z, n, md) BOOST_PP_ENUM_TRAILING_M_2_IM(z, n, BOOST_PP_TUPLE_REM_2 md)
#define BOOST_PP_ENUM_TRAILING_M_3(z, n, md) BOOST_PP_ENUM_TRAILING_M_3_IM(z, n, BOOST_PP_TUPLE_REM_2 md)
#define BOOST_PP_ENUM_TRAILING_M_1_I(z, n, m, d) , m(z, n, d)
#define BOOST_PP_ENUM_TRAILING_M_2_I(z, n, m, d) , m(z, n, d)
#define BOOST_PP_ENUM_TRAILING_M_3_I(z, n, m, d) , m(z, n, d)
#define BOOST_PP_ENUM_TRAILING_M_1_IM(z, n, im) BOOST_PP_ENUM_TRAILING_M_1_I(z, n, im)
#define BOOST_PP_ENUM_TRAILING_M_2_IM(z, n, im) BOOST_PP_ENUM_TRAILING_M_2_I(z, n, im)
#define BOOST_PP_ENUM_TRAILING_M_3_IM(z, n, im) BOOST_PP_ENUM_TRAILING_M_3_I(z, n, im)

#define BOOST_PP_ENUM_TRAILING_PARAMS(count, param) BOOST_PP_REPEAT(count, BOOST_PP_ENUM_TRAILING_PARAMS_M, param)
#define BOOST_PP_ENUM_TRAILING_PARAMS_M(z, n, param) , param ## n
#define BOOST_PP_ENUM_TRAILING_PARAMS_Z(z, count, param) BOOST_PP_REPEAT_ ## z(count, BOOST_PP_ENUM_TRAILING_PARAMS_M, param)

#define BOOST_PP_EQUAL(x, y) BOOST_PP_COMPL(BOOST_PP_NOT_EQUAL(x, y))
#define BOOST_PP_EQUAL_D(d, x, y) BOOST_PP_EQUAL(x, y)

#define BOOST_PP_ERROR(code) BOOST_PP_CAT(BOOST_PP_ERROR_, code)
#define BOOST_PP_ERROR_0x0000 BOOST_PP_ERROR(0x0000, BOOST_PP_INDEX_OUT_OF_BOUNDS)
#define BOOST_PP_ERROR_0x0001 BOOST_PP_ERROR(0x0001, BOOST_PP_WHILE_OVERFLOW)
#define BOOST_PP_ERROR_0x0002 BOOST_PP_ERROR(0x0002, BOOST_PP_FOR_OVERFLOW)
#define BOOST_PP_ERROR_0x0003 BOOST_PP_ERROR(0x0003, BOOST_PP_REPEAT_OVERFLOW)
#define BOOST_PP_ERROR_0x0004 BOOST_PP_ERROR(0x0004, BOOST_PP_LIST_FOLD_OVERFLOW)
#define BOOST_PP_ERROR_0x0005 BOOST_PP_ERROR(0x0005, BOOST_PP_SEQ_FOLD_OVERFLOW)
#define BOOST_PP_ERROR_0x0006 BOOST_PP_ERROR(0x0006, BOOST_PP_ARITHMETIC_OVERFLOW)
#define BOOST_PP_ERROR_0x0007 BOOST_PP_ERROR(0x0007, BOOST_PP_DIVISION_BY_ZERO)

#define BOOST_PP_EXPAND(x) BOOST_PP_EXPAND_I(x)
#define BOOST_PP_EXPAND_I(x) x

#define BOOST_PP_EXPR_IF(cond, expr) BOOST_PP_EXPR_IIF(BOOST_PP_BOOL(cond), expr)
#define BOOST_PP_EXPR_IIF(bit, expr) BOOST_PP_EXPR_IIF_I(bit, expr)
#define BOOST_PP_EXPR_IIF_I(bit, expr) BOOST_PP_EXPR_IIF_ ## bit(expr)
#define BOOST_PP_EXPR_IIF_0(expr)
#define BOOST_PP_EXPR_IIF_1(expr) expr

#define BOOST_PP_FOR BOOST_PP_CAT(BOOST_PP_FOR_, BOOST_PP_AUTO_REC(BOOST_PP_FOR_P, 256))

#define BOOST_PP_FOR_1(s, p, o, m) BOOST_PP_FOR_1_C(BOOST_PP_BOOL(p##(2, s)), s, p, o, m)
#define BOOST_PP_FOR_2(s, p, o, m) BOOST_PP_FOR_2_C(BOOST_PP_BOOL(p##(3, s)), s, p, o, m)
#define BOOST_PP_FOR_3(s, p, o, m) BOOST_PP_FOR_3_C(BOOST_PP_BOOL(p##(4, s)), s, p, o, m)
#define BOOST_PP_FOR_4(s, p, o, m) BOOST_PP_FOR_4_C(BOOST_PP_BOOL(p##(5, s)), s, p, o, m)
#define BOOST_PP_FOR_5(s, p, o, m) BOOST_PP_FOR_5_C(BOOST_PP_BOOL(p##(6, s)), s, p, o, m)
#define BOOST_PP_FOR_6(s, p, o, m) BOOST_PP_FOR_6_C(BOOST_PP_BOOL(p##(7, s)), s, p, o, m)
#define BOOST_PP_FOR_7(s, p, o, m) BOOST_PP_FOR_7_C(BOOST_PP_BOOL(p##(8, s)), s, p, o, m)
#define BOOST_PP_FOR_8(s, p, o, m) BOOST_PP_FOR_8_C(BOOST_PP_BOOL(p##(9, s)), s, p, o, m)
#define BOOST_PP_FOR_9(s, p, o, m) BOOST_PP_FOR_9_C(BOOST_PP_BOOL(p##(10, s)), s, p, o, m)
#define BOOST_PP_FOR_10(s, p, o, m) BOOST_PP_FOR_10_C(BOOST_PP_BOOL(p##(11, s)), s, p, o, m)
#define BOOST_PP_FOR_11(s, p, o, m) BOOST_PP_FOR_11_C(BOOST_PP_BOOL(p##(12, s)), s, p, o, m)
#define BOOST_PP_FOR_12(s, p, o, m) BOOST_PP_FOR_12_C(BOOST_PP_BOOL(p##(13, s)), s, p, o, m)
#define BOOST_PP_FOR_13(s, p, o, m) BOOST_PP_FOR_13_C(BOOST_PP_BOOL(p##(14, s)), s, p, o, m)
#define BOOST_PP_FOR_14(s, p, o, m) BOOST_PP_FOR_14_C(BOOST_PP_BOOL(p##(15, s)), s, p, o, m)
#define BOOST_PP_FOR_15(s, p, o, m) BOOST_PP_FOR_15_C(BOOST_PP_BOOL(p##(16, s)), s, p, o, m)
#define BOOST_PP_FOR_16(s, p, o, m) BOOST_PP_FOR_16_C(BOOST_PP_BOOL(p##(17, s)), s, p, o, m)
#define BOOST_PP_FOR_17(s, p, o, m) BOOST_PP_FOR_17_C(BOOST_PP_BOOL(p##(18, s)), s, p, o, m)
#define BOOST_PP_FOR_18(s, p, o, m) BOOST_PP_FOR_18_C(BOOST_PP_BOOL(p##(19, s)), s, p, o, m)
#define BOOST_PP_FOR_19(s, p, o, m) BOOST_PP_FOR_19_C(BOOST_PP_BOOL(p##(20, s)), s, p, o, m)
#define BOOST_PP_FOR_20(s, p, o, m) BOOST_PP_FOR_20_C(BOOST_PP_BOOL(p##(21, s)), s, p, o, m)
#define BOOST_PP_FOR_21(s, p, o, m) BOOST_PP_FOR_21_C(BOOST_PP_BOOL(p##(22, s)), s, p, o, m)
#define BOOST_PP_FOR_22(s, p, o, m) BOOST_PP_FOR_22_C(BOOST_PP_BOOL(p##(23, s)), s, p, o, m)
#define BOOST_PP_FOR_23(s, p, o, m) BOOST_PP_FOR_23_C(BOOST_PP_BOOL(p##(24, s)), s, p, o, m)
#define BOOST_PP_FOR_24(s, p, o, m) BOOST_PP_FOR_24_C(BOOST_PP_BOOL(p##(25, s)), s, p, o, m)
#define BOOST_PP_FOR_25(s, p, o, m) BOOST_PP_FOR_25_C(BOOST_PP_BOOL(p##(26, s)), s, p, o, m)
#define BOOST_PP_FOR_26(s, p, o, m) BOOST_PP_FOR_26_C(BOOST_PP_BOOL(p##(27, s)), s, p, o, m)
#define BOOST_PP_FOR_27(s, p, o, m) BOOST_PP_FOR_27_C(BOOST_PP_BOOL(p##(28, s)), s, p, o, m)
#define BOOST_PP_FOR_28(s, p, o, m) BOOST_PP_FOR_28_C(BOOST_PP_BOOL(p##(29, s)), s, p, o, m)
#define BOOST_PP_FOR_29(s, p, o, m) BOOST_PP_FOR_29_C(BOOST_PP_BOOL(p##(30, s)), s, p, o, m)
#define BOOST_PP_FOR_30(s, p, o, m) BOOST_PP_FOR_30_C(BOOST_PP_BOOL(p##(31, s)), s, p, o, m)
#define BOOST_PP_FOR_31(s, p, o, m) BOOST_PP_FOR_31_C(BOOST_PP_BOOL(p##(32, s)), s, p, o, m)
#define BOOST_PP_FOR_32(s, p, o, m) BOOST_PP_FOR_32_C(BOOST_PP_BOOL(p##(33, s)), s, p, o, m)
#define BOOST_PP_FOR_33(s, p, o, m) BOOST_PP_FOR_33_C(BOOST_PP_BOOL(p##(34, s)), s, p, o, m)
#define BOOST_PP_FOR_34(s, p, o, m) BOOST_PP_FOR_34_C(BOOST_PP_BOOL(p##(35, s)), s, p, o, m)
#define BOOST_PP_FOR_35(s, p, o, m) BOOST_PP_FOR_35_C(BOOST_PP_BOOL(p##(36, s)), s, p, o, m)
#define BOOST_PP_FOR_36(s, p, o, m) BOOST_PP_FOR_36_C(BOOST_PP_BOOL(p##(37, s)), s, p, o, m)
#define BOOST_PP_FOR_37(s, p, o, m) BOOST_PP_FOR_37_C(BOOST_PP_BOOL(p##(38, s)), s, p, o, m)
#define BOOST_PP_FOR_38(s, p, o, m) BOOST_PP_FOR_38_C(BOOST_PP_BOOL(p##(39, s)), s, p, o, m)
#define BOOST_PP_FOR_39(s, p, o, m) BOOST_PP_FOR_39_C(BOOST_PP_BOOL(p##(40, s)), s, p, o, m)
#define BOOST_PP_FOR_40(s, p, o, m) BOOST_PP_FOR_40_C(BOOST_PP_BOOL(p##(41, s)), s, p, o, m)
#define BOOST_PP_FOR_41(s, p, o, m) BOOST_PP_FOR_41_C(BOOST_PP_BOOL(p##(42, s)), s, p, o, m)
#define BOOST_PP_FOR_42(s, p, o, m) BOOST_PP_FOR_42_C(BOOST_PP_BOOL(p##(43, s)), s, p, o, m)
#define BOOST_PP_FOR_43(s, p, o, m) BOOST_PP_FOR_43_C(BOOST_PP_BOOL(p##(44, s)), s, p, o, m)
#define BOOST_PP_FOR_44(s, p, o, m) BOOST_PP_FOR_44_C(BOOST_PP_BOOL(p##(45, s)), s, p, o, m)
#define BOOST_PP_FOR_45(s, p, o, m) BOOST_PP_FOR_45_C(BOOST_PP_BOOL(p##(46, s)), s, p, o, m)
#define BOOST_PP_FOR_46(s, p, o, m) BOOST_PP_FOR_46_C(BOOST_PP_BOOL(p##(47, s)), s, p, o, m)
#define BOOST_PP_FOR_47(s, p, o, m) BOOST_PP_FOR_47_C(BOOST_PP_BOOL(p##(48, s)), s, p, o, m)
#define BOOST_PP_FOR_48(s, p, o, m) BOOST_PP_FOR_48_C(BOOST_PP_BOOL(p##(49, s)), s, p, o, m)
#define BOOST_PP_FOR_49(s, p, o, m) BOOST_PP_FOR_49_C(BOOST_PP_BOOL(p##(50, s)), s, p, o, m)
#define BOOST_PP_FOR_50(s, p, o, m) BOOST_PP_FOR_50_C(BOOST_PP_BOOL(p##(51, s)), s, p, o, m)
#define BOOST_PP_FOR_51(s, p, o, m) BOOST_PP_FOR_51_C(BOOST_PP_BOOL(p##(52, s)), s, p, o, m)
#define BOOST_PP_FOR_52(s, p, o, m) BOOST_PP_FOR_52_C(BOOST_PP_BOOL(p##(53, s)), s, p, o, m)
#define BOOST_PP_FOR_53(s, p, o, m) BOOST_PP_FOR_53_C(BOOST_PP_BOOL(p##(54, s)), s, p, o, m)
#define BOOST_PP_FOR_54(s, p, o, m) BOOST_PP_FOR_54_C(BOOST_PP_BOOL(p##(55, s)), s, p, o, m)
#define BOOST_PP_FOR_55(s, p, o, m) BOOST_PP_FOR_55_C(BOOST_PP_BOOL(p##(56, s)), s, p, o, m)
#define BOOST_PP_FOR_56(s, p, o, m) BOOST_PP_FOR_56_C(BOOST_PP_BOOL(p##(57, s)), s, p, o, m)
#define BOOST_PP_FOR_57(s, p, o, m) BOOST_PP_FOR_57_C(BOOST_PP_BOOL(p##(58, s)), s, p, o, m)
#define BOOST_PP_FOR_58(s, p, o, m) BOOST_PP_FOR_58_C(BOOST_PP_BOOL(p##(59, s)), s, p, o, m)
#define BOOST_PP_FOR_59(s, p, o, m) BOOST_PP_FOR_59_C(BOOST_PP_BOOL(p##(60, s)), s, p, o, m)
#define BOOST_PP_FOR_60(s, p, o, m) BOOST_PP_FOR_60_C(BOOST_PP_BOOL(p##(61, s)), s, p, o, m)
#define BOOST_PP_FOR_61(s, p, o, m) BOOST_PP_FOR_61_C(BOOST_PP_BOOL(p##(62, s)), s, p, o, m)
#define BOOST_PP_FOR_62(s, p, o, m) BOOST_PP_FOR_62_C(BOOST_PP_BOOL(p##(63, s)), s, p, o, m)
#define BOOST_PP_FOR_63(s, p, o, m) BOOST_PP_FOR_63_C(BOOST_PP_BOOL(p##(64, s)), s, p, o, m)
#define BOOST_PP_FOR_64(s, p, o, m) BOOST_PP_FOR_64_C(BOOST_PP_BOOL(p##(65, s)), s, p, o, m)
#define BOOST_PP_FOR_65(s, p, o, m) BOOST_PP_FOR_65_C(BOOST_PP_BOOL(p##(66, s)), s, p, o, m)
#define BOOST_PP_FOR_66(s, p, o, m) BOOST_PP_FOR_66_C(BOOST_PP_BOOL(p##(67, s)), s, p, o, m)
#define BOOST_PP_FOR_67(s, p, o, m) BOOST_PP_FOR_67_C(BOOST_PP_BOOL(p##(68, s)), s, p, o, m)
#define BOOST_PP_FOR_68(s, p, o, m) BOOST_PP_FOR_68_C(BOOST_PP_BOOL(p##(69, s)), s, p, o, m)
#define BOOST_PP_FOR_69(s, p, o, m) BOOST_PP_FOR_69_C(BOOST_PP_BOOL(p##(70, s)), s, p, o, m)
#define BOOST_PP_FOR_70(s, p, o, m) BOOST_PP_FOR_70_C(BOOST_PP_BOOL(p##(71, s)), s, p, o, m)
#define BOOST_PP_FOR_71(s, p, o, m) BOOST_PP_FOR_71_C(BOOST_PP_BOOL(p##(72, s)), s, p, o, m)
#define BOOST_PP_FOR_72(s, p, o, m) BOOST_PP_FOR_72_C(BOOST_PP_BOOL(p##(73, s)), s, p, o, m)
#define BOOST_PP_FOR_73(s, p, o, m) BOOST_PP_FOR_73_C(BOOST_PP_BOOL(p##(74, s)), s, p, o, m)
#define BOOST_PP_FOR_74(s, p, o, m) BOOST_PP_FOR_74_C(BOOST_PP_BOOL(p##(75, s)), s, p, o, m)
#define BOOST_PP_FOR_75(s, p, o, m) BOOST_PP_FOR_75_C(BOOST_PP_BOOL(p##(76, s)), s, p, o, m)
#define BOOST_PP_FOR_76(s, p, o, m) BOOST_PP_FOR_76_C(BOOST_PP_BOOL(p##(77, s)), s, p, o, m)
#define BOOST_PP_FOR_77(s, p, o, m) BOOST_PP_FOR_77_C(BOOST_PP_BOOL(p##(78, s)), s, p, o, m)
#define BOOST_PP_FOR_78(s, p, o, m) BOOST_PP_FOR_78_C(BOOST_PP_BOOL(p##(79, s)), s, p, o, m)
#define BOOST_PP_FOR_79(s, p, o, m) BOOST_PP_FOR_79_C(BOOST_PP_BOOL(p##(80, s)), s, p, o, m)
#define BOOST_PP_FOR_80(s, p, o, m) BOOST_PP_FOR_80_C(BOOST_PP_BOOL(p##(81, s)), s, p, o, m)
#define BOOST_PP_FOR_81(s, p, o, m) BOOST_PP_FOR_81_C(BOOST_PP_BOOL(p##(82, s)), s, p, o, m)
#define BOOST_PP_FOR_82(s, p, o, m) BOOST_PP_FOR_82_C(BOOST_PP_BOOL(p##(83, s)), s, p, o, m)
#define BOOST_PP_FOR_83(s, p, o, m) BOOST_PP_FOR_83_C(BOOST_PP_BOOL(p##(84, s)), s, p, o, m)
#define BOOST_PP_FOR_84(s, p, o, m) BOOST_PP_FOR_84_C(BOOST_PP_BOOL(p##(85, s)), s, p, o, m)
#define BOOST_PP_FOR_85(s, p, o, m) BOOST_PP_FOR_85_C(BOOST_PP_BOOL(p##(86, s)), s, p, o, m)
#define BOOST_PP_FOR_86(s, p, o, m) BOOST_PP_FOR_86_C(BOOST_PP_BOOL(p##(87, s)), s, p, o, m)
#define BOOST_PP_FOR_87(s, p, o, m) BOOST_PP_FOR_87_C(BOOST_PP_BOOL(p##(88, s)), s, p, o, m)
#define BOOST_PP_FOR_88(s, p, o, m) BOOST_PP_FOR_88_C(BOOST_PP_BOOL(p##(89, s)), s, p, o, m)
#define BOOST_PP_FOR_89(s, p, o, m) BOOST_PP_FOR_89_C(BOOST_PP_BOOL(p##(90, s)), s, p, o, m)
#define BOOST_PP_FOR_90(s, p, o, m) BOOST_PP_FOR_90_C(BOOST_PP_BOOL(p##(91, s)), s, p, o, m)
#define BOOST_PP_FOR_91(s, p, o, m) BOOST_PP_FOR_91_C(BOOST_PP_BOOL(p##(92, s)), s, p, o, m)
#define BOOST_PP_FOR_92(s, p, o, m) BOOST_PP_FOR_92_C(BOOST_PP_BOOL(p##(93, s)), s, p, o, m)
#define BOOST_PP_FOR_93(s, p, o, m) BOOST_PP_FOR_93_C(BOOST_PP_BOOL(p##(94, s)), s, p, o, m)
#define BOOST_PP_FOR_94(s, p, o, m) BOOST_PP_FOR_94_C(BOOST_PP_BOOL(p##(95, s)), s, p, o, m)
#define BOOST_PP_FOR_95(s, p, o, m) BOOST_PP_FOR_95_C(BOOST_PP_BOOL(p##(96, s)), s, p, o, m)
#define BOOST_PP_FOR_96(s, p, o, m) BOOST_PP_FOR_96_C(BOOST_PP_BOOL(p##(97, s)), s, p, o, m)
#define BOOST_PP_FOR_97(s, p, o, m) BOOST_PP_FOR_97_C(BOOST_PP_BOOL(p##(98, s)), s, p, o, m)
#define BOOST_PP_FOR_98(s, p, o, m) BOOST_PP_FOR_98_C(BOOST_PP_BOOL(p##(99, s)), s, p, o, m)
#define BOOST_PP_FOR_99(s, p, o, m) BOOST_PP_FOR_99_C(BOOST_PP_BOOL(p##(100, s)), s, p, o, m)
#define BOOST_PP_FOR_100(s, p, o, m) BOOST_PP_FOR_100_C(BOOST_PP_BOOL(p##(101, s)), s, p, o, m)
#define BOOST_PP_FOR_101(s, p, o, m) BOOST_PP_FOR_101_C(BOOST_PP_BOOL(p##(102, s)), s, p, o, m)
#define BOOST_PP_FOR_102(s, p, o, m) BOOST_PP_FOR_102_C(BOOST_PP_BOOL(p##(103, s)), s, p, o, m)
#define BOOST_PP_FOR_103(s, p, o, m) BOOST_PP_FOR_103_C(BOOST_PP_BOOL(p##(104, s)), s, p, o, m)
#define BOOST_PP_FOR_104(s, p, o, m) BOOST_PP_FOR_104_C(BOOST_PP_BOOL(p##(105, s)), s, p, o, m)
#define BOOST_PP_FOR_105(s, p, o, m) BOOST_PP_FOR_105_C(BOOST_PP_BOOL(p##(106, s)), s, p, o, m)
#define BOOST_PP_FOR_106(s, p, o, m) BOOST_PP_FOR_106_C(BOOST_PP_BOOL(p##(107, s)), s, p, o, m)
#define BOOST_PP_FOR_107(s, p, o, m) BOOST_PP_FOR_107_C(BOOST_PP_BOOL(p##(108, s)), s, p, o, m)
#define BOOST_PP_FOR_108(s, p, o, m) BOOST_PP_FOR_108_C(BOOST_PP_BOOL(p##(109, s)), s, p, o, m)
#define BOOST_PP_FOR_109(s, p, o, m) BOOST_PP_FOR_109_C(BOOST_PP_BOOL(p##(110, s)), s, p, o, m)
#define BOOST_PP_FOR_110(s, p, o, m) BOOST_PP_FOR_110_C(BOOST_PP_BOOL(p##(111, s)), s, p, o, m)
#define BOOST_PP_FOR_111(s, p, o, m) BOOST_PP_FOR_111_C(BOOST_PP_BOOL(p##(112, s)), s, p, o, m)
#define BOOST_PP_FOR_112(s, p, o, m) BOOST_PP_FOR_112_C(BOOST_PP_BOOL(p##(113, s)), s, p, o, m)
#define BOOST_PP_FOR_113(s, p, o, m) BOOST_PP_FOR_113_C(BOOST_PP_BOOL(p##(114, s)), s, p, o, m)
#define BOOST_PP_FOR_114(s, p, o, m) BOOST_PP_FOR_114_C(BOOST_PP_BOOL(p##(115, s)), s, p, o, m)
#define BOOST_PP_FOR_115(s, p, o, m) BOOST_PP_FOR_115_C(BOOST_PP_BOOL(p##(116, s)), s, p, o, m)
#define BOOST_PP_FOR_116(s, p, o, m) BOOST_PP_FOR_116_C(BOOST_PP_BOOL(p##(117, s)), s, p, o, m)
#define BOOST_PP_FOR_117(s, p, o, m) BOOST_PP_FOR_117_C(BOOST_PP_BOOL(p##(118, s)), s, p, o, m)
#define BOOST_PP_FOR_118(s, p, o, m) BOOST_PP_FOR_118_C(BOOST_PP_BOOL(p##(119, s)), s, p, o, m)
#define BOOST_PP_FOR_119(s, p, o, m) BOOST_PP_FOR_119_C(BOOST_PP_BOOL(p##(120, s)), s, p, o, m)
#define BOOST_PP_FOR_120(s, p, o, m) BOOST_PP_FOR_120_C(BOOST_PP_BOOL(p##(121, s)), s, p, o, m)
#define BOOST_PP_FOR_121(s, p, o, m) BOOST_PP_FOR_121_C(BOOST_PP_BOOL(p##(122, s)), s, p, o, m)
#define BOOST_PP_FOR_122(s, p, o, m) BOOST_PP_FOR_122_C(BOOST_PP_BOOL(p##(123, s)), s, p, o, m)
#define BOOST_PP_FOR_123(s, p, o, m) BOOST_PP_FOR_123_C(BOOST_PP_BOOL(p##(124, s)), s, p, o, m)
#define BOOST_PP_FOR_124(s, p, o, m) BOOST_PP_FOR_124_C(BOOST_PP_BOOL(p##(125, s)), s, p, o, m)
#define BOOST_PP_FOR_125(s, p, o, m) BOOST_PP_FOR_125_C(BOOST_PP_BOOL(p##(126, s)), s, p, o, m)
#define BOOST_PP_FOR_126(s, p, o, m) BOOST_PP_FOR_126_C(BOOST_PP_BOOL(p##(127, s)), s, p, o, m)
#define BOOST_PP_FOR_127(s, p, o, m) BOOST_PP_FOR_127_C(BOOST_PP_BOOL(p##(128, s)), s, p, o, m)
#define BOOST_PP_FOR_128(s, p, o, m) BOOST_PP_FOR_128_C(BOOST_PP_BOOL(p##(129, s)), s, p, o, m)
#define BOOST_PP_FOR_129(s, p, o, m) BOOST_PP_FOR_129_C(BOOST_PP_BOOL(p##(130, s)), s, p, o, m)
#define BOOST_PP_FOR_130(s, p, o, m) BOOST_PP_FOR_130_C(BOOST_PP_BOOL(p##(131, s)), s, p, o, m)
#define BOOST_PP_FOR_131(s, p, o, m) BOOST_PP_FOR_131_C(BOOST_PP_BOOL(p##(132, s)), s, p, o, m)
#define BOOST_PP_FOR_132(s, p, o, m) BOOST_PP_FOR_132_C(BOOST_PP_BOOL(p##(133, s)), s, p, o, m)
#define BOOST_PP_FOR_133(s, p, o, m) BOOST_PP_FOR_133_C(BOOST_PP_BOOL(p##(134, s)), s, p, o, m)
#define BOOST_PP_FOR_134(s, p, o, m) BOOST_PP_FOR_134_C(BOOST_PP_BOOL(p##(135, s)), s, p, o, m)
#define BOOST_PP_FOR_135(s, p, o, m) BOOST_PP_FOR_135_C(BOOST_PP_BOOL(p##(136, s)), s, p, o, m)
#define BOOST_PP_FOR_136(s, p, o, m) BOOST_PP_FOR_136_C(BOOST_PP_BOOL(p##(137, s)), s, p, o, m)
#define BOOST_PP_FOR_137(s, p, o, m) BOOST_PP_FOR_137_C(BOOST_PP_BOOL(p##(138, s)), s, p, o, m)
#define BOOST_PP_FOR_138(s, p, o, m) BOOST_PP_FOR_138_C(BOOST_PP_BOOL(p##(139, s)), s, p, o, m)
#define BOOST_PP_FOR_139(s, p, o, m) BOOST_PP_FOR_139_C(BOOST_PP_BOOL(p##(140, s)), s, p, o, m)
#define BOOST_PP_FOR_140(s, p, o, m) BOOST_PP_FOR_140_C(BOOST_PP_BOOL(p##(141, s)), s, p, o, m)
#define BOOST_PP_FOR_141(s, p, o, m) BOOST_PP_FOR_141_C(BOOST_PP_BOOL(p##(142, s)), s, p, o, m)
#define BOOST_PP_FOR_142(s, p, o, m) BOOST_PP_FOR_142_C(BOOST_PP_BOOL(p##(143, s)), s, p, o, m)
#define BOOST_PP_FOR_143(s, p, o, m) BOOST_PP_FOR_143_C(BOOST_PP_BOOL(p##(144, s)), s, p, o, m)
#define BOOST_PP_FOR_144(s, p, o, m) BOOST_PP_FOR_144_C(BOOST_PP_BOOL(p##(145, s)), s, p, o, m)
#define BOOST_PP_FOR_145(s, p, o, m) BOOST_PP_FOR_145_C(BOOST_PP_BOOL(p##(146, s)), s, p, o, m)
#define BOOST_PP_FOR_146(s, p, o, m) BOOST_PP_FOR_146_C(BOOST_PP_BOOL(p##(147, s)), s, p, o, m)
#define BOOST_PP_FOR_147(s, p, o, m) BOOST_PP_FOR_147_C(BOOST_PP_BOOL(p##(148, s)), s, p, o, m)
#define BOOST_PP_FOR_148(s, p, o, m) BOOST_PP_FOR_148_C(BOOST_PP_BOOL(p##(149, s)), s, p, o, m)
#define BOOST_PP_FOR_149(s, p, o, m) BOOST_PP_FOR_149_C(BOOST_PP_BOOL(p##(150, s)), s, p, o, m)
#define BOOST_PP_FOR_150(s, p, o, m) BOOST_PP_FOR_150_C(BOOST_PP_BOOL(p##(151, s)), s, p, o, m)
#define BOOST_PP_FOR_151(s, p, o, m) BOOST_PP_FOR_151_C(BOOST_PP_BOOL(p##(152, s)), s, p, o, m)
#define BOOST_PP_FOR_152(s, p, o, m) BOOST_PP_FOR_152_C(BOOST_PP_BOOL(p##(153, s)), s, p, o, m)
#define BOOST_PP_FOR_153(s, p, o, m) BOOST_PP_FOR_153_C(BOOST_PP_BOOL(p##(154, s)), s, p, o, m)
#define BOOST_PP_FOR_154(s, p, o, m) BOOST_PP_FOR_154_C(BOOST_PP_BOOL(p##(155, s)), s, p, o, m)
#define BOOST_PP_FOR_155(s, p, o, m) BOOST_PP_FOR_155_C(BOOST_PP_BOOL(p##(156, s)), s, p, o, m)
#define BOOST_PP_FOR_156(s, p, o, m) BOOST_PP_FOR_156_C(BOOST_PP_BOOL(p##(157, s)), s, p, o, m)
#define BOOST_PP_FOR_157(s, p, o, m) BOOST_PP_FOR_157_C(BOOST_PP_BOOL(p##(158, s)), s, p, o, m)
#define BOOST_PP_FOR_158(s, p, o, m) BOOST_PP_FOR_158_C(BOOST_PP_BOOL(p##(159, s)), s, p, o, m)
#define BOOST_PP_FOR_159(s, p, o, m) BOOST_PP_FOR_159_C(BOOST_PP_BOOL(p##(160, s)), s, p, o, m)
#define BOOST_PP_FOR_160(s, p, o, m) BOOST_PP_FOR_160_C(BOOST_PP_BOOL(p##(161, s)), s, p, o, m)
#define BOOST_PP_FOR_161(s, p, o, m) BOOST_PP_FOR_161_C(BOOST_PP_BOOL(p##(162, s)), s, p, o, m)
#define BOOST_PP_FOR_162(s, p, o, m) BOOST_PP_FOR_162_C(BOOST_PP_BOOL(p##(163, s)), s, p, o, m)
#define BOOST_PP_FOR_163(s, p, o, m) BOOST_PP_FOR_163_C(BOOST_PP_BOOL(p##(164, s)), s, p, o, m)
#define BOOST_PP_FOR_164(s, p, o, m) BOOST_PP_FOR_164_C(BOOST_PP_BOOL(p##(165, s)), s, p, o, m)
#define BOOST_PP_FOR_165(s, p, o, m) BOOST_PP_FOR_165_C(BOOST_PP_BOOL(p##(166, s)), s, p, o, m)
#define BOOST_PP_FOR_166(s, p, o, m) BOOST_PP_FOR_166_C(BOOST_PP_BOOL(p##(167, s)), s, p, o, m)
#define BOOST_PP_FOR_167(s, p, o, m) BOOST_PP_FOR_167_C(BOOST_PP_BOOL(p##(168, s)), s, p, o, m)
#define BOOST_PP_FOR_168(s, p, o, m) BOOST_PP_FOR_168_C(BOOST_PP_BOOL(p##(169, s)), s, p, o, m)
#define BOOST_PP_FOR_169(s, p, o, m) BOOST_PP_FOR_169_C(BOOST_PP_BOOL(p##(170, s)), s, p, o, m)
#define BOOST_PP_FOR_170(s, p, o, m) BOOST_PP_FOR_170_C(BOOST_PP_BOOL(p##(171, s)), s, p, o, m)
#define BOOST_PP_FOR_171(s, p, o, m) BOOST_PP_FOR_171_C(BOOST_PP_BOOL(p##(172, s)), s, p, o, m)
#define BOOST_PP_FOR_172(s, p, o, m) BOOST_PP_FOR_172_C(BOOST_PP_BOOL(p##(173, s)), s, p, o, m)
#define BOOST_PP_FOR_173(s, p, o, m) BOOST_PP_FOR_173_C(BOOST_PP_BOOL(p##(174, s)), s, p, o, m)
#define BOOST_PP_FOR_174(s, p, o, m) BOOST_PP_FOR_174_C(BOOST_PP_BOOL(p##(175, s)), s, p, o, m)
#define BOOST_PP_FOR_175(s, p, o, m) BOOST_PP_FOR_175_C(BOOST_PP_BOOL(p##(176, s)), s, p, o, m)
#define BOOST_PP_FOR_176(s, p, o, m) BOOST_PP_FOR_176_C(BOOST_PP_BOOL(p##(177, s)), s, p, o, m)
#define BOOST_PP_FOR_177(s, p, o, m) BOOST_PP_FOR_177_C(BOOST_PP_BOOL(p##(178, s)), s, p, o, m)
#define BOOST_PP_FOR_178(s, p, o, m) BOOST_PP_FOR_178_C(BOOST_PP_BOOL(p##(179, s)), s, p, o, m)
#define BOOST_PP_FOR_179(s, p, o, m) BOOST_PP_FOR_179_C(BOOST_PP_BOOL(p##(180, s)), s, p, o, m)
#define BOOST_PP_FOR_180(s, p, o, m) BOOST_PP_FOR_180_C(BOOST_PP_BOOL(p##(181, s)), s, p, o, m)
#define BOOST_PP_FOR_181(s, p, o, m) BOOST_PP_FOR_181_C(BOOST_PP_BOOL(p##(182, s)), s, p, o, m)
#define BOOST_PP_FOR_182(s, p, o, m) BOOST_PP_FOR_182_C(BOOST_PP_BOOL(p##(183, s)), s, p, o, m)
#define BOOST_PP_FOR_183(s, p, o, m) BOOST_PP_FOR_183_C(BOOST_PP_BOOL(p##(184, s)), s, p, o, m)
#define BOOST_PP_FOR_184(s, p, o, m) BOOST_PP_FOR_184_C(BOOST_PP_BOOL(p##(185, s)), s, p, o, m)
#define BOOST_PP_FOR_185(s, p, o, m) BOOST_PP_FOR_185_C(BOOST_PP_BOOL(p##(186, s)), s, p, o, m)
#define BOOST_PP_FOR_186(s, p, o, m) BOOST_PP_FOR_186_C(BOOST_PP_BOOL(p##(187, s)), s, p, o, m)
#define BOOST_PP_FOR_187(s, p, o, m) BOOST_PP_FOR_187_C(BOOST_PP_BOOL(p##(188, s)), s, p, o, m)
#define BOOST_PP_FOR_188(s, p, o, m) BOOST_PP_FOR_188_C(BOOST_PP_BOOL(p##(189, s)), s, p, o, m)
#define BOOST_PP_FOR_189(s, p, o, m) BOOST_PP_FOR_189_C(BOOST_PP_BOOL(p##(190, s)), s, p, o, m)
#define BOOST_PP_FOR_190(s, p, o, m) BOOST_PP_FOR_190_C(BOOST_PP_BOOL(p##(191, s)), s, p, o, m)
#define BOOST_PP_FOR_191(s, p, o, m) BOOST_PP_FOR_191_C(BOOST_PP_BOOL(p##(192, s)), s, p, o, m)
#define BOOST_PP_FOR_192(s, p, o, m) BOOST_PP_FOR_192_C(BOOST_PP_BOOL(p##(193, s)), s, p, o, m)
#define BOOST_PP_FOR_193(s, p, o, m) BOOST_PP_FOR_193_C(BOOST_PP_BOOL(p##(194, s)), s, p, o, m)
#define BOOST_PP_FOR_194(s, p, o, m) BOOST_PP_FOR_194_C(BOOST_PP_BOOL(p##(195, s)), s, p, o, m)
#define BOOST_PP_FOR_195(s, p, o, m) BOOST_PP_FOR_195_C(BOOST_PP_BOOL(p##(196, s)), s, p, o, m)
#define BOOST_PP_FOR_196(s, p, o, m) BOOST_PP_FOR_196_C(BOOST_PP_BOOL(p##(197, s)), s, p, o, m)
#define BOOST_PP_FOR_197(s, p, o, m) BOOST_PP_FOR_197_C(BOOST_PP_BOOL(p##(198, s)), s, p, o, m)
#define BOOST_PP_FOR_198(s, p, o, m) BOOST_PP_FOR_198_C(BOOST_PP_BOOL(p##(199, s)), s, p, o, m)
#define BOOST_PP_FOR_199(s, p, o, m) BOOST_PP_FOR_199_C(BOOST_PP_BOOL(p##(200, s)), s, p, o, m)
#define BOOST_PP_FOR_200(s, p, o, m) BOOST_PP_FOR_200_C(BOOST_PP_BOOL(p##(201, s)), s, p, o, m)
#define BOOST_PP_FOR_201(s, p, o, m) BOOST_PP_FOR_201_C(BOOST_PP_BOOL(p##(202, s)), s, p, o, m)
#define BOOST_PP_FOR_202(s, p, o, m) BOOST_PP_FOR_202_C(BOOST_PP_BOOL(p##(203, s)), s, p, o, m)
#define BOOST_PP_FOR_203(s, p, o, m) BOOST_PP_FOR_203_C(BOOST_PP_BOOL(p##(204, s)), s, p, o, m)
#define BOOST_PP_FOR_204(s, p, o, m) BOOST_PP_FOR_204_C(BOOST_PP_BOOL(p##(205, s)), s, p, o, m)
#define BOOST_PP_FOR_205(s, p, o, m) BOOST_PP_FOR_205_C(BOOST_PP_BOOL(p##(206, s)), s, p, o, m)
#define BOOST_PP_FOR_206(s, p, o, m) BOOST_PP_FOR_206_C(BOOST_PP_BOOL(p##(207, s)), s, p, o, m)
#define BOOST_PP_FOR_207(s, p, o, m) BOOST_PP_FOR_207_C(BOOST_PP_BOOL(p##(208, s)), s, p, o, m)
#define BOOST_PP_FOR_208(s, p, o, m) BOOST_PP_FOR_208_C(BOOST_PP_BOOL(p##(209, s)), s, p, o, m)
#define BOOST_PP_FOR_209(s, p, o, m) BOOST_PP_FOR_209_C(BOOST_PP_BOOL(p##(210, s)), s, p, o, m)
#define BOOST_PP_FOR_210(s, p, o, m) BOOST_PP_FOR_210_C(BOOST_PP_BOOL(p##(211, s)), s, p, o, m)
#define BOOST_PP_FOR_211(s, p, o, m) BOOST_PP_FOR_211_C(BOOST_PP_BOOL(p##(212, s)), s, p, o, m)
#define BOOST_PP_FOR_212(s, p, o, m) BOOST_PP_FOR_212_C(BOOST_PP_BOOL(p##(213, s)), s, p, o, m)
#define BOOST_PP_FOR_213(s, p, o, m) BOOST_PP_FOR_213_C(BOOST_PP_BOOL(p##(214, s)), s, p, o, m)
#define BOOST_PP_FOR_214(s, p, o, m) BOOST_PP_FOR_214_C(BOOST_PP_BOOL(p##(215, s)), s, p, o, m)
#define BOOST_PP_FOR_215(s, p, o, m) BOOST_PP_FOR_215_C(BOOST_PP_BOOL(p##(216, s)), s, p, o, m)
#define BOOST_PP_FOR_216(s, p, o, m) BOOST_PP_FOR_216_C(BOOST_PP_BOOL(p##(217, s)), s, p, o, m)
#define BOOST_PP_FOR_217(s, p, o, m) BOOST_PP_FOR_217_C(BOOST_PP_BOOL(p##(218, s)), s, p, o, m)
#define BOOST_PP_FOR_218(s, p, o, m) BOOST_PP_FOR_218_C(BOOST_PP_BOOL(p##(219, s)), s, p, o, m)
#define BOOST_PP_FOR_219(s, p, o, m) BOOST_PP_FOR_219_C(BOOST_PP_BOOL(p##(220, s)), s, p, o, m)
#define BOOST_PP_FOR_220(s, p, o, m) BOOST_PP_FOR_220_C(BOOST_PP_BOOL(p##(221, s)), s, p, o, m)
#define BOOST_PP_FOR_221(s, p, o, m) BOOST_PP_FOR_221_C(BOOST_PP_BOOL(p##(222, s)), s, p, o, m)
#define BOOST_PP_FOR_222(s, p, o, m) BOOST_PP_FOR_222_C(BOOST_PP_BOOL(p##(223, s)), s, p, o, m)
#define BOOST_PP_FOR_223(s, p, o, m) BOOST_PP_FOR_223_C(BOOST_PP_BOOL(p##(224, s)), s, p, o, m)
#define BOOST_PP_FOR_224(s, p, o, m) BOOST_PP_FOR_224_C(BOOST_PP_BOOL(p##(225, s)), s, p, o, m)
#define BOOST_PP_FOR_225(s, p, o, m) BOOST_PP_FOR_225_C(BOOST_PP_BOOL(p##(226, s)), s, p, o, m)
#define BOOST_PP_FOR_226(s, p, o, m) BOOST_PP_FOR_226_C(BOOST_PP_BOOL(p##(227, s)), s, p, o, m)
#define BOOST_PP_FOR_227(s, p, o, m) BOOST_PP_FOR_227_C(BOOST_PP_BOOL(p##(228, s)), s, p, o, m)
#define BOOST_PP_FOR_228(s, p, o, m) BOOST_PP_FOR_228_C(BOOST_PP_BOOL(p##(229, s)), s, p, o, m)
#define BOOST_PP_FOR_229(s, p, o, m) BOOST_PP_FOR_229_C(BOOST_PP_BOOL(p##(230, s)), s, p, o, m)
#define BOOST_PP_FOR_230(s, p, o, m) BOOST_PP_FOR_230_C(BOOST_PP_BOOL(p##(231, s)), s, p, o, m)
#define BOOST_PP_FOR_231(s, p, o, m) BOOST_PP_FOR_231_C(BOOST_PP_BOOL(p##(232, s)), s, p, o, m)
#define BOOST_PP_FOR_232(s, p, o, m) BOOST_PP_FOR_232_C(BOOST_PP_BOOL(p##(233, s)), s, p, o, m)
#define BOOST_PP_FOR_233(s, p, o, m) BOOST_PP_FOR_233_C(BOOST_PP_BOOL(p##(234, s)), s, p, o, m)
#define BOOST_PP_FOR_234(s, p, o, m) BOOST_PP_FOR_234_C(BOOST_PP_BOOL(p##(235, s)), s, p, o, m)
#define BOOST_PP_FOR_235(s, p, o, m) BOOST_PP_FOR_235_C(BOOST_PP_BOOL(p##(236, s)), s, p, o, m)
#define BOOST_PP_FOR_236(s, p, o, m) BOOST_PP_FOR_236_C(BOOST_PP_BOOL(p##(237, s)), s, p, o, m)
#define BOOST_PP_FOR_237(s, p, o, m) BOOST_PP_FOR_237_C(BOOST_PP_BOOL(p##(238, s)), s, p, o, m)
#define BOOST_PP_FOR_238(s, p, o, m) BOOST_PP_FOR_238_C(BOOST_PP_BOOL(p##(239, s)), s, p, o, m)
#define BOOST_PP_FOR_239(s, p, o, m) BOOST_PP_FOR_239_C(BOOST_PP_BOOL(p##(240, s)), s, p, o, m)
#define BOOST_PP_FOR_240(s, p, o, m) BOOST_PP_FOR_240_C(BOOST_PP_BOOL(p##(241, s)), s, p, o, m)
#define BOOST_PP_FOR_241(s, p, o, m) BOOST_PP_FOR_241_C(BOOST_PP_BOOL(p##(242, s)), s, p, o, m)
#define BOOST_PP_FOR_242(s, p, o, m) BOOST_PP_FOR_242_C(BOOST_PP_BOOL(p##(243, s)), s, p, o, m)
#define BOOST_PP_FOR_243(s, p, o, m) BOOST_PP_FOR_243_C(BOOST_PP_BOOL(p##(244, s)), s, p, o, m)
#define BOOST_PP_FOR_244(s, p, o, m) BOOST_PP_FOR_244_C(BOOST_PP_BOOL(p##(245, s)), s, p, o, m)
#define BOOST_PP_FOR_245(s, p, o, m) BOOST_PP_FOR_245_C(BOOST_PP_BOOL(p##(246, s)), s, p, o, m)
#define BOOST_PP_FOR_246(s, p, o, m) BOOST_PP_FOR_246_C(BOOST_PP_BOOL(p##(247, s)), s, p, o, m)
#define BOOST_PP_FOR_247(s, p, o, m) BOOST_PP_FOR_247_C(BOOST_PP_BOOL(p##(248, s)), s, p, o, m)
#define BOOST_PP_FOR_248(s, p, o, m) BOOST_PP_FOR_248_C(BOOST_PP_BOOL(p##(249, s)), s, p, o, m)
#define BOOST_PP_FOR_249(s, p, o, m) BOOST_PP_FOR_249_C(BOOST_PP_BOOL(p##(250, s)), s, p, o, m)
#define BOOST_PP_FOR_250(s, p, o, m) BOOST_PP_FOR_250_C(BOOST_PP_BOOL(p##(251, s)), s, p, o, m)
#define BOOST_PP_FOR_251(s, p, o, m) BOOST_PP_FOR_251_C(BOOST_PP_BOOL(p##(252, s)), s, p, o, m)
#define BOOST_PP_FOR_252(s, p, o, m) BOOST_PP_FOR_252_C(BOOST_PP_BOOL(p##(253, s)), s, p, o, m)
#define BOOST_PP_FOR_253(s, p, o, m) BOOST_PP_FOR_253_C(BOOST_PP_BOOL(p##(254, s)), s, p, o, m)
#define BOOST_PP_FOR_254(s, p, o, m) BOOST_PP_FOR_254_C(BOOST_PP_BOOL(p##(255, s)), s, p, o, m)
#define BOOST_PP_FOR_255(s, p, o, m) BOOST_PP_FOR_255_C(BOOST_PP_BOOL(p##(256, s)), s, p, o, m)
#define BOOST_PP_FOR_256(s, p, o, m) BOOST_PP_FOR_256_C(BOOST_PP_BOOL(p##(257, s)), s, p, o, m)

#define BOOST_PP_FOR_1_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(2, s) BOOST_PP_IIF(c, BOOST_PP_FOR_2, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(2, s), p, o, m)
#define BOOST_PP_FOR_2_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(3, s) BOOST_PP_IIF(c, BOOST_PP_FOR_3, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(3, s), p, o, m)
#define BOOST_PP_FOR_3_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(4, s) BOOST_PP_IIF(c, BOOST_PP_FOR_4, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(4, s), p, o, m)
#define BOOST_PP_FOR_4_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(5, s) BOOST_PP_IIF(c, BOOST_PP_FOR_5, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(5, s), p, o, m)
#define BOOST_PP_FOR_5_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(6, s) BOOST_PP_IIF(c, BOOST_PP_FOR_6, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(6, s), p, o, m)
#define BOOST_PP_FOR_6_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(7, s) BOOST_PP_IIF(c, BOOST_PP_FOR_7, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(7, s), p, o, m)
#define BOOST_PP_FOR_7_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(8, s) BOOST_PP_IIF(c, BOOST_PP_FOR_8, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(8, s), p, o, m)
#define BOOST_PP_FOR_8_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(9, s) BOOST_PP_IIF(c, BOOST_PP_FOR_9, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(9, s), p, o, m)
#define BOOST_PP_FOR_9_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(10, s) BOOST_PP_IIF(c, BOOST_PP_FOR_10, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(10, s), p, o, m)
#define BOOST_PP_FOR_10_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(11, s) BOOST_PP_IIF(c, BOOST_PP_FOR_11, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(11, s), p, o, m)
#define BOOST_PP_FOR_11_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(12, s) BOOST_PP_IIF(c, BOOST_PP_FOR_12, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(12, s), p, o, m)
#define BOOST_PP_FOR_12_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(13, s) BOOST_PP_IIF(c, BOOST_PP_FOR_13, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(13, s), p, o, m)
#define BOOST_PP_FOR_13_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(14, s) BOOST_PP_IIF(c, BOOST_PP_FOR_14, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(14, s), p, o, m)
#define BOOST_PP_FOR_14_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(15, s) BOOST_PP_IIF(c, BOOST_PP_FOR_15, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(15, s), p, o, m)
#define BOOST_PP_FOR_15_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(16, s) BOOST_PP_IIF(c, BOOST_PP_FOR_16, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(16, s), p, o, m)
#define BOOST_PP_FOR_16_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(17, s) BOOST_PP_IIF(c, BOOST_PP_FOR_17, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(17, s), p, o, m)
#define BOOST_PP_FOR_17_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(18, s) BOOST_PP_IIF(c, BOOST_PP_FOR_18, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(18, s), p, o, m)
#define BOOST_PP_FOR_18_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(19, s) BOOST_PP_IIF(c, BOOST_PP_FOR_19, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(19, s), p, o, m)
#define BOOST_PP_FOR_19_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(20, s) BOOST_PP_IIF(c, BOOST_PP_FOR_20, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(20, s), p, o, m)
#define BOOST_PP_FOR_20_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(21, s) BOOST_PP_IIF(c, BOOST_PP_FOR_21, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(21, s), p, o, m)
#define BOOST_PP_FOR_21_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(22, s) BOOST_PP_IIF(c, BOOST_PP_FOR_22, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(22, s), p, o, m)
#define BOOST_PP_FOR_22_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(23, s) BOOST_PP_IIF(c, BOOST_PP_FOR_23, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(23, s), p, o, m)
#define BOOST_PP_FOR_23_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(24, s) BOOST_PP_IIF(c, BOOST_PP_FOR_24, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(24, s), p, o, m)
#define BOOST_PP_FOR_24_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(25, s) BOOST_PP_IIF(c, BOOST_PP_FOR_25, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(25, s), p, o, m)
#define BOOST_PP_FOR_25_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(26, s) BOOST_PP_IIF(c, BOOST_PP_FOR_26, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(26, s), p, o, m)
#define BOOST_PP_FOR_26_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(27, s) BOOST_PP_IIF(c, BOOST_PP_FOR_27, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(27, s), p, o, m)
#define BOOST_PP_FOR_27_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(28, s) BOOST_PP_IIF(c, BOOST_PP_FOR_28, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(28, s), p, o, m)
#define BOOST_PP_FOR_28_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(29, s) BOOST_PP_IIF(c, BOOST_PP_FOR_29, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(29, s), p, o, m)
#define BOOST_PP_FOR_29_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(30, s) BOOST_PP_IIF(c, BOOST_PP_FOR_30, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(30, s), p, o, m)
#define BOOST_PP_FOR_30_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(31, s) BOOST_PP_IIF(c, BOOST_PP_FOR_31, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(31, s), p, o, m)
#define BOOST_PP_FOR_31_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(32, s) BOOST_PP_IIF(c, BOOST_PP_FOR_32, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(32, s), p, o, m)
#define BOOST_PP_FOR_32_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(33, s) BOOST_PP_IIF(c, BOOST_PP_FOR_33, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(33, s), p, o, m)
#define BOOST_PP_FOR_33_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(34, s) BOOST_PP_IIF(c, BOOST_PP_FOR_34, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(34, s), p, o, m)
#define BOOST_PP_FOR_34_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(35, s) BOOST_PP_IIF(c, BOOST_PP_FOR_35, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(35, s), p, o, m)
#define BOOST_PP_FOR_35_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(36, s) BOOST_PP_IIF(c, BOOST_PP_FOR_36, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(36, s), p, o, m)
#define BOOST_PP_FOR_36_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(37, s) BOOST_PP_IIF(c, BOOST_PP_FOR_37, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(37, s), p, o, m)
#define BOOST_PP_FOR_37_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(38, s) BOOST_PP_IIF(c, BOOST_PP_FOR_38, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(38, s), p, o, m)
#define BOOST_PP_FOR_38_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(39, s) BOOST_PP_IIF(c, BOOST_PP_FOR_39, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(39, s), p, o, m)
#define BOOST_PP_FOR_39_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(40, s) BOOST_PP_IIF(c, BOOST_PP_FOR_40, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(40, s), p, o, m)
#define BOOST_PP_FOR_40_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(41, s) BOOST_PP_IIF(c, BOOST_PP_FOR_41, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(41, s), p, o, m)
#define BOOST_PP_FOR_41_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(42, s) BOOST_PP_IIF(c, BOOST_PP_FOR_42, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(42, s), p, o, m)
#define BOOST_PP_FOR_42_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(43, s) BOOST_PP_IIF(c, BOOST_PP_FOR_43, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(43, s), p, o, m)
#define BOOST_PP_FOR_43_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(44, s) BOOST_PP_IIF(c, BOOST_PP_FOR_44, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(44, s), p, o, m)
#define BOOST_PP_FOR_44_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(45, s) BOOST_PP_IIF(c, BOOST_PP_FOR_45, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(45, s), p, o, m)
#define BOOST_PP_FOR_45_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(46, s) BOOST_PP_IIF(c, BOOST_PP_FOR_46, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(46, s), p, o, m)
#define BOOST_PP_FOR_46_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(47, s) BOOST_PP_IIF(c, BOOST_PP_FOR_47, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(47, s), p, o, m)
#define BOOST_PP_FOR_47_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(48, s) BOOST_PP_IIF(c, BOOST_PP_FOR_48, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(48, s), p, o, m)
#define BOOST_PP_FOR_48_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(49, s) BOOST_PP_IIF(c, BOOST_PP_FOR_49, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(49, s), p, o, m)
#define BOOST_PP_FOR_49_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(50, s) BOOST_PP_IIF(c, BOOST_PP_FOR_50, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(50, s), p, o, m)
#define BOOST_PP_FOR_50_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(51, s) BOOST_PP_IIF(c, BOOST_PP_FOR_51, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(51, s), p, o, m)
#define BOOST_PP_FOR_51_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(52, s) BOOST_PP_IIF(c, BOOST_PP_FOR_52, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(52, s), p, o, m)
#define BOOST_PP_FOR_52_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(53, s) BOOST_PP_IIF(c, BOOST_PP_FOR_53, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(53, s), p, o, m)
#define BOOST_PP_FOR_53_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(54, s) BOOST_PP_IIF(c, BOOST_PP_FOR_54, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(54, s), p, o, m)
#define BOOST_PP_FOR_54_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(55, s) BOOST_PP_IIF(c, BOOST_PP_FOR_55, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(55, s), p, o, m)
#define BOOST_PP_FOR_55_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(56, s) BOOST_PP_IIF(c, BOOST_PP_FOR_56, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(56, s), p, o, m)
#define BOOST_PP_FOR_56_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(57, s) BOOST_PP_IIF(c, BOOST_PP_FOR_57, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(57, s), p, o, m)
#define BOOST_PP_FOR_57_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(58, s) BOOST_PP_IIF(c, BOOST_PP_FOR_58, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(58, s), p, o, m)
#define BOOST_PP_FOR_58_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(59, s) BOOST_PP_IIF(c, BOOST_PP_FOR_59, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(59, s), p, o, m)
#define BOOST_PP_FOR_59_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(60, s) BOOST_PP_IIF(c, BOOST_PP_FOR_60, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(60, s), p, o, m)
#define BOOST_PP_FOR_60_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(61, s) BOOST_PP_IIF(c, BOOST_PP_FOR_61, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(61, s), p, o, m)
#define BOOST_PP_FOR_61_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(62, s) BOOST_PP_IIF(c, BOOST_PP_FOR_62, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(62, s), p, o, m)
#define BOOST_PP_FOR_62_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(63, s) BOOST_PP_IIF(c, BOOST_PP_FOR_63, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(63, s), p, o, m)
#define BOOST_PP_FOR_63_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(64, s) BOOST_PP_IIF(c, BOOST_PP_FOR_64, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(64, s), p, o, m)
#define BOOST_PP_FOR_64_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(65, s) BOOST_PP_IIF(c, BOOST_PP_FOR_65, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(65, s), p, o, m)
#define BOOST_PP_FOR_65_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(66, s) BOOST_PP_IIF(c, BOOST_PP_FOR_66, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(66, s), p, o, m)
#define BOOST_PP_FOR_66_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(67, s) BOOST_PP_IIF(c, BOOST_PP_FOR_67, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(67, s), p, o, m)
#define BOOST_PP_FOR_67_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(68, s) BOOST_PP_IIF(c, BOOST_PP_FOR_68, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(68, s), p, o, m)
#define BOOST_PP_FOR_68_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(69, s) BOOST_PP_IIF(c, BOOST_PP_FOR_69, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(69, s), p, o, m)
#define BOOST_PP_FOR_69_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(70, s) BOOST_PP_IIF(c, BOOST_PP_FOR_70, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(70, s), p, o, m)
#define BOOST_PP_FOR_70_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(71, s) BOOST_PP_IIF(c, BOOST_PP_FOR_71, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(71, s), p, o, m)
#define BOOST_PP_FOR_71_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(72, s) BOOST_PP_IIF(c, BOOST_PP_FOR_72, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(72, s), p, o, m)
#define BOOST_PP_FOR_72_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(73, s) BOOST_PP_IIF(c, BOOST_PP_FOR_73, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(73, s), p, o, m)
#define BOOST_PP_FOR_73_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(74, s) BOOST_PP_IIF(c, BOOST_PP_FOR_74, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(74, s), p, o, m)
#define BOOST_PP_FOR_74_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(75, s) BOOST_PP_IIF(c, BOOST_PP_FOR_75, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(75, s), p, o, m)
#define BOOST_PP_FOR_75_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(76, s) BOOST_PP_IIF(c, BOOST_PP_FOR_76, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(76, s), p, o, m)
#define BOOST_PP_FOR_76_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(77, s) BOOST_PP_IIF(c, BOOST_PP_FOR_77, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(77, s), p, o, m)
#define BOOST_PP_FOR_77_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(78, s) BOOST_PP_IIF(c, BOOST_PP_FOR_78, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(78, s), p, o, m)
#define BOOST_PP_FOR_78_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(79, s) BOOST_PP_IIF(c, BOOST_PP_FOR_79, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(79, s), p, o, m)
#define BOOST_PP_FOR_79_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(80, s) BOOST_PP_IIF(c, BOOST_PP_FOR_80, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(80, s), p, o, m)
#define BOOST_PP_FOR_80_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(81, s) BOOST_PP_IIF(c, BOOST_PP_FOR_81, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(81, s), p, o, m)
#define BOOST_PP_FOR_81_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(82, s) BOOST_PP_IIF(c, BOOST_PP_FOR_82, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(82, s), p, o, m)
#define BOOST_PP_FOR_82_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(83, s) BOOST_PP_IIF(c, BOOST_PP_FOR_83, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(83, s), p, o, m)
#define BOOST_PP_FOR_83_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(84, s) BOOST_PP_IIF(c, BOOST_PP_FOR_84, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(84, s), p, o, m)
#define BOOST_PP_FOR_84_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(85, s) BOOST_PP_IIF(c, BOOST_PP_FOR_85, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(85, s), p, o, m)
#define BOOST_PP_FOR_85_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(86, s) BOOST_PP_IIF(c, BOOST_PP_FOR_86, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(86, s), p, o, m)
#define BOOST_PP_FOR_86_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(87, s) BOOST_PP_IIF(c, BOOST_PP_FOR_87, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(87, s), p, o, m)
#define BOOST_PP_FOR_87_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(88, s) BOOST_PP_IIF(c, BOOST_PP_FOR_88, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(88, s), p, o, m)
#define BOOST_PP_FOR_88_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(89, s) BOOST_PP_IIF(c, BOOST_PP_FOR_89, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(89, s), p, o, m)
#define BOOST_PP_FOR_89_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(90, s) BOOST_PP_IIF(c, BOOST_PP_FOR_90, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(90, s), p, o, m)
#define BOOST_PP_FOR_90_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(91, s) BOOST_PP_IIF(c, BOOST_PP_FOR_91, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(91, s), p, o, m)
#define BOOST_PP_FOR_91_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(92, s) BOOST_PP_IIF(c, BOOST_PP_FOR_92, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(92, s), p, o, m)
#define BOOST_PP_FOR_92_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(93, s) BOOST_PP_IIF(c, BOOST_PP_FOR_93, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(93, s), p, o, m)
#define BOOST_PP_FOR_93_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(94, s) BOOST_PP_IIF(c, BOOST_PP_FOR_94, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(94, s), p, o, m)
#define BOOST_PP_FOR_94_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(95, s) BOOST_PP_IIF(c, BOOST_PP_FOR_95, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(95, s), p, o, m)
#define BOOST_PP_FOR_95_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(96, s) BOOST_PP_IIF(c, BOOST_PP_FOR_96, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(96, s), p, o, m)
#define BOOST_PP_FOR_96_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(97, s) BOOST_PP_IIF(c, BOOST_PP_FOR_97, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(97, s), p, o, m)
#define BOOST_PP_FOR_97_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(98, s) BOOST_PP_IIF(c, BOOST_PP_FOR_98, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(98, s), p, o, m)
#define BOOST_PP_FOR_98_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(99, s) BOOST_PP_IIF(c, BOOST_PP_FOR_99, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(99, s), p, o, m)
#define BOOST_PP_FOR_99_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(100, s) BOOST_PP_IIF(c, BOOST_PP_FOR_100, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(100, s), p, o, m)
#define BOOST_PP_FOR_100_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(101, s) BOOST_PP_IIF(c, BOOST_PP_FOR_101, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(101, s), p, o, m)
#define BOOST_PP_FOR_101_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(102, s) BOOST_PP_IIF(c, BOOST_PP_FOR_102, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(102, s), p, o, m)
#define BOOST_PP_FOR_102_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(103, s) BOOST_PP_IIF(c, BOOST_PP_FOR_103, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(103, s), p, o, m)
#define BOOST_PP_FOR_103_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(104, s) BOOST_PP_IIF(c, BOOST_PP_FOR_104, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(104, s), p, o, m)
#define BOOST_PP_FOR_104_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(105, s) BOOST_PP_IIF(c, BOOST_PP_FOR_105, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(105, s), p, o, m)
#define BOOST_PP_FOR_105_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(106, s) BOOST_PP_IIF(c, BOOST_PP_FOR_106, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(106, s), p, o, m)
#define BOOST_PP_FOR_106_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(107, s) BOOST_PP_IIF(c, BOOST_PP_FOR_107, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(107, s), p, o, m)
#define BOOST_PP_FOR_107_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(108, s) BOOST_PP_IIF(c, BOOST_PP_FOR_108, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(108, s), p, o, m)
#define BOOST_PP_FOR_108_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(109, s) BOOST_PP_IIF(c, BOOST_PP_FOR_109, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(109, s), p, o, m)
#define BOOST_PP_FOR_109_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(110, s) BOOST_PP_IIF(c, BOOST_PP_FOR_110, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(110, s), p, o, m)
#define BOOST_PP_FOR_110_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(111, s) BOOST_PP_IIF(c, BOOST_PP_FOR_111, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(111, s), p, o, m)
#define BOOST_PP_FOR_111_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(112, s) BOOST_PP_IIF(c, BOOST_PP_FOR_112, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(112, s), p, o, m)
#define BOOST_PP_FOR_112_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(113, s) BOOST_PP_IIF(c, BOOST_PP_FOR_113, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(113, s), p, o, m)
#define BOOST_PP_FOR_113_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(114, s) BOOST_PP_IIF(c, BOOST_PP_FOR_114, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(114, s), p, o, m)
#define BOOST_PP_FOR_114_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(115, s) BOOST_PP_IIF(c, BOOST_PP_FOR_115, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(115, s), p, o, m)
#define BOOST_PP_FOR_115_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(116, s) BOOST_PP_IIF(c, BOOST_PP_FOR_116, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(116, s), p, o, m)
#define BOOST_PP_FOR_116_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(117, s) BOOST_PP_IIF(c, BOOST_PP_FOR_117, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(117, s), p, o, m)
#define BOOST_PP_FOR_117_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(118, s) BOOST_PP_IIF(c, BOOST_PP_FOR_118, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(118, s), p, o, m)
#define BOOST_PP_FOR_118_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(119, s) BOOST_PP_IIF(c, BOOST_PP_FOR_119, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(119, s), p, o, m)
#define BOOST_PP_FOR_119_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(120, s) BOOST_PP_IIF(c, BOOST_PP_FOR_120, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(120, s), p, o, m)
#define BOOST_PP_FOR_120_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(121, s) BOOST_PP_IIF(c, BOOST_PP_FOR_121, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(121, s), p, o, m)
#define BOOST_PP_FOR_121_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(122, s) BOOST_PP_IIF(c, BOOST_PP_FOR_122, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(122, s), p, o, m)
#define BOOST_PP_FOR_122_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(123, s) BOOST_PP_IIF(c, BOOST_PP_FOR_123, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(123, s), p, o, m)
#define BOOST_PP_FOR_123_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(124, s) BOOST_PP_IIF(c, BOOST_PP_FOR_124, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(124, s), p, o, m)
#define BOOST_PP_FOR_124_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(125, s) BOOST_PP_IIF(c, BOOST_PP_FOR_125, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(125, s), p, o, m)
#define BOOST_PP_FOR_125_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(126, s) BOOST_PP_IIF(c, BOOST_PP_FOR_126, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(126, s), p, o, m)
#define BOOST_PP_FOR_126_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(127, s) BOOST_PP_IIF(c, BOOST_PP_FOR_127, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(127, s), p, o, m)
#define BOOST_PP_FOR_127_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(128, s) BOOST_PP_IIF(c, BOOST_PP_FOR_128, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(128, s), p, o, m)
#define BOOST_PP_FOR_128_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(129, s) BOOST_PP_IIF(c, BOOST_PP_FOR_129, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(129, s), p, o, m)
#define BOOST_PP_FOR_129_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(130, s) BOOST_PP_IIF(c, BOOST_PP_FOR_130, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(130, s), p, o, m)
#define BOOST_PP_FOR_130_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(131, s) BOOST_PP_IIF(c, BOOST_PP_FOR_131, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(131, s), p, o, m)
#define BOOST_PP_FOR_131_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(132, s) BOOST_PP_IIF(c, BOOST_PP_FOR_132, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(132, s), p, o, m)
#define BOOST_PP_FOR_132_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(133, s) BOOST_PP_IIF(c, BOOST_PP_FOR_133, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(133, s), p, o, m)
#define BOOST_PP_FOR_133_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(134, s) BOOST_PP_IIF(c, BOOST_PP_FOR_134, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(134, s), p, o, m)
#define BOOST_PP_FOR_134_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(135, s) BOOST_PP_IIF(c, BOOST_PP_FOR_135, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(135, s), p, o, m)
#define BOOST_PP_FOR_135_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(136, s) BOOST_PP_IIF(c, BOOST_PP_FOR_136, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(136, s), p, o, m)
#define BOOST_PP_FOR_136_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(137, s) BOOST_PP_IIF(c, BOOST_PP_FOR_137, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(137, s), p, o, m)
#define BOOST_PP_FOR_137_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(138, s) BOOST_PP_IIF(c, BOOST_PP_FOR_138, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(138, s), p, o, m)
#define BOOST_PP_FOR_138_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(139, s) BOOST_PP_IIF(c, BOOST_PP_FOR_139, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(139, s), p, o, m)
#define BOOST_PP_FOR_139_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(140, s) BOOST_PP_IIF(c, BOOST_PP_FOR_140, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(140, s), p, o, m)
#define BOOST_PP_FOR_140_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(141, s) BOOST_PP_IIF(c, BOOST_PP_FOR_141, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(141, s), p, o, m)
#define BOOST_PP_FOR_141_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(142, s) BOOST_PP_IIF(c, BOOST_PP_FOR_142, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(142, s), p, o, m)
#define BOOST_PP_FOR_142_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(143, s) BOOST_PP_IIF(c, BOOST_PP_FOR_143, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(143, s), p, o, m)
#define BOOST_PP_FOR_143_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(144, s) BOOST_PP_IIF(c, BOOST_PP_FOR_144, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(144, s), p, o, m)
#define BOOST_PP_FOR_144_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(145, s) BOOST_PP_IIF(c, BOOST_PP_FOR_145, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(145, s), p, o, m)
#define BOOST_PP_FOR_145_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(146, s) BOOST_PP_IIF(c, BOOST_PP_FOR_146, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(146, s), p, o, m)
#define BOOST_PP_FOR_146_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(147, s) BOOST_PP_IIF(c, BOOST_PP_FOR_147, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(147, s), p, o, m)
#define BOOST_PP_FOR_147_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(148, s) BOOST_PP_IIF(c, BOOST_PP_FOR_148, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(148, s), p, o, m)
#define BOOST_PP_FOR_148_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(149, s) BOOST_PP_IIF(c, BOOST_PP_FOR_149, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(149, s), p, o, m)
#define BOOST_PP_FOR_149_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(150, s) BOOST_PP_IIF(c, BOOST_PP_FOR_150, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(150, s), p, o, m)
#define BOOST_PP_FOR_150_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(151, s) BOOST_PP_IIF(c, BOOST_PP_FOR_151, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(151, s), p, o, m)
#define BOOST_PP_FOR_151_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(152, s) BOOST_PP_IIF(c, BOOST_PP_FOR_152, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(152, s), p, o, m)
#define BOOST_PP_FOR_152_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(153, s) BOOST_PP_IIF(c, BOOST_PP_FOR_153, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(153, s), p, o, m)
#define BOOST_PP_FOR_153_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(154, s) BOOST_PP_IIF(c, BOOST_PP_FOR_154, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(154, s), p, o, m)
#define BOOST_PP_FOR_154_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(155, s) BOOST_PP_IIF(c, BOOST_PP_FOR_155, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(155, s), p, o, m)
#define BOOST_PP_FOR_155_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(156, s) BOOST_PP_IIF(c, BOOST_PP_FOR_156, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(156, s), p, o, m)
#define BOOST_PP_FOR_156_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(157, s) BOOST_PP_IIF(c, BOOST_PP_FOR_157, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(157, s), p, o, m)
#define BOOST_PP_FOR_157_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(158, s) BOOST_PP_IIF(c, BOOST_PP_FOR_158, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(158, s), p, o, m)
#define BOOST_PP_FOR_158_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(159, s) BOOST_PP_IIF(c, BOOST_PP_FOR_159, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(159, s), p, o, m)
#define BOOST_PP_FOR_159_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(160, s) BOOST_PP_IIF(c, BOOST_PP_FOR_160, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(160, s), p, o, m)
#define BOOST_PP_FOR_160_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(161, s) BOOST_PP_IIF(c, BOOST_PP_FOR_161, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(161, s), p, o, m)
#define BOOST_PP_FOR_161_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(162, s) BOOST_PP_IIF(c, BOOST_PP_FOR_162, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(162, s), p, o, m)
#define BOOST_PP_FOR_162_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(163, s) BOOST_PP_IIF(c, BOOST_PP_FOR_163, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(163, s), p, o, m)
#define BOOST_PP_FOR_163_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(164, s) BOOST_PP_IIF(c, BOOST_PP_FOR_164, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(164, s), p, o, m)
#define BOOST_PP_FOR_164_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(165, s) BOOST_PP_IIF(c, BOOST_PP_FOR_165, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(165, s), p, o, m)
#define BOOST_PP_FOR_165_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(166, s) BOOST_PP_IIF(c, BOOST_PP_FOR_166, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(166, s), p, o, m)
#define BOOST_PP_FOR_166_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(167, s) BOOST_PP_IIF(c, BOOST_PP_FOR_167, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(167, s), p, o, m)
#define BOOST_PP_FOR_167_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(168, s) BOOST_PP_IIF(c, BOOST_PP_FOR_168, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(168, s), p, o, m)
#define BOOST_PP_FOR_168_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(169, s) BOOST_PP_IIF(c, BOOST_PP_FOR_169, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(169, s), p, o, m)
#define BOOST_PP_FOR_169_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(170, s) BOOST_PP_IIF(c, BOOST_PP_FOR_170, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(170, s), p, o, m)
#define BOOST_PP_FOR_170_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(171, s) BOOST_PP_IIF(c, BOOST_PP_FOR_171, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(171, s), p, o, m)
#define BOOST_PP_FOR_171_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(172, s) BOOST_PP_IIF(c, BOOST_PP_FOR_172, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(172, s), p, o, m)
#define BOOST_PP_FOR_172_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(173, s) BOOST_PP_IIF(c, BOOST_PP_FOR_173, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(173, s), p, o, m)
#define BOOST_PP_FOR_173_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(174, s) BOOST_PP_IIF(c, BOOST_PP_FOR_174, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(174, s), p, o, m)
#define BOOST_PP_FOR_174_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(175, s) BOOST_PP_IIF(c, BOOST_PP_FOR_175, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(175, s), p, o, m)
#define BOOST_PP_FOR_175_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(176, s) BOOST_PP_IIF(c, BOOST_PP_FOR_176, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(176, s), p, o, m)
#define BOOST_PP_FOR_176_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(177, s) BOOST_PP_IIF(c, BOOST_PP_FOR_177, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(177, s), p, o, m)
#define BOOST_PP_FOR_177_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(178, s) BOOST_PP_IIF(c, BOOST_PP_FOR_178, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(178, s), p, o, m)
#define BOOST_PP_FOR_178_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(179, s) BOOST_PP_IIF(c, BOOST_PP_FOR_179, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(179, s), p, o, m)
#define BOOST_PP_FOR_179_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(180, s) BOOST_PP_IIF(c, BOOST_PP_FOR_180, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(180, s), p, o, m)
#define BOOST_PP_FOR_180_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(181, s) BOOST_PP_IIF(c, BOOST_PP_FOR_181, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(181, s), p, o, m)
#define BOOST_PP_FOR_181_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(182, s) BOOST_PP_IIF(c, BOOST_PP_FOR_182, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(182, s), p, o, m)
#define BOOST_PP_FOR_182_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(183, s) BOOST_PP_IIF(c, BOOST_PP_FOR_183, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(183, s), p, o, m)
#define BOOST_PP_FOR_183_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(184, s) BOOST_PP_IIF(c, BOOST_PP_FOR_184, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(184, s), p, o, m)
#define BOOST_PP_FOR_184_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(185, s) BOOST_PP_IIF(c, BOOST_PP_FOR_185, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(185, s), p, o, m)
#define BOOST_PP_FOR_185_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(186, s) BOOST_PP_IIF(c, BOOST_PP_FOR_186, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(186, s), p, o, m)
#define BOOST_PP_FOR_186_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(187, s) BOOST_PP_IIF(c, BOOST_PP_FOR_187, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(187, s), p, o, m)
#define BOOST_PP_FOR_187_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(188, s) BOOST_PP_IIF(c, BOOST_PP_FOR_188, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(188, s), p, o, m)
#define BOOST_PP_FOR_188_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(189, s) BOOST_PP_IIF(c, BOOST_PP_FOR_189, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(189, s), p, o, m)
#define BOOST_PP_FOR_189_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(190, s) BOOST_PP_IIF(c, BOOST_PP_FOR_190, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(190, s), p, o, m)
#define BOOST_PP_FOR_190_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(191, s) BOOST_PP_IIF(c, BOOST_PP_FOR_191, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(191, s), p, o, m)
#define BOOST_PP_FOR_191_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(192, s) BOOST_PP_IIF(c, BOOST_PP_FOR_192, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(192, s), p, o, m)
#define BOOST_PP_FOR_192_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(193, s) BOOST_PP_IIF(c, BOOST_PP_FOR_193, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(193, s), p, o, m)
#define BOOST_PP_FOR_193_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(194, s) BOOST_PP_IIF(c, BOOST_PP_FOR_194, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(194, s), p, o, m)
#define BOOST_PP_FOR_194_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(195, s) BOOST_PP_IIF(c, BOOST_PP_FOR_195, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(195, s), p, o, m)
#define BOOST_PP_FOR_195_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(196, s) BOOST_PP_IIF(c, BOOST_PP_FOR_196, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(196, s), p, o, m)
#define BOOST_PP_FOR_196_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(197, s) BOOST_PP_IIF(c, BOOST_PP_FOR_197, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(197, s), p, o, m)
#define BOOST_PP_FOR_197_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(198, s) BOOST_PP_IIF(c, BOOST_PP_FOR_198, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(198, s), p, o, m)
#define BOOST_PP_FOR_198_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(199, s) BOOST_PP_IIF(c, BOOST_PP_FOR_199, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(199, s), p, o, m)
#define BOOST_PP_FOR_199_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(200, s) BOOST_PP_IIF(c, BOOST_PP_FOR_200, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(200, s), p, o, m)
#define BOOST_PP_FOR_200_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(201, s) BOOST_PP_IIF(c, BOOST_PP_FOR_201, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(201, s), p, o, m)
#define BOOST_PP_FOR_201_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(202, s) BOOST_PP_IIF(c, BOOST_PP_FOR_202, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(202, s), p, o, m)
#define BOOST_PP_FOR_202_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(203, s) BOOST_PP_IIF(c, BOOST_PP_FOR_203, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(203, s), p, o, m)
#define BOOST_PP_FOR_203_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(204, s) BOOST_PP_IIF(c, BOOST_PP_FOR_204, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(204, s), p, o, m)
#define BOOST_PP_FOR_204_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(205, s) BOOST_PP_IIF(c, BOOST_PP_FOR_205, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(205, s), p, o, m)
#define BOOST_PP_FOR_205_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(206, s) BOOST_PP_IIF(c, BOOST_PP_FOR_206, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(206, s), p, o, m)
#define BOOST_PP_FOR_206_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(207, s) BOOST_PP_IIF(c, BOOST_PP_FOR_207, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(207, s), p, o, m)
#define BOOST_PP_FOR_207_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(208, s) BOOST_PP_IIF(c, BOOST_PP_FOR_208, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(208, s), p, o, m)
#define BOOST_PP_FOR_208_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(209, s) BOOST_PP_IIF(c, BOOST_PP_FOR_209, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(209, s), p, o, m)
#define BOOST_PP_FOR_209_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(210, s) BOOST_PP_IIF(c, BOOST_PP_FOR_210, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(210, s), p, o, m)
#define BOOST_PP_FOR_210_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(211, s) BOOST_PP_IIF(c, BOOST_PP_FOR_211, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(211, s), p, o, m)
#define BOOST_PP_FOR_211_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(212, s) BOOST_PP_IIF(c, BOOST_PP_FOR_212, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(212, s), p, o, m)
#define BOOST_PP_FOR_212_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(213, s) BOOST_PP_IIF(c, BOOST_PP_FOR_213, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(213, s), p, o, m)
#define BOOST_PP_FOR_213_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(214, s) BOOST_PP_IIF(c, BOOST_PP_FOR_214, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(214, s), p, o, m)
#define BOOST_PP_FOR_214_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(215, s) BOOST_PP_IIF(c, BOOST_PP_FOR_215, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(215, s), p, o, m)
#define BOOST_PP_FOR_215_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(216, s) BOOST_PP_IIF(c, BOOST_PP_FOR_216, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(216, s), p, o, m)
#define BOOST_PP_FOR_216_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(217, s) BOOST_PP_IIF(c, BOOST_PP_FOR_217, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(217, s), p, o, m)
#define BOOST_PP_FOR_217_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(218, s) BOOST_PP_IIF(c, BOOST_PP_FOR_218, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(218, s), p, o, m)
#define BOOST_PP_FOR_218_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(219, s) BOOST_PP_IIF(c, BOOST_PP_FOR_219, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(219, s), p, o, m)
#define BOOST_PP_FOR_219_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(220, s) BOOST_PP_IIF(c, BOOST_PP_FOR_220, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(220, s), p, o, m)
#define BOOST_PP_FOR_220_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(221, s) BOOST_PP_IIF(c, BOOST_PP_FOR_221, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(221, s), p, o, m)
#define BOOST_PP_FOR_221_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(222, s) BOOST_PP_IIF(c, BOOST_PP_FOR_222, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(222, s), p, o, m)
#define BOOST_PP_FOR_222_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(223, s) BOOST_PP_IIF(c, BOOST_PP_FOR_223, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(223, s), p, o, m)
#define BOOST_PP_FOR_223_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(224, s) BOOST_PP_IIF(c, BOOST_PP_FOR_224, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(224, s), p, o, m)
#define BOOST_PP_FOR_224_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(225, s) BOOST_PP_IIF(c, BOOST_PP_FOR_225, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(225, s), p, o, m)
#define BOOST_PP_FOR_225_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(226, s) BOOST_PP_IIF(c, BOOST_PP_FOR_226, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(226, s), p, o, m)
#define BOOST_PP_FOR_226_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(227, s) BOOST_PP_IIF(c, BOOST_PP_FOR_227, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(227, s), p, o, m)
#define BOOST_PP_FOR_227_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(228, s) BOOST_PP_IIF(c, BOOST_PP_FOR_228, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(228, s), p, o, m)
#define BOOST_PP_FOR_228_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(229, s) BOOST_PP_IIF(c, BOOST_PP_FOR_229, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(229, s), p, o, m)
#define BOOST_PP_FOR_229_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(230, s) BOOST_PP_IIF(c, BOOST_PP_FOR_230, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(230, s), p, o, m)
#define BOOST_PP_FOR_230_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(231, s) BOOST_PP_IIF(c, BOOST_PP_FOR_231, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(231, s), p, o, m)
#define BOOST_PP_FOR_231_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(232, s) BOOST_PP_IIF(c, BOOST_PP_FOR_232, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(232, s), p, o, m)
#define BOOST_PP_FOR_232_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(233, s) BOOST_PP_IIF(c, BOOST_PP_FOR_233, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(233, s), p, o, m)
#define BOOST_PP_FOR_233_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(234, s) BOOST_PP_IIF(c, BOOST_PP_FOR_234, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(234, s), p, o, m)
#define BOOST_PP_FOR_234_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(235, s) BOOST_PP_IIF(c, BOOST_PP_FOR_235, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(235, s), p, o, m)
#define BOOST_PP_FOR_235_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(236, s) BOOST_PP_IIF(c, BOOST_PP_FOR_236, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(236, s), p, o, m)
#define BOOST_PP_FOR_236_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(237, s) BOOST_PP_IIF(c, BOOST_PP_FOR_237, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(237, s), p, o, m)
#define BOOST_PP_FOR_237_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(238, s) BOOST_PP_IIF(c, BOOST_PP_FOR_238, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(238, s), p, o, m)
#define BOOST_PP_FOR_238_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(239, s) BOOST_PP_IIF(c, BOOST_PP_FOR_239, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(239, s), p, o, m)
#define BOOST_PP_FOR_239_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(240, s) BOOST_PP_IIF(c, BOOST_PP_FOR_240, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(240, s), p, o, m)
#define BOOST_PP_FOR_240_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(241, s) BOOST_PP_IIF(c, BOOST_PP_FOR_241, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(241, s), p, o, m)
#define BOOST_PP_FOR_241_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(242, s) BOOST_PP_IIF(c, BOOST_PP_FOR_242, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(242, s), p, o, m)
#define BOOST_PP_FOR_242_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(243, s) BOOST_PP_IIF(c, BOOST_PP_FOR_243, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(243, s), p, o, m)
#define BOOST_PP_FOR_243_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(244, s) BOOST_PP_IIF(c, BOOST_PP_FOR_244, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(244, s), p, o, m)
#define BOOST_PP_FOR_244_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(245, s) BOOST_PP_IIF(c, BOOST_PP_FOR_245, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(245, s), p, o, m)
#define BOOST_PP_FOR_245_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(246, s) BOOST_PP_IIF(c, BOOST_PP_FOR_246, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(246, s), p, o, m)
#define BOOST_PP_FOR_246_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(247, s) BOOST_PP_IIF(c, BOOST_PP_FOR_247, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(247, s), p, o, m)
#define BOOST_PP_FOR_247_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(248, s) BOOST_PP_IIF(c, BOOST_PP_FOR_248, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(248, s), p, o, m)
#define BOOST_PP_FOR_248_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(249, s) BOOST_PP_IIF(c, BOOST_PP_FOR_249, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(249, s), p, o, m)
#define BOOST_PP_FOR_249_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(250, s) BOOST_PP_IIF(c, BOOST_PP_FOR_250, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(250, s), p, o, m)
#define BOOST_PP_FOR_250_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(251, s) BOOST_PP_IIF(c, BOOST_PP_FOR_251, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(251, s), p, o, m)
#define BOOST_PP_FOR_251_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(252, s) BOOST_PP_IIF(c, BOOST_PP_FOR_252, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(252, s), p, o, m)
#define BOOST_PP_FOR_252_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(253, s) BOOST_PP_IIF(c, BOOST_PP_FOR_253, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(253, s), p, o, m)
#define BOOST_PP_FOR_253_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(254, s) BOOST_PP_IIF(c, BOOST_PP_FOR_254, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(254, s), p, o, m)
#define BOOST_PP_FOR_254_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(255, s) BOOST_PP_IIF(c, BOOST_PP_FOR_255, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(255, s), p, o, m)
#define BOOST_PP_FOR_255_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(256, s) BOOST_PP_IIF(c, BOOST_PP_FOR_256, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(256, s), p, o, m)
#define BOOST_PP_FOR_256_C(c, s, p, o, m) BOOST_PP_IIF(c, m, BOOST_PP_TUPLE_EAT_2)(257, s) BOOST_PP_IIF(c, BOOST_PP_FOR_257, BOOST_PP_TUPLE_EAT_4)(BOOST_PP_EXPR_IIF(c, o)(257, s), p, o, m)

#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_1(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_2(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_3(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_4(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_5(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_6(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_7(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_8(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_9(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_10(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_11(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_12(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_13(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_14(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_15(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_16(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_17(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_18(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_19(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_20(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_21(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_22(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_23(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_24(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_25(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_26(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_27(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_28(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_29(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_30(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_31(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_32(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_33(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_34(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_35(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_36(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_37(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_38(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_39(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_40(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_41(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_42(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_43(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_44(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_45(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_46(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_47(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_48(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_49(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_50(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_51(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_52(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_53(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_54(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_55(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_56(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_57(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_58(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_59(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_60(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_61(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_62(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_63(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_64(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_65(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_66(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_67(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_68(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_69(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_70(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_71(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_72(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_73(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_74(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_75(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_76(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_77(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_78(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_79(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_80(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_81(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_82(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_83(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_84(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_85(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_86(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_87(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_88(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_89(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_90(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_91(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_92(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_93(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_94(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_95(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_96(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_97(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_98(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_99(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_100(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_101(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_102(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_103(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_104(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_105(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_106(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_107(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_108(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_109(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_110(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_111(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_112(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_113(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_114(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_115(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_116(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_117(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_118(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_119(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_120(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_121(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_122(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_123(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_124(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_125(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_126(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_127(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_128(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_129(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_130(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_131(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_132(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_133(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_134(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_135(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_136(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_137(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_138(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_139(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_140(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_141(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_142(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_143(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_144(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_145(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_146(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_147(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_148(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_149(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_150(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_151(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_152(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_153(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_154(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_155(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_156(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_157(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_158(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_159(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_160(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_161(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_162(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_163(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_164(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_165(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_166(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_167(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_168(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_169(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_170(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_171(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_172(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_173(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_174(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_175(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_176(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_177(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_178(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_179(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_180(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_181(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_182(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_183(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_184(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_185(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_186(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_187(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_188(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_189(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_190(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_191(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_192(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_193(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_194(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_195(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_196(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_197(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_198(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_199(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_200(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_201(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_202(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_203(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_204(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_205(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_206(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_207(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_208(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_209(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_210(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_211(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_212(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_213(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_214(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_215(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_216(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_217(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_218(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_219(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_220(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_221(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_222(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_223(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_224(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_225(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_226(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_227(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_228(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_229(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_230(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_231(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_232(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_233(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_234(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_235(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_236(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_237(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_238(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_239(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_240(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_241(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_242(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_243(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_244(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_245(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_246(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_247(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_248(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_249(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_250(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_251(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_252(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_253(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_254(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_255(s, p, o, m) 0
#define BOOST_PP_FOR_CHECK_BOOST_PP_FOR_256(s, p, o, m) 0

#define BOOST_PP_FOR_P(n) BOOST_PP_CAT(BOOST_PP_FOR_CHECK_, BOOST_PP_FOR_ ## n(1, BOOST_PP_FOR_SR_P, BOOST_PP_FOR_SR_O, BOOST_PP_FOR_SR_M))
#define BOOST_PP_FOR_SR_P(r, s) s
#define BOOST_PP_FOR_SR_O(r, s) 0
#define BOOST_PP_FOR_SR_M(r, s) BOOST_PP_NIL

#define BOOST_PP_FRAME_FINISH(i) BOOST_PP_CAT(BOOST_PP_ITERATION_FINISH_, i)
#define BOOST_PP_FRAME_FLAGS(i) (BOOST_PP_CAT(BOOST_PP_ITERATION_FLAGS_, i))
#define BOOST_PP_FRAME_ITERATION(i) BOOST_PP_CAT(BOOST_PP_ITERATION_, i)
#define BOOST_PP_FRAME_START(i) BOOST_PP_CAT(BOOST_PP_ITERATION_START_, i)

#define BOOST_PP_GREATER(x, y) BOOST_PP_LESS(y,x)
#define BOOST_PP_GREATER_D(d, x, y) BOOST_PP_LESS_D(d, y, x)

#define BOOST_PP_GREATER_EQUAL(x, y) BOOST_PP_LESS_EQUAL(y,x)
#define BOOST_PP_GREATER_EQUAL_D(d, x, y) BOOST_PP_LESS_EQUAL_D(d,y,x)

#define BOOST_PP_IDENTITY(item) item BOOST_PP_EMPTY()

#define BOOST_PP_IF(cond, t, f) BOOST_PP_IIF(BOOST_PP_BOOL(cond), t, f)
#define BOOST_PP_IIF(bit, t, f) BOOST_PP_IIF_I(bit, t, f)
#define BOOST_PP_IIF_I(bit, t, f) BOOST_PP_IIF_ ## bit(t, f)
#define BOOST_PP_IIF_0(t, f) f
#define BOOST_PP_IIF_1(t, f) t

#define BOOST_PP_INC(x) BOOST_PP_INC_I(x)
#define BOOST_PP_INC_I(x) BOOST_PP_INC_##x
#define BOOST_PP_INC_0 1
#define BOOST_PP_INC_1 2
#define BOOST_PP_INC_2 3
#define BOOST_PP_INC_3 4
#define BOOST_PP_INC_4 5
#define BOOST_PP_INC_5 6
#define BOOST_PP_INC_6 7
#define BOOST_PP_INC_7 8
#define BOOST_PP_INC_8 9
#define BOOST_PP_INC_9 10
#define BOOST_PP_INC_10 11
#define BOOST_PP_INC_11 12
#define BOOST_PP_INC_12 13
#define BOOST_PP_INC_13 14
#define BOOST_PP_INC_14 15
#define BOOST_PP_INC_15 16
#define BOOST_PP_INC_16 17
#define BOOST_PP_INC_17 18
#define BOOST_PP_INC_18 19
#define BOOST_PP_INC_19 20
#define BOOST_PP_INC_20 21
#define BOOST_PP_INC_21 22
#define BOOST_PP_INC_22 23
#define BOOST_PP_INC_23 24
#define BOOST_PP_INC_24 25
#define BOOST_PP_INC_25 26
#define BOOST_PP_INC_26 27
#define BOOST_PP_INC_27 28
#define BOOST_PP_INC_28 29
#define BOOST_PP_INC_29 30
#define BOOST_PP_INC_30 31
#define BOOST_PP_INC_31 32
#define BOOST_PP_INC_32 33
#define BOOST_PP_INC_33 34
#define BOOST_PP_INC_34 35
#define BOOST_PP_INC_35 36
#define BOOST_PP_INC_36 37
#define BOOST_PP_INC_37 38
#define BOOST_PP_INC_38 39
#define BOOST_PP_INC_39 40
#define BOOST_PP_INC_40 41
#define BOOST_PP_INC_41 42
#define BOOST_PP_INC_42 43
#define BOOST_PP_INC_43 44
#define BOOST_PP_INC_44 45
#define BOOST_PP_INC_45 46
#define BOOST_PP_INC_46 47
#define BOOST_PP_INC_47 48
#define BOOST_PP_INC_48 49
#define BOOST_PP_INC_49 50
#define BOOST_PP_INC_50 51
#define BOOST_PP_INC_51 52
#define BOOST_PP_INC_52 53
#define BOOST_PP_INC_53 54
#define BOOST_PP_INC_54 55
#define BOOST_PP_INC_55 56
#define BOOST_PP_INC_56 57
#define BOOST_PP_INC_57 58
#define BOOST_PP_INC_58 59
#define BOOST_PP_INC_59 60
#define BOOST_PP_INC_60 61
#define BOOST_PP_INC_61 62
#define BOOST_PP_INC_62 63
#define BOOST_PP_INC_63 64
#define BOOST_PP_INC_64 65
#define BOOST_PP_INC_65 66
#define BOOST_PP_INC_66 67
#define BOOST_PP_INC_67 68
#define BOOST_PP_INC_68 69
#define BOOST_PP_INC_69 70
#define BOOST_PP_INC_70 71
#define BOOST_PP_INC_71 72
#define BOOST_PP_INC_72 73
#define BOOST_PP_INC_73 74
#define BOOST_PP_INC_74 75
#define BOOST_PP_INC_75 76
#define BOOST_PP_INC_76 77
#define BOOST_PP_INC_77 78
#define BOOST_PP_INC_78 79
#define BOOST_PP_INC_79 80
#define BOOST_PP_INC_80 81
#define BOOST_PP_INC_81 82
#define BOOST_PP_INC_82 83
#define BOOST_PP_INC_83 84
#define BOOST_PP_INC_84 85
#define BOOST_PP_INC_85 86
#define BOOST_PP_INC_86 87
#define BOOST_PP_INC_87 88
#define BOOST_PP_INC_88 89
#define BOOST_PP_INC_89 90
#define BOOST_PP_INC_90 91
#define BOOST_PP_INC_91 92
#define BOOST_PP_INC_92 93
#define BOOST_PP_INC_93 94
#define BOOST_PP_INC_94 95
#define BOOST_PP_INC_95 96
#define BOOST_PP_INC_96 97
#define BOOST_PP_INC_97 98
#define BOOST_PP_INC_98 99
#define BOOST_PP_INC_99 100
#define BOOST_PP_INC_100 101
#define BOOST_PP_INC_101 102
#define BOOST_PP_INC_102 103
#define BOOST_PP_INC_103 104
#define BOOST_PP_INC_104 105
#define BOOST_PP_INC_105 106
#define BOOST_PP_INC_106 107
#define BOOST_PP_INC_107 108
#define BOOST_PP_INC_108 109
#define BOOST_PP_INC_109 110
#define BOOST_PP_INC_110 111
#define BOOST_PP_INC_111 112
#define BOOST_PP_INC_112 113
#define BOOST_PP_INC_113 114
#define BOOST_PP_INC_114 115
#define BOOST_PP_INC_115 116
#define BOOST_PP_INC_116 117
#define BOOST_PP_INC_117 118
#define BOOST_PP_INC_118 119
#define BOOST_PP_INC_119 120
#define BOOST_PP_INC_120 121
#define BOOST_PP_INC_121 122
#define BOOST_PP_INC_122 123
#define BOOST_PP_INC_123 124
#define BOOST_PP_INC_124 125
#define BOOST_PP_INC_125 126
#define BOOST_PP_INC_126 127
#define BOOST_PP_INC_127 128
#define BOOST_PP_INC_128 129
#define BOOST_PP_INC_129 130
#define BOOST_PP_INC_130 131
#define BOOST_PP_INC_131 132
#define BOOST_PP_INC_132 133
#define BOOST_PP_INC_133 134
#define BOOST_PP_INC_134 135
#define BOOST_PP_INC_135 136
#define BOOST_PP_INC_136 137
#define BOOST_PP_INC_137 138
#define BOOST_PP_INC_138 139
#define BOOST_PP_INC_139 140
#define BOOST_PP_INC_140 141
#define BOOST_PP_INC_141 142
#define BOOST_PP_INC_142 143
#define BOOST_PP_INC_143 144
#define BOOST_PP_INC_144 145
#define BOOST_PP_INC_145 146
#define BOOST_PP_INC_146 147
#define BOOST_PP_INC_147 148
#define BOOST_PP_INC_148 149
#define BOOST_PP_INC_149 150
#define BOOST_PP_INC_150 151
#define BOOST_PP_INC_151 152
#define BOOST_PP_INC_152 153
#define BOOST_PP_INC_153 154
#define BOOST_PP_INC_154 155
#define BOOST_PP_INC_155 156
#define BOOST_PP_INC_156 157
#define BOOST_PP_INC_157 158
#define BOOST_PP_INC_158 159
#define BOOST_PP_INC_159 160
#define BOOST_PP_INC_160 161
#define BOOST_PP_INC_161 162
#define BOOST_PP_INC_162 163
#define BOOST_PP_INC_163 164
#define BOOST_PP_INC_164 165
#define BOOST_PP_INC_165 166
#define BOOST_PP_INC_166 167
#define BOOST_PP_INC_167 168
#define BOOST_PP_INC_168 169
#define BOOST_PP_INC_169 170
#define BOOST_PP_INC_170 171
#define BOOST_PP_INC_171 172
#define BOOST_PP_INC_172 173
#define BOOST_PP_INC_173 174
#define BOOST_PP_INC_174 175
#define BOOST_PP_INC_175 176
#define BOOST_PP_INC_176 177
#define BOOST_PP_INC_177 178
#define BOOST_PP_INC_178 179
#define BOOST_PP_INC_179 180
#define BOOST_PP_INC_180 181
#define BOOST_PP_INC_181 182
#define BOOST_PP_INC_182 183
#define BOOST_PP_INC_183 184
#define BOOST_PP_INC_184 185
#define BOOST_PP_INC_185 186
#define BOOST_PP_INC_186 187
#define BOOST_PP_INC_187 188
#define BOOST_PP_INC_188 189
#define BOOST_PP_INC_189 190
#define BOOST_PP_INC_190 191
#define BOOST_PP_INC_191 192
#define BOOST_PP_INC_192 193
#define BOOST_PP_INC_193 194
#define BOOST_PP_INC_194 195
#define BOOST_PP_INC_195 196
#define BOOST_PP_INC_196 197
#define BOOST_PP_INC_197 198
#define BOOST_PP_INC_198 199
#define BOOST_PP_INC_199 200
#define BOOST_PP_INC_200 201
#define BOOST_PP_INC_201 202
#define BOOST_PP_INC_202 203
#define BOOST_PP_INC_203 204
#define BOOST_PP_INC_204 205
#define BOOST_PP_INC_205 206
#define BOOST_PP_INC_206 207
#define BOOST_PP_INC_207 208
#define BOOST_PP_INC_208 209
#define BOOST_PP_INC_209 210
#define BOOST_PP_INC_210 211
#define BOOST_PP_INC_211 212
#define BOOST_PP_INC_212 213
#define BOOST_PP_INC_213 214
#define BOOST_PP_INC_214 215
#define BOOST_PP_INC_215 216
#define BOOST_PP_INC_216 217
#define BOOST_PP_INC_217 218
#define BOOST_PP_INC_218 219
#define BOOST_PP_INC_219 220
#define BOOST_PP_INC_220 221
#define BOOST_PP_INC_221 222
#define BOOST_PP_INC_222 223
#define BOOST_PP_INC_223 224
#define BOOST_PP_INC_224 225
#define BOOST_PP_INC_225 226
#define BOOST_PP_INC_226 227
#define BOOST_PP_INC_227 228
#define BOOST_PP_INC_228 229
#define BOOST_PP_INC_229 230
#define BOOST_PP_INC_230 231
#define BOOST_PP_INC_231 232
#define BOOST_PP_INC_232 233
#define BOOST_PP_INC_233 234
#define BOOST_PP_INC_234 235
#define BOOST_PP_INC_235 236
#define BOOST_PP_INC_236 237
#define BOOST_PP_INC_237 238
#define BOOST_PP_INC_238 239
#define BOOST_PP_INC_239 240
#define BOOST_PP_INC_240 241
#define BOOST_PP_INC_241 242
#define BOOST_PP_INC_242 243
#define BOOST_PP_INC_243 244
#define BOOST_PP_INC_244 245
#define BOOST_PP_INC_245 246
#define BOOST_PP_INC_246 247
#define BOOST_PP_INC_247 248
#define BOOST_PP_INC_248 249
#define BOOST_PP_INC_249 250
#define BOOST_PP_INC_250 251
#define BOOST_PP_INC_251 252
#define BOOST_PP_INC_252 253
#define BOOST_PP_INC_253 254
#define BOOST_PP_INC_254 255
#define BOOST_PP_INC_255 256
#define BOOST_PP_INC_256 256

#define BOOST_PP_INTERCEPT BOOST_PP_INTERCEPT_
#define BOOST_PP_INTERCEPT_0
#define BOOST_PP_INTERCEPT_1
#define BOOST_PP_INTERCEPT_2
#define BOOST_PP_INTERCEPT_3
#define BOOST_PP_INTERCEPT_4
#define BOOST_PP_INTERCEPT_5
#define BOOST_PP_INTERCEPT_6
#define BOOST_PP_INTERCEPT_7
#define BOOST_PP_INTERCEPT_8
#define BOOST_PP_INTERCEPT_9
#define BOOST_PP_INTERCEPT_10
#define BOOST_PP_INTERCEPT_11
#define BOOST_PP_INTERCEPT_12
#define BOOST_PP_INTERCEPT_13
#define BOOST_PP_INTERCEPT_14
#define BOOST_PP_INTERCEPT_15
#define BOOST_PP_INTERCEPT_16
#define BOOST_PP_INTERCEPT_17
#define BOOST_PP_INTERCEPT_18
#define BOOST_PP_INTERCEPT_19
#define BOOST_PP_INTERCEPT_20
#define BOOST_PP_INTERCEPT_21
#define BOOST_PP_INTERCEPT_22
#define BOOST_PP_INTERCEPT_23
#define BOOST_PP_INTERCEPT_24
#define BOOST_PP_INTERCEPT_25
#define BOOST_PP_INTERCEPT_26
#define BOOST_PP_INTERCEPT_27
#define BOOST_PP_INTERCEPT_28
#define BOOST_PP_INTERCEPT_29
#define BOOST_PP_INTERCEPT_30
#define BOOST_PP_INTERCEPT_31
#define BOOST_PP_INTERCEPT_32
#define BOOST_PP_INTERCEPT_33
#define BOOST_PP_INTERCEPT_34
#define BOOST_PP_INTERCEPT_35
#define BOOST_PP_INTERCEPT_36
#define BOOST_PP_INTERCEPT_37
#define BOOST_PP_INTERCEPT_38
#define BOOST_PP_INTERCEPT_39
#define BOOST_PP_INTERCEPT_40
#define BOOST_PP_INTERCEPT_41
#define BOOST_PP_INTERCEPT_42
#define BOOST_PP_INTERCEPT_43
#define BOOST_PP_INTERCEPT_44
#define BOOST_PP_INTERCEPT_45
#define BOOST_PP_INTERCEPT_46
#define BOOST_PP_INTERCEPT_47
#define BOOST_PP_INTERCEPT_48
#define BOOST_PP_INTERCEPT_49
#define BOOST_PP_INTERCEPT_50
#define BOOST_PP_INTERCEPT_51
#define BOOST_PP_INTERCEPT_52
#define BOOST_PP_INTERCEPT_53
#define BOOST_PP_INTERCEPT_54
#define BOOST_PP_INTERCEPT_55
#define BOOST_PP_INTERCEPT_56
#define BOOST_PP_INTERCEPT_57
#define BOOST_PP_INTERCEPT_58
#define BOOST_PP_INTERCEPT_59
#define BOOST_PP_INTERCEPT_60
#define BOOST_PP_INTERCEPT_61
#define BOOST_PP_INTERCEPT_62
#define BOOST_PP_INTERCEPT_63
#define BOOST_PP_INTERCEPT_64
#define BOOST_PP_INTERCEPT_65
#define BOOST_PP_INTERCEPT_66
#define BOOST_PP_INTERCEPT_67
#define BOOST_PP_INTERCEPT_68
#define BOOST_PP_INTERCEPT_69
#define BOOST_PP_INTERCEPT_70
#define BOOST_PP_INTERCEPT_71
#define BOOST_PP_INTERCEPT_72
#define BOOST_PP_INTERCEPT_73
#define BOOST_PP_INTERCEPT_74
#define BOOST_PP_INTERCEPT_75
#define BOOST_PP_INTERCEPT_76
#define BOOST_PP_INTERCEPT_77
#define BOOST_PP_INTERCEPT_78
#define BOOST_PP_INTERCEPT_79
#define BOOST_PP_INTERCEPT_80
#define BOOST_PP_INTERCEPT_81
#define BOOST_PP_INTERCEPT_82
#define BOOST_PP_INTERCEPT_83
#define BOOST_PP_INTERCEPT_84
#define BOOST_PP_INTERCEPT_85
#define BOOST_PP_INTERCEPT_86
#define BOOST_PP_INTERCEPT_87
#define BOOST_PP_INTERCEPT_88
#define BOOST_PP_INTERCEPT_89
#define BOOST_PP_INTERCEPT_90
#define BOOST_PP_INTERCEPT_91
#define BOOST_PP_INTERCEPT_92
#define BOOST_PP_INTERCEPT_93
#define BOOST_PP_INTERCEPT_94
#define BOOST_PP_INTERCEPT_95
#define BOOST_PP_INTERCEPT_96
#define BOOST_PP_INTERCEPT_97
#define BOOST_PP_INTERCEPT_98
#define BOOST_PP_INTERCEPT_99
#define BOOST_PP_INTERCEPT_100
#define BOOST_PP_INTERCEPT_101
#define BOOST_PP_INTERCEPT_102
#define BOOST_PP_INTERCEPT_103
#define BOOST_PP_INTERCEPT_104
#define BOOST_PP_INTERCEPT_105
#define BOOST_PP_INTERCEPT_106
#define BOOST_PP_INTERCEPT_107
#define BOOST_PP_INTERCEPT_108
#define BOOST_PP_INTERCEPT_109
#define BOOST_PP_INTERCEPT_110
#define BOOST_PP_INTERCEPT_111
#define BOOST_PP_INTERCEPT_112
#define BOOST_PP_INTERCEPT_113
#define BOOST_PP_INTERCEPT_114
#define BOOST_PP_INTERCEPT_115
#define BOOST_PP_INTERCEPT_116
#define BOOST_PP_INTERCEPT_117
#define BOOST_PP_INTERCEPT_118
#define BOOST_PP_INTERCEPT_119
#define BOOST_PP_INTERCEPT_120
#define BOOST_PP_INTERCEPT_121
#define BOOST_PP_INTERCEPT_122
#define BOOST_PP_INTERCEPT_123
#define BOOST_PP_INTERCEPT_124
#define BOOST_PP_INTERCEPT_125
#define BOOST_PP_INTERCEPT_126
#define BOOST_PP_INTERCEPT_127
#define BOOST_PP_INTERCEPT_128
#define BOOST_PP_INTERCEPT_129
#define BOOST_PP_INTERCEPT_130
#define BOOST_PP_INTERCEPT_131
#define BOOST_PP_INTERCEPT_132
#define BOOST_PP_INTERCEPT_133
#define BOOST_PP_INTERCEPT_134
#define BOOST_PP_INTERCEPT_135
#define BOOST_PP_INTERCEPT_136
#define BOOST_PP_INTERCEPT_137
#define BOOST_PP_INTERCEPT_138
#define BOOST_PP_INTERCEPT_139
#define BOOST_PP_INTERCEPT_140
#define BOOST_PP_INTERCEPT_141
#define BOOST_PP_INTERCEPT_142
#define BOOST_PP_INTERCEPT_143
#define BOOST_PP_INTERCEPT_144
#define BOOST_PP_INTERCEPT_145
#define BOOST_PP_INTERCEPT_146
#define BOOST_PP_INTERCEPT_147
#define BOOST_PP_INTERCEPT_148
#define BOOST_PP_INTERCEPT_149
#define BOOST_PP_INTERCEPT_150
#define BOOST_PP_INTERCEPT_151
#define BOOST_PP_INTERCEPT_152
#define BOOST_PP_INTERCEPT_153
#define BOOST_PP_INTERCEPT_154
#define BOOST_PP_INTERCEPT_155
#define BOOST_PP_INTERCEPT_156
#define BOOST_PP_INTERCEPT_157
#define BOOST_PP_INTERCEPT_158
#define BOOST_PP_INTERCEPT_159
#define BOOST_PP_INTERCEPT_160
#define BOOST_PP_INTERCEPT_161
#define BOOST_PP_INTERCEPT_162
#define BOOST_PP_INTERCEPT_163
#define BOOST_PP_INTERCEPT_164
#define BOOST_PP_INTERCEPT_165
#define BOOST_PP_INTERCEPT_166
#define BOOST_PP_INTERCEPT_167
#define BOOST_PP_INTERCEPT_168
#define BOOST_PP_INTERCEPT_169
#define BOOST_PP_INTERCEPT_170
#define BOOST_PP_INTERCEPT_171
#define BOOST_PP_INTERCEPT_172
#define BOOST_PP_INTERCEPT_173
#define BOOST_PP_INTERCEPT_174
#define BOOST_PP_INTERCEPT_175
#define BOOST_PP_INTERCEPT_176
#define BOOST_PP_INTERCEPT_177
#define BOOST_PP_INTERCEPT_178
#define BOOST_PP_INTERCEPT_179
#define BOOST_PP_INTERCEPT_180
#define BOOST_PP_INTERCEPT_181
#define BOOST_PP_INTERCEPT_182
#define BOOST_PP_INTERCEPT_183
#define BOOST_PP_INTERCEPT_184
#define BOOST_PP_INTERCEPT_185
#define BOOST_PP_INTERCEPT_186
#define BOOST_PP_INTERCEPT_187
#define BOOST_PP_INTERCEPT_188
#define BOOST_PP_INTERCEPT_189
#define BOOST_PP_INTERCEPT_190
#define BOOST_PP_INTERCEPT_191
#define BOOST_PP_INTERCEPT_192
#define BOOST_PP_INTERCEPT_193
#define BOOST_PP_INTERCEPT_194
#define BOOST_PP_INTERCEPT_195
#define BOOST_PP_INTERCEPT_196
#define BOOST_PP_INTERCEPT_197
#define BOOST_PP_INTERCEPT_198
#define BOOST_PP_INTERCEPT_199
#define BOOST_PP_INTERCEPT_200
#define BOOST_PP_INTERCEPT_201
#define BOOST_PP_INTERCEPT_202
#define BOOST_PP_INTERCEPT_203
#define BOOST_PP_INTERCEPT_204
#define BOOST_PP_INTERCEPT_205
#define BOOST_PP_INTERCEPT_206
#define BOOST_PP_INTERCEPT_207
#define BOOST_PP_INTERCEPT_208
#define BOOST_PP_INTERCEPT_209
#define BOOST_PP_INTERCEPT_210
#define BOOST_PP_INTERCEPT_211
#define BOOST_PP_INTERCEPT_212
#define BOOST_PP_INTERCEPT_213
#define BOOST_PP_INTERCEPT_214
#define BOOST_PP_INTERCEPT_215
#define BOOST_PP_INTERCEPT_216
#define BOOST_PP_INTERCEPT_217
#define BOOST_PP_INTERCEPT_218
#define BOOST_PP_INTERCEPT_219
#define BOOST_PP_INTERCEPT_220
#define BOOST_PP_INTERCEPT_221
#define BOOST_PP_INTERCEPT_222
#define BOOST_PP_INTERCEPT_223
#define BOOST_PP_INTERCEPT_224
#define BOOST_PP_INTERCEPT_225
#define BOOST_PP_INTERCEPT_226
#define BOOST_PP_INTERCEPT_227
#define BOOST_PP_INTERCEPT_228
#define BOOST_PP_INTERCEPT_229
#define BOOST_PP_INTERCEPT_230
#define BOOST_PP_INTERCEPT_231
#define BOOST_PP_INTERCEPT_232
#define BOOST_PP_INTERCEPT_233
#define BOOST_PP_INTERCEPT_234
#define BOOST_PP_INTERCEPT_235
#define BOOST_PP_INTERCEPT_236
#define BOOST_PP_INTERCEPT_237
#define BOOST_PP_INTERCEPT_238
#define BOOST_PP_INTERCEPT_239
#define BOOST_PP_INTERCEPT_240
#define BOOST_PP_INTERCEPT_241
#define BOOST_PP_INTERCEPT_242
#define BOOST_PP_INTERCEPT_243
#define BOOST_PP_INTERCEPT_244
#define BOOST_PP_INTERCEPT_245
#define BOOST_PP_INTERCEPT_246
#define BOOST_PP_INTERCEPT_247
#define BOOST_PP_INTERCEPT_248
#define BOOST_PP_INTERCEPT_249
#define BOOST_PP_INTERCEPT_250
#define BOOST_PP_INTERCEPT_251
#define BOOST_PP_INTERCEPT_252
#define BOOST_PP_INTERCEPT_253
#define BOOST_PP_INTERCEPT_254
#define BOOST_PP_INTERCEPT_255
#define BOOST_PP_INTERCEPT_256

#define BOOST_PP_IS_1(x) BOOST_PP_IS_EMPTY(BOOST_PP_CAT(BOOST_PP_IS_1_HELPER_, x))
#define BOOST_PP_IS_1_HELPER_1

#define BOOST_PP_IS_BINARY(x) BOOST_PP_CHECK(x, BOOST_PP_IS_BINARY_CHECK)
#define BOOST_PP_IS_BINARY_CHECK(a, b) 1

#define BOOST_PP_IS_EMPTY(x) BOOST_PP_IS_EMPTY_I(x BOOST_PP_IS_EMPTY_HELPER)
#define BOOST_PP_IS_EMPTY_I(contents) BOOST_PP_TUPLE_ELEM(2, 1, (BOOST_PP_IS_EMPTY_DEF_ ## contents()))
#define BOOST_PP_IS_EMPTY_DEF_BOOST_PP_IS_EMPTY_HELPER 1, 1 BOOST_PP_EMPTY
#define BOOST_PP_IS_EMPTY_HELPER() , 0

#define BOOST_PP_IS_EMPTY_OR_1(x)	\
    BOOST_PP_IIF(	\
        BOOST_PP_IS_EMPTY(x BOOST_PP_EMPTY()),	\
        1 BOOST_PP_EMPTY,	\
        BOOST_PP_IS_1	\
    )(x)	\
    /**/

#define BOOST_PP_IS_NULLARY(x) BOOST_PP_CHECK(x, BOOST_PP_IS_NULLARY_CHECK)
#define BOOST_PP_IS_NULLARY_CHECK() 1

#define BOOST_PP_IS_UNARY(x) BOOST_PP_CHECK(x, BOOST_PP_IS_UNARY_CHECK)
#define BOOST_PP_IS_UNARY_CHECK(a) 1

#define BOOST_PP_ITERATE() BOOST_PP_CAT(BOOST_PP_ITERATE_, BOOST_PP_INC(BOOST_PP_ITERATION_DEPTH()))
#define BOOST_PP_ITERATE_1 <boost/preprocessor/iteration/detail/iter/forward1.hpp>
#define BOOST_PP_ITERATE_2 <boost/preprocessor/iteration/detail/iter/forward2.hpp>
#define BOOST_PP_ITERATE_3 <boost/preprocessor/iteration/detail/iter/forward3.hpp>
#define BOOST_PP_ITERATE_4 <boost/preprocessor/iteration/detail/iter/forward4.hpp>
#define BOOST_PP_ITERATE_5 <boost/preprocessor/iteration/detail/iter/forward5.hpp>

#define BOOST_PP_ITERATION() BOOST_PP_CAT(BOOST_PP_ITERATION_, BOOST_PP_ITERATION_DEPTH())
#define BOOST_PP_ITERATION_DEPTH() 0
#define BOOST_PP_ITERATION_FINISH() BOOST_PP_CAT(BOOST_PP_ITERATION_FINISH_, BOOST_PP_ITERATION_DEPTH())
#define BOOST_PP_ITERATION_FLAGS() (BOOST_PP_CAT(BOOST_PP_ITERATION_FLAGS_, BOOST_PP_ITERATION_DEPTH()))
#define BOOST_PP_ITERATION_START() BOOST_PP_CAT(BOOST_PP_ITERATION_START_, BOOST_PP_ITERATION_DEPTH())

#define BOOST_PP_ITERATION_FINISH_1 BOOST_PP_ITERATION_FINISH_1_DIGIT_1
#define BOOST_PP_ITERATION_FINISH_1_DIGIT_1 0
#define BOOST_PP_ITERATION_FINISH_2 BOOST_PP_ITERATION_FINISH_2_DIGIT_1
#define BOOST_PP_ITERATION_FINISH_2_DIGIT_1 0
#define BOOST_PP_ITERATION_FINISH_3 BOOST_PP_ITERATION_FINISH_3_DIGIT_1
#define BOOST_PP_ITERATION_FINISH_3_DIGIT_1 0
#define BOOST_PP_ITERATION_FINISH_4 BOOST_PP_ITERATION_FINISH_4_DIGIT_1
#define BOOST_PP_ITERATION_FINISH_4_DIGIT_1 0
#define BOOST_PP_ITERATION_FINISH_5 BOOST_PP_ITERATION_FINISH_5_DIGIT_1
#define BOOST_PP_ITERATION_FINISH_5_DIGIT_1 0

#define BOOST_PP_ITERATION_1 0
#define BOOST_PP_ITERATION_2 0
#define BOOST_PP_ITERATION_3 0
#define BOOST_PP_ITERATION_4 0
#define BOOST_PP_ITERATION_5 0

#define BOOST_PP_ITERATION_FLAGS_1 0
#define BOOST_PP_ITERATION_FLAGS_2 0
#define BOOST_PP_ITERATION_FLAGS_3 0
#define BOOST_PP_ITERATION_FLAGS_4 0
#define BOOST_PP_ITERATION_FLAGS_5 0

#define BOOST_PP_ITERATION_LIMITS (0,BOOST_MPL_LIMIT_METAFUNCTION_ARITY)

#define BOOST_PP_ITERATION_START_1 BOOST_PP_ITERATION_START_1_DIGIT_1
#define BOOST_PP_ITERATION_START_1_DIGIT_1 0
#define BOOST_PP_ITERATION_START_1_DIGIT_2 0
#define BOOST_PP_ITERATION_START_1_DIGIT_3 0
#define BOOST_PP_ITERATION_START_2 BOOST_PP_ITERATION_START_2_DIGIT_1
#define BOOST_PP_ITERATION_START_2_DIGIT_1 0
#define BOOST_PP_ITERATION_START_2_DIGIT_2 0
#define BOOST_PP_ITERATION_START_2_DIGIT_3 0
#define BOOST_PP_ITERATION_START_3 BOOST_PP_ITERATION_START_3_DIGIT_1
#define BOOST_PP_ITERATION_START_3_DIGIT_1 0
#define BOOST_PP_ITERATION_START_3_DIGIT_2 0
#define BOOST_PP_ITERATION_START_3_DIGIT_3 0
#define BOOST_PP_ITERATION_START_4 BOOST_PP_ITERATION_START_4_DIGIT_1
#define BOOST_PP_ITERATION_START_4_DIGIT_1 0
#define BOOST_PP_ITERATION_START_4_DIGIT_2 0
#define BOOST_PP_ITERATION_START_4_DIGIT_3 0
#define BOOST_PP_ITERATION_START_5 BOOST_PP_ITERATION_START_5_DIGIT_1
#define BOOST_PP_ITERATION_START_5_DIGIT_1 0
#define BOOST_PP_ITERATION_START_5_DIGIT_2 0
#define BOOST_PP_ITERATION_START_5_DIGIT_3 0

#define BOOST_PP_LESS(x, y) BOOST_PP_IIF(BOOST_PP_NOT_EQUAL(x, y), BOOST_PP_LESS_EQUAL, 0 BOOST_PP_TUPLE_EAT_2)(x, y)
#define BOOST_PP_LESS_D(d, x, y) BOOST_PP_IIF(BOOST_PP_NOT_EQUAL(x, y), BOOST_PP_LESS_EQUAL_D, 0 BOOST_PP_TUPLE_EAT_3)(d, x, y)

#define BOOST_PP_LESS_EQUAL(x, y) BOOST_PP_NOT(BOOST_PP_SUB(x, y))
#define BOOST_PP_LESS_EQUAL_D(d, x, y) BOOST_PP_NOT(BOOST_PP_SUB_D(d, x, y))

#define BOOST_PP_LIMIT_DIM 3
#define BOOST_PP_LIMIT_FOR 256
#define BOOST_PP_LIMIT_ITERATION 256
#define BOOST_PP_LIMIT_ITERATION_DIM 3
#define BOOST_PP_LIMIT_MAG 256
#define BOOST_PP_LIMIT_REPEAT 256
#define BOOST_PP_LIMIT_SEQ 256
#define BOOST_PP_LIMIT_SLOT_COUNT 5
#define BOOST_PP_LIMIT_SLOT_SIG 10
#define BOOST_PP_LIMIT_TUPLE 25
#define BOOST_PP_LIMIT_WHILE 256

#define BOOST_PP_LINE(line, file) line __FILE__

#define BOOST_PP_LIST_APPEND(a, b) BOOST_PP_LIST_FOLD_RIGHT(BOOST_PP_LIST_APPEND_O, b, a)
#define BOOST_PP_LIST_APPEND_D(d, a, b) BOOST_PP_LIST_FOLD_RIGHT_ ## d(BOOST_PP_LIST_APPEND_O, b, a)
#define BOOST_PP_LIST_APPEND_O(d, s, x) (x, s)

#define BOOST_PP_LIST_AT(list, index) BOOST_PP_LIST_FIRST(BOOST_PP_LIST_REST_N(index, list))
#define BOOST_PP_LIST_AT_D(d, list, index) BOOST_PP_LIST_FIRST(BOOST_PP_LIST_REST_N_D(d, index, list))

#define BOOST_PP_LIST_CAT(list) BOOST_PP_LIST_FOLD_LEFT(BOOST_PP_LIST_CAT_O, BOOST_PP_LIST_FIRST(list), BOOST_PP_LIST_REST(list))
#define BOOST_PP_LIST_CAT_D(d, list) BOOST_PP_LIST_FOLD_LEFT_ ## d(BOOST_PP_LIST_CAT_O, BOOST_PP_LIST_FIRST(list), BOOST_PP_LIST_REST(list))
#define BOOST_PP_LIST_CAT_O(d, s, x) BOOST_PP_CAT(s, x)

#define BOOST_PP_LIST_CONS(head, tail) (head, tail)

#define BOOST_PP_LIST_ENUM(list) BOOST_PP_LIST_FOR_EACH_I(BOOST_PP_LIST_ENUM_O, BOOST_PP_NIL, list)
#define BOOST_PP_LIST_ENUM_O(r, _, i, elem) BOOST_PP_COMMA_IF(i) elem
#define BOOST_PP_LIST_ENUM_R(r, list) BOOST_PP_LIST_FOR_EACH_I_R(r, BOOST_PP_LIST_ENUM_O, BOOST_PP_NIL, list)

#define BOOST_PP_LIST_FILTER(pred, data, list) BOOST_PP_TUPLE_ELEM(3, 2, BOOST_PP_LIST_FOLD_RIGHT(BOOST_PP_LIST_FILTER_O, (pred, data, BOOST_PP_NIL), list))
#define BOOST_PP_LIST_FILTER_D(d, pred, data, list) BOOST_PP_TUPLE_ELEM(3, 2, BOOST_PP_LIST_FOLD_RIGHT_ ## d(BOOST_PP_LIST_FILTER_O, (pred, data, BOOST_PP_NIL), list))
#define BOOST_PP_LIST_FILTER_O(d, pdr, elem) BOOST_PP_LIST_FILTER_O_D(d, BOOST_PP_TUPLE_ELEM(3, 0, pdr), BOOST_PP_TUPLE_ELEM(3, 1, pdr), BOOST_PP_TUPLE_ELEM(3, 2, pdr), elem)
#define BOOST_PP_LIST_FILTER_O_D(d, pred, data, res, elem) (pred, data, BOOST_PP_IF(pred(d, data, elem), (elem, res), res))

#define BOOST_PP_LIST_FIRST(list) BOOST_PP_LIST_FIRST_D(list)
#define BOOST_PP_LIST_FIRST_D(list) BOOST_PP_LIST_FIRST_I list
#define BOOST_PP_LIST_FIRST_I(head, tail) head
#define BOOST_PP_LIST_FIRST_N(count, list) BOOST_PP_LIST_REVERSE(BOOST_PP_TUPLE_ELEM(3, 2, BOOST_PP_WHILE(BOOST_PP_LIST_FIRST_N_P, BOOST_PP_LIST_FIRST_N_O, (count, list, BOOST_PP_NIL))))
#define BOOST_PP_LIST_FIRST_N_D(d, count, list) BOOST_PP_LIST_REVERSE_D(d, BOOST_PP_TUPLE_ELEM(3, 2, BOOST_PP_WHILE_ ## d(BOOST_PP_LIST_FIRST_N_P, BOOST_PP_LIST_FIRST_N_O, (count, list, BOOST_PP_NIL))))
#define BOOST_PP_LIST_FIRST_N_O(d, data) BOOST_PP_LIST_FIRST_N_O_D data
#define BOOST_PP_LIST_FIRST_N_O_D(c, l, nl) (BOOST_PP_DEC(c), BOOST_PP_LIST_REST(l), (BOOST_PP_LIST_FIRST(l), nl))
#define BOOST_PP_LIST_FIRST_N_P(d, data) BOOST_PP_TUPLE_ELEM(3, 0, data)

#define BOOST_PP_LIST_FOLD_LEFT BOOST_PP_CAT(BOOST_PP_LIST_FOLD_LEFT_, BOOST_PP_AUTO_REC(BOOST_PP_WHILE_P, 256))
#define BOOST_PP_LIST_FOLD_LEFT_D(d, o, s, l) BOOST_PP_LIST_FOLD_LEFT_ ## d(o, s, l)
#define BOOST_PP_LIST_FOLD_LEFT_1(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_2, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(2, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_2(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_3, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(3, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_3(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_4, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(4, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_4(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_5, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(5, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_5(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_6, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(6, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_6(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_7, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(7, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_7(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_8, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(8, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_8(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_9, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(9, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_9(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_10, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(10, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_10(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_11, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(11, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_11(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_12, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(12, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_12(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_13, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(13, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_13(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_14, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(14, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_14(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_15, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(15, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_15(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_16, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(16, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_16(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_17, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(17, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_17(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_18, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(18, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_18(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_19, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(19, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_19(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_20, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(20, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_20(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_21, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(21, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_21(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_22, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(22, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_22(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_23, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(23, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_23(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_24, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(24, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_24(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_25, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(25, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_25(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_26, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(26, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_26(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_27, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(27, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_27(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_28, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(28, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_28(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_29, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(29, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_29(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_30, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(30, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_30(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_31, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(31, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_31(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_32, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(32, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_32(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_33, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(33, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_33(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_34, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(34, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_34(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_35, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(35, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_35(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_36, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(36, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_36(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_37, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(37, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_37(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_38, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(38, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_38(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_39, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(39, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_39(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_40, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(40, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_40(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_41, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(41, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_41(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_42, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(42, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_42(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_43, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(43, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_43(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_44, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(44, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_44(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_45, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(45, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_45(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_46, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(46, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_46(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_47, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(47, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_47(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_48, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(48, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_48(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_49, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(49, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_49(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_50, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(50, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_50(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_51, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(51, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_51(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_52, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(52, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_52(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_53, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(53, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_53(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_54, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(54, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_54(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_55, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(55, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_55(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_56, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(56, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_56(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_57, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(57, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_57(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_58, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(58, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_58(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_59, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(59, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_59(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_60, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(60, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_60(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_61, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(61, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_61(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_62, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(62, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_62(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_63, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(63, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_63(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_64, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(64, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_64(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_65, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(65, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_65(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_66, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(66, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_66(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_67, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(67, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_67(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_68, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(68, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_68(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_69, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(69, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_69(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_70, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(70, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_70(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_71, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(71, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_71(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_72, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(72, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_72(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_73, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(73, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_73(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_74, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(74, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_74(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_75, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(75, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_75(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_76, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(76, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_76(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_77, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(77, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_77(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_78, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(78, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_78(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_79, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(79, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_79(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_80, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(80, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_80(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_81, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(81, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_81(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_82, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(82, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_82(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_83, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(83, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_83(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_84, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(84, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_84(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_85, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(85, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_85(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_86, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(86, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_86(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_87, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(87, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_87(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_88, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(88, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_88(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_89, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(89, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_89(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_90, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(90, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_90(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_91, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(91, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_91(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_92, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(92, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_92(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_93, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(93, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_93(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_94, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(94, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_94(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_95, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(95, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_95(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_96, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(96, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_96(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_97, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(97, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_97(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_98, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(98, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_98(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_99, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(99, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_99(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_100, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(100, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_100(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_101, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(101, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_101(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_102, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(102, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_102(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_103, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(103, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_103(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_104, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(104, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_104(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_105, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(105, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_105(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_106, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(106, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_106(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_107, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(107, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_107(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_108, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(108, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_108(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_109, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(109, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_109(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_110, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(110, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_110(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_111, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(111, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_111(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_112, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(112, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_112(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_113, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(113, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_113(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_114, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(114, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_114(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_115, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(115, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_115(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_116, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(116, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_116(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_117, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(117, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_117(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_118, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(118, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_118(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_119, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(119, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_119(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_120, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(120, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_120(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_121, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(121, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_121(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_122, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(122, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_122(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_123, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(123, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_123(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_124, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(124, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_124(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_125, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(125, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_125(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_126, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(126, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_126(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_127, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(127, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_127(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_128, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(128, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_128(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_129, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(129, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_129(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_130, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(130, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_130(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_131, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(131, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_131(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_132, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(132, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_132(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_133, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(133, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_133(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_134, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(134, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_134(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_135, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(135, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_135(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_136, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(136, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_136(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_137, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(137, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_137(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_138, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(138, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_138(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_139, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(139, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_139(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_140, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(140, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_140(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_141, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(141, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_141(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_142, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(142, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_142(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_143, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(143, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_143(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_144, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(144, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_144(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_145, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(145, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_145(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_146, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(146, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_146(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_147, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(147, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_147(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_148, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(148, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_148(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_149, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(149, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_149(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_150, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(150, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_150(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_151, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(151, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_151(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_152, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(152, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_152(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_153, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(153, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_153(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_154, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(154, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_154(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_155, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(155, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_155(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_156, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(156, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_156(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_157, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(157, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_157(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_158, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(158, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_158(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_159, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(159, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_159(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_160, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(160, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_160(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_161, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(161, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_161(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_162, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(162, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_162(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_163, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(163, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_163(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_164, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(164, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_164(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_165, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(165, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_165(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_166, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(166, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_166(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_167, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(167, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_167(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_168, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(168, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_168(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_169, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(169, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_169(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_170, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(170, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_170(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_171, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(171, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_171(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_172, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(172, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_172(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_173, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(173, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_173(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_174, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(174, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_174(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_175, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(175, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_175(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_176, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(176, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_176(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_177, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(177, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_177(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_178, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(178, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_178(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_179, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(179, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_179(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_180, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(180, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_180(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_181, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(181, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_181(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_182, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(182, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_182(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_183, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(183, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_183(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_184, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(184, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_184(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_185, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(185, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_185(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_186, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(186, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_186(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_187, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(187, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_187(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_188, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(188, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_188(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_189, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(189, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_189(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_190, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(190, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_190(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_191, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(191, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_191(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_192, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(192, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_192(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_193, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(193, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_193(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_194, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(194, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_194(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_195, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(195, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_195(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_196, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(196, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_196(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_197, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(197, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_197(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_198, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(198, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_198(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_199, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(199, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_199(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_200, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(200, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_200(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_201, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(201, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_201(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_202, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(202, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_202(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_203, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(203, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_203(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_204, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(204, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_204(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_205, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(205, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_205(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_206, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(206, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_206(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_207, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(207, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_207(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_208, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(208, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_208(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_209, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(209, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_209(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_210, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(210, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_210(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_211, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(211, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_211(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_212, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(212, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_212(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_213, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(213, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_213(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_214, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(214, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_214(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_215, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(215, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_215(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_216, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(216, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_216(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_217, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(217, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_217(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_218, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(218, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_218(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_219, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(219, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_219(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_220, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(220, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_220(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_221, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(221, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_221(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_222, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(222, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_222(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_223, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(223, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_223(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_224, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(224, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_224(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_225, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(225, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_225(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_226, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(226, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_226(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_227, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(227, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_227(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_228, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(228, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_228(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_229, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(229, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_229(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_230, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(230, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_230(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_231, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(231, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_231(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_232, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(232, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_232(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_233, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(233, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_233(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_234, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(234, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_234(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_235, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(235, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_235(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_236, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(236, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_236(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_237, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(237, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_237(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_238, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(238, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_238(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_239, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(239, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_239(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_240, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(240, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_240(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_241, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(241, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_241(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_242, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(242, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_242(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_243, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(243, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_243(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_244, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(244, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_244(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_245, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(245, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_245(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_246, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(246, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_246(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_247, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(247, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_247(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_248, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(248, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_248(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_249, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(249, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_249(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_250, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(250, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_250(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_251, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(251, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_251(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_252, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(252, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_252(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_253, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(253, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_253(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_254, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(254, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_254(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_255, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(255, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_255(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_256, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(256, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))
#define BOOST_PP_LIST_FOLD_LEFT_256(o, s, l) BOOST_PP_IIF(BOOST_PP_LIST_IS_CONS(l), BOOST_PP_LIST_FOLD_LEFT_257, s BOOST_PP_TUPLE_EAT_3)(o, BOOST_PP_EXPR_IIF(BOOST_PP_LIST_IS_CONS(l), o)(257, s, BOOST_PP_LIST_FIRST(l)), BOOST_PP_LIST_REST(l))

#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_1(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_2(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_3(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_4(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_5(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_6(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_7(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_8(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_9(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_10(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_11(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_12(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_13(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_14(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_15(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_16(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_17(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_18(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_19(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_20(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_21(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_22(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_23(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_24(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_25(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_26(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_27(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_28(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_29(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_30(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_31(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_32(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_33(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_34(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_35(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_36(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_37(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_38(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_39(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_40(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_41(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_42(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_43(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_44(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_45(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_46(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_47(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_48(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_49(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_50(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_51(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_52(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_53(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_54(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_55(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_56(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_57(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_58(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_59(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_60(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_61(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_62(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_63(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_64(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_65(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_66(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_67(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_68(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_69(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_70(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_71(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_72(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_73(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_74(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_75(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_76(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_77(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_78(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_79(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_80(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_81(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_82(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_83(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_84(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_85(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_86(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_87(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_88(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_89(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_90(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_91(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_92(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_93(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_94(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_95(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_96(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_97(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_98(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_99(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_100(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_101(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_102(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_103(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_104(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_105(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_106(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_107(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_108(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_109(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_110(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_111(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_112(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_113(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_114(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_115(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_116(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_117(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_118(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_119(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_120(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_121(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_122(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_123(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_124(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_125(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_126(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_127(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_128(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_129(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_130(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_131(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_132(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_133(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_134(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_135(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_136(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_137(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_138(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_139(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_140(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_141(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_142(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_143(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_144(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_145(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_146(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_147(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_148(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_149(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_150(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_151(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_152(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_153(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_154(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_155(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_156(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_157(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_158(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_159(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_160(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_161(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_162(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_163(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_164(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_165(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_166(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_167(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_168(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_169(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_170(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_171(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_172(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_173(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_174(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_175(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_176(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_177(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_178(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_179(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_180(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_181(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_182(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_183(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_184(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_185(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_186(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_187(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_188(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_189(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_190(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_191(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_192(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_193(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_194(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_195(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_196(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_197(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_198(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_199(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_200(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_201(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_202(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_203(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_204(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_205(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_206(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_207(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_208(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_209(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_210(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_211(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_212(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_213(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_214(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_215(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_216(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_217(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_218(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_219(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_220(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_221(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_222(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_223(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_224(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_225(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_226(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_227(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_228(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_229(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_230(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_231(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_232(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_233(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_234(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_235(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_236(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_237(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_238(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_239(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_240(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_241(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_242(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_243(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_244(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_245(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_246(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_247(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_248(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_249(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_250(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_251(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_252(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_253(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_254(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_255(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_LIST_FOLD_LEFT_256(o, s, l) 0
#define BOOST_PP_LIST_FOLD_LEFT_CHECK_BOOST_PP_NIL 1

#define BOOST_PP_LIST_FOLD_RIGHT BOOST_PP_CAT(BOOST_PP_LIST_FOLD_RIGHT_, BOOST_PP_AUTO_REC(BOOST_PP_WHILE_P, 256))
#define BOOST_PP_LIST_FOLD_RIGHT_257(o, s, l) BOOST_PP_ERROR(0x0004)
#define BOOST_PP_LIST_FOLD_RIGHT_D(d, o, s, l) BOOST_PP_LIST_FOLD_RIGHT_ ## d(o, s, l)
#define BOOST_PP_LIST_FOLD_RIGHT_1(o, s, l) BOOST_PP_LIST_FOLD_LEFT_1(o, s, BOOST_PP_LIST_REVERSE_D(1, l))
#define BOOST_PP_LIST_FOLD_RIGHT_2(o, s, l) BOOST_PP_LIST_FOLD_LEFT_2(o, s, BOOST_PP_LIST_REVERSE_D(2, l))
#define BOOST_PP_LIST_FOLD_RIGHT_3(o, s, l) BOOST_PP_LIST_FOLD_LEFT_3(o, s, BOOST_PP_LIST_REVERSE_D(3, l))
#define BOOST_PP_LIST_FOLD_RIGHT_4(o, s, l) BOOST_PP_LIST_FOLD_LEFT_4(o, s, BOOST_PP_LIST_REVERSE_D(4, l))
#define BOOST_PP_LIST_FOLD_RIGHT_5(o, s, l) BOOST_PP_LIST_FOLD_LEFT_5(o, s, BOOST_PP_LIST_REVERSE_D(5, l))
#define BOOST_PP_LIST_FOLD_RIGHT_6(o, s, l) BOOST_PP_LIST_FOLD_LEFT_6(o, s, BOOST_PP_LIST_REVERSE_D(6, l))
#define BOOST_PP_LIST_FOLD_RIGHT_7(o, s, l) BOOST_PP_LIST_FOLD_LEFT_7(o, s, BOOST_PP_LIST_REVERSE_D(7, l))
#define BOOST_PP_LIST_FOLD_RIGHT_8(o, s, l) BOOST_PP_LIST_FOLD_LEFT_8(o, s, BOOST_PP_LIST_REVERSE_D(8, l))
#define BOOST_PP_LIST_FOLD_RIGHT_9(o, s, l) BOOST_PP_LIST_FOLD_LEFT_9(o, s, BOOST_PP_LIST_REVERSE_D(9, l))
#define BOOST_PP_LIST_FOLD_RIGHT_10(o, s, l) BOOST_PP_LIST_FOLD_LEFT_10(o, s, BOOST_PP_LIST_REVERSE_D(10, l))
#define BOOST_PP_LIST_FOLD_RIGHT_11(o, s, l) BOOST_PP_LIST_FOLD_LEFT_11(o, s, BOOST_PP_LIST_REVERSE_D(11, l))
#define BOOST_PP_LIST_FOLD_RIGHT_12(o, s, l) BOOST_PP_LIST_FOLD_LEFT_12(o, s, BOOST_PP_LIST_REVERSE_D(12, l))
#define BOOST_PP_LIST_FOLD_RIGHT_13(o, s, l) BOOST_PP_LIST_FOLD_LEFT_13(o, s, BOOST_PP_LIST_REVERSE_D(13, l))
#define BOOST_PP_LIST_FOLD_RIGHT_14(o, s, l) BOOST_PP_LIST_FOLD_LEFT_14(o, s, BOOST_PP_LIST_REVERSE_D(14, l))
#define BOOST_PP_LIST_FOLD_RIGHT_15(o, s, l) BOOST_PP_LIST_FOLD_LEFT_15(o, s, BOOST_PP_LIST_REVERSE_D(15, l))
#define BOOST_PP_LIST_FOLD_RIGHT_16(o, s, l) BOOST_PP_LIST_FOLD_LEFT_16(o, s, BOOST_PP_LIST_REVERSE_D(16, l))
#define BOOST_PP_LIST_FOLD_RIGHT_17(o, s, l) BOOST_PP_LIST_FOLD_LEFT_17(o, s, BOOST_PP_LIST_REVERSE_D(17, l))
#define BOOST_PP_LIST_FOLD_RIGHT_18(o, s, l) BOOST_PP_LIST_FOLD_LEFT_18(o, s, BOOST_PP_LIST_REVERSE_D(18, l))
#define BOOST_PP_LIST_FOLD_RIGHT_19(o, s, l) BOOST_PP_LIST_FOLD_LEFT_19(o, s, BOOST_PP_LIST_REVERSE_D(19, l))
#define BOOST_PP_LIST_FOLD_RIGHT_20(o, s, l) BOOST_PP_LIST_FOLD_LEFT_20(o, s, BOOST_PP_LIST_REVERSE_D(20, l))
#define BOOST_PP_LIST_FOLD_RIGHT_21(o, s, l) BOOST_PP_LIST_FOLD_LEFT_21(o, s, BOOST_PP_LIST_REVERSE_D(21, l))
#define BOOST_PP_LIST_FOLD_RIGHT_22(o, s, l) BOOST_PP_LIST_FOLD_LEFT_22(o, s, BOOST_PP_LIST_REVERSE_D(22, l))
#define BOOST_PP_LIST_FOLD_RIGHT_23(o, s, l) BOOST_PP_LIST_FOLD_LEFT_23(o, s, BOOST_PP_LIST_REVERSE_D(23, l))
#define BOOST_PP_LIST_FOLD_RIGHT_24(o, s, l) BOOST_PP_LIST_FOLD_LEFT_24(o, s, BOOST_PP_LIST_REVERSE_D(24, l))
#define BOOST_PP_LIST_FOLD_RIGHT_25(o, s, l) BOOST_PP_LIST_FOLD_LEFT_25(o, s, BOOST_PP_LIST_REVERSE_D(25, l))
#define BOOST_PP_LIST_FOLD_RIGHT_26(o, s, l) BOOST_PP_LIST_FOLD_LEFT_26(o, s, BOOST_PP_LIST_REVERSE_D(26, l))
#define BOOST_PP_LIST_FOLD_RIGHT_27(o, s, l) BOOST_PP_LIST_FOLD_LEFT_27(o, s, BOOST_PP_LIST_REVERSE_D(27, l))
#define BOOST_PP_LIST_FOLD_RIGHT_28(o, s, l) BOOST_PP_LIST_FOLD_LEFT_28(o, s, BOOST_PP_LIST_REVERSE_D(28, l))
#define BOOST_PP_LIST_FOLD_RIGHT_29(o, s, l) BOOST_PP_LIST_FOLD_LEFT_29(o, s, BOOST_PP_LIST_REVERSE_D(29, l))
#define BOOST_PP_LIST_FOLD_RIGHT_30(o, s, l) BOOST_PP_LIST_FOLD_LEFT_30(o, s, BOOST_PP_LIST_REVERSE_D(30, l))
#define BOOST_PP_LIST_FOLD_RIGHT_31(o, s, l) BOOST_PP_LIST_FOLD_LEFT_31(o, s, BOOST_PP_LIST_REVERSE_D(31, l))
#define BOOST_PP_LIST_FOLD_RIGHT_32(o, s, l) BOOST_PP_LIST_FOLD_LEFT_32(o, s, BOOST_PP_LIST_REVERSE_D(32, l))
#define BOOST_PP_LIST_FOLD_RIGHT_33(o, s, l) BOOST_PP_LIST_FOLD_LEFT_33(o, s, BOOST_PP_LIST_REVERSE_D(33, l))
#define BOOST_PP_LIST_FOLD_RIGHT_34(o, s, l) BOOST_PP_LIST_FOLD_LEFT_34(o, s, BOOST_PP_LIST_REVERSE_D(34, l))
#define BOOST_PP_LIST_FOLD_RIGHT_35(o, s, l) BOOST_PP_LIST_FOLD_LEFT_35(o, s, BOOST_PP_LIST_REVERSE_D(35, l))
#define BOOST_PP_LIST_FOLD_RIGHT_36(o, s, l) BOOST_PP_LIST_FOLD_LEFT_36(o, s, BOOST_PP_LIST_REVERSE_D(36, l))
#define BOOST_PP_LIST_FOLD_RIGHT_37(o, s, l) BOOST_PP_LIST_FOLD_LEFT_37(o, s, BOOST_PP_LIST_REVERSE_D(37, l))
#define BOOST_PP_LIST_FOLD_RIGHT_38(o, s, l) BOOST_PP_LIST_FOLD_LEFT_38(o, s, BOOST_PP_LIST_REVERSE_D(38, l))
#define BOOST_PP_LIST_FOLD_RIGHT_39(o, s, l) BOOST_PP_LIST_FOLD_LEFT_39(o, s, BOOST_PP_LIST_REVERSE_D(39, l))
#define BOOST_PP_LIST_FOLD_RIGHT_40(o, s, l) BOOST_PP_LIST_FOLD_LEFT_40(o, s, BOOST_PP_LIST_REVERSE_D(40, l))
#define BOOST_PP_LIST_FOLD_RIGHT_41(o, s, l) BOOST_PP_LIST_FOLD_LEFT_41(o, s, BOOST_PP_LIST_REVERSE_D(41, l))
#define BOOST_PP_LIST_FOLD_RIGHT_42(o, s, l) BOOST_PP_LIST_FOLD_LEFT_42(o, s, BOOST_PP_LIST_REVERSE_D(42, l))
#define BOOST_PP_LIST_FOLD_RIGHT_43(o, s, l) BOOST_PP_LIST_FOLD_LEFT_43(o, s, BOOST_PP_LIST_REVERSE_D(43, l))
#define BOOST_PP_LIST_FOLD_RIGHT_44(o, s, l) BOOST_PP_LIST_FOLD_LEFT_44(o, s, BOOST_PP_LIST_REVERSE_D(44, l))
#define BOOST_PP_LIST_FOLD_RIGHT_45(o, s, l) BOOST_PP_LIST_FOLD_LEFT_45(o, s, BOOST_PP_LIST_REVERSE_D(45, l))
#define BOOST_PP_LIST_FOLD_RIGHT_46(o, s, l) BOOST_PP_LIST_FOLD_LEFT_46(o, s, BOOST_PP_LIST_REVERSE_D(46, l))
#define BOOST_PP_LIST_FOLD_RIGHT_47(o, s, l) BOOST_PP_LIST_FOLD_LEFT_47(o, s, BOOST_PP_LIST_REVERSE_D(47, l))
#define BOOST_PP_LIST_FOLD_RIGHT_48(o, s, l) BOOST_PP_LIST_FOLD_LEFT_48(o, s, BOOST_PP_LIST_REVERSE_D(48, l))
#define BOOST_PP_LIST_FOLD_RIGHT_49(o, s, l) BOOST_PP_LIST_FOLD_LEFT_49(o, s, BOOST_PP_LIST_REVERSE_D(49, l))
#define BOOST_PP_LIST_FOLD_RIGHT_50(o, s, l) BOOST_PP_LIST_FOLD_LEFT_50(o, s, BOOST_PP_LIST_REVERSE_D(50, l))
#define BOOST_PP_LIST_FOLD_RIGHT_51(o, s, l) BOOST_PP_LIST_FOLD_LEFT_51(o, s, BOOST_PP_LIST_REVERSE_D(51, l))
#define BOOST_PP_LIST_FOLD_RIGHT_52(o, s, l) BOOST_PP_LIST_FOLD_LEFT_52(o, s, BOOST_PP_LIST_REVERSE_D(52, l))
#define BOOST_PP_LIST_FOLD_RIGHT_53(o, s, l) BOOST_PP_LIST_FOLD_LEFT_53(o, s, BOOST_PP_LIST_REVERSE_D(53, l))
#define BOOST_PP_LIST_FOLD_RIGHT_54(o, s, l) BOOST_PP_LIST_FOLD_LEFT_54(o, s, BOOST_PP_LIST_REVERSE_D(54, l))
#define BOOST_PP_LIST_FOLD_RIGHT_55(o, s, l) BOOST_PP_LIST_FOLD_LEFT_55(o, s, BOOST_PP_LIST_REVERSE_D(55, l))
#define BOOST_PP_LIST_FOLD_RIGHT_56(o, s, l) BOOST_PP_LIST_FOLD_LEFT_56(o, s, BOOST_PP_LIST_REVERSE_D(56, l))
#define BOOST_PP_LIST_FOLD_RIGHT_57(o, s, l) BOOST_PP_LIST_FOLD_LEFT_57(o, s, BOOST_PP_LIST_REVERSE_D(57, l))
#define BOOST_PP_LIST_FOLD_RIGHT_58(o, s, l) BOOST_PP_LIST_FOLD_LEFT_58(o, s, BOOST_PP_LIST_REVERSE_D(58, l))
#define BOOST_PP_LIST_FOLD_RIGHT_59(o, s, l) BOOST_PP_LIST_FOLD_LEFT_59(o, s, BOOST_PP_LIST_REVERSE_D(59, l))
#define BOOST_PP_LIST_FOLD_RIGHT_60(o, s, l) BOOST_PP_LIST_FOLD_LEFT_60(o, s, BOOST_PP_LIST_REVERSE_D(60, l))
#define BOOST_PP_LIST_FOLD_RIGHT_61(o, s, l) BOOST_PP_LIST_FOLD_LEFT_61(o, s, BOOST_PP_LIST_REVERSE_D(61, l))
#define BOOST_PP_LIST_FOLD_RIGHT_62(o, s, l) BOOST_PP_LIST_FOLD_LEFT_62(o, s, BOOST_PP_LIST_REVERSE_D(62, l))
#define BOOST_PP_LIST_FOLD_RIGHT_63(o, s, l) BOOST_PP_LIST_FOLD_LEFT_63(o, s, BOOST_PP_LIST_REVERSE_D(63, l))
#define BOOST_PP_LIST_FOLD_RIGHT_64(o, s, l) BOOST_PP_LIST_FOLD_LEFT_64(o, s, BOOST_PP_LIST_REVERSE_D(64, l))
#define BOOST_PP_LIST_FOLD_RIGHT_65(o, s, l) BOOST_PP_LIST_FOLD_LEFT_65(o, s, BOOST_PP_LIST_REVERSE_D(65, l))
#define BOOST_PP_LIST_FOLD_RIGHT_66(o, s, l) BOOST_PP_LIST_FOLD_LEFT_66(o, s, BOOST_PP_LIST_REVERSE_D(66, l))
#define BOOST_PP_LIST_FOLD_RIGHT_67(o, s, l) BOOST_PP_LIST_FOLD_LEFT_67(o, s, BOOST_PP_LIST_REVERSE_D(67, l))
#define BOOST_PP_LIST_FOLD_RIGHT_68(o, s, l) BOOST_PP_LIST_FOLD_LEFT_68(o, s, BOOST_PP_LIST_REVERSE_D(68, l))
#define BOOST_PP_LIST_FOLD_RIGHT_69(o, s, l) BOOST_PP_LIST_FOLD_LEFT_69(o, s, BOOST_PP_LIST_REVERSE_D(69, l))
#define BOOST_PP_LIST_FOLD_RIGHT_70(o, s, l) BOOST_PP_LIST_FOLD_LEFT_70(o, s, BOOST_PP_LIST_REVERSE_D(70, l))
#define BOOST_PP_LIST_FOLD_RIGHT_71(o, s, l) BOOST_PP_LIST_FOLD_LEFT_71(o, s, BOOST_PP_LIST_REVERSE_D(71, l))
#define BOOST_PP_LIST_FOLD_RIGHT_72(o, s, l) BOOST_PP_LIST_FOLD_LEFT_72(o, s, BOOST_PP_LIST_REVERSE_D(72, l))
#define BOOST_PP_LIST_FOLD_RIGHT_73(o, s, l) BOOST_PP_LIST_FOLD_LEFT_73(o, s, BOOST_PP_LIST_REVERSE_D(73, l))
#define BOOST_PP_LIST_FOLD_RIGHT_74(o, s, l) BOOST_PP_LIST_FOLD_LEFT_74(o, s, BOOST_PP_LIST_REVERSE_D(74, l))
#define BOOST_PP_LIST_FOLD_RIGHT_75(o, s, l) BOOST_PP_LIST_FOLD_LEFT_75(o, s, BOOST_PP_LIST_REVERSE_D(75, l))
#define BOOST_PP_LIST_FOLD_RIGHT_76(o, s, l) BOOST_PP_LIST_FOLD_LEFT_76(o, s, BOOST_PP_LIST_REVERSE_D(76, l))
#define BOOST_PP_LIST_FOLD_RIGHT_77(o, s, l) BOOST_PP_LIST_FOLD_LEFT_77(o, s, BOOST_PP_LIST_REVERSE_D(77, l))
#define BOOST_PP_LIST_FOLD_RIGHT_78(o, s, l) BOOST_PP_LIST_FOLD_LEFT_78(o, s, BOOST_PP_LIST_REVERSE_D(78, l))
#define BOOST_PP_LIST_FOLD_RIGHT_79(o, s, l) BOOST_PP_LIST_FOLD_LEFT_79(o, s, BOOST_PP_LIST_REVERSE_D(79, l))
#define BOOST_PP_LIST_FOLD_RIGHT_80(o, s, l) BOOST_PP_LIST_FOLD_LEFT_80(o, s, BOOST_PP_LIST_REVERSE_D(80, l))
#define BOOST_PP_LIST_FOLD_RIGHT_81(o, s, l) BOOST_PP_LIST_FOLD_LEFT_81(o, s, BOOST_PP_LIST_REVERSE_D(81, l))
#define BOOST_PP_LIST_FOLD_RIGHT_82(o, s, l) BOOST_PP_LIST_FOLD_LEFT_82(o, s, BOOST_PP_LIST_REVERSE_D(82, l))
#define BOOST_PP_LIST_FOLD_RIGHT_83(o, s, l) BOOST_PP_LIST_FOLD_LEFT_83(o, s, BOOST_PP_LIST_REVERSE_D(83, l))
#define BOOST_PP_LIST_FOLD_RIGHT_84(o, s, l) BOOST_PP_LIST_FOLD_LEFT_84(o, s, BOOST_PP_LIST_REVERSE_D(84, l))
#define BOOST_PP_LIST_FOLD_RIGHT_85(o, s, l) BOOST_PP_LIST_FOLD_LEFT_85(o, s, BOOST_PP_LIST_REVERSE_D(85, l))
#define BOOST_PP_LIST_FOLD_RIGHT_86(o, s, l) BOOST_PP_LIST_FOLD_LEFT_86(o, s, BOOST_PP_LIST_REVERSE_D(86, l))
#define BOOST_PP_LIST_FOLD_RIGHT_87(o, s, l) BOOST_PP_LIST_FOLD_LEFT_87(o, s, BOOST_PP_LIST_REVERSE_D(87, l))
#define BOOST_PP_LIST_FOLD_RIGHT_88(o, s, l) BOOST_PP_LIST_FOLD_LEFT_88(o, s, BOOST_PP_LIST_REVERSE_D(88, l))
#define BOOST_PP_LIST_FOLD_RIGHT_89(o, s, l) BOOST_PP_LIST_FOLD_LEFT_89(o, s, BOOST_PP_LIST_REVERSE_D(89, l))
#define BOOST_PP_LIST_FOLD_RIGHT_90(o, s, l) BOOST_PP_LIST_FOLD_LEFT_90(o, s, BOOST_PP_LIST_REVERSE_D(90, l))
#define BOOST_PP_LIST_FOLD_RIGHT_91(o, s, l) BOOST_PP_LIST_FOLD_LEFT_91(o, s, BOOST_PP_LIST_REVERSE_D(91, l))
#define BOOST_PP_LIST_FOLD_RIGHT_92(o, s, l) BOOST_PP_LIST_FOLD_LEFT_92(o, s, BOOST_PP_LIST_REVERSE_D(92, l))
#define BOOST_PP_LIST_FOLD_RIGHT_93(o, s, l) BOOST_PP_LIST_FOLD_LEFT_93(o, s, BOOST_PP_LIST_REVERSE_D(93, l))
#define BOOST_PP_LIST_FOLD_RIGHT_94(o, s, l) BOOST_PP_LIST_FOLD_LEFT_94(o, s, BOOST_PP_LIST_REVERSE_D(94, l))
#define BOOST_PP_LIST_FOLD_RIGHT_95(o, s, l) BOOST_PP_LIST_FOLD_LEFT_95(o, s, BOOST_PP_LIST_REVERSE_D(95, l))
#define BOOST_PP_LIST_FOLD_RIGHT_96(o, s, l) BOOST_PP_LIST_FOLD_LEFT_96(o, s, BOOST_PP_LIST_REVERSE_D(96, l))
#define BOOST_PP_LIST_FOLD_RIGHT_97(o, s, l) BOOST_PP_LIST_FOLD_LEFT_97(o, s, BOOST_PP_LIST_REVERSE_D(97, l))
#define BOOST_PP_LIST_FOLD_RIGHT_98(o, s, l) BOOST_PP_LIST_FOLD_LEFT_98(o, s, BOOST_PP_LIST_REVERSE_D(98, l))
#define BOOST_PP_LIST_FOLD_RIGHT_99(o, s, l) BOOST_PP_LIST_FOLD_LEFT_99(o, s, BOOST_PP_LIST_REVERSE_D(99, l))
#define BOOST_PP_LIST_FOLD_RIGHT_100(o, s, l) BOOST_PP_LIST_FOLD_LEFT_100(o, s, BOOST_PP_LIST_REVERSE_D(100, l))
#define BOOST_PP_LIST_FOLD_RIGHT_101(o, s, l) BOOST_PP_LIST_FOLD_LEFT_101(o, s, BOOST_PP_LIST_REVERSE_D(101, l))
#define BOOST_PP_LIST_FOLD_RIGHT_102(o, s, l) BOOST_PP_LIST_FOLD_LEFT_102(o, s, BOOST_PP_LIST_REVERSE_D(102, l))
#define BOOST_PP_LIST_FOLD_RIGHT_103(o, s, l) BOOST_PP_LIST_FOLD_LEFT_103(o, s, BOOST_PP_LIST_REVERSE_D(103, l))
#define BOOST_PP_LIST_FOLD_RIGHT_104(o, s, l) BOOST_PP_LIST_FOLD_LEFT_104(o, s, BOOST_PP_LIST_REVERSE_D(104, l))
#define BOOST_PP_LIST_FOLD_RIGHT_105(o, s, l) BOOST_PP_LIST_FOLD_LEFT_105(o, s, BOOST_PP_LIST_REVERSE_D(105, l))
#define BOOST_PP_LIST_FOLD_RIGHT_106(o, s, l) BOOST_PP_LIST_FOLD_LEFT_106(o, s, BOOST_PP_LIST_REVERSE_D(106, l))
#define BOOST_PP_LIST_FOLD_RIGHT_107(o, s, l) BOOST_PP_LIST_FOLD_LEFT_107(o, s, BOOST_PP_LIST_REVERSE_D(107, l))
#define BOOST_PP_LIST_FOLD_RIGHT_108(o, s, l) BOOST_PP_LIST_FOLD_LEFT_108(o, s, BOOST_PP_LIST_REVERSE_D(108, l))
#define BOOST_PP_LIST_FOLD_RIGHT_109(o, s, l) BOOST_PP_LIST_FOLD_LEFT_109(o, s, BOOST_PP_LIST_REVERSE_D(109, l))
#define BOOST_PP_LIST_FOLD_RIGHT_110(o, s, l) BOOST_PP_LIST_FOLD_LEFT_110(o, s, BOOST_PP_LIST_REVERSE_D(110, l))
#define BOOST_PP_LIST_FOLD_RIGHT_111(o, s, l) BOOST_PP_LIST_FOLD_LEFT_111(o, s, BOOST_PP_LIST_REVERSE_D(111, l))
#define BOOST_PP_LIST_FOLD_RIGHT_112(o, s, l) BOOST_PP_LIST_FOLD_LEFT_112(o, s, BOOST_PP_LIST_REVERSE_D(112, l))
#define BOOST_PP_LIST_FOLD_RIGHT_113(o, s, l) BOOST_PP_LIST_FOLD_LEFT_113(o, s, BOOST_PP_LIST_REVERSE_D(113, l))
#define BOOST_PP_LIST_FOLD_RIGHT_114(o, s, l) BOOST_PP_LIST_FOLD_LEFT_114(o, s, BOOST_PP_LIST_REVERSE_D(114, l))
#define BOOST_PP_LIST_FOLD_RIGHT_115(o, s, l) BOOST_PP_LIST_FOLD_LEFT_115(o, s, BOOST_PP_LIST_REVERSE_D(115, l))
#define BOOST_PP_LIST_FOLD_RIGHT_116(o, s, l) BOOST_PP_LIST_FOLD_LEFT_116(o, s, BOOST_PP_LIST_REVERSE_D(116, l))
#define BOOST_PP_LIST_FOLD_RIGHT_117(o, s, l) BOOST_PP_LIST_FOLD_LEFT_117(o, s, BOOST_PP_LIST_REVERSE_D(117, l))
#define BOOST_PP_LIST_FOLD_RIGHT_118(o, s, l) BOOST_PP_LIST_FOLD_LEFT_118(o, s, BOOST_PP_LIST_REVERSE_D(118, l))
#define BOOST_PP_LIST_FOLD_RIGHT_119(o, s, l) BOOST_PP_LIST_FOLD_LEFT_119(o, s, BOOST_PP_LIST_REVERSE_D(119, l))
#define BOOST_PP_LIST_FOLD_RIGHT_120(o, s, l) BOOST_PP_LIST_FOLD_LEFT_120(o, s, BOOST_PP_LIST_REVERSE_D(120, l))
#define BOOST_PP_LIST_FOLD_RIGHT_121(o, s, l) BOOST_PP_LIST_FOLD_LEFT_121(o, s, BOOST_PP_LIST_REVERSE_D(121, l))
#define BOOST_PP_LIST_FOLD_RIGHT_122(o, s, l) BOOST_PP_LIST_FOLD_LEFT_122(o, s, BOOST_PP_LIST_REVERSE_D(122, l))
#define BOOST_PP_LIST_FOLD_RIGHT_123(o, s, l) BOOST_PP_LIST_FOLD_LEFT_123(o, s, BOOST_PP_LIST_REVERSE_D(123, l))
#define BOOST_PP_LIST_FOLD_RIGHT_124(o, s, l) BOOST_PP_LIST_FOLD_LEFT_124(o, s, BOOST_PP_LIST_REVERSE_D(124, l))
#define BOOST_PP_LIST_FOLD_RIGHT_125(o, s, l) BOOST_PP_LIST_FOLD_LEFT_125(o, s, BOOST_PP_LIST_REVERSE_D(125, l))
#define BOOST_PP_LIST_FOLD_RIGHT_126(o, s, l) BOOST_PP_LIST_FOLD_LEFT_126(o, s, BOOST_PP_LIST_REVERSE_D(126, l))
#define BOOST_PP_LIST_FOLD_RIGHT_127(o, s, l) BOOST_PP_LIST_FOLD_LEFT_127(o, s, BOOST_PP_LIST_REVERSE_D(127, l))
#define BOOST_PP_LIST_FOLD_RIGHT_128(o, s, l) BOOST_PP_LIST_FOLD_LEFT_128(o, s, BOOST_PP_LIST_REVERSE_D(128, l))
#define BOOST_PP_LIST_FOLD_RIGHT_129(o, s, l) BOOST_PP_LIST_FOLD_LEFT_129(o, s, BOOST_PP_LIST_REVERSE_D(129, l))
#define BOOST_PP_LIST_FOLD_RIGHT_130(o, s, l) BOOST_PP_LIST_FOLD_LEFT_130(o, s, BOOST_PP_LIST_REVERSE_D(130, l))
#define BOOST_PP_LIST_FOLD_RIGHT_131(o, s, l) BOOST_PP_LIST_FOLD_LEFT_131(o, s, BOOST_PP_LIST_REVERSE_D(131, l))
#define BOOST_PP_LIST_FOLD_RIGHT_132(o, s, l) BOOST_PP_LIST_FOLD_LEFT_132(o, s, BOOST_PP_LIST_REVERSE_D(132, l))
#define BOOST_PP_LIST_FOLD_RIGHT_133(o, s, l) BOOST_PP_LIST_FOLD_LEFT_133(o, s, BOOST_PP_LIST_REVERSE_D(133, l))
#define BOOST_PP_LIST_FOLD_RIGHT_134(o, s, l) BOOST_PP_LIST_FOLD_LEFT_134(o, s, BOOST_PP_LIST_REVERSE_D(134, l))
#define BOOST_PP_LIST_FOLD_RIGHT_135(o, s, l) BOOST_PP_LIST_FOLD_LEFT_135(o, s, BOOST_PP_LIST_REVERSE_D(135, l))
#define BOOST_PP_LIST_FOLD_RIGHT_136(o, s, l) BOOST_PP_LIST_FOLD_LEFT_136(o, s, BOOST_PP_LIST_REVERSE_D(136, l))
#define BOOST_PP_LIST_FOLD_RIGHT_137(o, s, l) BOOST_PP_LIST_FOLD_LEFT_137(o, s, BOOST_PP_LIST_REVERSE_D(137, l))
#define BOOST_PP_LIST_FOLD_RIGHT_138(o, s, l) BOOST_PP_LIST_FOLD_LEFT_138(o, s, BOOST_PP_LIST_REVERSE_D(138, l))
#define BOOST_PP_LIST_FOLD_RIGHT_139(o, s, l) BOOST_PP_LIST_FOLD_LEFT_139(o, s, BOOST_PP_LIST_REVERSE_D(139, l))
#define BOOST_PP_LIST_FOLD_RIGHT_140(o, s, l) BOOST_PP_LIST_FOLD_LEFT_140(o, s, BOOST_PP_LIST_REVERSE_D(140, l))
#define BOOST_PP_LIST_FOLD_RIGHT_141(o, s, l) BOOST_PP_LIST_FOLD_LEFT_141(o, s, BOOST_PP_LIST_REVERSE_D(141, l))
#define BOOST_PP_LIST_FOLD_RIGHT_142(o, s, l) BOOST_PP_LIST_FOLD_LEFT_142(o, s, BOOST_PP_LIST_REVERSE_D(142, l))
#define BOOST_PP_LIST_FOLD_RIGHT_143(o, s, l) BOOST_PP_LIST_FOLD_LEFT_143(o, s, BOOST_PP_LIST_REVERSE_D(143, l))
#define BOOST_PP_LIST_FOLD_RIGHT_144(o, s, l) BOOST_PP_LIST_FOLD_LEFT_144(o, s, BOOST_PP_LIST_REVERSE_D(144, l))
#define BOOST_PP_LIST_FOLD_RIGHT_145(o, s, l) BOOST_PP_LIST_FOLD_LEFT_145(o, s, BOOST_PP_LIST_REVERSE_D(145, l))
#define BOOST_PP_LIST_FOLD_RIGHT_146(o, s, l) BOOST_PP_LIST_FOLD_LEFT_146(o, s, BOOST_PP_LIST_REVERSE_D(146, l))
#define BOOST_PP_LIST_FOLD_RIGHT_147(o, s, l) BOOST_PP_LIST_FOLD_LEFT_147(o, s, BOOST_PP_LIST_REVERSE_D(147, l))
#define BOOST_PP_LIST_FOLD_RIGHT_148(o, s, l) BOOST_PP_LIST_FOLD_LEFT_148(o, s, BOOST_PP_LIST_REVERSE_D(148, l))
#define BOOST_PP_LIST_FOLD_RIGHT_149(o, s, l) BOOST_PP_LIST_FOLD_LEFT_149(o, s, BOOST_PP_LIST_REVERSE_D(149, l))
#define BOOST_PP_LIST_FOLD_RIGHT_150(o, s, l) BOOST_PP_LIST_FOLD_LEFT_150(o, s, BOOST_PP_LIST_REVERSE_D(150, l))
#define BOOST_PP_LIST_FOLD_RIGHT_151(o, s, l) BOOST_PP_LIST_FOLD_LEFT_151(o, s, BOOST_PP_LIST_REVERSE_D(151, l))
#define BOOST_PP_LIST_FOLD_RIGHT_152(o, s, l) BOOST_PP_LIST_FOLD_LEFT_152(o, s, BOOST_PP_LIST_REVERSE_D(152, l))
#define BOOST_PP_LIST_FOLD_RIGHT_153(o, s, l) BOOST_PP_LIST_FOLD_LEFT_153(o, s, BOOST_PP_LIST_REVERSE_D(153, l))
#define BOOST_PP_LIST_FOLD_RIGHT_154(o, s, l) BOOST_PP_LIST_FOLD_LEFT_154(o, s, BOOST_PP_LIST_REVERSE_D(154, l))
#define BOOST_PP_LIST_FOLD_RIGHT_155(o, s, l) BOOST_PP_LIST_FOLD_LEFT_155(o, s, BOOST_PP_LIST_REVERSE_D(155, l))
#define BOOST_PP_LIST_FOLD_RIGHT_156(o, s, l) BOOST_PP_LIST_FOLD_LEFT_156(o, s, BOOST_PP_LIST_REVERSE_D(156, l))
#define BOOST_PP_LIST_FOLD_RIGHT_157(o, s, l) BOOST_PP_LIST_FOLD_LEFT_157(o, s, BOOST_PP_LIST_REVERSE_D(157, l))
#define BOOST_PP_LIST_FOLD_RIGHT_158(o, s, l) BOOST_PP_LIST_FOLD_LEFT_158(o, s, BOOST_PP_LIST_REVERSE_D(158, l))
#define BOOST_PP_LIST_FOLD_RIGHT_159(o, s, l) BOOST_PP_LIST_FOLD_LEFT_159(o, s, BOOST_PP_LIST_REVERSE_D(159, l))
#define BOOST_PP_LIST_FOLD_RIGHT_160(o, s, l) BOOST_PP_LIST_FOLD_LEFT_160(o, s, BOOST_PP_LIST_REVERSE_D(160, l))
#define BOOST_PP_LIST_FOLD_RIGHT_161(o, s, l) BOOST_PP_LIST_FOLD_LEFT_161(o, s, BOOST_PP_LIST_REVERSE_D(161, l))
#define BOOST_PP_LIST_FOLD_RIGHT_162(o, s, l) BOOST_PP_LIST_FOLD_LEFT_162(o, s, BOOST_PP_LIST_REVERSE_D(162, l))
#define BOOST_PP_LIST_FOLD_RIGHT_163(o, s, l) BOOST_PP_LIST_FOLD_LEFT_163(o, s, BOOST_PP_LIST_REVERSE_D(163, l))
#define BOOST_PP_LIST_FOLD_RIGHT_164(o, s, l) BOOST_PP_LIST_FOLD_LEFT_164(o, s, BOOST_PP_LIST_REVERSE_D(164, l))
#define BOOST_PP_LIST_FOLD_RIGHT_165(o, s, l) BOOST_PP_LIST_FOLD_LEFT_165(o, s, BOOST_PP_LIST_REVERSE_D(165, l))
#define BOOST_PP_LIST_FOLD_RIGHT_166(o, s, l) BOOST_PP_LIST_FOLD_LEFT_166(o, s, BOOST_PP_LIST_REVERSE_D(166, l))
#define BOOST_PP_LIST_FOLD_RIGHT_167(o, s, l) BOOST_PP_LIST_FOLD_LEFT_167(o, s, BOOST_PP_LIST_REVERSE_D(167, l))
#define BOOST_PP_LIST_FOLD_RIGHT_168(o, s, l) BOOST_PP_LIST_FOLD_LEFT_168(o, s, BOOST_PP_LIST_REVERSE_D(168, l))
#define BOOST_PP_LIST_FOLD_RIGHT_169(o, s, l) BOOST_PP_LIST_FOLD_LEFT_169(o, s, BOOST_PP_LIST_REVERSE_D(169, l))
#define BOOST_PP_LIST_FOLD_RIGHT_170(o, s, l) BOOST_PP_LIST_FOLD_LEFT_170(o, s, BOOST_PP_LIST_REVERSE_D(170, l))
#define BOOST_PP_LIST_FOLD_RIGHT_171(o, s, l) BOOST_PP_LIST_FOLD_LEFT_171(o, s, BOOST_PP_LIST_REVERSE_D(171, l))
#define BOOST_PP_LIST_FOLD_RIGHT_172(o, s, l) BOOST_PP_LIST_FOLD_LEFT_172(o, s, BOOST_PP_LIST_REVERSE_D(172, l))
#define BOOST_PP_LIST_FOLD_RIGHT_173(o, s, l) BOOST_PP_LIST_FOLD_LEFT_173(o, s, BOOST_PP_LIST_REVERSE_D(173, l))
#define BOOST_PP_LIST_FOLD_RIGHT_174(o, s, l) BOOST_PP_LIST_FOLD_LEFT_174(o, s, BOOST_PP_LIST_REVERSE_D(174, l))
#define BOOST_PP_LIST_FOLD_RIGHT_175(o, s, l) BOOST_PP_LIST_FOLD_LEFT_175(o, s, BOOST_PP_LIST_REVERSE_D(175, l))
#define BOOST_PP_LIST_FOLD_RIGHT_176(o, s, l) BOOST_PP_LIST_FOLD_LEFT_176(o, s, BOOST_PP_LIST_REVERSE_D(176, l))
#define BOOST_PP_LIST_FOLD_RIGHT_177(o, s, l) BOOST_PP_LIST_FOLD_LEFT_177(o, s, BOOST_PP_LIST_REVERSE_D(177, l))
#define BOOST_PP_LIST_FOLD_RIGHT_178(o, s, l) BOOST_PP_LIST_FOLD_LEFT_178(o, s, BOOST_PP_LIST_REVERSE_D(178, l))
#define BOOST_PP_LIST_FOLD_RIGHT_179(o, s, l) BOOST_PP_LIST_FOLD_LEFT_179(o, s, BOOST_PP_LIST_REVERSE_D(179, l))
#define BOOST_PP_LIST_FOLD_RIGHT_180(o, s, l) BOOST_PP_LIST_FOLD_LEFT_180(o, s, BOOST_PP_LIST_REVERSE_D(180, l))
#define BOOST_PP_LIST_FOLD_RIGHT_181(o, s, l) BOOST_PP_LIST_FOLD_LEFT_181(o, s, BOOST_PP_LIST_REVERSE_D(181, l))
#define BOOST_PP_LIST_FOLD_RIGHT_182(o, s, l) BOOST_PP_LIST_FOLD_LEFT_182(o, s, BOOST_PP_LIST_REVERSE_D(182, l))
#define BOOST_PP_LIST_FOLD_RIGHT_183(o, s, l) BOOST_PP_LIST_FOLD_LEFT_183(o, s, BOOST_PP_LIST_REVERSE_D(183, l))
#define BOOST_PP_LIST_FOLD_RIGHT_184(o, s, l) BOOST_PP_LIST_FOLD_LEFT_184(o, s, BOOST_PP_LIST_REVERSE_D(184, l))
#define BOOST_PP_LIST_FOLD_RIGHT_185(o, s, l) BOOST_PP_LIST_FOLD_LEFT_185(o, s, BOOST_PP_LIST_REVERSE_D(185, l))
#define BOOST_PP_LIST_FOLD_RIGHT_186(o, s, l) BOOST_PP_LIST_FOLD_LEFT_186(o, s, BOOST_PP_LIST_REVERSE_D(186, l))
#define BOOST_PP_LIST_FOLD_RIGHT_187(o, s, l) BOOST_PP_LIST_FOLD_LEFT_187(o, s, BOOST_PP_LIST_REVERSE_D(187, l))
#define BOOST_PP_LIST_FOLD_RIGHT_188(o, s, l) BOOST_PP_LIST_FOLD_LEFT_188(o, s, BOOST_PP_LIST_REVERSE_D(188, l))
#define BOOST_PP_LIST_FOLD_RIGHT_189(o, s, l) BOOST_PP_LIST_FOLD_LEFT_189(o, s, BOOST_PP_LIST_REVERSE_D(189, l))
#define BOOST_PP_LIST_FOLD_RIGHT_190(o, s, l) BOOST_PP_LIST_FOLD_LEFT_190(o, s, BOOST_PP_LIST_REVERSE_D(190, l))
#define BOOST_PP_LIST_FOLD_RIGHT_191(o, s, l) BOOST_PP_LIST_FOLD_LEFT_191(o, s, BOOST_PP_LIST_REVERSE_D(191, l))
#define BOOST_PP_LIST_FOLD_RIGHT_192(o, s, l) BOOST_PP_LIST_FOLD_LEFT_192(o, s, BOOST_PP_LIST_REVERSE_D(192, l))
#define BOOST_PP_LIST_FOLD_RIGHT_193(o, s, l) BOOST_PP_LIST_FOLD_LEFT_193(o, s, BOOST_PP_LIST_REVERSE_D(193, l))
#define BOOST_PP_LIST_FOLD_RIGHT_194(o, s, l) BOOST_PP_LIST_FOLD_LEFT_194(o, s, BOOST_PP_LIST_REVERSE_D(194, l))
#define BOOST_PP_LIST_FOLD_RIGHT_195(o, s, l) BOOST_PP_LIST_FOLD_LEFT_195(o, s, BOOST_PP_LIST_REVERSE_D(195, l))
#define BOOST_PP_LIST_FOLD_RIGHT_196(o, s, l) BOOST_PP_LIST_FOLD_LEFT_196(o, s, BOOST_PP_LIST_REVERSE_D(196, l))
#define BOOST_PP_LIST_FOLD_RIGHT_197(o, s, l) BOOST_PP_LIST_FOLD_LEFT_197(o, s, BOOST_PP_LIST_REVERSE_D(197, l))
#define BOOST_PP_LIST_FOLD_RIGHT_198(o, s, l) BOOST_PP_LIST_FOLD_LEFT_198(o, s, BOOST_PP_LIST_REVERSE_D(198, l))
#define BOOST_PP_LIST_FOLD_RIGHT_199(o, s, l) BOOST_PP_LIST_FOLD_LEFT_199(o, s, BOOST_PP_LIST_REVERSE_D(199, l))
#define BOOST_PP_LIST_FOLD_RIGHT_200(o, s, l) BOOST_PP_LIST_FOLD_LEFT_200(o, s, BOOST_PP_LIST_REVERSE_D(200, l))
#define BOOST_PP_LIST_FOLD_RIGHT_201(o, s, l) BOOST_PP_LIST_FOLD_LEFT_201(o, s, BOOST_PP_LIST_REVERSE_D(201, l))
#define BOOST_PP_LIST_FOLD_RIGHT_202(o, s, l) BOOST_PP_LIST_FOLD_LEFT_202(o, s, BOOST_PP_LIST_REVERSE_D(202, l))
#define BOOST_PP_LIST_FOLD_RIGHT_203(o, s, l) BOOST_PP_LIST_FOLD_LEFT_203(o, s, BOOST_PP_LIST_REVERSE_D(203, l))
#define BOOST_PP_LIST_FOLD_RIGHT_204(o, s, l) BOOST_PP_LIST_FOLD_LEFT_204(o, s, BOOST_PP_LIST_REVERSE_D(204, l))
#define BOOST_PP_LIST_FOLD_RIGHT_205(o, s, l) BOOST_PP_LIST_FOLD_LEFT_205(o, s, BOOST_PP_LIST_REVERSE_D(205, l))
#define BOOST_PP_LIST_FOLD_RIGHT_206(o, s, l) BOOST_PP_LIST_FOLD_LEFT_206(o, s, BOOST_PP_LIST_REVERSE_D(206, l))
#define BOOST_PP_LIST_FOLD_RIGHT_207(o, s, l) BOOST_PP_LIST_FOLD_LEFT_207(o, s, BOOST_PP_LIST_REVERSE_D(207, l))
#define BOOST_PP_LIST_FOLD_RIGHT_208(o, s, l) BOOST_PP_LIST_FOLD_LEFT_208(o, s, BOOST_PP_LIST_REVERSE_D(208, l))
#define BOOST_PP_LIST_FOLD_RIGHT_209(o, s, l) BOOST_PP_LIST_FOLD_LEFT_209(o, s, BOOST_PP_LIST_REVERSE_D(209, l))
#define BOOST_PP_LIST_FOLD_RIGHT_210(o, s, l) BOOST_PP_LIST_FOLD_LEFT_210(o, s, BOOST_PP_LIST_REVERSE_D(210, l))
#define BOOST_PP_LIST_FOLD_RIGHT_211(o, s, l) BOOST_PP_LIST_FOLD_LEFT_211(o, s, BOOST_PP_LIST_REVERSE_D(211, l))
#define BOOST_PP_LIST_FOLD_RIGHT_212(o, s, l) BOOST_PP_LIST_FOLD_LEFT_212(o, s, BOOST_PP_LIST_REVERSE_D(212, l))
#define BOOST_PP_LIST_FOLD_RIGHT_213(o, s, l) BOOST_PP_LIST_FOLD_LEFT_213(o, s, BOOST_PP_LIST_REVERSE_D(213, l))
#define BOOST_PP_LIST_FOLD_RIGHT_214(o, s, l) BOOST_PP_LIST_FOLD_LEFT_214(o, s, BOOST_PP_LIST_REVERSE_D(214, l))
#define BOOST_PP_LIST_FOLD_RIGHT_215(o, s, l) BOOST_PP_LIST_FOLD_LEFT_215(o, s, BOOST_PP_LIST_REVERSE_D(215, l))
#define BOOST_PP_LIST_FOLD_RIGHT_216(o, s, l) BOOST_PP_LIST_FOLD_LEFT_216(o, s, BOOST_PP_LIST_REVERSE_D(216, l))
#define BOOST_PP_LIST_FOLD_RIGHT_217(o, s, l) BOOST_PP_LIST_FOLD_LEFT_217(o, s, BOOST_PP_LIST_REVERSE_D(217, l))
#define BOOST_PP_LIST_FOLD_RIGHT_218(o, s, l) BOOST_PP_LIST_FOLD_LEFT_218(o, s, BOOST_PP_LIST_REVERSE_D(218, l))
#define BOOST_PP_LIST_FOLD_RIGHT_219(o, s, l) BOOST_PP_LIST_FOLD_LEFT_219(o, s, BOOST_PP_LIST_REVERSE_D(219, l))
#define BOOST_PP_LIST_FOLD_RIGHT_220(o, s, l) BOOST_PP_LIST_FOLD_LEFT_220(o, s, BOOST_PP_LIST_REVERSE_D(220, l))
#define BOOST_PP_LIST_FOLD_RIGHT_221(o, s, l) BOOST_PP_LIST_FOLD_LEFT_221(o, s, BOOST_PP_LIST_REVERSE_D(221, l))
#define BOOST_PP_LIST_FOLD_RIGHT_222(o, s, l) BOOST_PP_LIST_FOLD_LEFT_222(o, s, BOOST_PP_LIST_REVERSE_D(222, l))
#define BOOST_PP_LIST_FOLD_RIGHT_223(o, s, l) BOOST_PP_LIST_FOLD_LEFT_223(o, s, BOOST_PP_LIST_REVERSE_D(223, l))
#define BOOST_PP_LIST_FOLD_RIGHT_224(o, s, l) BOOST_PP_LIST_FOLD_LEFT_224(o, s, BOOST_PP_LIST_REVERSE_D(224, l))
#define BOOST_PP_LIST_FOLD_RIGHT_225(o, s, l) BOOST_PP_LIST_FOLD_LEFT_225(o, s, BOOST_PP_LIST_REVERSE_D(225, l))
#define BOOST_PP_LIST_FOLD_RIGHT_226(o, s, l) BOOST_PP_LIST_FOLD_LEFT_226(o, s, BOOST_PP_LIST_REVERSE_D(226, l))
#define BOOST_PP_LIST_FOLD_RIGHT_227(o, s, l) BOOST_PP_LIST_FOLD_LEFT_227(o, s, BOOST_PP_LIST_REVERSE_D(227, l))
#define BOOST_PP_LIST_FOLD_RIGHT_228(o, s, l) BOOST_PP_LIST_FOLD_LEFT_228(o, s, BOOST_PP_LIST_REVERSE_D(228, l))
#define BOOST_PP_LIST_FOLD_RIGHT_229(o, s, l) BOOST_PP_LIST_FOLD_LEFT_229(o, s, BOOST_PP_LIST_REVERSE_D(229, l))
#define BOOST_PP_LIST_FOLD_RIGHT_230(o, s, l) BOOST_PP_LIST_FOLD_LEFT_230(o, s, BOOST_PP_LIST_REVERSE_D(230, l))
#define BOOST_PP_LIST_FOLD_RIGHT_231(o, s, l) BOOST_PP_LIST_FOLD_LEFT_231(o, s, BOOST_PP_LIST_REVERSE_D(231, l))
#define BOOST_PP_LIST_FOLD_RIGHT_232(o, s, l) BOOST_PP_LIST_FOLD_LEFT_232(o, s, BOOST_PP_LIST_REVERSE_D(232, l))
#define BOOST_PP_LIST_FOLD_RIGHT_233(o, s, l) BOOST_PP_LIST_FOLD_LEFT_233(o, s, BOOST_PP_LIST_REVERSE_D(233, l))
#define BOOST_PP_LIST_FOLD_RIGHT_234(o, s, l) BOOST_PP_LIST_FOLD_LEFT_234(o, s, BOOST_PP_LIST_REVERSE_D(234, l))
#define BOOST_PP_LIST_FOLD_RIGHT_235(o, s, l) BOOST_PP_LIST_FOLD_LEFT_235(o, s, BOOST_PP_LIST_REVERSE_D(235, l))
#define BOOST_PP_LIST_FOLD_RIGHT_236(o, s, l) BOOST_PP_LIST_FOLD_LEFT_236(o, s, BOOST_PP_LIST_REVERSE_D(236, l))
#define BOOST_PP_LIST_FOLD_RIGHT_237(o, s, l) BOOST_PP_LIST_FOLD_LEFT_237(o, s, BOOST_PP_LIST_REVERSE_D(237, l))
#define BOOST_PP_LIST_FOLD_RIGHT_238(o, s, l) BOOST_PP_LIST_FOLD_LEFT_238(o, s, BOOST_PP_LIST_REVERSE_D(238, l))
#define BOOST_PP_LIST_FOLD_RIGHT_239(o, s, l) BOOST_PP_LIST_FOLD_LEFT_239(o, s, BOOST_PP_LIST_REVERSE_D(239, l))
#define BOOST_PP_LIST_FOLD_RIGHT_240(o, s, l) BOOST_PP_LIST_FOLD_LEFT_240(o, s, BOOST_PP_LIST_REVERSE_D(240, l))
#define BOOST_PP_LIST_FOLD_RIGHT_241(o, s, l) BOOST_PP_LIST_FOLD_LEFT_241(o, s, BOOST_PP_LIST_REVERSE_D(241, l))
#define BOOST_PP_LIST_FOLD_RIGHT_242(o, s, l) BOOST_PP_LIST_FOLD_LEFT_242(o, s, BOOST_PP_LIST_REVERSE_D(242, l))
#define BOOST_PP_LIST_FOLD_RIGHT_243(o, s, l) BOOST_PP_LIST_FOLD_LEFT_243(o, s, BOOST_PP_LIST_REVERSE_D(243, l))
#define BOOST_PP_LIST_FOLD_RIGHT_244(o, s, l) BOOST_PP_LIST_FOLD_LEFT_244(o, s, BOOST_PP_LIST_REVERSE_D(244, l))
#define BOOST_PP_LIST_FOLD_RIGHT_245(o, s, l) BOOST_PP_LIST_FOLD_LEFT_245(o, s, BOOST_PP_LIST_REVERSE_D(245, l))
#define BOOST_PP_LIST_FOLD_RIGHT_246(o, s, l) BOOST_PP_LIST_FOLD_LEFT_246(o, s, BOOST_PP_LIST_REVERSE_D(246, l))
#define BOOST_PP_LIST_FOLD_RIGHT_247(o, s, l) BOOST_PP_LIST_FOLD_LEFT_247(o, s, BOOST_PP_LIST_REVERSE_D(247, l))
#define BOOST_PP_LIST_FOLD_RIGHT_248(o, s, l) BOOST_PP_LIST_FOLD_LEFT_248(o, s, BOOST_PP_LIST_REVERSE_D(248, l))
#define BOOST_PP_LIST_FOLD_RIGHT_249(o, s, l) BOOST_PP_LIST_FOLD_LEFT_249(o, s, BOOST_PP_LIST_REVERSE_D(249, l))
#define BOOST_PP_LIST_FOLD_RIGHT_250(o, s, l) BOOST_PP_LIST_FOLD_LEFT_250(o, s, BOOST_PP_LIST_REVERSE_D(250, l))
#define BOOST_PP_LIST_FOLD_RIGHT_251(o, s, l) BOOST_PP_LIST_FOLD_LEFT_251(o, s, BOOST_PP_LIST_REVERSE_D(251, l))
#define BOOST_PP_LIST_FOLD_RIGHT_252(o, s, l) BOOST_PP_LIST_FOLD_LEFT_252(o, s, BOOST_PP_LIST_REVERSE_D(252, l))
#define BOOST_PP_LIST_FOLD_RIGHT_253(o, s, l) BOOST_PP_LIST_FOLD_LEFT_253(o, s, BOOST_PP_LIST_REVERSE_D(253, l))
#define BOOST_PP_LIST_FOLD_RIGHT_254(o, s, l) BOOST_PP_LIST_FOLD_LEFT_254(o, s, BOOST_PP_LIST_REVERSE_D(254, l))
#define BOOST_PP_LIST_FOLD_RIGHT_255(o, s, l) BOOST_PP_LIST_FOLD_LEFT_255(o, s, BOOST_PP_LIST_REVERSE_D(255, l))
#define BOOST_PP_LIST_FOLD_RIGHT_256(o, s, l) BOOST_PP_LIST_FOLD_LEFT_256(o, s, BOOST_PP_LIST_REVERSE_D(256, l))
#define BOOST_PP_LIST_FOLD_RIGHT_CHECK_BOOST_PP_NIL 1

#define BOOST_PP_LIST_FOR_EACH(macro, data, list) BOOST_PP_LIST_FOR_EACH_I(BOOST_PP_LIST_FOR_EACH_O, (macro, data), list)
#define BOOST_PP_LIST_FOR_EACH_I(macro, data, list) BOOST_PP_FOR((macro, data, list, 0), BOOST_PP_LIST_FOR_EACH_I_P, BOOST_PP_LIST_FOR_EACH_I_O, BOOST_PP_LIST_FOR_EACH_I_M)
#define BOOST_PP_LIST_FOR_EACH_I_P(r, x) BOOST_PP_LIST_FOR_EACH_I_P_D x
#define BOOST_PP_LIST_FOR_EACH_I_P_D(m, d, l, i) BOOST_PP_LIST_IS_CONS(l)
#define BOOST_PP_LIST_FOR_EACH_I_O(r, x) BOOST_PP_LIST_FOR_EACH_I_O_D x
#define BOOST_PP_LIST_FOR_EACH_I_O_D(m, d, l, i) (m, d, BOOST_PP_LIST_REST(l), BOOST_PP_INC(i))
#define BOOST_PP_LIST_FOR_EACH_I_M(r, x) BOOST_PP_LIST_FOR_EACH_I_M_D(r, BOOST_PP_TUPLE_ELEM(4, 0, x), BOOST_PP_TUPLE_ELEM(4, 1, x), BOOST_PP_TUPLE_ELEM(4, 2, x), BOOST_PP_TUPLE_ELEM(4, 3, x))
#define BOOST_PP_LIST_FOR_EACH_I_M_D(r, m, d, l, i) m(r, d, i, BOOST_PP_LIST_FIRST(l))
#define BOOST_PP_LIST_FOR_EACH_I_R(r, macro, data, list) BOOST_PP_FOR_ ## r((macro, data, list, 0), BOOST_PP_LIST_FOR_EACH_I_P, BOOST_PP_LIST_FOR_EACH_I_O, BOOST_PP_LIST_FOR_EACH_I_M)
#define BOOST_PP_LIST_FOR_EACH_O(r, md, i, elem) BOOST_PP_LIST_FOR_EACH_O_D(r, BOOST_PP_TUPLE_ELEM(2, 0, md), BOOST_PP_TUPLE_ELEM(2, 1, md), elem)
#define BOOST_PP_LIST_FOR_EACH_O_D(r, m, d, elem) m(r, d, elem)
#define BOOST_PP_LIST_FOR_EACH_R(r, macro, data, list) BOOST_PP_LIST_FOR_EACH_I_R(r, BOOST_PP_LIST_FOR_EACH_O, (macro, data), list)

#define BOOST_PP_LIST_FOR_EACH_PRODUCT(macro, size, tuple) BOOST_PP_LIST_FOR_EACH_PRODUCT_E(BOOST_PP_FOR, macro, size, BOOST_PP_TUPLE_TO_LIST(size, tuple))
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_R(r, macro, size, tuple) BOOST_PP_LIST_FOR_EACH_PRODUCT_E(BOOST_PP_FOR_ ## r, macro, size, BOOST_PP_TUPLE_TO_LIST(size, tuple))
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_E(impl, macro, size, lists) impl((BOOST_PP_LIST_FIRST(lists), BOOST_PP_LIST_REST(lists), BOOST_PP_NIL, macro, size), BOOST_PP_LIST_FOR_EACH_PRODUCT_P, BOOST_PP_LIST_FOR_EACH_PRODUCT_O, BOOST_PP_LIST_FOR_EACH_PRODUCT_M_0)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_P(r, data) BOOST_PP_LIST_FOR_EACH_PRODUCT_P_I data
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_P_I(a, b, res, macro, size) BOOST_PP_LIST_IS_CONS(a)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_O(r, data) BOOST_PP_LIST_FOR_EACH_PRODUCT_O_I data
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_O_I(a, b, res, macro, size) (BOOST_PP_LIST_REST(a), b, res, macro, size)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_I(r, data) BOOST_PP_LIST_FOR_EACH_PRODUCT_I_I(r, BOOST_PP_TUPLE_ELEM(5, 0, data), BOOST_PP_TUPLE_ELEM(5, 1, data), BOOST_PP_TUPLE_ELEM(5, 2, data), BOOST_PP_TUPLE_ELEM(5, 3, data), BOOST_PP_TUPLE_ELEM(5, 4, data))
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_I_I(r, a, b, res, macro, size) BOOST_PP_LIST_FOR_EACH_PRODUCT_I_II(r, macro, BOOST_PP_LIST_TO_TUPLE_R(r, (BOOST_PP_LIST_FIRST(a), res)), size)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_I_II(r, macro, args, size) BOOST_PP_LIST_FOR_EACH_PRODUCT_I_III(r, macro, args, size)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_I_III(r, macro, args, size) macro(r, BOOST_PP_TUPLE_REVERSE(size, args))
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_C(data, i) BOOST_PP_IF(BOOST_PP_LIST_IS_CONS(BOOST_PP_TUPLE_ELEM(5, 1, data)), BOOST_PP_LIST_FOR_EACH_PRODUCT_N_ ## i, BOOST_PP_LIST_FOR_EACH_PRODUCT_I)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_H(data) BOOST_PP_LIST_FOR_EACH_PRODUCT_H_I data
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_H_I(a, b, res, macro, size) (BOOST_PP_LIST_FIRST(b), BOOST_PP_LIST_REST(b), (BOOST_PP_LIST_FIRST(a), res), macro, size)

#define BOOST_PP_LIST_FOR_EACH_PRODUCT_M_0(r, data) BOOST_PP_LIST_FOR_EACH_PRODUCT_C(data, 0)(r, data)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_M_1(r, data) BOOST_PP_LIST_FOR_EACH_PRODUCT_C(data, 1)(r, data)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_M_2(r, data) BOOST_PP_LIST_FOR_EACH_PRODUCT_C(data, 2)(r, data)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_M_3(r, data) BOOST_PP_LIST_FOR_EACH_PRODUCT_C(data, 3)(r, data)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_M_4(r, data) BOOST_PP_LIST_FOR_EACH_PRODUCT_C(data, 4)(r, data)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_M_5(r, data) BOOST_PP_LIST_FOR_EACH_PRODUCT_C(data, 5)(r, data)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_M_6(r, data) BOOST_PP_LIST_FOR_EACH_PRODUCT_C(data, 6)(r, data)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_M_7(r, data) BOOST_PP_LIST_FOR_EACH_PRODUCT_C(data, 7)(r, data)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_M_8(r, data) BOOST_PP_LIST_FOR_EACH_PRODUCT_C(data, 8)(r, data)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_M_9(r, data) BOOST_PP_LIST_FOR_EACH_PRODUCT_C(data, 9)(r, data)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_M_10(r, data) BOOST_PP_LIST_FOR_EACH_PRODUCT_C(data, 10)(r, data)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_M_11(r, data) BOOST_PP_LIST_FOR_EACH_PRODUCT_C(data, 11)(r, data)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_M_12(r, data) BOOST_PP_LIST_FOR_EACH_PRODUCT_C(data, 12)(r, data)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_M_13(r, data) BOOST_PP_LIST_FOR_EACH_PRODUCT_C(data, 13)(r, data)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_M_14(r, data) BOOST_PP_LIST_FOR_EACH_PRODUCT_C(data, 14)(r, data)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_M_15(r, data) BOOST_PP_LIST_FOR_EACH_PRODUCT_C(data, 15)(r, data)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_M_16(r, data) BOOST_PP_LIST_FOR_EACH_PRODUCT_C(data, 16)(r, data)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_M_17(r, data) BOOST_PP_LIST_FOR_EACH_PRODUCT_C(data, 17)(r, data)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_M_18(r, data) BOOST_PP_LIST_FOR_EACH_PRODUCT_C(data, 18)(r, data)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_M_19(r, data) BOOST_PP_LIST_FOR_EACH_PRODUCT_C(data, 19)(r, data)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_M_20(r, data) BOOST_PP_LIST_FOR_EACH_PRODUCT_C(data, 20)(r, data)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_M_21(r, data) BOOST_PP_LIST_FOR_EACH_PRODUCT_C(data, 21)(r, data)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_M_22(r, data) BOOST_PP_LIST_FOR_EACH_PRODUCT_C(data, 22)(r, data)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_M_23(r, data) BOOST_PP_LIST_FOR_EACH_PRODUCT_C(data, 23)(r, data)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_M_24(r, data) BOOST_PP_LIST_FOR_EACH_PRODUCT_C(data, 24)(r, data)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_M_25(r, data) BOOST_PP_LIST_FOR_EACH_PRODUCT_C(data, 25)(r, data)

#define BOOST_PP_LIST_FOR_EACH_PRODUCT_N_0(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_LIST_FOR_EACH_PRODUCT_H(data), BOOST_PP_LIST_FOR_EACH_PRODUCT_P, BOOST_PP_LIST_FOR_EACH_PRODUCT_O, BOOST_PP_LIST_FOR_EACH_PRODUCT_M_1)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_N_1(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_LIST_FOR_EACH_PRODUCT_H(data), BOOST_PP_LIST_FOR_EACH_PRODUCT_P, BOOST_PP_LIST_FOR_EACH_PRODUCT_O, BOOST_PP_LIST_FOR_EACH_PRODUCT_M_2)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_N_2(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_LIST_FOR_EACH_PRODUCT_H(data), BOOST_PP_LIST_FOR_EACH_PRODUCT_P, BOOST_PP_LIST_FOR_EACH_PRODUCT_O, BOOST_PP_LIST_FOR_EACH_PRODUCT_M_3)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_N_3(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_LIST_FOR_EACH_PRODUCT_H(data), BOOST_PP_LIST_FOR_EACH_PRODUCT_P, BOOST_PP_LIST_FOR_EACH_PRODUCT_O, BOOST_PP_LIST_FOR_EACH_PRODUCT_M_4)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_N_4(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_LIST_FOR_EACH_PRODUCT_H(data), BOOST_PP_LIST_FOR_EACH_PRODUCT_P, BOOST_PP_LIST_FOR_EACH_PRODUCT_O, BOOST_PP_LIST_FOR_EACH_PRODUCT_M_5)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_N_5(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_LIST_FOR_EACH_PRODUCT_H(data), BOOST_PP_LIST_FOR_EACH_PRODUCT_P, BOOST_PP_LIST_FOR_EACH_PRODUCT_O, BOOST_PP_LIST_FOR_EACH_PRODUCT_M_6)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_N_6(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_LIST_FOR_EACH_PRODUCT_H(data), BOOST_PP_LIST_FOR_EACH_PRODUCT_P, BOOST_PP_LIST_FOR_EACH_PRODUCT_O, BOOST_PP_LIST_FOR_EACH_PRODUCT_M_7)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_N_7(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_LIST_FOR_EACH_PRODUCT_H(data), BOOST_PP_LIST_FOR_EACH_PRODUCT_P, BOOST_PP_LIST_FOR_EACH_PRODUCT_O, BOOST_PP_LIST_FOR_EACH_PRODUCT_M_8)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_N_8(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_LIST_FOR_EACH_PRODUCT_H(data), BOOST_PP_LIST_FOR_EACH_PRODUCT_P, BOOST_PP_LIST_FOR_EACH_PRODUCT_O, BOOST_PP_LIST_FOR_EACH_PRODUCT_M_9)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_N_9(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_LIST_FOR_EACH_PRODUCT_H(data), BOOST_PP_LIST_FOR_EACH_PRODUCT_P, BOOST_PP_LIST_FOR_EACH_PRODUCT_O, BOOST_PP_LIST_FOR_EACH_PRODUCT_M_10)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_N_10(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_LIST_FOR_EACH_PRODUCT_H(data), BOOST_PP_LIST_FOR_EACH_PRODUCT_P, BOOST_PP_LIST_FOR_EACH_PRODUCT_O, BOOST_PP_LIST_FOR_EACH_PRODUCT_M_11)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_N_11(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_LIST_FOR_EACH_PRODUCT_H(data), BOOST_PP_LIST_FOR_EACH_PRODUCT_P, BOOST_PP_LIST_FOR_EACH_PRODUCT_O, BOOST_PP_LIST_FOR_EACH_PRODUCT_M_12)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_N_12(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_LIST_FOR_EACH_PRODUCT_H(data), BOOST_PP_LIST_FOR_EACH_PRODUCT_P, BOOST_PP_LIST_FOR_EACH_PRODUCT_O, BOOST_PP_LIST_FOR_EACH_PRODUCT_M_13)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_N_13(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_LIST_FOR_EACH_PRODUCT_H(data), BOOST_PP_LIST_FOR_EACH_PRODUCT_P, BOOST_PP_LIST_FOR_EACH_PRODUCT_O, BOOST_PP_LIST_FOR_EACH_PRODUCT_M_14)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_N_14(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_LIST_FOR_EACH_PRODUCT_H(data), BOOST_PP_LIST_FOR_EACH_PRODUCT_P, BOOST_PP_LIST_FOR_EACH_PRODUCT_O, BOOST_PP_LIST_FOR_EACH_PRODUCT_M_15)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_N_15(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_LIST_FOR_EACH_PRODUCT_H(data), BOOST_PP_LIST_FOR_EACH_PRODUCT_P, BOOST_PP_LIST_FOR_EACH_PRODUCT_O, BOOST_PP_LIST_FOR_EACH_PRODUCT_M_16)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_N_16(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_LIST_FOR_EACH_PRODUCT_H(data), BOOST_PP_LIST_FOR_EACH_PRODUCT_P, BOOST_PP_LIST_FOR_EACH_PRODUCT_O, BOOST_PP_LIST_FOR_EACH_PRODUCT_M_17)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_N_17(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_LIST_FOR_EACH_PRODUCT_H(data), BOOST_PP_LIST_FOR_EACH_PRODUCT_P, BOOST_PP_LIST_FOR_EACH_PRODUCT_O, BOOST_PP_LIST_FOR_EACH_PRODUCT_M_18)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_N_18(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_LIST_FOR_EACH_PRODUCT_H(data), BOOST_PP_LIST_FOR_EACH_PRODUCT_P, BOOST_PP_LIST_FOR_EACH_PRODUCT_O, BOOST_PP_LIST_FOR_EACH_PRODUCT_M_19)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_N_19(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_LIST_FOR_EACH_PRODUCT_H(data), BOOST_PP_LIST_FOR_EACH_PRODUCT_P, BOOST_PP_LIST_FOR_EACH_PRODUCT_O, BOOST_PP_LIST_FOR_EACH_PRODUCT_M_20)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_N_20(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_LIST_FOR_EACH_PRODUCT_H(data), BOOST_PP_LIST_FOR_EACH_PRODUCT_P, BOOST_PP_LIST_FOR_EACH_PRODUCT_O, BOOST_PP_LIST_FOR_EACH_PRODUCT_M_21)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_N_21(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_LIST_FOR_EACH_PRODUCT_H(data), BOOST_PP_LIST_FOR_EACH_PRODUCT_P, BOOST_PP_LIST_FOR_EACH_PRODUCT_O, BOOST_PP_LIST_FOR_EACH_PRODUCT_M_22)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_N_22(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_LIST_FOR_EACH_PRODUCT_H(data), BOOST_PP_LIST_FOR_EACH_PRODUCT_P, BOOST_PP_LIST_FOR_EACH_PRODUCT_O, BOOST_PP_LIST_FOR_EACH_PRODUCT_M_23)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_N_23(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_LIST_FOR_EACH_PRODUCT_H(data), BOOST_PP_LIST_FOR_EACH_PRODUCT_P, BOOST_PP_LIST_FOR_EACH_PRODUCT_O, BOOST_PP_LIST_FOR_EACH_PRODUCT_M_24)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_N_24(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_LIST_FOR_EACH_PRODUCT_H(data), BOOST_PP_LIST_FOR_EACH_PRODUCT_P, BOOST_PP_LIST_FOR_EACH_PRODUCT_O, BOOST_PP_LIST_FOR_EACH_PRODUCT_M_25)
#define BOOST_PP_LIST_FOR_EACH_PRODUCT_N_25(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_LIST_FOR_EACH_PRODUCT_H(data), BOOST_PP_LIST_FOR_EACH_PRODUCT_P, BOOST_PP_LIST_FOR_EACH_PRODUCT_O, BOOST_PP_LIST_FOR_EACH_PRODUCT_M_26)

#define BOOST_PP_LIST_IS_CONS(list) BOOST_PP_IS_BINARY(list)

#define BOOST_PP_LIST_IS_NIL(list) BOOST_PP_COMPL(BOOST_PP_IS_BINARY(list))
#define BOOST_PP_LIST_NIL BOOST_PP_NIL

#define BOOST_PP_LIST_REST(list) BOOST_PP_LIST_REST_D(list)
#define BOOST_PP_LIST_REST_D(list) BOOST_PP_LIST_REST_I list
#define BOOST_PP_LIST_REST_I(head, tail) tail
#define BOOST_PP_LIST_REST_N(count, list) BOOST_PP_TUPLE_ELEM(2, 0, BOOST_PP_WHILE(BOOST_PP_LIST_REST_N_P, BOOST_PP_LIST_REST_N_O, (list, count)))
#define BOOST_PP_LIST_REST_N_P(d, lc) BOOST_PP_TUPLE_ELEM(2, 1, lc)
#define BOOST_PP_LIST_REST_N_O(d, lc) (BOOST_PP_LIST_REST(BOOST_PP_TUPLE_ELEM(2, 0, lc)), BOOST_PP_DEC(BOOST_PP_TUPLE_ELEM(2, 1, lc)))
#define BOOST_PP_LIST_REST_N_D(d, count, list) BOOST_PP_TUPLE_ELEM(2, 0, BOOST_PP_WHILE_ ## d(BOOST_PP_LIST_REST_N_P, BOOST_PP_LIST_REST_N_O, (list, count)))

#define BOOST_PP_LIST_REVERSE(list) BOOST_PP_LIST_FOLD_LEFT(BOOST_PP_LIST_REVERSE_O, BOOST_PP_NIL, list)
#define BOOST_PP_LIST_REVERSE_O(d, s, x) (x, s)
#define BOOST_PP_LIST_REVERSE_D(d, list) BOOST_PP_LIST_FOLD_LEFT_ ## d(BOOST_PP_LIST_REVERSE_O, BOOST_PP_NIL, list)

#define BOOST_PP_LIST_SIZE(list) BOOST_PP_TUPLE_ELEM(2, 0, BOOST_PP_WHILE(BOOST_PP_LIST_SIZE_P, BOOST_PP_LIST_SIZE_O, (0, list)))
#define BOOST_PP_LIST_SIZE_P(d, rl) BOOST_PP_LIST_IS_CONS(BOOST_PP_TUPLE_ELEM(2, 1, rl))
#define BOOST_PP_LIST_SIZE_O(d, rl) (BOOST_PP_INC(BOOST_PP_TUPLE_ELEM(2, 0, rl)), BOOST_PP_LIST_REST(BOOST_PP_TUPLE_ELEM(2, 1, rl)))
#define BOOST_PP_LIST_SIZE_D(d, list) BOOST_PP_TUPLE_ELEM(2, 0, BOOST_PP_WHILE_ ## d(BOOST_PP_LIST_SIZE_P, BOOST_PP_LIST_SIZE_O, (0, list)))

#define BOOST_PP_LIST_TO_TUPLE(list) (BOOST_PP_LIST_ENUM(list))
#define BOOST_PP_LIST_TO_TUPLE_R(r, list) (BOOST_PP_LIST_ENUM_R(r, list))

#define BOOST_PP_LIST_TRANSFORM(op, data, list) BOOST_PP_TUPLE_ELEM(3, 2, BOOST_PP_LIST_FOLD_RIGHT(BOOST_PP_LIST_TRANSFORM_O, (op, data, BOOST_PP_NIL), list))
#define BOOST_PP_LIST_TRANSFORM_O(d, odr, elem) BOOST_PP_LIST_TRANSFORM_O_D(d, BOOST_PP_TUPLE_ELEM(3, 0, odr), BOOST_PP_TUPLE_ELEM(3, 1, odr), BOOST_PP_TUPLE_ELEM(3, 2, odr), elem)
#define BOOST_PP_LIST_TRANSFORM_O_D(d, op, data, res, elem) (op, data, (op(d, data, elem), res))
#define BOOST_PP_LIST_TRANSFORM_D(d, op, data, list) BOOST_PP_TUPLE_ELEM(3, 2, BOOST_PP_LIST_FOLD_RIGHT_ ## d(BOOST_PP_LIST_TRANSFORM_O, (op, data, BOOST_PP_NIL), list))

#define BOOST_PP_LOCAL_C(n) (BOOST_PP_LOCAL_S) <= n && (BOOST_PP_LOCAL_F) >= n
#define BOOST_PP_LOCAL_R(n) (BOOST_PP_LOCAL_F) <= n && (BOOST_PP_LOCAL_S) >= n
#define BOOST_PP_LOCAL_S BOOST_PP_TUPLE_ELEM(2, 0, BOOST_PP_LOCAL_LIMITS)
#define BOOST_PP_LOCAL_F BOOST_PP_TUPLE_ELEM(2, 1, BOOST_PP_LOCAL_LIMITS)
#define BOOST_PP_LOCAL_FE() BOOST_PP_LOCAL_FE_DIGIT_1
#define BOOST_PP_LOCAL_FE_DIGIT_1 0
#define BOOST_PP_LOCAL_FE_DIGIT_2 0
#define BOOST_PP_LOCAL_FE_DIGIT_3 0
#define BOOST_PP_LOCAL_R(n) (BOOST_PP_LOCAL_F)<=n &&(BOOST_PP_LOCAL_S)>=n
#define BOOST_PP_LOCAL_S BOOST_PP_TUPLE_ELEM(2,0,BOOST_PP_LOCAL_LIMITS)
#define BOOST_PP_LOCAL_SE BOOST_PP_LOCAL_SE_DIGIT_1
#define BOOST_PP_LOCAL_SE_DIGIT_1 0
#define BOOST_PP_LOCAL_SE_DIGIT_2 0
#define BOOST_PP_LOCAL_SE_DIGIT_3 0

#define BOOST_PP_LPAREN (
#define BOOST_PP_LPAREN_IF(cond) BOOST_PP_IF(cond, BOOST_PP_LPAREN, BOOST_PP_EMPTY)()

#define BOOST_PP_MAX(x, y) BOOST_PP_IIF(BOOST_PP_LESS_EQUAL(x, y), y, x)
#define BOOST_PP_MAX_D(d, x, y) BOOST_PP_IIF(BOOST_PP_LESS_EQUAL_D(d, x, y), y, x)

#define BOOST_PP_MIN(x, y) BOOST_PP_IIF(BOOST_PP_LESS_EQUAL(y, x), y, x)
#define BOOST_PP_MIN_D(d, x, y) BOOST_PP_IIF(BOOST_PP_LESS_EQUAL_D(d, y, x), y, x)

#define BOOST_PP_MOD(x, y) BOOST_PP_TUPLE_ELEM(3, 1, BOOST_PP_DIV_BASE(x, y))
#define BOOST_PP_MOD_D(d, x, y) BOOST_PP_TUPLE_ELEM(3, 1, BOOST_PP_DIV_BASE_D(d, x, y))

#define BOOST_PP_MUL(x, y) BOOST_PP_TUPLE_ELEM(3, 0, BOOST_PP_WHILE(BOOST_PP_MUL_P, BOOST_PP_MUL_O, (0, x, y)))
#define BOOST_PP_MUL_P(d, rxy) BOOST_PP_TUPLE_ELEM(3, 2, rxy)
#define BOOST_PP_MUL_O(d, rxy) BOOST_PP_MUL_O_IM(d, BOOST_PP_TUPLE_REM_3 rxy)
#define BOOST_PP_MUL_O_IM(d, im) BOOST_PP_MUL_O_I(d, im)
#define BOOST_PP_MUL_O_I(d, r, x, y) (BOOST_PP_ADD_D(d, r, x), x, BOOST_PP_DEC(y))
#define BOOST_PP_MUL_D(d, x, y) BOOST_PP_TUPLE_ELEM(3, 0, BOOST_PP_WHILE_ ## d(BOOST_PP_MUL_P, BOOST_PP_MUL_O, (0, x, y)))

#define BOOST_PP_NODE_128(p) BOOST_PP_IIF(p(128), BOOST_PP_NODE_64, BOOST_PP_NODE_192)
#define BOOST_PP_NODE_64(p) BOOST_PP_IIF(p(64), BOOST_PP_NODE_32, BOOST_PP_NODE_96)
#define BOOST_PP_NODE_32(p) BOOST_PP_IIF(p(32), BOOST_PP_NODE_16, BOOST_PP_NODE_48)
#define BOOST_PP_NODE_16(p) BOOST_PP_IIF(p(16), BOOST_PP_NODE_8, BOOST_PP_NODE_24)
#define BOOST_PP_NODE_8(p) BOOST_PP_IIF(p(8), BOOST_PP_NODE_4, BOOST_PP_NODE_12)
#define BOOST_PP_NODE_4(p) BOOST_PP_IIF(p(4), BOOST_PP_NODE_2, BOOST_PP_NODE_6)
#define BOOST_PP_NODE_2(p) BOOST_PP_IIF(p(2), BOOST_PP_NODE_1, BOOST_PP_NODE_3)
#define BOOST_PP_NODE_1(p) BOOST_PP_IIF(p(1), 1, 2)
#define BOOST_PP_NODE_3(p) BOOST_PP_IIF(p(3), 3, 4)
#define BOOST_PP_NODE_6(p) BOOST_PP_IIF(p(6), BOOST_PP_NODE_5, BOOST_PP_NODE_7)
#define BOOST_PP_NODE_5(p) BOOST_PP_IIF(p(5), 5, 6)
#define BOOST_PP_NODE_7(p) BOOST_PP_IIF(p(7), 7, 8)
#define BOOST_PP_NODE_12(p) BOOST_PP_IIF(p(12), BOOST_PP_NODE_10, BOOST_PP_NODE_14)
#define BOOST_PP_NODE_10(p) BOOST_PP_IIF(p(10), BOOST_PP_NODE_9, BOOST_PP_NODE_11)
#define BOOST_PP_NODE_9(p) BOOST_PP_IIF(p(9), 9, 10)
#define BOOST_PP_NODE_11(p) BOOST_PP_IIF(p(11), 11, 12)
#define BOOST_PP_NODE_14(p) BOOST_PP_IIF(p(14), BOOST_PP_NODE_13, BOOST_PP_NODE_15)
#define BOOST_PP_NODE_13(p) BOOST_PP_IIF(p(13), 13, 14)
#define BOOST_PP_NODE_15(p) BOOST_PP_IIF(p(15), 15, 16)
#define BOOST_PP_NODE_24(p) BOOST_PP_IIF(p(24), BOOST_PP_NODE_20, BOOST_PP_NODE_28)
#define BOOST_PP_NODE_20(p) BOOST_PP_IIF(p(20), BOOST_PP_NODE_18, BOOST_PP_NODE_22)
#define BOOST_PP_NODE_18(p) BOOST_PP_IIF(p(18), BOOST_PP_NODE_17, BOOST_PP_NODE_19)
#define BOOST_PP_NODE_17(p) BOOST_PP_IIF(p(17), 17, 18)
#define BOOST_PP_NODE_19(p) BOOST_PP_IIF(p(19), 19, 20)
#define BOOST_PP_NODE_22(p) BOOST_PP_IIF(p(22), BOOST_PP_NODE_21, BOOST_PP_NODE_23)
#define BOOST_PP_NODE_21(p) BOOST_PP_IIF(p(21), 21, 22)
#define BOOST_PP_NODE_23(p) BOOST_PP_IIF(p(23), 23, 24)
#define BOOST_PP_NODE_28(p) BOOST_PP_IIF(p(28), BOOST_PP_NODE_26, BOOST_PP_NODE_30)
#define BOOST_PP_NODE_26(p) BOOST_PP_IIF(p(26), BOOST_PP_NODE_25, BOOST_PP_NODE_27)
#define BOOST_PP_NODE_25(p) BOOST_PP_IIF(p(25), 25, 26)
#define BOOST_PP_NODE_27(p) BOOST_PP_IIF(p(27), 27, 28)
#define BOOST_PP_NODE_30(p) BOOST_PP_IIF(p(30), BOOST_PP_NODE_29, BOOST_PP_NODE_31)
#define BOOST_PP_NODE_29(p) BOOST_PP_IIF(p(29), 29, 30)
#define BOOST_PP_NODE_31(p) BOOST_PP_IIF(p(31), 31, 32)
#define BOOST_PP_NODE_48(p) BOOST_PP_IIF(p(48), BOOST_PP_NODE_40, BOOST_PP_NODE_56)
#define BOOST_PP_NODE_40(p) BOOST_PP_IIF(p(40), BOOST_PP_NODE_36, BOOST_PP_NODE_44)
#define BOOST_PP_NODE_36(p) BOOST_PP_IIF(p(36), BOOST_PP_NODE_34, BOOST_PP_NODE_38)
#define BOOST_PP_NODE_34(p) BOOST_PP_IIF(p(34), BOOST_PP_NODE_33, BOOST_PP_NODE_35)
#define BOOST_PP_NODE_33(p) BOOST_PP_IIF(p(33), 33, 34)
#define BOOST_PP_NODE_35(p) BOOST_PP_IIF(p(35), 35, 36)
#define BOOST_PP_NODE_38(p) BOOST_PP_IIF(p(38), BOOST_PP_NODE_37, BOOST_PP_NODE_39)
#define BOOST_PP_NODE_37(p) BOOST_PP_IIF(p(37), 37, 38)
#define BOOST_PP_NODE_39(p) BOOST_PP_IIF(p(39), 39, 40)
#define BOOST_PP_NODE_44(p) BOOST_PP_IIF(p(44), BOOST_PP_NODE_42, BOOST_PP_NODE_46)
#define BOOST_PP_NODE_42(p) BOOST_PP_IIF(p(42), BOOST_PP_NODE_41, BOOST_PP_NODE_43)
#define BOOST_PP_NODE_41(p) BOOST_PP_IIF(p(41), 41, 42)
#define BOOST_PP_NODE_43(p) BOOST_PP_IIF(p(43), 43, 44)
#define BOOST_PP_NODE_46(p) BOOST_PP_IIF(p(46), BOOST_PP_NODE_45, BOOST_PP_NODE_47)
#define BOOST_PP_NODE_45(p) BOOST_PP_IIF(p(45), 45, 46)
#define BOOST_PP_NODE_47(p) BOOST_PP_IIF(p(47), 47, 48)
#define BOOST_PP_NODE_56(p) BOOST_PP_IIF(p(56), BOOST_PP_NODE_52, BOOST_PP_NODE_60)
#define BOOST_PP_NODE_52(p) BOOST_PP_IIF(p(52), BOOST_PP_NODE_50, BOOST_PP_NODE_54)
#define BOOST_PP_NODE_50(p) BOOST_PP_IIF(p(50), BOOST_PP_NODE_49, BOOST_PP_NODE_51)
#define BOOST_PP_NODE_49(p) BOOST_PP_IIF(p(49), 49, 50)
#define BOOST_PP_NODE_51(p) BOOST_PP_IIF(p(51), 51, 52)
#define BOOST_PP_NODE_54(p) BOOST_PP_IIF(p(54), BOOST_PP_NODE_53, BOOST_PP_NODE_55)
#define BOOST_PP_NODE_53(p) BOOST_PP_IIF(p(53), 53, 54)
#define BOOST_PP_NODE_55(p) BOOST_PP_IIF(p(55), 55, 56)
#define BOOST_PP_NODE_60(p) BOOST_PP_IIF(p(60), BOOST_PP_NODE_58, BOOST_PP_NODE_62)
#define BOOST_PP_NODE_58(p) BOOST_PP_IIF(p(58), BOOST_PP_NODE_57, BOOST_PP_NODE_59)
#define BOOST_PP_NODE_57(p) BOOST_PP_IIF(p(57), 57, 58)
#define BOOST_PP_NODE_59(p) BOOST_PP_IIF(p(59), 59, 60)
#define BOOST_PP_NODE_62(p) BOOST_PP_IIF(p(62), BOOST_PP_NODE_61, BOOST_PP_NODE_63)
#define BOOST_PP_NODE_61(p) BOOST_PP_IIF(p(61), 61, 62)
#define BOOST_PP_NODE_63(p) BOOST_PP_IIF(p(63), 63, 64)
#define BOOST_PP_NODE_96(p) BOOST_PP_IIF(p(96), BOOST_PP_NODE_80, BOOST_PP_NODE_112)
#define BOOST_PP_NODE_80(p) BOOST_PP_IIF(p(80), BOOST_PP_NODE_72, BOOST_PP_NODE_88)
#define BOOST_PP_NODE_72(p) BOOST_PP_IIF(p(72), BOOST_PP_NODE_68, BOOST_PP_NODE_76)
#define BOOST_PP_NODE_68(p) BOOST_PP_IIF(p(68), BOOST_PP_NODE_66, BOOST_PP_NODE_70)
#define BOOST_PP_NODE_66(p) BOOST_PP_IIF(p(66), BOOST_PP_NODE_65, BOOST_PP_NODE_67)
#define BOOST_PP_NODE_65(p) BOOST_PP_IIF(p(65), 65, 66)
#define BOOST_PP_NODE_67(p) BOOST_PP_IIF(p(67), 67, 68)
#define BOOST_PP_NODE_70(p) BOOST_PP_IIF(p(70), BOOST_PP_NODE_69, BOOST_PP_NODE_71)
#define BOOST_PP_NODE_69(p) BOOST_PP_IIF(p(69), 69, 70)
#define BOOST_PP_NODE_71(p) BOOST_PP_IIF(p(71), 71, 72)
#define BOOST_PP_NODE_76(p) BOOST_PP_IIF(p(76), BOOST_PP_NODE_74, BOOST_PP_NODE_78)
#define BOOST_PP_NODE_74(p) BOOST_PP_IIF(p(74), BOOST_PP_NODE_73, BOOST_PP_NODE_75)
#define BOOST_PP_NODE_73(p) BOOST_PP_IIF(p(73), 73, 74)
#define BOOST_PP_NODE_75(p) BOOST_PP_IIF(p(75), 75, 76)
#define BOOST_PP_NODE_78(p) BOOST_PP_IIF(p(78), BOOST_PP_NODE_77, BOOST_PP_NODE_79)
#define BOOST_PP_NODE_77(p) BOOST_PP_IIF(p(77), 77, 78)
#define BOOST_PP_NODE_79(p) BOOST_PP_IIF(p(79), 79, 80)
#define BOOST_PP_NODE_88(p) BOOST_PP_IIF(p(88), BOOST_PP_NODE_84, BOOST_PP_NODE_92)
#define BOOST_PP_NODE_84(p) BOOST_PP_IIF(p(84), BOOST_PP_NODE_82, BOOST_PP_NODE_86)
#define BOOST_PP_NODE_82(p) BOOST_PP_IIF(p(82), BOOST_PP_NODE_81, BOOST_PP_NODE_83)
#define BOOST_PP_NODE_81(p) BOOST_PP_IIF(p(81), 81, 82)
#define BOOST_PP_NODE_83(p) BOOST_PP_IIF(p(83), 83, 84)
#define BOOST_PP_NODE_86(p) BOOST_PP_IIF(p(86), BOOST_PP_NODE_85, BOOST_PP_NODE_87)
#define BOOST_PP_NODE_85(p) BOOST_PP_IIF(p(85), 85, 86)
#define BOOST_PP_NODE_87(p) BOOST_PP_IIF(p(87), 87, 88)
#define BOOST_PP_NODE_92(p) BOOST_PP_IIF(p(92), BOOST_PP_NODE_90, BOOST_PP_NODE_94)
#define BOOST_PP_NODE_90(p) BOOST_PP_IIF(p(90), BOOST_PP_NODE_89, BOOST_PP_NODE_91)
#define BOOST_PP_NODE_89(p) BOOST_PP_IIF(p(89), 89, 90)
#define BOOST_PP_NODE_91(p) BOOST_PP_IIF(p(91), 91, 92)
#define BOOST_PP_NODE_94(p) BOOST_PP_IIF(p(94), BOOST_PP_NODE_93, BOOST_PP_NODE_95)
#define BOOST_PP_NODE_93(p) BOOST_PP_IIF(p(93), 93, 94)
#define BOOST_PP_NODE_95(p) BOOST_PP_IIF(p(95), 95, 96)
#define BOOST_PP_NODE_112(p) BOOST_PP_IIF(p(112), BOOST_PP_NODE_104, BOOST_PP_NODE_120)
#define BOOST_PP_NODE_104(p) BOOST_PP_IIF(p(104), BOOST_PP_NODE_100, BOOST_PP_NODE_108)
#define BOOST_PP_NODE_100(p) BOOST_PP_IIF(p(100), BOOST_PP_NODE_98, BOOST_PP_NODE_102)
#define BOOST_PP_NODE_98(p) BOOST_PP_IIF(p(98), BOOST_PP_NODE_97, BOOST_PP_NODE_99)
#define BOOST_PP_NODE_97(p) BOOST_PP_IIF(p(97), 97, 98)
#define BOOST_PP_NODE_99(p) BOOST_PP_IIF(p(99), 99, 100)
#define BOOST_PP_NODE_102(p) BOOST_PP_IIF(p(102), BOOST_PP_NODE_101, BOOST_PP_NODE_103)
#define BOOST_PP_NODE_101(p) BOOST_PP_IIF(p(101), 101, 102)
#define BOOST_PP_NODE_103(p) BOOST_PP_IIF(p(103), 103, 104)
#define BOOST_PP_NODE_108(p) BOOST_PP_IIF(p(108), BOOST_PP_NODE_106, BOOST_PP_NODE_110)
#define BOOST_PP_NODE_106(p) BOOST_PP_IIF(p(106), BOOST_PP_NODE_105, BOOST_PP_NODE_107)
#define BOOST_PP_NODE_105(p) BOOST_PP_IIF(p(105), 105, 106)
#define BOOST_PP_NODE_107(p) BOOST_PP_IIF(p(107), 107, 108)
#define BOOST_PP_NODE_110(p) BOOST_PP_IIF(p(110), BOOST_PP_NODE_109, BOOST_PP_NODE_111)
#define BOOST_PP_NODE_109(p) BOOST_PP_IIF(p(109), 109, 110)
#define BOOST_PP_NODE_111(p) BOOST_PP_IIF(p(111), 111, 112)
#define BOOST_PP_NODE_120(p) BOOST_PP_IIF(p(120), BOOST_PP_NODE_116, BOOST_PP_NODE_124)
#define BOOST_PP_NODE_116(p) BOOST_PP_IIF(p(116), BOOST_PP_NODE_114, BOOST_PP_NODE_118)
#define BOOST_PP_NODE_114(p) BOOST_PP_IIF(p(114), BOOST_PP_NODE_113, BOOST_PP_NODE_115)
#define BOOST_PP_NODE_113(p) BOOST_PP_IIF(p(113), 113, 114)
#define BOOST_PP_NODE_115(p) BOOST_PP_IIF(p(115), 115, 116)
#define BOOST_PP_NODE_118(p) BOOST_PP_IIF(p(118), BOOST_PP_NODE_117, BOOST_PP_NODE_119)
#define BOOST_PP_NODE_117(p) BOOST_PP_IIF(p(117), 117, 118)
#define BOOST_PP_NODE_119(p) BOOST_PP_IIF(p(119), 119, 120)
#define BOOST_PP_NODE_124(p) BOOST_PP_IIF(p(124), BOOST_PP_NODE_122, BOOST_PP_NODE_126)
#define BOOST_PP_NODE_122(p) BOOST_PP_IIF(p(122), BOOST_PP_NODE_121, BOOST_PP_NODE_123)
#define BOOST_PP_NODE_121(p) BOOST_PP_IIF(p(121), 121, 122)
#define BOOST_PP_NODE_123(p) BOOST_PP_IIF(p(123), 123, 124)
#define BOOST_PP_NODE_126(p) BOOST_PP_IIF(p(126), BOOST_PP_NODE_125, BOOST_PP_NODE_127)
#define BOOST_PP_NODE_125(p) BOOST_PP_IIF(p(125), 125, 126)
#define BOOST_PP_NODE_127(p) BOOST_PP_IIF(p(127), 127, 128)
#define BOOST_PP_NODE_192(p) BOOST_PP_IIF(p(192), BOOST_PP_NODE_160, BOOST_PP_NODE_224)
#define BOOST_PP_NODE_160(p) BOOST_PP_IIF(p(160), BOOST_PP_NODE_144, BOOST_PP_NODE_176)
#define BOOST_PP_NODE_144(p) BOOST_PP_IIF(p(144), BOOST_PP_NODE_136, BOOST_PP_NODE_152)
#define BOOST_PP_NODE_136(p) BOOST_PP_IIF(p(136), BOOST_PP_NODE_132, BOOST_PP_NODE_140)
#define BOOST_PP_NODE_132(p) BOOST_PP_IIF(p(132), BOOST_PP_NODE_130, BOOST_PP_NODE_134)
#define BOOST_PP_NODE_130(p) BOOST_PP_IIF(p(130), BOOST_PP_NODE_129, BOOST_PP_NODE_131)
#define BOOST_PP_NODE_129(p) BOOST_PP_IIF(p(129), 129, 130)
#define BOOST_PP_NODE_131(p) BOOST_PP_IIF(p(131), 131, 132)
#define BOOST_PP_NODE_134(p) BOOST_PP_IIF(p(134), BOOST_PP_NODE_133, BOOST_PP_NODE_135)
#define BOOST_PP_NODE_133(p) BOOST_PP_IIF(p(133), 133, 134)
#define BOOST_PP_NODE_135(p) BOOST_PP_IIF(p(135), 135, 136)
#define BOOST_PP_NODE_140(p) BOOST_PP_IIF(p(140), BOOST_PP_NODE_138, BOOST_PP_NODE_142)
#define BOOST_PP_NODE_138(p) BOOST_PP_IIF(p(138), BOOST_PP_NODE_137, BOOST_PP_NODE_139)
#define BOOST_PP_NODE_137(p) BOOST_PP_IIF(p(137), 137, 138)
#define BOOST_PP_NODE_139(p) BOOST_PP_IIF(p(139), 139, 140)
#define BOOST_PP_NODE_142(p) BOOST_PP_IIF(p(142), BOOST_PP_NODE_141, BOOST_PP_NODE_143)
#define BOOST_PP_NODE_141(p) BOOST_PP_IIF(p(141), 141, 142)
#define BOOST_PP_NODE_143(p) BOOST_PP_IIF(p(143), 143, 144)
#define BOOST_PP_NODE_152(p) BOOST_PP_IIF(p(152), BOOST_PP_NODE_148, BOOST_PP_NODE_156)
#define BOOST_PP_NODE_148(p) BOOST_PP_IIF(p(148), BOOST_PP_NODE_146, BOOST_PP_NODE_150)
#define BOOST_PP_NODE_146(p) BOOST_PP_IIF(p(146), BOOST_PP_NODE_145, BOOST_PP_NODE_147)
#define BOOST_PP_NODE_145(p) BOOST_PP_IIF(p(145), 145, 146)
#define BOOST_PP_NODE_147(p) BOOST_PP_IIF(p(147), 147, 148)
#define BOOST_PP_NODE_150(p) BOOST_PP_IIF(p(150), BOOST_PP_NODE_149, BOOST_PP_NODE_151)
#define BOOST_PP_NODE_149(p) BOOST_PP_IIF(p(149), 149, 150)
#define BOOST_PP_NODE_151(p) BOOST_PP_IIF(p(151), 151, 152)
#define BOOST_PP_NODE_156(p) BOOST_PP_IIF(p(156), BOOST_PP_NODE_154, BOOST_PP_NODE_158)
#define BOOST_PP_NODE_154(p) BOOST_PP_IIF(p(154), BOOST_PP_NODE_153, BOOST_PP_NODE_155)
#define BOOST_PP_NODE_153(p) BOOST_PP_IIF(p(153), 153, 154)
#define BOOST_PP_NODE_155(p) BOOST_PP_IIF(p(155), 155, 156)
#define BOOST_PP_NODE_158(p) BOOST_PP_IIF(p(158), BOOST_PP_NODE_157, BOOST_PP_NODE_159)
#define BOOST_PP_NODE_157(p) BOOST_PP_IIF(p(157), 157, 158)
#define BOOST_PP_NODE_159(p) BOOST_PP_IIF(p(159), 159, 160)
#define BOOST_PP_NODE_176(p) BOOST_PP_IIF(p(176), BOOST_PP_NODE_168, BOOST_PP_NODE_184)
#define BOOST_PP_NODE_168(p) BOOST_PP_IIF(p(168), BOOST_PP_NODE_164, BOOST_PP_NODE_172)
#define BOOST_PP_NODE_164(p) BOOST_PP_IIF(p(164), BOOST_PP_NODE_162, BOOST_PP_NODE_166)
#define BOOST_PP_NODE_162(p) BOOST_PP_IIF(p(162), BOOST_PP_NODE_161, BOOST_PP_NODE_163)
#define BOOST_PP_NODE_161(p) BOOST_PP_IIF(p(161), 161, 162)
#define BOOST_PP_NODE_163(p) BOOST_PP_IIF(p(163), 163, 164)
#define BOOST_PP_NODE_166(p) BOOST_PP_IIF(p(166), BOOST_PP_NODE_165, BOOST_PP_NODE_167)
#define BOOST_PP_NODE_165(p) BOOST_PP_IIF(p(165), 165, 166)
#define BOOST_PP_NODE_167(p) BOOST_PP_IIF(p(167), 167, 168)
#define BOOST_PP_NODE_172(p) BOOST_PP_IIF(p(172), BOOST_PP_NODE_170, BOOST_PP_NODE_174)
#define BOOST_PP_NODE_170(p) BOOST_PP_IIF(p(170), BOOST_PP_NODE_169, BOOST_PP_NODE_171)
#define BOOST_PP_NODE_169(p) BOOST_PP_IIF(p(169), 169, 170)
#define BOOST_PP_NODE_171(p) BOOST_PP_IIF(p(171), 171, 172)
#define BOOST_PP_NODE_174(p) BOOST_PP_IIF(p(174), BOOST_PP_NODE_173, BOOST_PP_NODE_175)
#define BOOST_PP_NODE_173(p) BOOST_PP_IIF(p(173), 173, 174)
#define BOOST_PP_NODE_175(p) BOOST_PP_IIF(p(175), 175, 176)
#define BOOST_PP_NODE_184(p) BOOST_PP_IIF(p(184), BOOST_PP_NODE_180, BOOST_PP_NODE_188)
#define BOOST_PP_NODE_180(p) BOOST_PP_IIF(p(180), BOOST_PP_NODE_178, BOOST_PP_NODE_182)
#define BOOST_PP_NODE_178(p) BOOST_PP_IIF(p(178), BOOST_PP_NODE_177, BOOST_PP_NODE_179)
#define BOOST_PP_NODE_177(p) BOOST_PP_IIF(p(177), 177, 178)
#define BOOST_PP_NODE_179(p) BOOST_PP_IIF(p(179), 179, 180)
#define BOOST_PP_NODE_182(p) BOOST_PP_IIF(p(182), BOOST_PP_NODE_181, BOOST_PP_NODE_183)
#define BOOST_PP_NODE_181(p) BOOST_PP_IIF(p(181), 181, 182)
#define BOOST_PP_NODE_183(p) BOOST_PP_IIF(p(183), 183, 184)
#define BOOST_PP_NODE_188(p) BOOST_PP_IIF(p(188), BOOST_PP_NODE_186, BOOST_PP_NODE_190)
#define BOOST_PP_NODE_186(p) BOOST_PP_IIF(p(186), BOOST_PP_NODE_185, BOOST_PP_NODE_187)
#define BOOST_PP_NODE_185(p) BOOST_PP_IIF(p(185), 185, 186)
#define BOOST_PP_NODE_187(p) BOOST_PP_IIF(p(187), 187, 188)
#define BOOST_PP_NODE_190(p) BOOST_PP_IIF(p(190), BOOST_PP_NODE_189, BOOST_PP_NODE_191)
#define BOOST_PP_NODE_189(p) BOOST_PP_IIF(p(189), 189, 190)
#define BOOST_PP_NODE_191(p) BOOST_PP_IIF(p(191), 191, 192)
#define BOOST_PP_NODE_224(p) BOOST_PP_IIF(p(224), BOOST_PP_NODE_208, BOOST_PP_NODE_240)
#define BOOST_PP_NODE_208(p) BOOST_PP_IIF(p(208), BOOST_PP_NODE_200, BOOST_PP_NODE_216)
#define BOOST_PP_NODE_200(p) BOOST_PP_IIF(p(200), BOOST_PP_NODE_196, BOOST_PP_NODE_204)
#define BOOST_PP_NODE_196(p) BOOST_PP_IIF(p(196), BOOST_PP_NODE_194, BOOST_PP_NODE_198)
#define BOOST_PP_NODE_194(p) BOOST_PP_IIF(p(194), BOOST_PP_NODE_193, BOOST_PP_NODE_195)
#define BOOST_PP_NODE_193(p) BOOST_PP_IIF(p(193), 193, 194)
#define BOOST_PP_NODE_195(p) BOOST_PP_IIF(p(195), 195, 196)
#define BOOST_PP_NODE_198(p) BOOST_PP_IIF(p(198), BOOST_PP_NODE_197, BOOST_PP_NODE_199)
#define BOOST_PP_NODE_197(p) BOOST_PP_IIF(p(197), 197, 198)
#define BOOST_PP_NODE_199(p) BOOST_PP_IIF(p(199), 199, 200)
#define BOOST_PP_NODE_204(p) BOOST_PP_IIF(p(204), BOOST_PP_NODE_202, BOOST_PP_NODE_206)
#define BOOST_PP_NODE_202(p) BOOST_PP_IIF(p(202), BOOST_PP_NODE_201, BOOST_PP_NODE_203)
#define BOOST_PP_NODE_201(p) BOOST_PP_IIF(p(201), 201, 202)
#define BOOST_PP_NODE_203(p) BOOST_PP_IIF(p(203), 203, 204)
#define BOOST_PP_NODE_206(p) BOOST_PP_IIF(p(206), BOOST_PP_NODE_205, BOOST_PP_NODE_207)
#define BOOST_PP_NODE_205(p) BOOST_PP_IIF(p(205), 205, 206)
#define BOOST_PP_NODE_207(p) BOOST_PP_IIF(p(207), 207, 208)
#define BOOST_PP_NODE_216(p) BOOST_PP_IIF(p(216), BOOST_PP_NODE_212, BOOST_PP_NODE_220)
#define BOOST_PP_NODE_212(p) BOOST_PP_IIF(p(212), BOOST_PP_NODE_210, BOOST_PP_NODE_214)
#define BOOST_PP_NODE_210(p) BOOST_PP_IIF(p(210), BOOST_PP_NODE_209, BOOST_PP_NODE_211)
#define BOOST_PP_NODE_209(p) BOOST_PP_IIF(p(209), 209, 210)
#define BOOST_PP_NODE_211(p) BOOST_PP_IIF(p(211), 211, 212)
#define BOOST_PP_NODE_214(p) BOOST_PP_IIF(p(214), BOOST_PP_NODE_213, BOOST_PP_NODE_215)
#define BOOST_PP_NODE_213(p) BOOST_PP_IIF(p(213), 213, 214)
#define BOOST_PP_NODE_215(p) BOOST_PP_IIF(p(215), 215, 216)
#define BOOST_PP_NODE_220(p) BOOST_PP_IIF(p(220), BOOST_PP_NODE_218, BOOST_PP_NODE_222)
#define BOOST_PP_NODE_218(p) BOOST_PP_IIF(p(218), BOOST_PP_NODE_217, BOOST_PP_NODE_219)
#define BOOST_PP_NODE_217(p) BOOST_PP_IIF(p(217), 217, 218)
#define BOOST_PP_NODE_219(p) BOOST_PP_IIF(p(219), 219, 220)
#define BOOST_PP_NODE_222(p) BOOST_PP_IIF(p(222), BOOST_PP_NODE_221, BOOST_PP_NODE_223)
#define BOOST_PP_NODE_221(p) BOOST_PP_IIF(p(221), 221, 222)
#define BOOST_PP_NODE_223(p) BOOST_PP_IIF(p(223), 223, 224)
#define BOOST_PP_NODE_240(p) BOOST_PP_IIF(p(240), BOOST_PP_NODE_232, BOOST_PP_NODE_248)
#define BOOST_PP_NODE_232(p) BOOST_PP_IIF(p(232), BOOST_PP_NODE_228, BOOST_PP_NODE_236)
#define BOOST_PP_NODE_228(p) BOOST_PP_IIF(p(228), BOOST_PP_NODE_226, BOOST_PP_NODE_230)
#define BOOST_PP_NODE_226(p) BOOST_PP_IIF(p(226), BOOST_PP_NODE_225, BOOST_PP_NODE_227)
#define BOOST_PP_NODE_225(p) BOOST_PP_IIF(p(225), 225, 226)
#define BOOST_PP_NODE_227(p) BOOST_PP_IIF(p(227), 227, 228)
#define BOOST_PP_NODE_230(p) BOOST_PP_IIF(p(230), BOOST_PP_NODE_229, BOOST_PP_NODE_231)
#define BOOST_PP_NODE_229(p) BOOST_PP_IIF(p(229), 229, 230)
#define BOOST_PP_NODE_231(p) BOOST_PP_IIF(p(231), 231, 232)
#define BOOST_PP_NODE_236(p) BOOST_PP_IIF(p(236), BOOST_PP_NODE_234, BOOST_PP_NODE_238)
#define BOOST_PP_NODE_234(p) BOOST_PP_IIF(p(234), BOOST_PP_NODE_233, BOOST_PP_NODE_235)
#define BOOST_PP_NODE_233(p) BOOST_PP_IIF(p(233), 233, 234)
#define BOOST_PP_NODE_235(p) BOOST_PP_IIF(p(235), 235, 236)
#define BOOST_PP_NODE_238(p) BOOST_PP_IIF(p(238), BOOST_PP_NODE_237, BOOST_PP_NODE_239)
#define BOOST_PP_NODE_237(p) BOOST_PP_IIF(p(237), 237, 238)
#define BOOST_PP_NODE_239(p) BOOST_PP_IIF(p(239), 239, 240)
#define BOOST_PP_NODE_248(p) BOOST_PP_IIF(p(248), BOOST_PP_NODE_244, BOOST_PP_NODE_252)
#define BOOST_PP_NODE_244(p) BOOST_PP_IIF(p(244), BOOST_PP_NODE_242, BOOST_PP_NODE_246)
#define BOOST_PP_NODE_242(p) BOOST_PP_IIF(p(242), BOOST_PP_NODE_241, BOOST_PP_NODE_243)
#define BOOST_PP_NODE_241(p) BOOST_PP_IIF(p(241), 241, 242)
#define BOOST_PP_NODE_243(p) BOOST_PP_IIF(p(243), 243, 244)
#define BOOST_PP_NODE_246(p) BOOST_PP_IIF(p(246), BOOST_PP_NODE_245, BOOST_PP_NODE_247)
#define BOOST_PP_NODE_245(p) BOOST_PP_IIF(p(245), 245, 246)
#define BOOST_PP_NODE_247(p) BOOST_PP_IIF(p(247), 247, 248)
#define BOOST_PP_NODE_252(p) BOOST_PP_IIF(p(252), BOOST_PP_NODE_250, BOOST_PP_NODE_254)
#define BOOST_PP_NODE_250(p) BOOST_PP_IIF(p(250), BOOST_PP_NODE_249, BOOST_PP_NODE_251)
#define BOOST_PP_NODE_249(p) BOOST_PP_IIF(p(249), 249, 250)
#define BOOST_PP_NODE_251(p) BOOST_PP_IIF(p(251), 251, 252)
#define BOOST_PP_NODE_254(p) BOOST_PP_IIF(p(254), BOOST_PP_NODE_253, BOOST_PP_NODE_255)
#define BOOST_PP_NODE_253(p) BOOST_PP_IIF(p(253), 253, 254)
#define BOOST_PP_NODE_255(p) BOOST_PP_IIF(p(255), 255, 256)

#define BOOST_PP_NODE_ENTRY_256(p) BOOST_PP_NODE_128(p)(p)(p)(p)(p)(p)(p)(p)
#define BOOST_PP_NODE_ENTRY_128(p) BOOST_PP_NODE_64(p)(p)(p)(p)(p)(p)(p)
#define BOOST_PP_NODE_ENTRY_64(p) BOOST_PP_NODE_32(p)(p)(p)(p)(p)(p)
#define BOOST_PP_NODE_ENTRY_32(p) BOOST_PP_NODE_16(p)(p)(p)(p)(p)
#define BOOST_PP_NODE_ENTRY_16(p) BOOST_PP_NODE_8(p)(p)(p)(p)
#define BOOST_PP_NODE_ENTRY_8(p) BOOST_PP_NODE_4(p)(p)(p)
#define BOOST_PP_NODE_ENTRY_4(p) BOOST_PP_NODE_2(p)(p)
#define BOOST_PP_NODE_ENTRY_2(p) BOOST_PP_NODE_1(p)

#define BOOST_PP_NOR(p, q) BOOST_PP_BITNOR(BOOST_PP_BOOL(p), BOOST_PP_BOOL(q))

#define BOOST_PP_NOT(x) BOOST_PP_COMPL(BOOST_PP_BOOL(x))

#define BOOST_PP_NOT_EQUAL(x, y) BOOST_PP_NOT_EQUAL_I(x, y)
#define BOOST_PP_NOT_EQUAL_I(x, y) BOOST_PP_CAT(BOOST_PP_NOT_EQUAL_CHECK_, BOOST_PP_NOT_EQUAL_ ## x(0, BOOST_PP_NOT_EQUAL_ ## y))
#define BOOST_PP_NOT_EQUAL_D(d, x, y) BOOST_PP_NOT_EQUAL(x, y)
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NIL 1

#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_0(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_1(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_2(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_3(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_4(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_5(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_6(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_7(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_8(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_9(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_10(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_11(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_12(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_13(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_14(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_15(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_16(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_17(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_18(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_19(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_20(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_21(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_22(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_23(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_24(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_25(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_26(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_27(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_28(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_29(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_30(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_31(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_32(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_33(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_34(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_35(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_36(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_37(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_38(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_39(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_40(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_41(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_42(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_43(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_44(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_45(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_46(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_47(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_48(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_49(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_50(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_51(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_52(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_53(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_54(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_55(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_56(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_57(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_58(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_59(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_60(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_61(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_62(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_63(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_64(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_65(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_66(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_67(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_68(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_69(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_70(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_71(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_72(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_73(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_74(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_75(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_76(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_77(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_78(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_79(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_80(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_81(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_82(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_83(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_84(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_85(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_86(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_87(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_88(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_89(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_90(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_91(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_92(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_93(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_94(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_95(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_96(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_97(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_98(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_99(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_100(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_101(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_102(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_103(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_104(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_105(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_106(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_107(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_108(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_109(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_110(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_111(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_112(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_113(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_114(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_115(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_116(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_117(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_118(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_119(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_120(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_121(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_122(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_123(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_124(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_125(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_126(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_127(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_128(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_129(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_130(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_131(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_132(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_133(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_134(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_135(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_136(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_137(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_138(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_139(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_140(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_141(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_142(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_143(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_144(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_145(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_146(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_147(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_148(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_149(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_150(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_151(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_152(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_153(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_154(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_155(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_156(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_157(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_158(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_159(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_160(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_161(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_162(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_163(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_164(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_165(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_166(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_167(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_168(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_169(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_170(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_171(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_172(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_173(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_174(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_175(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_176(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_177(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_178(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_179(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_180(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_181(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_182(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_183(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_184(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_185(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_186(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_187(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_188(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_189(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_190(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_191(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_192(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_193(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_194(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_195(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_196(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_197(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_198(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_199(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_200(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_201(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_202(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_203(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_204(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_205(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_206(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_207(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_208(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_209(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_210(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_211(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_212(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_213(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_214(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_215(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_216(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_217(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_218(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_219(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_220(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_221(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_222(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_223(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_224(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_225(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_226(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_227(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_228(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_229(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_230(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_231(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_232(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_233(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_234(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_235(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_236(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_237(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_238(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_239(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_240(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_241(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_242(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_243(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_244(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_245(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_246(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_247(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_248(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_249(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_250(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_251(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_252(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_253(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_254(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_255(c, y) 0
#define BOOST_PP_NOT_EQUAL_CHECK_BOOST_PP_NOT_EQUAL_256(c, y) 0

#define BOOST_PP_NOT_EQUAL_0(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_1(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_2(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_3(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_4(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_5(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_6(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_7(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_8(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_9(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_10(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_11(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_12(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_13(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_14(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_15(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_16(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_17(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_18(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_19(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_20(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_21(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_22(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_23(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_24(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_25(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_26(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_27(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_28(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_29(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_30(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_31(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_32(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_33(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_34(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_35(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_36(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_37(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_38(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_39(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_40(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_41(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_42(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_43(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_44(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_45(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_46(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_47(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_48(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_49(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_50(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_51(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_52(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_53(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_54(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_55(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_56(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_57(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_58(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_59(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_60(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_61(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_62(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_63(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_64(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_65(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_66(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_67(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_68(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_69(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_70(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_71(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_72(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_73(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_74(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_75(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_76(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_77(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_78(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_79(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_80(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_81(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_82(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_83(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_84(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_85(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_86(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_87(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_88(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_89(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_90(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_91(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_92(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_93(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_94(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_95(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_96(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_97(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_98(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_99(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_100(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_101(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_102(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_103(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_104(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_105(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_106(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_107(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_108(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_109(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_110(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_111(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_112(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_113(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_114(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_115(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_116(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_117(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_118(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_119(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_120(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_121(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_122(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_123(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_124(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_125(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_126(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_127(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_128(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_129(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_130(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_131(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_132(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_133(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_134(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_135(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_136(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_137(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_138(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_139(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_140(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_141(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_142(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_143(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_144(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_145(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_146(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_147(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_148(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_149(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_150(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_151(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_152(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_153(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_154(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_155(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_156(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_157(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_158(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_159(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_160(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_161(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_162(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_163(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_164(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_165(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_166(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_167(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_168(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_169(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_170(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_171(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_172(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_173(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_174(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_175(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_176(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_177(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_178(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_179(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_180(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_181(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_182(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_183(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_184(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_185(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_186(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_187(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_188(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_189(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_190(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_191(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_192(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_193(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_194(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_195(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_196(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_197(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_198(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_199(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_200(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_201(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_202(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_203(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_204(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_205(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_206(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_207(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_208(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_209(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_210(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_211(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_212(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_213(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_214(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_215(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_216(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_217(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_218(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_219(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_220(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_221(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_222(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_223(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_224(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_225(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_226(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_227(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_228(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_229(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_230(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_231(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_232(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_233(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_234(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_235(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_236(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_237(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_238(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_239(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_240(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_241(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_242(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_243(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_244(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_245(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_246(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_247(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_248(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_249(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_250(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_251(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_252(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_253(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_254(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_255(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))
#define BOOST_PP_NOT_EQUAL_256(c, y) BOOST_PP_IIF(c, BOOST_PP_NIL, y(1, BOOST_PP_NIL))

#define BOOST_PP_OR(p, q) BOOST_PP_BITOR(BOOST_PP_BOOL(p), BOOST_PP_BOOL(q))

#define BOOST_PP_RELATIVE_ITERATION(i) BOOST_PP_CAT(BOOST_PP_RELATIVE_, i)(BOOST_PP_ITERATION_)
#define BOOST_PP_RELATIVE_0(m) BOOST_PP_CAT(m, BOOST_PP_ITERATION_DEPTH())
#define BOOST_PP_RELATIVE_1(m) BOOST_PP_CAT(m, BOOST_PP_DEC(BOOST_PP_ITERATION_DEPTH()))
#define BOOST_PP_RELATIVE_2(m) BOOST_PP_CAT(m, BOOST_PP_DEC(BOOST_PP_DEC(BOOST_PP_ITERATION_DEPTH())))
#define BOOST_PP_RELATIVE_3(m) BOOST_PP_CAT(m, BOOST_PP_DEC(BOOST_PP_DEC(BOOST_PP_DEC(BOOST_PP_ITERATION_DEPTH()))))
#define BOOST_PP_RELATIVE_4(m) BOOST_PP_CAT(m, BOOST_PP_DEC(BOOST_PP_DEC(BOOST_PP_DEC(BOOST_PP_DEC(BOOST_PP_ITERATION_DEPTH())))))
#define BOOST_PP_RELATIVE_START(i) BOOST_PP_CAT(BOOST_PP_RELATIVE_, i)(BOOST_PP_ITERATION_START_)
#define BOOST_PP_RELATIVE_FINISH(i) BOOST_PP_CAT(BOOST_PP_RELATIVE_, i)(BOOST_PP_ITERATION_FINISH_)
#define BOOST_PP_RELATIVE_FLAGS(i) (BOOST_PP_CAT(BOOST_PP_RELATIVE_, i)(BOOST_PP_ITERATION_FLAGS_))

#define BOOST_PP_REPEAT BOOST_PP_CAT(BOOST_PP_REPEAT_, BOOST_PP_AUTO_REC(BOOST_PP_REPEAT_P, 4))
#define BOOST_PP_REPEAT_P(n) BOOST_PP_CAT(BOOST_PP_REPEAT_CHECK_, BOOST_PP_REPEAT_ ## n(1, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_3, BOOST_PP_NIL))

#define BOOST_PP_REPEAT_CHECK_BOOST_PP_NIL 1
#define BOOST_PP_REPEAT_CHECK_BOOST_PP_REPEAT_1(c, m, d) 0
#define BOOST_PP_REPEAT_CHECK_BOOST_PP_REPEAT_2(c, m, d) 0
#define BOOST_PP_REPEAT_CHECK_BOOST_PP_REPEAT_3(c, m, d) 0
#define BOOST_PP_REPEAT_1(c, m, d) BOOST_PP_REPEAT_1_I(c, m, d)
#define BOOST_PP_REPEAT_2(c, m, d) BOOST_PP_REPEAT_2_I(c, m, d)
#define BOOST_PP_REPEAT_3(c, m, d) BOOST_PP_REPEAT_3_I(c, m, d)
#define BOOST_PP_REPEAT_4(c, m, d) BOOST_PP_ERROR(0x0003)
#define BOOST_PP_REPEAT_1_I(c, m, d) BOOST_PP_REPEAT_1_ ## c(m, d)
#define BOOST_PP_REPEAT_2_I(c, m, d) BOOST_PP_REPEAT_2_ ## c(m, d)
#define BOOST_PP_REPEAT_3_I(c, m, d) BOOST_PP_REPEAT_3_ ## c(m, d)

#define BOOST_PP_REPEAT_1ST BOOST_PP_REPEAT_1
#define BOOST_PP_REPEAT_2ND BOOST_PP_REPEAT_2
#define BOOST_PP_REPEAT_3RD BOOST_PP_REPEAT_3

#define BOOST_PP_REPEAT_1_0(m, d)
#define BOOST_PP_REPEAT_1_1(m, d) m(2, 0, d)
#define BOOST_PP_REPEAT_1_2(m, d) BOOST_PP_REPEAT_1_1(m, d) m(2, 1, d)
#define BOOST_PP_REPEAT_1_3(m, d) BOOST_PP_REPEAT_1_2(m, d) m(2, 2, d)
#define BOOST_PP_REPEAT_1_4(m, d) BOOST_PP_REPEAT_1_3(m, d) m(2, 3, d)
#define BOOST_PP_REPEAT_1_5(m, d) BOOST_PP_REPEAT_1_4(m, d) m(2, 4, d)
#define BOOST_PP_REPEAT_1_6(m, d) BOOST_PP_REPEAT_1_5(m, d) m(2, 5, d)
#define BOOST_PP_REPEAT_1_7(m, d) BOOST_PP_REPEAT_1_6(m, d) m(2, 6, d)
#define BOOST_PP_REPEAT_1_8(m, d) BOOST_PP_REPEAT_1_7(m, d) m(2, 7, d)
#define BOOST_PP_REPEAT_1_9(m, d) BOOST_PP_REPEAT_1_8(m, d) m(2, 8, d)
#define BOOST_PP_REPEAT_1_10(m, d) BOOST_PP_REPEAT_1_9(m, d) m(2, 9, d)
#define BOOST_PP_REPEAT_1_11(m, d) BOOST_PP_REPEAT_1_10(m, d) m(2, 10, d)
#define BOOST_PP_REPEAT_1_12(m, d) BOOST_PP_REPEAT_1_11(m, d) m(2, 11, d)
#define BOOST_PP_REPEAT_1_13(m, d) BOOST_PP_REPEAT_1_12(m, d) m(2, 12, d)
#define BOOST_PP_REPEAT_1_14(m, d) BOOST_PP_REPEAT_1_13(m, d) m(2, 13, d)
#define BOOST_PP_REPEAT_1_15(m, d) BOOST_PP_REPEAT_1_14(m, d) m(2, 14, d)
#define BOOST_PP_REPEAT_1_16(m, d) BOOST_PP_REPEAT_1_15(m, d) m(2, 15, d)
#define BOOST_PP_REPEAT_1_17(m, d) BOOST_PP_REPEAT_1_16(m, d) m(2, 16, d)
#define BOOST_PP_REPEAT_1_18(m, d) BOOST_PP_REPEAT_1_17(m, d) m(2, 17, d)
#define BOOST_PP_REPEAT_1_19(m, d) BOOST_PP_REPEAT_1_18(m, d) m(2, 18, d)
#define BOOST_PP_REPEAT_1_20(m, d) BOOST_PP_REPEAT_1_19(m, d) m(2, 19, d)
#define BOOST_PP_REPEAT_1_21(m, d) BOOST_PP_REPEAT_1_20(m, d) m(2, 20, d)
#define BOOST_PP_REPEAT_1_22(m, d) BOOST_PP_REPEAT_1_21(m, d) m(2, 21, d)
#define BOOST_PP_REPEAT_1_23(m, d) BOOST_PP_REPEAT_1_22(m, d) m(2, 22, d)
#define BOOST_PP_REPEAT_1_24(m, d) BOOST_PP_REPEAT_1_23(m, d) m(2, 23, d)
#define BOOST_PP_REPEAT_1_25(m, d) BOOST_PP_REPEAT_1_24(m, d) m(2, 24, d)
#define BOOST_PP_REPEAT_1_26(m, d) BOOST_PP_REPEAT_1_25(m, d) m(2, 25, d)
#define BOOST_PP_REPEAT_1_27(m, d) BOOST_PP_REPEAT_1_26(m, d) m(2, 26, d)
#define BOOST_PP_REPEAT_1_28(m, d) BOOST_PP_REPEAT_1_27(m, d) m(2, 27, d)
#define BOOST_PP_REPEAT_1_29(m, d) BOOST_PP_REPEAT_1_28(m, d) m(2, 28, d)
#define BOOST_PP_REPEAT_1_30(m, d) BOOST_PP_REPEAT_1_29(m, d) m(2, 29, d)
#define BOOST_PP_REPEAT_1_31(m, d) BOOST_PP_REPEAT_1_30(m, d) m(2, 30, d)
#define BOOST_PP_REPEAT_1_32(m, d) BOOST_PP_REPEAT_1_31(m, d) m(2, 31, d)
#define BOOST_PP_REPEAT_1_33(m, d) BOOST_PP_REPEAT_1_32(m, d) m(2, 32, d)
#define BOOST_PP_REPEAT_1_34(m, d) BOOST_PP_REPEAT_1_33(m, d) m(2, 33, d)
#define BOOST_PP_REPEAT_1_35(m, d) BOOST_PP_REPEAT_1_34(m, d) m(2, 34, d)
#define BOOST_PP_REPEAT_1_36(m, d) BOOST_PP_REPEAT_1_35(m, d) m(2, 35, d)
#define BOOST_PP_REPEAT_1_37(m, d) BOOST_PP_REPEAT_1_36(m, d) m(2, 36, d)
#define BOOST_PP_REPEAT_1_38(m, d) BOOST_PP_REPEAT_1_37(m, d) m(2, 37, d)
#define BOOST_PP_REPEAT_1_39(m, d) BOOST_PP_REPEAT_1_38(m, d) m(2, 38, d)
#define BOOST_PP_REPEAT_1_40(m, d) BOOST_PP_REPEAT_1_39(m, d) m(2, 39, d)
#define BOOST_PP_REPEAT_1_41(m, d) BOOST_PP_REPEAT_1_40(m, d) m(2, 40, d)
#define BOOST_PP_REPEAT_1_42(m, d) BOOST_PP_REPEAT_1_41(m, d) m(2, 41, d)
#define BOOST_PP_REPEAT_1_43(m, d) BOOST_PP_REPEAT_1_42(m, d) m(2, 42, d)
#define BOOST_PP_REPEAT_1_44(m, d) BOOST_PP_REPEAT_1_43(m, d) m(2, 43, d)
#define BOOST_PP_REPEAT_1_45(m, d) BOOST_PP_REPEAT_1_44(m, d) m(2, 44, d)
#define BOOST_PP_REPEAT_1_46(m, d) BOOST_PP_REPEAT_1_45(m, d) m(2, 45, d)
#define BOOST_PP_REPEAT_1_47(m, d) BOOST_PP_REPEAT_1_46(m, d) m(2, 46, d)
#define BOOST_PP_REPEAT_1_48(m, d) BOOST_PP_REPEAT_1_47(m, d) m(2, 47, d)
#define BOOST_PP_REPEAT_1_49(m, d) BOOST_PP_REPEAT_1_48(m, d) m(2, 48, d)
#define BOOST_PP_REPEAT_1_50(m, d) BOOST_PP_REPEAT_1_49(m, d) m(2, 49, d)
#define BOOST_PP_REPEAT_1_51(m, d) BOOST_PP_REPEAT_1_50(m, d) m(2, 50, d)
#define BOOST_PP_REPEAT_1_52(m, d) BOOST_PP_REPEAT_1_51(m, d) m(2, 51, d)
#define BOOST_PP_REPEAT_1_53(m, d) BOOST_PP_REPEAT_1_52(m, d) m(2, 52, d)
#define BOOST_PP_REPEAT_1_54(m, d) BOOST_PP_REPEAT_1_53(m, d) m(2, 53, d)
#define BOOST_PP_REPEAT_1_55(m, d) BOOST_PP_REPEAT_1_54(m, d) m(2, 54, d)
#define BOOST_PP_REPEAT_1_56(m, d) BOOST_PP_REPEAT_1_55(m, d) m(2, 55, d)
#define BOOST_PP_REPEAT_1_57(m, d) BOOST_PP_REPEAT_1_56(m, d) m(2, 56, d)
#define BOOST_PP_REPEAT_1_58(m, d) BOOST_PP_REPEAT_1_57(m, d) m(2, 57, d)
#define BOOST_PP_REPEAT_1_59(m, d) BOOST_PP_REPEAT_1_58(m, d) m(2, 58, d)
#define BOOST_PP_REPEAT_1_60(m, d) BOOST_PP_REPEAT_1_59(m, d) m(2, 59, d)
#define BOOST_PP_REPEAT_1_61(m, d) BOOST_PP_REPEAT_1_60(m, d) m(2, 60, d)
#define BOOST_PP_REPEAT_1_62(m, d) BOOST_PP_REPEAT_1_61(m, d) m(2, 61, d)
#define BOOST_PP_REPEAT_1_63(m, d) BOOST_PP_REPEAT_1_62(m, d) m(2, 62, d)
#define BOOST_PP_REPEAT_1_64(m, d) BOOST_PP_REPEAT_1_63(m, d) m(2, 63, d)
#define BOOST_PP_REPEAT_1_65(m, d) BOOST_PP_REPEAT_1_64(m, d) m(2, 64, d)
#define BOOST_PP_REPEAT_1_66(m, d) BOOST_PP_REPEAT_1_65(m, d) m(2, 65, d)
#define BOOST_PP_REPEAT_1_67(m, d) BOOST_PP_REPEAT_1_66(m, d) m(2, 66, d)
#define BOOST_PP_REPEAT_1_68(m, d) BOOST_PP_REPEAT_1_67(m, d) m(2, 67, d)
#define BOOST_PP_REPEAT_1_69(m, d) BOOST_PP_REPEAT_1_68(m, d) m(2, 68, d)
#define BOOST_PP_REPEAT_1_70(m, d) BOOST_PP_REPEAT_1_69(m, d) m(2, 69, d)
#define BOOST_PP_REPEAT_1_71(m, d) BOOST_PP_REPEAT_1_70(m, d) m(2, 70, d)
#define BOOST_PP_REPEAT_1_72(m, d) BOOST_PP_REPEAT_1_71(m, d) m(2, 71, d)
#define BOOST_PP_REPEAT_1_73(m, d) BOOST_PP_REPEAT_1_72(m, d) m(2, 72, d)
#define BOOST_PP_REPEAT_1_74(m, d) BOOST_PP_REPEAT_1_73(m, d) m(2, 73, d)
#define BOOST_PP_REPEAT_1_75(m, d) BOOST_PP_REPEAT_1_74(m, d) m(2, 74, d)
#define BOOST_PP_REPEAT_1_76(m, d) BOOST_PP_REPEAT_1_75(m, d) m(2, 75, d)
#define BOOST_PP_REPEAT_1_77(m, d) BOOST_PP_REPEAT_1_76(m, d) m(2, 76, d)
#define BOOST_PP_REPEAT_1_78(m, d) BOOST_PP_REPEAT_1_77(m, d) m(2, 77, d)
#define BOOST_PP_REPEAT_1_79(m, d) BOOST_PP_REPEAT_1_78(m, d) m(2, 78, d)
#define BOOST_PP_REPEAT_1_80(m, d) BOOST_PP_REPEAT_1_79(m, d) m(2, 79, d)
#define BOOST_PP_REPEAT_1_81(m, d) BOOST_PP_REPEAT_1_80(m, d) m(2, 80, d)
#define BOOST_PP_REPEAT_1_82(m, d) BOOST_PP_REPEAT_1_81(m, d) m(2, 81, d)
#define BOOST_PP_REPEAT_1_83(m, d) BOOST_PP_REPEAT_1_82(m, d) m(2, 82, d)
#define BOOST_PP_REPEAT_1_84(m, d) BOOST_PP_REPEAT_1_83(m, d) m(2, 83, d)
#define BOOST_PP_REPEAT_1_85(m, d) BOOST_PP_REPEAT_1_84(m, d) m(2, 84, d)
#define BOOST_PP_REPEAT_1_86(m, d) BOOST_PP_REPEAT_1_85(m, d) m(2, 85, d)
#define BOOST_PP_REPEAT_1_87(m, d) BOOST_PP_REPEAT_1_86(m, d) m(2, 86, d)
#define BOOST_PP_REPEAT_1_88(m, d) BOOST_PP_REPEAT_1_87(m, d) m(2, 87, d)
#define BOOST_PP_REPEAT_1_89(m, d) BOOST_PP_REPEAT_1_88(m, d) m(2, 88, d)
#define BOOST_PP_REPEAT_1_90(m, d) BOOST_PP_REPEAT_1_89(m, d) m(2, 89, d)
#define BOOST_PP_REPEAT_1_91(m, d) BOOST_PP_REPEAT_1_90(m, d) m(2, 90, d)
#define BOOST_PP_REPEAT_1_92(m, d) BOOST_PP_REPEAT_1_91(m, d) m(2, 91, d)
#define BOOST_PP_REPEAT_1_93(m, d) BOOST_PP_REPEAT_1_92(m, d) m(2, 92, d)
#define BOOST_PP_REPEAT_1_94(m, d) BOOST_PP_REPEAT_1_93(m, d) m(2, 93, d)
#define BOOST_PP_REPEAT_1_95(m, d) BOOST_PP_REPEAT_1_94(m, d) m(2, 94, d)
#define BOOST_PP_REPEAT_1_96(m, d) BOOST_PP_REPEAT_1_95(m, d) m(2, 95, d)
#define BOOST_PP_REPEAT_1_97(m, d) BOOST_PP_REPEAT_1_96(m, d) m(2, 96, d)
#define BOOST_PP_REPEAT_1_98(m, d) BOOST_PP_REPEAT_1_97(m, d) m(2, 97, d)
#define BOOST_PP_REPEAT_1_99(m, d) BOOST_PP_REPEAT_1_98(m, d) m(2, 98, d)
#define BOOST_PP_REPEAT_1_100(m, d) BOOST_PP_REPEAT_1_99(m, d) m(2, 99, d)
#define BOOST_PP_REPEAT_1_101(m, d) BOOST_PP_REPEAT_1_100(m, d) m(2, 100, d)
#define BOOST_PP_REPEAT_1_102(m, d) BOOST_PP_REPEAT_1_101(m, d) m(2, 101, d)
#define BOOST_PP_REPEAT_1_103(m, d) BOOST_PP_REPEAT_1_102(m, d) m(2, 102, d)
#define BOOST_PP_REPEAT_1_104(m, d) BOOST_PP_REPEAT_1_103(m, d) m(2, 103, d)
#define BOOST_PP_REPEAT_1_105(m, d) BOOST_PP_REPEAT_1_104(m, d) m(2, 104, d)
#define BOOST_PP_REPEAT_1_106(m, d) BOOST_PP_REPEAT_1_105(m, d) m(2, 105, d)
#define BOOST_PP_REPEAT_1_107(m, d) BOOST_PP_REPEAT_1_106(m, d) m(2, 106, d)
#define BOOST_PP_REPEAT_1_108(m, d) BOOST_PP_REPEAT_1_107(m, d) m(2, 107, d)
#define BOOST_PP_REPEAT_1_109(m, d) BOOST_PP_REPEAT_1_108(m, d) m(2, 108, d)
#define BOOST_PP_REPEAT_1_110(m, d) BOOST_PP_REPEAT_1_109(m, d) m(2, 109, d)
#define BOOST_PP_REPEAT_1_111(m, d) BOOST_PP_REPEAT_1_110(m, d) m(2, 110, d)
#define BOOST_PP_REPEAT_1_112(m, d) BOOST_PP_REPEAT_1_111(m, d) m(2, 111, d)
#define BOOST_PP_REPEAT_1_113(m, d) BOOST_PP_REPEAT_1_112(m, d) m(2, 112, d)
#define BOOST_PP_REPEAT_1_114(m, d) BOOST_PP_REPEAT_1_113(m, d) m(2, 113, d)
#define BOOST_PP_REPEAT_1_115(m, d) BOOST_PP_REPEAT_1_114(m, d) m(2, 114, d)
#define BOOST_PP_REPEAT_1_116(m, d) BOOST_PP_REPEAT_1_115(m, d) m(2, 115, d)
#define BOOST_PP_REPEAT_1_117(m, d) BOOST_PP_REPEAT_1_116(m, d) m(2, 116, d)
#define BOOST_PP_REPEAT_1_118(m, d) BOOST_PP_REPEAT_1_117(m, d) m(2, 117, d)
#define BOOST_PP_REPEAT_1_119(m, d) BOOST_PP_REPEAT_1_118(m, d) m(2, 118, d)
#define BOOST_PP_REPEAT_1_120(m, d) BOOST_PP_REPEAT_1_119(m, d) m(2, 119, d)
#define BOOST_PP_REPEAT_1_121(m, d) BOOST_PP_REPEAT_1_120(m, d) m(2, 120, d)
#define BOOST_PP_REPEAT_1_122(m, d) BOOST_PP_REPEAT_1_121(m, d) m(2, 121, d)
#define BOOST_PP_REPEAT_1_123(m, d) BOOST_PP_REPEAT_1_122(m, d) m(2, 122, d)
#define BOOST_PP_REPEAT_1_124(m, d) BOOST_PP_REPEAT_1_123(m, d) m(2, 123, d)
#define BOOST_PP_REPEAT_1_125(m, d) BOOST_PP_REPEAT_1_124(m, d) m(2, 124, d)
#define BOOST_PP_REPEAT_1_126(m, d) BOOST_PP_REPEAT_1_125(m, d) m(2, 125, d)
#define BOOST_PP_REPEAT_1_127(m, d) BOOST_PP_REPEAT_1_126(m, d) m(2, 126, d)
#define BOOST_PP_REPEAT_1_128(m, d) BOOST_PP_REPEAT_1_127(m, d) m(2, 127, d)
#define BOOST_PP_REPEAT_1_129(m, d) BOOST_PP_REPEAT_1_128(m, d) m(2, 128, d)
#define BOOST_PP_REPEAT_1_130(m, d) BOOST_PP_REPEAT_1_129(m, d) m(2, 129, d)
#define BOOST_PP_REPEAT_1_131(m, d) BOOST_PP_REPEAT_1_130(m, d) m(2, 130, d)
#define BOOST_PP_REPEAT_1_132(m, d) BOOST_PP_REPEAT_1_131(m, d) m(2, 131, d)
#define BOOST_PP_REPEAT_1_133(m, d) BOOST_PP_REPEAT_1_132(m, d) m(2, 132, d)
#define BOOST_PP_REPEAT_1_134(m, d) BOOST_PP_REPEAT_1_133(m, d) m(2, 133, d)
#define BOOST_PP_REPEAT_1_135(m, d) BOOST_PP_REPEAT_1_134(m, d) m(2, 134, d)
#define BOOST_PP_REPEAT_1_136(m, d) BOOST_PP_REPEAT_1_135(m, d) m(2, 135, d)
#define BOOST_PP_REPEAT_1_137(m, d) BOOST_PP_REPEAT_1_136(m, d) m(2, 136, d)
#define BOOST_PP_REPEAT_1_138(m, d) BOOST_PP_REPEAT_1_137(m, d) m(2, 137, d)
#define BOOST_PP_REPEAT_1_139(m, d) BOOST_PP_REPEAT_1_138(m, d) m(2, 138, d)
#define BOOST_PP_REPEAT_1_140(m, d) BOOST_PP_REPEAT_1_139(m, d) m(2, 139, d)
#define BOOST_PP_REPEAT_1_141(m, d) BOOST_PP_REPEAT_1_140(m, d) m(2, 140, d)
#define BOOST_PP_REPEAT_1_142(m, d) BOOST_PP_REPEAT_1_141(m, d) m(2, 141, d)
#define BOOST_PP_REPEAT_1_143(m, d) BOOST_PP_REPEAT_1_142(m, d) m(2, 142, d)
#define BOOST_PP_REPEAT_1_144(m, d) BOOST_PP_REPEAT_1_143(m, d) m(2, 143, d)
#define BOOST_PP_REPEAT_1_145(m, d) BOOST_PP_REPEAT_1_144(m, d) m(2, 144, d)
#define BOOST_PP_REPEAT_1_146(m, d) BOOST_PP_REPEAT_1_145(m, d) m(2, 145, d)
#define BOOST_PP_REPEAT_1_147(m, d) BOOST_PP_REPEAT_1_146(m, d) m(2, 146, d)
#define BOOST_PP_REPEAT_1_148(m, d) BOOST_PP_REPEAT_1_147(m, d) m(2, 147, d)
#define BOOST_PP_REPEAT_1_149(m, d) BOOST_PP_REPEAT_1_148(m, d) m(2, 148, d)
#define BOOST_PP_REPEAT_1_150(m, d) BOOST_PP_REPEAT_1_149(m, d) m(2, 149, d)
#define BOOST_PP_REPEAT_1_151(m, d) BOOST_PP_REPEAT_1_150(m, d) m(2, 150, d)
#define BOOST_PP_REPEAT_1_152(m, d) BOOST_PP_REPEAT_1_151(m, d) m(2, 151, d)
#define BOOST_PP_REPEAT_1_153(m, d) BOOST_PP_REPEAT_1_152(m, d) m(2, 152, d)
#define BOOST_PP_REPEAT_1_154(m, d) BOOST_PP_REPEAT_1_153(m, d) m(2, 153, d)
#define BOOST_PP_REPEAT_1_155(m, d) BOOST_PP_REPEAT_1_154(m, d) m(2, 154, d)
#define BOOST_PP_REPEAT_1_156(m, d) BOOST_PP_REPEAT_1_155(m, d) m(2, 155, d)
#define BOOST_PP_REPEAT_1_157(m, d) BOOST_PP_REPEAT_1_156(m, d) m(2, 156, d)
#define BOOST_PP_REPEAT_1_158(m, d) BOOST_PP_REPEAT_1_157(m, d) m(2, 157, d)
#define BOOST_PP_REPEAT_1_159(m, d) BOOST_PP_REPEAT_1_158(m, d) m(2, 158, d)
#define BOOST_PP_REPEAT_1_160(m, d) BOOST_PP_REPEAT_1_159(m, d) m(2, 159, d)
#define BOOST_PP_REPEAT_1_161(m, d) BOOST_PP_REPEAT_1_160(m, d) m(2, 160, d)
#define BOOST_PP_REPEAT_1_162(m, d) BOOST_PP_REPEAT_1_161(m, d) m(2, 161, d)
#define BOOST_PP_REPEAT_1_163(m, d) BOOST_PP_REPEAT_1_162(m, d) m(2, 162, d)
#define BOOST_PP_REPEAT_1_164(m, d) BOOST_PP_REPEAT_1_163(m, d) m(2, 163, d)
#define BOOST_PP_REPEAT_1_165(m, d) BOOST_PP_REPEAT_1_164(m, d) m(2, 164, d)
#define BOOST_PP_REPEAT_1_166(m, d) BOOST_PP_REPEAT_1_165(m, d) m(2, 165, d)
#define BOOST_PP_REPEAT_1_167(m, d) BOOST_PP_REPEAT_1_166(m, d) m(2, 166, d)
#define BOOST_PP_REPEAT_1_168(m, d) BOOST_PP_REPEAT_1_167(m, d) m(2, 167, d)
#define BOOST_PP_REPEAT_1_169(m, d) BOOST_PP_REPEAT_1_168(m, d) m(2, 168, d)
#define BOOST_PP_REPEAT_1_170(m, d) BOOST_PP_REPEAT_1_169(m, d) m(2, 169, d)
#define BOOST_PP_REPEAT_1_171(m, d) BOOST_PP_REPEAT_1_170(m, d) m(2, 170, d)
#define BOOST_PP_REPEAT_1_172(m, d) BOOST_PP_REPEAT_1_171(m, d) m(2, 171, d)
#define BOOST_PP_REPEAT_1_173(m, d) BOOST_PP_REPEAT_1_172(m, d) m(2, 172, d)
#define BOOST_PP_REPEAT_1_174(m, d) BOOST_PP_REPEAT_1_173(m, d) m(2, 173, d)
#define BOOST_PP_REPEAT_1_175(m, d) BOOST_PP_REPEAT_1_174(m, d) m(2, 174, d)
#define BOOST_PP_REPEAT_1_176(m, d) BOOST_PP_REPEAT_1_175(m, d) m(2, 175, d)
#define BOOST_PP_REPEAT_1_177(m, d) BOOST_PP_REPEAT_1_176(m, d) m(2, 176, d)
#define BOOST_PP_REPEAT_1_178(m, d) BOOST_PP_REPEAT_1_177(m, d) m(2, 177, d)
#define BOOST_PP_REPEAT_1_179(m, d) BOOST_PP_REPEAT_1_178(m, d) m(2, 178, d)
#define BOOST_PP_REPEAT_1_180(m, d) BOOST_PP_REPEAT_1_179(m, d) m(2, 179, d)
#define BOOST_PP_REPEAT_1_181(m, d) BOOST_PP_REPEAT_1_180(m, d) m(2, 180, d)
#define BOOST_PP_REPEAT_1_182(m, d) BOOST_PP_REPEAT_1_181(m, d) m(2, 181, d)
#define BOOST_PP_REPEAT_1_183(m, d) BOOST_PP_REPEAT_1_182(m, d) m(2, 182, d)
#define BOOST_PP_REPEAT_1_184(m, d) BOOST_PP_REPEAT_1_183(m, d) m(2, 183, d)
#define BOOST_PP_REPEAT_1_185(m, d) BOOST_PP_REPEAT_1_184(m, d) m(2, 184, d)
#define BOOST_PP_REPEAT_1_186(m, d) BOOST_PP_REPEAT_1_185(m, d) m(2, 185, d)
#define BOOST_PP_REPEAT_1_187(m, d) BOOST_PP_REPEAT_1_186(m, d) m(2, 186, d)
#define BOOST_PP_REPEAT_1_188(m, d) BOOST_PP_REPEAT_1_187(m, d) m(2, 187, d)
#define BOOST_PP_REPEAT_1_189(m, d) BOOST_PP_REPEAT_1_188(m, d) m(2, 188, d)
#define BOOST_PP_REPEAT_1_190(m, d) BOOST_PP_REPEAT_1_189(m, d) m(2, 189, d)
#define BOOST_PP_REPEAT_1_191(m, d) BOOST_PP_REPEAT_1_190(m, d) m(2, 190, d)
#define BOOST_PP_REPEAT_1_192(m, d) BOOST_PP_REPEAT_1_191(m, d) m(2, 191, d)
#define BOOST_PP_REPEAT_1_193(m, d) BOOST_PP_REPEAT_1_192(m, d) m(2, 192, d)
#define BOOST_PP_REPEAT_1_194(m, d) BOOST_PP_REPEAT_1_193(m, d) m(2, 193, d)
#define BOOST_PP_REPEAT_1_195(m, d) BOOST_PP_REPEAT_1_194(m, d) m(2, 194, d)
#define BOOST_PP_REPEAT_1_196(m, d) BOOST_PP_REPEAT_1_195(m, d) m(2, 195, d)
#define BOOST_PP_REPEAT_1_197(m, d) BOOST_PP_REPEAT_1_196(m, d) m(2, 196, d)
#define BOOST_PP_REPEAT_1_198(m, d) BOOST_PP_REPEAT_1_197(m, d) m(2, 197, d)
#define BOOST_PP_REPEAT_1_199(m, d) BOOST_PP_REPEAT_1_198(m, d) m(2, 198, d)
#define BOOST_PP_REPEAT_1_200(m, d) BOOST_PP_REPEAT_1_199(m, d) m(2, 199, d)
#define BOOST_PP_REPEAT_1_201(m, d) BOOST_PP_REPEAT_1_200(m, d) m(2, 200, d)
#define BOOST_PP_REPEAT_1_202(m, d) BOOST_PP_REPEAT_1_201(m, d) m(2, 201, d)
#define BOOST_PP_REPEAT_1_203(m, d) BOOST_PP_REPEAT_1_202(m, d) m(2, 202, d)
#define BOOST_PP_REPEAT_1_204(m, d) BOOST_PP_REPEAT_1_203(m, d) m(2, 203, d)
#define BOOST_PP_REPEAT_1_205(m, d) BOOST_PP_REPEAT_1_204(m, d) m(2, 204, d)
#define BOOST_PP_REPEAT_1_206(m, d) BOOST_PP_REPEAT_1_205(m, d) m(2, 205, d)
#define BOOST_PP_REPEAT_1_207(m, d) BOOST_PP_REPEAT_1_206(m, d) m(2, 206, d)
#define BOOST_PP_REPEAT_1_208(m, d) BOOST_PP_REPEAT_1_207(m, d) m(2, 207, d)
#define BOOST_PP_REPEAT_1_209(m, d) BOOST_PP_REPEAT_1_208(m, d) m(2, 208, d)
#define BOOST_PP_REPEAT_1_210(m, d) BOOST_PP_REPEAT_1_209(m, d) m(2, 209, d)
#define BOOST_PP_REPEAT_1_211(m, d) BOOST_PP_REPEAT_1_210(m, d) m(2, 210, d)
#define BOOST_PP_REPEAT_1_212(m, d) BOOST_PP_REPEAT_1_211(m, d) m(2, 211, d)
#define BOOST_PP_REPEAT_1_213(m, d) BOOST_PP_REPEAT_1_212(m, d) m(2, 212, d)
#define BOOST_PP_REPEAT_1_214(m, d) BOOST_PP_REPEAT_1_213(m, d) m(2, 213, d)
#define BOOST_PP_REPEAT_1_215(m, d) BOOST_PP_REPEAT_1_214(m, d) m(2, 214, d)
#define BOOST_PP_REPEAT_1_216(m, d) BOOST_PP_REPEAT_1_215(m, d) m(2, 215, d)
#define BOOST_PP_REPEAT_1_217(m, d) BOOST_PP_REPEAT_1_216(m, d) m(2, 216, d)
#define BOOST_PP_REPEAT_1_218(m, d) BOOST_PP_REPEAT_1_217(m, d) m(2, 217, d)
#define BOOST_PP_REPEAT_1_219(m, d) BOOST_PP_REPEAT_1_218(m, d) m(2, 218, d)
#define BOOST_PP_REPEAT_1_220(m, d) BOOST_PP_REPEAT_1_219(m, d) m(2, 219, d)
#define BOOST_PP_REPEAT_1_221(m, d) BOOST_PP_REPEAT_1_220(m, d) m(2, 220, d)
#define BOOST_PP_REPEAT_1_222(m, d) BOOST_PP_REPEAT_1_221(m, d) m(2, 221, d)
#define BOOST_PP_REPEAT_1_223(m, d) BOOST_PP_REPEAT_1_222(m, d) m(2, 222, d)
#define BOOST_PP_REPEAT_1_224(m, d) BOOST_PP_REPEAT_1_223(m, d) m(2, 223, d)
#define BOOST_PP_REPEAT_1_225(m, d) BOOST_PP_REPEAT_1_224(m, d) m(2, 224, d)
#define BOOST_PP_REPEAT_1_226(m, d) BOOST_PP_REPEAT_1_225(m, d) m(2, 225, d)
#define BOOST_PP_REPEAT_1_227(m, d) BOOST_PP_REPEAT_1_226(m, d) m(2, 226, d)
#define BOOST_PP_REPEAT_1_228(m, d) BOOST_PP_REPEAT_1_227(m, d) m(2, 227, d)
#define BOOST_PP_REPEAT_1_229(m, d) BOOST_PP_REPEAT_1_228(m, d) m(2, 228, d)
#define BOOST_PP_REPEAT_1_230(m, d) BOOST_PP_REPEAT_1_229(m, d) m(2, 229, d)
#define BOOST_PP_REPEAT_1_231(m, d) BOOST_PP_REPEAT_1_230(m, d) m(2, 230, d)
#define BOOST_PP_REPEAT_1_232(m, d) BOOST_PP_REPEAT_1_231(m, d) m(2, 231, d)
#define BOOST_PP_REPEAT_1_233(m, d) BOOST_PP_REPEAT_1_232(m, d) m(2, 232, d)
#define BOOST_PP_REPEAT_1_234(m, d) BOOST_PP_REPEAT_1_233(m, d) m(2, 233, d)
#define BOOST_PP_REPEAT_1_235(m, d) BOOST_PP_REPEAT_1_234(m, d) m(2, 234, d)
#define BOOST_PP_REPEAT_1_236(m, d) BOOST_PP_REPEAT_1_235(m, d) m(2, 235, d)
#define BOOST_PP_REPEAT_1_237(m, d) BOOST_PP_REPEAT_1_236(m, d) m(2, 236, d)
#define BOOST_PP_REPEAT_1_238(m, d) BOOST_PP_REPEAT_1_237(m, d) m(2, 237, d)
#define BOOST_PP_REPEAT_1_239(m, d) BOOST_PP_REPEAT_1_238(m, d) m(2, 238, d)
#define BOOST_PP_REPEAT_1_240(m, d) BOOST_PP_REPEAT_1_239(m, d) m(2, 239, d)
#define BOOST_PP_REPEAT_1_241(m, d) BOOST_PP_REPEAT_1_240(m, d) m(2, 240, d)
#define BOOST_PP_REPEAT_1_242(m, d) BOOST_PP_REPEAT_1_241(m, d) m(2, 241, d)
#define BOOST_PP_REPEAT_1_243(m, d) BOOST_PP_REPEAT_1_242(m, d) m(2, 242, d)
#define BOOST_PP_REPEAT_1_244(m, d) BOOST_PP_REPEAT_1_243(m, d) m(2, 243, d)
#define BOOST_PP_REPEAT_1_245(m, d) BOOST_PP_REPEAT_1_244(m, d) m(2, 244, d)
#define BOOST_PP_REPEAT_1_246(m, d) BOOST_PP_REPEAT_1_245(m, d) m(2, 245, d)
#define BOOST_PP_REPEAT_1_247(m, d) BOOST_PP_REPEAT_1_246(m, d) m(2, 246, d)
#define BOOST_PP_REPEAT_1_248(m, d) BOOST_PP_REPEAT_1_247(m, d) m(2, 247, d)
#define BOOST_PP_REPEAT_1_249(m, d) BOOST_PP_REPEAT_1_248(m, d) m(2, 248, d)
#define BOOST_PP_REPEAT_1_250(m, d) BOOST_PP_REPEAT_1_249(m, d) m(2, 249, d)
#define BOOST_PP_REPEAT_1_251(m, d) BOOST_PP_REPEAT_1_250(m, d) m(2, 250, d)
#define BOOST_PP_REPEAT_1_252(m, d) BOOST_PP_REPEAT_1_251(m, d) m(2, 251, d)
#define BOOST_PP_REPEAT_1_253(m, d) BOOST_PP_REPEAT_1_252(m, d) m(2, 252, d)
#define BOOST_PP_REPEAT_1_254(m, d) BOOST_PP_REPEAT_1_253(m, d) m(2, 253, d)
#define BOOST_PP_REPEAT_1_255(m, d) BOOST_PP_REPEAT_1_254(m, d) m(2, 254, d)
#define BOOST_PP_REPEAT_1_256(m, d) BOOST_PP_REPEAT_1_255(m, d) m(2, 255, d)

#define BOOST_PP_REPEAT_2_0(m, d)
#define BOOST_PP_REPEAT_2_1(m, d) m(3, 0, d)
#define BOOST_PP_REPEAT_2_2(m, d) BOOST_PP_REPEAT_2_1(m, d) m(3, 1, d)
#define BOOST_PP_REPEAT_2_3(m, d) BOOST_PP_REPEAT_2_2(m, d) m(3, 2, d)
#define BOOST_PP_REPEAT_2_4(m, d) BOOST_PP_REPEAT_2_3(m, d) m(3, 3, d)
#define BOOST_PP_REPEAT_2_5(m, d) BOOST_PP_REPEAT_2_4(m, d) m(3, 4, d)
#define BOOST_PP_REPEAT_2_6(m, d) BOOST_PP_REPEAT_2_5(m, d) m(3, 5, d)
#define BOOST_PP_REPEAT_2_7(m, d) BOOST_PP_REPEAT_2_6(m, d) m(3, 6, d)
#define BOOST_PP_REPEAT_2_8(m, d) BOOST_PP_REPEAT_2_7(m, d) m(3, 7, d)
#define BOOST_PP_REPEAT_2_9(m, d) BOOST_PP_REPEAT_2_8(m, d) m(3, 8, d)
#define BOOST_PP_REPEAT_2_10(m, d) BOOST_PP_REPEAT_2_9(m, d) m(3, 9, d)
#define BOOST_PP_REPEAT_2_11(m, d) BOOST_PP_REPEAT_2_10(m, d) m(3, 10, d)
#define BOOST_PP_REPEAT_2_12(m, d) BOOST_PP_REPEAT_2_11(m, d) m(3, 11, d)
#define BOOST_PP_REPEAT_2_13(m, d) BOOST_PP_REPEAT_2_12(m, d) m(3, 12, d)
#define BOOST_PP_REPEAT_2_14(m, d) BOOST_PP_REPEAT_2_13(m, d) m(3, 13, d)
#define BOOST_PP_REPEAT_2_15(m, d) BOOST_PP_REPEAT_2_14(m, d) m(3, 14, d)
#define BOOST_PP_REPEAT_2_16(m, d) BOOST_PP_REPEAT_2_15(m, d) m(3, 15, d)
#define BOOST_PP_REPEAT_2_17(m, d) BOOST_PP_REPEAT_2_16(m, d) m(3, 16, d)
#define BOOST_PP_REPEAT_2_18(m, d) BOOST_PP_REPEAT_2_17(m, d) m(3, 17, d)
#define BOOST_PP_REPEAT_2_19(m, d) BOOST_PP_REPEAT_2_18(m, d) m(3, 18, d)
#define BOOST_PP_REPEAT_2_20(m, d) BOOST_PP_REPEAT_2_19(m, d) m(3, 19, d)
#define BOOST_PP_REPEAT_2_21(m, d) BOOST_PP_REPEAT_2_20(m, d) m(3, 20, d)
#define BOOST_PP_REPEAT_2_22(m, d) BOOST_PP_REPEAT_2_21(m, d) m(3, 21, d)
#define BOOST_PP_REPEAT_2_23(m, d) BOOST_PP_REPEAT_2_22(m, d) m(3, 22, d)
#define BOOST_PP_REPEAT_2_24(m, d) BOOST_PP_REPEAT_2_23(m, d) m(3, 23, d)
#define BOOST_PP_REPEAT_2_25(m, d) BOOST_PP_REPEAT_2_24(m, d) m(3, 24, d)
#define BOOST_PP_REPEAT_2_26(m, d) BOOST_PP_REPEAT_2_25(m, d) m(3, 25, d)
#define BOOST_PP_REPEAT_2_27(m, d) BOOST_PP_REPEAT_2_26(m, d) m(3, 26, d)
#define BOOST_PP_REPEAT_2_28(m, d) BOOST_PP_REPEAT_2_27(m, d) m(3, 27, d)
#define BOOST_PP_REPEAT_2_29(m, d) BOOST_PP_REPEAT_2_28(m, d) m(3, 28, d)
#define BOOST_PP_REPEAT_2_30(m, d) BOOST_PP_REPEAT_2_29(m, d) m(3, 29, d)
#define BOOST_PP_REPEAT_2_31(m, d) BOOST_PP_REPEAT_2_30(m, d) m(3, 30, d)
#define BOOST_PP_REPEAT_2_32(m, d) BOOST_PP_REPEAT_2_31(m, d) m(3, 31, d)
#define BOOST_PP_REPEAT_2_33(m, d) BOOST_PP_REPEAT_2_32(m, d) m(3, 32, d)
#define BOOST_PP_REPEAT_2_34(m, d) BOOST_PP_REPEAT_2_33(m, d) m(3, 33, d)
#define BOOST_PP_REPEAT_2_35(m, d) BOOST_PP_REPEAT_2_34(m, d) m(3, 34, d)
#define BOOST_PP_REPEAT_2_36(m, d) BOOST_PP_REPEAT_2_35(m, d) m(3, 35, d)
#define BOOST_PP_REPEAT_2_37(m, d) BOOST_PP_REPEAT_2_36(m, d) m(3, 36, d)
#define BOOST_PP_REPEAT_2_38(m, d) BOOST_PP_REPEAT_2_37(m, d) m(3, 37, d)
#define BOOST_PP_REPEAT_2_39(m, d) BOOST_PP_REPEAT_2_38(m, d) m(3, 38, d)
#define BOOST_PP_REPEAT_2_40(m, d) BOOST_PP_REPEAT_2_39(m, d) m(3, 39, d)
#define BOOST_PP_REPEAT_2_41(m, d) BOOST_PP_REPEAT_2_40(m, d) m(3, 40, d)
#define BOOST_PP_REPEAT_2_42(m, d) BOOST_PP_REPEAT_2_41(m, d) m(3, 41, d)
#define BOOST_PP_REPEAT_2_43(m, d) BOOST_PP_REPEAT_2_42(m, d) m(3, 42, d)
#define BOOST_PP_REPEAT_2_44(m, d) BOOST_PP_REPEAT_2_43(m, d) m(3, 43, d)
#define BOOST_PP_REPEAT_2_45(m, d) BOOST_PP_REPEAT_2_44(m, d) m(3, 44, d)
#define BOOST_PP_REPEAT_2_46(m, d) BOOST_PP_REPEAT_2_45(m, d) m(3, 45, d)
#define BOOST_PP_REPEAT_2_47(m, d) BOOST_PP_REPEAT_2_46(m, d) m(3, 46, d)
#define BOOST_PP_REPEAT_2_48(m, d) BOOST_PP_REPEAT_2_47(m, d) m(3, 47, d)
#define BOOST_PP_REPEAT_2_49(m, d) BOOST_PP_REPEAT_2_48(m, d) m(3, 48, d)
#define BOOST_PP_REPEAT_2_50(m, d) BOOST_PP_REPEAT_2_49(m, d) m(3, 49, d)
#define BOOST_PP_REPEAT_2_51(m, d) BOOST_PP_REPEAT_2_50(m, d) m(3, 50, d)
#define BOOST_PP_REPEAT_2_52(m, d) BOOST_PP_REPEAT_2_51(m, d) m(3, 51, d)
#define BOOST_PP_REPEAT_2_53(m, d) BOOST_PP_REPEAT_2_52(m, d) m(3, 52, d)
#define BOOST_PP_REPEAT_2_54(m, d) BOOST_PP_REPEAT_2_53(m, d) m(3, 53, d)
#define BOOST_PP_REPEAT_2_55(m, d) BOOST_PP_REPEAT_2_54(m, d) m(3, 54, d)
#define BOOST_PP_REPEAT_2_56(m, d) BOOST_PP_REPEAT_2_55(m, d) m(3, 55, d)
#define BOOST_PP_REPEAT_2_57(m, d) BOOST_PP_REPEAT_2_56(m, d) m(3, 56, d)
#define BOOST_PP_REPEAT_2_58(m, d) BOOST_PP_REPEAT_2_57(m, d) m(3, 57, d)
#define BOOST_PP_REPEAT_2_59(m, d) BOOST_PP_REPEAT_2_58(m, d) m(3, 58, d)
#define BOOST_PP_REPEAT_2_60(m, d) BOOST_PP_REPEAT_2_59(m, d) m(3, 59, d)
#define BOOST_PP_REPEAT_2_61(m, d) BOOST_PP_REPEAT_2_60(m, d) m(3, 60, d)
#define BOOST_PP_REPEAT_2_62(m, d) BOOST_PP_REPEAT_2_61(m, d) m(3, 61, d)
#define BOOST_PP_REPEAT_2_63(m, d) BOOST_PP_REPEAT_2_62(m, d) m(3, 62, d)
#define BOOST_PP_REPEAT_2_64(m, d) BOOST_PP_REPEAT_2_63(m, d) m(3, 63, d)
#define BOOST_PP_REPEAT_2_65(m, d) BOOST_PP_REPEAT_2_64(m, d) m(3, 64, d)
#define BOOST_PP_REPEAT_2_66(m, d) BOOST_PP_REPEAT_2_65(m, d) m(3, 65, d)
#define BOOST_PP_REPEAT_2_67(m, d) BOOST_PP_REPEAT_2_66(m, d) m(3, 66, d)
#define BOOST_PP_REPEAT_2_68(m, d) BOOST_PP_REPEAT_2_67(m, d) m(3, 67, d)
#define BOOST_PP_REPEAT_2_69(m, d) BOOST_PP_REPEAT_2_68(m, d) m(3, 68, d)
#define BOOST_PP_REPEAT_2_70(m, d) BOOST_PP_REPEAT_2_69(m, d) m(3, 69, d)
#define BOOST_PP_REPEAT_2_71(m, d) BOOST_PP_REPEAT_2_70(m, d) m(3, 70, d)
#define BOOST_PP_REPEAT_2_72(m, d) BOOST_PP_REPEAT_2_71(m, d) m(3, 71, d)
#define BOOST_PP_REPEAT_2_73(m, d) BOOST_PP_REPEAT_2_72(m, d) m(3, 72, d)
#define BOOST_PP_REPEAT_2_74(m, d) BOOST_PP_REPEAT_2_73(m, d) m(3, 73, d)
#define BOOST_PP_REPEAT_2_75(m, d) BOOST_PP_REPEAT_2_74(m, d) m(3, 74, d)
#define BOOST_PP_REPEAT_2_76(m, d) BOOST_PP_REPEAT_2_75(m, d) m(3, 75, d)
#define BOOST_PP_REPEAT_2_77(m, d) BOOST_PP_REPEAT_2_76(m, d) m(3, 76, d)
#define BOOST_PP_REPEAT_2_78(m, d) BOOST_PP_REPEAT_2_77(m, d) m(3, 77, d)
#define BOOST_PP_REPEAT_2_79(m, d) BOOST_PP_REPEAT_2_78(m, d) m(3, 78, d)
#define BOOST_PP_REPEAT_2_80(m, d) BOOST_PP_REPEAT_2_79(m, d) m(3, 79, d)
#define BOOST_PP_REPEAT_2_81(m, d) BOOST_PP_REPEAT_2_80(m, d) m(3, 80, d)
#define BOOST_PP_REPEAT_2_82(m, d) BOOST_PP_REPEAT_2_81(m, d) m(3, 81, d)
#define BOOST_PP_REPEAT_2_83(m, d) BOOST_PP_REPEAT_2_82(m, d) m(3, 82, d)
#define BOOST_PP_REPEAT_2_84(m, d) BOOST_PP_REPEAT_2_83(m, d) m(3, 83, d)
#define BOOST_PP_REPEAT_2_85(m, d) BOOST_PP_REPEAT_2_84(m, d) m(3, 84, d)
#define BOOST_PP_REPEAT_2_86(m, d) BOOST_PP_REPEAT_2_85(m, d) m(3, 85, d)
#define BOOST_PP_REPEAT_2_87(m, d) BOOST_PP_REPEAT_2_86(m, d) m(3, 86, d)
#define BOOST_PP_REPEAT_2_88(m, d) BOOST_PP_REPEAT_2_87(m, d) m(3, 87, d)
#define BOOST_PP_REPEAT_2_89(m, d) BOOST_PP_REPEAT_2_88(m, d) m(3, 88, d)
#define BOOST_PP_REPEAT_2_90(m, d) BOOST_PP_REPEAT_2_89(m, d) m(3, 89, d)
#define BOOST_PP_REPEAT_2_91(m, d) BOOST_PP_REPEAT_2_90(m, d) m(3, 90, d)
#define BOOST_PP_REPEAT_2_92(m, d) BOOST_PP_REPEAT_2_91(m, d) m(3, 91, d)
#define BOOST_PP_REPEAT_2_93(m, d) BOOST_PP_REPEAT_2_92(m, d) m(3, 92, d)
#define BOOST_PP_REPEAT_2_94(m, d) BOOST_PP_REPEAT_2_93(m, d) m(3, 93, d)
#define BOOST_PP_REPEAT_2_95(m, d) BOOST_PP_REPEAT_2_94(m, d) m(3, 94, d)
#define BOOST_PP_REPEAT_2_96(m, d) BOOST_PP_REPEAT_2_95(m, d) m(3, 95, d)
#define BOOST_PP_REPEAT_2_97(m, d) BOOST_PP_REPEAT_2_96(m, d) m(3, 96, d)
#define BOOST_PP_REPEAT_2_98(m, d) BOOST_PP_REPEAT_2_97(m, d) m(3, 97, d)
#define BOOST_PP_REPEAT_2_99(m, d) BOOST_PP_REPEAT_2_98(m, d) m(3, 98, d)
#define BOOST_PP_REPEAT_2_100(m, d) BOOST_PP_REPEAT_2_99(m, d) m(3, 99, d)
#define BOOST_PP_REPEAT_2_101(m, d) BOOST_PP_REPEAT_2_100(m, d) m(3, 100, d)
#define BOOST_PP_REPEAT_2_102(m, d) BOOST_PP_REPEAT_2_101(m, d) m(3, 101, d)
#define BOOST_PP_REPEAT_2_103(m, d) BOOST_PP_REPEAT_2_102(m, d) m(3, 102, d)
#define BOOST_PP_REPEAT_2_104(m, d) BOOST_PP_REPEAT_2_103(m, d) m(3, 103, d)
#define BOOST_PP_REPEAT_2_105(m, d) BOOST_PP_REPEAT_2_104(m, d) m(3, 104, d)
#define BOOST_PP_REPEAT_2_106(m, d) BOOST_PP_REPEAT_2_105(m, d) m(3, 105, d)
#define BOOST_PP_REPEAT_2_107(m, d) BOOST_PP_REPEAT_2_106(m, d) m(3, 106, d)
#define BOOST_PP_REPEAT_2_108(m, d) BOOST_PP_REPEAT_2_107(m, d) m(3, 107, d)
#define BOOST_PP_REPEAT_2_109(m, d) BOOST_PP_REPEAT_2_108(m, d) m(3, 108, d)
#define BOOST_PP_REPEAT_2_110(m, d) BOOST_PP_REPEAT_2_109(m, d) m(3, 109, d)
#define BOOST_PP_REPEAT_2_111(m, d) BOOST_PP_REPEAT_2_110(m, d) m(3, 110, d)
#define BOOST_PP_REPEAT_2_112(m, d) BOOST_PP_REPEAT_2_111(m, d) m(3, 111, d)
#define BOOST_PP_REPEAT_2_113(m, d) BOOST_PP_REPEAT_2_112(m, d) m(3, 112, d)
#define BOOST_PP_REPEAT_2_114(m, d) BOOST_PP_REPEAT_2_113(m, d) m(3, 113, d)
#define BOOST_PP_REPEAT_2_115(m, d) BOOST_PP_REPEAT_2_114(m, d) m(3, 114, d)
#define BOOST_PP_REPEAT_2_116(m, d) BOOST_PP_REPEAT_2_115(m, d) m(3, 115, d)
#define BOOST_PP_REPEAT_2_117(m, d) BOOST_PP_REPEAT_2_116(m, d) m(3, 116, d)
#define BOOST_PP_REPEAT_2_118(m, d) BOOST_PP_REPEAT_2_117(m, d) m(3, 117, d)
#define BOOST_PP_REPEAT_2_119(m, d) BOOST_PP_REPEAT_2_118(m, d) m(3, 118, d)
#define BOOST_PP_REPEAT_2_120(m, d) BOOST_PP_REPEAT_2_119(m, d) m(3, 119, d)
#define BOOST_PP_REPEAT_2_121(m, d) BOOST_PP_REPEAT_2_120(m, d) m(3, 120, d)
#define BOOST_PP_REPEAT_2_122(m, d) BOOST_PP_REPEAT_2_121(m, d) m(3, 121, d)
#define BOOST_PP_REPEAT_2_123(m, d) BOOST_PP_REPEAT_2_122(m, d) m(3, 122, d)
#define BOOST_PP_REPEAT_2_124(m, d) BOOST_PP_REPEAT_2_123(m, d) m(3, 123, d)
#define BOOST_PP_REPEAT_2_125(m, d) BOOST_PP_REPEAT_2_124(m, d) m(3, 124, d)
#define BOOST_PP_REPEAT_2_126(m, d) BOOST_PP_REPEAT_2_125(m, d) m(3, 125, d)
#define BOOST_PP_REPEAT_2_127(m, d) BOOST_PP_REPEAT_2_126(m, d) m(3, 126, d)
#define BOOST_PP_REPEAT_2_128(m, d) BOOST_PP_REPEAT_2_127(m, d) m(3, 127, d)
#define BOOST_PP_REPEAT_2_129(m, d) BOOST_PP_REPEAT_2_128(m, d) m(3, 128, d)
#define BOOST_PP_REPEAT_2_130(m, d) BOOST_PP_REPEAT_2_129(m, d) m(3, 129, d)
#define BOOST_PP_REPEAT_2_131(m, d) BOOST_PP_REPEAT_2_130(m, d) m(3, 130, d)
#define BOOST_PP_REPEAT_2_132(m, d) BOOST_PP_REPEAT_2_131(m, d) m(3, 131, d)
#define BOOST_PP_REPEAT_2_133(m, d) BOOST_PP_REPEAT_2_132(m, d) m(3, 132, d)
#define BOOST_PP_REPEAT_2_134(m, d) BOOST_PP_REPEAT_2_133(m, d) m(3, 133, d)
#define BOOST_PP_REPEAT_2_135(m, d) BOOST_PP_REPEAT_2_134(m, d) m(3, 134, d)
#define BOOST_PP_REPEAT_2_136(m, d) BOOST_PP_REPEAT_2_135(m, d) m(3, 135, d)
#define BOOST_PP_REPEAT_2_137(m, d) BOOST_PP_REPEAT_2_136(m, d) m(3, 136, d)
#define BOOST_PP_REPEAT_2_138(m, d) BOOST_PP_REPEAT_2_137(m, d) m(3, 137, d)
#define BOOST_PP_REPEAT_2_139(m, d) BOOST_PP_REPEAT_2_138(m, d) m(3, 138, d)
#define BOOST_PP_REPEAT_2_140(m, d) BOOST_PP_REPEAT_2_139(m, d) m(3, 139, d)
#define BOOST_PP_REPEAT_2_141(m, d) BOOST_PP_REPEAT_2_140(m, d) m(3, 140, d)
#define BOOST_PP_REPEAT_2_142(m, d) BOOST_PP_REPEAT_2_141(m, d) m(3, 141, d)
#define BOOST_PP_REPEAT_2_143(m, d) BOOST_PP_REPEAT_2_142(m, d) m(3, 142, d)
#define BOOST_PP_REPEAT_2_144(m, d) BOOST_PP_REPEAT_2_143(m, d) m(3, 143, d)
#define BOOST_PP_REPEAT_2_145(m, d) BOOST_PP_REPEAT_2_144(m, d) m(3, 144, d)
#define BOOST_PP_REPEAT_2_146(m, d) BOOST_PP_REPEAT_2_145(m, d) m(3, 145, d)
#define BOOST_PP_REPEAT_2_147(m, d) BOOST_PP_REPEAT_2_146(m, d) m(3, 146, d)
#define BOOST_PP_REPEAT_2_148(m, d) BOOST_PP_REPEAT_2_147(m, d) m(3, 147, d)
#define BOOST_PP_REPEAT_2_149(m, d) BOOST_PP_REPEAT_2_148(m, d) m(3, 148, d)
#define BOOST_PP_REPEAT_2_150(m, d) BOOST_PP_REPEAT_2_149(m, d) m(3, 149, d)
#define BOOST_PP_REPEAT_2_151(m, d) BOOST_PP_REPEAT_2_150(m, d) m(3, 150, d)
#define BOOST_PP_REPEAT_2_152(m, d) BOOST_PP_REPEAT_2_151(m, d) m(3, 151, d)
#define BOOST_PP_REPEAT_2_153(m, d) BOOST_PP_REPEAT_2_152(m, d) m(3, 152, d)
#define BOOST_PP_REPEAT_2_154(m, d) BOOST_PP_REPEAT_2_153(m, d) m(3, 153, d)
#define BOOST_PP_REPEAT_2_155(m, d) BOOST_PP_REPEAT_2_154(m, d) m(3, 154, d)
#define BOOST_PP_REPEAT_2_156(m, d) BOOST_PP_REPEAT_2_155(m, d) m(3, 155, d)
#define BOOST_PP_REPEAT_2_157(m, d) BOOST_PP_REPEAT_2_156(m, d) m(3, 156, d)
#define BOOST_PP_REPEAT_2_158(m, d) BOOST_PP_REPEAT_2_157(m, d) m(3, 157, d)
#define BOOST_PP_REPEAT_2_159(m, d) BOOST_PP_REPEAT_2_158(m, d) m(3, 158, d)
#define BOOST_PP_REPEAT_2_160(m, d) BOOST_PP_REPEAT_2_159(m, d) m(3, 159, d)
#define BOOST_PP_REPEAT_2_161(m, d) BOOST_PP_REPEAT_2_160(m, d) m(3, 160, d)
#define BOOST_PP_REPEAT_2_162(m, d) BOOST_PP_REPEAT_2_161(m, d) m(3, 161, d)
#define BOOST_PP_REPEAT_2_163(m, d) BOOST_PP_REPEAT_2_162(m, d) m(3, 162, d)
#define BOOST_PP_REPEAT_2_164(m, d) BOOST_PP_REPEAT_2_163(m, d) m(3, 163, d)
#define BOOST_PP_REPEAT_2_165(m, d) BOOST_PP_REPEAT_2_164(m, d) m(3, 164, d)
#define BOOST_PP_REPEAT_2_166(m, d) BOOST_PP_REPEAT_2_165(m, d) m(3, 165, d)
#define BOOST_PP_REPEAT_2_167(m, d) BOOST_PP_REPEAT_2_166(m, d) m(3, 166, d)
#define BOOST_PP_REPEAT_2_168(m, d) BOOST_PP_REPEAT_2_167(m, d) m(3, 167, d)
#define BOOST_PP_REPEAT_2_169(m, d) BOOST_PP_REPEAT_2_168(m, d) m(3, 168, d)
#define BOOST_PP_REPEAT_2_170(m, d) BOOST_PP_REPEAT_2_169(m, d) m(3, 169, d)
#define BOOST_PP_REPEAT_2_171(m, d) BOOST_PP_REPEAT_2_170(m, d) m(3, 170, d)
#define BOOST_PP_REPEAT_2_172(m, d) BOOST_PP_REPEAT_2_171(m, d) m(3, 171, d)
#define BOOST_PP_REPEAT_2_173(m, d) BOOST_PP_REPEAT_2_172(m, d) m(3, 172, d)
#define BOOST_PP_REPEAT_2_174(m, d) BOOST_PP_REPEAT_2_173(m, d) m(3, 173, d)
#define BOOST_PP_REPEAT_2_175(m, d) BOOST_PP_REPEAT_2_174(m, d) m(3, 174, d)
#define BOOST_PP_REPEAT_2_176(m, d) BOOST_PP_REPEAT_2_175(m, d) m(3, 175, d)
#define BOOST_PP_REPEAT_2_177(m, d) BOOST_PP_REPEAT_2_176(m, d) m(3, 176, d)
#define BOOST_PP_REPEAT_2_178(m, d) BOOST_PP_REPEAT_2_177(m, d) m(3, 177, d)
#define BOOST_PP_REPEAT_2_179(m, d) BOOST_PP_REPEAT_2_178(m, d) m(3, 178, d)
#define BOOST_PP_REPEAT_2_180(m, d) BOOST_PP_REPEAT_2_179(m, d) m(3, 179, d)
#define BOOST_PP_REPEAT_2_181(m, d) BOOST_PP_REPEAT_2_180(m, d) m(3, 180, d)
#define BOOST_PP_REPEAT_2_182(m, d) BOOST_PP_REPEAT_2_181(m, d) m(3, 181, d)
#define BOOST_PP_REPEAT_2_183(m, d) BOOST_PP_REPEAT_2_182(m, d) m(3, 182, d)
#define BOOST_PP_REPEAT_2_184(m, d) BOOST_PP_REPEAT_2_183(m, d) m(3, 183, d)
#define BOOST_PP_REPEAT_2_185(m, d) BOOST_PP_REPEAT_2_184(m, d) m(3, 184, d)
#define BOOST_PP_REPEAT_2_186(m, d) BOOST_PP_REPEAT_2_185(m, d) m(3, 185, d)
#define BOOST_PP_REPEAT_2_187(m, d) BOOST_PP_REPEAT_2_186(m, d) m(3, 186, d)
#define BOOST_PP_REPEAT_2_188(m, d) BOOST_PP_REPEAT_2_187(m, d) m(3, 187, d)
#define BOOST_PP_REPEAT_2_189(m, d) BOOST_PP_REPEAT_2_188(m, d) m(3, 188, d)
#define BOOST_PP_REPEAT_2_190(m, d) BOOST_PP_REPEAT_2_189(m, d) m(3, 189, d)
#define BOOST_PP_REPEAT_2_191(m, d) BOOST_PP_REPEAT_2_190(m, d) m(3, 190, d)
#define BOOST_PP_REPEAT_2_192(m, d) BOOST_PP_REPEAT_2_191(m, d) m(3, 191, d)
#define BOOST_PP_REPEAT_2_193(m, d) BOOST_PP_REPEAT_2_192(m, d) m(3, 192, d)
#define BOOST_PP_REPEAT_2_194(m, d) BOOST_PP_REPEAT_2_193(m, d) m(3, 193, d)
#define BOOST_PP_REPEAT_2_195(m, d) BOOST_PP_REPEAT_2_194(m, d) m(3, 194, d)
#define BOOST_PP_REPEAT_2_196(m, d) BOOST_PP_REPEAT_2_195(m, d) m(3, 195, d)
#define BOOST_PP_REPEAT_2_197(m, d) BOOST_PP_REPEAT_2_196(m, d) m(3, 196, d)
#define BOOST_PP_REPEAT_2_198(m, d) BOOST_PP_REPEAT_2_197(m, d) m(3, 197, d)
#define BOOST_PP_REPEAT_2_199(m, d) BOOST_PP_REPEAT_2_198(m, d) m(3, 198, d)
#define BOOST_PP_REPEAT_2_200(m, d) BOOST_PP_REPEAT_2_199(m, d) m(3, 199, d)
#define BOOST_PP_REPEAT_2_201(m, d) BOOST_PP_REPEAT_2_200(m, d) m(3, 200, d)
#define BOOST_PP_REPEAT_2_202(m, d) BOOST_PP_REPEAT_2_201(m, d) m(3, 201, d)
#define BOOST_PP_REPEAT_2_203(m, d) BOOST_PP_REPEAT_2_202(m, d) m(3, 202, d)
#define BOOST_PP_REPEAT_2_204(m, d) BOOST_PP_REPEAT_2_203(m, d) m(3, 203, d)
#define BOOST_PP_REPEAT_2_205(m, d) BOOST_PP_REPEAT_2_204(m, d) m(3, 204, d)
#define BOOST_PP_REPEAT_2_206(m, d) BOOST_PP_REPEAT_2_205(m, d) m(3, 205, d)
#define BOOST_PP_REPEAT_2_207(m, d) BOOST_PP_REPEAT_2_206(m, d) m(3, 206, d)
#define BOOST_PP_REPEAT_2_208(m, d) BOOST_PP_REPEAT_2_207(m, d) m(3, 207, d)
#define BOOST_PP_REPEAT_2_209(m, d) BOOST_PP_REPEAT_2_208(m, d) m(3, 208, d)
#define BOOST_PP_REPEAT_2_210(m, d) BOOST_PP_REPEAT_2_209(m, d) m(3, 209, d)
#define BOOST_PP_REPEAT_2_211(m, d) BOOST_PP_REPEAT_2_210(m, d) m(3, 210, d)
#define BOOST_PP_REPEAT_2_212(m, d) BOOST_PP_REPEAT_2_211(m, d) m(3, 211, d)
#define BOOST_PP_REPEAT_2_213(m, d) BOOST_PP_REPEAT_2_212(m, d) m(3, 212, d)
#define BOOST_PP_REPEAT_2_214(m, d) BOOST_PP_REPEAT_2_213(m, d) m(3, 213, d)
#define BOOST_PP_REPEAT_2_215(m, d) BOOST_PP_REPEAT_2_214(m, d) m(3, 214, d)
#define BOOST_PP_REPEAT_2_216(m, d) BOOST_PP_REPEAT_2_215(m, d) m(3, 215, d)
#define BOOST_PP_REPEAT_2_217(m, d) BOOST_PP_REPEAT_2_216(m, d) m(3, 216, d)
#define BOOST_PP_REPEAT_2_218(m, d) BOOST_PP_REPEAT_2_217(m, d) m(3, 217, d)
#define BOOST_PP_REPEAT_2_219(m, d) BOOST_PP_REPEAT_2_218(m, d) m(3, 218, d)
#define BOOST_PP_REPEAT_2_220(m, d) BOOST_PP_REPEAT_2_219(m, d) m(3, 219, d)
#define BOOST_PP_REPEAT_2_221(m, d) BOOST_PP_REPEAT_2_220(m, d) m(3, 220, d)
#define BOOST_PP_REPEAT_2_222(m, d) BOOST_PP_REPEAT_2_221(m, d) m(3, 221, d)
#define BOOST_PP_REPEAT_2_223(m, d) BOOST_PP_REPEAT_2_222(m, d) m(3, 222, d)
#define BOOST_PP_REPEAT_2_224(m, d) BOOST_PP_REPEAT_2_223(m, d) m(3, 223, d)
#define BOOST_PP_REPEAT_2_225(m, d) BOOST_PP_REPEAT_2_224(m, d) m(3, 224, d)
#define BOOST_PP_REPEAT_2_226(m, d) BOOST_PP_REPEAT_2_225(m, d) m(3, 225, d)
#define BOOST_PP_REPEAT_2_227(m, d) BOOST_PP_REPEAT_2_226(m, d) m(3, 226, d)
#define BOOST_PP_REPEAT_2_228(m, d) BOOST_PP_REPEAT_2_227(m, d) m(3, 227, d)
#define BOOST_PP_REPEAT_2_229(m, d) BOOST_PP_REPEAT_2_228(m, d) m(3, 228, d)
#define BOOST_PP_REPEAT_2_230(m, d) BOOST_PP_REPEAT_2_229(m, d) m(3, 229, d)
#define BOOST_PP_REPEAT_2_231(m, d) BOOST_PP_REPEAT_2_230(m, d) m(3, 230, d)
#define BOOST_PP_REPEAT_2_232(m, d) BOOST_PP_REPEAT_2_231(m, d) m(3, 231, d)
#define BOOST_PP_REPEAT_2_233(m, d) BOOST_PP_REPEAT_2_232(m, d) m(3, 232, d)
#define BOOST_PP_REPEAT_2_234(m, d) BOOST_PP_REPEAT_2_233(m, d) m(3, 233, d)
#define BOOST_PP_REPEAT_2_235(m, d) BOOST_PP_REPEAT_2_234(m, d) m(3, 234, d)
#define BOOST_PP_REPEAT_2_236(m, d) BOOST_PP_REPEAT_2_235(m, d) m(3, 235, d)
#define BOOST_PP_REPEAT_2_237(m, d) BOOST_PP_REPEAT_2_236(m, d) m(3, 236, d)
#define BOOST_PP_REPEAT_2_238(m, d) BOOST_PP_REPEAT_2_237(m, d) m(3, 237, d)
#define BOOST_PP_REPEAT_2_239(m, d) BOOST_PP_REPEAT_2_238(m, d) m(3, 238, d)
#define BOOST_PP_REPEAT_2_240(m, d) BOOST_PP_REPEAT_2_239(m, d) m(3, 239, d)
#define BOOST_PP_REPEAT_2_241(m, d) BOOST_PP_REPEAT_2_240(m, d) m(3, 240, d)
#define BOOST_PP_REPEAT_2_242(m, d) BOOST_PP_REPEAT_2_241(m, d) m(3, 241, d)
#define BOOST_PP_REPEAT_2_243(m, d) BOOST_PP_REPEAT_2_242(m, d) m(3, 242, d)
#define BOOST_PP_REPEAT_2_244(m, d) BOOST_PP_REPEAT_2_243(m, d) m(3, 243, d)
#define BOOST_PP_REPEAT_2_245(m, d) BOOST_PP_REPEAT_2_244(m, d) m(3, 244, d)
#define BOOST_PP_REPEAT_2_246(m, d) BOOST_PP_REPEAT_2_245(m, d) m(3, 245, d)
#define BOOST_PP_REPEAT_2_247(m, d) BOOST_PP_REPEAT_2_246(m, d) m(3, 246, d)
#define BOOST_PP_REPEAT_2_248(m, d) BOOST_PP_REPEAT_2_247(m, d) m(3, 247, d)
#define BOOST_PP_REPEAT_2_249(m, d) BOOST_PP_REPEAT_2_248(m, d) m(3, 248, d)
#define BOOST_PP_REPEAT_2_250(m, d) BOOST_PP_REPEAT_2_249(m, d) m(3, 249, d)
#define BOOST_PP_REPEAT_2_251(m, d) BOOST_PP_REPEAT_2_250(m, d) m(3, 250, d)
#define BOOST_PP_REPEAT_2_252(m, d) BOOST_PP_REPEAT_2_251(m, d) m(3, 251, d)
#define BOOST_PP_REPEAT_2_253(m, d) BOOST_PP_REPEAT_2_252(m, d) m(3, 252, d)
#define BOOST_PP_REPEAT_2_254(m, d) BOOST_PP_REPEAT_2_253(m, d) m(3, 253, d)
#define BOOST_PP_REPEAT_2_255(m, d) BOOST_PP_REPEAT_2_254(m, d) m(3, 254, d)
#define BOOST_PP_REPEAT_2_256(m, d) BOOST_PP_REPEAT_2_255(m, d) m(3, 255, d)

#define BOOST_PP_REPEAT_3_0(m, d)
#define BOOST_PP_REPEAT_3_1(m, d) m(4, 0, d)
#define BOOST_PP_REPEAT_3_2(m, d) BOOST_PP_REPEAT_3_1(m, d) m(4, 1, d)
#define BOOST_PP_REPEAT_3_3(m, d) BOOST_PP_REPEAT_3_2(m, d) m(4, 2, d)
#define BOOST_PP_REPEAT_3_4(m, d) BOOST_PP_REPEAT_3_3(m, d) m(4, 3, d)
#define BOOST_PP_REPEAT_3_5(m, d) BOOST_PP_REPEAT_3_4(m, d) m(4, 4, d)
#define BOOST_PP_REPEAT_3_6(m, d) BOOST_PP_REPEAT_3_5(m, d) m(4, 5, d)
#define BOOST_PP_REPEAT_3_7(m, d) BOOST_PP_REPEAT_3_6(m, d) m(4, 6, d)
#define BOOST_PP_REPEAT_3_8(m, d) BOOST_PP_REPEAT_3_7(m, d) m(4, 7, d)
#define BOOST_PP_REPEAT_3_9(m, d) BOOST_PP_REPEAT_3_8(m, d) m(4, 8, d)
#define BOOST_PP_REPEAT_3_10(m, d) BOOST_PP_REPEAT_3_9(m, d) m(4, 9, d)
#define BOOST_PP_REPEAT_3_11(m, d) BOOST_PP_REPEAT_3_10(m, d) m(4, 10, d)
#define BOOST_PP_REPEAT_3_12(m, d) BOOST_PP_REPEAT_3_11(m, d) m(4, 11, d)
#define BOOST_PP_REPEAT_3_13(m, d) BOOST_PP_REPEAT_3_12(m, d) m(4, 12, d)
#define BOOST_PP_REPEAT_3_14(m, d) BOOST_PP_REPEAT_3_13(m, d) m(4, 13, d)
#define BOOST_PP_REPEAT_3_15(m, d) BOOST_PP_REPEAT_3_14(m, d) m(4, 14, d)
#define BOOST_PP_REPEAT_3_16(m, d) BOOST_PP_REPEAT_3_15(m, d) m(4, 15, d)
#define BOOST_PP_REPEAT_3_17(m, d) BOOST_PP_REPEAT_3_16(m, d) m(4, 16, d)
#define BOOST_PP_REPEAT_3_18(m, d) BOOST_PP_REPEAT_3_17(m, d) m(4, 17, d)
#define BOOST_PP_REPEAT_3_19(m, d) BOOST_PP_REPEAT_3_18(m, d) m(4, 18, d)
#define BOOST_PP_REPEAT_3_20(m, d) BOOST_PP_REPEAT_3_19(m, d) m(4, 19, d)
#define BOOST_PP_REPEAT_3_21(m, d) BOOST_PP_REPEAT_3_20(m, d) m(4, 20, d)
#define BOOST_PP_REPEAT_3_22(m, d) BOOST_PP_REPEAT_3_21(m, d) m(4, 21, d)
#define BOOST_PP_REPEAT_3_23(m, d) BOOST_PP_REPEAT_3_22(m, d) m(4, 22, d)
#define BOOST_PP_REPEAT_3_24(m, d) BOOST_PP_REPEAT_3_23(m, d) m(4, 23, d)
#define BOOST_PP_REPEAT_3_25(m, d) BOOST_PP_REPEAT_3_24(m, d) m(4, 24, d)
#define BOOST_PP_REPEAT_3_26(m, d) BOOST_PP_REPEAT_3_25(m, d) m(4, 25, d)
#define BOOST_PP_REPEAT_3_27(m, d) BOOST_PP_REPEAT_3_26(m, d) m(4, 26, d)
#define BOOST_PP_REPEAT_3_28(m, d) BOOST_PP_REPEAT_3_27(m, d) m(4, 27, d)
#define BOOST_PP_REPEAT_3_29(m, d) BOOST_PP_REPEAT_3_28(m, d) m(4, 28, d)
#define BOOST_PP_REPEAT_3_30(m, d) BOOST_PP_REPEAT_3_29(m, d) m(4, 29, d)
#define BOOST_PP_REPEAT_3_31(m, d) BOOST_PP_REPEAT_3_30(m, d) m(4, 30, d)
#define BOOST_PP_REPEAT_3_32(m, d) BOOST_PP_REPEAT_3_31(m, d) m(4, 31, d)
#define BOOST_PP_REPEAT_3_33(m, d) BOOST_PP_REPEAT_3_32(m, d) m(4, 32, d)
#define BOOST_PP_REPEAT_3_34(m, d) BOOST_PP_REPEAT_3_33(m, d) m(4, 33, d)
#define BOOST_PP_REPEAT_3_35(m, d) BOOST_PP_REPEAT_3_34(m, d) m(4, 34, d)
#define BOOST_PP_REPEAT_3_36(m, d) BOOST_PP_REPEAT_3_35(m, d) m(4, 35, d)
#define BOOST_PP_REPEAT_3_37(m, d) BOOST_PP_REPEAT_3_36(m, d) m(4, 36, d)
#define BOOST_PP_REPEAT_3_38(m, d) BOOST_PP_REPEAT_3_37(m, d) m(4, 37, d)
#define BOOST_PP_REPEAT_3_39(m, d) BOOST_PP_REPEAT_3_38(m, d) m(4, 38, d)
#define BOOST_PP_REPEAT_3_40(m, d) BOOST_PP_REPEAT_3_39(m, d) m(4, 39, d)
#define BOOST_PP_REPEAT_3_41(m, d) BOOST_PP_REPEAT_3_40(m, d) m(4, 40, d)
#define BOOST_PP_REPEAT_3_42(m, d) BOOST_PP_REPEAT_3_41(m, d) m(4, 41, d)
#define BOOST_PP_REPEAT_3_43(m, d) BOOST_PP_REPEAT_3_42(m, d) m(4, 42, d)
#define BOOST_PP_REPEAT_3_44(m, d) BOOST_PP_REPEAT_3_43(m, d) m(4, 43, d)
#define BOOST_PP_REPEAT_3_45(m, d) BOOST_PP_REPEAT_3_44(m, d) m(4, 44, d)
#define BOOST_PP_REPEAT_3_46(m, d) BOOST_PP_REPEAT_3_45(m, d) m(4, 45, d)
#define BOOST_PP_REPEAT_3_47(m, d) BOOST_PP_REPEAT_3_46(m, d) m(4, 46, d)
#define BOOST_PP_REPEAT_3_48(m, d) BOOST_PP_REPEAT_3_47(m, d) m(4, 47, d)
#define BOOST_PP_REPEAT_3_49(m, d) BOOST_PP_REPEAT_3_48(m, d) m(4, 48, d)
#define BOOST_PP_REPEAT_3_50(m, d) BOOST_PP_REPEAT_3_49(m, d) m(4, 49, d)
#define BOOST_PP_REPEAT_3_51(m, d) BOOST_PP_REPEAT_3_50(m, d) m(4, 50, d)
#define BOOST_PP_REPEAT_3_52(m, d) BOOST_PP_REPEAT_3_51(m, d) m(4, 51, d)
#define BOOST_PP_REPEAT_3_53(m, d) BOOST_PP_REPEAT_3_52(m, d) m(4, 52, d)
#define BOOST_PP_REPEAT_3_54(m, d) BOOST_PP_REPEAT_3_53(m, d) m(4, 53, d)
#define BOOST_PP_REPEAT_3_55(m, d) BOOST_PP_REPEAT_3_54(m, d) m(4, 54, d)
#define BOOST_PP_REPEAT_3_56(m, d) BOOST_PP_REPEAT_3_55(m, d) m(4, 55, d)
#define BOOST_PP_REPEAT_3_57(m, d) BOOST_PP_REPEAT_3_56(m, d) m(4, 56, d)
#define BOOST_PP_REPEAT_3_58(m, d) BOOST_PP_REPEAT_3_57(m, d) m(4, 57, d)
#define BOOST_PP_REPEAT_3_59(m, d) BOOST_PP_REPEAT_3_58(m, d) m(4, 58, d)
#define BOOST_PP_REPEAT_3_60(m, d) BOOST_PP_REPEAT_3_59(m, d) m(4, 59, d)
#define BOOST_PP_REPEAT_3_61(m, d) BOOST_PP_REPEAT_3_60(m, d) m(4, 60, d)
#define BOOST_PP_REPEAT_3_62(m, d) BOOST_PP_REPEAT_3_61(m, d) m(4, 61, d)
#define BOOST_PP_REPEAT_3_63(m, d) BOOST_PP_REPEAT_3_62(m, d) m(4, 62, d)
#define BOOST_PP_REPEAT_3_64(m, d) BOOST_PP_REPEAT_3_63(m, d) m(4, 63, d)
#define BOOST_PP_REPEAT_3_65(m, d) BOOST_PP_REPEAT_3_64(m, d) m(4, 64, d)
#define BOOST_PP_REPEAT_3_66(m, d) BOOST_PP_REPEAT_3_65(m, d) m(4, 65, d)
#define BOOST_PP_REPEAT_3_67(m, d) BOOST_PP_REPEAT_3_66(m, d) m(4, 66, d)
#define BOOST_PP_REPEAT_3_68(m, d) BOOST_PP_REPEAT_3_67(m, d) m(4, 67, d)
#define BOOST_PP_REPEAT_3_69(m, d) BOOST_PP_REPEAT_3_68(m, d) m(4, 68, d)
#define BOOST_PP_REPEAT_3_70(m, d) BOOST_PP_REPEAT_3_69(m, d) m(4, 69, d)
#define BOOST_PP_REPEAT_3_71(m, d) BOOST_PP_REPEAT_3_70(m, d) m(4, 70, d)
#define BOOST_PP_REPEAT_3_72(m, d) BOOST_PP_REPEAT_3_71(m, d) m(4, 71, d)
#define BOOST_PP_REPEAT_3_73(m, d) BOOST_PP_REPEAT_3_72(m, d) m(4, 72, d)
#define BOOST_PP_REPEAT_3_74(m, d) BOOST_PP_REPEAT_3_73(m, d) m(4, 73, d)
#define BOOST_PP_REPEAT_3_75(m, d) BOOST_PP_REPEAT_3_74(m, d) m(4, 74, d)
#define BOOST_PP_REPEAT_3_76(m, d) BOOST_PP_REPEAT_3_75(m, d) m(4, 75, d)
#define BOOST_PP_REPEAT_3_77(m, d) BOOST_PP_REPEAT_3_76(m, d) m(4, 76, d)
#define BOOST_PP_REPEAT_3_78(m, d) BOOST_PP_REPEAT_3_77(m, d) m(4, 77, d)
#define BOOST_PP_REPEAT_3_79(m, d) BOOST_PP_REPEAT_3_78(m, d) m(4, 78, d)
#define BOOST_PP_REPEAT_3_80(m, d) BOOST_PP_REPEAT_3_79(m, d) m(4, 79, d)
#define BOOST_PP_REPEAT_3_81(m, d) BOOST_PP_REPEAT_3_80(m, d) m(4, 80, d)
#define BOOST_PP_REPEAT_3_82(m, d) BOOST_PP_REPEAT_3_81(m, d) m(4, 81, d)
#define BOOST_PP_REPEAT_3_83(m, d) BOOST_PP_REPEAT_3_82(m, d) m(4, 82, d)
#define BOOST_PP_REPEAT_3_84(m, d) BOOST_PP_REPEAT_3_83(m, d) m(4, 83, d)
#define BOOST_PP_REPEAT_3_85(m, d) BOOST_PP_REPEAT_3_84(m, d) m(4, 84, d)
#define BOOST_PP_REPEAT_3_86(m, d) BOOST_PP_REPEAT_3_85(m, d) m(4, 85, d)
#define BOOST_PP_REPEAT_3_87(m, d) BOOST_PP_REPEAT_3_86(m, d) m(4, 86, d)
#define BOOST_PP_REPEAT_3_88(m, d) BOOST_PP_REPEAT_3_87(m, d) m(4, 87, d)
#define BOOST_PP_REPEAT_3_89(m, d) BOOST_PP_REPEAT_3_88(m, d) m(4, 88, d)
#define BOOST_PP_REPEAT_3_90(m, d) BOOST_PP_REPEAT_3_89(m, d) m(4, 89, d)
#define BOOST_PP_REPEAT_3_91(m, d) BOOST_PP_REPEAT_3_90(m, d) m(4, 90, d)
#define BOOST_PP_REPEAT_3_92(m, d) BOOST_PP_REPEAT_3_91(m, d) m(4, 91, d)
#define BOOST_PP_REPEAT_3_93(m, d) BOOST_PP_REPEAT_3_92(m, d) m(4, 92, d)
#define BOOST_PP_REPEAT_3_94(m, d) BOOST_PP_REPEAT_3_93(m, d) m(4, 93, d)
#define BOOST_PP_REPEAT_3_95(m, d) BOOST_PP_REPEAT_3_94(m, d) m(4, 94, d)
#define BOOST_PP_REPEAT_3_96(m, d) BOOST_PP_REPEAT_3_95(m, d) m(4, 95, d)
#define BOOST_PP_REPEAT_3_97(m, d) BOOST_PP_REPEAT_3_96(m, d) m(4, 96, d)
#define BOOST_PP_REPEAT_3_98(m, d) BOOST_PP_REPEAT_3_97(m, d) m(4, 97, d)
#define BOOST_PP_REPEAT_3_99(m, d) BOOST_PP_REPEAT_3_98(m, d) m(4, 98, d)
#define BOOST_PP_REPEAT_3_100(m, d) BOOST_PP_REPEAT_3_99(m, d) m(4, 99, d)
#define BOOST_PP_REPEAT_3_101(m, d) BOOST_PP_REPEAT_3_100(m, d) m(4, 100, d)
#define BOOST_PP_REPEAT_3_102(m, d) BOOST_PP_REPEAT_3_101(m, d) m(4, 101, d)
#define BOOST_PP_REPEAT_3_103(m, d) BOOST_PP_REPEAT_3_102(m, d) m(4, 102, d)
#define BOOST_PP_REPEAT_3_104(m, d) BOOST_PP_REPEAT_3_103(m, d) m(4, 103, d)
#define BOOST_PP_REPEAT_3_105(m, d) BOOST_PP_REPEAT_3_104(m, d) m(4, 104, d)
#define BOOST_PP_REPEAT_3_106(m, d) BOOST_PP_REPEAT_3_105(m, d) m(4, 105, d)
#define BOOST_PP_REPEAT_3_107(m, d) BOOST_PP_REPEAT_3_106(m, d) m(4, 106, d)
#define BOOST_PP_REPEAT_3_108(m, d) BOOST_PP_REPEAT_3_107(m, d) m(4, 107, d)
#define BOOST_PP_REPEAT_3_109(m, d) BOOST_PP_REPEAT_3_108(m, d) m(4, 108, d)
#define BOOST_PP_REPEAT_3_110(m, d) BOOST_PP_REPEAT_3_109(m, d) m(4, 109, d)
#define BOOST_PP_REPEAT_3_111(m, d) BOOST_PP_REPEAT_3_110(m, d) m(4, 110, d)
#define BOOST_PP_REPEAT_3_112(m, d) BOOST_PP_REPEAT_3_111(m, d) m(4, 111, d)
#define BOOST_PP_REPEAT_3_113(m, d) BOOST_PP_REPEAT_3_112(m, d) m(4, 112, d)
#define BOOST_PP_REPEAT_3_114(m, d) BOOST_PP_REPEAT_3_113(m, d) m(4, 113, d)
#define BOOST_PP_REPEAT_3_115(m, d) BOOST_PP_REPEAT_3_114(m, d) m(4, 114, d)
#define BOOST_PP_REPEAT_3_116(m, d) BOOST_PP_REPEAT_3_115(m, d) m(4, 115, d)
#define BOOST_PP_REPEAT_3_117(m, d) BOOST_PP_REPEAT_3_116(m, d) m(4, 116, d)
#define BOOST_PP_REPEAT_3_118(m, d) BOOST_PP_REPEAT_3_117(m, d) m(4, 117, d)
#define BOOST_PP_REPEAT_3_119(m, d) BOOST_PP_REPEAT_3_118(m, d) m(4, 118, d)
#define BOOST_PP_REPEAT_3_120(m, d) BOOST_PP_REPEAT_3_119(m, d) m(4, 119, d)
#define BOOST_PP_REPEAT_3_121(m, d) BOOST_PP_REPEAT_3_120(m, d) m(4, 120, d)
#define BOOST_PP_REPEAT_3_122(m, d) BOOST_PP_REPEAT_3_121(m, d) m(4, 121, d)
#define BOOST_PP_REPEAT_3_123(m, d) BOOST_PP_REPEAT_3_122(m, d) m(4, 122, d)
#define BOOST_PP_REPEAT_3_124(m, d) BOOST_PP_REPEAT_3_123(m, d) m(4, 123, d)
#define BOOST_PP_REPEAT_3_125(m, d) BOOST_PP_REPEAT_3_124(m, d) m(4, 124, d)
#define BOOST_PP_REPEAT_3_126(m, d) BOOST_PP_REPEAT_3_125(m, d) m(4, 125, d)
#define BOOST_PP_REPEAT_3_127(m, d) BOOST_PP_REPEAT_3_126(m, d) m(4, 126, d)
#define BOOST_PP_REPEAT_3_128(m, d) BOOST_PP_REPEAT_3_127(m, d) m(4, 127, d)
#define BOOST_PP_REPEAT_3_129(m, d) BOOST_PP_REPEAT_3_128(m, d) m(4, 128, d)
#define BOOST_PP_REPEAT_3_130(m, d) BOOST_PP_REPEAT_3_129(m, d) m(4, 129, d)
#define BOOST_PP_REPEAT_3_131(m, d) BOOST_PP_REPEAT_3_130(m, d) m(4, 130, d)
#define BOOST_PP_REPEAT_3_132(m, d) BOOST_PP_REPEAT_3_131(m, d) m(4, 131, d)
#define BOOST_PP_REPEAT_3_133(m, d) BOOST_PP_REPEAT_3_132(m, d) m(4, 132, d)
#define BOOST_PP_REPEAT_3_134(m, d) BOOST_PP_REPEAT_3_133(m, d) m(4, 133, d)
#define BOOST_PP_REPEAT_3_135(m, d) BOOST_PP_REPEAT_3_134(m, d) m(4, 134, d)
#define BOOST_PP_REPEAT_3_136(m, d) BOOST_PP_REPEAT_3_135(m, d) m(4, 135, d)
#define BOOST_PP_REPEAT_3_137(m, d) BOOST_PP_REPEAT_3_136(m, d) m(4, 136, d)
#define BOOST_PP_REPEAT_3_138(m, d) BOOST_PP_REPEAT_3_137(m, d) m(4, 137, d)
#define BOOST_PP_REPEAT_3_139(m, d) BOOST_PP_REPEAT_3_138(m, d) m(4, 138, d)
#define BOOST_PP_REPEAT_3_140(m, d) BOOST_PP_REPEAT_3_139(m, d) m(4, 139, d)
#define BOOST_PP_REPEAT_3_141(m, d) BOOST_PP_REPEAT_3_140(m, d) m(4, 140, d)
#define BOOST_PP_REPEAT_3_142(m, d) BOOST_PP_REPEAT_3_141(m, d) m(4, 141, d)
#define BOOST_PP_REPEAT_3_143(m, d) BOOST_PP_REPEAT_3_142(m, d) m(4, 142, d)
#define BOOST_PP_REPEAT_3_144(m, d) BOOST_PP_REPEAT_3_143(m, d) m(4, 143, d)
#define BOOST_PP_REPEAT_3_145(m, d) BOOST_PP_REPEAT_3_144(m, d) m(4, 144, d)
#define BOOST_PP_REPEAT_3_146(m, d) BOOST_PP_REPEAT_3_145(m, d) m(4, 145, d)
#define BOOST_PP_REPEAT_3_147(m, d) BOOST_PP_REPEAT_3_146(m, d) m(4, 146, d)
#define BOOST_PP_REPEAT_3_148(m, d) BOOST_PP_REPEAT_3_147(m, d) m(4, 147, d)
#define BOOST_PP_REPEAT_3_149(m, d) BOOST_PP_REPEAT_3_148(m, d) m(4, 148, d)
#define BOOST_PP_REPEAT_3_150(m, d) BOOST_PP_REPEAT_3_149(m, d) m(4, 149, d)
#define BOOST_PP_REPEAT_3_151(m, d) BOOST_PP_REPEAT_3_150(m, d) m(4, 150, d)
#define BOOST_PP_REPEAT_3_152(m, d) BOOST_PP_REPEAT_3_151(m, d) m(4, 151, d)
#define BOOST_PP_REPEAT_3_153(m, d) BOOST_PP_REPEAT_3_152(m, d) m(4, 152, d)
#define BOOST_PP_REPEAT_3_154(m, d) BOOST_PP_REPEAT_3_153(m, d) m(4, 153, d)
#define BOOST_PP_REPEAT_3_155(m, d) BOOST_PP_REPEAT_3_154(m, d) m(4, 154, d)
#define BOOST_PP_REPEAT_3_156(m, d) BOOST_PP_REPEAT_3_155(m, d) m(4, 155, d)
#define BOOST_PP_REPEAT_3_157(m, d) BOOST_PP_REPEAT_3_156(m, d) m(4, 156, d)
#define BOOST_PP_REPEAT_3_158(m, d) BOOST_PP_REPEAT_3_157(m, d) m(4, 157, d)
#define BOOST_PP_REPEAT_3_159(m, d) BOOST_PP_REPEAT_3_158(m, d) m(4, 158, d)
#define BOOST_PP_REPEAT_3_160(m, d) BOOST_PP_REPEAT_3_159(m, d) m(4, 159, d)
#define BOOST_PP_REPEAT_3_161(m, d) BOOST_PP_REPEAT_3_160(m, d) m(4, 160, d)
#define BOOST_PP_REPEAT_3_162(m, d) BOOST_PP_REPEAT_3_161(m, d) m(4, 161, d)
#define BOOST_PP_REPEAT_3_163(m, d) BOOST_PP_REPEAT_3_162(m, d) m(4, 162, d)
#define BOOST_PP_REPEAT_3_164(m, d) BOOST_PP_REPEAT_3_163(m, d) m(4, 163, d)
#define BOOST_PP_REPEAT_3_165(m, d) BOOST_PP_REPEAT_3_164(m, d) m(4, 164, d)
#define BOOST_PP_REPEAT_3_166(m, d) BOOST_PP_REPEAT_3_165(m, d) m(4, 165, d)
#define BOOST_PP_REPEAT_3_167(m, d) BOOST_PP_REPEAT_3_166(m, d) m(4, 166, d)
#define BOOST_PP_REPEAT_3_168(m, d) BOOST_PP_REPEAT_3_167(m, d) m(4, 167, d)
#define BOOST_PP_REPEAT_3_169(m, d) BOOST_PP_REPEAT_3_168(m, d) m(4, 168, d)
#define BOOST_PP_REPEAT_3_170(m, d) BOOST_PP_REPEAT_3_169(m, d) m(4, 169, d)
#define BOOST_PP_REPEAT_3_171(m, d) BOOST_PP_REPEAT_3_170(m, d) m(4, 170, d)
#define BOOST_PP_REPEAT_3_172(m, d) BOOST_PP_REPEAT_3_171(m, d) m(4, 171, d)
#define BOOST_PP_REPEAT_3_173(m, d) BOOST_PP_REPEAT_3_172(m, d) m(4, 172, d)
#define BOOST_PP_REPEAT_3_174(m, d) BOOST_PP_REPEAT_3_173(m, d) m(4, 173, d)
#define BOOST_PP_REPEAT_3_175(m, d) BOOST_PP_REPEAT_3_174(m, d) m(4, 174, d)
#define BOOST_PP_REPEAT_3_176(m, d) BOOST_PP_REPEAT_3_175(m, d) m(4, 175, d)
#define BOOST_PP_REPEAT_3_177(m, d) BOOST_PP_REPEAT_3_176(m, d) m(4, 176, d)
#define BOOST_PP_REPEAT_3_178(m, d) BOOST_PP_REPEAT_3_177(m, d) m(4, 177, d)
#define BOOST_PP_REPEAT_3_179(m, d) BOOST_PP_REPEAT_3_178(m, d) m(4, 178, d)
#define BOOST_PP_REPEAT_3_180(m, d) BOOST_PP_REPEAT_3_179(m, d) m(4, 179, d)
#define BOOST_PP_REPEAT_3_181(m, d) BOOST_PP_REPEAT_3_180(m, d) m(4, 180, d)
#define BOOST_PP_REPEAT_3_182(m, d) BOOST_PP_REPEAT_3_181(m, d) m(4, 181, d)
#define BOOST_PP_REPEAT_3_183(m, d) BOOST_PP_REPEAT_3_182(m, d) m(4, 182, d)
#define BOOST_PP_REPEAT_3_184(m, d) BOOST_PP_REPEAT_3_183(m, d) m(4, 183, d)
#define BOOST_PP_REPEAT_3_185(m, d) BOOST_PP_REPEAT_3_184(m, d) m(4, 184, d)
#define BOOST_PP_REPEAT_3_186(m, d) BOOST_PP_REPEAT_3_185(m, d) m(4, 185, d)
#define BOOST_PP_REPEAT_3_187(m, d) BOOST_PP_REPEAT_3_186(m, d) m(4, 186, d)
#define BOOST_PP_REPEAT_3_188(m, d) BOOST_PP_REPEAT_3_187(m, d) m(4, 187, d)
#define BOOST_PP_REPEAT_3_189(m, d) BOOST_PP_REPEAT_3_188(m, d) m(4, 188, d)
#define BOOST_PP_REPEAT_3_190(m, d) BOOST_PP_REPEAT_3_189(m, d) m(4, 189, d)
#define BOOST_PP_REPEAT_3_191(m, d) BOOST_PP_REPEAT_3_190(m, d) m(4, 190, d)
#define BOOST_PP_REPEAT_3_192(m, d) BOOST_PP_REPEAT_3_191(m, d) m(4, 191, d)
#define BOOST_PP_REPEAT_3_193(m, d) BOOST_PP_REPEAT_3_192(m, d) m(4, 192, d)
#define BOOST_PP_REPEAT_3_194(m, d) BOOST_PP_REPEAT_3_193(m, d) m(4, 193, d)
#define BOOST_PP_REPEAT_3_195(m, d) BOOST_PP_REPEAT_3_194(m, d) m(4, 194, d)
#define BOOST_PP_REPEAT_3_196(m, d) BOOST_PP_REPEAT_3_195(m, d) m(4, 195, d)
#define BOOST_PP_REPEAT_3_197(m, d) BOOST_PP_REPEAT_3_196(m, d) m(4, 196, d)
#define BOOST_PP_REPEAT_3_198(m, d) BOOST_PP_REPEAT_3_197(m, d) m(4, 197, d)
#define BOOST_PP_REPEAT_3_199(m, d) BOOST_PP_REPEAT_3_198(m, d) m(4, 198, d)
#define BOOST_PP_REPEAT_3_200(m, d) BOOST_PP_REPEAT_3_199(m, d) m(4, 199, d)
#define BOOST_PP_REPEAT_3_201(m, d) BOOST_PP_REPEAT_3_200(m, d) m(4, 200, d)
#define BOOST_PP_REPEAT_3_202(m, d) BOOST_PP_REPEAT_3_201(m, d) m(4, 201, d)
#define BOOST_PP_REPEAT_3_203(m, d) BOOST_PP_REPEAT_3_202(m, d) m(4, 202, d)
#define BOOST_PP_REPEAT_3_204(m, d) BOOST_PP_REPEAT_3_203(m, d) m(4, 203, d)
#define BOOST_PP_REPEAT_3_205(m, d) BOOST_PP_REPEAT_3_204(m, d) m(4, 204, d)
#define BOOST_PP_REPEAT_3_206(m, d) BOOST_PP_REPEAT_3_205(m, d) m(4, 205, d)
#define BOOST_PP_REPEAT_3_207(m, d) BOOST_PP_REPEAT_3_206(m, d) m(4, 206, d)
#define BOOST_PP_REPEAT_3_208(m, d) BOOST_PP_REPEAT_3_207(m, d) m(4, 207, d)
#define BOOST_PP_REPEAT_3_209(m, d) BOOST_PP_REPEAT_3_208(m, d) m(4, 208, d)
#define BOOST_PP_REPEAT_3_210(m, d) BOOST_PP_REPEAT_3_209(m, d) m(4, 209, d)
#define BOOST_PP_REPEAT_3_211(m, d) BOOST_PP_REPEAT_3_210(m, d) m(4, 210, d)
#define BOOST_PP_REPEAT_3_212(m, d) BOOST_PP_REPEAT_3_211(m, d) m(4, 211, d)
#define BOOST_PP_REPEAT_3_213(m, d) BOOST_PP_REPEAT_3_212(m, d) m(4, 212, d)
#define BOOST_PP_REPEAT_3_214(m, d) BOOST_PP_REPEAT_3_213(m, d) m(4, 213, d)
#define BOOST_PP_REPEAT_3_215(m, d) BOOST_PP_REPEAT_3_214(m, d) m(4, 214, d)
#define BOOST_PP_REPEAT_3_216(m, d) BOOST_PP_REPEAT_3_215(m, d) m(4, 215, d)
#define BOOST_PP_REPEAT_3_217(m, d) BOOST_PP_REPEAT_3_216(m, d) m(4, 216, d)
#define BOOST_PP_REPEAT_3_218(m, d) BOOST_PP_REPEAT_3_217(m, d) m(4, 217, d)
#define BOOST_PP_REPEAT_3_219(m, d) BOOST_PP_REPEAT_3_218(m, d) m(4, 218, d)
#define BOOST_PP_REPEAT_3_220(m, d) BOOST_PP_REPEAT_3_219(m, d) m(4, 219, d)
#define BOOST_PP_REPEAT_3_221(m, d) BOOST_PP_REPEAT_3_220(m, d) m(4, 220, d)
#define BOOST_PP_REPEAT_3_222(m, d) BOOST_PP_REPEAT_3_221(m, d) m(4, 221, d)
#define BOOST_PP_REPEAT_3_223(m, d) BOOST_PP_REPEAT_3_222(m, d) m(4, 222, d)
#define BOOST_PP_REPEAT_3_224(m, d) BOOST_PP_REPEAT_3_223(m, d) m(4, 223, d)
#define BOOST_PP_REPEAT_3_225(m, d) BOOST_PP_REPEAT_3_224(m, d) m(4, 224, d)
#define BOOST_PP_REPEAT_3_226(m, d) BOOST_PP_REPEAT_3_225(m, d) m(4, 225, d)
#define BOOST_PP_REPEAT_3_227(m, d) BOOST_PP_REPEAT_3_226(m, d) m(4, 226, d)
#define BOOST_PP_REPEAT_3_228(m, d) BOOST_PP_REPEAT_3_227(m, d) m(4, 227, d)
#define BOOST_PP_REPEAT_3_229(m, d) BOOST_PP_REPEAT_3_228(m, d) m(4, 228, d)
#define BOOST_PP_REPEAT_3_230(m, d) BOOST_PP_REPEAT_3_229(m, d) m(4, 229, d)
#define BOOST_PP_REPEAT_3_231(m, d) BOOST_PP_REPEAT_3_230(m, d) m(4, 230, d)
#define BOOST_PP_REPEAT_3_232(m, d) BOOST_PP_REPEAT_3_231(m, d) m(4, 231, d)
#define BOOST_PP_REPEAT_3_233(m, d) BOOST_PP_REPEAT_3_232(m, d) m(4, 232, d)
#define BOOST_PP_REPEAT_3_234(m, d) BOOST_PP_REPEAT_3_233(m, d) m(4, 233, d)
#define BOOST_PP_REPEAT_3_235(m, d) BOOST_PP_REPEAT_3_234(m, d) m(4, 234, d)
#define BOOST_PP_REPEAT_3_236(m, d) BOOST_PP_REPEAT_3_235(m, d) m(4, 235, d)
#define BOOST_PP_REPEAT_3_237(m, d) BOOST_PP_REPEAT_3_236(m, d) m(4, 236, d)
#define BOOST_PP_REPEAT_3_238(m, d) BOOST_PP_REPEAT_3_237(m, d) m(4, 237, d)
#define BOOST_PP_REPEAT_3_239(m, d) BOOST_PP_REPEAT_3_238(m, d) m(4, 238, d)
#define BOOST_PP_REPEAT_3_240(m, d) BOOST_PP_REPEAT_3_239(m, d) m(4, 239, d)
#define BOOST_PP_REPEAT_3_241(m, d) BOOST_PP_REPEAT_3_240(m, d) m(4, 240, d)
#define BOOST_PP_REPEAT_3_242(m, d) BOOST_PP_REPEAT_3_241(m, d) m(4, 241, d)
#define BOOST_PP_REPEAT_3_243(m, d) BOOST_PP_REPEAT_3_242(m, d) m(4, 242, d)
#define BOOST_PP_REPEAT_3_244(m, d) BOOST_PP_REPEAT_3_243(m, d) m(4, 243, d)
#define BOOST_PP_REPEAT_3_245(m, d) BOOST_PP_REPEAT_3_244(m, d) m(4, 244, d)
#define BOOST_PP_REPEAT_3_246(m, d) BOOST_PP_REPEAT_3_245(m, d) m(4, 245, d)
#define BOOST_PP_REPEAT_3_247(m, d) BOOST_PP_REPEAT_3_246(m, d) m(4, 246, d)
#define BOOST_PP_REPEAT_3_248(m, d) BOOST_PP_REPEAT_3_247(m, d) m(4, 247, d)
#define BOOST_PP_REPEAT_3_249(m, d) BOOST_PP_REPEAT_3_248(m, d) m(4, 248, d)
#define BOOST_PP_REPEAT_3_250(m, d) BOOST_PP_REPEAT_3_249(m, d) m(4, 249, d)
#define BOOST_PP_REPEAT_3_251(m, d) BOOST_PP_REPEAT_3_250(m, d) m(4, 250, d)
#define BOOST_PP_REPEAT_3_252(m, d) BOOST_PP_REPEAT_3_251(m, d) m(4, 251, d)
#define BOOST_PP_REPEAT_3_253(m, d) BOOST_PP_REPEAT_3_252(m, d) m(4, 252, d)
#define BOOST_PP_REPEAT_3_254(m, d) BOOST_PP_REPEAT_3_253(m, d) m(4, 253, d)
#define BOOST_PP_REPEAT_3_255(m, d) BOOST_PP_REPEAT_3_254(m, d) m(4, 254, d)
#define BOOST_PP_REPEAT_3_256(m, d) BOOST_PP_REPEAT_3_255(m, d) m(4, 255, d)

#define BOOST_PP_REPEAT_FROM_TO BOOST_PP_CAT(BOOST_PP_REPEAT_FROM_TO_, BOOST_PP_AUTO_REC(BOOST_PP_REPEAT_P, 4))
#define BOOST_PP_REPEAT_FROM_TO_1(f, l, m, dt) BOOST_PP_REPEAT_FROM_TO_D_1(BOOST_PP_AUTO_REC(BOOST_PP_WHILE_P, 256), f, l, m, dt)
#define BOOST_PP_REPEAT_FROM_TO_2(f, l, m, dt) BOOST_PP_REPEAT_FROM_TO_D_2(BOOST_PP_AUTO_REC(BOOST_PP_WHILE_P, 256), f, l, m, dt)
#define BOOST_PP_REPEAT_FROM_TO_3(f, l, m, dt) BOOST_PP_REPEAT_FROM_TO_D_3(BOOST_PP_AUTO_REC(BOOST_PP_WHILE_P, 256), f, l, m, dt)
#define BOOST_PP_REPEAT_FROM_TO_4(f, l, m, dt) BOOST_PP_ERROR(0x0003)

#define BOOST_PP_REPEAT_FROM_TO_1ST BOOST_PP_REPEAT_FROM_TO_1
#define BOOST_PP_REPEAT_FROM_TO_2ND BOOST_PP_REPEAT_FROM_TO_2
#define BOOST_PP_REPEAT_FROM_TO_3RD BOOST_PP_REPEAT_FROM_TO_3

#define BOOST_PP_REPEAT_FROM_TO_D BOOST_PP_CAT(BOOST_PP_REPEAT_FROM_TO_D_, BOOST_PP_AUTO_REC(BOOST_PP_REPEAT_P, 4))
#define BOOST_PP_REPEAT_FROM_TO_D_1(d, f, l, m, dt) BOOST_PP_REPEAT_1(BOOST_PP_SUB_D(d, l, f), BOOST_PP_REPEAT_FROM_TO_M_1, (d, f, m, dt))
#define BOOST_PP_REPEAT_FROM_TO_D_2(d, f, l, m, dt) BOOST_PP_REPEAT_2(BOOST_PP_SUB_D(d, l, f), BOOST_PP_REPEAT_FROM_TO_M_2, (d, f, m, dt))
#define BOOST_PP_REPEAT_FROM_TO_D_3(d, f, l, m, dt) BOOST_PP_REPEAT_3(BOOST_PP_SUB_D(d, l, f), BOOST_PP_REPEAT_FROM_TO_M_3, (d, f, m, dt))
#define BOOST_PP_REPEAT_FROM_TO_M_1(z, n, dfmd) BOOST_PP_REPEAT_FROM_TO_M_1_IM(z, n, BOOST_PP_TUPLE_REM_4 dfmd)
#define BOOST_PP_REPEAT_FROM_TO_M_2(z, n, dfmd) BOOST_PP_REPEAT_FROM_TO_M_2_IM(z, n, BOOST_PP_TUPLE_REM_4 dfmd)
#define BOOST_PP_REPEAT_FROM_TO_M_3(z, n, dfmd) BOOST_PP_REPEAT_FROM_TO_M_3_IM(z, n, BOOST_PP_TUPLE_REM_4 dfmd)
#define BOOST_PP_REPEAT_FROM_TO_M_1_IM(z, n, im) BOOST_PP_REPEAT_FROM_TO_M_1_I(z, n, im)
#define BOOST_PP_REPEAT_FROM_TO_M_2_IM(z, n, im) BOOST_PP_REPEAT_FROM_TO_M_2_I(z, n, im)
#define BOOST_PP_REPEAT_FROM_TO_M_3_IM(z, n, im) BOOST_PP_REPEAT_FROM_TO_M_3_I(z, n, im)
#define BOOST_PP_REPEAT_FROM_TO_M_1_I(z, n, d, f, m, dt) BOOST_PP_REPEAT_FROM_TO_M_1_II(z, BOOST_PP_ADD_D(d, n, f), m, dt)
#define BOOST_PP_REPEAT_FROM_TO_M_2_I(z, n, d, f, m, dt) BOOST_PP_REPEAT_FROM_TO_M_2_II(z, BOOST_PP_ADD_D(d, n, f), m, dt)
#define BOOST_PP_REPEAT_FROM_TO_M_3_I(z, n, d, f, m, dt) BOOST_PP_REPEAT_FROM_TO_M_3_II(z, BOOST_PP_ADD_D(d, n, f), m, dt)
#define BOOST_PP_REPEAT_FROM_TO_M_1_II(z, n, m, dt) m(z, n, dt)
#define BOOST_PP_REPEAT_FROM_TO_M_2_II(z, n, m, dt) m(z, n, dt)
#define BOOST_PP_REPEAT_FROM_TO_M_3_II(z, n, m, dt) m(z, n, dt)

#define BOOST_PP_RPAREN )
#define BOOST_PP_RPAREN_IF(cond) BOOST_PP_IF(cond, BOOST_PP_RPAREN, BOOST_PP_EMPTY)()

#define BOOST_PP_SEQ_CAT(seq) BOOST_PP_SEQ_FOLD_LEFT(BOOST_PP_SEQ_CAT_O, BOOST_PP_SEQ_HEAD(seq), BOOST_PP_SEQ_TAIL(seq))
#define BOOST_PP_SEQ_CAT_O(s, st, elem) BOOST_PP_SEQ_CAT_O_I(st, elem)
#define BOOST_PP_SEQ_CAT_O_I(a, b) a ## b
#define BOOST_PP_SEQ_CAT_S(s, seq) BOOST_PP_SEQ_FOLD_LEFT_ ## s(BOOST_PP_SEQ_CAT_O, BOOST_PP_SEQ_HEAD(seq), BOOST_PP_SEQ_TAIL(seq))

#define BOOST_PP_SEQ_ELEM(i, seq) BOOST_PP_SEQ_ELEM_I(i, seq)
#define BOOST_PP_SEQ_ELEM_I(i, seq) BOOST_PP_SEQ_ELEM_II(BOOST_PP_SEQ_ELEM_ ## i seq)
#define BOOST_PP_SEQ_ELEM_II(im) BOOST_PP_SEQ_ELEM_III(im)
#define BOOST_PP_SEQ_ELEM_III(x, _) x

#define BOOST_PP_SEQ_ELEM_0(x) x, BOOST_PP_NIL
#define BOOST_PP_SEQ_ELEM_1(_) BOOST_PP_SEQ_ELEM_0
#define BOOST_PP_SEQ_ELEM_2(_) BOOST_PP_SEQ_ELEM_1
#define BOOST_PP_SEQ_ELEM_3(_) BOOST_PP_SEQ_ELEM_2
#define BOOST_PP_SEQ_ELEM_4(_) BOOST_PP_SEQ_ELEM_3
#define BOOST_PP_SEQ_ELEM_5(_) BOOST_PP_SEQ_ELEM_4
#define BOOST_PP_SEQ_ELEM_6(_) BOOST_PP_SEQ_ELEM_5
#define BOOST_PP_SEQ_ELEM_7(_) BOOST_PP_SEQ_ELEM_6
#define BOOST_PP_SEQ_ELEM_8(_) BOOST_PP_SEQ_ELEM_7
#define BOOST_PP_SEQ_ELEM_9(_) BOOST_PP_SEQ_ELEM_8
#define BOOST_PP_SEQ_ELEM_10(_) BOOST_PP_SEQ_ELEM_9
#define BOOST_PP_SEQ_ELEM_11(_) BOOST_PP_SEQ_ELEM_10
#define BOOST_PP_SEQ_ELEM_12(_) BOOST_PP_SEQ_ELEM_11
#define BOOST_PP_SEQ_ELEM_13(_) BOOST_PP_SEQ_ELEM_12
#define BOOST_PP_SEQ_ELEM_14(_) BOOST_PP_SEQ_ELEM_13
#define BOOST_PP_SEQ_ELEM_15(_) BOOST_PP_SEQ_ELEM_14
#define BOOST_PP_SEQ_ELEM_16(_) BOOST_PP_SEQ_ELEM_15
#define BOOST_PP_SEQ_ELEM_17(_) BOOST_PP_SEQ_ELEM_16
#define BOOST_PP_SEQ_ELEM_18(_) BOOST_PP_SEQ_ELEM_17
#define BOOST_PP_SEQ_ELEM_19(_) BOOST_PP_SEQ_ELEM_18
#define BOOST_PP_SEQ_ELEM_20(_) BOOST_PP_SEQ_ELEM_19
#define BOOST_PP_SEQ_ELEM_21(_) BOOST_PP_SEQ_ELEM_20
#define BOOST_PP_SEQ_ELEM_22(_) BOOST_PP_SEQ_ELEM_21
#define BOOST_PP_SEQ_ELEM_23(_) BOOST_PP_SEQ_ELEM_22
#define BOOST_PP_SEQ_ELEM_24(_) BOOST_PP_SEQ_ELEM_23
#define BOOST_PP_SEQ_ELEM_25(_) BOOST_PP_SEQ_ELEM_24
#define BOOST_PP_SEQ_ELEM_26(_) BOOST_PP_SEQ_ELEM_25
#define BOOST_PP_SEQ_ELEM_27(_) BOOST_PP_SEQ_ELEM_26
#define BOOST_PP_SEQ_ELEM_28(_) BOOST_PP_SEQ_ELEM_27
#define BOOST_PP_SEQ_ELEM_29(_) BOOST_PP_SEQ_ELEM_28
#define BOOST_PP_SEQ_ELEM_30(_) BOOST_PP_SEQ_ELEM_29
#define BOOST_PP_SEQ_ELEM_31(_) BOOST_PP_SEQ_ELEM_30
#define BOOST_PP_SEQ_ELEM_32(_) BOOST_PP_SEQ_ELEM_31
#define BOOST_PP_SEQ_ELEM_33(_) BOOST_PP_SEQ_ELEM_32
#define BOOST_PP_SEQ_ELEM_34(_) BOOST_PP_SEQ_ELEM_33
#define BOOST_PP_SEQ_ELEM_35(_) BOOST_PP_SEQ_ELEM_34
#define BOOST_PP_SEQ_ELEM_36(_) BOOST_PP_SEQ_ELEM_35
#define BOOST_PP_SEQ_ELEM_37(_) BOOST_PP_SEQ_ELEM_36
#define BOOST_PP_SEQ_ELEM_38(_) BOOST_PP_SEQ_ELEM_37
#define BOOST_PP_SEQ_ELEM_39(_) BOOST_PP_SEQ_ELEM_38
#define BOOST_PP_SEQ_ELEM_40(_) BOOST_PP_SEQ_ELEM_39
#define BOOST_PP_SEQ_ELEM_41(_) BOOST_PP_SEQ_ELEM_40
#define BOOST_PP_SEQ_ELEM_42(_) BOOST_PP_SEQ_ELEM_41
#define BOOST_PP_SEQ_ELEM_43(_) BOOST_PP_SEQ_ELEM_42
#define BOOST_PP_SEQ_ELEM_44(_) BOOST_PP_SEQ_ELEM_43
#define BOOST_PP_SEQ_ELEM_45(_) BOOST_PP_SEQ_ELEM_44
#define BOOST_PP_SEQ_ELEM_46(_) BOOST_PP_SEQ_ELEM_45
#define BOOST_PP_SEQ_ELEM_47(_) BOOST_PP_SEQ_ELEM_46
#define BOOST_PP_SEQ_ELEM_48(_) BOOST_PP_SEQ_ELEM_47
#define BOOST_PP_SEQ_ELEM_49(_) BOOST_PP_SEQ_ELEM_48
#define BOOST_PP_SEQ_ELEM_50(_) BOOST_PP_SEQ_ELEM_49
#define BOOST_PP_SEQ_ELEM_51(_) BOOST_PP_SEQ_ELEM_50
#define BOOST_PP_SEQ_ELEM_52(_) BOOST_PP_SEQ_ELEM_51
#define BOOST_PP_SEQ_ELEM_53(_) BOOST_PP_SEQ_ELEM_52
#define BOOST_PP_SEQ_ELEM_54(_) BOOST_PP_SEQ_ELEM_53
#define BOOST_PP_SEQ_ELEM_55(_) BOOST_PP_SEQ_ELEM_54
#define BOOST_PP_SEQ_ELEM_56(_) BOOST_PP_SEQ_ELEM_55
#define BOOST_PP_SEQ_ELEM_57(_) BOOST_PP_SEQ_ELEM_56
#define BOOST_PP_SEQ_ELEM_58(_) BOOST_PP_SEQ_ELEM_57
#define BOOST_PP_SEQ_ELEM_59(_) BOOST_PP_SEQ_ELEM_58
#define BOOST_PP_SEQ_ELEM_60(_) BOOST_PP_SEQ_ELEM_59
#define BOOST_PP_SEQ_ELEM_61(_) BOOST_PP_SEQ_ELEM_60
#define BOOST_PP_SEQ_ELEM_62(_) BOOST_PP_SEQ_ELEM_61
#define BOOST_PP_SEQ_ELEM_63(_) BOOST_PP_SEQ_ELEM_62
#define BOOST_PP_SEQ_ELEM_64(_) BOOST_PP_SEQ_ELEM_63
#define BOOST_PP_SEQ_ELEM_65(_) BOOST_PP_SEQ_ELEM_64
#define BOOST_PP_SEQ_ELEM_66(_) BOOST_PP_SEQ_ELEM_65
#define BOOST_PP_SEQ_ELEM_67(_) BOOST_PP_SEQ_ELEM_66
#define BOOST_PP_SEQ_ELEM_68(_) BOOST_PP_SEQ_ELEM_67
#define BOOST_PP_SEQ_ELEM_69(_) BOOST_PP_SEQ_ELEM_68
#define BOOST_PP_SEQ_ELEM_70(_) BOOST_PP_SEQ_ELEM_69
#define BOOST_PP_SEQ_ELEM_71(_) BOOST_PP_SEQ_ELEM_70
#define BOOST_PP_SEQ_ELEM_72(_) BOOST_PP_SEQ_ELEM_71
#define BOOST_PP_SEQ_ELEM_73(_) BOOST_PP_SEQ_ELEM_72
#define BOOST_PP_SEQ_ELEM_74(_) BOOST_PP_SEQ_ELEM_73
#define BOOST_PP_SEQ_ELEM_75(_) BOOST_PP_SEQ_ELEM_74
#define BOOST_PP_SEQ_ELEM_76(_) BOOST_PP_SEQ_ELEM_75
#define BOOST_PP_SEQ_ELEM_77(_) BOOST_PP_SEQ_ELEM_76
#define BOOST_PP_SEQ_ELEM_78(_) BOOST_PP_SEQ_ELEM_77
#define BOOST_PP_SEQ_ELEM_79(_) BOOST_PP_SEQ_ELEM_78
#define BOOST_PP_SEQ_ELEM_80(_) BOOST_PP_SEQ_ELEM_79
#define BOOST_PP_SEQ_ELEM_81(_) BOOST_PP_SEQ_ELEM_80
#define BOOST_PP_SEQ_ELEM_82(_) BOOST_PP_SEQ_ELEM_81
#define BOOST_PP_SEQ_ELEM_83(_) BOOST_PP_SEQ_ELEM_82
#define BOOST_PP_SEQ_ELEM_84(_) BOOST_PP_SEQ_ELEM_83
#define BOOST_PP_SEQ_ELEM_85(_) BOOST_PP_SEQ_ELEM_84
#define BOOST_PP_SEQ_ELEM_86(_) BOOST_PP_SEQ_ELEM_85
#define BOOST_PP_SEQ_ELEM_87(_) BOOST_PP_SEQ_ELEM_86
#define BOOST_PP_SEQ_ELEM_88(_) BOOST_PP_SEQ_ELEM_87
#define BOOST_PP_SEQ_ELEM_89(_) BOOST_PP_SEQ_ELEM_88
#define BOOST_PP_SEQ_ELEM_90(_) BOOST_PP_SEQ_ELEM_89
#define BOOST_PP_SEQ_ELEM_91(_) BOOST_PP_SEQ_ELEM_90
#define BOOST_PP_SEQ_ELEM_92(_) BOOST_PP_SEQ_ELEM_91
#define BOOST_PP_SEQ_ELEM_93(_) BOOST_PP_SEQ_ELEM_92
#define BOOST_PP_SEQ_ELEM_94(_) BOOST_PP_SEQ_ELEM_93
#define BOOST_PP_SEQ_ELEM_95(_) BOOST_PP_SEQ_ELEM_94
#define BOOST_PP_SEQ_ELEM_96(_) BOOST_PP_SEQ_ELEM_95
#define BOOST_PP_SEQ_ELEM_97(_) BOOST_PP_SEQ_ELEM_96
#define BOOST_PP_SEQ_ELEM_98(_) BOOST_PP_SEQ_ELEM_97
#define BOOST_PP_SEQ_ELEM_99(_) BOOST_PP_SEQ_ELEM_98
#define BOOST_PP_SEQ_ELEM_100(_) BOOST_PP_SEQ_ELEM_99
#define BOOST_PP_SEQ_ELEM_101(_) BOOST_PP_SEQ_ELEM_100
#define BOOST_PP_SEQ_ELEM_102(_) BOOST_PP_SEQ_ELEM_101
#define BOOST_PP_SEQ_ELEM_103(_) BOOST_PP_SEQ_ELEM_102
#define BOOST_PP_SEQ_ELEM_104(_) BOOST_PP_SEQ_ELEM_103
#define BOOST_PP_SEQ_ELEM_105(_) BOOST_PP_SEQ_ELEM_104
#define BOOST_PP_SEQ_ELEM_106(_) BOOST_PP_SEQ_ELEM_105
#define BOOST_PP_SEQ_ELEM_107(_) BOOST_PP_SEQ_ELEM_106
#define BOOST_PP_SEQ_ELEM_108(_) BOOST_PP_SEQ_ELEM_107
#define BOOST_PP_SEQ_ELEM_109(_) BOOST_PP_SEQ_ELEM_108
#define BOOST_PP_SEQ_ELEM_110(_) BOOST_PP_SEQ_ELEM_109
#define BOOST_PP_SEQ_ELEM_111(_) BOOST_PP_SEQ_ELEM_110
#define BOOST_PP_SEQ_ELEM_112(_) BOOST_PP_SEQ_ELEM_111
#define BOOST_PP_SEQ_ELEM_113(_) BOOST_PP_SEQ_ELEM_112
#define BOOST_PP_SEQ_ELEM_114(_) BOOST_PP_SEQ_ELEM_113
#define BOOST_PP_SEQ_ELEM_115(_) BOOST_PP_SEQ_ELEM_114
#define BOOST_PP_SEQ_ELEM_116(_) BOOST_PP_SEQ_ELEM_115
#define BOOST_PP_SEQ_ELEM_117(_) BOOST_PP_SEQ_ELEM_116
#define BOOST_PP_SEQ_ELEM_118(_) BOOST_PP_SEQ_ELEM_117
#define BOOST_PP_SEQ_ELEM_119(_) BOOST_PP_SEQ_ELEM_118
#define BOOST_PP_SEQ_ELEM_120(_) BOOST_PP_SEQ_ELEM_119
#define BOOST_PP_SEQ_ELEM_121(_) BOOST_PP_SEQ_ELEM_120
#define BOOST_PP_SEQ_ELEM_122(_) BOOST_PP_SEQ_ELEM_121
#define BOOST_PP_SEQ_ELEM_123(_) BOOST_PP_SEQ_ELEM_122
#define BOOST_PP_SEQ_ELEM_124(_) BOOST_PP_SEQ_ELEM_123
#define BOOST_PP_SEQ_ELEM_125(_) BOOST_PP_SEQ_ELEM_124
#define BOOST_PP_SEQ_ELEM_126(_) BOOST_PP_SEQ_ELEM_125
#define BOOST_PP_SEQ_ELEM_127(_) BOOST_PP_SEQ_ELEM_126
#define BOOST_PP_SEQ_ELEM_128(_) BOOST_PP_SEQ_ELEM_127
#define BOOST_PP_SEQ_ELEM_129(_) BOOST_PP_SEQ_ELEM_128
#define BOOST_PP_SEQ_ELEM_130(_) BOOST_PP_SEQ_ELEM_129
#define BOOST_PP_SEQ_ELEM_131(_) BOOST_PP_SEQ_ELEM_130
#define BOOST_PP_SEQ_ELEM_132(_) BOOST_PP_SEQ_ELEM_131
#define BOOST_PP_SEQ_ELEM_133(_) BOOST_PP_SEQ_ELEM_132
#define BOOST_PP_SEQ_ELEM_134(_) BOOST_PP_SEQ_ELEM_133
#define BOOST_PP_SEQ_ELEM_135(_) BOOST_PP_SEQ_ELEM_134
#define BOOST_PP_SEQ_ELEM_136(_) BOOST_PP_SEQ_ELEM_135
#define BOOST_PP_SEQ_ELEM_137(_) BOOST_PP_SEQ_ELEM_136
#define BOOST_PP_SEQ_ELEM_138(_) BOOST_PP_SEQ_ELEM_137
#define BOOST_PP_SEQ_ELEM_139(_) BOOST_PP_SEQ_ELEM_138
#define BOOST_PP_SEQ_ELEM_140(_) BOOST_PP_SEQ_ELEM_139
#define BOOST_PP_SEQ_ELEM_141(_) BOOST_PP_SEQ_ELEM_140
#define BOOST_PP_SEQ_ELEM_142(_) BOOST_PP_SEQ_ELEM_141
#define BOOST_PP_SEQ_ELEM_143(_) BOOST_PP_SEQ_ELEM_142
#define BOOST_PP_SEQ_ELEM_144(_) BOOST_PP_SEQ_ELEM_143
#define BOOST_PP_SEQ_ELEM_145(_) BOOST_PP_SEQ_ELEM_144
#define BOOST_PP_SEQ_ELEM_146(_) BOOST_PP_SEQ_ELEM_145
#define BOOST_PP_SEQ_ELEM_147(_) BOOST_PP_SEQ_ELEM_146
#define BOOST_PP_SEQ_ELEM_148(_) BOOST_PP_SEQ_ELEM_147
#define BOOST_PP_SEQ_ELEM_149(_) BOOST_PP_SEQ_ELEM_148
#define BOOST_PP_SEQ_ELEM_150(_) BOOST_PP_SEQ_ELEM_149
#define BOOST_PP_SEQ_ELEM_151(_) BOOST_PP_SEQ_ELEM_150
#define BOOST_PP_SEQ_ELEM_152(_) BOOST_PP_SEQ_ELEM_151
#define BOOST_PP_SEQ_ELEM_153(_) BOOST_PP_SEQ_ELEM_152
#define BOOST_PP_SEQ_ELEM_154(_) BOOST_PP_SEQ_ELEM_153
#define BOOST_PP_SEQ_ELEM_155(_) BOOST_PP_SEQ_ELEM_154
#define BOOST_PP_SEQ_ELEM_156(_) BOOST_PP_SEQ_ELEM_155
#define BOOST_PP_SEQ_ELEM_157(_) BOOST_PP_SEQ_ELEM_156
#define BOOST_PP_SEQ_ELEM_158(_) BOOST_PP_SEQ_ELEM_157
#define BOOST_PP_SEQ_ELEM_159(_) BOOST_PP_SEQ_ELEM_158
#define BOOST_PP_SEQ_ELEM_160(_) BOOST_PP_SEQ_ELEM_159
#define BOOST_PP_SEQ_ELEM_161(_) BOOST_PP_SEQ_ELEM_160
#define BOOST_PP_SEQ_ELEM_162(_) BOOST_PP_SEQ_ELEM_161
#define BOOST_PP_SEQ_ELEM_163(_) BOOST_PP_SEQ_ELEM_162
#define BOOST_PP_SEQ_ELEM_164(_) BOOST_PP_SEQ_ELEM_163
#define BOOST_PP_SEQ_ELEM_165(_) BOOST_PP_SEQ_ELEM_164
#define BOOST_PP_SEQ_ELEM_166(_) BOOST_PP_SEQ_ELEM_165
#define BOOST_PP_SEQ_ELEM_167(_) BOOST_PP_SEQ_ELEM_166
#define BOOST_PP_SEQ_ELEM_168(_) BOOST_PP_SEQ_ELEM_167
#define BOOST_PP_SEQ_ELEM_169(_) BOOST_PP_SEQ_ELEM_168
#define BOOST_PP_SEQ_ELEM_170(_) BOOST_PP_SEQ_ELEM_169
#define BOOST_PP_SEQ_ELEM_171(_) BOOST_PP_SEQ_ELEM_170
#define BOOST_PP_SEQ_ELEM_172(_) BOOST_PP_SEQ_ELEM_171
#define BOOST_PP_SEQ_ELEM_173(_) BOOST_PP_SEQ_ELEM_172
#define BOOST_PP_SEQ_ELEM_174(_) BOOST_PP_SEQ_ELEM_173
#define BOOST_PP_SEQ_ELEM_175(_) BOOST_PP_SEQ_ELEM_174
#define BOOST_PP_SEQ_ELEM_176(_) BOOST_PP_SEQ_ELEM_175
#define BOOST_PP_SEQ_ELEM_177(_) BOOST_PP_SEQ_ELEM_176
#define BOOST_PP_SEQ_ELEM_178(_) BOOST_PP_SEQ_ELEM_177
#define BOOST_PP_SEQ_ELEM_179(_) BOOST_PP_SEQ_ELEM_178
#define BOOST_PP_SEQ_ELEM_180(_) BOOST_PP_SEQ_ELEM_179
#define BOOST_PP_SEQ_ELEM_181(_) BOOST_PP_SEQ_ELEM_180
#define BOOST_PP_SEQ_ELEM_182(_) BOOST_PP_SEQ_ELEM_181
#define BOOST_PP_SEQ_ELEM_183(_) BOOST_PP_SEQ_ELEM_182
#define BOOST_PP_SEQ_ELEM_184(_) BOOST_PP_SEQ_ELEM_183
#define BOOST_PP_SEQ_ELEM_185(_) BOOST_PP_SEQ_ELEM_184
#define BOOST_PP_SEQ_ELEM_186(_) BOOST_PP_SEQ_ELEM_185
#define BOOST_PP_SEQ_ELEM_187(_) BOOST_PP_SEQ_ELEM_186
#define BOOST_PP_SEQ_ELEM_188(_) BOOST_PP_SEQ_ELEM_187
#define BOOST_PP_SEQ_ELEM_189(_) BOOST_PP_SEQ_ELEM_188
#define BOOST_PP_SEQ_ELEM_190(_) BOOST_PP_SEQ_ELEM_189
#define BOOST_PP_SEQ_ELEM_191(_) BOOST_PP_SEQ_ELEM_190
#define BOOST_PP_SEQ_ELEM_192(_) BOOST_PP_SEQ_ELEM_191
#define BOOST_PP_SEQ_ELEM_193(_) BOOST_PP_SEQ_ELEM_192
#define BOOST_PP_SEQ_ELEM_194(_) BOOST_PP_SEQ_ELEM_193
#define BOOST_PP_SEQ_ELEM_195(_) BOOST_PP_SEQ_ELEM_194
#define BOOST_PP_SEQ_ELEM_196(_) BOOST_PP_SEQ_ELEM_195
#define BOOST_PP_SEQ_ELEM_197(_) BOOST_PP_SEQ_ELEM_196
#define BOOST_PP_SEQ_ELEM_198(_) BOOST_PP_SEQ_ELEM_197
#define BOOST_PP_SEQ_ELEM_199(_) BOOST_PP_SEQ_ELEM_198
#define BOOST_PP_SEQ_ELEM_200(_) BOOST_PP_SEQ_ELEM_199
#define BOOST_PP_SEQ_ELEM_201(_) BOOST_PP_SEQ_ELEM_200
#define BOOST_PP_SEQ_ELEM_202(_) BOOST_PP_SEQ_ELEM_201
#define BOOST_PP_SEQ_ELEM_203(_) BOOST_PP_SEQ_ELEM_202
#define BOOST_PP_SEQ_ELEM_204(_) BOOST_PP_SEQ_ELEM_203
#define BOOST_PP_SEQ_ELEM_205(_) BOOST_PP_SEQ_ELEM_204
#define BOOST_PP_SEQ_ELEM_206(_) BOOST_PP_SEQ_ELEM_205
#define BOOST_PP_SEQ_ELEM_207(_) BOOST_PP_SEQ_ELEM_206
#define BOOST_PP_SEQ_ELEM_208(_) BOOST_PP_SEQ_ELEM_207
#define BOOST_PP_SEQ_ELEM_209(_) BOOST_PP_SEQ_ELEM_208
#define BOOST_PP_SEQ_ELEM_210(_) BOOST_PP_SEQ_ELEM_209
#define BOOST_PP_SEQ_ELEM_211(_) BOOST_PP_SEQ_ELEM_210
#define BOOST_PP_SEQ_ELEM_212(_) BOOST_PP_SEQ_ELEM_211
#define BOOST_PP_SEQ_ELEM_213(_) BOOST_PP_SEQ_ELEM_212
#define BOOST_PP_SEQ_ELEM_214(_) BOOST_PP_SEQ_ELEM_213
#define BOOST_PP_SEQ_ELEM_215(_) BOOST_PP_SEQ_ELEM_214
#define BOOST_PP_SEQ_ELEM_216(_) BOOST_PP_SEQ_ELEM_215
#define BOOST_PP_SEQ_ELEM_217(_) BOOST_PP_SEQ_ELEM_216
#define BOOST_PP_SEQ_ELEM_218(_) BOOST_PP_SEQ_ELEM_217
#define BOOST_PP_SEQ_ELEM_219(_) BOOST_PP_SEQ_ELEM_218
#define BOOST_PP_SEQ_ELEM_220(_) BOOST_PP_SEQ_ELEM_219
#define BOOST_PP_SEQ_ELEM_221(_) BOOST_PP_SEQ_ELEM_220
#define BOOST_PP_SEQ_ELEM_222(_) BOOST_PP_SEQ_ELEM_221
#define BOOST_PP_SEQ_ELEM_223(_) BOOST_PP_SEQ_ELEM_222
#define BOOST_PP_SEQ_ELEM_224(_) BOOST_PP_SEQ_ELEM_223
#define BOOST_PP_SEQ_ELEM_225(_) BOOST_PP_SEQ_ELEM_224
#define BOOST_PP_SEQ_ELEM_226(_) BOOST_PP_SEQ_ELEM_225
#define BOOST_PP_SEQ_ELEM_227(_) BOOST_PP_SEQ_ELEM_226
#define BOOST_PP_SEQ_ELEM_228(_) BOOST_PP_SEQ_ELEM_227
#define BOOST_PP_SEQ_ELEM_229(_) BOOST_PP_SEQ_ELEM_228
#define BOOST_PP_SEQ_ELEM_230(_) BOOST_PP_SEQ_ELEM_229
#define BOOST_PP_SEQ_ELEM_231(_) BOOST_PP_SEQ_ELEM_230
#define BOOST_PP_SEQ_ELEM_232(_) BOOST_PP_SEQ_ELEM_231
#define BOOST_PP_SEQ_ELEM_233(_) BOOST_PP_SEQ_ELEM_232
#define BOOST_PP_SEQ_ELEM_234(_) BOOST_PP_SEQ_ELEM_233
#define BOOST_PP_SEQ_ELEM_235(_) BOOST_PP_SEQ_ELEM_234
#define BOOST_PP_SEQ_ELEM_236(_) BOOST_PP_SEQ_ELEM_235
#define BOOST_PP_SEQ_ELEM_237(_) BOOST_PP_SEQ_ELEM_236
#define BOOST_PP_SEQ_ELEM_238(_) BOOST_PP_SEQ_ELEM_237
#define BOOST_PP_SEQ_ELEM_239(_) BOOST_PP_SEQ_ELEM_238
#define BOOST_PP_SEQ_ELEM_240(_) BOOST_PP_SEQ_ELEM_239
#define BOOST_PP_SEQ_ELEM_241(_) BOOST_PP_SEQ_ELEM_240
#define BOOST_PP_SEQ_ELEM_242(_) BOOST_PP_SEQ_ELEM_241
#define BOOST_PP_SEQ_ELEM_243(_) BOOST_PP_SEQ_ELEM_242
#define BOOST_PP_SEQ_ELEM_244(_) BOOST_PP_SEQ_ELEM_243
#define BOOST_PP_SEQ_ELEM_245(_) BOOST_PP_SEQ_ELEM_244
#define BOOST_PP_SEQ_ELEM_246(_) BOOST_PP_SEQ_ELEM_245
#define BOOST_PP_SEQ_ELEM_247(_) BOOST_PP_SEQ_ELEM_246
#define BOOST_PP_SEQ_ELEM_248(_) BOOST_PP_SEQ_ELEM_247
#define BOOST_PP_SEQ_ELEM_249(_) BOOST_PP_SEQ_ELEM_248
#define BOOST_PP_SEQ_ELEM_250(_) BOOST_PP_SEQ_ELEM_249
#define BOOST_PP_SEQ_ELEM_251(_) BOOST_PP_SEQ_ELEM_250
#define BOOST_PP_SEQ_ELEM_252(_) BOOST_PP_SEQ_ELEM_251
#define BOOST_PP_SEQ_ELEM_253(_) BOOST_PP_SEQ_ELEM_252
#define BOOST_PP_SEQ_ELEM_254(_) BOOST_PP_SEQ_ELEM_253
#define BOOST_PP_SEQ_ELEM_255(_) BOOST_PP_SEQ_ELEM_254

#define BOOST_PP_SEQ_ENUM(seq) BOOST_PP_CAT(BOOST_PP_SEQ_ENUM_, BOOST_PP_SEQ_SIZE(seq)) seq
#define BOOST_PP_SEQ_ENUM_1(x) x
#define BOOST_PP_SEQ_ENUM_2(x) x, BOOST_PP_SEQ_ENUM_1
#define BOOST_PP_SEQ_ENUM_3(x) x, BOOST_PP_SEQ_ENUM_2
#define BOOST_PP_SEQ_ENUM_4(x) x, BOOST_PP_SEQ_ENUM_3
#define BOOST_PP_SEQ_ENUM_5(x) x, BOOST_PP_SEQ_ENUM_4
#define BOOST_PP_SEQ_ENUM_6(x) x, BOOST_PP_SEQ_ENUM_5
#define BOOST_PP_SEQ_ENUM_7(x) x, BOOST_PP_SEQ_ENUM_6
#define BOOST_PP_SEQ_ENUM_8(x) x, BOOST_PP_SEQ_ENUM_7
#define BOOST_PP_SEQ_ENUM_9(x) x, BOOST_PP_SEQ_ENUM_8
#define BOOST_PP_SEQ_ENUM_10(x) x, BOOST_PP_SEQ_ENUM_9
#define BOOST_PP_SEQ_ENUM_11(x) x, BOOST_PP_SEQ_ENUM_10
#define BOOST_PP_SEQ_ENUM_12(x) x, BOOST_PP_SEQ_ENUM_11
#define BOOST_PP_SEQ_ENUM_13(x) x, BOOST_PP_SEQ_ENUM_12
#define BOOST_PP_SEQ_ENUM_14(x) x, BOOST_PP_SEQ_ENUM_13
#define BOOST_PP_SEQ_ENUM_15(x) x, BOOST_PP_SEQ_ENUM_14
#define BOOST_PP_SEQ_ENUM_16(x) x, BOOST_PP_SEQ_ENUM_15
#define BOOST_PP_SEQ_ENUM_17(x) x, BOOST_PP_SEQ_ENUM_16
#define BOOST_PP_SEQ_ENUM_18(x) x, BOOST_PP_SEQ_ENUM_17
#define BOOST_PP_SEQ_ENUM_19(x) x, BOOST_PP_SEQ_ENUM_18
#define BOOST_PP_SEQ_ENUM_20(x) x, BOOST_PP_SEQ_ENUM_19
#define BOOST_PP_SEQ_ENUM_21(x) x, BOOST_PP_SEQ_ENUM_20
#define BOOST_PP_SEQ_ENUM_22(x) x, BOOST_PP_SEQ_ENUM_21
#define BOOST_PP_SEQ_ENUM_23(x) x, BOOST_PP_SEQ_ENUM_22
#define BOOST_PP_SEQ_ENUM_24(x) x, BOOST_PP_SEQ_ENUM_23
#define BOOST_PP_SEQ_ENUM_25(x) x, BOOST_PP_SEQ_ENUM_24
#define BOOST_PP_SEQ_ENUM_26(x) x, BOOST_PP_SEQ_ENUM_25
#define BOOST_PP_SEQ_ENUM_27(x) x, BOOST_PP_SEQ_ENUM_26
#define BOOST_PP_SEQ_ENUM_28(x) x, BOOST_PP_SEQ_ENUM_27
#define BOOST_PP_SEQ_ENUM_29(x) x, BOOST_PP_SEQ_ENUM_28
#define BOOST_PP_SEQ_ENUM_30(x) x, BOOST_PP_SEQ_ENUM_29
#define BOOST_PP_SEQ_ENUM_31(x) x, BOOST_PP_SEQ_ENUM_30
#define BOOST_PP_SEQ_ENUM_32(x) x, BOOST_PP_SEQ_ENUM_31
#define BOOST_PP_SEQ_ENUM_33(x) x, BOOST_PP_SEQ_ENUM_32
#define BOOST_PP_SEQ_ENUM_34(x) x, BOOST_PP_SEQ_ENUM_33
#define BOOST_PP_SEQ_ENUM_35(x) x, BOOST_PP_SEQ_ENUM_34
#define BOOST_PP_SEQ_ENUM_36(x) x, BOOST_PP_SEQ_ENUM_35
#define BOOST_PP_SEQ_ENUM_37(x) x, BOOST_PP_SEQ_ENUM_36
#define BOOST_PP_SEQ_ENUM_38(x) x, BOOST_PP_SEQ_ENUM_37
#define BOOST_PP_SEQ_ENUM_39(x) x, BOOST_PP_SEQ_ENUM_38
#define BOOST_PP_SEQ_ENUM_40(x) x, BOOST_PP_SEQ_ENUM_39
#define BOOST_PP_SEQ_ENUM_41(x) x, BOOST_PP_SEQ_ENUM_40
#define BOOST_PP_SEQ_ENUM_42(x) x, BOOST_PP_SEQ_ENUM_41
#define BOOST_PP_SEQ_ENUM_43(x) x, BOOST_PP_SEQ_ENUM_42
#define BOOST_PP_SEQ_ENUM_44(x) x, BOOST_PP_SEQ_ENUM_43
#define BOOST_PP_SEQ_ENUM_45(x) x, BOOST_PP_SEQ_ENUM_44
#define BOOST_PP_SEQ_ENUM_46(x) x, BOOST_PP_SEQ_ENUM_45
#define BOOST_PP_SEQ_ENUM_47(x) x, BOOST_PP_SEQ_ENUM_46
#define BOOST_PP_SEQ_ENUM_48(x) x, BOOST_PP_SEQ_ENUM_47
#define BOOST_PP_SEQ_ENUM_49(x) x, BOOST_PP_SEQ_ENUM_48
#define BOOST_PP_SEQ_ENUM_50(x) x, BOOST_PP_SEQ_ENUM_49
#define BOOST_PP_SEQ_ENUM_51(x) x, BOOST_PP_SEQ_ENUM_50
#define BOOST_PP_SEQ_ENUM_52(x) x, BOOST_PP_SEQ_ENUM_51
#define BOOST_PP_SEQ_ENUM_53(x) x, BOOST_PP_SEQ_ENUM_52
#define BOOST_PP_SEQ_ENUM_54(x) x, BOOST_PP_SEQ_ENUM_53
#define BOOST_PP_SEQ_ENUM_55(x) x, BOOST_PP_SEQ_ENUM_54
#define BOOST_PP_SEQ_ENUM_56(x) x, BOOST_PP_SEQ_ENUM_55
#define BOOST_PP_SEQ_ENUM_57(x) x, BOOST_PP_SEQ_ENUM_56
#define BOOST_PP_SEQ_ENUM_58(x) x, BOOST_PP_SEQ_ENUM_57
#define BOOST_PP_SEQ_ENUM_59(x) x, BOOST_PP_SEQ_ENUM_58
#define BOOST_PP_SEQ_ENUM_60(x) x, BOOST_PP_SEQ_ENUM_59
#define BOOST_PP_SEQ_ENUM_61(x) x, BOOST_PP_SEQ_ENUM_60
#define BOOST_PP_SEQ_ENUM_62(x) x, BOOST_PP_SEQ_ENUM_61
#define BOOST_PP_SEQ_ENUM_63(x) x, BOOST_PP_SEQ_ENUM_62
#define BOOST_PP_SEQ_ENUM_64(x) x, BOOST_PP_SEQ_ENUM_63
#define BOOST_PP_SEQ_ENUM_65(x) x, BOOST_PP_SEQ_ENUM_64
#define BOOST_PP_SEQ_ENUM_66(x) x, BOOST_PP_SEQ_ENUM_65
#define BOOST_PP_SEQ_ENUM_67(x) x, BOOST_PP_SEQ_ENUM_66
#define BOOST_PP_SEQ_ENUM_68(x) x, BOOST_PP_SEQ_ENUM_67
#define BOOST_PP_SEQ_ENUM_69(x) x, BOOST_PP_SEQ_ENUM_68
#define BOOST_PP_SEQ_ENUM_70(x) x, BOOST_PP_SEQ_ENUM_69
#define BOOST_PP_SEQ_ENUM_71(x) x, BOOST_PP_SEQ_ENUM_70
#define BOOST_PP_SEQ_ENUM_72(x) x, BOOST_PP_SEQ_ENUM_71
#define BOOST_PP_SEQ_ENUM_73(x) x, BOOST_PP_SEQ_ENUM_72
#define BOOST_PP_SEQ_ENUM_74(x) x, BOOST_PP_SEQ_ENUM_73
#define BOOST_PP_SEQ_ENUM_75(x) x, BOOST_PP_SEQ_ENUM_74
#define BOOST_PP_SEQ_ENUM_76(x) x, BOOST_PP_SEQ_ENUM_75
#define BOOST_PP_SEQ_ENUM_77(x) x, BOOST_PP_SEQ_ENUM_76
#define BOOST_PP_SEQ_ENUM_78(x) x, BOOST_PP_SEQ_ENUM_77
#define BOOST_PP_SEQ_ENUM_79(x) x, BOOST_PP_SEQ_ENUM_78
#define BOOST_PP_SEQ_ENUM_80(x) x, BOOST_PP_SEQ_ENUM_79
#define BOOST_PP_SEQ_ENUM_81(x) x, BOOST_PP_SEQ_ENUM_80
#define BOOST_PP_SEQ_ENUM_82(x) x, BOOST_PP_SEQ_ENUM_81
#define BOOST_PP_SEQ_ENUM_83(x) x, BOOST_PP_SEQ_ENUM_82
#define BOOST_PP_SEQ_ENUM_84(x) x, BOOST_PP_SEQ_ENUM_83
#define BOOST_PP_SEQ_ENUM_85(x) x, BOOST_PP_SEQ_ENUM_84
#define BOOST_PP_SEQ_ENUM_86(x) x, BOOST_PP_SEQ_ENUM_85
#define BOOST_PP_SEQ_ENUM_87(x) x, BOOST_PP_SEQ_ENUM_86
#define BOOST_PP_SEQ_ENUM_88(x) x, BOOST_PP_SEQ_ENUM_87
#define BOOST_PP_SEQ_ENUM_89(x) x, BOOST_PP_SEQ_ENUM_88
#define BOOST_PP_SEQ_ENUM_90(x) x, BOOST_PP_SEQ_ENUM_89
#define BOOST_PP_SEQ_ENUM_91(x) x, BOOST_PP_SEQ_ENUM_90
#define BOOST_PP_SEQ_ENUM_92(x) x, BOOST_PP_SEQ_ENUM_91
#define BOOST_PP_SEQ_ENUM_93(x) x, BOOST_PP_SEQ_ENUM_92
#define BOOST_PP_SEQ_ENUM_94(x) x, BOOST_PP_SEQ_ENUM_93
#define BOOST_PP_SEQ_ENUM_95(x) x, BOOST_PP_SEQ_ENUM_94
#define BOOST_PP_SEQ_ENUM_96(x) x, BOOST_PP_SEQ_ENUM_95
#define BOOST_PP_SEQ_ENUM_97(x) x, BOOST_PP_SEQ_ENUM_96
#define BOOST_PP_SEQ_ENUM_98(x) x, BOOST_PP_SEQ_ENUM_97
#define BOOST_PP_SEQ_ENUM_99(x) x, BOOST_PP_SEQ_ENUM_98
#define BOOST_PP_SEQ_ENUM_100(x) x, BOOST_PP_SEQ_ENUM_99
#define BOOST_PP_SEQ_ENUM_101(x) x, BOOST_PP_SEQ_ENUM_100
#define BOOST_PP_SEQ_ENUM_102(x) x, BOOST_PP_SEQ_ENUM_101
#define BOOST_PP_SEQ_ENUM_103(x) x, BOOST_PP_SEQ_ENUM_102
#define BOOST_PP_SEQ_ENUM_104(x) x, BOOST_PP_SEQ_ENUM_103
#define BOOST_PP_SEQ_ENUM_105(x) x, BOOST_PP_SEQ_ENUM_104
#define BOOST_PP_SEQ_ENUM_106(x) x, BOOST_PP_SEQ_ENUM_105
#define BOOST_PP_SEQ_ENUM_107(x) x, BOOST_PP_SEQ_ENUM_106
#define BOOST_PP_SEQ_ENUM_108(x) x, BOOST_PP_SEQ_ENUM_107
#define BOOST_PP_SEQ_ENUM_109(x) x, BOOST_PP_SEQ_ENUM_108
#define BOOST_PP_SEQ_ENUM_110(x) x, BOOST_PP_SEQ_ENUM_109
#define BOOST_PP_SEQ_ENUM_111(x) x, BOOST_PP_SEQ_ENUM_110
#define BOOST_PP_SEQ_ENUM_112(x) x, BOOST_PP_SEQ_ENUM_111
#define BOOST_PP_SEQ_ENUM_113(x) x, BOOST_PP_SEQ_ENUM_112
#define BOOST_PP_SEQ_ENUM_114(x) x, BOOST_PP_SEQ_ENUM_113
#define BOOST_PP_SEQ_ENUM_115(x) x, BOOST_PP_SEQ_ENUM_114
#define BOOST_PP_SEQ_ENUM_116(x) x, BOOST_PP_SEQ_ENUM_115
#define BOOST_PP_SEQ_ENUM_117(x) x, BOOST_PP_SEQ_ENUM_116
#define BOOST_PP_SEQ_ENUM_118(x) x, BOOST_PP_SEQ_ENUM_117
#define BOOST_PP_SEQ_ENUM_119(x) x, BOOST_PP_SEQ_ENUM_118
#define BOOST_PP_SEQ_ENUM_120(x) x, BOOST_PP_SEQ_ENUM_119
#define BOOST_PP_SEQ_ENUM_121(x) x, BOOST_PP_SEQ_ENUM_120
#define BOOST_PP_SEQ_ENUM_122(x) x, BOOST_PP_SEQ_ENUM_121
#define BOOST_PP_SEQ_ENUM_123(x) x, BOOST_PP_SEQ_ENUM_122
#define BOOST_PP_SEQ_ENUM_124(x) x, BOOST_PP_SEQ_ENUM_123
#define BOOST_PP_SEQ_ENUM_125(x) x, BOOST_PP_SEQ_ENUM_124
#define BOOST_PP_SEQ_ENUM_126(x) x, BOOST_PP_SEQ_ENUM_125
#define BOOST_PP_SEQ_ENUM_127(x) x, BOOST_PP_SEQ_ENUM_126
#define BOOST_PP_SEQ_ENUM_128(x) x, BOOST_PP_SEQ_ENUM_127
#define BOOST_PP_SEQ_ENUM_129(x) x, BOOST_PP_SEQ_ENUM_128
#define BOOST_PP_SEQ_ENUM_130(x) x, BOOST_PP_SEQ_ENUM_129
#define BOOST_PP_SEQ_ENUM_131(x) x, BOOST_PP_SEQ_ENUM_130
#define BOOST_PP_SEQ_ENUM_132(x) x, BOOST_PP_SEQ_ENUM_131
#define BOOST_PP_SEQ_ENUM_133(x) x, BOOST_PP_SEQ_ENUM_132
#define BOOST_PP_SEQ_ENUM_134(x) x, BOOST_PP_SEQ_ENUM_133
#define BOOST_PP_SEQ_ENUM_135(x) x, BOOST_PP_SEQ_ENUM_134
#define BOOST_PP_SEQ_ENUM_136(x) x, BOOST_PP_SEQ_ENUM_135
#define BOOST_PP_SEQ_ENUM_137(x) x, BOOST_PP_SEQ_ENUM_136
#define BOOST_PP_SEQ_ENUM_138(x) x, BOOST_PP_SEQ_ENUM_137
#define BOOST_PP_SEQ_ENUM_139(x) x, BOOST_PP_SEQ_ENUM_138
#define BOOST_PP_SEQ_ENUM_140(x) x, BOOST_PP_SEQ_ENUM_139
#define BOOST_PP_SEQ_ENUM_141(x) x, BOOST_PP_SEQ_ENUM_140
#define BOOST_PP_SEQ_ENUM_142(x) x, BOOST_PP_SEQ_ENUM_141
#define BOOST_PP_SEQ_ENUM_143(x) x, BOOST_PP_SEQ_ENUM_142
#define BOOST_PP_SEQ_ENUM_144(x) x, BOOST_PP_SEQ_ENUM_143
#define BOOST_PP_SEQ_ENUM_145(x) x, BOOST_PP_SEQ_ENUM_144
#define BOOST_PP_SEQ_ENUM_146(x) x, BOOST_PP_SEQ_ENUM_145
#define BOOST_PP_SEQ_ENUM_147(x) x, BOOST_PP_SEQ_ENUM_146
#define BOOST_PP_SEQ_ENUM_148(x) x, BOOST_PP_SEQ_ENUM_147
#define BOOST_PP_SEQ_ENUM_149(x) x, BOOST_PP_SEQ_ENUM_148
#define BOOST_PP_SEQ_ENUM_150(x) x, BOOST_PP_SEQ_ENUM_149
#define BOOST_PP_SEQ_ENUM_151(x) x, BOOST_PP_SEQ_ENUM_150
#define BOOST_PP_SEQ_ENUM_152(x) x, BOOST_PP_SEQ_ENUM_151
#define BOOST_PP_SEQ_ENUM_153(x) x, BOOST_PP_SEQ_ENUM_152
#define BOOST_PP_SEQ_ENUM_154(x) x, BOOST_PP_SEQ_ENUM_153
#define BOOST_PP_SEQ_ENUM_155(x) x, BOOST_PP_SEQ_ENUM_154
#define BOOST_PP_SEQ_ENUM_156(x) x, BOOST_PP_SEQ_ENUM_155
#define BOOST_PP_SEQ_ENUM_157(x) x, BOOST_PP_SEQ_ENUM_156
#define BOOST_PP_SEQ_ENUM_158(x) x, BOOST_PP_SEQ_ENUM_157
#define BOOST_PP_SEQ_ENUM_159(x) x, BOOST_PP_SEQ_ENUM_158
#define BOOST_PP_SEQ_ENUM_160(x) x, BOOST_PP_SEQ_ENUM_159
#define BOOST_PP_SEQ_ENUM_161(x) x, BOOST_PP_SEQ_ENUM_160
#define BOOST_PP_SEQ_ENUM_162(x) x, BOOST_PP_SEQ_ENUM_161
#define BOOST_PP_SEQ_ENUM_163(x) x, BOOST_PP_SEQ_ENUM_162
#define BOOST_PP_SEQ_ENUM_164(x) x, BOOST_PP_SEQ_ENUM_163
#define BOOST_PP_SEQ_ENUM_165(x) x, BOOST_PP_SEQ_ENUM_164
#define BOOST_PP_SEQ_ENUM_166(x) x, BOOST_PP_SEQ_ENUM_165
#define BOOST_PP_SEQ_ENUM_167(x) x, BOOST_PP_SEQ_ENUM_166
#define BOOST_PP_SEQ_ENUM_168(x) x, BOOST_PP_SEQ_ENUM_167
#define BOOST_PP_SEQ_ENUM_169(x) x, BOOST_PP_SEQ_ENUM_168
#define BOOST_PP_SEQ_ENUM_170(x) x, BOOST_PP_SEQ_ENUM_169
#define BOOST_PP_SEQ_ENUM_171(x) x, BOOST_PP_SEQ_ENUM_170
#define BOOST_PP_SEQ_ENUM_172(x) x, BOOST_PP_SEQ_ENUM_171
#define BOOST_PP_SEQ_ENUM_173(x) x, BOOST_PP_SEQ_ENUM_172
#define BOOST_PP_SEQ_ENUM_174(x) x, BOOST_PP_SEQ_ENUM_173
#define BOOST_PP_SEQ_ENUM_175(x) x, BOOST_PP_SEQ_ENUM_174
#define BOOST_PP_SEQ_ENUM_176(x) x, BOOST_PP_SEQ_ENUM_175
#define BOOST_PP_SEQ_ENUM_177(x) x, BOOST_PP_SEQ_ENUM_176
#define BOOST_PP_SEQ_ENUM_178(x) x, BOOST_PP_SEQ_ENUM_177
#define BOOST_PP_SEQ_ENUM_179(x) x, BOOST_PP_SEQ_ENUM_178
#define BOOST_PP_SEQ_ENUM_180(x) x, BOOST_PP_SEQ_ENUM_179
#define BOOST_PP_SEQ_ENUM_181(x) x, BOOST_PP_SEQ_ENUM_180
#define BOOST_PP_SEQ_ENUM_182(x) x, BOOST_PP_SEQ_ENUM_181
#define BOOST_PP_SEQ_ENUM_183(x) x, BOOST_PP_SEQ_ENUM_182
#define BOOST_PP_SEQ_ENUM_184(x) x, BOOST_PP_SEQ_ENUM_183
#define BOOST_PP_SEQ_ENUM_185(x) x, BOOST_PP_SEQ_ENUM_184
#define BOOST_PP_SEQ_ENUM_186(x) x, BOOST_PP_SEQ_ENUM_185
#define BOOST_PP_SEQ_ENUM_187(x) x, BOOST_PP_SEQ_ENUM_186
#define BOOST_PP_SEQ_ENUM_188(x) x, BOOST_PP_SEQ_ENUM_187
#define BOOST_PP_SEQ_ENUM_189(x) x, BOOST_PP_SEQ_ENUM_188
#define BOOST_PP_SEQ_ENUM_190(x) x, BOOST_PP_SEQ_ENUM_189
#define BOOST_PP_SEQ_ENUM_191(x) x, BOOST_PP_SEQ_ENUM_190
#define BOOST_PP_SEQ_ENUM_192(x) x, BOOST_PP_SEQ_ENUM_191
#define BOOST_PP_SEQ_ENUM_193(x) x, BOOST_PP_SEQ_ENUM_192
#define BOOST_PP_SEQ_ENUM_194(x) x, BOOST_PP_SEQ_ENUM_193
#define BOOST_PP_SEQ_ENUM_195(x) x, BOOST_PP_SEQ_ENUM_194
#define BOOST_PP_SEQ_ENUM_196(x) x, BOOST_PP_SEQ_ENUM_195
#define BOOST_PP_SEQ_ENUM_197(x) x, BOOST_PP_SEQ_ENUM_196
#define BOOST_PP_SEQ_ENUM_198(x) x, BOOST_PP_SEQ_ENUM_197
#define BOOST_PP_SEQ_ENUM_199(x) x, BOOST_PP_SEQ_ENUM_198
#define BOOST_PP_SEQ_ENUM_200(x) x, BOOST_PP_SEQ_ENUM_199
#define BOOST_PP_SEQ_ENUM_201(x) x, BOOST_PP_SEQ_ENUM_200
#define BOOST_PP_SEQ_ENUM_202(x) x, BOOST_PP_SEQ_ENUM_201
#define BOOST_PP_SEQ_ENUM_203(x) x, BOOST_PP_SEQ_ENUM_202
#define BOOST_PP_SEQ_ENUM_204(x) x, BOOST_PP_SEQ_ENUM_203
#define BOOST_PP_SEQ_ENUM_205(x) x, BOOST_PP_SEQ_ENUM_204
#define BOOST_PP_SEQ_ENUM_206(x) x, BOOST_PP_SEQ_ENUM_205
#define BOOST_PP_SEQ_ENUM_207(x) x, BOOST_PP_SEQ_ENUM_206
#define BOOST_PP_SEQ_ENUM_208(x) x, BOOST_PP_SEQ_ENUM_207
#define BOOST_PP_SEQ_ENUM_209(x) x, BOOST_PP_SEQ_ENUM_208
#define BOOST_PP_SEQ_ENUM_210(x) x, BOOST_PP_SEQ_ENUM_209
#define BOOST_PP_SEQ_ENUM_211(x) x, BOOST_PP_SEQ_ENUM_210
#define BOOST_PP_SEQ_ENUM_212(x) x, BOOST_PP_SEQ_ENUM_211
#define BOOST_PP_SEQ_ENUM_213(x) x, BOOST_PP_SEQ_ENUM_212
#define BOOST_PP_SEQ_ENUM_214(x) x, BOOST_PP_SEQ_ENUM_213
#define BOOST_PP_SEQ_ENUM_215(x) x, BOOST_PP_SEQ_ENUM_214
#define BOOST_PP_SEQ_ENUM_216(x) x, BOOST_PP_SEQ_ENUM_215
#define BOOST_PP_SEQ_ENUM_217(x) x, BOOST_PP_SEQ_ENUM_216
#define BOOST_PP_SEQ_ENUM_218(x) x, BOOST_PP_SEQ_ENUM_217
#define BOOST_PP_SEQ_ENUM_219(x) x, BOOST_PP_SEQ_ENUM_218
#define BOOST_PP_SEQ_ENUM_220(x) x, BOOST_PP_SEQ_ENUM_219
#define BOOST_PP_SEQ_ENUM_221(x) x, BOOST_PP_SEQ_ENUM_220
#define BOOST_PP_SEQ_ENUM_222(x) x, BOOST_PP_SEQ_ENUM_221
#define BOOST_PP_SEQ_ENUM_223(x) x, BOOST_PP_SEQ_ENUM_222
#define BOOST_PP_SEQ_ENUM_224(x) x, BOOST_PP_SEQ_ENUM_223
#define BOOST_PP_SEQ_ENUM_225(x) x, BOOST_PP_SEQ_ENUM_224
#define BOOST_PP_SEQ_ENUM_226(x) x, BOOST_PP_SEQ_ENUM_225
#define BOOST_PP_SEQ_ENUM_227(x) x, BOOST_PP_SEQ_ENUM_226
#define BOOST_PP_SEQ_ENUM_228(x) x, BOOST_PP_SEQ_ENUM_227
#define BOOST_PP_SEQ_ENUM_229(x) x, BOOST_PP_SEQ_ENUM_228
#define BOOST_PP_SEQ_ENUM_230(x) x, BOOST_PP_SEQ_ENUM_229
#define BOOST_PP_SEQ_ENUM_231(x) x, BOOST_PP_SEQ_ENUM_230
#define BOOST_PP_SEQ_ENUM_232(x) x, BOOST_PP_SEQ_ENUM_231
#define BOOST_PP_SEQ_ENUM_233(x) x, BOOST_PP_SEQ_ENUM_232
#define BOOST_PP_SEQ_ENUM_234(x) x, BOOST_PP_SEQ_ENUM_233
#define BOOST_PP_SEQ_ENUM_235(x) x, BOOST_PP_SEQ_ENUM_234
#define BOOST_PP_SEQ_ENUM_236(x) x, BOOST_PP_SEQ_ENUM_235
#define BOOST_PP_SEQ_ENUM_237(x) x, BOOST_PP_SEQ_ENUM_236
#define BOOST_PP_SEQ_ENUM_238(x) x, BOOST_PP_SEQ_ENUM_237
#define BOOST_PP_SEQ_ENUM_239(x) x, BOOST_PP_SEQ_ENUM_238
#define BOOST_PP_SEQ_ENUM_240(x) x, BOOST_PP_SEQ_ENUM_239
#define BOOST_PP_SEQ_ENUM_241(x) x, BOOST_PP_SEQ_ENUM_240
#define BOOST_PP_SEQ_ENUM_242(x) x, BOOST_PP_SEQ_ENUM_241
#define BOOST_PP_SEQ_ENUM_243(x) x, BOOST_PP_SEQ_ENUM_242
#define BOOST_PP_SEQ_ENUM_244(x) x, BOOST_PP_SEQ_ENUM_243
#define BOOST_PP_SEQ_ENUM_245(x) x, BOOST_PP_SEQ_ENUM_244
#define BOOST_PP_SEQ_ENUM_246(x) x, BOOST_PP_SEQ_ENUM_245
#define BOOST_PP_SEQ_ENUM_247(x) x, BOOST_PP_SEQ_ENUM_246
#define BOOST_PP_SEQ_ENUM_248(x) x, BOOST_PP_SEQ_ENUM_247
#define BOOST_PP_SEQ_ENUM_249(x) x, BOOST_PP_SEQ_ENUM_248
#define BOOST_PP_SEQ_ENUM_250(x) x, BOOST_PP_SEQ_ENUM_249
#define BOOST_PP_SEQ_ENUM_251(x) x, BOOST_PP_SEQ_ENUM_250
#define BOOST_PP_SEQ_ENUM_252(x) x, BOOST_PP_SEQ_ENUM_251
#define BOOST_PP_SEQ_ENUM_253(x) x, BOOST_PP_SEQ_ENUM_252
#define BOOST_PP_SEQ_ENUM_254(x) x, BOOST_PP_SEQ_ENUM_253
#define BOOST_PP_SEQ_ENUM_255(x) x, BOOST_PP_SEQ_ENUM_254
#define BOOST_PP_SEQ_ENUM_256(x) x, BOOST_PP_SEQ_ENUM_255

#define BOOST_PP_SEQ_FILTER(pred, data, seq) BOOST_PP_SEQ_TAIL(BOOST_PP_TUPLE_ELEM(3, 2, BOOST_PP_SEQ_FOLD_LEFT(BOOST_PP_SEQ_FILTER_O, (pred, data, (nil)), seq)))
#define BOOST_PP_SEQ_FILTER_O(s, st, elem) BOOST_PP_SEQ_FILTER_O_IM(s, BOOST_PP_TUPLE_REM_3 st, elem)
#define BOOST_PP_SEQ_FILTER_O_IM(s, im, elem) BOOST_PP_SEQ_FILTER_O_I(s, im, elem)
#define BOOST_PP_SEQ_FILTER_O_I(s, pred, data, res, elem) (pred, data, res BOOST_PP_EXPR_IF(pred(s, data, elem), (elem)))
#define BOOST_PP_SEQ_FILTER_S(s, pred, data, seq) BOOST_PP_SEQ_TAIL(BOOST_PP_TUPLE_ELEM(3, 2, BOOST_PP_SEQ_FOLD_LEFT_ ## s(BOOST_PP_SEQ_FILTER_O, (pred, data, (nil)), seq)))

#define BOOST_PP_SEQ_FIRST_N(n, seq) BOOST_PP_IF(n, BOOST_PP_TUPLE_ELEM, BOOST_PP_TUPLE_EAT_3)(2, 0, BOOST_PP_SEQ_SPLIT(n, seq (nil)))

#define BOOST_PP_SEQ_FOLD_LEFT BOOST_PP_CAT(BOOST_PP_SEQ_FOLD_LEFT_, BOOST_PP_AUTO_REC(BOOST_PP_SEQ_FOLD_LEFT_P, 256))
#define BOOST_PP_SEQ_FOLD_LEFT_P(n) BOOST_PP_CAT(BOOST_PP_SEQ_FOLD_LEFT_CHECK_, BOOST_PP_SEQ_FOLD_LEFT_I_ ## n(BOOST_PP_SEQ_FOLD_LEFT_O, BOOST_PP_NIL, (nil), 1))
#define BOOST_PP_SEQ_FOLD_LEFT_O(s, st, _) st
#define BOOST_PP_SEQ_FOLD_LEFT_257(op, st, ss) BOOST_PP_ERROR(0x0005)
#define BOOST_PP_SEQ_FOLD_LEFT_I_257(op, st, ss, sz) BOOST_PP_ERROR(0x0005)
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_NIL 1
#define BOOST_PP_SEQ_FOLD_LEFT_F(op, st, ss, sz) st

#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_1(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_2(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_3(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_4(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_5(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_6(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_7(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_8(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_9(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_10(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_11(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_12(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_13(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_14(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_15(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_16(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_17(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_18(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_19(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_20(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_21(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_22(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_23(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_24(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_25(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_26(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_27(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_28(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_29(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_30(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_31(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_32(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_33(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_34(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_35(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_36(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_37(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_38(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_39(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_40(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_41(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_42(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_43(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_44(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_45(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_46(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_47(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_48(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_49(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_50(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_51(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_52(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_53(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_54(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_55(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_56(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_57(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_58(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_59(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_60(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_61(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_62(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_63(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_64(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_65(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_66(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_67(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_68(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_69(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_70(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_71(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_72(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_73(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_74(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_75(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_76(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_77(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_78(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_79(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_80(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_81(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_82(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_83(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_84(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_85(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_86(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_87(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_88(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_89(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_90(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_91(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_92(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_93(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_94(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_95(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_96(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_97(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_98(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_99(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_100(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_101(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_102(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_103(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_104(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_105(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_106(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_107(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_108(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_109(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_110(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_111(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_112(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_113(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_114(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_115(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_116(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_117(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_118(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_119(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_120(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_121(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_122(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_123(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_124(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_125(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_126(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_127(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_128(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_129(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_130(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_131(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_132(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_133(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_134(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_135(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_136(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_137(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_138(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_139(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_140(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_141(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_142(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_143(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_144(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_145(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_146(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_147(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_148(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_149(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_150(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_151(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_152(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_153(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_154(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_155(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_156(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_157(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_158(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_159(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_160(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_161(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_162(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_163(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_164(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_165(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_166(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_167(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_168(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_169(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_170(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_171(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_172(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_173(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_174(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_175(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_176(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_177(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_178(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_179(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_180(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_181(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_182(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_183(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_184(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_185(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_186(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_187(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_188(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_189(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_190(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_191(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_192(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_193(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_194(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_195(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_196(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_197(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_198(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_199(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_200(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_201(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_202(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_203(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_204(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_205(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_206(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_207(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_208(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_209(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_210(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_211(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_212(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_213(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_214(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_215(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_216(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_217(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_218(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_219(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_220(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_221(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_222(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_223(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_224(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_225(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_226(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_227(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_228(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_229(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_230(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_231(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_232(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_233(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_234(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_235(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_236(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_237(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_238(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_239(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_240(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_241(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_242(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_243(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_244(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_245(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_246(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_247(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_248(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_249(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_250(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_251(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_252(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_253(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_254(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_255(op, st, ss, sz) 0
#define BOOST_PP_SEQ_FOLD_LEFT_CHECK_BOOST_PP_SEQ_FOLD_LEFT_I_256(op, st, ss, sz) 0

#define BOOST_PP_SEQ_FOLD_LEFT_1(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_1(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_2(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_2(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_3(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_3(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_4(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_4(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_5(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_5(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_6(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_6(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_7(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_7(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_8(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_8(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_9(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_9(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_10(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_10(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_11(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_11(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_12(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_12(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_13(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_13(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_14(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_14(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_15(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_15(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_16(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_16(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_17(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_17(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_18(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_18(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_19(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_19(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_20(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_20(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_21(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_21(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_22(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_22(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_23(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_23(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_24(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_24(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_25(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_25(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_26(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_26(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_27(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_27(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_28(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_28(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_29(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_29(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_30(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_30(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_31(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_31(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_32(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_32(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_33(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_33(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_34(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_34(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_35(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_35(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_36(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_36(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_37(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_37(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_38(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_38(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_39(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_39(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_40(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_40(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_41(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_41(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_42(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_42(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_43(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_43(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_44(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_44(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_45(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_45(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_46(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_46(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_47(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_47(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_48(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_48(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_49(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_49(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_50(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_50(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_51(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_51(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_52(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_52(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_53(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_53(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_54(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_54(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_55(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_55(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_56(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_56(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_57(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_57(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_58(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_58(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_59(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_59(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_60(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_60(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_61(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_61(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_62(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_62(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_63(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_63(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_64(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_64(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_65(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_65(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_66(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_66(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_67(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_67(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_68(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_68(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_69(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_69(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_70(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_70(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_71(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_71(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_72(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_72(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_73(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_73(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_74(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_74(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_75(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_75(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_76(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_76(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_77(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_77(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_78(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_78(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_79(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_79(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_80(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_80(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_81(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_81(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_82(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_82(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_83(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_83(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_84(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_84(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_85(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_85(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_86(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_86(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_87(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_87(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_88(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_88(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_89(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_89(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_90(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_90(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_91(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_91(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_92(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_92(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_93(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_93(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_94(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_94(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_95(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_95(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_96(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_96(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_97(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_97(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_98(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_98(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_99(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_99(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_100(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_100(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_101(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_101(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_102(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_102(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_103(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_103(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_104(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_104(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_105(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_105(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_106(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_106(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_107(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_107(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_108(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_108(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_109(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_109(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_110(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_110(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_111(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_111(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_112(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_112(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_113(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_113(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_114(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_114(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_115(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_115(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_116(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_116(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_117(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_117(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_118(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_118(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_119(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_119(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_120(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_120(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_121(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_121(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_122(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_122(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_123(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_123(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_124(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_124(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_125(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_125(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_126(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_126(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_127(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_127(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_128(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_128(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_129(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_129(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_130(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_130(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_131(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_131(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_132(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_132(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_133(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_133(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_134(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_134(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_135(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_135(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_136(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_136(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_137(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_137(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_138(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_138(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_139(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_139(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_140(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_140(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_141(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_141(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_142(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_142(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_143(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_143(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_144(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_144(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_145(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_145(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_146(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_146(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_147(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_147(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_148(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_148(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_149(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_149(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_150(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_150(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_151(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_151(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_152(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_152(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_153(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_153(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_154(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_154(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_155(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_155(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_156(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_156(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_157(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_157(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_158(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_158(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_159(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_159(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_160(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_160(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_161(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_161(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_162(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_162(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_163(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_163(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_164(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_164(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_165(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_165(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_166(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_166(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_167(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_167(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_168(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_168(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_169(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_169(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_170(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_170(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_171(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_171(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_172(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_172(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_173(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_173(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_174(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_174(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_175(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_175(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_176(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_176(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_177(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_177(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_178(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_178(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_179(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_179(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_180(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_180(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_181(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_181(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_182(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_182(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_183(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_183(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_184(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_184(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_185(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_185(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_186(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_186(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_187(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_187(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_188(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_188(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_189(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_189(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_190(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_190(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_191(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_191(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_192(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_192(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_193(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_193(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_194(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_194(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_195(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_195(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_196(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_196(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_197(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_197(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_198(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_198(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_199(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_199(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_200(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_200(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_201(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_201(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_202(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_202(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_203(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_203(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_204(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_204(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_205(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_205(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_206(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_206(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_207(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_207(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_208(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_208(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_209(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_209(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_210(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_210(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_211(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_211(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_212(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_212(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_213(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_213(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_214(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_214(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_215(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_215(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_216(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_216(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_217(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_217(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_218(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_218(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_219(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_219(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_220(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_220(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_221(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_221(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_222(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_222(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_223(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_223(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_224(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_224(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_225(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_225(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_226(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_226(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_227(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_227(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_228(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_228(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_229(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_229(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_230(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_230(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_231(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_231(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_232(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_232(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_233(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_233(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_234(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_234(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_235(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_235(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_236(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_236(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_237(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_237(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_238(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_238(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_239(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_239(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_240(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_240(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_241(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_241(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_242(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_242(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_243(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_243(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_244(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_244(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_245(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_245(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_246(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_246(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_247(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_247(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_248(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_248(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_249(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_249(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_250(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_250(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_251(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_251(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_252(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_252(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_253(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_253(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_254(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_254(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_255(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_255(op, st, ss, BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_LEFT_256(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_256(op, st, ss, BOOST_PP_SEQ_SIZE(ss))

#define BOOST_PP_SEQ_FOLD_LEFT_I_1(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_2, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(2, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_2(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_3, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(3, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_3(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_4, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(4, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_4(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_5, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(5, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_5(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_6, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(6, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_6(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_7, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(7, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_7(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_8, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(8, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_8(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_9, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(9, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_9(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_10, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(10, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_10(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_11, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(11, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_11(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_12, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(12, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_12(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_13, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(13, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_13(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_14, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(14, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_14(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_15, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(15, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_15(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_16, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(16, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_16(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_17, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(17, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_17(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_18, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(18, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_18(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_19, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(19, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_19(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_20, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(20, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_20(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_21, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(21, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_21(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_22, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(22, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_22(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_23, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(23, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_23(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_24, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(24, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_24(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_25, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(25, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_25(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_26, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(26, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_26(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_27, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(27, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_27(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_28, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(28, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_28(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_29, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(29, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_29(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_30, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(30, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_30(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_31, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(31, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_31(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_32, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(32, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_32(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_33, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(33, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_33(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_34, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(34, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_34(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_35, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(35, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_35(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_36, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(36, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_36(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_37, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(37, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_37(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_38, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(38, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_38(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_39, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(39, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_39(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_40, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(40, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_40(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_41, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(41, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_41(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_42, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(42, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_42(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_43, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(43, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_43(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_44, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(44, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_44(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_45, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(45, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_45(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_46, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(46, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_46(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_47, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(47, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_47(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_48, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(48, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_48(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_49, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(49, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_49(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_50, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(50, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_50(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_51, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(51, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_51(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_52, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(52, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_52(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_53, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(53, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_53(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_54, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(54, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_54(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_55, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(55, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_55(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_56, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(56, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_56(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_57, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(57, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_57(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_58, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(58, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_58(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_59, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(59, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_59(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_60, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(60, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_60(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_61, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(61, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_61(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_62, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(62, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_62(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_63, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(63, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_63(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_64, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(64, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_64(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_65, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(65, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_65(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_66, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(66, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_66(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_67, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(67, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_67(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_68, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(68, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_68(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_69, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(69, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_69(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_70, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(70, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_70(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_71, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(71, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_71(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_72, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(72, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_72(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_73, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(73, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_73(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_74, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(74, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_74(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_75, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(75, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_75(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_76, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(76, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_76(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_77, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(77, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_77(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_78, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(78, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_78(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_79, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(79, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_79(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_80, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(80, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_80(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_81, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(81, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_81(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_82, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(82, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_82(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_83, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(83, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_83(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_84, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(84, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_84(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_85, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(85, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_85(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_86, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(86, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_86(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_87, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(87, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_87(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_88, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(88, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_88(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_89, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(89, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_89(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_90, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(90, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_90(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_91, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(91, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_91(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_92, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(92, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_92(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_93, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(93, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_93(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_94, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(94, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_94(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_95, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(95, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_95(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_96, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(96, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_96(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_97, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(97, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_97(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_98, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(98, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_98(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_99, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(99, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_99(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_100, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(100, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_100(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_101, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(101, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_101(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_102, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(102, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_102(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_103, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(103, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_103(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_104, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(104, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_104(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_105, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(105, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_105(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_106, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(106, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_106(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_107, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(107, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_107(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_108, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(108, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_108(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_109, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(109, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_109(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_110, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(110, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_110(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_111, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(111, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_111(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_112, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(112, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_112(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_113, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(113, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_113(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_114, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(114, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_114(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_115, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(115, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_115(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_116, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(116, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_116(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_117, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(117, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_117(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_118, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(118, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_118(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_119, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(119, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_119(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_120, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(120, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_120(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_121, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(121, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_121(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_122, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(122, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_122(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_123, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(123, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_123(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_124, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(124, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_124(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_125, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(125, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_125(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_126, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(126, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_126(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_127, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(127, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_127(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_128, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(128, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_128(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_129, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(129, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_129(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_130, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(130, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_130(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_131, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(131, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_131(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_132, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(132, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_132(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_133, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(133, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_133(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_134, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(134, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_134(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_135, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(135, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_135(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_136, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(136, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_136(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_137, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(137, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_137(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_138, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(138, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_138(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_139, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(139, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_139(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_140, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(140, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_140(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_141, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(141, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_141(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_142, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(142, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_142(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_143, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(143, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_143(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_144, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(144, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_144(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_145, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(145, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_145(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_146, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(146, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_146(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_147, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(147, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_147(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_148, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(148, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_148(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_149, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(149, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_149(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_150, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(150, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_150(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_151, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(151, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_151(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_152, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(152, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_152(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_153, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(153, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_153(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_154, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(154, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_154(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_155, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(155, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_155(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_156, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(156, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_156(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_157, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(157, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_157(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_158, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(158, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_158(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_159, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(159, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_159(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_160, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(160, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_160(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_161, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(161, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_161(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_162, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(162, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_162(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_163, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(163, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_163(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_164, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(164, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_164(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_165, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(165, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_165(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_166, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(166, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_166(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_167, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(167, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_167(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_168, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(168, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_168(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_169, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(169, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_169(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_170, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(170, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_170(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_171, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(171, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_171(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_172, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(172, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_172(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_173, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(173, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_173(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_174, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(174, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_174(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_175, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(175, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_175(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_176, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(176, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_176(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_177, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(177, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_177(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_178, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(178, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_178(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_179, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(179, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_179(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_180, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(180, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_180(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_181, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(181, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_181(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_182, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(182, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_182(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_183, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(183, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_183(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_184, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(184, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_184(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_185, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(185, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_185(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_186, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(186, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_186(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_187, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(187, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_187(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_188, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(188, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_188(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_189, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(189, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_189(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_190, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(190, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_190(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_191, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(191, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_191(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_192, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(192, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_192(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_193, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(193, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_193(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_194, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(194, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_194(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_195, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(195, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_195(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_196, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(196, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_196(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_197, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(197, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_197(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_198, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(198, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_198(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_199, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(199, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_199(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_200, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(200, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_200(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_201, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(201, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_201(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_202, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(202, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_202(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_203, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(203, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_203(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_204, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(204, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_204(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_205, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(205, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_205(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_206, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(206, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_206(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_207, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(207, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_207(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_208, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(208, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_208(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_209, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(209, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_209(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_210, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(210, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_210(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_211, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(211, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_211(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_212, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(212, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_212(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_213, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(213, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_213(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_214, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(214, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_214(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_215, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(215, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_215(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_216, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(216, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_216(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_217, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(217, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_217(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_218, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(218, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_218(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_219, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(219, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_219(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_220, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(220, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_220(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_221, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(221, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_221(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_222, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(222, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_222(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_223, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(223, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_223(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_224, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(224, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_224(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_225, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(225, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_225(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_226, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(226, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_226(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_227, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(227, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_227(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_228, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(228, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_228(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_229, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(229, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_229(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_230, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(230, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_230(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_231, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(231, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_231(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_232, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(232, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_232(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_233, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(233, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_233(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_234, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(234, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_234(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_235, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(235, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_235(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_236, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(236, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_236(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_237, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(237, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_237(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_238, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(238, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_238(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_239, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(239, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_239(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_240, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(240, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_240(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_241, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(241, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_241(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_242, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(242, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_242(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_243, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(243, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_243(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_244, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(244, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_244(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_245, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(245, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_245(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_246, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(246, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_246(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_247, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(247, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_247(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_248, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(248, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_248(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_249, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(249, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_249(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_250, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(250, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_250(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_251, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(251, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_251(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_252, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(252, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_252(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_253, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(253, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_253(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_254, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(254, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_254(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_255, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(255, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_255(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_256, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(256, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))
#define BOOST_PP_SEQ_FOLD_LEFT_I_256(op, st, ss, sz) BOOST_PP_IF(BOOST_PP_DEC(sz), BOOST_PP_SEQ_FOLD_LEFT_I_257, BOOST_PP_SEQ_FOLD_LEFT_F)(op, op(257, st, BOOST_PP_SEQ_HEAD(ss)), BOOST_PP_SEQ_TAIL(ss), BOOST_PP_DEC(sz))

#define BOOST_PP_SEQ_FOLD_RIGHT BOOST_PP_CAT(BOOST_PP_SEQ_FOLD_RIGHT_, BOOST_PP_AUTO_REC(BOOST_PP_SEQ_FOLD_LEFT_P, 256))
#define BOOST_PP_SEQ_FOLD_RIGHT_257(op, st, ss) BOOST_PP_ERROR(0x0005)
#define BOOST_PP_SEQ_FOLD_RIGHT_1(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_1(op, st, BOOST_PP_SEQ_REVERSE_S(2, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_2(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_2(op, st, BOOST_PP_SEQ_REVERSE_S(3, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_3(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_3(op, st, BOOST_PP_SEQ_REVERSE_S(4, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_4(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_4(op, st, BOOST_PP_SEQ_REVERSE_S(5, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_5(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_5(op, st, BOOST_PP_SEQ_REVERSE_S(6, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_6(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_6(op, st, BOOST_PP_SEQ_REVERSE_S(7, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_7(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_7(op, st, BOOST_PP_SEQ_REVERSE_S(8, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_8(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_8(op, st, BOOST_PP_SEQ_REVERSE_S(9, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_9(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_9(op, st, BOOST_PP_SEQ_REVERSE_S(10, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_10(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_10(op, st, BOOST_PP_SEQ_REVERSE_S(11, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_11(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_11(op, st, BOOST_PP_SEQ_REVERSE_S(12, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_12(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_12(op, st, BOOST_PP_SEQ_REVERSE_S(13, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_13(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_13(op, st, BOOST_PP_SEQ_REVERSE_S(14, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_14(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_14(op, st, BOOST_PP_SEQ_REVERSE_S(15, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_15(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_15(op, st, BOOST_PP_SEQ_REVERSE_S(16, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_16(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_16(op, st, BOOST_PP_SEQ_REVERSE_S(17, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_17(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_17(op, st, BOOST_PP_SEQ_REVERSE_S(18, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_18(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_18(op, st, BOOST_PP_SEQ_REVERSE_S(19, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_19(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_19(op, st, BOOST_PP_SEQ_REVERSE_S(20, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_20(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_20(op, st, BOOST_PP_SEQ_REVERSE_S(21, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_21(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_21(op, st, BOOST_PP_SEQ_REVERSE_S(22, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_22(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_22(op, st, BOOST_PP_SEQ_REVERSE_S(23, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_23(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_23(op, st, BOOST_PP_SEQ_REVERSE_S(24, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_24(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_24(op, st, BOOST_PP_SEQ_REVERSE_S(25, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_25(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_25(op, st, BOOST_PP_SEQ_REVERSE_S(26, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_26(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_26(op, st, BOOST_PP_SEQ_REVERSE_S(27, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_27(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_27(op, st, BOOST_PP_SEQ_REVERSE_S(28, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_28(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_28(op, st, BOOST_PP_SEQ_REVERSE_S(29, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_29(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_29(op, st, BOOST_PP_SEQ_REVERSE_S(30, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_30(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_30(op, st, BOOST_PP_SEQ_REVERSE_S(31, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_31(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_31(op, st, BOOST_PP_SEQ_REVERSE_S(32, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_32(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_32(op, st, BOOST_PP_SEQ_REVERSE_S(33, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_33(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_33(op, st, BOOST_PP_SEQ_REVERSE_S(34, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_34(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_34(op, st, BOOST_PP_SEQ_REVERSE_S(35, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_35(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_35(op, st, BOOST_PP_SEQ_REVERSE_S(36, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_36(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_36(op, st, BOOST_PP_SEQ_REVERSE_S(37, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_37(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_37(op, st, BOOST_PP_SEQ_REVERSE_S(38, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_38(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_38(op, st, BOOST_PP_SEQ_REVERSE_S(39, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_39(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_39(op, st, BOOST_PP_SEQ_REVERSE_S(40, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_40(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_40(op, st, BOOST_PP_SEQ_REVERSE_S(41, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_41(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_41(op, st, BOOST_PP_SEQ_REVERSE_S(42, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_42(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_42(op, st, BOOST_PP_SEQ_REVERSE_S(43, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_43(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_43(op, st, BOOST_PP_SEQ_REVERSE_S(44, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_44(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_44(op, st, BOOST_PP_SEQ_REVERSE_S(45, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_45(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_45(op, st, BOOST_PP_SEQ_REVERSE_S(46, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_46(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_46(op, st, BOOST_PP_SEQ_REVERSE_S(47, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_47(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_47(op, st, BOOST_PP_SEQ_REVERSE_S(48, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_48(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_48(op, st, BOOST_PP_SEQ_REVERSE_S(49, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_49(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_49(op, st, BOOST_PP_SEQ_REVERSE_S(50, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_50(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_50(op, st, BOOST_PP_SEQ_REVERSE_S(51, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_51(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_51(op, st, BOOST_PP_SEQ_REVERSE_S(52, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_52(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_52(op, st, BOOST_PP_SEQ_REVERSE_S(53, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_53(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_53(op, st, BOOST_PP_SEQ_REVERSE_S(54, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_54(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_54(op, st, BOOST_PP_SEQ_REVERSE_S(55, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_55(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_55(op, st, BOOST_PP_SEQ_REVERSE_S(56, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_56(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_56(op, st, BOOST_PP_SEQ_REVERSE_S(57, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_57(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_57(op, st, BOOST_PP_SEQ_REVERSE_S(58, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_58(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_58(op, st, BOOST_PP_SEQ_REVERSE_S(59, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_59(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_59(op, st, BOOST_PP_SEQ_REVERSE_S(60, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_60(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_60(op, st, BOOST_PP_SEQ_REVERSE_S(61, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_61(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_61(op, st, BOOST_PP_SEQ_REVERSE_S(62, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_62(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_62(op, st, BOOST_PP_SEQ_REVERSE_S(63, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_63(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_63(op, st, BOOST_PP_SEQ_REVERSE_S(64, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_64(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_64(op, st, BOOST_PP_SEQ_REVERSE_S(65, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_65(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_65(op, st, BOOST_PP_SEQ_REVERSE_S(66, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_66(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_66(op, st, BOOST_PP_SEQ_REVERSE_S(67, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_67(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_67(op, st, BOOST_PP_SEQ_REVERSE_S(68, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_68(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_68(op, st, BOOST_PP_SEQ_REVERSE_S(69, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_69(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_69(op, st, BOOST_PP_SEQ_REVERSE_S(70, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_70(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_70(op, st, BOOST_PP_SEQ_REVERSE_S(71, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_71(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_71(op, st, BOOST_PP_SEQ_REVERSE_S(72, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_72(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_72(op, st, BOOST_PP_SEQ_REVERSE_S(73, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_73(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_73(op, st, BOOST_PP_SEQ_REVERSE_S(74, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_74(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_74(op, st, BOOST_PP_SEQ_REVERSE_S(75, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_75(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_75(op, st, BOOST_PP_SEQ_REVERSE_S(76, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_76(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_76(op, st, BOOST_PP_SEQ_REVERSE_S(77, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_77(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_77(op, st, BOOST_PP_SEQ_REVERSE_S(78, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_78(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_78(op, st, BOOST_PP_SEQ_REVERSE_S(79, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_79(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_79(op, st, BOOST_PP_SEQ_REVERSE_S(80, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_80(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_80(op, st, BOOST_PP_SEQ_REVERSE_S(81, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_81(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_81(op, st, BOOST_PP_SEQ_REVERSE_S(82, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_82(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_82(op, st, BOOST_PP_SEQ_REVERSE_S(83, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_83(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_83(op, st, BOOST_PP_SEQ_REVERSE_S(84, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_84(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_84(op, st, BOOST_PP_SEQ_REVERSE_S(85, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_85(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_85(op, st, BOOST_PP_SEQ_REVERSE_S(86, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_86(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_86(op, st, BOOST_PP_SEQ_REVERSE_S(87, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_87(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_87(op, st, BOOST_PP_SEQ_REVERSE_S(88, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_88(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_88(op, st, BOOST_PP_SEQ_REVERSE_S(89, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_89(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_89(op, st, BOOST_PP_SEQ_REVERSE_S(90, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_90(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_90(op, st, BOOST_PP_SEQ_REVERSE_S(91, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_91(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_91(op, st, BOOST_PP_SEQ_REVERSE_S(92, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_92(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_92(op, st, BOOST_PP_SEQ_REVERSE_S(93, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_93(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_93(op, st, BOOST_PP_SEQ_REVERSE_S(94, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_94(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_94(op, st, BOOST_PP_SEQ_REVERSE_S(95, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_95(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_95(op, st, BOOST_PP_SEQ_REVERSE_S(96, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_96(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_96(op, st, BOOST_PP_SEQ_REVERSE_S(97, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_97(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_97(op, st, BOOST_PP_SEQ_REVERSE_S(98, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_98(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_98(op, st, BOOST_PP_SEQ_REVERSE_S(99, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_99(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_99(op, st, BOOST_PP_SEQ_REVERSE_S(100, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_100(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_100(op, st, BOOST_PP_SEQ_REVERSE_S(101, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_101(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_101(op, st, BOOST_PP_SEQ_REVERSE_S(102, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_102(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_102(op, st, BOOST_PP_SEQ_REVERSE_S(103, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_103(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_103(op, st, BOOST_PP_SEQ_REVERSE_S(104, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_104(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_104(op, st, BOOST_PP_SEQ_REVERSE_S(105, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_105(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_105(op, st, BOOST_PP_SEQ_REVERSE_S(106, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_106(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_106(op, st, BOOST_PP_SEQ_REVERSE_S(107, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_107(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_107(op, st, BOOST_PP_SEQ_REVERSE_S(108, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_108(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_108(op, st, BOOST_PP_SEQ_REVERSE_S(109, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_109(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_109(op, st, BOOST_PP_SEQ_REVERSE_S(110, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_110(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_110(op, st, BOOST_PP_SEQ_REVERSE_S(111, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_111(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_111(op, st, BOOST_PP_SEQ_REVERSE_S(112, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_112(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_112(op, st, BOOST_PP_SEQ_REVERSE_S(113, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_113(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_113(op, st, BOOST_PP_SEQ_REVERSE_S(114, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_114(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_114(op, st, BOOST_PP_SEQ_REVERSE_S(115, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_115(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_115(op, st, BOOST_PP_SEQ_REVERSE_S(116, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_116(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_116(op, st, BOOST_PP_SEQ_REVERSE_S(117, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_117(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_117(op, st, BOOST_PP_SEQ_REVERSE_S(118, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_118(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_118(op, st, BOOST_PP_SEQ_REVERSE_S(119, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_119(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_119(op, st, BOOST_PP_SEQ_REVERSE_S(120, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_120(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_120(op, st, BOOST_PP_SEQ_REVERSE_S(121, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_121(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_121(op, st, BOOST_PP_SEQ_REVERSE_S(122, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_122(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_122(op, st, BOOST_PP_SEQ_REVERSE_S(123, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_123(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_123(op, st, BOOST_PP_SEQ_REVERSE_S(124, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_124(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_124(op, st, BOOST_PP_SEQ_REVERSE_S(125, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_125(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_125(op, st, BOOST_PP_SEQ_REVERSE_S(126, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_126(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_126(op, st, BOOST_PP_SEQ_REVERSE_S(127, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_127(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_127(op, st, BOOST_PP_SEQ_REVERSE_S(128, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_128(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_128(op, st, BOOST_PP_SEQ_REVERSE_S(129, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_129(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_129(op, st, BOOST_PP_SEQ_REVERSE_S(130, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_130(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_130(op, st, BOOST_PP_SEQ_REVERSE_S(131, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_131(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_131(op, st, BOOST_PP_SEQ_REVERSE_S(132, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_132(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_132(op, st, BOOST_PP_SEQ_REVERSE_S(133, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_133(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_133(op, st, BOOST_PP_SEQ_REVERSE_S(134, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_134(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_134(op, st, BOOST_PP_SEQ_REVERSE_S(135, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_135(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_135(op, st, BOOST_PP_SEQ_REVERSE_S(136, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_136(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_136(op, st, BOOST_PP_SEQ_REVERSE_S(137, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_137(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_137(op, st, BOOST_PP_SEQ_REVERSE_S(138, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_138(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_138(op, st, BOOST_PP_SEQ_REVERSE_S(139, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_139(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_139(op, st, BOOST_PP_SEQ_REVERSE_S(140, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_140(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_140(op, st, BOOST_PP_SEQ_REVERSE_S(141, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_141(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_141(op, st, BOOST_PP_SEQ_REVERSE_S(142, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_142(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_142(op, st, BOOST_PP_SEQ_REVERSE_S(143, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_143(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_143(op, st, BOOST_PP_SEQ_REVERSE_S(144, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_144(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_144(op, st, BOOST_PP_SEQ_REVERSE_S(145, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_145(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_145(op, st, BOOST_PP_SEQ_REVERSE_S(146, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_146(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_146(op, st, BOOST_PP_SEQ_REVERSE_S(147, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_147(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_147(op, st, BOOST_PP_SEQ_REVERSE_S(148, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_148(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_148(op, st, BOOST_PP_SEQ_REVERSE_S(149, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_149(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_149(op, st, BOOST_PP_SEQ_REVERSE_S(150, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_150(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_150(op, st, BOOST_PP_SEQ_REVERSE_S(151, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_151(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_151(op, st, BOOST_PP_SEQ_REVERSE_S(152, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_152(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_152(op, st, BOOST_PP_SEQ_REVERSE_S(153, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_153(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_153(op, st, BOOST_PP_SEQ_REVERSE_S(154, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_154(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_154(op, st, BOOST_PP_SEQ_REVERSE_S(155, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_155(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_155(op, st, BOOST_PP_SEQ_REVERSE_S(156, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_156(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_156(op, st, BOOST_PP_SEQ_REVERSE_S(157, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_157(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_157(op, st, BOOST_PP_SEQ_REVERSE_S(158, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_158(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_158(op, st, BOOST_PP_SEQ_REVERSE_S(159, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_159(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_159(op, st, BOOST_PP_SEQ_REVERSE_S(160, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_160(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_160(op, st, BOOST_PP_SEQ_REVERSE_S(161, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_161(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_161(op, st, BOOST_PP_SEQ_REVERSE_S(162, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_162(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_162(op, st, BOOST_PP_SEQ_REVERSE_S(163, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_163(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_163(op, st, BOOST_PP_SEQ_REVERSE_S(164, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_164(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_164(op, st, BOOST_PP_SEQ_REVERSE_S(165, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_165(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_165(op, st, BOOST_PP_SEQ_REVERSE_S(166, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_166(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_166(op, st, BOOST_PP_SEQ_REVERSE_S(167, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_167(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_167(op, st, BOOST_PP_SEQ_REVERSE_S(168, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_168(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_168(op, st, BOOST_PP_SEQ_REVERSE_S(169, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_169(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_169(op, st, BOOST_PP_SEQ_REVERSE_S(170, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_170(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_170(op, st, BOOST_PP_SEQ_REVERSE_S(171, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_171(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_171(op, st, BOOST_PP_SEQ_REVERSE_S(172, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_172(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_172(op, st, BOOST_PP_SEQ_REVERSE_S(173, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_173(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_173(op, st, BOOST_PP_SEQ_REVERSE_S(174, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_174(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_174(op, st, BOOST_PP_SEQ_REVERSE_S(175, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_175(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_175(op, st, BOOST_PP_SEQ_REVERSE_S(176, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_176(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_176(op, st, BOOST_PP_SEQ_REVERSE_S(177, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_177(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_177(op, st, BOOST_PP_SEQ_REVERSE_S(178, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_178(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_178(op, st, BOOST_PP_SEQ_REVERSE_S(179, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_179(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_179(op, st, BOOST_PP_SEQ_REVERSE_S(180, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_180(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_180(op, st, BOOST_PP_SEQ_REVERSE_S(181, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_181(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_181(op, st, BOOST_PP_SEQ_REVERSE_S(182, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_182(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_182(op, st, BOOST_PP_SEQ_REVERSE_S(183, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_183(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_183(op, st, BOOST_PP_SEQ_REVERSE_S(184, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_184(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_184(op, st, BOOST_PP_SEQ_REVERSE_S(185, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_185(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_185(op, st, BOOST_PP_SEQ_REVERSE_S(186, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_186(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_186(op, st, BOOST_PP_SEQ_REVERSE_S(187, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_187(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_187(op, st, BOOST_PP_SEQ_REVERSE_S(188, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_188(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_188(op, st, BOOST_PP_SEQ_REVERSE_S(189, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_189(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_189(op, st, BOOST_PP_SEQ_REVERSE_S(190, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_190(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_190(op, st, BOOST_PP_SEQ_REVERSE_S(191, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_191(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_191(op, st, BOOST_PP_SEQ_REVERSE_S(192, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_192(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_192(op, st, BOOST_PP_SEQ_REVERSE_S(193, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_193(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_193(op, st, BOOST_PP_SEQ_REVERSE_S(194, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_194(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_194(op, st, BOOST_PP_SEQ_REVERSE_S(195, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_195(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_195(op, st, BOOST_PP_SEQ_REVERSE_S(196, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_196(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_196(op, st, BOOST_PP_SEQ_REVERSE_S(197, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_197(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_197(op, st, BOOST_PP_SEQ_REVERSE_S(198, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_198(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_198(op, st, BOOST_PP_SEQ_REVERSE_S(199, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_199(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_199(op, st, BOOST_PP_SEQ_REVERSE_S(200, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_200(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_200(op, st, BOOST_PP_SEQ_REVERSE_S(201, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_201(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_201(op, st, BOOST_PP_SEQ_REVERSE_S(202, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_202(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_202(op, st, BOOST_PP_SEQ_REVERSE_S(203, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_203(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_203(op, st, BOOST_PP_SEQ_REVERSE_S(204, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_204(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_204(op, st, BOOST_PP_SEQ_REVERSE_S(205, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_205(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_205(op, st, BOOST_PP_SEQ_REVERSE_S(206, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_206(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_206(op, st, BOOST_PP_SEQ_REVERSE_S(207, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_207(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_207(op, st, BOOST_PP_SEQ_REVERSE_S(208, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_208(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_208(op, st, BOOST_PP_SEQ_REVERSE_S(209, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_209(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_209(op, st, BOOST_PP_SEQ_REVERSE_S(210, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_210(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_210(op, st, BOOST_PP_SEQ_REVERSE_S(211, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_211(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_211(op, st, BOOST_PP_SEQ_REVERSE_S(212, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_212(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_212(op, st, BOOST_PP_SEQ_REVERSE_S(213, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_213(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_213(op, st, BOOST_PP_SEQ_REVERSE_S(214, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_214(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_214(op, st, BOOST_PP_SEQ_REVERSE_S(215, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_215(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_215(op, st, BOOST_PP_SEQ_REVERSE_S(216, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_216(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_216(op, st, BOOST_PP_SEQ_REVERSE_S(217, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_217(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_217(op, st, BOOST_PP_SEQ_REVERSE_S(218, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_218(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_218(op, st, BOOST_PP_SEQ_REVERSE_S(219, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_219(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_219(op, st, BOOST_PP_SEQ_REVERSE_S(220, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_220(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_220(op, st, BOOST_PP_SEQ_REVERSE_S(221, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_221(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_221(op, st, BOOST_PP_SEQ_REVERSE_S(222, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_222(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_222(op, st, BOOST_PP_SEQ_REVERSE_S(223, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_223(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_223(op, st, BOOST_PP_SEQ_REVERSE_S(224, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_224(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_224(op, st, BOOST_PP_SEQ_REVERSE_S(225, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_225(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_225(op, st, BOOST_PP_SEQ_REVERSE_S(226, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_226(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_226(op, st, BOOST_PP_SEQ_REVERSE_S(227, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_227(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_227(op, st, BOOST_PP_SEQ_REVERSE_S(228, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_228(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_228(op, st, BOOST_PP_SEQ_REVERSE_S(229, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_229(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_229(op, st, BOOST_PP_SEQ_REVERSE_S(230, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_230(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_230(op, st, BOOST_PP_SEQ_REVERSE_S(231, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_231(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_231(op, st, BOOST_PP_SEQ_REVERSE_S(232, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_232(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_232(op, st, BOOST_PP_SEQ_REVERSE_S(233, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_233(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_233(op, st, BOOST_PP_SEQ_REVERSE_S(234, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_234(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_234(op, st, BOOST_PP_SEQ_REVERSE_S(235, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_235(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_235(op, st, BOOST_PP_SEQ_REVERSE_S(236, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_236(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_236(op, st, BOOST_PP_SEQ_REVERSE_S(237, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_237(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_237(op, st, BOOST_PP_SEQ_REVERSE_S(238, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_238(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_238(op, st, BOOST_PP_SEQ_REVERSE_S(239, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_239(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_239(op, st, BOOST_PP_SEQ_REVERSE_S(240, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_240(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_240(op, st, BOOST_PP_SEQ_REVERSE_S(241, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_241(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_241(op, st, BOOST_PP_SEQ_REVERSE_S(242, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_242(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_242(op, st, BOOST_PP_SEQ_REVERSE_S(243, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_243(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_243(op, st, BOOST_PP_SEQ_REVERSE_S(244, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_244(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_244(op, st, BOOST_PP_SEQ_REVERSE_S(245, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_245(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_245(op, st, BOOST_PP_SEQ_REVERSE_S(246, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_246(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_246(op, st, BOOST_PP_SEQ_REVERSE_S(247, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_247(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_247(op, st, BOOST_PP_SEQ_REVERSE_S(248, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_248(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_248(op, st, BOOST_PP_SEQ_REVERSE_S(249, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_249(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_249(op, st, BOOST_PP_SEQ_REVERSE_S(250, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_250(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_250(op, st, BOOST_PP_SEQ_REVERSE_S(251, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_251(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_251(op, st, BOOST_PP_SEQ_REVERSE_S(252, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_252(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_252(op, st, BOOST_PP_SEQ_REVERSE_S(253, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_253(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_253(op, st, BOOST_PP_SEQ_REVERSE_S(254, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_254(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_254(op, st, BOOST_PP_SEQ_REVERSE_S(255, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_255(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_255(op, st, BOOST_PP_SEQ_REVERSE_S(256, ss), BOOST_PP_SEQ_SIZE(ss))
#define BOOST_PP_SEQ_FOLD_RIGHT_256(op, st, ss) BOOST_PP_SEQ_FOLD_LEFT_I_256(op, st, BOOST_PP_SEQ_REVERSE_S(257, ss), BOOST_PP_SEQ_SIZE(ss))

#define BOOST_PP_SEQ_FOR_EACH(macro, data, seq) BOOST_PP_FOR((macro, data, seq (nil)), BOOST_PP_SEQ_FOR_EACH_P, BOOST_PP_SEQ_FOR_EACH_O, BOOST_PP_SEQ_FOR_EACH_M)
#define BOOST_PP_SEQ_FOR_EACH_P(r, x) BOOST_PP_DEC(BOOST_PP_SEQ_SIZE(BOOST_PP_TUPLE_ELEM(3, 2, x)))
#define BOOST_PP_SEQ_FOR_EACH_O(r, x) BOOST_PP_SEQ_FOR_EACH_O_I x
#define BOOST_PP_SEQ_FOR_EACH_O_I(macro, data, seq) (macro, data, BOOST_PP_SEQ_TAIL(seq))
#define BOOST_PP_SEQ_FOR_EACH_M(r, x) BOOST_PP_SEQ_FOR_EACH_M_IM(r, BOOST_PP_TUPLE_REM_3 x)
#define BOOST_PP_SEQ_FOR_EACH_M_IM(r, im) BOOST_PP_SEQ_FOR_EACH_M_I(r, im)
#define BOOST_PP_SEQ_FOR_EACH_M_I(r, macro, data, seq) macro(r, data, BOOST_PP_SEQ_HEAD(seq))
#define BOOST_PP_SEQ_FOR_EACH_R(r, macro, data, seq) BOOST_PP_FOR_ ## r((macro, data, seq (nil)), BOOST_PP_SEQ_FOR_EACH_P, BOOST_PP_SEQ_FOR_EACH_O, BOOST_PP_SEQ_FOR_EACH_M)

#define BOOST_PP_SEQ_FOR_EACH_PRODUCT(macro, sets) BOOST_PP_SEQ_FOR_EACH_PRODUCT_E(BOOST_PP_FOR, macro, sets)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_R(r, macro, sets) BOOST_PP_SEQ_FOR_EACH_PRODUCT_E(BOOST_PP_FOR_ ## r, macro, sets)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_E(impl, macro, sets) BOOST_PP_SEQ_FOR_EACH_PRODUCT_E_I(impl, macro, sets)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_E_I(impl, macro, sets) impl((BOOST_PP_SEQ_HEAD(sets)(nil), BOOST_PP_SEQ_TAIL(sets)(nil), (nil), macro), BOOST_PP_SEQ_FOR_EACH_PRODUCT_P, BOOST_PP_SEQ_FOR_EACH_PRODUCT_O, BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_0)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_P(r, data) BOOST_PP_SEQ_FOR_EACH_PRODUCT_P_I data
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_P_I(cset, rset, res, macro) BOOST_PP_DEC(BOOST_PP_SEQ_SIZE(cset))
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_O(r, data) BOOST_PP_SEQ_FOR_EACH_PRODUCT_O_I data
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_O_I(cset, rset, res, macro) (BOOST_PP_SEQ_TAIL(cset), rset, res, macro)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_C(data, i) BOOST_PP_IF(BOOST_PP_DEC(BOOST_PP_SEQ_SIZE(BOOST_PP_TUPLE_ELEM(4, 1, data))), BOOST_PP_SEQ_FOR_EACH_PRODUCT_N_ ## i, BOOST_PP_SEQ_FOR_EACH_PRODUCT_I)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_I(r, data) BOOST_PP_SEQ_FOR_EACH_PRODUCT_I_I(r, BOOST_PP_TUPLE_ELEM(4, 0, data), BOOST_PP_TUPLE_ELEM(4, 1, data), BOOST_PP_TUPLE_ELEM(4, 2, data), BOOST_PP_TUPLE_ELEM(4, 3, data))
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_I_I(r, cset, rset, res, macro) macro(r, BOOST_PP_SEQ_TAIL(res (BOOST_PP_SEQ_HEAD(cset))))
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_H(data) BOOST_PP_SEQ_FOR_EACH_PRODUCT_H_I data
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_H_I(cset, rset, res, macro) (BOOST_PP_SEQ_HEAD(rset)(nil), BOOST_PP_SEQ_TAIL(rset), res (BOOST_PP_SEQ_HEAD(cset)), macro)

#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_0(r, data) BOOST_PP_SEQ_FOR_EACH_PRODUCT_C(data, 0)(r, data)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_1(r, data) BOOST_PP_SEQ_FOR_EACH_PRODUCT_C(data, 1)(r, data)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_2(r, data) BOOST_PP_SEQ_FOR_EACH_PRODUCT_C(data, 2)(r, data)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_3(r, data) BOOST_PP_SEQ_FOR_EACH_PRODUCT_C(data, 3)(r, data)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_4(r, data) BOOST_PP_SEQ_FOR_EACH_PRODUCT_C(data, 4)(r, data)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_5(r, data) BOOST_PP_SEQ_FOR_EACH_PRODUCT_C(data, 5)(r, data)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_6(r, data) BOOST_PP_SEQ_FOR_EACH_PRODUCT_C(data, 6)(r, data)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_7(r, data) BOOST_PP_SEQ_FOR_EACH_PRODUCT_C(data, 7)(r, data)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_8(r, data) BOOST_PP_SEQ_FOR_EACH_PRODUCT_C(data, 8)(r, data)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_9(r, data) BOOST_PP_SEQ_FOR_EACH_PRODUCT_C(data, 9)(r, data)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_10(r, data) BOOST_PP_SEQ_FOR_EACH_PRODUCT_C(data, 10)(r, data)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_11(r, data) BOOST_PP_SEQ_FOR_EACH_PRODUCT_C(data, 11)(r, data)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_12(r, data) BOOST_PP_SEQ_FOR_EACH_PRODUCT_C(data, 12)(r, data)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_13(r, data) BOOST_PP_SEQ_FOR_EACH_PRODUCT_C(data, 13)(r, data)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_14(r, data) BOOST_PP_SEQ_FOR_EACH_PRODUCT_C(data, 14)(r, data)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_15(r, data) BOOST_PP_SEQ_FOR_EACH_PRODUCT_C(data, 15)(r, data)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_16(r, data) BOOST_PP_SEQ_FOR_EACH_PRODUCT_C(data, 16)(r, data)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_17(r, data) BOOST_PP_SEQ_FOR_EACH_PRODUCT_C(data, 17)(r, data)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_18(r, data) BOOST_PP_SEQ_FOR_EACH_PRODUCT_C(data, 18)(r, data)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_19(r, data) BOOST_PP_SEQ_FOR_EACH_PRODUCT_C(data, 19)(r, data)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_20(r, data) BOOST_PP_SEQ_FOR_EACH_PRODUCT_C(data, 20)(r, data)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_21(r, data) BOOST_PP_SEQ_FOR_EACH_PRODUCT_C(data, 21)(r, data)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_22(r, data) BOOST_PP_SEQ_FOR_EACH_PRODUCT_C(data, 22)(r, data)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_23(r, data) BOOST_PP_SEQ_FOR_EACH_PRODUCT_C(data, 23)(r, data)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_24(r, data) BOOST_PP_SEQ_FOR_EACH_PRODUCT_C(data, 24)(r, data)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_25(r, data) BOOST_PP_SEQ_FOR_EACH_PRODUCT_C(data, 25)(r, data)

#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_N_0(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_SEQ_FOR_EACH_PRODUCT_H(data), BOOST_PP_SEQ_FOR_EACH_PRODUCT_P, BOOST_PP_SEQ_FOR_EACH_PRODUCT_O, BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_1)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_N_1(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_SEQ_FOR_EACH_PRODUCT_H(data), BOOST_PP_SEQ_FOR_EACH_PRODUCT_P, BOOST_PP_SEQ_FOR_EACH_PRODUCT_O, BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_2)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_N_2(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_SEQ_FOR_EACH_PRODUCT_H(data), BOOST_PP_SEQ_FOR_EACH_PRODUCT_P, BOOST_PP_SEQ_FOR_EACH_PRODUCT_O, BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_3)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_N_3(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_SEQ_FOR_EACH_PRODUCT_H(data), BOOST_PP_SEQ_FOR_EACH_PRODUCT_P, BOOST_PP_SEQ_FOR_EACH_PRODUCT_O, BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_4)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_N_4(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_SEQ_FOR_EACH_PRODUCT_H(data), BOOST_PP_SEQ_FOR_EACH_PRODUCT_P, BOOST_PP_SEQ_FOR_EACH_PRODUCT_O, BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_5)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_N_5(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_SEQ_FOR_EACH_PRODUCT_H(data), BOOST_PP_SEQ_FOR_EACH_PRODUCT_P, BOOST_PP_SEQ_FOR_EACH_PRODUCT_O, BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_6)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_N_6(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_SEQ_FOR_EACH_PRODUCT_H(data), BOOST_PP_SEQ_FOR_EACH_PRODUCT_P, BOOST_PP_SEQ_FOR_EACH_PRODUCT_O, BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_7)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_N_7(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_SEQ_FOR_EACH_PRODUCT_H(data), BOOST_PP_SEQ_FOR_EACH_PRODUCT_P, BOOST_PP_SEQ_FOR_EACH_PRODUCT_O, BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_8)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_N_8(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_SEQ_FOR_EACH_PRODUCT_H(data), BOOST_PP_SEQ_FOR_EACH_PRODUCT_P, BOOST_PP_SEQ_FOR_EACH_PRODUCT_O, BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_9)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_N_9(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_SEQ_FOR_EACH_PRODUCT_H(data), BOOST_PP_SEQ_FOR_EACH_PRODUCT_P, BOOST_PP_SEQ_FOR_EACH_PRODUCT_O, BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_10)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_N_10(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_SEQ_FOR_EACH_PRODUCT_H(data), BOOST_PP_SEQ_FOR_EACH_PRODUCT_P, BOOST_PP_SEQ_FOR_EACH_PRODUCT_O, BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_11)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_N_11(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_SEQ_FOR_EACH_PRODUCT_H(data), BOOST_PP_SEQ_FOR_EACH_PRODUCT_P, BOOST_PP_SEQ_FOR_EACH_PRODUCT_O, BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_12)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_N_12(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_SEQ_FOR_EACH_PRODUCT_H(data), BOOST_PP_SEQ_FOR_EACH_PRODUCT_P, BOOST_PP_SEQ_FOR_EACH_PRODUCT_O, BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_13)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_N_13(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_SEQ_FOR_EACH_PRODUCT_H(data), BOOST_PP_SEQ_FOR_EACH_PRODUCT_P, BOOST_PP_SEQ_FOR_EACH_PRODUCT_O, BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_14)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_N_14(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_SEQ_FOR_EACH_PRODUCT_H(data), BOOST_PP_SEQ_FOR_EACH_PRODUCT_P, BOOST_PP_SEQ_FOR_EACH_PRODUCT_O, BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_15)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_N_15(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_SEQ_FOR_EACH_PRODUCT_H(data), BOOST_PP_SEQ_FOR_EACH_PRODUCT_P, BOOST_PP_SEQ_FOR_EACH_PRODUCT_O, BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_16)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_N_16(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_SEQ_FOR_EACH_PRODUCT_H(data), BOOST_PP_SEQ_FOR_EACH_PRODUCT_P, BOOST_PP_SEQ_FOR_EACH_PRODUCT_O, BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_17)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_N_17(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_SEQ_FOR_EACH_PRODUCT_H(data), BOOST_PP_SEQ_FOR_EACH_PRODUCT_P, BOOST_PP_SEQ_FOR_EACH_PRODUCT_O, BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_18)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_N_18(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_SEQ_FOR_EACH_PRODUCT_H(data), BOOST_PP_SEQ_FOR_EACH_PRODUCT_P, BOOST_PP_SEQ_FOR_EACH_PRODUCT_O, BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_19)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_N_19(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_SEQ_FOR_EACH_PRODUCT_H(data), BOOST_PP_SEQ_FOR_EACH_PRODUCT_P, BOOST_PP_SEQ_FOR_EACH_PRODUCT_O, BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_20)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_N_20(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_SEQ_FOR_EACH_PRODUCT_H(data), BOOST_PP_SEQ_FOR_EACH_PRODUCT_P, BOOST_PP_SEQ_FOR_EACH_PRODUCT_O, BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_21)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_N_21(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_SEQ_FOR_EACH_PRODUCT_H(data), BOOST_PP_SEQ_FOR_EACH_PRODUCT_P, BOOST_PP_SEQ_FOR_EACH_PRODUCT_O, BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_22)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_N_22(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_SEQ_FOR_EACH_PRODUCT_H(data), BOOST_PP_SEQ_FOR_EACH_PRODUCT_P, BOOST_PP_SEQ_FOR_EACH_PRODUCT_O, BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_23)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_N_23(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_SEQ_FOR_EACH_PRODUCT_H(data), BOOST_PP_SEQ_FOR_EACH_PRODUCT_P, BOOST_PP_SEQ_FOR_EACH_PRODUCT_O, BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_24)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_N_24(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_SEQ_FOR_EACH_PRODUCT_H(data), BOOST_PP_SEQ_FOR_EACH_PRODUCT_P, BOOST_PP_SEQ_FOR_EACH_PRODUCT_O, BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_25)
#define BOOST_PP_SEQ_FOR_EACH_PRODUCT_N_25(r, data) BOOST_PP_FOR_ ## r(BOOST_PP_SEQ_FOR_EACH_PRODUCT_H(data), BOOST_PP_SEQ_FOR_EACH_PRODUCT_P, BOOST_PP_SEQ_FOR_EACH_PRODUCT_O, BOOST_PP_SEQ_FOR_EACH_PRODUCT_M_26)

#define BOOST_PP_SEQ_HEAD(seq) BOOST_PP_SEQ_ELEM(0,seq)

#define BOOST_PP_SEQ_INSERT(seq, i, elem) BOOST_PP_SEQ_FIRST_N(i, seq) (elem) BOOST_PP_SEQ_REST_N(i, seq)

#define BOOST_PP_SEQ_NIL(x) (x)

#define BOOST_PP_SEQ_POP_BACK(seq) BOOST_PP_SEQ_FIRST_N(BOOST_PP_DEC(BOOST_PP_SEQ_SIZE(seq)), seq)
#define BOOST_PP_SEQ_POP_FRONT(seq) BOOST_PP_SEQ_TAIL(seq)
#define BOOST_PP_SEQ_PUSH_BACK(seq, elem) seq(elem)
#define BOOST_PP_SEQ_PUSH_FRONT(seq, elem) (elem) seq

#define BOOST_PP_SEQ_REMOVE(seq, i) BOOST_PP_SEQ_FIRST_N(i, seq) BOOST_PP_SEQ_REST_N(BOOST_PP_INC(i), seq)

#define BOOST_PP_SEQ_REPLACE(seq, i, elem) BOOST_PP_SEQ_FIRST_N(i, seq) (elem) BOOST_PP_SEQ_REST_N(BOOST_PP_INC(i), seq)

#define BOOST_PP_SEQ_REST_N(n, seq) BOOST_PP_TUPLE_ELEM(2, 1, BOOST_PP_SEQ_SPLIT(BOOST_PP_INC(n), (nil) seq BOOST_PP_EMPTY))()

#define BOOST_PP_SEQ_REVERSE(seq) BOOST_PP_SEQ_FOLD_LEFT(BOOST_PP_SEQ_REVERSE_O, BOOST_PP_EMPTY, seq)()
#define BOOST_PP_SEQ_REVERSE_O(s, state, elem) (elem) state
#define BOOST_PP_SEQ_REVERSE_S(s, seq) BOOST_PP_SEQ_FOLD_LEFT_ ## s(BOOST_PP_SEQ_REVERSE_O, BOOST_PP_EMPTY, seq)()

#define BOOST_PP_SEQ_SIZE(seq) BOOST_PP_CAT(BOOST_PP_SEQ_SIZE_, BOOST_PP_SEQ_SIZE_0 seq)
#define BOOST_PP_SEQ_SIZE_0(_) BOOST_PP_SEQ_SIZE_1
#define BOOST_PP_SEQ_SIZE_1(_) BOOST_PP_SEQ_SIZE_2
#define BOOST_PP_SEQ_SIZE_2(_) BOOST_PP_SEQ_SIZE_3
#define BOOST_PP_SEQ_SIZE_3(_) BOOST_PP_SEQ_SIZE_4
#define BOOST_PP_SEQ_SIZE_4(_) BOOST_PP_SEQ_SIZE_5
#define BOOST_PP_SEQ_SIZE_5(_) BOOST_PP_SEQ_SIZE_6
#define BOOST_PP_SEQ_SIZE_6(_) BOOST_PP_SEQ_SIZE_7
#define BOOST_PP_SEQ_SIZE_7(_) BOOST_PP_SEQ_SIZE_8
#define BOOST_PP_SEQ_SIZE_8(_) BOOST_PP_SEQ_SIZE_9
#define BOOST_PP_SEQ_SIZE_9(_) BOOST_PP_SEQ_SIZE_10
#define BOOST_PP_SEQ_SIZE_10(_) BOOST_PP_SEQ_SIZE_11
#define BOOST_PP_SEQ_SIZE_11(_) BOOST_PP_SEQ_SIZE_12
#define BOOST_PP_SEQ_SIZE_12(_) BOOST_PP_SEQ_SIZE_13
#define BOOST_PP_SEQ_SIZE_13(_) BOOST_PP_SEQ_SIZE_14
#define BOOST_PP_SEQ_SIZE_14(_) BOOST_PP_SEQ_SIZE_15
#define BOOST_PP_SEQ_SIZE_15(_) BOOST_PP_SEQ_SIZE_16
#define BOOST_PP_SEQ_SIZE_16(_) BOOST_PP_SEQ_SIZE_17
#define BOOST_PP_SEQ_SIZE_17(_) BOOST_PP_SEQ_SIZE_18
#define BOOST_PP_SEQ_SIZE_18(_) BOOST_PP_SEQ_SIZE_19
#define BOOST_PP_SEQ_SIZE_19(_) BOOST_PP_SEQ_SIZE_20
#define BOOST_PP_SEQ_SIZE_20(_) BOOST_PP_SEQ_SIZE_21
#define BOOST_PP_SEQ_SIZE_21(_) BOOST_PP_SEQ_SIZE_22
#define BOOST_PP_SEQ_SIZE_22(_) BOOST_PP_SEQ_SIZE_23
#define BOOST_PP_SEQ_SIZE_23(_) BOOST_PP_SEQ_SIZE_24
#define BOOST_PP_SEQ_SIZE_24(_) BOOST_PP_SEQ_SIZE_25
#define BOOST_PP_SEQ_SIZE_25(_) BOOST_PP_SEQ_SIZE_26
#define BOOST_PP_SEQ_SIZE_26(_) BOOST_PP_SEQ_SIZE_27
#define BOOST_PP_SEQ_SIZE_27(_) BOOST_PP_SEQ_SIZE_28
#define BOOST_PP_SEQ_SIZE_28(_) BOOST_PP_SEQ_SIZE_29
#define BOOST_PP_SEQ_SIZE_29(_) BOOST_PP_SEQ_SIZE_30
#define BOOST_PP_SEQ_SIZE_30(_) BOOST_PP_SEQ_SIZE_31
#define BOOST_PP_SEQ_SIZE_31(_) BOOST_PP_SEQ_SIZE_32
#define BOOST_PP_SEQ_SIZE_32(_) BOOST_PP_SEQ_SIZE_33
#define BOOST_PP_SEQ_SIZE_33(_) BOOST_PP_SEQ_SIZE_34
#define BOOST_PP_SEQ_SIZE_34(_) BOOST_PP_SEQ_SIZE_35
#define BOOST_PP_SEQ_SIZE_35(_) BOOST_PP_SEQ_SIZE_36
#define BOOST_PP_SEQ_SIZE_36(_) BOOST_PP_SEQ_SIZE_37
#define BOOST_PP_SEQ_SIZE_37(_) BOOST_PP_SEQ_SIZE_38
#define BOOST_PP_SEQ_SIZE_38(_) BOOST_PP_SEQ_SIZE_39
#define BOOST_PP_SEQ_SIZE_39(_) BOOST_PP_SEQ_SIZE_40
#define BOOST_PP_SEQ_SIZE_40(_) BOOST_PP_SEQ_SIZE_41
#define BOOST_PP_SEQ_SIZE_41(_) BOOST_PP_SEQ_SIZE_42
#define BOOST_PP_SEQ_SIZE_42(_) BOOST_PP_SEQ_SIZE_43
#define BOOST_PP_SEQ_SIZE_43(_) BOOST_PP_SEQ_SIZE_44
#define BOOST_PP_SEQ_SIZE_44(_) BOOST_PP_SEQ_SIZE_45
#define BOOST_PP_SEQ_SIZE_45(_) BOOST_PP_SEQ_SIZE_46
#define BOOST_PP_SEQ_SIZE_46(_) BOOST_PP_SEQ_SIZE_47
#define BOOST_PP_SEQ_SIZE_47(_) BOOST_PP_SEQ_SIZE_48
#define BOOST_PP_SEQ_SIZE_48(_) BOOST_PP_SEQ_SIZE_49
#define BOOST_PP_SEQ_SIZE_49(_) BOOST_PP_SEQ_SIZE_50
#define BOOST_PP_SEQ_SIZE_50(_) BOOST_PP_SEQ_SIZE_51
#define BOOST_PP_SEQ_SIZE_51(_) BOOST_PP_SEQ_SIZE_52
#define BOOST_PP_SEQ_SIZE_52(_) BOOST_PP_SEQ_SIZE_53
#define BOOST_PP_SEQ_SIZE_53(_) BOOST_PP_SEQ_SIZE_54
#define BOOST_PP_SEQ_SIZE_54(_) BOOST_PP_SEQ_SIZE_55
#define BOOST_PP_SEQ_SIZE_55(_) BOOST_PP_SEQ_SIZE_56
#define BOOST_PP_SEQ_SIZE_56(_) BOOST_PP_SEQ_SIZE_57
#define BOOST_PP_SEQ_SIZE_57(_) BOOST_PP_SEQ_SIZE_58
#define BOOST_PP_SEQ_SIZE_58(_) BOOST_PP_SEQ_SIZE_59
#define BOOST_PP_SEQ_SIZE_59(_) BOOST_PP_SEQ_SIZE_60
#define BOOST_PP_SEQ_SIZE_60(_) BOOST_PP_SEQ_SIZE_61
#define BOOST_PP_SEQ_SIZE_61(_) BOOST_PP_SEQ_SIZE_62
#define BOOST_PP_SEQ_SIZE_62(_) BOOST_PP_SEQ_SIZE_63
#define BOOST_PP_SEQ_SIZE_63(_) BOOST_PP_SEQ_SIZE_64
#define BOOST_PP_SEQ_SIZE_64(_) BOOST_PP_SEQ_SIZE_65
#define BOOST_PP_SEQ_SIZE_65(_) BOOST_PP_SEQ_SIZE_66
#define BOOST_PP_SEQ_SIZE_66(_) BOOST_PP_SEQ_SIZE_67
#define BOOST_PP_SEQ_SIZE_67(_) BOOST_PP_SEQ_SIZE_68
#define BOOST_PP_SEQ_SIZE_68(_) BOOST_PP_SEQ_SIZE_69
#define BOOST_PP_SEQ_SIZE_69(_) BOOST_PP_SEQ_SIZE_70
#define BOOST_PP_SEQ_SIZE_70(_) BOOST_PP_SEQ_SIZE_71
#define BOOST_PP_SEQ_SIZE_71(_) BOOST_PP_SEQ_SIZE_72
#define BOOST_PP_SEQ_SIZE_72(_) BOOST_PP_SEQ_SIZE_73
#define BOOST_PP_SEQ_SIZE_73(_) BOOST_PP_SEQ_SIZE_74
#define BOOST_PP_SEQ_SIZE_74(_) BOOST_PP_SEQ_SIZE_75
#define BOOST_PP_SEQ_SIZE_75(_) BOOST_PP_SEQ_SIZE_76
#define BOOST_PP_SEQ_SIZE_76(_) BOOST_PP_SEQ_SIZE_77
#define BOOST_PP_SEQ_SIZE_77(_) BOOST_PP_SEQ_SIZE_78
#define BOOST_PP_SEQ_SIZE_78(_) BOOST_PP_SEQ_SIZE_79
#define BOOST_PP_SEQ_SIZE_79(_) BOOST_PP_SEQ_SIZE_80
#define BOOST_PP_SEQ_SIZE_80(_) BOOST_PP_SEQ_SIZE_81
#define BOOST_PP_SEQ_SIZE_81(_) BOOST_PP_SEQ_SIZE_82
#define BOOST_PP_SEQ_SIZE_82(_) BOOST_PP_SEQ_SIZE_83
#define BOOST_PP_SEQ_SIZE_83(_) BOOST_PP_SEQ_SIZE_84
#define BOOST_PP_SEQ_SIZE_84(_) BOOST_PP_SEQ_SIZE_85
#define BOOST_PP_SEQ_SIZE_85(_) BOOST_PP_SEQ_SIZE_86
#define BOOST_PP_SEQ_SIZE_86(_) BOOST_PP_SEQ_SIZE_87
#define BOOST_PP_SEQ_SIZE_87(_) BOOST_PP_SEQ_SIZE_88
#define BOOST_PP_SEQ_SIZE_88(_) BOOST_PP_SEQ_SIZE_89
#define BOOST_PP_SEQ_SIZE_89(_) BOOST_PP_SEQ_SIZE_90
#define BOOST_PP_SEQ_SIZE_90(_) BOOST_PP_SEQ_SIZE_91
#define BOOST_PP_SEQ_SIZE_91(_) BOOST_PP_SEQ_SIZE_92
#define BOOST_PP_SEQ_SIZE_92(_) BOOST_PP_SEQ_SIZE_93
#define BOOST_PP_SEQ_SIZE_93(_) BOOST_PP_SEQ_SIZE_94
#define BOOST_PP_SEQ_SIZE_94(_) BOOST_PP_SEQ_SIZE_95
#define BOOST_PP_SEQ_SIZE_95(_) BOOST_PP_SEQ_SIZE_96
#define BOOST_PP_SEQ_SIZE_96(_) BOOST_PP_SEQ_SIZE_97
#define BOOST_PP_SEQ_SIZE_97(_) BOOST_PP_SEQ_SIZE_98
#define BOOST_PP_SEQ_SIZE_98(_) BOOST_PP_SEQ_SIZE_99
#define BOOST_PP_SEQ_SIZE_99(_) BOOST_PP_SEQ_SIZE_100
#define BOOST_PP_SEQ_SIZE_100(_) BOOST_PP_SEQ_SIZE_101
#define BOOST_PP_SEQ_SIZE_101(_) BOOST_PP_SEQ_SIZE_102
#define BOOST_PP_SEQ_SIZE_102(_) BOOST_PP_SEQ_SIZE_103
#define BOOST_PP_SEQ_SIZE_103(_) BOOST_PP_SEQ_SIZE_104
#define BOOST_PP_SEQ_SIZE_104(_) BOOST_PP_SEQ_SIZE_105
#define BOOST_PP_SEQ_SIZE_105(_) BOOST_PP_SEQ_SIZE_106
#define BOOST_PP_SEQ_SIZE_106(_) BOOST_PP_SEQ_SIZE_107
#define BOOST_PP_SEQ_SIZE_107(_) BOOST_PP_SEQ_SIZE_108
#define BOOST_PP_SEQ_SIZE_108(_) BOOST_PP_SEQ_SIZE_109
#define BOOST_PP_SEQ_SIZE_109(_) BOOST_PP_SEQ_SIZE_110
#define BOOST_PP_SEQ_SIZE_110(_) BOOST_PP_SEQ_SIZE_111
#define BOOST_PP_SEQ_SIZE_111(_) BOOST_PP_SEQ_SIZE_112
#define BOOST_PP_SEQ_SIZE_112(_) BOOST_PP_SEQ_SIZE_113
#define BOOST_PP_SEQ_SIZE_113(_) BOOST_PP_SEQ_SIZE_114
#define BOOST_PP_SEQ_SIZE_114(_) BOOST_PP_SEQ_SIZE_115
#define BOOST_PP_SEQ_SIZE_115(_) BOOST_PP_SEQ_SIZE_116
#define BOOST_PP_SEQ_SIZE_116(_) BOOST_PP_SEQ_SIZE_117
#define BOOST_PP_SEQ_SIZE_117(_) BOOST_PP_SEQ_SIZE_118
#define BOOST_PP_SEQ_SIZE_118(_) BOOST_PP_SEQ_SIZE_119
#define BOOST_PP_SEQ_SIZE_119(_) BOOST_PP_SEQ_SIZE_120
#define BOOST_PP_SEQ_SIZE_120(_) BOOST_PP_SEQ_SIZE_121
#define BOOST_PP_SEQ_SIZE_121(_) BOOST_PP_SEQ_SIZE_122
#define BOOST_PP_SEQ_SIZE_122(_) BOOST_PP_SEQ_SIZE_123
#define BOOST_PP_SEQ_SIZE_123(_) BOOST_PP_SEQ_SIZE_124
#define BOOST_PP_SEQ_SIZE_124(_) BOOST_PP_SEQ_SIZE_125
#define BOOST_PP_SEQ_SIZE_125(_) BOOST_PP_SEQ_SIZE_126
#define BOOST_PP_SEQ_SIZE_126(_) BOOST_PP_SEQ_SIZE_127
#define BOOST_PP_SEQ_SIZE_127(_) BOOST_PP_SEQ_SIZE_128
#define BOOST_PP_SEQ_SIZE_128(_) BOOST_PP_SEQ_SIZE_129
#define BOOST_PP_SEQ_SIZE_129(_) BOOST_PP_SEQ_SIZE_130
#define BOOST_PP_SEQ_SIZE_130(_) BOOST_PP_SEQ_SIZE_131
#define BOOST_PP_SEQ_SIZE_131(_) BOOST_PP_SEQ_SIZE_132
#define BOOST_PP_SEQ_SIZE_132(_) BOOST_PP_SEQ_SIZE_133
#define BOOST_PP_SEQ_SIZE_133(_) BOOST_PP_SEQ_SIZE_134
#define BOOST_PP_SEQ_SIZE_134(_) BOOST_PP_SEQ_SIZE_135
#define BOOST_PP_SEQ_SIZE_135(_) BOOST_PP_SEQ_SIZE_136
#define BOOST_PP_SEQ_SIZE_136(_) BOOST_PP_SEQ_SIZE_137
#define BOOST_PP_SEQ_SIZE_137(_) BOOST_PP_SEQ_SIZE_138
#define BOOST_PP_SEQ_SIZE_138(_) BOOST_PP_SEQ_SIZE_139
#define BOOST_PP_SEQ_SIZE_139(_) BOOST_PP_SEQ_SIZE_140
#define BOOST_PP_SEQ_SIZE_140(_) BOOST_PP_SEQ_SIZE_141
#define BOOST_PP_SEQ_SIZE_141(_) BOOST_PP_SEQ_SIZE_142
#define BOOST_PP_SEQ_SIZE_142(_) BOOST_PP_SEQ_SIZE_143
#define BOOST_PP_SEQ_SIZE_143(_) BOOST_PP_SEQ_SIZE_144
#define BOOST_PP_SEQ_SIZE_144(_) BOOST_PP_SEQ_SIZE_145
#define BOOST_PP_SEQ_SIZE_145(_) BOOST_PP_SEQ_SIZE_146
#define BOOST_PP_SEQ_SIZE_146(_) BOOST_PP_SEQ_SIZE_147
#define BOOST_PP_SEQ_SIZE_147(_) BOOST_PP_SEQ_SIZE_148
#define BOOST_PP_SEQ_SIZE_148(_) BOOST_PP_SEQ_SIZE_149
#define BOOST_PP_SEQ_SIZE_149(_) BOOST_PP_SEQ_SIZE_150
#define BOOST_PP_SEQ_SIZE_150(_) BOOST_PP_SEQ_SIZE_151
#define BOOST_PP_SEQ_SIZE_151(_) BOOST_PP_SEQ_SIZE_152
#define BOOST_PP_SEQ_SIZE_152(_) BOOST_PP_SEQ_SIZE_153
#define BOOST_PP_SEQ_SIZE_153(_) BOOST_PP_SEQ_SIZE_154
#define BOOST_PP_SEQ_SIZE_154(_) BOOST_PP_SEQ_SIZE_155
#define BOOST_PP_SEQ_SIZE_155(_) BOOST_PP_SEQ_SIZE_156
#define BOOST_PP_SEQ_SIZE_156(_) BOOST_PP_SEQ_SIZE_157
#define BOOST_PP_SEQ_SIZE_157(_) BOOST_PP_SEQ_SIZE_158
#define BOOST_PP_SEQ_SIZE_158(_) BOOST_PP_SEQ_SIZE_159
#define BOOST_PP_SEQ_SIZE_159(_) BOOST_PP_SEQ_SIZE_160
#define BOOST_PP_SEQ_SIZE_160(_) BOOST_PP_SEQ_SIZE_161
#define BOOST_PP_SEQ_SIZE_161(_) BOOST_PP_SEQ_SIZE_162
#define BOOST_PP_SEQ_SIZE_162(_) BOOST_PP_SEQ_SIZE_163
#define BOOST_PP_SEQ_SIZE_163(_) BOOST_PP_SEQ_SIZE_164
#define BOOST_PP_SEQ_SIZE_164(_) BOOST_PP_SEQ_SIZE_165
#define BOOST_PP_SEQ_SIZE_165(_) BOOST_PP_SEQ_SIZE_166
#define BOOST_PP_SEQ_SIZE_166(_) BOOST_PP_SEQ_SIZE_167
#define BOOST_PP_SEQ_SIZE_167(_) BOOST_PP_SEQ_SIZE_168
#define BOOST_PP_SEQ_SIZE_168(_) BOOST_PP_SEQ_SIZE_169
#define BOOST_PP_SEQ_SIZE_169(_) BOOST_PP_SEQ_SIZE_170
#define BOOST_PP_SEQ_SIZE_170(_) BOOST_PP_SEQ_SIZE_171
#define BOOST_PP_SEQ_SIZE_171(_) BOOST_PP_SEQ_SIZE_172
#define BOOST_PP_SEQ_SIZE_172(_) BOOST_PP_SEQ_SIZE_173
#define BOOST_PP_SEQ_SIZE_173(_) BOOST_PP_SEQ_SIZE_174
#define BOOST_PP_SEQ_SIZE_174(_) BOOST_PP_SEQ_SIZE_175
#define BOOST_PP_SEQ_SIZE_175(_) BOOST_PP_SEQ_SIZE_176
#define BOOST_PP_SEQ_SIZE_176(_) BOOST_PP_SEQ_SIZE_177
#define BOOST_PP_SEQ_SIZE_177(_) BOOST_PP_SEQ_SIZE_178
#define BOOST_PP_SEQ_SIZE_178(_) BOOST_PP_SEQ_SIZE_179
#define BOOST_PP_SEQ_SIZE_179(_) BOOST_PP_SEQ_SIZE_180
#define BOOST_PP_SEQ_SIZE_180(_) BOOST_PP_SEQ_SIZE_181
#define BOOST_PP_SEQ_SIZE_181(_) BOOST_PP_SEQ_SIZE_182
#define BOOST_PP_SEQ_SIZE_182(_) BOOST_PP_SEQ_SIZE_183
#define BOOST_PP_SEQ_SIZE_183(_) BOOST_PP_SEQ_SIZE_184
#define BOOST_PP_SEQ_SIZE_184(_) BOOST_PP_SEQ_SIZE_185
#define BOOST_PP_SEQ_SIZE_185(_) BOOST_PP_SEQ_SIZE_186
#define BOOST_PP_SEQ_SIZE_186(_) BOOST_PP_SEQ_SIZE_187
#define BOOST_PP_SEQ_SIZE_187(_) BOOST_PP_SEQ_SIZE_188
#define BOOST_PP_SEQ_SIZE_188(_) BOOST_PP_SEQ_SIZE_189
#define BOOST_PP_SEQ_SIZE_189(_) BOOST_PP_SEQ_SIZE_190
#define BOOST_PP_SEQ_SIZE_190(_) BOOST_PP_SEQ_SIZE_191
#define BOOST_PP_SEQ_SIZE_191(_) BOOST_PP_SEQ_SIZE_192
#define BOOST_PP_SEQ_SIZE_192(_) BOOST_PP_SEQ_SIZE_193
#define BOOST_PP_SEQ_SIZE_193(_) BOOST_PP_SEQ_SIZE_194
#define BOOST_PP_SEQ_SIZE_194(_) BOOST_PP_SEQ_SIZE_195
#define BOOST_PP_SEQ_SIZE_195(_) BOOST_PP_SEQ_SIZE_196
#define BOOST_PP_SEQ_SIZE_196(_) BOOST_PP_SEQ_SIZE_197
#define BOOST_PP_SEQ_SIZE_197(_) BOOST_PP_SEQ_SIZE_198
#define BOOST_PP_SEQ_SIZE_198(_) BOOST_PP_SEQ_SIZE_199
#define BOOST_PP_SEQ_SIZE_199(_) BOOST_PP_SEQ_SIZE_200
#define BOOST_PP_SEQ_SIZE_200(_) BOOST_PP_SEQ_SIZE_201
#define BOOST_PP_SEQ_SIZE_201(_) BOOST_PP_SEQ_SIZE_202
#define BOOST_PP_SEQ_SIZE_202(_) BOOST_PP_SEQ_SIZE_203
#define BOOST_PP_SEQ_SIZE_203(_) BOOST_PP_SEQ_SIZE_204
#define BOOST_PP_SEQ_SIZE_204(_) BOOST_PP_SEQ_SIZE_205
#define BOOST_PP_SEQ_SIZE_205(_) BOOST_PP_SEQ_SIZE_206
#define BOOST_PP_SEQ_SIZE_206(_) BOOST_PP_SEQ_SIZE_207
#define BOOST_PP_SEQ_SIZE_207(_) BOOST_PP_SEQ_SIZE_208
#define BOOST_PP_SEQ_SIZE_208(_) BOOST_PP_SEQ_SIZE_209
#define BOOST_PP_SEQ_SIZE_209(_) BOOST_PP_SEQ_SIZE_210
#define BOOST_PP_SEQ_SIZE_210(_) BOOST_PP_SEQ_SIZE_211
#define BOOST_PP_SEQ_SIZE_211(_) BOOST_PP_SEQ_SIZE_212
#define BOOST_PP_SEQ_SIZE_212(_) BOOST_PP_SEQ_SIZE_213
#define BOOST_PP_SEQ_SIZE_213(_) BOOST_PP_SEQ_SIZE_214
#define BOOST_PP_SEQ_SIZE_214(_) BOOST_PP_SEQ_SIZE_215
#define BOOST_PP_SEQ_SIZE_215(_) BOOST_PP_SEQ_SIZE_216
#define BOOST_PP_SEQ_SIZE_216(_) BOOST_PP_SEQ_SIZE_217
#define BOOST_PP_SEQ_SIZE_217(_) BOOST_PP_SEQ_SIZE_218
#define BOOST_PP_SEQ_SIZE_218(_) BOOST_PP_SEQ_SIZE_219
#define BOOST_PP_SEQ_SIZE_219(_) BOOST_PP_SEQ_SIZE_220
#define BOOST_PP_SEQ_SIZE_220(_) BOOST_PP_SEQ_SIZE_221
#define BOOST_PP_SEQ_SIZE_221(_) BOOST_PP_SEQ_SIZE_222
#define BOOST_PP_SEQ_SIZE_222(_) BOOST_PP_SEQ_SIZE_223
#define BOOST_PP_SEQ_SIZE_223(_) BOOST_PP_SEQ_SIZE_224
#define BOOST_PP_SEQ_SIZE_224(_) BOOST_PP_SEQ_SIZE_225
#define BOOST_PP_SEQ_SIZE_225(_) BOOST_PP_SEQ_SIZE_226
#define BOOST_PP_SEQ_SIZE_226(_) BOOST_PP_SEQ_SIZE_227
#define BOOST_PP_SEQ_SIZE_227(_) BOOST_PP_SEQ_SIZE_228
#define BOOST_PP_SEQ_SIZE_228(_) BOOST_PP_SEQ_SIZE_229
#define BOOST_PP_SEQ_SIZE_229(_) BOOST_PP_SEQ_SIZE_230
#define BOOST_PP_SEQ_SIZE_230(_) BOOST_PP_SEQ_SIZE_231
#define BOOST_PP_SEQ_SIZE_231(_) BOOST_PP_SEQ_SIZE_232
#define BOOST_PP_SEQ_SIZE_232(_) BOOST_PP_SEQ_SIZE_233
#define BOOST_PP_SEQ_SIZE_233(_) BOOST_PP_SEQ_SIZE_234
#define BOOST_PP_SEQ_SIZE_234(_) BOOST_PP_SEQ_SIZE_235
#define BOOST_PP_SEQ_SIZE_235(_) BOOST_PP_SEQ_SIZE_236
#define BOOST_PP_SEQ_SIZE_236(_) BOOST_PP_SEQ_SIZE_237
#define BOOST_PP_SEQ_SIZE_237(_) BOOST_PP_SEQ_SIZE_238
#define BOOST_PP_SEQ_SIZE_238(_) BOOST_PP_SEQ_SIZE_239
#define BOOST_PP_SEQ_SIZE_239(_) BOOST_PP_SEQ_SIZE_240
#define BOOST_PP_SEQ_SIZE_240(_) BOOST_PP_SEQ_SIZE_241
#define BOOST_PP_SEQ_SIZE_241(_) BOOST_PP_SEQ_SIZE_242
#define BOOST_PP_SEQ_SIZE_242(_) BOOST_PP_SEQ_SIZE_243
#define BOOST_PP_SEQ_SIZE_243(_) BOOST_PP_SEQ_SIZE_244
#define BOOST_PP_SEQ_SIZE_244(_) BOOST_PP_SEQ_SIZE_245
#define BOOST_PP_SEQ_SIZE_245(_) BOOST_PP_SEQ_SIZE_246
#define BOOST_PP_SEQ_SIZE_246(_) BOOST_PP_SEQ_SIZE_247
#define BOOST_PP_SEQ_SIZE_247(_) BOOST_PP_SEQ_SIZE_248
#define BOOST_PP_SEQ_SIZE_248(_) BOOST_PP_SEQ_SIZE_249
#define BOOST_PP_SEQ_SIZE_249(_) BOOST_PP_SEQ_SIZE_250
#define BOOST_PP_SEQ_SIZE_250(_) BOOST_PP_SEQ_SIZE_251
#define BOOST_PP_SEQ_SIZE_251(_) BOOST_PP_SEQ_SIZE_252
#define BOOST_PP_SEQ_SIZE_252(_) BOOST_PP_SEQ_SIZE_253
#define BOOST_PP_SEQ_SIZE_253(_) BOOST_PP_SEQ_SIZE_254
#define BOOST_PP_SEQ_SIZE_254(_) BOOST_PP_SEQ_SIZE_255
#define BOOST_PP_SEQ_SIZE_255(_) BOOST_PP_SEQ_SIZE_256
#define BOOST_PP_SEQ_SIZE_256(_) BOOST_PP_SEQ_SIZE_257

#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_0 0
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_1 1
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_2 2
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_3 3
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_4 4
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_5 5
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_6 6
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_7 7
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_8 8
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_9 9
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_10 10
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_11 11
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_12 12
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_13 13
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_14 14
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_15 15
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_16 16
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_17 17
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_18 18
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_19 19
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_20 20
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_21 21
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_22 22
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_23 23
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_24 24
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_25 25
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_26 26
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_27 27
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_28 28
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_29 29
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_30 30
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_31 31
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_32 32
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_33 33
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_34 34
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_35 35
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_36 36
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_37 37
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_38 38
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_39 39
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_40 40
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_41 41
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_42 42
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_43 43
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_44 44
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_45 45
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_46 46
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_47 47
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_48 48
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_49 49
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_50 50
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_51 51
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_52 52
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_53 53
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_54 54
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_55 55
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_56 56
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_57 57
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_58 58
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_59 59
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_60 60
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_61 61
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_62 62
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_63 63
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_64 64
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_65 65
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_66 66
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_67 67
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_68 68
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_69 69
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_70 70
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_71 71
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_72 72
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_73 73
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_74 74
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_75 75
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_76 76
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_77 77
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_78 78
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_79 79
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_80 80
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_81 81
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_82 82
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_83 83
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_84 84
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_85 85
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_86 86
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_87 87
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_88 88
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_89 89
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_90 90
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_91 91
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_92 92
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_93 93
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_94 94
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_95 95
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_96 96
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_97 97
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_98 98
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_99 99
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_100 100
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_101 101
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_102 102
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_103 103
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_104 104
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_105 105
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_106 106
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_107 107
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_108 108
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_109 109
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_110 110
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_111 111
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_112 112
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_113 113
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_114 114
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_115 115
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_116 116
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_117 117
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_118 118
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_119 119
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_120 120
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_121 121
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_122 122
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_123 123
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_124 124
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_125 125
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_126 126
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_127 127
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_128 128
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_129 129
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_130 130
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_131 131
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_132 132
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_133 133
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_134 134
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_135 135
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_136 136
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_137 137
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_138 138
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_139 139
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_140 140
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_141 141
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_142 142
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_143 143
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_144 144
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_145 145
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_146 146
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_147 147
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_148 148
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_149 149
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_150 150
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_151 151
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_152 152
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_153 153
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_154 154
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_155 155
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_156 156
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_157 157
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_158 158
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_159 159
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_160 160
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_161 161
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_162 162
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_163 163
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_164 164
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_165 165
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_166 166
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_167 167
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_168 168
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_169 169
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_170 170
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_171 171
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_172 172
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_173 173
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_174 174
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_175 175
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_176 176
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_177 177
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_178 178
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_179 179
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_180 180
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_181 181
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_182 182
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_183 183
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_184 184
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_185 185
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_186 186
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_187 187
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_188 188
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_189 189
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_190 190
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_191 191
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_192 192
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_193 193
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_194 194
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_195 195
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_196 196
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_197 197
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_198 198
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_199 199
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_200 200
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_201 201
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_202 202
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_203 203
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_204 204
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_205 205
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_206 206
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_207 207
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_208 208
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_209 209
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_210 210
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_211 211
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_212 212
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_213 213
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_214 214
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_215 215
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_216 216
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_217 217
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_218 218
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_219 219
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_220 220
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_221 221
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_222 222
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_223 223
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_224 224
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_225 225
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_226 226
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_227 227
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_228 228
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_229 229
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_230 230
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_231 231
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_232 232
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_233 233
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_234 234
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_235 235
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_236 236
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_237 237
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_238 238
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_239 239
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_240 240
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_241 241
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_242 242
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_243 243
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_244 244
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_245 245
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_246 246
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_247 247
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_248 248
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_249 249
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_250 250
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_251 251
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_252 252
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_253 253
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_254 254
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_255 255
#define BOOST_PP_SEQ_SIZE_BOOST_PP_SEQ_SIZE_256 256

#define BOOST_PP_SEQ_SPLIT(n, seq) BOOST_PP_SEQ_SPLIT_D(n, seq)
#define BOOST_PP_SEQ_SPLIT_D(n, seq) (BOOST_PP_SEQ_SPLIT_ ## n seq)
#define BOOST_PP_SEQ_SPLIT_1(x) (x),
#define BOOST_PP_SEQ_SPLIT_2(x) (x) BOOST_PP_SEQ_SPLIT_1
#define BOOST_PP_SEQ_SPLIT_3(x) (x) BOOST_PP_SEQ_SPLIT_2
#define BOOST_PP_SEQ_SPLIT_4(x) (x) BOOST_PP_SEQ_SPLIT_3
#define BOOST_PP_SEQ_SPLIT_5(x) (x) BOOST_PP_SEQ_SPLIT_4
#define BOOST_PP_SEQ_SPLIT_6(x) (x) BOOST_PP_SEQ_SPLIT_5
#define BOOST_PP_SEQ_SPLIT_7(x) (x) BOOST_PP_SEQ_SPLIT_6
#define BOOST_PP_SEQ_SPLIT_8(x) (x) BOOST_PP_SEQ_SPLIT_7
#define BOOST_PP_SEQ_SPLIT_9(x) (x) BOOST_PP_SEQ_SPLIT_8
#define BOOST_PP_SEQ_SPLIT_10(x) (x) BOOST_PP_SEQ_SPLIT_9
#define BOOST_PP_SEQ_SPLIT_11(x) (x) BOOST_PP_SEQ_SPLIT_10
#define BOOST_PP_SEQ_SPLIT_12(x) (x) BOOST_PP_SEQ_SPLIT_11
#define BOOST_PP_SEQ_SPLIT_13(x) (x) BOOST_PP_SEQ_SPLIT_12
#define BOOST_PP_SEQ_SPLIT_14(x) (x) BOOST_PP_SEQ_SPLIT_13
#define BOOST_PP_SEQ_SPLIT_15(x) (x) BOOST_PP_SEQ_SPLIT_14
#define BOOST_PP_SEQ_SPLIT_16(x) (x) BOOST_PP_SEQ_SPLIT_15
#define BOOST_PP_SEQ_SPLIT_17(x) (x) BOOST_PP_SEQ_SPLIT_16
#define BOOST_PP_SEQ_SPLIT_18(x) (x) BOOST_PP_SEQ_SPLIT_17
#define BOOST_PP_SEQ_SPLIT_19(x) (x) BOOST_PP_SEQ_SPLIT_18
#define BOOST_PP_SEQ_SPLIT_20(x) (x) BOOST_PP_SEQ_SPLIT_19
#define BOOST_PP_SEQ_SPLIT_21(x) (x) BOOST_PP_SEQ_SPLIT_20
#define BOOST_PP_SEQ_SPLIT_22(x) (x) BOOST_PP_SEQ_SPLIT_21
#define BOOST_PP_SEQ_SPLIT_23(x) (x) BOOST_PP_SEQ_SPLIT_22
#define BOOST_PP_SEQ_SPLIT_24(x) (x) BOOST_PP_SEQ_SPLIT_23
#define BOOST_PP_SEQ_SPLIT_25(x) (x) BOOST_PP_SEQ_SPLIT_24
#define BOOST_PP_SEQ_SPLIT_26(x) (x) BOOST_PP_SEQ_SPLIT_25
#define BOOST_PP_SEQ_SPLIT_27(x) (x) BOOST_PP_SEQ_SPLIT_26
#define BOOST_PP_SEQ_SPLIT_28(x) (x) BOOST_PP_SEQ_SPLIT_27
#define BOOST_PP_SEQ_SPLIT_29(x) (x) BOOST_PP_SEQ_SPLIT_28
#define BOOST_PP_SEQ_SPLIT_30(x) (x) BOOST_PP_SEQ_SPLIT_29
#define BOOST_PP_SEQ_SPLIT_31(x) (x) BOOST_PP_SEQ_SPLIT_30
#define BOOST_PP_SEQ_SPLIT_32(x) (x) BOOST_PP_SEQ_SPLIT_31
#define BOOST_PP_SEQ_SPLIT_33(x) (x) BOOST_PP_SEQ_SPLIT_32
#define BOOST_PP_SEQ_SPLIT_34(x) (x) BOOST_PP_SEQ_SPLIT_33
#define BOOST_PP_SEQ_SPLIT_35(x) (x) BOOST_PP_SEQ_SPLIT_34
#define BOOST_PP_SEQ_SPLIT_36(x) (x) BOOST_PP_SEQ_SPLIT_35
#define BOOST_PP_SEQ_SPLIT_37(x) (x) BOOST_PP_SEQ_SPLIT_36
#define BOOST_PP_SEQ_SPLIT_38(x) (x) BOOST_PP_SEQ_SPLIT_37
#define BOOST_PP_SEQ_SPLIT_39(x) (x) BOOST_PP_SEQ_SPLIT_38
#define BOOST_PP_SEQ_SPLIT_40(x) (x) BOOST_PP_SEQ_SPLIT_39
#define BOOST_PP_SEQ_SPLIT_41(x) (x) BOOST_PP_SEQ_SPLIT_40
#define BOOST_PP_SEQ_SPLIT_42(x) (x) BOOST_PP_SEQ_SPLIT_41
#define BOOST_PP_SEQ_SPLIT_43(x) (x) BOOST_PP_SEQ_SPLIT_42
#define BOOST_PP_SEQ_SPLIT_44(x) (x) BOOST_PP_SEQ_SPLIT_43
#define BOOST_PP_SEQ_SPLIT_45(x) (x) BOOST_PP_SEQ_SPLIT_44
#define BOOST_PP_SEQ_SPLIT_46(x) (x) BOOST_PP_SEQ_SPLIT_45
#define BOOST_PP_SEQ_SPLIT_47(x) (x) BOOST_PP_SEQ_SPLIT_46
#define BOOST_PP_SEQ_SPLIT_48(x) (x) BOOST_PP_SEQ_SPLIT_47
#define BOOST_PP_SEQ_SPLIT_49(x) (x) BOOST_PP_SEQ_SPLIT_48
#define BOOST_PP_SEQ_SPLIT_50(x) (x) BOOST_PP_SEQ_SPLIT_49
#define BOOST_PP_SEQ_SPLIT_51(x) (x) BOOST_PP_SEQ_SPLIT_50
#define BOOST_PP_SEQ_SPLIT_52(x) (x) BOOST_PP_SEQ_SPLIT_51
#define BOOST_PP_SEQ_SPLIT_53(x) (x) BOOST_PP_SEQ_SPLIT_52
#define BOOST_PP_SEQ_SPLIT_54(x) (x) BOOST_PP_SEQ_SPLIT_53
#define BOOST_PP_SEQ_SPLIT_55(x) (x) BOOST_PP_SEQ_SPLIT_54
#define BOOST_PP_SEQ_SPLIT_56(x) (x) BOOST_PP_SEQ_SPLIT_55
#define BOOST_PP_SEQ_SPLIT_57(x) (x) BOOST_PP_SEQ_SPLIT_56
#define BOOST_PP_SEQ_SPLIT_58(x) (x) BOOST_PP_SEQ_SPLIT_57
#define BOOST_PP_SEQ_SPLIT_59(x) (x) BOOST_PP_SEQ_SPLIT_58
#define BOOST_PP_SEQ_SPLIT_60(x) (x) BOOST_PP_SEQ_SPLIT_59
#define BOOST_PP_SEQ_SPLIT_61(x) (x) BOOST_PP_SEQ_SPLIT_60
#define BOOST_PP_SEQ_SPLIT_62(x) (x) BOOST_PP_SEQ_SPLIT_61
#define BOOST_PP_SEQ_SPLIT_63(x) (x) BOOST_PP_SEQ_SPLIT_62
#define BOOST_PP_SEQ_SPLIT_64(x) (x) BOOST_PP_SEQ_SPLIT_63
#define BOOST_PP_SEQ_SPLIT_65(x) (x) BOOST_PP_SEQ_SPLIT_64
#define BOOST_PP_SEQ_SPLIT_66(x) (x) BOOST_PP_SEQ_SPLIT_65
#define BOOST_PP_SEQ_SPLIT_67(x) (x) BOOST_PP_SEQ_SPLIT_66
#define BOOST_PP_SEQ_SPLIT_68(x) (x) BOOST_PP_SEQ_SPLIT_67
#define BOOST_PP_SEQ_SPLIT_69(x) (x) BOOST_PP_SEQ_SPLIT_68
#define BOOST_PP_SEQ_SPLIT_70(x) (x) BOOST_PP_SEQ_SPLIT_69
#define BOOST_PP_SEQ_SPLIT_71(x) (x) BOOST_PP_SEQ_SPLIT_70
#define BOOST_PP_SEQ_SPLIT_72(x) (x) BOOST_PP_SEQ_SPLIT_71
#define BOOST_PP_SEQ_SPLIT_73(x) (x) BOOST_PP_SEQ_SPLIT_72
#define BOOST_PP_SEQ_SPLIT_74(x) (x) BOOST_PP_SEQ_SPLIT_73
#define BOOST_PP_SEQ_SPLIT_75(x) (x) BOOST_PP_SEQ_SPLIT_74
#define BOOST_PP_SEQ_SPLIT_76(x) (x) BOOST_PP_SEQ_SPLIT_75
#define BOOST_PP_SEQ_SPLIT_77(x) (x) BOOST_PP_SEQ_SPLIT_76
#define BOOST_PP_SEQ_SPLIT_78(x) (x) BOOST_PP_SEQ_SPLIT_77
#define BOOST_PP_SEQ_SPLIT_79(x) (x) BOOST_PP_SEQ_SPLIT_78
#define BOOST_PP_SEQ_SPLIT_80(x) (x) BOOST_PP_SEQ_SPLIT_79
#define BOOST_PP_SEQ_SPLIT_81(x) (x) BOOST_PP_SEQ_SPLIT_80
#define BOOST_PP_SEQ_SPLIT_82(x) (x) BOOST_PP_SEQ_SPLIT_81
#define BOOST_PP_SEQ_SPLIT_83(x) (x) BOOST_PP_SEQ_SPLIT_82
#define BOOST_PP_SEQ_SPLIT_84(x) (x) BOOST_PP_SEQ_SPLIT_83
#define BOOST_PP_SEQ_SPLIT_85(x) (x) BOOST_PP_SEQ_SPLIT_84
#define BOOST_PP_SEQ_SPLIT_86(x) (x) BOOST_PP_SEQ_SPLIT_85
#define BOOST_PP_SEQ_SPLIT_87(x) (x) BOOST_PP_SEQ_SPLIT_86
#define BOOST_PP_SEQ_SPLIT_88(x) (x) BOOST_PP_SEQ_SPLIT_87
#define BOOST_PP_SEQ_SPLIT_89(x) (x) BOOST_PP_SEQ_SPLIT_88
#define BOOST_PP_SEQ_SPLIT_90(x) (x) BOOST_PP_SEQ_SPLIT_89
#define BOOST_PP_SEQ_SPLIT_91(x) (x) BOOST_PP_SEQ_SPLIT_90
#define BOOST_PP_SEQ_SPLIT_92(x) (x) BOOST_PP_SEQ_SPLIT_91
#define BOOST_PP_SEQ_SPLIT_93(x) (x) BOOST_PP_SEQ_SPLIT_92
#define BOOST_PP_SEQ_SPLIT_94(x) (x) BOOST_PP_SEQ_SPLIT_93
#define BOOST_PP_SEQ_SPLIT_95(x) (x) BOOST_PP_SEQ_SPLIT_94
#define BOOST_PP_SEQ_SPLIT_96(x) (x) BOOST_PP_SEQ_SPLIT_95
#define BOOST_PP_SEQ_SPLIT_97(x) (x) BOOST_PP_SEQ_SPLIT_96
#define BOOST_PP_SEQ_SPLIT_98(x) (x) BOOST_PP_SEQ_SPLIT_97
#define BOOST_PP_SEQ_SPLIT_99(x) (x) BOOST_PP_SEQ_SPLIT_98
#define BOOST_PP_SEQ_SPLIT_100(x) (x) BOOST_PP_SEQ_SPLIT_99
#define BOOST_PP_SEQ_SPLIT_101(x) (x) BOOST_PP_SEQ_SPLIT_100
#define BOOST_PP_SEQ_SPLIT_102(x) (x) BOOST_PP_SEQ_SPLIT_101
#define BOOST_PP_SEQ_SPLIT_103(x) (x) BOOST_PP_SEQ_SPLIT_102
#define BOOST_PP_SEQ_SPLIT_104(x) (x) BOOST_PP_SEQ_SPLIT_103
#define BOOST_PP_SEQ_SPLIT_105(x) (x) BOOST_PP_SEQ_SPLIT_104
#define BOOST_PP_SEQ_SPLIT_106(x) (x) BOOST_PP_SEQ_SPLIT_105
#define BOOST_PP_SEQ_SPLIT_107(x) (x) BOOST_PP_SEQ_SPLIT_106
#define BOOST_PP_SEQ_SPLIT_108(x) (x) BOOST_PP_SEQ_SPLIT_107
#define BOOST_PP_SEQ_SPLIT_109(x) (x) BOOST_PP_SEQ_SPLIT_108
#define BOOST_PP_SEQ_SPLIT_110(x) (x) BOOST_PP_SEQ_SPLIT_109
#define BOOST_PP_SEQ_SPLIT_111(x) (x) BOOST_PP_SEQ_SPLIT_110
#define BOOST_PP_SEQ_SPLIT_112(x) (x) BOOST_PP_SEQ_SPLIT_111
#define BOOST_PP_SEQ_SPLIT_113(x) (x) BOOST_PP_SEQ_SPLIT_112
#define BOOST_PP_SEQ_SPLIT_114(x) (x) BOOST_PP_SEQ_SPLIT_113
#define BOOST_PP_SEQ_SPLIT_115(x) (x) BOOST_PP_SEQ_SPLIT_114
#define BOOST_PP_SEQ_SPLIT_116(x) (x) BOOST_PP_SEQ_SPLIT_115
#define BOOST_PP_SEQ_SPLIT_117(x) (x) BOOST_PP_SEQ_SPLIT_116
#define BOOST_PP_SEQ_SPLIT_118(x) (x) BOOST_PP_SEQ_SPLIT_117
#define BOOST_PP_SEQ_SPLIT_119(x) (x) BOOST_PP_SEQ_SPLIT_118
#define BOOST_PP_SEQ_SPLIT_120(x) (x) BOOST_PP_SEQ_SPLIT_119
#define BOOST_PP_SEQ_SPLIT_121(x) (x) BOOST_PP_SEQ_SPLIT_120
#define BOOST_PP_SEQ_SPLIT_122(x) (x) BOOST_PP_SEQ_SPLIT_121
#define BOOST_PP_SEQ_SPLIT_123(x) (x) BOOST_PP_SEQ_SPLIT_122
#define BOOST_PP_SEQ_SPLIT_124(x) (x) BOOST_PP_SEQ_SPLIT_123
#define BOOST_PP_SEQ_SPLIT_125(x) (x) BOOST_PP_SEQ_SPLIT_124
#define BOOST_PP_SEQ_SPLIT_126(x) (x) BOOST_PP_SEQ_SPLIT_125
#define BOOST_PP_SEQ_SPLIT_127(x) (x) BOOST_PP_SEQ_SPLIT_126
#define BOOST_PP_SEQ_SPLIT_128(x) (x) BOOST_PP_SEQ_SPLIT_127
#define BOOST_PP_SEQ_SPLIT_129(x) (x) BOOST_PP_SEQ_SPLIT_128
#define BOOST_PP_SEQ_SPLIT_130(x) (x) BOOST_PP_SEQ_SPLIT_129
#define BOOST_PP_SEQ_SPLIT_131(x) (x) BOOST_PP_SEQ_SPLIT_130
#define BOOST_PP_SEQ_SPLIT_132(x) (x) BOOST_PP_SEQ_SPLIT_131
#define BOOST_PP_SEQ_SPLIT_133(x) (x) BOOST_PP_SEQ_SPLIT_132
#define BOOST_PP_SEQ_SPLIT_134(x) (x) BOOST_PP_SEQ_SPLIT_133
#define BOOST_PP_SEQ_SPLIT_135(x) (x) BOOST_PP_SEQ_SPLIT_134
#define BOOST_PP_SEQ_SPLIT_136(x) (x) BOOST_PP_SEQ_SPLIT_135
#define BOOST_PP_SEQ_SPLIT_137(x) (x) BOOST_PP_SEQ_SPLIT_136
#define BOOST_PP_SEQ_SPLIT_138(x) (x) BOOST_PP_SEQ_SPLIT_137
#define BOOST_PP_SEQ_SPLIT_139(x) (x) BOOST_PP_SEQ_SPLIT_138
#define BOOST_PP_SEQ_SPLIT_140(x) (x) BOOST_PP_SEQ_SPLIT_139
#define BOOST_PP_SEQ_SPLIT_141(x) (x) BOOST_PP_SEQ_SPLIT_140
#define BOOST_PP_SEQ_SPLIT_142(x) (x) BOOST_PP_SEQ_SPLIT_141
#define BOOST_PP_SEQ_SPLIT_143(x) (x) BOOST_PP_SEQ_SPLIT_142
#define BOOST_PP_SEQ_SPLIT_144(x) (x) BOOST_PP_SEQ_SPLIT_143
#define BOOST_PP_SEQ_SPLIT_145(x) (x) BOOST_PP_SEQ_SPLIT_144
#define BOOST_PP_SEQ_SPLIT_146(x) (x) BOOST_PP_SEQ_SPLIT_145
#define BOOST_PP_SEQ_SPLIT_147(x) (x) BOOST_PP_SEQ_SPLIT_146
#define BOOST_PP_SEQ_SPLIT_148(x) (x) BOOST_PP_SEQ_SPLIT_147
#define BOOST_PP_SEQ_SPLIT_149(x) (x) BOOST_PP_SEQ_SPLIT_148
#define BOOST_PP_SEQ_SPLIT_150(x) (x) BOOST_PP_SEQ_SPLIT_149
#define BOOST_PP_SEQ_SPLIT_151(x) (x) BOOST_PP_SEQ_SPLIT_150
#define BOOST_PP_SEQ_SPLIT_152(x) (x) BOOST_PP_SEQ_SPLIT_151
#define BOOST_PP_SEQ_SPLIT_153(x) (x) BOOST_PP_SEQ_SPLIT_152
#define BOOST_PP_SEQ_SPLIT_154(x) (x) BOOST_PP_SEQ_SPLIT_153
#define BOOST_PP_SEQ_SPLIT_155(x) (x) BOOST_PP_SEQ_SPLIT_154
#define BOOST_PP_SEQ_SPLIT_156(x) (x) BOOST_PP_SEQ_SPLIT_155
#define BOOST_PP_SEQ_SPLIT_157(x) (x) BOOST_PP_SEQ_SPLIT_156
#define BOOST_PP_SEQ_SPLIT_158(x) (x) BOOST_PP_SEQ_SPLIT_157
#define BOOST_PP_SEQ_SPLIT_159(x) (x) BOOST_PP_SEQ_SPLIT_158
#define BOOST_PP_SEQ_SPLIT_160(x) (x) BOOST_PP_SEQ_SPLIT_159
#define BOOST_PP_SEQ_SPLIT_161(x) (x) BOOST_PP_SEQ_SPLIT_160
#define BOOST_PP_SEQ_SPLIT_162(x) (x) BOOST_PP_SEQ_SPLIT_161
#define BOOST_PP_SEQ_SPLIT_163(x) (x) BOOST_PP_SEQ_SPLIT_162
#define BOOST_PP_SEQ_SPLIT_164(x) (x) BOOST_PP_SEQ_SPLIT_163
#define BOOST_PP_SEQ_SPLIT_165(x) (x) BOOST_PP_SEQ_SPLIT_164
#define BOOST_PP_SEQ_SPLIT_166(x) (x) BOOST_PP_SEQ_SPLIT_165
#define BOOST_PP_SEQ_SPLIT_167(x) (x) BOOST_PP_SEQ_SPLIT_166
#define BOOST_PP_SEQ_SPLIT_168(x) (x) BOOST_PP_SEQ_SPLIT_167
#define BOOST_PP_SEQ_SPLIT_169(x) (x) BOOST_PP_SEQ_SPLIT_168
#define BOOST_PP_SEQ_SPLIT_170(x) (x) BOOST_PP_SEQ_SPLIT_169
#define BOOST_PP_SEQ_SPLIT_171(x) (x) BOOST_PP_SEQ_SPLIT_170
#define BOOST_PP_SEQ_SPLIT_172(x) (x) BOOST_PP_SEQ_SPLIT_171
#define BOOST_PP_SEQ_SPLIT_173(x) (x) BOOST_PP_SEQ_SPLIT_172
#define BOOST_PP_SEQ_SPLIT_174(x) (x) BOOST_PP_SEQ_SPLIT_173
#define BOOST_PP_SEQ_SPLIT_175(x) (x) BOOST_PP_SEQ_SPLIT_174
#define BOOST_PP_SEQ_SPLIT_176(x) (x) BOOST_PP_SEQ_SPLIT_175
#define BOOST_PP_SEQ_SPLIT_177(x) (x) BOOST_PP_SEQ_SPLIT_176
#define BOOST_PP_SEQ_SPLIT_178(x) (x) BOOST_PP_SEQ_SPLIT_177
#define BOOST_PP_SEQ_SPLIT_179(x) (x) BOOST_PP_SEQ_SPLIT_178
#define BOOST_PP_SEQ_SPLIT_180(x) (x) BOOST_PP_SEQ_SPLIT_179
#define BOOST_PP_SEQ_SPLIT_181(x) (x) BOOST_PP_SEQ_SPLIT_180
#define BOOST_PP_SEQ_SPLIT_182(x) (x) BOOST_PP_SEQ_SPLIT_181
#define BOOST_PP_SEQ_SPLIT_183(x) (x) BOOST_PP_SEQ_SPLIT_182
#define BOOST_PP_SEQ_SPLIT_184(x) (x) BOOST_PP_SEQ_SPLIT_183
#define BOOST_PP_SEQ_SPLIT_185(x) (x) BOOST_PP_SEQ_SPLIT_184
#define BOOST_PP_SEQ_SPLIT_186(x) (x) BOOST_PP_SEQ_SPLIT_185
#define BOOST_PP_SEQ_SPLIT_187(x) (x) BOOST_PP_SEQ_SPLIT_186
#define BOOST_PP_SEQ_SPLIT_188(x) (x) BOOST_PP_SEQ_SPLIT_187
#define BOOST_PP_SEQ_SPLIT_189(x) (x) BOOST_PP_SEQ_SPLIT_188
#define BOOST_PP_SEQ_SPLIT_190(x) (x) BOOST_PP_SEQ_SPLIT_189
#define BOOST_PP_SEQ_SPLIT_191(x) (x) BOOST_PP_SEQ_SPLIT_190
#define BOOST_PP_SEQ_SPLIT_192(x) (x) BOOST_PP_SEQ_SPLIT_191
#define BOOST_PP_SEQ_SPLIT_193(x) (x) BOOST_PP_SEQ_SPLIT_192
#define BOOST_PP_SEQ_SPLIT_194(x) (x) BOOST_PP_SEQ_SPLIT_193
#define BOOST_PP_SEQ_SPLIT_195(x) (x) BOOST_PP_SEQ_SPLIT_194
#define BOOST_PP_SEQ_SPLIT_196(x) (x) BOOST_PP_SEQ_SPLIT_195
#define BOOST_PP_SEQ_SPLIT_197(x) (x) BOOST_PP_SEQ_SPLIT_196
#define BOOST_PP_SEQ_SPLIT_198(x) (x) BOOST_PP_SEQ_SPLIT_197
#define BOOST_PP_SEQ_SPLIT_199(x) (x) BOOST_PP_SEQ_SPLIT_198
#define BOOST_PP_SEQ_SPLIT_200(x) (x) BOOST_PP_SEQ_SPLIT_199
#define BOOST_PP_SEQ_SPLIT_201(x) (x) BOOST_PP_SEQ_SPLIT_200
#define BOOST_PP_SEQ_SPLIT_202(x) (x) BOOST_PP_SEQ_SPLIT_201
#define BOOST_PP_SEQ_SPLIT_203(x) (x) BOOST_PP_SEQ_SPLIT_202
#define BOOST_PP_SEQ_SPLIT_204(x) (x) BOOST_PP_SEQ_SPLIT_203
#define BOOST_PP_SEQ_SPLIT_205(x) (x) BOOST_PP_SEQ_SPLIT_204
#define BOOST_PP_SEQ_SPLIT_206(x) (x) BOOST_PP_SEQ_SPLIT_205
#define BOOST_PP_SEQ_SPLIT_207(x) (x) BOOST_PP_SEQ_SPLIT_206
#define BOOST_PP_SEQ_SPLIT_208(x) (x) BOOST_PP_SEQ_SPLIT_207
#define BOOST_PP_SEQ_SPLIT_209(x) (x) BOOST_PP_SEQ_SPLIT_208
#define BOOST_PP_SEQ_SPLIT_210(x) (x) BOOST_PP_SEQ_SPLIT_209
#define BOOST_PP_SEQ_SPLIT_211(x) (x) BOOST_PP_SEQ_SPLIT_210
#define BOOST_PP_SEQ_SPLIT_212(x) (x) BOOST_PP_SEQ_SPLIT_211
#define BOOST_PP_SEQ_SPLIT_213(x) (x) BOOST_PP_SEQ_SPLIT_212
#define BOOST_PP_SEQ_SPLIT_214(x) (x) BOOST_PP_SEQ_SPLIT_213
#define BOOST_PP_SEQ_SPLIT_215(x) (x) BOOST_PP_SEQ_SPLIT_214
#define BOOST_PP_SEQ_SPLIT_216(x) (x) BOOST_PP_SEQ_SPLIT_215
#define BOOST_PP_SEQ_SPLIT_217(x) (x) BOOST_PP_SEQ_SPLIT_216
#define BOOST_PP_SEQ_SPLIT_218(x) (x) BOOST_PP_SEQ_SPLIT_217
#define BOOST_PP_SEQ_SPLIT_219(x) (x) BOOST_PP_SEQ_SPLIT_218
#define BOOST_PP_SEQ_SPLIT_220(x) (x) BOOST_PP_SEQ_SPLIT_219
#define BOOST_PP_SEQ_SPLIT_221(x) (x) BOOST_PP_SEQ_SPLIT_220
#define BOOST_PP_SEQ_SPLIT_222(x) (x) BOOST_PP_SEQ_SPLIT_221
#define BOOST_PP_SEQ_SPLIT_223(x) (x) BOOST_PP_SEQ_SPLIT_222
#define BOOST_PP_SEQ_SPLIT_224(x) (x) BOOST_PP_SEQ_SPLIT_223
#define BOOST_PP_SEQ_SPLIT_225(x) (x) BOOST_PP_SEQ_SPLIT_224
#define BOOST_PP_SEQ_SPLIT_226(x) (x) BOOST_PP_SEQ_SPLIT_225
#define BOOST_PP_SEQ_SPLIT_227(x) (x) BOOST_PP_SEQ_SPLIT_226
#define BOOST_PP_SEQ_SPLIT_228(x) (x) BOOST_PP_SEQ_SPLIT_227
#define BOOST_PP_SEQ_SPLIT_229(x) (x) BOOST_PP_SEQ_SPLIT_228
#define BOOST_PP_SEQ_SPLIT_230(x) (x) BOOST_PP_SEQ_SPLIT_229
#define BOOST_PP_SEQ_SPLIT_231(x) (x) BOOST_PP_SEQ_SPLIT_230
#define BOOST_PP_SEQ_SPLIT_232(x) (x) BOOST_PP_SEQ_SPLIT_231
#define BOOST_PP_SEQ_SPLIT_233(x) (x) BOOST_PP_SEQ_SPLIT_232
#define BOOST_PP_SEQ_SPLIT_234(x) (x) BOOST_PP_SEQ_SPLIT_233
#define BOOST_PP_SEQ_SPLIT_235(x) (x) BOOST_PP_SEQ_SPLIT_234
#define BOOST_PP_SEQ_SPLIT_236(x) (x) BOOST_PP_SEQ_SPLIT_235
#define BOOST_PP_SEQ_SPLIT_237(x) (x) BOOST_PP_SEQ_SPLIT_236
#define BOOST_PP_SEQ_SPLIT_238(x) (x) BOOST_PP_SEQ_SPLIT_237
#define BOOST_PP_SEQ_SPLIT_239(x) (x) BOOST_PP_SEQ_SPLIT_238
#define BOOST_PP_SEQ_SPLIT_240(x) (x) BOOST_PP_SEQ_SPLIT_239
#define BOOST_PP_SEQ_SPLIT_241(x) (x) BOOST_PP_SEQ_SPLIT_240
#define BOOST_PP_SEQ_SPLIT_242(x) (x) BOOST_PP_SEQ_SPLIT_241
#define BOOST_PP_SEQ_SPLIT_243(x) (x) BOOST_PP_SEQ_SPLIT_242
#define BOOST_PP_SEQ_SPLIT_244(x) (x) BOOST_PP_SEQ_SPLIT_243
#define BOOST_PP_SEQ_SPLIT_245(x) (x) BOOST_PP_SEQ_SPLIT_244
#define BOOST_PP_SEQ_SPLIT_246(x) (x) BOOST_PP_SEQ_SPLIT_245
#define BOOST_PP_SEQ_SPLIT_247(x) (x) BOOST_PP_SEQ_SPLIT_246
#define BOOST_PP_SEQ_SPLIT_248(x) (x) BOOST_PP_SEQ_SPLIT_247
#define BOOST_PP_SEQ_SPLIT_249(x) (x) BOOST_PP_SEQ_SPLIT_248
#define BOOST_PP_SEQ_SPLIT_250(x) (x) BOOST_PP_SEQ_SPLIT_249
#define BOOST_PP_SEQ_SPLIT_251(x) (x) BOOST_PP_SEQ_SPLIT_250
#define BOOST_PP_SEQ_SPLIT_252(x) (x) BOOST_PP_SEQ_SPLIT_251
#define BOOST_PP_SEQ_SPLIT_253(x) (x) BOOST_PP_SEQ_SPLIT_252
#define BOOST_PP_SEQ_SPLIT_254(x) (x) BOOST_PP_SEQ_SPLIT_253
#define BOOST_PP_SEQ_SPLIT_255(x) (x) BOOST_PP_SEQ_SPLIT_254
#define BOOST_PP_SEQ_SPLIT_256(x) (x) BOOST_PP_SEQ_SPLIT_255

#define BOOST_PP_SEQ_SUBSEQ(seq, i, len) BOOST_PP_SEQ_FIRST_N(len, BOOST_PP_SEQ_REST_N(i, seq))

#define BOOST_PP_SEQ_TAIL(seq) BOOST_PP_SEQ_TAIL_I seq
#define BOOST_PP_SEQ_TAIL_I(x)

#define BOOST_PP_SEQ_TO_ARRAY(seq) (BOOST_PP_SEQ_SIZE(seq), (BOOST_PP_SEQ_ENUM(seq)))

#define BOOST_PP_SEQ_TO_TUPLE(seq) (BOOST_PP_SEQ_ENUM(seq))

#define BOOST_PP_SEQ_TRANSFORM(op, data, seq) BOOST_PP_SEQ_TAIL(BOOST_PP_TUPLE_ELEM(3, 2, BOOST_PP_SEQ_FOLD_LEFT(BOOST_PP_SEQ_TRANSFORM_O, (op, data, (nil)), seq)))
#define BOOST_PP_SEQ_TRANSFORM_O(s, state, elem) BOOST_PP_SEQ_TRANSFORM_O_IM(s, BOOST_PP_TUPLE_REM_3 state, elem)
#define BOOST_PP_SEQ_TRANSFORM_O_IM(s, im, elem) BOOST_PP_SEQ_TRANSFORM_O_I(s, im, elem)
#define BOOST_PP_SEQ_TRANSFORM_O_I(s, op, data, res, elem) (op, data, res (op(s, data, elem)))
#define BOOST_PP_SEQ_TRANSFORM_S(s, op, data, seq) BOOST_PP_SEQ_TAIL(BOOST_PP_TUPLE_ELEM(3, 2, BOOST_PP_SEQ_FOLD_LEFT_ ## s(BOOST_PP_SEQ_TRANSFORM_O, (op, data, (nil)), seq)))

#define BOOST_PP_SLOT(i) BOOST_PP_CAT(BOOST_PP_SLOT_, i)()

#define BOOST_PP_SLOT_CC_2(a, b) BOOST_PP_SLOT_CC_2_D(a, b)
#define BOOST_PP_SLOT_CC_3(a, b, c) BOOST_PP_SLOT_CC_3_D(a, b, c)
#define BOOST_PP_SLOT_CC_4(a, b, c, d) BOOST_PP_SLOT_CC_4_D(a, b, c, d)
#define BOOST_PP_SLOT_CC_5(a, b, c, d, e) BOOST_PP_SLOT_CC_5_D(a, b, c, d, e)
#define BOOST_PP_SLOT_CC_6(a, b, c, d, e, f) BOOST_PP_SLOT_CC_6_D(a, b, c, d, e, f)
#define BOOST_PP_SLOT_CC_7(a, b, c, d, e, f, g) BOOST_PP_SLOT_CC_7_D(a, b, c, d, e, f, g)
#define BOOST_PP_SLOT_CC_8(a, b, c, d, e, f, g, h) BOOST_PP_SLOT_CC_8_D(a, b, c, d, e, f, g, h)
#define BOOST_PP_SLOT_CC_9(a, b, c, d, e, f, g, h, i) BOOST_PP_SLOT_CC_9_D(a, b, c, d, e, f, g, h, i)
#define BOOST_PP_SLOT_CC_10(a, b, c, d, e, f, g, h, i, j) BOOST_PP_SLOT_CC_10_D(a, b, c, d, e, f, g, h, i, j)

#define BOOST_PP_SLOT_CC_2_D(a, b) a ## b
#define BOOST_PP_SLOT_CC_3_D(a, b, c) a ## b ## c
#define BOOST_PP_SLOT_CC_4_D(a, b, c, d) a ## b ## c ## d
#define BOOST_PP_SLOT_CC_5_D(a, b, c, d, e) a ## b ## c ## d ## e
#define BOOST_PP_SLOT_CC_6_D(a, b, c, d, e, f) a ## b ## c ## d ## e ## f
#define BOOST_PP_SLOT_CC_7_D(a, b, c, d, e, f, g) a ## b ## c ## d ## e ## f ## g
#define BOOST_PP_SLOT_CC_8_D(a, b, c, d, e, f, g, h) a ## b ## c ## d ## e ## f ## g ## h
#define BOOST_PP_SLOT_CC_9_D(a, b, c, d, e, f, g, h, i) a ## b ## c ## d ## e ## f ## g ## h ## i
#define BOOST_PP_SLOT_CC_10_D(a, b, c, d, e, f, g, h, i, j) a ## b ## c ## d ## e ## f ## g ## h ## i ## j

#define BOOST_PP_SLOT_OFFSET_10(x) (x) % 1000000000UL
#define BOOST_PP_SLOT_OFFSET_9(x) BOOST_PP_SLOT_OFFSET_10(x) % 100000000UL
#define BOOST_PP_SLOT_OFFSET_8(x) BOOST_PP_SLOT_OFFSET_9(x) % 10000000UL
#define BOOST_PP_SLOT_OFFSET_7(x) BOOST_PP_SLOT_OFFSET_8(x) % 1000000UL
#define BOOST_PP_SLOT_OFFSET_6(x) BOOST_PP_SLOT_OFFSET_7(x) % 100000UL
#define BOOST_PP_SLOT_OFFSET_5(x) BOOST_PP_SLOT_OFFSET_6(x) % 10000UL
#define BOOST_PP_SLOT_OFFSET_4(x) BOOST_PP_SLOT_OFFSET_5(x) % 1000UL
#define BOOST_PP_SLOT_OFFSET_3(x) BOOST_PP_SLOT_OFFSET_4(x) % 100UL
#define BOOST_PP_SLOT_OFFSET_2(x) BOOST_PP_SLOT_OFFSET_3(x) % 10UL

#define BOOST_PP_SPLIT(n, im) BOOST_PP_SPLIT_I(n)(im)
#define BOOST_PP_SPLIT_I(n) BOOST_PP_SPLIT_ ## n
#define BOOST_PP_SPLIT_0(a, b) a
#define BOOST_PP_SPLIT_1(a, b) b

#define BOOST_PP_STRINGIZE(text) BOOST_PP_STRINGIZE_I(text)
#define BOOST_PP_STRINGIZE_I(text) #text

#define BOOST_PP_SUB(x, y) BOOST_PP_TUPLE_ELEM(2, 0, BOOST_PP_WHILE(BOOST_PP_SUB_P, BOOST_PP_SUB_O, (x, y)))
#define BOOST_PP_SUB_P(d, xy) BOOST_PP_TUPLE_ELEM(2, 1, xy)
#define BOOST_PP_SUB_O(d, xy) BOOST_PP_SUB_O_I xy
#define BOOST_PP_SUB_O_I(x, y) (BOOST_PP_DEC(x), BOOST_PP_DEC(y))
#define BOOST_PP_SUB_D(d, x, y) BOOST_PP_TUPLE_ELEM(2, 0, BOOST_PP_WHILE_ ## d(BOOST_PP_SUB_P, BOOST_PP_SUB_O, (x, y)))

#define BOOST_PP_TUPLE_EAT(size) BOOST_PP_TUPLE_EAT_I(size)
#define BOOST_PP_TUPLE_EAT_I(size) BOOST_PP_TUPLE_EAT_ ## size
#define BOOST_PP_TUPLE_EAT_0()
#define BOOST_PP_TUPLE_EAT_1(a)
#define BOOST_PP_TUPLE_EAT_2(a, b)
#define BOOST_PP_TUPLE_EAT_3(a, b, c)
#define BOOST_PP_TUPLE_EAT_4(a, b, c, d)
#define BOOST_PP_TUPLE_EAT_5(a, b, c, d, e)
#define BOOST_PP_TUPLE_EAT_6(a, b, c, d, e, f)
#define BOOST_PP_TUPLE_EAT_7(a, b, c, d, e, f, g)
#define BOOST_PP_TUPLE_EAT_8(a, b, c, d, e, f, g, h)
#define BOOST_PP_TUPLE_EAT_9(a, b, c, d, e, f, g, h, i)
#define BOOST_PP_TUPLE_EAT_10(a, b, c, d, e, f, g, h, i, j)
#define BOOST_PP_TUPLE_EAT_11(a, b, c, d, e, f, g, h, i, j, k)
#define BOOST_PP_TUPLE_EAT_12(a, b, c, d, e, f, g, h, i, j, k, l)
#define BOOST_PP_TUPLE_EAT_13(a, b, c, d, e, f, g, h, i, j, k, l, m)
#define BOOST_PP_TUPLE_EAT_14(a, b, c, d, e, f, g, h, i, j, k, l, m, n)
#define BOOST_PP_TUPLE_EAT_15(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o)
#define BOOST_PP_TUPLE_EAT_16(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p)
#define BOOST_PP_TUPLE_EAT_17(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q)
#define BOOST_PP_TUPLE_EAT_18(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r)
#define BOOST_PP_TUPLE_EAT_19(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s)
#define BOOST_PP_TUPLE_EAT_20(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t)
#define BOOST_PP_TUPLE_EAT_21(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u)
#define BOOST_PP_TUPLE_EAT_22(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v)
#define BOOST_PP_TUPLE_EAT_23(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w)
#define BOOST_PP_TUPLE_EAT_24(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x)
#define BOOST_PP_TUPLE_EAT_25(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y)

#define BOOST_PP_TUPLE_ELEM(size, index, tuple) BOOST_PP_TUPLE_ELEM_I(size, index, tuple)
#define BOOST_PP_TUPLE_ELEM_I(s, i, t) BOOST_PP_TUPLE_ELEM_ ## s ## _ ## i t
#define BOOST_PP_TUPLE_ELEM_1_0(a) a
#define BOOST_PP_TUPLE_ELEM_2_0(a, b) a
#define BOOST_PP_TUPLE_ELEM_2_1(a, b) b
#define BOOST_PP_TUPLE_ELEM_3_0(a, b, c) a
#define BOOST_PP_TUPLE_ELEM_3_1(a, b, c) b
#define BOOST_PP_TUPLE_ELEM_3_2(a, b, c) c
#define BOOST_PP_TUPLE_ELEM_4_0(a, b, c, d) a
#define BOOST_PP_TUPLE_ELEM_4_1(a, b, c, d) b
#define BOOST_PP_TUPLE_ELEM_4_2(a, b, c, d) c
#define BOOST_PP_TUPLE_ELEM_4_3(a, b, c, d) d
#define BOOST_PP_TUPLE_ELEM_5_0(a, b, c, d, e) a
#define BOOST_PP_TUPLE_ELEM_5_1(a, b, c, d, e) b
#define BOOST_PP_TUPLE_ELEM_5_2(a, b, c, d, e) c
#define BOOST_PP_TUPLE_ELEM_5_3(a, b, c, d, e) d
#define BOOST_PP_TUPLE_ELEM_5_4(a, b, c, d, e) e
#define BOOST_PP_TUPLE_ELEM_6_0(a, b, c, d, e, f) a
#define BOOST_PP_TUPLE_ELEM_6_1(a, b, c, d, e, f) b
#define BOOST_PP_TUPLE_ELEM_6_2(a, b, c, d, e, f) c
#define BOOST_PP_TUPLE_ELEM_6_3(a, b, c, d, e, f) d
#define BOOST_PP_TUPLE_ELEM_6_4(a, b, c, d, e, f) e
#define BOOST_PP_TUPLE_ELEM_6_5(a, b, c, d, e, f) f
#define BOOST_PP_TUPLE_ELEM_7_0(a, b, c, d, e, f, g) a
#define BOOST_PP_TUPLE_ELEM_7_1(a, b, c, d, e, f, g) b
#define BOOST_PP_TUPLE_ELEM_7_2(a, b, c, d, e, f, g) c
#define BOOST_PP_TUPLE_ELEM_7_3(a, b, c, d, e, f, g) d
#define BOOST_PP_TUPLE_ELEM_7_4(a, b, c, d, e, f, g) e
#define BOOST_PP_TUPLE_ELEM_7_5(a, b, c, d, e, f, g) f
#define BOOST_PP_TUPLE_ELEM_7_6(a, b, c, d, e, f, g) g
#define BOOST_PP_TUPLE_ELEM_8_0(a, b, c, d, e, f, g, h) a
#define BOOST_PP_TUPLE_ELEM_8_1(a, b, c, d, e, f, g, h) b
#define BOOST_PP_TUPLE_ELEM_8_2(a, b, c, d, e, f, g, h) c
#define BOOST_PP_TUPLE_ELEM_8_3(a, b, c, d, e, f, g, h) d
#define BOOST_PP_TUPLE_ELEM_8_4(a, b, c, d, e, f, g, h) e
#define BOOST_PP_TUPLE_ELEM_8_5(a, b, c, d, e, f, g, h) f
#define BOOST_PP_TUPLE_ELEM_8_6(a, b, c, d, e, f, g, h) g
#define BOOST_PP_TUPLE_ELEM_8_7(a, b, c, d, e, f, g, h) h
#define BOOST_PP_TUPLE_ELEM_9_0(a, b, c, d, e, f, g, h, i) a
#define BOOST_PP_TUPLE_ELEM_9_1(a, b, c, d, e, f, g, h, i) b
#define BOOST_PP_TUPLE_ELEM_9_2(a, b, c, d, e, f, g, h, i) c
#define BOOST_PP_TUPLE_ELEM_9_3(a, b, c, d, e, f, g, h, i) d
#define BOOST_PP_TUPLE_ELEM_9_4(a, b, c, d, e, f, g, h, i) e
#define BOOST_PP_TUPLE_ELEM_9_5(a, b, c, d, e, f, g, h, i) f
#define BOOST_PP_TUPLE_ELEM_9_6(a, b, c, d, e, f, g, h, i) g
#define BOOST_PP_TUPLE_ELEM_9_7(a, b, c, d, e, f, g, h, i) h
#define BOOST_PP_TUPLE_ELEM_9_8(a, b, c, d, e, f, g, h, i) i
#define BOOST_PP_TUPLE_ELEM_10_0(a, b, c, d, e, f, g, h, i, j) a
#define BOOST_PP_TUPLE_ELEM_10_1(a, b, c, d, e, f, g, h, i, j) b
#define BOOST_PP_TUPLE_ELEM_10_2(a, b, c, d, e, f, g, h, i, j) c
#define BOOST_PP_TUPLE_ELEM_10_3(a, b, c, d, e, f, g, h, i, j) d
#define BOOST_PP_TUPLE_ELEM_10_4(a, b, c, d, e, f, g, h, i, j) e
#define BOOST_PP_TUPLE_ELEM_10_5(a, b, c, d, e, f, g, h, i, j) f
#define BOOST_PP_TUPLE_ELEM_10_6(a, b, c, d, e, f, g, h, i, j) g
#define BOOST_PP_TUPLE_ELEM_10_7(a, b, c, d, e, f, g, h, i, j) h
#define BOOST_PP_TUPLE_ELEM_10_8(a, b, c, d, e, f, g, h, i, j) i
#define BOOST_PP_TUPLE_ELEM_10_9(a, b, c, d, e, f, g, h, i, j) j
#define BOOST_PP_TUPLE_ELEM_11_0(a, b, c, d, e, f, g, h, i, j, k) a
#define BOOST_PP_TUPLE_ELEM_11_1(a, b, c, d, e, f, g, h, i, j, k) b
#define BOOST_PP_TUPLE_ELEM_11_2(a, b, c, d, e, f, g, h, i, j, k) c
#define BOOST_PP_TUPLE_ELEM_11_3(a, b, c, d, e, f, g, h, i, j, k) d
#define BOOST_PP_TUPLE_ELEM_11_4(a, b, c, d, e, f, g, h, i, j, k) e
#define BOOST_PP_TUPLE_ELEM_11_5(a, b, c, d, e, f, g, h, i, j, k) f
#define BOOST_PP_TUPLE_ELEM_11_6(a, b, c, d, e, f, g, h, i, j, k) g
#define BOOST_PP_TUPLE_ELEM_11_7(a, b, c, d, e, f, g, h, i, j, k) h
#define BOOST_PP_TUPLE_ELEM_11_8(a, b, c, d, e, f, g, h, i, j, k) i
#define BOOST_PP_TUPLE_ELEM_11_9(a, b, c, d, e, f, g, h, i, j, k) j
#define BOOST_PP_TUPLE_ELEM_11_10(a, b, c, d, e, f, g, h, i, j, k) k
#define BOOST_PP_TUPLE_ELEM_12_0(a, b, c, d, e, f, g, h, i, j, k, l) a
#define BOOST_PP_TUPLE_ELEM_12_1(a, b, c, d, e, f, g, h, i, j, k, l) b
#define BOOST_PP_TUPLE_ELEM_12_2(a, b, c, d, e, f, g, h, i, j, k, l) c
#define BOOST_PP_TUPLE_ELEM_12_3(a, b, c, d, e, f, g, h, i, j, k, l) d
#define BOOST_PP_TUPLE_ELEM_12_4(a, b, c, d, e, f, g, h, i, j, k, l) e
#define BOOST_PP_TUPLE_ELEM_12_5(a, b, c, d, e, f, g, h, i, j, k, l) f
#define BOOST_PP_TUPLE_ELEM_12_6(a, b, c, d, e, f, g, h, i, j, k, l) g
#define BOOST_PP_TUPLE_ELEM_12_7(a, b, c, d, e, f, g, h, i, j, k, l) h
#define BOOST_PP_TUPLE_ELEM_12_8(a, b, c, d, e, f, g, h, i, j, k, l) i
#define BOOST_PP_TUPLE_ELEM_12_9(a, b, c, d, e, f, g, h, i, j, k, l) j
#define BOOST_PP_TUPLE_ELEM_12_10(a, b, c, d, e, f, g, h, i, j, k, l) k
#define BOOST_PP_TUPLE_ELEM_12_11(a, b, c, d, e, f, g, h, i, j, k, l) l
#define BOOST_PP_TUPLE_ELEM_13_0(a, b, c, d, e, f, g, h, i, j, k, l, m) a
#define BOOST_PP_TUPLE_ELEM_13_1(a, b, c, d, e, f, g, h, i, j, k, l, m) b
#define BOOST_PP_TUPLE_ELEM_13_2(a, b, c, d, e, f, g, h, i, j, k, l, m) c
#define BOOST_PP_TUPLE_ELEM_13_3(a, b, c, d, e, f, g, h, i, j, k, l, m) d
#define BOOST_PP_TUPLE_ELEM_13_4(a, b, c, d, e, f, g, h, i, j, k, l, m) e
#define BOOST_PP_TUPLE_ELEM_13_5(a, b, c, d, e, f, g, h, i, j, k, l, m) f
#define BOOST_PP_TUPLE_ELEM_13_6(a, b, c, d, e, f, g, h, i, j, k, l, m) g
#define BOOST_PP_TUPLE_ELEM_13_7(a, b, c, d, e, f, g, h, i, j, k, l, m) h
#define BOOST_PP_TUPLE_ELEM_13_8(a, b, c, d, e, f, g, h, i, j, k, l, m) i
#define BOOST_PP_TUPLE_ELEM_13_9(a, b, c, d, e, f, g, h, i, j, k, l, m) j
#define BOOST_PP_TUPLE_ELEM_13_10(a, b, c, d, e, f, g, h, i, j, k, l, m) k
#define BOOST_PP_TUPLE_ELEM_13_11(a, b, c, d, e, f, g, h, i, j, k, l, m) l
#define BOOST_PP_TUPLE_ELEM_13_12(a, b, c, d, e, f, g, h, i, j, k, l, m) m
#define BOOST_PP_TUPLE_ELEM_14_0(a, b, c, d, e, f, g, h, i, j, k, l, m, n) a
#define BOOST_PP_TUPLE_ELEM_14_1(a, b, c, d, e, f, g, h, i, j, k, l, m, n) b
#define BOOST_PP_TUPLE_ELEM_14_2(a, b, c, d, e, f, g, h, i, j, k, l, m, n) c
#define BOOST_PP_TUPLE_ELEM_14_3(a, b, c, d, e, f, g, h, i, j, k, l, m, n) d
#define BOOST_PP_TUPLE_ELEM_14_4(a, b, c, d, e, f, g, h, i, j, k, l, m, n) e
#define BOOST_PP_TUPLE_ELEM_14_5(a, b, c, d, e, f, g, h, i, j, k, l, m, n) f
#define BOOST_PP_TUPLE_ELEM_14_6(a, b, c, d, e, f, g, h, i, j, k, l, m, n) g
#define BOOST_PP_TUPLE_ELEM_14_7(a, b, c, d, e, f, g, h, i, j, k, l, m, n) h
#define BOOST_PP_TUPLE_ELEM_14_8(a, b, c, d, e, f, g, h, i, j, k, l, m, n) i
#define BOOST_PP_TUPLE_ELEM_14_9(a, b, c, d, e, f, g, h, i, j, k, l, m, n) j
#define BOOST_PP_TUPLE_ELEM_14_10(a, b, c, d, e, f, g, h, i, j, k, l, m, n) k
#define BOOST_PP_TUPLE_ELEM_14_11(a, b, c, d, e, f, g, h, i, j, k, l, m, n) l
#define BOOST_PP_TUPLE_ELEM_14_12(a, b, c, d, e, f, g, h, i, j, k, l, m, n) m
#define BOOST_PP_TUPLE_ELEM_14_13(a, b, c, d, e, f, g, h, i, j, k, l, m, n) n
#define BOOST_PP_TUPLE_ELEM_15_0(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o) a
#define BOOST_PP_TUPLE_ELEM_15_1(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o) b
#define BOOST_PP_TUPLE_ELEM_15_2(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o) c
#define BOOST_PP_TUPLE_ELEM_15_3(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o) d
#define BOOST_PP_TUPLE_ELEM_15_4(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o) e
#define BOOST_PP_TUPLE_ELEM_15_5(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o) f
#define BOOST_PP_TUPLE_ELEM_15_6(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o) g
#define BOOST_PP_TUPLE_ELEM_15_7(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o) h
#define BOOST_PP_TUPLE_ELEM_15_8(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o) i
#define BOOST_PP_TUPLE_ELEM_15_9(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o) j
#define BOOST_PP_TUPLE_ELEM_15_10(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o) k
#define BOOST_PP_TUPLE_ELEM_15_11(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o) l
#define BOOST_PP_TUPLE_ELEM_15_12(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o) m
#define BOOST_PP_TUPLE_ELEM_15_13(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o) n
#define BOOST_PP_TUPLE_ELEM_15_14(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o) o
#define BOOST_PP_TUPLE_ELEM_16_0(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p) a
#define BOOST_PP_TUPLE_ELEM_16_1(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p) b
#define BOOST_PP_TUPLE_ELEM_16_2(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p) c
#define BOOST_PP_TUPLE_ELEM_16_3(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p) d
#define BOOST_PP_TUPLE_ELEM_16_4(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p) e
#define BOOST_PP_TUPLE_ELEM_16_5(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p) f
#define BOOST_PP_TUPLE_ELEM_16_6(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p) g
#define BOOST_PP_TUPLE_ELEM_16_7(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p) h
#define BOOST_PP_TUPLE_ELEM_16_8(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p) i
#define BOOST_PP_TUPLE_ELEM_16_9(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p) j
#define BOOST_PP_TUPLE_ELEM_16_10(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p) k
#define BOOST_PP_TUPLE_ELEM_16_11(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p) l
#define BOOST_PP_TUPLE_ELEM_16_12(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p) m
#define BOOST_PP_TUPLE_ELEM_16_13(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p) n
#define BOOST_PP_TUPLE_ELEM_16_14(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p) o
#define BOOST_PP_TUPLE_ELEM_16_15(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p) p
#define BOOST_PP_TUPLE_ELEM_17_0(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q) a
#define BOOST_PP_TUPLE_ELEM_17_1(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q) b
#define BOOST_PP_TUPLE_ELEM_17_2(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q) c
#define BOOST_PP_TUPLE_ELEM_17_3(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q) d
#define BOOST_PP_TUPLE_ELEM_17_4(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q) e
#define BOOST_PP_TUPLE_ELEM_17_5(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q) f
#define BOOST_PP_TUPLE_ELEM_17_6(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q) g
#define BOOST_PP_TUPLE_ELEM_17_7(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q) h
#define BOOST_PP_TUPLE_ELEM_17_8(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q) i
#define BOOST_PP_TUPLE_ELEM_17_9(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q) j
#define BOOST_PP_TUPLE_ELEM_17_10(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q) k
#define BOOST_PP_TUPLE_ELEM_17_11(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q) l
#define BOOST_PP_TUPLE_ELEM_17_12(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q) m
#define BOOST_PP_TUPLE_ELEM_17_13(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q) n
#define BOOST_PP_TUPLE_ELEM_17_14(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q) o
#define BOOST_PP_TUPLE_ELEM_17_15(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q) p
#define BOOST_PP_TUPLE_ELEM_17_16(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q) q
#define BOOST_PP_TUPLE_ELEM_18_0(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r) a
#define BOOST_PP_TUPLE_ELEM_18_1(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r) b
#define BOOST_PP_TUPLE_ELEM_18_2(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r) c
#define BOOST_PP_TUPLE_ELEM_18_3(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r) d
#define BOOST_PP_TUPLE_ELEM_18_4(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r) e
#define BOOST_PP_TUPLE_ELEM_18_5(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r) f
#define BOOST_PP_TUPLE_ELEM_18_6(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r) g
#define BOOST_PP_TUPLE_ELEM_18_7(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r) h
#define BOOST_PP_TUPLE_ELEM_18_8(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r) i
#define BOOST_PP_TUPLE_ELEM_18_9(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r) j
#define BOOST_PP_TUPLE_ELEM_18_10(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r) k
#define BOOST_PP_TUPLE_ELEM_18_11(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r) l
#define BOOST_PP_TUPLE_ELEM_18_12(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r) m
#define BOOST_PP_TUPLE_ELEM_18_13(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r) n
#define BOOST_PP_TUPLE_ELEM_18_14(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r) o
#define BOOST_PP_TUPLE_ELEM_18_15(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r) p
#define BOOST_PP_TUPLE_ELEM_18_16(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r) q
#define BOOST_PP_TUPLE_ELEM_18_17(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r) r
#define BOOST_PP_TUPLE_ELEM_19_0(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s) a
#define BOOST_PP_TUPLE_ELEM_19_1(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s) b
#define BOOST_PP_TUPLE_ELEM_19_2(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s) c
#define BOOST_PP_TUPLE_ELEM_19_3(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s) d
#define BOOST_PP_TUPLE_ELEM_19_4(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s) e
#define BOOST_PP_TUPLE_ELEM_19_5(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s) f
#define BOOST_PP_TUPLE_ELEM_19_6(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s) g
#define BOOST_PP_TUPLE_ELEM_19_7(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s) h
#define BOOST_PP_TUPLE_ELEM_19_8(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s) i
#define BOOST_PP_TUPLE_ELEM_19_9(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s) j
#define BOOST_PP_TUPLE_ELEM_19_10(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s) k
#define BOOST_PP_TUPLE_ELEM_19_11(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s) l
#define BOOST_PP_TUPLE_ELEM_19_12(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s) m
#define BOOST_PP_TUPLE_ELEM_19_13(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s) n
#define BOOST_PP_TUPLE_ELEM_19_14(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s) o
#define BOOST_PP_TUPLE_ELEM_19_15(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s) p
#define BOOST_PP_TUPLE_ELEM_19_16(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s) q
#define BOOST_PP_TUPLE_ELEM_19_17(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s) r
#define BOOST_PP_TUPLE_ELEM_19_18(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s) s
#define BOOST_PP_TUPLE_ELEM_20_0(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t) a
#define BOOST_PP_TUPLE_ELEM_20_1(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t) b
#define BOOST_PP_TUPLE_ELEM_20_2(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t) c
#define BOOST_PP_TUPLE_ELEM_20_3(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t) d
#define BOOST_PP_TUPLE_ELEM_20_4(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t) e
#define BOOST_PP_TUPLE_ELEM_20_5(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t) f
#define BOOST_PP_TUPLE_ELEM_20_6(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t) g
#define BOOST_PP_TUPLE_ELEM_20_7(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t) h
#define BOOST_PP_TUPLE_ELEM_20_8(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t) i
#define BOOST_PP_TUPLE_ELEM_20_9(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t) j
#define BOOST_PP_TUPLE_ELEM_20_10(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t) k
#define BOOST_PP_TUPLE_ELEM_20_11(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t) l
#define BOOST_PP_TUPLE_ELEM_20_12(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t) m
#define BOOST_PP_TUPLE_ELEM_20_13(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t) n
#define BOOST_PP_TUPLE_ELEM_20_14(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t) o
#define BOOST_PP_TUPLE_ELEM_20_15(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t) p
#define BOOST_PP_TUPLE_ELEM_20_16(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t) q
#define BOOST_PP_TUPLE_ELEM_20_17(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t) r
#define BOOST_PP_TUPLE_ELEM_20_18(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t) s
#define BOOST_PP_TUPLE_ELEM_20_19(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t) t
#define BOOST_PP_TUPLE_ELEM_21_0(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u) a
#define BOOST_PP_TUPLE_ELEM_21_1(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u) b
#define BOOST_PP_TUPLE_ELEM_21_2(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u) c
#define BOOST_PP_TUPLE_ELEM_21_3(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u) d
#define BOOST_PP_TUPLE_ELEM_21_4(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u) e
#define BOOST_PP_TUPLE_ELEM_21_5(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u) f
#define BOOST_PP_TUPLE_ELEM_21_6(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u) g
#define BOOST_PP_TUPLE_ELEM_21_7(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u) h
#define BOOST_PP_TUPLE_ELEM_21_8(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u) i
#define BOOST_PP_TUPLE_ELEM_21_9(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u) j
#define BOOST_PP_TUPLE_ELEM_21_10(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u) k
#define BOOST_PP_TUPLE_ELEM_21_11(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u) l
#define BOOST_PP_TUPLE_ELEM_21_12(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u) m
#define BOOST_PP_TUPLE_ELEM_21_13(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u) n
#define BOOST_PP_TUPLE_ELEM_21_14(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u) o
#define BOOST_PP_TUPLE_ELEM_21_15(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u) p
#define BOOST_PP_TUPLE_ELEM_21_16(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u) q
#define BOOST_PP_TUPLE_ELEM_21_17(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u) r
#define BOOST_PP_TUPLE_ELEM_21_18(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u) s
#define BOOST_PP_TUPLE_ELEM_21_19(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u) t
#define BOOST_PP_TUPLE_ELEM_21_20(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u) u
#define BOOST_PP_TUPLE_ELEM_22_0(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v) a
#define BOOST_PP_TUPLE_ELEM_22_1(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v) b
#define BOOST_PP_TUPLE_ELEM_22_2(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v) c
#define BOOST_PP_TUPLE_ELEM_22_3(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v) d
#define BOOST_PP_TUPLE_ELEM_22_4(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v) e
#define BOOST_PP_TUPLE_ELEM_22_5(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v) f
#define BOOST_PP_TUPLE_ELEM_22_6(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v) g
#define BOOST_PP_TUPLE_ELEM_22_7(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v) h
#define BOOST_PP_TUPLE_ELEM_22_8(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v) i
#define BOOST_PP_TUPLE_ELEM_22_9(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v) j
#define BOOST_PP_TUPLE_ELEM_22_10(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v) k
#define BOOST_PP_TUPLE_ELEM_22_11(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v) l
#define BOOST_PP_TUPLE_ELEM_22_12(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v) m
#define BOOST_PP_TUPLE_ELEM_22_13(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v) n
#define BOOST_PP_TUPLE_ELEM_22_14(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v) o
#define BOOST_PP_TUPLE_ELEM_22_15(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v) p
#define BOOST_PP_TUPLE_ELEM_22_16(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v) q
#define BOOST_PP_TUPLE_ELEM_22_17(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v) r
#define BOOST_PP_TUPLE_ELEM_22_18(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v) s
#define BOOST_PP_TUPLE_ELEM_22_19(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v) t
#define BOOST_PP_TUPLE_ELEM_22_20(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v) u
#define BOOST_PP_TUPLE_ELEM_22_21(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v) v
#define BOOST_PP_TUPLE_ELEM_23_0(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w) a
#define BOOST_PP_TUPLE_ELEM_23_1(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w) b
#define BOOST_PP_TUPLE_ELEM_23_2(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w) c
#define BOOST_PP_TUPLE_ELEM_23_3(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w) d
#define BOOST_PP_TUPLE_ELEM_23_4(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w) e
#define BOOST_PP_TUPLE_ELEM_23_5(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w) f
#define BOOST_PP_TUPLE_ELEM_23_6(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w) g
#define BOOST_PP_TUPLE_ELEM_23_7(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w) h
#define BOOST_PP_TUPLE_ELEM_23_8(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w) i
#define BOOST_PP_TUPLE_ELEM_23_9(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w) j
#define BOOST_PP_TUPLE_ELEM_23_10(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w) k
#define BOOST_PP_TUPLE_ELEM_23_11(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w) l
#define BOOST_PP_TUPLE_ELEM_23_12(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w) m
#define BOOST_PP_TUPLE_ELEM_23_13(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w) n
#define BOOST_PP_TUPLE_ELEM_23_14(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w) o
#define BOOST_PP_TUPLE_ELEM_23_15(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w) p
#define BOOST_PP_TUPLE_ELEM_23_16(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w) q
#define BOOST_PP_TUPLE_ELEM_23_17(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w) r
#define BOOST_PP_TUPLE_ELEM_23_18(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w) s
#define BOOST_PP_TUPLE_ELEM_23_19(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w) t
#define BOOST_PP_TUPLE_ELEM_23_20(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w) u
#define BOOST_PP_TUPLE_ELEM_23_21(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w) v
#define BOOST_PP_TUPLE_ELEM_23_22(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w) w
#define BOOST_PP_TUPLE_ELEM_24_0(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x) a
#define BOOST_PP_TUPLE_ELEM_24_1(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x) b
#define BOOST_PP_TUPLE_ELEM_24_2(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x) c
#define BOOST_PP_TUPLE_ELEM_24_3(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x) d
#define BOOST_PP_TUPLE_ELEM_24_4(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x) e
#define BOOST_PP_TUPLE_ELEM_24_5(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x) f
#define BOOST_PP_TUPLE_ELEM_24_6(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x) g
#define BOOST_PP_TUPLE_ELEM_24_7(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x) h
#define BOOST_PP_TUPLE_ELEM_24_8(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x) i
#define BOOST_PP_TUPLE_ELEM_24_9(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x) j
#define BOOST_PP_TUPLE_ELEM_24_10(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x) k
#define BOOST_PP_TUPLE_ELEM_24_11(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x) l
#define BOOST_PP_TUPLE_ELEM_24_12(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x) m
#define BOOST_PP_TUPLE_ELEM_24_13(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x) n
#define BOOST_PP_TUPLE_ELEM_24_14(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x) o
#define BOOST_PP_TUPLE_ELEM_24_15(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x) p
#define BOOST_PP_TUPLE_ELEM_24_16(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x) q
#define BOOST_PP_TUPLE_ELEM_24_17(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x) r
#define BOOST_PP_TUPLE_ELEM_24_18(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x) s
#define BOOST_PP_TUPLE_ELEM_24_19(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x) t
#define BOOST_PP_TUPLE_ELEM_24_20(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x) u
#define BOOST_PP_TUPLE_ELEM_24_21(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x) v
#define BOOST_PP_TUPLE_ELEM_24_22(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x) w
#define BOOST_PP_TUPLE_ELEM_24_23(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x) x
#define BOOST_PP_TUPLE_ELEM_25_0(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y) a
#define BOOST_PP_TUPLE_ELEM_25_1(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y) b
#define BOOST_PP_TUPLE_ELEM_25_2(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y) c
#define BOOST_PP_TUPLE_ELEM_25_3(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y) d
#define BOOST_PP_TUPLE_ELEM_25_4(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y) e
#define BOOST_PP_TUPLE_ELEM_25_5(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y) f
#define BOOST_PP_TUPLE_ELEM_25_6(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y) g
#define BOOST_PP_TUPLE_ELEM_25_7(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y) h
#define BOOST_PP_TUPLE_ELEM_25_8(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y) i
#define BOOST_PP_TUPLE_ELEM_25_9(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y) j
#define BOOST_PP_TUPLE_ELEM_25_10(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y) k
#define BOOST_PP_TUPLE_ELEM_25_11(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y) l
#define BOOST_PP_TUPLE_ELEM_25_12(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y) m
#define BOOST_PP_TUPLE_ELEM_25_13(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y) n
#define BOOST_PP_TUPLE_ELEM_25_14(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y) o
#define BOOST_PP_TUPLE_ELEM_25_15(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y) p
#define BOOST_PP_TUPLE_ELEM_25_16(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y) q
#define BOOST_PP_TUPLE_ELEM_25_17(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y) r
#define BOOST_PP_TUPLE_ELEM_25_18(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y) s
#define BOOST_PP_TUPLE_ELEM_25_19(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y) t
#define BOOST_PP_TUPLE_ELEM_25_20(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y) u
#define BOOST_PP_TUPLE_ELEM_25_21(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y) v
#define BOOST_PP_TUPLE_ELEM_25_22(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y) w
#define BOOST_PP_TUPLE_ELEM_25_23(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y) x
#define BOOST_PP_TUPLE_ELEM_25_24(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y) y

#define BOOST_PP_TUPLE_REM(size) BOOST_PP_TUPLE_REM_I(size)
#define BOOST_PP_TUPLE_REM_I(size) BOOST_PP_TUPLE_REM_ ## size
#define BOOST_PP_TUPLE_REM_CTOR(size, tuple) BOOST_PP_TUPLE_REM_CTOR_I(BOOST_PP_TUPLE_REM(size), tuple)
#define BOOST_PP_TUPLE_REM_CTOR_I(ext, tuple) ext tuple

#define BOOST_PP_TUPLE_REM_0()
#define BOOST_PP_TUPLE_REM_1(a) a
#define BOOST_PP_TUPLE_REM_2(a, b) a, b
#define BOOST_PP_TUPLE_REM_3(a, b, c) a, b, c
#define BOOST_PP_TUPLE_REM_4(a, b, c, d) a, b, c, d
#define BOOST_PP_TUPLE_REM_5(a, b, c, d, e) a, b, c, d, e
#define BOOST_PP_TUPLE_REM_6(a, b, c, d, e, f) a, b, c, d, e, f
#define BOOST_PP_TUPLE_REM_7(a, b, c, d, e, f, g) a, b, c, d, e, f, g
#define BOOST_PP_TUPLE_REM_8(a, b, c, d, e, f, g, h) a, b, c, d, e, f, g, h
#define BOOST_PP_TUPLE_REM_9(a, b, c, d, e, f, g, h, i) a, b, c, d, e, f, g, h, i
#define BOOST_PP_TUPLE_REM_10(a, b, c, d, e, f, g, h, i, j) a, b, c, d, e, f, g, h, i, j
#define BOOST_PP_TUPLE_REM_11(a, b, c, d, e, f, g, h, i, j, k) a, b, c, d, e, f, g, h, i, j, k
#define BOOST_PP_TUPLE_REM_12(a, b, c, d, e, f, g, h, i, j, k, l) a, b, c, d, e, f, g, h, i, j, k, l
#define BOOST_PP_TUPLE_REM_13(a, b, c, d, e, f, g, h, i, j, k, l, m) a, b, c, d, e, f, g, h, i, j, k, l, m
#define BOOST_PP_TUPLE_REM_14(a, b, c, d, e, f, g, h, i, j, k, l, m, n) a, b, c, d, e, f, g, h, i, j, k, l, m, n
#define BOOST_PP_TUPLE_REM_15(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o) a, b, c, d, e, f, g, h, i, j, k, l, m, n, o
#define BOOST_PP_TUPLE_REM_16(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p) a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p
#define BOOST_PP_TUPLE_REM_17(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q) a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q
#define BOOST_PP_TUPLE_REM_18(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r) a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r
#define BOOST_PP_TUPLE_REM_19(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s) a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s
#define BOOST_PP_TUPLE_REM_20(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t) a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t
#define BOOST_PP_TUPLE_REM_21(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u) a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u
#define BOOST_PP_TUPLE_REM_22(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v) a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v
#define BOOST_PP_TUPLE_REM_23(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w) a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w
#define BOOST_PP_TUPLE_REM_24(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x) a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x
#define BOOST_PP_TUPLE_REM_25(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y) a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y

#define BOOST_PP_TUPLE_REVERSE(size, tuple) BOOST_PP_TUPLE_REVERSE_I(size, tuple)
#define BOOST_PP_TUPLE_REVERSE_I(s, t) BOOST_PP_TUPLE_REVERSE_ ## s t
#define BOOST_PP_TUPLE_REVERSE_0() ()
#define BOOST_PP_TUPLE_REVERSE_1(a) (a)
#define BOOST_PP_TUPLE_REVERSE_2(a, b) (b, a)
#define BOOST_PP_TUPLE_REVERSE_3(a, b, c) (c, b, a)
#define BOOST_PP_TUPLE_REVERSE_4(a, b, c, d) (d, c, b, a)
#define BOOST_PP_TUPLE_REVERSE_5(a, b, c, d, e) (e, d, c, b, a)
#define BOOST_PP_TUPLE_REVERSE_6(a, b, c, d, e, f) (f, e, d, c, b, a)
#define BOOST_PP_TUPLE_REVERSE_7(a, b, c, d, e, f, g) (g, f, e, d, c, b, a)
#define BOOST_PP_TUPLE_REVERSE_8(a, b, c, d, e, f, g, h) (h, g, f, e, d, c, b, a)
#define BOOST_PP_TUPLE_REVERSE_9(a, b, c, d, e, f, g, h, i) (i, h, g, f, e, d, c, b, a)
#define BOOST_PP_TUPLE_REVERSE_10(a, b, c, d, e, f, g, h, i, j) (j, i, h, g, f, e, d, c, b, a)
#define BOOST_PP_TUPLE_REVERSE_11(a, b, c, d, e, f, g, h, i, j, k) (k, j, i, h, g, f, e, d, c, b, a)
#define BOOST_PP_TUPLE_REVERSE_12(a, b, c, d, e, f, g, h, i, j, k, l) (l, k, j, i, h, g, f, e, d, c, b, a)
#define BOOST_PP_TUPLE_REVERSE_13(a, b, c, d, e, f, g, h, i, j, k, l, m) (m, l, k, j, i, h, g, f, e, d, c, b, a)
#define BOOST_PP_TUPLE_REVERSE_14(a, b, c, d, e, f, g, h, i, j, k, l, m, n) (n, m, l, k, j, i, h, g, f, e, d, c, b, a)
#define BOOST_PP_TUPLE_REVERSE_15(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o) (o, n, m, l, k, j, i, h, g, f, e, d, c, b, a)
#define BOOST_PP_TUPLE_REVERSE_16(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p) (p, o, n, m, l, k, j, i, h, g, f, e, d, c, b, a)
#define BOOST_PP_TUPLE_REVERSE_17(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q) (q, p, o, n, m, l, k, j, i, h, g, f, e, d, c, b, a)
#define BOOST_PP_TUPLE_REVERSE_18(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r) (r, q, p, o, n, m, l, k, j, i, h, g, f, e, d, c, b, a)
#define BOOST_PP_TUPLE_REVERSE_19(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s) (s, r, q, p, o, n, m, l, k, j, i, h, g, f, e, d, c, b, a)
#define BOOST_PP_TUPLE_REVERSE_20(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t) (t, s, r, q, p, o, n, m, l, k, j, i, h, g, f, e, d, c, b, a)
#define BOOST_PP_TUPLE_REVERSE_21(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u) (u, t, s, r, q, p, o, n, m, l, k, j, i, h, g, f, e, d, c, b, a)
#define BOOST_PP_TUPLE_REVERSE_22(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v) (v, u, t, s, r, q, p, o, n, m, l, k, j, i, h, g, f, e, d, c, b, a)
#define BOOST_PP_TUPLE_REVERSE_23(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w) (w, v, u, t, s, r, q, p, o, n, m, l, k, j, i, h, g, f, e, d, c, b, a)
#define BOOST_PP_TUPLE_REVERSE_24(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x) (x, w, v, u, t, s, r, q, p, o, n, m, l, k, j, i, h, g, f, e, d, c, b, a)
#define BOOST_PP_TUPLE_REVERSE_25(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y) (y, x, w, v, u, t, s, r, q, p, o, n, m, l, k, j, i, h, g, f, e, d, c, b, a)

#define BOOST_PP_TUPLE_TO_LIST(size, tuple) BOOST_PP_TUPLE_TO_LIST_I(size, tuple)
#define BOOST_PP_TUPLE_TO_LIST_I(s, t) BOOST_PP_TUPLE_TO_LIST_ ## s t
#define BOOST_PP_TUPLE_TO_LIST_0() BOOST_PP_NIL
#define BOOST_PP_TUPLE_TO_LIST_1(a) (a, BOOST_PP_NIL)
#define BOOST_PP_TUPLE_TO_LIST_2(a, b) (a, (b, BOOST_PP_NIL))
#define BOOST_PP_TUPLE_TO_LIST_3(a, b, c) (a, (b, (c, BOOST_PP_NIL)))
#define BOOST_PP_TUPLE_TO_LIST_4(a, b, c, d) (a, (b, (c, (d, BOOST_PP_NIL))))
#define BOOST_PP_TUPLE_TO_LIST_5(a, b, c, d, e) (a, (b, (c, (d, (e, BOOST_PP_NIL)))))
#define BOOST_PP_TUPLE_TO_LIST_6(a, b, c, d, e, f) (a, (b, (c, (d, (e, (f, BOOST_PP_NIL))))))
#define BOOST_PP_TUPLE_TO_LIST_7(a, b, c, d, e, f, g) (a, (b, (c, (d, (e, (f, (g, BOOST_PP_NIL)))))))
#define BOOST_PP_TUPLE_TO_LIST_8(a, b, c, d, e, f, g, h) (a, (b, (c, (d, (e, (f, (g, (h, BOOST_PP_NIL))))))))
#define BOOST_PP_TUPLE_TO_LIST_9(a, b, c, d, e, f, g, h, i) (a, (b, (c, (d, (e, (f, (g, (h, (i, BOOST_PP_NIL)))))))))
#define BOOST_PP_TUPLE_TO_LIST_10(a, b, c, d, e, f, g, h, i, j) (a, (b, (c, (d, (e, (f, (g, (h, (i, (j, BOOST_PP_NIL))))))))))
#define BOOST_PP_TUPLE_TO_LIST_11(a, b, c, d, e, f, g, h, i, j, k) (a, (b, (c, (d, (e, (f, (g, (h, (i, (j, (k, BOOST_PP_NIL)))))))))))
#define BOOST_PP_TUPLE_TO_LIST_12(a, b, c, d, e, f, g, h, i, j, k, l) (a, (b, (c, (d, (e, (f, (g, (h, (i, (j, (k, (l, BOOST_PP_NIL))))))))))))
#define BOOST_PP_TUPLE_TO_LIST_13(a, b, c, d, e, f, g, h, i, j, k, l, m) (a, (b, (c, (d, (e, (f, (g, (h, (i, (j, (k, (l, (m, BOOST_PP_NIL)))))))))))))
#define BOOST_PP_TUPLE_TO_LIST_14(a, b, c, d, e, f, g, h, i, j, k, l, m, n) (a, (b, (c, (d, (e, (f, (g, (h, (i, (j, (k, (l, (m, (n, BOOST_PP_NIL))))))))))))))
#define BOOST_PP_TUPLE_TO_LIST_15(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o) (a, (b, (c, (d, (e, (f, (g, (h, (i, (j, (k, (l, (m, (n, (o, BOOST_PP_NIL)))))))))))))))
#define BOOST_PP_TUPLE_TO_LIST_16(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p) (a, (b, (c, (d, (e, (f, (g, (h, (i, (j, (k, (l, (m, (n, (o, (p, BOOST_PP_NIL))))))))))))))))
#define BOOST_PP_TUPLE_TO_LIST_17(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q) (a, (b, (c, (d, (e, (f, (g, (h, (i, (j, (k, (l, (m, (n, (o, (p, (q, BOOST_PP_NIL)))))))))))))))))
#define BOOST_PP_TUPLE_TO_LIST_18(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r) (a, (b, (c, (d, (e, (f, (g, (h, (i, (j, (k, (l, (m, (n, (o, (p, (q, (r, BOOST_PP_NIL))))))))))))))))))
#define BOOST_PP_TUPLE_TO_LIST_19(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s) (a, (b, (c, (d, (e, (f, (g, (h, (i, (j, (k, (l, (m, (n, (o, (p, (q, (r, (s, BOOST_PP_NIL)))))))))))))))))))
#define BOOST_PP_TUPLE_TO_LIST_20(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t) (a, (b, (c, (d, (e, (f, (g, (h, (i, (j, (k, (l, (m, (n, (o, (p, (q, (r, (s, (t, BOOST_PP_NIL))))))))))))))))))))
#define BOOST_PP_TUPLE_TO_LIST_21(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u) (a, (b, (c, (d, (e, (f, (g, (h, (i, (j, (k, (l, (m, (n, (o, (p, (q, (r, (s, (t, (u, BOOST_PP_NIL)))))))))))))))))))))
#define BOOST_PP_TUPLE_TO_LIST_22(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v) (a, (b, (c, (d, (e, (f, (g, (h, (i, (j, (k, (l, (m, (n, (o, (p, (q, (r, (s, (t, (u, (v, BOOST_PP_NIL))))))))))))))))))))))
#define BOOST_PP_TUPLE_TO_LIST_23(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w) (a, (b, (c, (d, (e, (f, (g, (h, (i, (j, (k, (l, (m, (n, (o, (p, (q, (r, (s, (t, (u, (v, (w, BOOST_PP_NIL)))))))))))))))))))))))
#define BOOST_PP_TUPLE_TO_LIST_24(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x) (a, (b, (c, (d, (e, (f, (g, (h, (i, (j, (k, (l, (m, (n, (o, (p, (q, (r, (s, (t, (u, (v, (w, (x, BOOST_PP_NIL))))))))))))))))))))))))
#define BOOST_PP_TUPLE_TO_LIST_25(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y) (a, (b, (c, (d, (e, (f, (g, (h, (i, (j, (k, (l, (m, (n, (o, (p, (q, (r, (s, (t, (u, (v, (w, (x, (y, BOOST_PP_NIL)))))))))))))))))))))))))

#define BOOST_PP_TUPLE_TO_SEQ(size, tuple) BOOST_PP_TUPLE_TO_SEQ_I(size, tuple)
#define BOOST_PP_TUPLE_TO_SEQ_I(s, t) BOOST_PP_TUPLE_TO_SEQ_ ## s t
#define BOOST_PP_TUPLE_TO_SEQ_0()
#define BOOST_PP_TUPLE_TO_SEQ_1(a) (a)
#define BOOST_PP_TUPLE_TO_SEQ_2(a, b) (a)(b)
#define BOOST_PP_TUPLE_TO_SEQ_3(a, b, c) (a)(b)(c)
#define BOOST_PP_TUPLE_TO_SEQ_4(a, b, c, d) (a)(b)(c)(d)
#define BOOST_PP_TUPLE_TO_SEQ_5(a, b, c, d, e) (a)(b)(c)(d)(e)
#define BOOST_PP_TUPLE_TO_SEQ_6(a, b, c, d, e, f) (a)(b)(c)(d)(e)(f)
#define BOOST_PP_TUPLE_TO_SEQ_7(a, b, c, d, e, f, g) (a)(b)(c)(d)(e)(f)(g)
#define BOOST_PP_TUPLE_TO_SEQ_8(a, b, c, d, e, f, g, h) (a)(b)(c)(d)(e)(f)(g)(h)
#define BOOST_PP_TUPLE_TO_SEQ_9(a, b, c, d, e, f, g, h, i) (a)(b)(c)(d)(e)(f)(g)(h)(i)
#define BOOST_PP_TUPLE_TO_SEQ_10(a, b, c, d, e, f, g, h, i, j) (a)(b)(c)(d)(e)(f)(g)(h)(i)(j)
#define BOOST_PP_TUPLE_TO_SEQ_11(a, b, c, d, e, f, g, h, i, j, k) (a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)
#define BOOST_PP_TUPLE_TO_SEQ_12(a, b, c, d, e, f, g, h, i, j, k, l) (a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)
#define BOOST_PP_TUPLE_TO_SEQ_13(a, b, c, d, e, f, g, h, i, j, k, l, m) (a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)(m)
#define BOOST_PP_TUPLE_TO_SEQ_14(a, b, c, d, e, f, g, h, i, j, k, l, m, n) (a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)(m)(n)
#define BOOST_PP_TUPLE_TO_SEQ_15(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o) (a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)(m)(n)(o)
#define BOOST_PP_TUPLE_TO_SEQ_16(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p) (a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)(m)(n)(o)(p)
#define BOOST_PP_TUPLE_TO_SEQ_17(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q) (a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)(m)(n)(o)(p)(q)
#define BOOST_PP_TUPLE_TO_SEQ_18(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r) (a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)(m)(n)(o)(p)(q)(r)
#define BOOST_PP_TUPLE_TO_SEQ_19(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s) (a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)(m)(n)(o)(p)(q)(r)(s)
#define BOOST_PP_TUPLE_TO_SEQ_20(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t) (a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)(m)(n)(o)(p)(q)(r)(s)(t)
#define BOOST_PP_TUPLE_TO_SEQ_21(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u) (a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)(m)(n)(o)(p)(q)(r)(s)(t)(u)
#define BOOST_PP_TUPLE_TO_SEQ_22(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v) (a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)(m)(n)(o)(p)(q)(r)(s)(t)(u)(v)
#define BOOST_PP_TUPLE_TO_SEQ_23(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w) (a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)(m)(n)(o)(p)(q)(r)(s)(t)(u)(v)(w)
#define BOOST_PP_TUPLE_TO_SEQ_24(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x) (a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)(m)(n)(o)(p)(q)(r)(s)(t)(u)(v)(w)(x)
#define BOOST_PP_TUPLE_TO_SEQ_25(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y) (a)(b)(c)(d)(e)(f)(g)(h)(i)(j)(k)(l)(m)(n)(o)(p)(q)(r)(s)(t)(u)(v)(w)(x)(y)

#define BOOST_PP_WHILE BOOST_PP_CAT(BOOST_PP_WHILE_, BOOST_PP_AUTO_REC(BOOST_PP_WHILE_P, 256))
#define BOOST_PP_WHILE_P(n) BOOST_PP_BITAND(BOOST_PP_CAT(BOOST_PP_WHILE_CHECK_, BOOST_PP_WHILE_ ## n(BOOST_PP_WHILE_F, BOOST_PP_NIL, BOOST_PP_NIL)), BOOST_PP_CAT(BOOST_PP_LIST_FOLD_LEFT_CHECK_, BOOST_PP_LIST_FOLD_LEFT_ ## n(BOOST_PP_NIL, BOOST_PP_NIL, BOOST_PP_NIL)))
#define BOOST_PP_WHILE_F(d, _) 0
#define BOOST_PP_WHILE_257(p, o, s) BOOST_PP_ERROR(0x0001)
#define BOOST_PP_WHILE_CHECK_BOOST_PP_NIL 1
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_1(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_2(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_3(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_4(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_5(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_6(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_7(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_8(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_9(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_10(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_11(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_12(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_13(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_14(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_15(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_16(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_17(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_18(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_19(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_20(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_21(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_22(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_23(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_24(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_25(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_26(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_27(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_28(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_29(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_30(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_31(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_32(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_33(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_34(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_35(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_36(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_37(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_38(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_39(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_40(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_41(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_42(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_43(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_44(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_45(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_46(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_47(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_48(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_49(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_50(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_51(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_52(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_53(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_54(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_55(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_56(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_57(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_58(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_59(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_60(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_61(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_62(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_63(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_64(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_65(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_66(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_67(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_68(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_69(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_70(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_71(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_72(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_73(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_74(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_75(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_76(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_77(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_78(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_79(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_80(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_81(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_82(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_83(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_84(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_85(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_86(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_87(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_88(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_89(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_90(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_91(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_92(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_93(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_94(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_95(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_96(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_97(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_98(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_99(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_100(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_101(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_102(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_103(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_104(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_105(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_106(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_107(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_108(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_109(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_110(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_111(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_112(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_113(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_114(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_115(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_116(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_117(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_118(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_119(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_120(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_121(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_122(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_123(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_124(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_125(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_126(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_127(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_128(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_129(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_130(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_131(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_132(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_133(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_134(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_135(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_136(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_137(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_138(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_139(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_140(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_141(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_142(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_143(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_144(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_145(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_146(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_147(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_148(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_149(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_150(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_151(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_152(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_153(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_154(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_155(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_156(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_157(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_158(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_159(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_160(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_161(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_162(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_163(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_164(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_165(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_166(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_167(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_168(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_169(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_170(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_171(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_172(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_173(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_174(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_175(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_176(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_177(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_178(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_179(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_180(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_181(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_182(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_183(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_184(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_185(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_186(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_187(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_188(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_189(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_190(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_191(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_192(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_193(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_194(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_195(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_196(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_197(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_198(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_199(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_200(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_201(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_202(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_203(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_204(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_205(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_206(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_207(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_208(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_209(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_210(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_211(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_212(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_213(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_214(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_215(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_216(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_217(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_218(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_219(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_220(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_221(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_222(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_223(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_224(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_225(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_226(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_227(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_228(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_229(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_230(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_231(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_232(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_233(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_234(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_235(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_236(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_237(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_238(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_239(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_240(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_241(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_242(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_243(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_244(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_245(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_246(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_247(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_248(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_249(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_250(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_251(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_252(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_253(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_254(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_255(p, o, s) 0
#define BOOST_PP_WHILE_CHECK_BOOST_PP_WHILE_256(p, o, s) 0

#define BOOST_PP_WHILE_1(p, o, s) BOOST_PP_WHILE_1_C(BOOST_PP_BOOL(p(2, s)), p, o, s)
#define BOOST_PP_WHILE_2(p, o, s) BOOST_PP_WHILE_2_C(BOOST_PP_BOOL(p(3, s)), p, o, s)
#define BOOST_PP_WHILE_3(p, o, s) BOOST_PP_WHILE_3_C(BOOST_PP_BOOL(p(4, s)), p, o, s)
#define BOOST_PP_WHILE_4(p, o, s) BOOST_PP_WHILE_4_C(BOOST_PP_BOOL(p(5, s)), p, o, s)
#define BOOST_PP_WHILE_5(p, o, s) BOOST_PP_WHILE_5_C(BOOST_PP_BOOL(p(6, s)), p, o, s)
#define BOOST_PP_WHILE_6(p, o, s) BOOST_PP_WHILE_6_C(BOOST_PP_BOOL(p(7, s)), p, o, s)
#define BOOST_PP_WHILE_7(p, o, s) BOOST_PP_WHILE_7_C(BOOST_PP_BOOL(p(8, s)), p, o, s)
#define BOOST_PP_WHILE_8(p, o, s) BOOST_PP_WHILE_8_C(BOOST_PP_BOOL(p(9, s)), p, o, s)
#define BOOST_PP_WHILE_9(p, o, s) BOOST_PP_WHILE_9_C(BOOST_PP_BOOL(p(10, s)), p, o, s)
#define BOOST_PP_WHILE_10(p, o, s) BOOST_PP_WHILE_10_C(BOOST_PP_BOOL(p(11, s)), p, o, s)
#define BOOST_PP_WHILE_11(p, o, s) BOOST_PP_WHILE_11_C(BOOST_PP_BOOL(p(12, s)), p, o, s)
#define BOOST_PP_WHILE_12(p, o, s) BOOST_PP_WHILE_12_C(BOOST_PP_BOOL(p(13, s)), p, o, s)
#define BOOST_PP_WHILE_13(p, o, s) BOOST_PP_WHILE_13_C(BOOST_PP_BOOL(p(14, s)), p, o, s)
#define BOOST_PP_WHILE_14(p, o, s) BOOST_PP_WHILE_14_C(BOOST_PP_BOOL(p(15, s)), p, o, s)
#define BOOST_PP_WHILE_15(p, o, s) BOOST_PP_WHILE_15_C(BOOST_PP_BOOL(p(16, s)), p, o, s)
#define BOOST_PP_WHILE_16(p, o, s) BOOST_PP_WHILE_16_C(BOOST_PP_BOOL(p(17, s)), p, o, s)
#define BOOST_PP_WHILE_17(p, o, s) BOOST_PP_WHILE_17_C(BOOST_PP_BOOL(p(18, s)), p, o, s)
#define BOOST_PP_WHILE_18(p, o, s) BOOST_PP_WHILE_18_C(BOOST_PP_BOOL(p(19, s)), p, o, s)
#define BOOST_PP_WHILE_19(p, o, s) BOOST_PP_WHILE_19_C(BOOST_PP_BOOL(p(20, s)), p, o, s)
#define BOOST_PP_WHILE_20(p, o, s) BOOST_PP_WHILE_20_C(BOOST_PP_BOOL(p(21, s)), p, o, s)
#define BOOST_PP_WHILE_21(p, o, s) BOOST_PP_WHILE_21_C(BOOST_PP_BOOL(p(22, s)), p, o, s)
#define BOOST_PP_WHILE_22(p, o, s) BOOST_PP_WHILE_22_C(BOOST_PP_BOOL(p(23, s)), p, o, s)
#define BOOST_PP_WHILE_23(p, o, s) BOOST_PP_WHILE_23_C(BOOST_PP_BOOL(p(24, s)), p, o, s)
#define BOOST_PP_WHILE_24(p, o, s) BOOST_PP_WHILE_24_C(BOOST_PP_BOOL(p(25, s)), p, o, s)
#define BOOST_PP_WHILE_25(p, o, s) BOOST_PP_WHILE_25_C(BOOST_PP_BOOL(p(26, s)), p, o, s)
#define BOOST_PP_WHILE_26(p, o, s) BOOST_PP_WHILE_26_C(BOOST_PP_BOOL(p(27, s)), p, o, s)
#define BOOST_PP_WHILE_27(p, o, s) BOOST_PP_WHILE_27_C(BOOST_PP_BOOL(p(28, s)), p, o, s)
#define BOOST_PP_WHILE_28(p, o, s) BOOST_PP_WHILE_28_C(BOOST_PP_BOOL(p(29, s)), p, o, s)
#define BOOST_PP_WHILE_29(p, o, s) BOOST_PP_WHILE_29_C(BOOST_PP_BOOL(p(30, s)), p, o, s)
#define BOOST_PP_WHILE_30(p, o, s) BOOST_PP_WHILE_30_C(BOOST_PP_BOOL(p(31, s)), p, o, s)
#define BOOST_PP_WHILE_31(p, o, s) BOOST_PP_WHILE_31_C(BOOST_PP_BOOL(p(32, s)), p, o, s)
#define BOOST_PP_WHILE_32(p, o, s) BOOST_PP_WHILE_32_C(BOOST_PP_BOOL(p(33, s)), p, o, s)
#define BOOST_PP_WHILE_33(p, o, s) BOOST_PP_WHILE_33_C(BOOST_PP_BOOL(p(34, s)), p, o, s)
#define BOOST_PP_WHILE_34(p, o, s) BOOST_PP_WHILE_34_C(BOOST_PP_BOOL(p(35, s)), p, o, s)
#define BOOST_PP_WHILE_35(p, o, s) BOOST_PP_WHILE_35_C(BOOST_PP_BOOL(p(36, s)), p, o, s)
#define BOOST_PP_WHILE_36(p, o, s) BOOST_PP_WHILE_36_C(BOOST_PP_BOOL(p(37, s)), p, o, s)
#define BOOST_PP_WHILE_37(p, o, s) BOOST_PP_WHILE_37_C(BOOST_PP_BOOL(p(38, s)), p, o, s)
#define BOOST_PP_WHILE_38(p, o, s) BOOST_PP_WHILE_38_C(BOOST_PP_BOOL(p(39, s)), p, o, s)
#define BOOST_PP_WHILE_39(p, o, s) BOOST_PP_WHILE_39_C(BOOST_PP_BOOL(p(40, s)), p, o, s)
#define BOOST_PP_WHILE_40(p, o, s) BOOST_PP_WHILE_40_C(BOOST_PP_BOOL(p(41, s)), p, o, s)
#define BOOST_PP_WHILE_41(p, o, s) BOOST_PP_WHILE_41_C(BOOST_PP_BOOL(p(42, s)), p, o, s)
#define BOOST_PP_WHILE_42(p, o, s) BOOST_PP_WHILE_42_C(BOOST_PP_BOOL(p(43, s)), p, o, s)
#define BOOST_PP_WHILE_43(p, o, s) BOOST_PP_WHILE_43_C(BOOST_PP_BOOL(p(44, s)), p, o, s)
#define BOOST_PP_WHILE_44(p, o, s) BOOST_PP_WHILE_44_C(BOOST_PP_BOOL(p(45, s)), p, o, s)
#define BOOST_PP_WHILE_45(p, o, s) BOOST_PP_WHILE_45_C(BOOST_PP_BOOL(p(46, s)), p, o, s)
#define BOOST_PP_WHILE_46(p, o, s) BOOST_PP_WHILE_46_C(BOOST_PP_BOOL(p(47, s)), p, o, s)
#define BOOST_PP_WHILE_47(p, o, s) BOOST_PP_WHILE_47_C(BOOST_PP_BOOL(p(48, s)), p, o, s)
#define BOOST_PP_WHILE_48(p, o, s) BOOST_PP_WHILE_48_C(BOOST_PP_BOOL(p(49, s)), p, o, s)
#define BOOST_PP_WHILE_49(p, o, s) BOOST_PP_WHILE_49_C(BOOST_PP_BOOL(p(50, s)), p, o, s)
#define BOOST_PP_WHILE_50(p, o, s) BOOST_PP_WHILE_50_C(BOOST_PP_BOOL(p(51, s)), p, o, s)
#define BOOST_PP_WHILE_51(p, o, s) BOOST_PP_WHILE_51_C(BOOST_PP_BOOL(p(52, s)), p, o, s)
#define BOOST_PP_WHILE_52(p, o, s) BOOST_PP_WHILE_52_C(BOOST_PP_BOOL(p(53, s)), p, o, s)
#define BOOST_PP_WHILE_53(p, o, s) BOOST_PP_WHILE_53_C(BOOST_PP_BOOL(p(54, s)), p, o, s)
#define BOOST_PP_WHILE_54(p, o, s) BOOST_PP_WHILE_54_C(BOOST_PP_BOOL(p(55, s)), p, o, s)
#define BOOST_PP_WHILE_55(p, o, s) BOOST_PP_WHILE_55_C(BOOST_PP_BOOL(p(56, s)), p, o, s)
#define BOOST_PP_WHILE_56(p, o, s) BOOST_PP_WHILE_56_C(BOOST_PP_BOOL(p(57, s)), p, o, s)
#define BOOST_PP_WHILE_57(p, o, s) BOOST_PP_WHILE_57_C(BOOST_PP_BOOL(p(58, s)), p, o, s)
#define BOOST_PP_WHILE_58(p, o, s) BOOST_PP_WHILE_58_C(BOOST_PP_BOOL(p(59, s)), p, o, s)
#define BOOST_PP_WHILE_59(p, o, s) BOOST_PP_WHILE_59_C(BOOST_PP_BOOL(p(60, s)), p, o, s)
#define BOOST_PP_WHILE_60(p, o, s) BOOST_PP_WHILE_60_C(BOOST_PP_BOOL(p(61, s)), p, o, s)
#define BOOST_PP_WHILE_61(p, o, s) BOOST_PP_WHILE_61_C(BOOST_PP_BOOL(p(62, s)), p, o, s)
#define BOOST_PP_WHILE_62(p, o, s) BOOST_PP_WHILE_62_C(BOOST_PP_BOOL(p(63, s)), p, o, s)
#define BOOST_PP_WHILE_63(p, o, s) BOOST_PP_WHILE_63_C(BOOST_PP_BOOL(p(64, s)), p, o, s)
#define BOOST_PP_WHILE_64(p, o, s) BOOST_PP_WHILE_64_C(BOOST_PP_BOOL(p(65, s)), p, o, s)
#define BOOST_PP_WHILE_65(p, o, s) BOOST_PP_WHILE_65_C(BOOST_PP_BOOL(p(66, s)), p, o, s)
#define BOOST_PP_WHILE_66(p, o, s) BOOST_PP_WHILE_66_C(BOOST_PP_BOOL(p(67, s)), p, o, s)
#define BOOST_PP_WHILE_67(p, o, s) BOOST_PP_WHILE_67_C(BOOST_PP_BOOL(p(68, s)), p, o, s)
#define BOOST_PP_WHILE_68(p, o, s) BOOST_PP_WHILE_68_C(BOOST_PP_BOOL(p(69, s)), p, o, s)
#define BOOST_PP_WHILE_69(p, o, s) BOOST_PP_WHILE_69_C(BOOST_PP_BOOL(p(70, s)), p, o, s)
#define BOOST_PP_WHILE_70(p, o, s) BOOST_PP_WHILE_70_C(BOOST_PP_BOOL(p(71, s)), p, o, s)
#define BOOST_PP_WHILE_71(p, o, s) BOOST_PP_WHILE_71_C(BOOST_PP_BOOL(p(72, s)), p, o, s)
#define BOOST_PP_WHILE_72(p, o, s) BOOST_PP_WHILE_72_C(BOOST_PP_BOOL(p(73, s)), p, o, s)
#define BOOST_PP_WHILE_73(p, o, s) BOOST_PP_WHILE_73_C(BOOST_PP_BOOL(p(74, s)), p, o, s)
#define BOOST_PP_WHILE_74(p, o, s) BOOST_PP_WHILE_74_C(BOOST_PP_BOOL(p(75, s)), p, o, s)
#define BOOST_PP_WHILE_75(p, o, s) BOOST_PP_WHILE_75_C(BOOST_PP_BOOL(p(76, s)), p, o, s)
#define BOOST_PP_WHILE_76(p, o, s) BOOST_PP_WHILE_76_C(BOOST_PP_BOOL(p(77, s)), p, o, s)
#define BOOST_PP_WHILE_77(p, o, s) BOOST_PP_WHILE_77_C(BOOST_PP_BOOL(p(78, s)), p, o, s)
#define BOOST_PP_WHILE_78(p, o, s) BOOST_PP_WHILE_78_C(BOOST_PP_BOOL(p(79, s)), p, o, s)
#define BOOST_PP_WHILE_79(p, o, s) BOOST_PP_WHILE_79_C(BOOST_PP_BOOL(p(80, s)), p, o, s)
#define BOOST_PP_WHILE_80(p, o, s) BOOST_PP_WHILE_80_C(BOOST_PP_BOOL(p(81, s)), p, o, s)
#define BOOST_PP_WHILE_81(p, o, s) BOOST_PP_WHILE_81_C(BOOST_PP_BOOL(p(82, s)), p, o, s)
#define BOOST_PP_WHILE_82(p, o, s) BOOST_PP_WHILE_82_C(BOOST_PP_BOOL(p(83, s)), p, o, s)
#define BOOST_PP_WHILE_83(p, o, s) BOOST_PP_WHILE_83_C(BOOST_PP_BOOL(p(84, s)), p, o, s)
#define BOOST_PP_WHILE_84(p, o, s) BOOST_PP_WHILE_84_C(BOOST_PP_BOOL(p(85, s)), p, o, s)
#define BOOST_PP_WHILE_85(p, o, s) BOOST_PP_WHILE_85_C(BOOST_PP_BOOL(p(86, s)), p, o, s)
#define BOOST_PP_WHILE_86(p, o, s) BOOST_PP_WHILE_86_C(BOOST_PP_BOOL(p(87, s)), p, o, s)
#define BOOST_PP_WHILE_87(p, o, s) BOOST_PP_WHILE_87_C(BOOST_PP_BOOL(p(88, s)), p, o, s)
#define BOOST_PP_WHILE_88(p, o, s) BOOST_PP_WHILE_88_C(BOOST_PP_BOOL(p(89, s)), p, o, s)
#define BOOST_PP_WHILE_89(p, o, s) BOOST_PP_WHILE_89_C(BOOST_PP_BOOL(p(90, s)), p, o, s)
#define BOOST_PP_WHILE_90(p, o, s) BOOST_PP_WHILE_90_C(BOOST_PP_BOOL(p(91, s)), p, o, s)
#define BOOST_PP_WHILE_91(p, o, s) BOOST_PP_WHILE_91_C(BOOST_PP_BOOL(p(92, s)), p, o, s)
#define BOOST_PP_WHILE_92(p, o, s) BOOST_PP_WHILE_92_C(BOOST_PP_BOOL(p(93, s)), p, o, s)
#define BOOST_PP_WHILE_93(p, o, s) BOOST_PP_WHILE_93_C(BOOST_PP_BOOL(p(94, s)), p, o, s)
#define BOOST_PP_WHILE_94(p, o, s) BOOST_PP_WHILE_94_C(BOOST_PP_BOOL(p(95, s)), p, o, s)
#define BOOST_PP_WHILE_95(p, o, s) BOOST_PP_WHILE_95_C(BOOST_PP_BOOL(p(96, s)), p, o, s)
#define BOOST_PP_WHILE_96(p, o, s) BOOST_PP_WHILE_96_C(BOOST_PP_BOOL(p(97, s)), p, o, s)
#define BOOST_PP_WHILE_97(p, o, s) BOOST_PP_WHILE_97_C(BOOST_PP_BOOL(p(98, s)), p, o, s)
#define BOOST_PP_WHILE_98(p, o, s) BOOST_PP_WHILE_98_C(BOOST_PP_BOOL(p(99, s)), p, o, s)
#define BOOST_PP_WHILE_99(p, o, s) BOOST_PP_WHILE_99_C(BOOST_PP_BOOL(p(100, s)), p, o, s)
#define BOOST_PP_WHILE_100(p, o, s) BOOST_PP_WHILE_100_C(BOOST_PP_BOOL(p(101, s)), p, o, s)
#define BOOST_PP_WHILE_101(p, o, s) BOOST_PP_WHILE_101_C(BOOST_PP_BOOL(p(102, s)), p, o, s)
#define BOOST_PP_WHILE_102(p, o, s) BOOST_PP_WHILE_102_C(BOOST_PP_BOOL(p(103, s)), p, o, s)
#define BOOST_PP_WHILE_103(p, o, s) BOOST_PP_WHILE_103_C(BOOST_PP_BOOL(p(104, s)), p, o, s)
#define BOOST_PP_WHILE_104(p, o, s) BOOST_PP_WHILE_104_C(BOOST_PP_BOOL(p(105, s)), p, o, s)
#define BOOST_PP_WHILE_105(p, o, s) BOOST_PP_WHILE_105_C(BOOST_PP_BOOL(p(106, s)), p, o, s)
#define BOOST_PP_WHILE_106(p, o, s) BOOST_PP_WHILE_106_C(BOOST_PP_BOOL(p(107, s)), p, o, s)
#define BOOST_PP_WHILE_107(p, o, s) BOOST_PP_WHILE_107_C(BOOST_PP_BOOL(p(108, s)), p, o, s)
#define BOOST_PP_WHILE_108(p, o, s) BOOST_PP_WHILE_108_C(BOOST_PP_BOOL(p(109, s)), p, o, s)
#define BOOST_PP_WHILE_109(p, o, s) BOOST_PP_WHILE_109_C(BOOST_PP_BOOL(p(110, s)), p, o, s)
#define BOOST_PP_WHILE_110(p, o, s) BOOST_PP_WHILE_110_C(BOOST_PP_BOOL(p(111, s)), p, o, s)
#define BOOST_PP_WHILE_111(p, o, s) BOOST_PP_WHILE_111_C(BOOST_PP_BOOL(p(112, s)), p, o, s)
#define BOOST_PP_WHILE_112(p, o, s) BOOST_PP_WHILE_112_C(BOOST_PP_BOOL(p(113, s)), p, o, s)
#define BOOST_PP_WHILE_113(p, o, s) BOOST_PP_WHILE_113_C(BOOST_PP_BOOL(p(114, s)), p, o, s)
#define BOOST_PP_WHILE_114(p, o, s) BOOST_PP_WHILE_114_C(BOOST_PP_BOOL(p(115, s)), p, o, s)
#define BOOST_PP_WHILE_115(p, o, s) BOOST_PP_WHILE_115_C(BOOST_PP_BOOL(p(116, s)), p, o, s)
#define BOOST_PP_WHILE_116(p, o, s) BOOST_PP_WHILE_116_C(BOOST_PP_BOOL(p(117, s)), p, o, s)
#define BOOST_PP_WHILE_117(p, o, s) BOOST_PP_WHILE_117_C(BOOST_PP_BOOL(p(118, s)), p, o, s)
#define BOOST_PP_WHILE_118(p, o, s) BOOST_PP_WHILE_118_C(BOOST_PP_BOOL(p(119, s)), p, o, s)
#define BOOST_PP_WHILE_119(p, o, s) BOOST_PP_WHILE_119_C(BOOST_PP_BOOL(p(120, s)), p, o, s)
#define BOOST_PP_WHILE_120(p, o, s) BOOST_PP_WHILE_120_C(BOOST_PP_BOOL(p(121, s)), p, o, s)
#define BOOST_PP_WHILE_121(p, o, s) BOOST_PP_WHILE_121_C(BOOST_PP_BOOL(p(122, s)), p, o, s)
#define BOOST_PP_WHILE_122(p, o, s) BOOST_PP_WHILE_122_C(BOOST_PP_BOOL(p(123, s)), p, o, s)
#define BOOST_PP_WHILE_123(p, o, s) BOOST_PP_WHILE_123_C(BOOST_PP_BOOL(p(124, s)), p, o, s)
#define BOOST_PP_WHILE_124(p, o, s) BOOST_PP_WHILE_124_C(BOOST_PP_BOOL(p(125, s)), p, o, s)
#define BOOST_PP_WHILE_125(p, o, s) BOOST_PP_WHILE_125_C(BOOST_PP_BOOL(p(126, s)), p, o, s)
#define BOOST_PP_WHILE_126(p, o, s) BOOST_PP_WHILE_126_C(BOOST_PP_BOOL(p(127, s)), p, o, s)
#define BOOST_PP_WHILE_127(p, o, s) BOOST_PP_WHILE_127_C(BOOST_PP_BOOL(p(128, s)), p, o, s)
#define BOOST_PP_WHILE_128(p, o, s) BOOST_PP_WHILE_128_C(BOOST_PP_BOOL(p(129, s)), p, o, s)
#define BOOST_PP_WHILE_129(p, o, s) BOOST_PP_WHILE_129_C(BOOST_PP_BOOL(p(130, s)), p, o, s)
#define BOOST_PP_WHILE_130(p, o, s) BOOST_PP_WHILE_130_C(BOOST_PP_BOOL(p(131, s)), p, o, s)
#define BOOST_PP_WHILE_131(p, o, s) BOOST_PP_WHILE_131_C(BOOST_PP_BOOL(p(132, s)), p, o, s)
#define BOOST_PP_WHILE_132(p, o, s) BOOST_PP_WHILE_132_C(BOOST_PP_BOOL(p(133, s)), p, o, s)
#define BOOST_PP_WHILE_133(p, o, s) BOOST_PP_WHILE_133_C(BOOST_PP_BOOL(p(134, s)), p, o, s)
#define BOOST_PP_WHILE_134(p, o, s) BOOST_PP_WHILE_134_C(BOOST_PP_BOOL(p(135, s)), p, o, s)
#define BOOST_PP_WHILE_135(p, o, s) BOOST_PP_WHILE_135_C(BOOST_PP_BOOL(p(136, s)), p, o, s)
#define BOOST_PP_WHILE_136(p, o, s) BOOST_PP_WHILE_136_C(BOOST_PP_BOOL(p(137, s)), p, o, s)
#define BOOST_PP_WHILE_137(p, o, s) BOOST_PP_WHILE_137_C(BOOST_PP_BOOL(p(138, s)), p, o, s)
#define BOOST_PP_WHILE_138(p, o, s) BOOST_PP_WHILE_138_C(BOOST_PP_BOOL(p(139, s)), p, o, s)
#define BOOST_PP_WHILE_139(p, o, s) BOOST_PP_WHILE_139_C(BOOST_PP_BOOL(p(140, s)), p, o, s)
#define BOOST_PP_WHILE_140(p, o, s) BOOST_PP_WHILE_140_C(BOOST_PP_BOOL(p(141, s)), p, o, s)
#define BOOST_PP_WHILE_141(p, o, s) BOOST_PP_WHILE_141_C(BOOST_PP_BOOL(p(142, s)), p, o, s)
#define BOOST_PP_WHILE_142(p, o, s) BOOST_PP_WHILE_142_C(BOOST_PP_BOOL(p(143, s)), p, o, s)
#define BOOST_PP_WHILE_143(p, o, s) BOOST_PP_WHILE_143_C(BOOST_PP_BOOL(p(144, s)), p, o, s)
#define BOOST_PP_WHILE_144(p, o, s) BOOST_PP_WHILE_144_C(BOOST_PP_BOOL(p(145, s)), p, o, s)
#define BOOST_PP_WHILE_145(p, o, s) BOOST_PP_WHILE_145_C(BOOST_PP_BOOL(p(146, s)), p, o, s)
#define BOOST_PP_WHILE_146(p, o, s) BOOST_PP_WHILE_146_C(BOOST_PP_BOOL(p(147, s)), p, o, s)
#define BOOST_PP_WHILE_147(p, o, s) BOOST_PP_WHILE_147_C(BOOST_PP_BOOL(p(148, s)), p, o, s)
#define BOOST_PP_WHILE_148(p, o, s) BOOST_PP_WHILE_148_C(BOOST_PP_BOOL(p(149, s)), p, o, s)
#define BOOST_PP_WHILE_149(p, o, s) BOOST_PP_WHILE_149_C(BOOST_PP_BOOL(p(150, s)), p, o, s)
#define BOOST_PP_WHILE_150(p, o, s) BOOST_PP_WHILE_150_C(BOOST_PP_BOOL(p(151, s)), p, o, s)
#define BOOST_PP_WHILE_151(p, o, s) BOOST_PP_WHILE_151_C(BOOST_PP_BOOL(p(152, s)), p, o, s)
#define BOOST_PP_WHILE_152(p, o, s) BOOST_PP_WHILE_152_C(BOOST_PP_BOOL(p(153, s)), p, o, s)
#define BOOST_PP_WHILE_153(p, o, s) BOOST_PP_WHILE_153_C(BOOST_PP_BOOL(p(154, s)), p, o, s)
#define BOOST_PP_WHILE_154(p, o, s) BOOST_PP_WHILE_154_C(BOOST_PP_BOOL(p(155, s)), p, o, s)
#define BOOST_PP_WHILE_155(p, o, s) BOOST_PP_WHILE_155_C(BOOST_PP_BOOL(p(156, s)), p, o, s)
#define BOOST_PP_WHILE_156(p, o, s) BOOST_PP_WHILE_156_C(BOOST_PP_BOOL(p(157, s)), p, o, s)
#define BOOST_PP_WHILE_157(p, o, s) BOOST_PP_WHILE_157_C(BOOST_PP_BOOL(p(158, s)), p, o, s)
#define BOOST_PP_WHILE_158(p, o, s) BOOST_PP_WHILE_158_C(BOOST_PP_BOOL(p(159, s)), p, o, s)
#define BOOST_PP_WHILE_159(p, o, s) BOOST_PP_WHILE_159_C(BOOST_PP_BOOL(p(160, s)), p, o, s)
#define BOOST_PP_WHILE_160(p, o, s) BOOST_PP_WHILE_160_C(BOOST_PP_BOOL(p(161, s)), p, o, s)
#define BOOST_PP_WHILE_161(p, o, s) BOOST_PP_WHILE_161_C(BOOST_PP_BOOL(p(162, s)), p, o, s)
#define BOOST_PP_WHILE_162(p, o, s) BOOST_PP_WHILE_162_C(BOOST_PP_BOOL(p(163, s)), p, o, s)
#define BOOST_PP_WHILE_163(p, o, s) BOOST_PP_WHILE_163_C(BOOST_PP_BOOL(p(164, s)), p, o, s)
#define BOOST_PP_WHILE_164(p, o, s) BOOST_PP_WHILE_164_C(BOOST_PP_BOOL(p(165, s)), p, o, s)
#define BOOST_PP_WHILE_165(p, o, s) BOOST_PP_WHILE_165_C(BOOST_PP_BOOL(p(166, s)), p, o, s)
#define BOOST_PP_WHILE_166(p, o, s) BOOST_PP_WHILE_166_C(BOOST_PP_BOOL(p(167, s)), p, o, s)
#define BOOST_PP_WHILE_167(p, o, s) BOOST_PP_WHILE_167_C(BOOST_PP_BOOL(p(168, s)), p, o, s)
#define BOOST_PP_WHILE_168(p, o, s) BOOST_PP_WHILE_168_C(BOOST_PP_BOOL(p(169, s)), p, o, s)
#define BOOST_PP_WHILE_169(p, o, s) BOOST_PP_WHILE_169_C(BOOST_PP_BOOL(p(170, s)), p, o, s)
#define BOOST_PP_WHILE_170(p, o, s) BOOST_PP_WHILE_170_C(BOOST_PP_BOOL(p(171, s)), p, o, s)
#define BOOST_PP_WHILE_171(p, o, s) BOOST_PP_WHILE_171_C(BOOST_PP_BOOL(p(172, s)), p, o, s)
#define BOOST_PP_WHILE_172(p, o, s) BOOST_PP_WHILE_172_C(BOOST_PP_BOOL(p(173, s)), p, o, s)
#define BOOST_PP_WHILE_173(p, o, s) BOOST_PP_WHILE_173_C(BOOST_PP_BOOL(p(174, s)), p, o, s)
#define BOOST_PP_WHILE_174(p, o, s) BOOST_PP_WHILE_174_C(BOOST_PP_BOOL(p(175, s)), p, o, s)
#define BOOST_PP_WHILE_175(p, o, s) BOOST_PP_WHILE_175_C(BOOST_PP_BOOL(p(176, s)), p, o, s)
#define BOOST_PP_WHILE_176(p, o, s) BOOST_PP_WHILE_176_C(BOOST_PP_BOOL(p(177, s)), p, o, s)
#define BOOST_PP_WHILE_177(p, o, s) BOOST_PP_WHILE_177_C(BOOST_PP_BOOL(p(178, s)), p, o, s)
#define BOOST_PP_WHILE_178(p, o, s) BOOST_PP_WHILE_178_C(BOOST_PP_BOOL(p(179, s)), p, o, s)
#define BOOST_PP_WHILE_179(p, o, s) BOOST_PP_WHILE_179_C(BOOST_PP_BOOL(p(180, s)), p, o, s)
#define BOOST_PP_WHILE_180(p, o, s) BOOST_PP_WHILE_180_C(BOOST_PP_BOOL(p(181, s)), p, o, s)
#define BOOST_PP_WHILE_181(p, o, s) BOOST_PP_WHILE_181_C(BOOST_PP_BOOL(p(182, s)), p, o, s)
#define BOOST_PP_WHILE_182(p, o, s) BOOST_PP_WHILE_182_C(BOOST_PP_BOOL(p(183, s)), p, o, s)
#define BOOST_PP_WHILE_183(p, o, s) BOOST_PP_WHILE_183_C(BOOST_PP_BOOL(p(184, s)), p, o, s)
#define BOOST_PP_WHILE_184(p, o, s) BOOST_PP_WHILE_184_C(BOOST_PP_BOOL(p(185, s)), p, o, s)
#define BOOST_PP_WHILE_185(p, o, s) BOOST_PP_WHILE_185_C(BOOST_PP_BOOL(p(186, s)), p, o, s)
#define BOOST_PP_WHILE_186(p, o, s) BOOST_PP_WHILE_186_C(BOOST_PP_BOOL(p(187, s)), p, o, s)
#define BOOST_PP_WHILE_187(p, o, s) BOOST_PP_WHILE_187_C(BOOST_PP_BOOL(p(188, s)), p, o, s)
#define BOOST_PP_WHILE_188(p, o, s) BOOST_PP_WHILE_188_C(BOOST_PP_BOOL(p(189, s)), p, o, s)
#define BOOST_PP_WHILE_189(p, o, s) BOOST_PP_WHILE_189_C(BOOST_PP_BOOL(p(190, s)), p, o, s)
#define BOOST_PP_WHILE_190(p, o, s) BOOST_PP_WHILE_190_C(BOOST_PP_BOOL(p(191, s)), p, o, s)
#define BOOST_PP_WHILE_191(p, o, s) BOOST_PP_WHILE_191_C(BOOST_PP_BOOL(p(192, s)), p, o, s)
#define BOOST_PP_WHILE_192(p, o, s) BOOST_PP_WHILE_192_C(BOOST_PP_BOOL(p(193, s)), p, o, s)
#define BOOST_PP_WHILE_193(p, o, s) BOOST_PP_WHILE_193_C(BOOST_PP_BOOL(p(194, s)), p, o, s)
#define BOOST_PP_WHILE_194(p, o, s) BOOST_PP_WHILE_194_C(BOOST_PP_BOOL(p(195, s)), p, o, s)
#define BOOST_PP_WHILE_195(p, o, s) BOOST_PP_WHILE_195_C(BOOST_PP_BOOL(p(196, s)), p, o, s)
#define BOOST_PP_WHILE_196(p, o, s) BOOST_PP_WHILE_196_C(BOOST_PP_BOOL(p(197, s)), p, o, s)
#define BOOST_PP_WHILE_197(p, o, s) BOOST_PP_WHILE_197_C(BOOST_PP_BOOL(p(198, s)), p, o, s)
#define BOOST_PP_WHILE_198(p, o, s) BOOST_PP_WHILE_198_C(BOOST_PP_BOOL(p(199, s)), p, o, s)
#define BOOST_PP_WHILE_199(p, o, s) BOOST_PP_WHILE_199_C(BOOST_PP_BOOL(p(200, s)), p, o, s)
#define BOOST_PP_WHILE_200(p, o, s) BOOST_PP_WHILE_200_C(BOOST_PP_BOOL(p(201, s)), p, o, s)
#define BOOST_PP_WHILE_201(p, o, s) BOOST_PP_WHILE_201_C(BOOST_PP_BOOL(p(202, s)), p, o, s)
#define BOOST_PP_WHILE_202(p, o, s) BOOST_PP_WHILE_202_C(BOOST_PP_BOOL(p(203, s)), p, o, s)
#define BOOST_PP_WHILE_203(p, o, s) BOOST_PP_WHILE_203_C(BOOST_PP_BOOL(p(204, s)), p, o, s)
#define BOOST_PP_WHILE_204(p, o, s) BOOST_PP_WHILE_204_C(BOOST_PP_BOOL(p(205, s)), p, o, s)
#define BOOST_PP_WHILE_205(p, o, s) BOOST_PP_WHILE_205_C(BOOST_PP_BOOL(p(206, s)), p, o, s)
#define BOOST_PP_WHILE_206(p, o, s) BOOST_PP_WHILE_206_C(BOOST_PP_BOOL(p(207, s)), p, o, s)
#define BOOST_PP_WHILE_207(p, o, s) BOOST_PP_WHILE_207_C(BOOST_PP_BOOL(p(208, s)), p, o, s)
#define BOOST_PP_WHILE_208(p, o, s) BOOST_PP_WHILE_208_C(BOOST_PP_BOOL(p(209, s)), p, o, s)
#define BOOST_PP_WHILE_209(p, o, s) BOOST_PP_WHILE_209_C(BOOST_PP_BOOL(p(210, s)), p, o, s)
#define BOOST_PP_WHILE_210(p, o, s) BOOST_PP_WHILE_210_C(BOOST_PP_BOOL(p(211, s)), p, o, s)
#define BOOST_PP_WHILE_211(p, o, s) BOOST_PP_WHILE_211_C(BOOST_PP_BOOL(p(212, s)), p, o, s)
#define BOOST_PP_WHILE_212(p, o, s) BOOST_PP_WHILE_212_C(BOOST_PP_BOOL(p(213, s)), p, o, s)
#define BOOST_PP_WHILE_213(p, o, s) BOOST_PP_WHILE_213_C(BOOST_PP_BOOL(p(214, s)), p, o, s)
#define BOOST_PP_WHILE_214(p, o, s) BOOST_PP_WHILE_214_C(BOOST_PP_BOOL(p(215, s)), p, o, s)
#define BOOST_PP_WHILE_215(p, o, s) BOOST_PP_WHILE_215_C(BOOST_PP_BOOL(p(216, s)), p, o, s)
#define BOOST_PP_WHILE_216(p, o, s) BOOST_PP_WHILE_216_C(BOOST_PP_BOOL(p(217, s)), p, o, s)
#define BOOST_PP_WHILE_217(p, o, s) BOOST_PP_WHILE_217_C(BOOST_PP_BOOL(p(218, s)), p, o, s)
#define BOOST_PP_WHILE_218(p, o, s) BOOST_PP_WHILE_218_C(BOOST_PP_BOOL(p(219, s)), p, o, s)
#define BOOST_PP_WHILE_219(p, o, s) BOOST_PP_WHILE_219_C(BOOST_PP_BOOL(p(220, s)), p, o, s)
#define BOOST_PP_WHILE_220(p, o, s) BOOST_PP_WHILE_220_C(BOOST_PP_BOOL(p(221, s)), p, o, s)
#define BOOST_PP_WHILE_221(p, o, s) BOOST_PP_WHILE_221_C(BOOST_PP_BOOL(p(222, s)), p, o, s)
#define BOOST_PP_WHILE_222(p, o, s) BOOST_PP_WHILE_222_C(BOOST_PP_BOOL(p(223, s)), p, o, s)
#define BOOST_PP_WHILE_223(p, o, s) BOOST_PP_WHILE_223_C(BOOST_PP_BOOL(p(224, s)), p, o, s)
#define BOOST_PP_WHILE_224(p, o, s) BOOST_PP_WHILE_224_C(BOOST_PP_BOOL(p(225, s)), p, o, s)
#define BOOST_PP_WHILE_225(p, o, s) BOOST_PP_WHILE_225_C(BOOST_PP_BOOL(p(226, s)), p, o, s)
#define BOOST_PP_WHILE_226(p, o, s) BOOST_PP_WHILE_226_C(BOOST_PP_BOOL(p(227, s)), p, o, s)
#define BOOST_PP_WHILE_227(p, o, s) BOOST_PP_WHILE_227_C(BOOST_PP_BOOL(p(228, s)), p, o, s)
#define BOOST_PP_WHILE_228(p, o, s) BOOST_PP_WHILE_228_C(BOOST_PP_BOOL(p(229, s)), p, o, s)
#define BOOST_PP_WHILE_229(p, o, s) BOOST_PP_WHILE_229_C(BOOST_PP_BOOL(p(230, s)), p, o, s)
#define BOOST_PP_WHILE_230(p, o, s) BOOST_PP_WHILE_230_C(BOOST_PP_BOOL(p(231, s)), p, o, s)
#define BOOST_PP_WHILE_231(p, o, s) BOOST_PP_WHILE_231_C(BOOST_PP_BOOL(p(232, s)), p, o, s)
#define BOOST_PP_WHILE_232(p, o, s) BOOST_PP_WHILE_232_C(BOOST_PP_BOOL(p(233, s)), p, o, s)
#define BOOST_PP_WHILE_233(p, o, s) BOOST_PP_WHILE_233_C(BOOST_PP_BOOL(p(234, s)), p, o, s)
#define BOOST_PP_WHILE_234(p, o, s) BOOST_PP_WHILE_234_C(BOOST_PP_BOOL(p(235, s)), p, o, s)
#define BOOST_PP_WHILE_235(p, o, s) BOOST_PP_WHILE_235_C(BOOST_PP_BOOL(p(236, s)), p, o, s)
#define BOOST_PP_WHILE_236(p, o, s) BOOST_PP_WHILE_236_C(BOOST_PP_BOOL(p(237, s)), p, o, s)
#define BOOST_PP_WHILE_237(p, o, s) BOOST_PP_WHILE_237_C(BOOST_PP_BOOL(p(238, s)), p, o, s)
#define BOOST_PP_WHILE_238(p, o, s) BOOST_PP_WHILE_238_C(BOOST_PP_BOOL(p(239, s)), p, o, s)
#define BOOST_PP_WHILE_239(p, o, s) BOOST_PP_WHILE_239_C(BOOST_PP_BOOL(p(240, s)), p, o, s)
#define BOOST_PP_WHILE_240(p, o, s) BOOST_PP_WHILE_240_C(BOOST_PP_BOOL(p(241, s)), p, o, s)
#define BOOST_PP_WHILE_241(p, o, s) BOOST_PP_WHILE_241_C(BOOST_PP_BOOL(p(242, s)), p, o, s)
#define BOOST_PP_WHILE_242(p, o, s) BOOST_PP_WHILE_242_C(BOOST_PP_BOOL(p(243, s)), p, o, s)
#define BOOST_PP_WHILE_243(p, o, s) BOOST_PP_WHILE_243_C(BOOST_PP_BOOL(p(244, s)), p, o, s)
#define BOOST_PP_WHILE_244(p, o, s) BOOST_PP_WHILE_244_C(BOOST_PP_BOOL(p(245, s)), p, o, s)
#define BOOST_PP_WHILE_245(p, o, s) BOOST_PP_WHILE_245_C(BOOST_PP_BOOL(p(246, s)), p, o, s)
#define BOOST_PP_WHILE_246(p, o, s) BOOST_PP_WHILE_246_C(BOOST_PP_BOOL(p(247, s)), p, o, s)
#define BOOST_PP_WHILE_247(p, o, s) BOOST_PP_WHILE_247_C(BOOST_PP_BOOL(p(248, s)), p, o, s)
#define BOOST_PP_WHILE_248(p, o, s) BOOST_PP_WHILE_248_C(BOOST_PP_BOOL(p(249, s)), p, o, s)
#define BOOST_PP_WHILE_249(p, o, s) BOOST_PP_WHILE_249_C(BOOST_PP_BOOL(p(250, s)), p, o, s)
#define BOOST_PP_WHILE_250(p, o, s) BOOST_PP_WHILE_250_C(BOOST_PP_BOOL(p(251, s)), p, o, s)
#define BOOST_PP_WHILE_251(p, o, s) BOOST_PP_WHILE_251_C(BOOST_PP_BOOL(p(252, s)), p, o, s)
#define BOOST_PP_WHILE_252(p, o, s) BOOST_PP_WHILE_252_C(BOOST_PP_BOOL(p(253, s)), p, o, s)
#define BOOST_PP_WHILE_253(p, o, s) BOOST_PP_WHILE_253_C(BOOST_PP_BOOL(p(254, s)), p, o, s)
#define BOOST_PP_WHILE_254(p, o, s) BOOST_PP_WHILE_254_C(BOOST_PP_BOOL(p(255, s)), p, o, s)
#define BOOST_PP_WHILE_255(p, o, s) BOOST_PP_WHILE_255_C(BOOST_PP_BOOL(p(256, s)), p, o, s)
#define BOOST_PP_WHILE_256(p, o, s) BOOST_PP_WHILE_256_C(BOOST_PP_BOOL(p(257, s)), p, o, s)

#define BOOST_PP_WHILE_1_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_2, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(2, s))
#define BOOST_PP_WHILE_2_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_3, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(3, s))
#define BOOST_PP_WHILE_3_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_4, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(4, s))
#define BOOST_PP_WHILE_4_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_5, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(5, s))
#define BOOST_PP_WHILE_5_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_6, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(6, s))
#define BOOST_PP_WHILE_6_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_7, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(7, s))
#define BOOST_PP_WHILE_7_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_8, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(8, s))
#define BOOST_PP_WHILE_8_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_9, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(9, s))
#define BOOST_PP_WHILE_9_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_10, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(10, s))
#define BOOST_PP_WHILE_10_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_11, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(11, s))
#define BOOST_PP_WHILE_11_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_12, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(12, s))
#define BOOST_PP_WHILE_12_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_13, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(13, s))
#define BOOST_PP_WHILE_13_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_14, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(14, s))
#define BOOST_PP_WHILE_14_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_15, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(15, s))
#define BOOST_PP_WHILE_15_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_16, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(16, s))
#define BOOST_PP_WHILE_16_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_17, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(17, s))
#define BOOST_PP_WHILE_17_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_18, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(18, s))
#define BOOST_PP_WHILE_18_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_19, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(19, s))
#define BOOST_PP_WHILE_19_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_20, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(20, s))
#define BOOST_PP_WHILE_20_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_21, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(21, s))
#define BOOST_PP_WHILE_21_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_22, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(22, s))
#define BOOST_PP_WHILE_22_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_23, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(23, s))
#define BOOST_PP_WHILE_23_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_24, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(24, s))
#define BOOST_PP_WHILE_24_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_25, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(25, s))
#define BOOST_PP_WHILE_25_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_26, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(26, s))
#define BOOST_PP_WHILE_26_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_27, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(27, s))
#define BOOST_PP_WHILE_27_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_28, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(28, s))
#define BOOST_PP_WHILE_28_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_29, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(29, s))
#define BOOST_PP_WHILE_29_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_30, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(30, s))
#define BOOST_PP_WHILE_30_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_31, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(31, s))
#define BOOST_PP_WHILE_31_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_32, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(32, s))
#define BOOST_PP_WHILE_32_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_33, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(33, s))
#define BOOST_PP_WHILE_33_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_34, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(34, s))
#define BOOST_PP_WHILE_34_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_35, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(35, s))
#define BOOST_PP_WHILE_35_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_36, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(36, s))
#define BOOST_PP_WHILE_36_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_37, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(37, s))
#define BOOST_PP_WHILE_37_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_38, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(38, s))
#define BOOST_PP_WHILE_38_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_39, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(39, s))
#define BOOST_PP_WHILE_39_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_40, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(40, s))
#define BOOST_PP_WHILE_40_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_41, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(41, s))
#define BOOST_PP_WHILE_41_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_42, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(42, s))
#define BOOST_PP_WHILE_42_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_43, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(43, s))
#define BOOST_PP_WHILE_43_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_44, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(44, s))
#define BOOST_PP_WHILE_44_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_45, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(45, s))
#define BOOST_PP_WHILE_45_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_46, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(46, s))
#define BOOST_PP_WHILE_46_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_47, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(47, s))
#define BOOST_PP_WHILE_47_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_48, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(48, s))
#define BOOST_PP_WHILE_48_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_49, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(49, s))
#define BOOST_PP_WHILE_49_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_50, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(50, s))
#define BOOST_PP_WHILE_50_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_51, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(51, s))
#define BOOST_PP_WHILE_51_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_52, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(52, s))
#define BOOST_PP_WHILE_52_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_53, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(53, s))
#define BOOST_PP_WHILE_53_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_54, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(54, s))
#define BOOST_PP_WHILE_54_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_55, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(55, s))
#define BOOST_PP_WHILE_55_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_56, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(56, s))
#define BOOST_PP_WHILE_56_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_57, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(57, s))
#define BOOST_PP_WHILE_57_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_58, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(58, s))
#define BOOST_PP_WHILE_58_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_59, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(59, s))
#define BOOST_PP_WHILE_59_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_60, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(60, s))
#define BOOST_PP_WHILE_60_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_61, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(61, s))
#define BOOST_PP_WHILE_61_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_62, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(62, s))
#define BOOST_PP_WHILE_62_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_63, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(63, s))
#define BOOST_PP_WHILE_63_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_64, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(64, s))
#define BOOST_PP_WHILE_64_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_65, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(65, s))
#define BOOST_PP_WHILE_65_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_66, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(66, s))
#define BOOST_PP_WHILE_66_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_67, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(67, s))
#define BOOST_PP_WHILE_67_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_68, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(68, s))
#define BOOST_PP_WHILE_68_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_69, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(69, s))
#define BOOST_PP_WHILE_69_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_70, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(70, s))
#define BOOST_PP_WHILE_70_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_71, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(71, s))
#define BOOST_PP_WHILE_71_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_72, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(72, s))
#define BOOST_PP_WHILE_72_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_73, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(73, s))
#define BOOST_PP_WHILE_73_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_74, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(74, s))
#define BOOST_PP_WHILE_74_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_75, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(75, s))
#define BOOST_PP_WHILE_75_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_76, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(76, s))
#define BOOST_PP_WHILE_76_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_77, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(77, s))
#define BOOST_PP_WHILE_77_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_78, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(78, s))
#define BOOST_PP_WHILE_78_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_79, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(79, s))
#define BOOST_PP_WHILE_79_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_80, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(80, s))
#define BOOST_PP_WHILE_80_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_81, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(81, s))
#define BOOST_PP_WHILE_81_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_82, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(82, s))
#define BOOST_PP_WHILE_82_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_83, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(83, s))
#define BOOST_PP_WHILE_83_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_84, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(84, s))
#define BOOST_PP_WHILE_84_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_85, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(85, s))
#define BOOST_PP_WHILE_85_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_86, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(86, s))
#define BOOST_PP_WHILE_86_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_87, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(87, s))
#define BOOST_PP_WHILE_87_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_88, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(88, s))
#define BOOST_PP_WHILE_88_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_89, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(89, s))
#define BOOST_PP_WHILE_89_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_90, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(90, s))
#define BOOST_PP_WHILE_90_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_91, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(91, s))
#define BOOST_PP_WHILE_91_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_92, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(92, s))
#define BOOST_PP_WHILE_92_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_93, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(93, s))
#define BOOST_PP_WHILE_93_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_94, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(94, s))
#define BOOST_PP_WHILE_94_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_95, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(95, s))
#define BOOST_PP_WHILE_95_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_96, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(96, s))
#define BOOST_PP_WHILE_96_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_97, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(97, s))
#define BOOST_PP_WHILE_97_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_98, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(98, s))
#define BOOST_PP_WHILE_98_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_99, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(99, s))
#define BOOST_PP_WHILE_99_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_100, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(100, s))
#define BOOST_PP_WHILE_100_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_101, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(101, s))
#define BOOST_PP_WHILE_101_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_102, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(102, s))
#define BOOST_PP_WHILE_102_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_103, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(103, s))
#define BOOST_PP_WHILE_103_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_104, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(104, s))
#define BOOST_PP_WHILE_104_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_105, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(105, s))
#define BOOST_PP_WHILE_105_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_106, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(106, s))
#define BOOST_PP_WHILE_106_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_107, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(107, s))
#define BOOST_PP_WHILE_107_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_108, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(108, s))
#define BOOST_PP_WHILE_108_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_109, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(109, s))
#define BOOST_PP_WHILE_109_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_110, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(110, s))
#define BOOST_PP_WHILE_110_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_111, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(111, s))
#define BOOST_PP_WHILE_111_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_112, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(112, s))
#define BOOST_PP_WHILE_112_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_113, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(113, s))
#define BOOST_PP_WHILE_113_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_114, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(114, s))
#define BOOST_PP_WHILE_114_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_115, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(115, s))
#define BOOST_PP_WHILE_115_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_116, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(116, s))
#define BOOST_PP_WHILE_116_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_117, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(117, s))
#define BOOST_PP_WHILE_117_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_118, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(118, s))
#define BOOST_PP_WHILE_118_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_119, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(119, s))
#define BOOST_PP_WHILE_119_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_120, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(120, s))
#define BOOST_PP_WHILE_120_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_121, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(121, s))
#define BOOST_PP_WHILE_121_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_122, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(122, s))
#define BOOST_PP_WHILE_122_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_123, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(123, s))
#define BOOST_PP_WHILE_123_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_124, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(124, s))
#define BOOST_PP_WHILE_124_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_125, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(125, s))
#define BOOST_PP_WHILE_125_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_126, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(126, s))
#define BOOST_PP_WHILE_126_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_127, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(127, s))
#define BOOST_PP_WHILE_127_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_128, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(128, s))
#define BOOST_PP_WHILE_128_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_129, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(129, s))
#define BOOST_PP_WHILE_129_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_130, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(130, s))
#define BOOST_PP_WHILE_130_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_131, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(131, s))
#define BOOST_PP_WHILE_131_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_132, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(132, s))
#define BOOST_PP_WHILE_132_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_133, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(133, s))
#define BOOST_PP_WHILE_133_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_134, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(134, s))
#define BOOST_PP_WHILE_134_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_135, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(135, s))
#define BOOST_PP_WHILE_135_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_136, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(136, s))
#define BOOST_PP_WHILE_136_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_137, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(137, s))
#define BOOST_PP_WHILE_137_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_138, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(138, s))
#define BOOST_PP_WHILE_138_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_139, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(139, s))
#define BOOST_PP_WHILE_139_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_140, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(140, s))
#define BOOST_PP_WHILE_140_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_141, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(141, s))
#define BOOST_PP_WHILE_141_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_142, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(142, s))
#define BOOST_PP_WHILE_142_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_143, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(143, s))
#define BOOST_PP_WHILE_143_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_144, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(144, s))
#define BOOST_PP_WHILE_144_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_145, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(145, s))
#define BOOST_PP_WHILE_145_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_146, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(146, s))
#define BOOST_PP_WHILE_146_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_147, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(147, s))
#define BOOST_PP_WHILE_147_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_148, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(148, s))
#define BOOST_PP_WHILE_148_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_149, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(149, s))
#define BOOST_PP_WHILE_149_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_150, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(150, s))
#define BOOST_PP_WHILE_150_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_151, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(151, s))
#define BOOST_PP_WHILE_151_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_152, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(152, s))
#define BOOST_PP_WHILE_152_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_153, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(153, s))
#define BOOST_PP_WHILE_153_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_154, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(154, s))
#define BOOST_PP_WHILE_154_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_155, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(155, s))
#define BOOST_PP_WHILE_155_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_156, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(156, s))
#define BOOST_PP_WHILE_156_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_157, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(157, s))
#define BOOST_PP_WHILE_157_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_158, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(158, s))
#define BOOST_PP_WHILE_158_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_159, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(159, s))
#define BOOST_PP_WHILE_159_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_160, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(160, s))
#define BOOST_PP_WHILE_160_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_161, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(161, s))
#define BOOST_PP_WHILE_161_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_162, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(162, s))
#define BOOST_PP_WHILE_162_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_163, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(163, s))
#define BOOST_PP_WHILE_163_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_164, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(164, s))
#define BOOST_PP_WHILE_164_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_165, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(165, s))
#define BOOST_PP_WHILE_165_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_166, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(166, s))
#define BOOST_PP_WHILE_166_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_167, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(167, s))
#define BOOST_PP_WHILE_167_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_168, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(168, s))
#define BOOST_PP_WHILE_168_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_169, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(169, s))
#define BOOST_PP_WHILE_169_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_170, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(170, s))
#define BOOST_PP_WHILE_170_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_171, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(171, s))
#define BOOST_PP_WHILE_171_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_172, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(172, s))
#define BOOST_PP_WHILE_172_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_173, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(173, s))
#define BOOST_PP_WHILE_173_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_174, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(174, s))
#define BOOST_PP_WHILE_174_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_175, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(175, s))
#define BOOST_PP_WHILE_175_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_176, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(176, s))
#define BOOST_PP_WHILE_176_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_177, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(177, s))
#define BOOST_PP_WHILE_177_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_178, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(178, s))
#define BOOST_PP_WHILE_178_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_179, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(179, s))
#define BOOST_PP_WHILE_179_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_180, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(180, s))
#define BOOST_PP_WHILE_180_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_181, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(181, s))
#define BOOST_PP_WHILE_181_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_182, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(182, s))
#define BOOST_PP_WHILE_182_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_183, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(183, s))
#define BOOST_PP_WHILE_183_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_184, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(184, s))
#define BOOST_PP_WHILE_184_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_185, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(185, s))
#define BOOST_PP_WHILE_185_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_186, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(186, s))
#define BOOST_PP_WHILE_186_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_187, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(187, s))
#define BOOST_PP_WHILE_187_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_188, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(188, s))
#define BOOST_PP_WHILE_188_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_189, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(189, s))
#define BOOST_PP_WHILE_189_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_190, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(190, s))
#define BOOST_PP_WHILE_190_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_191, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(191, s))
#define BOOST_PP_WHILE_191_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_192, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(192, s))
#define BOOST_PP_WHILE_192_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_193, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(193, s))
#define BOOST_PP_WHILE_193_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_194, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(194, s))
#define BOOST_PP_WHILE_194_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_195, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(195, s))
#define BOOST_PP_WHILE_195_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_196, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(196, s))
#define BOOST_PP_WHILE_196_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_197, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(197, s))
#define BOOST_PP_WHILE_197_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_198, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(198, s))
#define BOOST_PP_WHILE_198_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_199, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(199, s))
#define BOOST_PP_WHILE_199_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_200, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(200, s))
#define BOOST_PP_WHILE_200_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_201, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(201, s))
#define BOOST_PP_WHILE_201_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_202, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(202, s))
#define BOOST_PP_WHILE_202_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_203, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(203, s))
#define BOOST_PP_WHILE_203_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_204, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(204, s))
#define BOOST_PP_WHILE_204_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_205, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(205, s))
#define BOOST_PP_WHILE_205_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_206, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(206, s))
#define BOOST_PP_WHILE_206_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_207, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(207, s))
#define BOOST_PP_WHILE_207_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_208, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(208, s))
#define BOOST_PP_WHILE_208_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_209, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(209, s))
#define BOOST_PP_WHILE_209_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_210, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(210, s))
#define BOOST_PP_WHILE_210_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_211, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(211, s))
#define BOOST_PP_WHILE_211_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_212, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(212, s))
#define BOOST_PP_WHILE_212_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_213, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(213, s))
#define BOOST_PP_WHILE_213_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_214, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(214, s))
#define BOOST_PP_WHILE_214_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_215, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(215, s))
#define BOOST_PP_WHILE_215_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_216, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(216, s))
#define BOOST_PP_WHILE_216_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_217, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(217, s))
#define BOOST_PP_WHILE_217_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_218, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(218, s))
#define BOOST_PP_WHILE_218_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_219, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(219, s))
#define BOOST_PP_WHILE_219_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_220, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(220, s))
#define BOOST_PP_WHILE_220_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_221, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(221, s))
#define BOOST_PP_WHILE_221_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_222, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(222, s))
#define BOOST_PP_WHILE_222_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_223, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(223, s))
#define BOOST_PP_WHILE_223_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_224, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(224, s))
#define BOOST_PP_WHILE_224_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_225, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(225, s))
#define BOOST_PP_WHILE_225_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_226, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(226, s))
#define BOOST_PP_WHILE_226_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_227, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(227, s))
#define BOOST_PP_WHILE_227_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_228, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(228, s))
#define BOOST_PP_WHILE_228_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_229, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(229, s))
#define BOOST_PP_WHILE_229_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_230, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(230, s))
#define BOOST_PP_WHILE_230_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_231, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(231, s))
#define BOOST_PP_WHILE_231_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_232, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(232, s))
#define BOOST_PP_WHILE_232_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_233, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(233, s))
#define BOOST_PP_WHILE_233_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_234, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(234, s))
#define BOOST_PP_WHILE_234_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_235, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(235, s))
#define BOOST_PP_WHILE_235_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_236, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(236, s))
#define BOOST_PP_WHILE_236_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_237, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(237, s))
#define BOOST_PP_WHILE_237_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_238, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(238, s))
#define BOOST_PP_WHILE_238_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_239, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(239, s))
#define BOOST_PP_WHILE_239_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_240, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(240, s))
#define BOOST_PP_WHILE_240_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_241, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(241, s))
#define BOOST_PP_WHILE_241_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_242, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(242, s))
#define BOOST_PP_WHILE_242_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_243, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(243, s))
#define BOOST_PP_WHILE_243_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_244, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(244, s))
#define BOOST_PP_WHILE_244_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_245, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(245, s))
#define BOOST_PP_WHILE_245_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_246, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(246, s))
#define BOOST_PP_WHILE_246_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_247, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(247, s))
#define BOOST_PP_WHILE_247_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_248, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(248, s))
#define BOOST_PP_WHILE_248_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_249, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(249, s))
#define BOOST_PP_WHILE_249_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_250, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(250, s))
#define BOOST_PP_WHILE_250_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_251, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(251, s))
#define BOOST_PP_WHILE_251_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_252, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(252, s))
#define BOOST_PP_WHILE_252_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_253, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(253, s))
#define BOOST_PP_WHILE_253_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_254, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(254, s))
#define BOOST_PP_WHILE_254_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_255, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(255, s))
#define BOOST_PP_WHILE_255_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_256, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(256, s))
#define BOOST_PP_WHILE_256_C(c, p, o, s) BOOST_PP_IIF(c, BOOST_PP_WHILE_257, s BOOST_PP_TUPLE_EAT_3)(p, o, BOOST_PP_IIF(c, o, BOOST_PP_NIL BOOST_PP_TUPLE_EAT_2)(257, s))

#define BOOST_PP_WSTRINGIZE(text) BOOST_PP_WSTRINGIZE_I(text)
#define BOOST_PP_WSTRINGIZE_I(text) BOOST_PP_WSTRINGIZE_II(#text)
#define BOOST_PP_WSTRINGIZE_II(str) L##str

#define BOOST_PP_XOR(p, q) BOOST_PP_BITXOR(BOOST_PP_BOOL(p), BOOST_PP_BOOL(q))

#define BOOST_PREVENT_MACRO_SUBSTITUTION

#define BOOST_PRIVATE_CTR_DEF( z, n, data )	\
    template < BOOST_PP_ENUM_PARAMS(n, typename T) >	\
    explicit base_from_member( BOOST_PP_ENUM_BINARY_PARAMS(n, T, x) )	\
        : member( BOOST_PP_ENUM_PARAMS(n, x) )	\
        {}	\
    /**/

#define BOOST_PROGRAM_OPTIONS_DECL

#define BOOST_PTR_CONTAINER_DEFINE_CONSTRUCTORS( PC, base_type )	\
    typedef BOOST_DEDUCED_TYPENAME base_type::iterator        iterator;	\
    typedef BOOST_DEDUCED_TYPENAME base_type::size_type       size_type;	\
    typedef BOOST_DEDUCED_TYPENAME base_type::const_reference const_reference;	\
    typedef BOOST_DEDUCED_TYPENAME base_type::allocator_type  allocator_type;	\
    PC( const allocator_type& a = allocator_type() ) : base_type(a) {}	\
    template< class InputIterator >	\
    PC( InputIterator first, InputIterator last,	\
    const allocator_type& a = allocator_type() ) : base_type( first, last, a ) {}

#define BOOST_PTR_CONTAINER_DEFINE_NON_INHERITED_MEMBERS( PC, base_type, this_type )	\
   BOOST_PTR_CONTAINER_DEFINE_CONSTRUCTORS( PC, base_type )	\
   BOOST_PTR_CONTAINER_DEFINE_RELEASE_AND_CLONE( PC, base_type, this_type )

#define BOOST_PTR_CONTAINER_DEFINE_RELEASE( base_type )	\
    using base_type::release;

#define BOOST_PTR_CONTAINER_DEFINE_RELEASE_AND_CLONE( PC, base_type, this_type )	\
	\
    PC( std::auto_ptr<this_type> r )	\
    : base_type ( r ) { }	\
	\
    void operator=( std::auto_ptr<this_type> r );	\
    std::auto_ptr<this_type> release();	\
    BOOST_PTR_CONTAINER_DEFINE_RELEASE( base_type )	\
    std::auto_ptr<this_type> clone() const;

#define BOOST_PYTHON_ALIGNER(T, n)	\
        typename mpl::if_c<	\
           sizeof(T) <= size, T, char>::type t##n

#define BOOST_PYTHON_APPLY(x) BOOST_PP_CAT(BOOST_PYTHON_APPLY_, x)
#define BOOST_PYTHON_APPLY_BOOST_PYTHON_ITEM(v) v
#define BOOST_PYTHON_APPLY_BOOST_PYTHON_NIL

#define BOOST_PYTHON_ARG_CONVERTER(n)	\
     BOOST_PYTHON_NEXT(typename mpl::next<first>::type, arg_iter,n)	\
     typedef arg_from_python<BOOST_DEDUCED_TYPENAME arg_iter##n::type> c_t##n;	\
     c_t##n c##n(get(mpl::int_<n>(), inner_args));	\
     if (!c##n.convertible())	\
          return 0;

#define BOOST_PYTHON_ARG_TO_PYTHON_BY_VALUE(T, expr)	\
    namespace converter	\
    {	\
      template <> struct arg_to_python< T >	\
        : handle<>	\
      {	\
          arg_to_python(T const& x)	\
            : python::handle<>(expr) {}	\
      };	\
    }

#define BOOST_PYTHON_AS_OBJECT(z, n, _) object(x##n)

#define BOOST_PYTHON_BASE_PARAMS BOOST_PP_ENUM_PARAMS_Z(1, BOOST_PYTHON_MAX_BASES, Base)

#define BOOST_PYTHON_BEGIN_CONVERSION_NAMESPACE namespace boost { namespace python {

#define BOOST_PYTHON_BINARY_ENUM(c, a, b) BOOST_PP_REPEAT(c, BOOST_PYTHON_BINARY_ENUM_I, (a, b))
#define BOOST_PYTHON_BINARY_ENUM_I(z, n, _) BOOST_PP_COMMA_IF(n) BOOST_PP_CAT(BOOST_PP_TUPLE_ELEM(2, 0, _), n) BOOST_PP_CAT(BOOST_PP_TUPLE_ELEM(2, 1, _), n)

#define BOOST_PYTHON_BINARY_OPERATION(id, rid, expr)	\
namespace detail	\
{	\
  template <>	\
  struct operator_l<op_##id>	\
  {	\
      template <class L, class R>	\
      struct apply	\
      {	\
          static inline PyObject* execute(L& l, R const& r);\
      };	\
      static char const* name();	\
  };	\
	\
  template <>	\
  struct operator_r<op_##id>	\
  {	\
      template <class L, class R>	\
      struct apply	\
      {	\
          static inline PyObject* execute(R& r, L const& l);	\
      };	\
      static char const* name();	\
  };	\
}

#define BOOST_PYTHON_BINARY_OPERATOR(id, rid, op)	\
BOOST_PYTHON_BINARY_OPERATION(id, rid, l op r)	\
namespace self_ns	\
{	\
  template <class L, class R>	\
  inline detail::operator_<detail::op_##id,L,R>	\
  operator op(L const&, R const&);	\
}

#define BOOST_PYTHON_BINARY_OPERATOR(op)	\
BOOST_PYTHON_DECL object operator op(object const& l, object const& r);	\
template <class L, class R>	\
BOOST_PYTHON_BINARY_RETURN(object) operator op(L const& l, R const& r);

#define BOOST_PYTHON_BINARY_OPERATOR(id, rid, op)	\
BOOST_PYTHON_BINARY_OPERATION(id, rid, l op r)	\
namespace self_ns	\
{	\
  template <class L, class R>	\
  inline detail::operator_<detail::op_##id,L,R>	\
  operator op(L const&, R const&);	\
}

#define BOOST_PYTHON_BINARY_RETURN(T) T

#define BOOST_PYTHON_BUILTIN_OBJECT_TRAITS(T)	\
    template <> struct pyobject_traits<Py##T##Object>	\
        : pyobject_type<Py##T##Object, &Py##T##_Type> {}

#define BOOST_PYTHON_COMPARE_OP(op, opid)	\
template <class L, class R>	\
BOOST_PYTHON_BINARY_RETURN(bool) operator op(L const& l, R const& r);

#define BOOST_PYTHON_CONVERSION boost::python
#define BOOST_PYTHON_END_CONVERSION_NAMESPACE }}

#define BOOST_PYTHON_CV_COUNT 4

#define BOOST_PYTHON_CV_QUALIFIER(i)	\
    BOOST_PYTHON_APPLY(	\
        BOOST_PP_TUPLE_ELEM(4, i, BOOST_PYTHON_CV_QUALIFIER_I)	\
    )

#define BOOST_PYTHON_CV_QUALIFIER_I	\
    (	\
        BOOST_PYTHON_NIL,	\
        BOOST_PYTHON_ITEM(const),	\
        BOOST_PYTHON_ITEM(volatile),	\
        BOOST_PYTHON_ITEM(const volatile)	\
    )


#define BOOST_PYTHON_DATA_MEMBER_HELPER(D)
#define BOOST_PYTHON_YES_DATA_MEMBER
#define BOOST_PYTHON_NO_DATA_MEMBER

#define BOOST_PYTHON_DECL
#define BOOST_PYTHON_DECL_EXCEPTION
#define BOOST_PYTHON_DECL_FORWARD

#define BOOST_PYTHON_DEFINE_STR_METHOD(name, arity)	\
str str_base:: name ( BOOST_PP_ENUM_PARAMS(arity, object_cref x) ) const;

#define BOOST_PYTHON_DO_FORWARD_ARG(z, index, _) , f##index(a##index)

#define BOOST_PYTHON_ENUM_AS_OBJECT(z, n, x) object(BOOST_PP_CAT(x,n))

#define BOOST_PYTHON_ENUM_WITH_DEFAULT(c, text, def) BOOST_PP_REPEAT(c, BOOST_PYTHON_ENUM_WITH_DEFAULT_I, (text, def))
#define BOOST_PYTHON_ENUM_WITH_DEFAULT_I(z, n, _) BOOST_PP_COMMA_IF(n) BOOST_PP_CAT(BOOST_PP_TUPLE_ELEM(2, 0, _), n) = BOOST_PP_TUPLE_ELEM(2, 1, _)

#define BOOST_PYTHON_EXPLICIT_TT_DEF(T)

#define BOOST_PYTHON_FIXED(z, n, text) text

#define BOOST_PYTHON_FORMAT_OBJECT(z, n, data) "O"

#define BOOST_PYTHON_FORWARD_OBJECT_CONSTRUCTORS(derived, base)	\
    BOOST_PYTHON_FORWARD_OBJECT_CONSTRUCTORS_(derived, base)	\
    template <class T>	\
    explicit derived(extract<T> const&);

#define BOOST_PYTHON_FUNC_WRAPPER_GEN(z, index, data)	\
    static RT BOOST_PP_CAT(func_,	\
        BOOST_PP_SUB_D(1, index, BOOST_PP_TUPLE_ELEM(3, 1, data))) (	\
        BOOST_PP_ENUM_BINARY_PARAMS_Z(	\
            1, index, T, arg));

#define BOOST_PYTHON_FUNCTION_OVERLOADS(generator_name, fname, min_args, max_args)	\
    BOOST_PYTHON_GEN_FUNCTION_STUB(	\
        fname,	\
        generator_name,	\
        max_args,	\
        BOOST_PP_SUB_D(1, max_args, min_args))

#define BOOST_PYTHON_GEN_FUNCTION(fname, fstubs_name, n_args, n_dflts, ret)	\
    struct fstubs_name	\
    {	\
        BOOST_STATIC_CONSTANT(int, n_funcs = BOOST_PP_INC(n_dflts));	\
        BOOST_STATIC_CONSTANT(int, max_args = n_funcs);	\
	\
        template <typename SigT>	\
        struct gen	\
        {	\
            typedef typename ::boost::mpl::begin<SigT>::type rt_iter;	\
            typedef typename ::boost::mpl::deref<rt_iter>::type RT;	\
            typedef typename ::boost::mpl::next<rt_iter>::type iter0;	\
	\
            BOOST_PP_REPEAT_2ND(	\
                n_args,	\
                BOOST_PYTHON_TYPEDEF_GEN,	\
                0)	\
	\
            BOOST_PP_REPEAT_FROM_TO_2(	\
                BOOST_PP_SUB_D(1, n_args, n_dflts),	\
                BOOST_PP_INC(n_args),	\
                BOOST_PYTHON_FUNC_WRAPPER_GEN,	\
                (fname, BOOST_PP_SUB_D(1, n_args, n_dflts), ret))	\
        };	\
    };	\


#define BOOST_PYTHON_GEN_FUNCTION_STUB(fname, fstubs_name, n_args, n_dflts)	\
    struct fstubs_name	\
        : public ::boost::python::detail::overloads_common<fstubs_name>	\
    {	\
        BOOST_PYTHON_GEN_FUNCTION(	\
            fname, non_void_return_type, n_args, n_dflts, return)	\
	\
        typedef non_void_return_type void_return_type;	\
        BOOST_PYTHON_OVERLOAD_CONSTRUCTORS(fstubs_name, n_args, n_dflts)	\
    };

#define BOOST_PYTHON_GEN_MEM_FUNCTION(fname, fstubs_name, n_args, n_dflts, ret)	\
    struct fstubs_name	\
    {	\
        BOOST_STATIC_CONSTANT(int, n_funcs = BOOST_PP_INC(n_dflts));	\
        BOOST_STATIC_CONSTANT(int, max_args = n_funcs + 1);	\
	\
        template <typename SigT>	\
        struct gen	\
        {	\
            typedef typename ::boost::mpl::begin<SigT>::type rt_iter;	\
            typedef typename ::boost::mpl::deref<rt_iter>::type RT;	\
	\
            typedef typename ::boost::mpl::next<rt_iter>::type class_iter;	\
            typedef typename ::boost::mpl::deref<class_iter>::type ClassT;	\
            typedef typename ::boost::mpl::next<class_iter>::type iter0;	\
	\
            BOOST_PP_REPEAT_2ND(	\
                n_args,	\
                BOOST_PYTHON_TYPEDEF_GEN,	\
                0)	\
	\
            BOOST_PP_REPEAT_FROM_TO_2(	\
                BOOST_PP_SUB_D(1, n_args, n_dflts),	\
                BOOST_PP_INC(n_args),	\
                BOOST_PYTHON_MEM_FUNC_WRAPPER_GEN,	\
                (fname, BOOST_PP_SUB_D(1, n_args, n_dflts), ret))	\
        };	\
    };

#define BOOST_PYTHON_GEN_MEM_FUNCTION_STUB(fname, fstubs_name, n_args, n_dflts)	\
    struct fstubs_name	\
        : public ::boost::python::detail::overloads_common<fstubs_name>	\
    {	\
        BOOST_PYTHON_GEN_MEM_FUNCTION(	\
            fname, non_void_return_type, n_args, n_dflts, return)	\
        BOOST_PYTHON_GEN_MEM_FUNCTION(	\
            fname, void_return_type, n_args, n_dflts, ;)	\
	\
        BOOST_PYTHON_OVERLOAD_CONSTRUCTORS(fstubs_name, n_args, n_dflts)	\
    };

#define BOOST_PYTHON_IMPORT_CONVERSION(x) void never_defined()

#define BOOST_PYTHON_INPLACE_OPERATOR(id, op)	\
namespace detail	\
{	\
  template <>	\
  struct operator_l<op_##id>	\
  {	\
      template <class L, class R>	\
      struct apply	\
      {	\
          static inline PyObject*	\
          execute(back_reference<L&> l, R const& r);	\
      };	\
      static char const* name();	\
  };	\
}	\
namespace self_ns	\
{	\
  template <class R>	\
  inline detail::operator_<detail::op_##id,self_t,R>	\
  operator op(self_t const&, R const&);	\
}

#define BOOST_PYTHON_INPLACE_OPERATOR(op)	\
BOOST_PYTHON_DECL object& operator op(object& l, object const& r);	\
template <class R>	\
object& operator op(object& l, R const& r);	\

#define BOOST_PYTHON_IS_LIST_ARG(z, n, data)	\
    BOOST_PP_IF(n, BOOST_PYTHON_PLUS, BOOST_PP_EMPTY)()	\
    is_list_arg< BOOST_PP_CAT(T,n) >::value

#define BOOST_PYTHON_IS_XXX_DEF(name, qualified_name, nargs)	\
    BOOST_DETAIL_IS_XXX_DEF(name, qualified_name, nargs)

#define BOOST_PYTHON_LIST_ACTUAL_PARAMS BOOST_PP_ENUM_PARAMS_Z(1,BOOST_PYTHON_LIST_SIZE,T)
#define BOOST_PYTHON_LIST_FORMAL_PARAMS BOOST_PP_ENUM_PARAMS_Z(1,BOOST_PYTHON_LIST_SIZE,class T)

#define BOOST_PYTHON_LIST_INC(n)	\
   BOOST_PP_CAT(mpl::vector, BOOST_PP_INC(n))

#define BOOST_PYTHON_MEM_FUNC_WRAPPER_GEN(z, index, data)	\
    static RT BOOST_PP_CAT(func_,	\
        BOOST_PP_SUB_D(1, index, BOOST_PP_TUPLE_ELEM(3, 1, data))) (	\
            ClassT obj BOOST_PP_COMMA_IF(index)	\
            BOOST_PP_ENUM_BINARY_PARAMS_Z(1, index, T, arg)	\
        );

#define BOOST_PYTHON_MEMBER_FUNCTION_OVERLOADS(generator_name, fname, min_args, max_args)	\
    BOOST_PYTHON_GEN_MEM_FUNCTION_STUB(	\
        fname,	\
        generator_name,	\
        max_args,	\
        BOOST_PP_SUB_D(1, max_args, min_args))

#define BOOST_PYTHON_MODULE_INIT(name)	\
void init_module_##name();	\
extern "C" __declspec(dllexport) void init##name();	\
void init_module_##name()

#define BOOST_PYTHON_MPL_LAMBDA_SUPPORT BOOST_MPL_AUX_LAMBDA_SUPPORT

#define BOOST_PYTHON_NEXT(init,name,n)	\
    typedef BOOST_PP_IF(n,typename mpl::next< BOOST_PP_CAT(name,BOOST_PP_DEC(n)) >::type, init) name##n;

#define BOOST_PYTHON_OPAQUE_SPECIALIZED_TYPE_ID(Pointee)	\
    namespace boost { namespace python {	\
    template<>	\
    inline type_info type_id<Pointee>(BOOST_PYTHON_EXPLICIT_TT_DEF(Pointee));	\
    template<>	\
    inline type_info type_id<const volatile Pointee&>(	\
        BOOST_PYTHON_EXPLICIT_TT_DEF(const volatile Pointee&));	\
}}

#define BOOST_PYTHON_OVERLOAD_ARGS	\
    BOOST_PP_ENUM_PARAMS_Z(1,	\
        BOOST_PYTHON_MAX_ARITY,	\
        T)	\

#define BOOST_PYTHON_OVERLOAD_CONSTRUCTORS(fstubs_name, n_args, n_dflts)	\
    fstubs_name(char const* doc = 0)	\
        : ::boost::python::detail::overloads_common<fstubs_name>(doc) {}	\
    template <std::size_t N>	\
    fstubs_name(char const* doc, ::boost::python::detail::keywords<N> const& keywords)	\
        : ::boost::python::detail::overloads_common<fstubs_name>(	\
            doc, keywords.range());	\
    template <std::size_t N>	\
    fstubs_name(::boost::python::detail::keywords<N> const& keywords, char const* doc = 0)	\
        : ::boost::python::detail::overloads_common<fstubs_name>(	\
            doc, keywords.range());

#define BOOST_PYTHON_OVERLOAD_TYPES	\
    BOOST_PP_ENUM_PARAMS_Z(1,	\
        BOOST_PYTHON_MAX_ARITY,	\
        class T)	\

#define BOOST_PYTHON_OVERLOAD_TYPES_WITH_DEFAULT	\
    BOOST_PP_ENUM_PARAMS_WITH_A_DEFAULT(	\
        BOOST_PYTHON_MAX_ARITY,	\
        class T,	\
        mpl::void_)	\

#define BOOST_PYTHON_PLUS +

#define BOOST_PYTHON_PROXY_INPLACE(op)	\
template <class Policies, class R>	\
proxy<Policies> const& operator op(proxy<Policies> const& lhs, R const& rhs);	\

#define BOOST_PYTHON_RETURN_TO_PYTHON_BY_VALUE(T, expr)	\
    template <> struct to_python_value<T&>	\
        : detail::builtin_to_python	\
    {	\
        inline PyObject* operator()(T const& x) const;	\
    };	\
    template <> struct to_python_value<T const&>	\
        : detail::builtin_to_python	\
    {	\
        inline PyObject* operator()(T const& x) const;	\
    };

#define BOOST_PYTHON_SIGNED_INTEGRAL_TYPE_ID(T)	\
template <>	\
inline type_info type_id<T>(BOOST_PYTHON_EXPLICIT_TT_DEF(T));

#define BOOST_PYTHON_TO_PYTHON_BY_VALUE(T, expr)	\
        BOOST_PYTHON_RETURN_TO_PYTHON_BY_VALUE(T,expr)	\
        BOOST_PYTHON_ARG_TO_PYTHON_BY_VALUE(T,expr)

#define BOOST_PYTHON_TYPEDEF_GEN(z, index, data)	\
    typedef typename ::boost::mpl::next<BOOST_PP_CAT(iter, index)>::type	\
        BOOST_PP_CAT(iter, BOOST_PP_INC(index));	\
    typedef typename ::boost::mpl::deref<BOOST_PP_CAT(iter, index)>::type	\
        BOOST_PP_CAT(T, index);

#define BOOST_PYTHON_UNARY_ENUM(c, text) BOOST_PP_REPEAT(c, BOOST_PYTHON_UNARY_ENUM_I, text)
#define BOOST_PYTHON_UNARY_ENUM_I(z, n, text) BOOST_PP_COMMA_IF(n) text ## n

#define BOOST_PYTHON_UNARY_OPERATOR(id, op, func_name)	\
namespace detail	\
{	\
  template <>	\
  struct operator_1<op_##id>	\
  {	\
      template <class T>	\
      struct apply	\
      {	\
          static PyObject* execute(T& x);	\
      };	\
      static char const* name();	\
  };	\
}	\
namespace self_ns	\
{	\
  inline detail::operator_<detail::op_##id>	\
  func_name(self_t const&);	\
}

#define BOOST_PYTHON_UNFORWARD(N,ignored) (typename unforward<A##N>::type)(a##N)

#define BOOST_PYTHON_VALUE_IS_XXX_DEF(name, qualified_name, nargs)	\
template <class X_>	\
struct value_is_##name	\
{	\
    BOOST_PYTHON_IS_XXX_DEF(name,qualified_name,nargs)	\
    BOOST_STATIC_CONSTANT(bool, value = is_##name<	\
                               typename remove_cv<	\
                                  typename remove_reference<X_>::type	\
                               >::type	\
                           >::value);	\
    typedef mpl::bool_<value> type;	\
	\
};

#define BOOST_PYTHON_VOID_ARGS BOOST_PP_SUB_D(1,BOOST_PYTHON_LIST_SIZE,N)

#define BOOST_QUATERNION_ACCESSOR_GENERATOR(type)	\
            type                    real() const;	\
            quaternion<type>        unreal() const;	\
            type                    R_component_1() const;	\
            type                    R_component_2() const;	\
            type                    R_component_3() const;	\
            type                    R_component_4() const;	\
            ::std::complex<type>    C_component_1() const;	\
            ::std::complex<type>    C_component_2() const;

#define BOOST_QUATERNION_CONSTRUCTOR_GENERATOR(type)	\
            explicit            quaternion( type const & requested_a = static_cast<type>(0),	\
                                            type const & requested_b = static_cast<type>(0),	\
                                            type const & requested_c = static_cast<type>(0),	\
                                            type const & requested_d = static_cast<type>(0))	\
            :   a(requested_a),	\
                b(requested_b),	\
                c(requested_c),	\
                d(requested_d)	\
            {	\
            }	\
	\
            explicit            quaternion( ::std::complex<type> const & z0,	\
                                            ::std::complex<type> const & z1 = ::std::complex<type>())	\
            :   a(z0.real()),	\
                b(z0.imag()),	\
                c(z1.real()),	\
                d(z1.imag())	\
            {	\
            }

#define BOOST_QUATERNION_MEMBER_ADD_GENERATOR(type)	\
        BOOST_QUATERNION_MEMBER_ADD_GENERATOR_1(type)	\
        BOOST_QUATERNION_MEMBER_ADD_GENERATOR_2(type)	\
        BOOST_QUATERNION_MEMBER_ADD_GENERATOR_3(type)

#define BOOST_QUATERNION_MEMBER_ADD_GENERATOR_1(type)	\
            quaternion<type> &        operator += (type const & rhs);

#define BOOST_QUATERNION_MEMBER_ADD_GENERATOR_2(type)	\
            quaternion<type> &        operator += (::std::complex<type> const & rhs);

#define BOOST_QUATERNION_MEMBER_ADD_GENERATOR_3(type)	\
            template<typename X>	\
            quaternion<type> &        operator += (quaternion<X> const & rhs);

#define BOOST_QUATERNION_MEMBER_ALGEBRAIC_GENERATOR(type)	\
        BOOST_QUATERNION_MEMBER_ADD_GENERATOR(type)	\
        BOOST_QUATERNION_MEMBER_SUB_GENERATOR(type)	\
        BOOST_QUATERNION_MEMBER_MUL_GENERATOR(type)	\
        BOOST_QUATERNION_MEMBER_DIV_GENERATOR(type)

#define BOOST_QUATERNION_MEMBER_ASSIGNMENT_GENERATOR(type)	\
            template<typename X>	\
            quaternion<type> &        operator = (quaternion<X> const  & a_affecter);	\
            quaternion<type> &        operator = (quaternion<type> const & a_affecter);	\
            quaternion<type> &        operator = (type const & a_affecter);	\
            quaternion<type> &        operator = (::std::complex<type> const & a_affecter);

#define BOOST_QUATERNION_MEMBER_DATA_GENERATOR(type)	\
            type    a;	\
            type    b;	\
            type    c;	\
            type    d;

#define BOOST_QUATERNION_MEMBER_DIV_GENERATOR(type)	\
        BOOST_QUATERNION_MEMBER_DIV_GENERATOR_1(type)	\
        BOOST_QUATERNION_MEMBER_DIV_GENERATOR_2(type)	\
        BOOST_QUATERNION_MEMBER_DIV_GENERATOR_3(type)

#define BOOST_QUATERNION_MEMBER_DIV_GENERATOR_1(type)	\
        quaternion<type> & operator /= (type const & rhs);

#define BOOST_QUATERNION_MEMBER_DIV_GENERATOR_2(type)	\
        quaternion<type> & operator /= (::std::complex<type> const & rhs);

#define BOOST_QUATERNION_MEMBER_DIV_GENERATOR_3(type)	\
            template<typename X>	\
            quaternion<type> & operator /= (quaternion<X> const & rhs);

#define BOOST_QUATERNION_MEMBER_MUL_GENERATOR(type)	\
        BOOST_QUATERNION_MEMBER_MUL_GENERATOR_1(type)	\
        BOOST_QUATERNION_MEMBER_MUL_GENERATOR_2(type)	\
        BOOST_QUATERNION_MEMBER_MUL_GENERATOR_3(type)

#define BOOST_QUATERNION_MEMBER_MUL_GENERATOR_1(type)	\
        quaternion<type> & operator *= (type const & rhs);

#define BOOST_QUATERNION_MEMBER_MUL_GENERATOR_2(type)	\
        quaternion<type> & operator *= (::std::complex<type> const & rhs);

#define BOOST_QUATERNION_MEMBER_MUL_GENERATOR_3(type)	\
        template<typename X>	\
        quaternion<type> &        operator *= (quaternion<X> const & rhs);

#define BOOST_QUATERNION_MEMBER_SUB_GENERATOR(type)	\
        BOOST_QUATERNION_MEMBER_SUB_GENERATOR_1(type)	\
        BOOST_QUATERNION_MEMBER_SUB_GENERATOR_2(type)	\
        BOOST_QUATERNION_MEMBER_SUB_GENERATOR_3(type)

#define BOOST_QUATERNION_MEMBER_SUB_GENERATOR_1(type)	\
            quaternion<type> & operator -= (type const & rhs);

#define BOOST_QUATERNION_MEMBER_SUB_GENERATOR_2(type)	\
            quaternion<type> & operator -= (::std::complex<type> const & rhs);

#define BOOST_QUATERNION_MEMBER_SUB_GENERATOR_3(type)	\
            template<typename X>	\
            quaternion<type> & operator -= (quaternion<X> const & rhs);

#define BOOST_QUATERNION_NOT_EQUAL_GENERATOR ;

#define BOOST_QUATERNION_OPERATOR_GENERATOR(op)	\
        BOOST_QUATERNION_OPERATOR_GENERATOR_1_L(op)	\
        BOOST_QUATERNION_OPERATOR_GENERATOR_1_R(op)	\
        BOOST_QUATERNION_OPERATOR_GENERATOR_2_L(op)	\
        BOOST_QUATERNION_OPERATOR_GENERATOR_2_R(op)	\
        BOOST_QUATERNION_OPERATOR_GENERATOR_3(op)

#define BOOST_QUATERNION_OPERATOR_GENERATOR_1_L(op)	\
        template<typename T>	\
        inline quaternion<T>    operator op (T const & lhs, quaternion<T> const & rhs)	\
        BOOST_QUATERNION_OPERATOR_GENERATOR_BODY(op)

#define BOOST_QUATERNION_OPERATOR_GENERATOR_1_R(op)	\
        template<typename T>	\
        inline quaternion<T>    operator op (quaternion<T> const & lhs, T const & rhs)	\
        BOOST_QUATERNION_OPERATOR_GENERATOR_BODY(op)

#define BOOST_QUATERNION_OPERATOR_GENERATOR_2_L(op)	\
        template<typename T>	\
        inline quaternion<T>    operator op (::std::complex<T> const & lhs, quaternion<T> const & rhs)	\
        BOOST_QUATERNION_OPERATOR_GENERATOR_BODY(op)

#define BOOST_QUATERNION_OPERATOR_GENERATOR_2_R(op)	\
        template<typename T>	\
        inline quaternion<T>    operator op (quaternion<T> const & lhs, ::std::complex<T> const & rhs)	\
        BOOST_QUATERNION_OPERATOR_GENERATOR_BODY(op)

#define BOOST_QUATERNION_OPERATOR_GENERATOR_3(op)	\
        template<typename T>	\
        inline quaternion<T>    operator op (quaternion<T> const & lhs, quaternion<T> const & rhs)	\
        BOOST_QUATERNION_OPERATOR_GENERATOR_BODY(op)

#define BOOST_QUATERNION_OPERATOR_GENERATOR_BODY(op) ;

#define BOOST_RANDOM_FIBONACCI_VAL(T,P,Q,V,E)	\
template<>	\
struct fibonacci_validation<T, P, Q>	\
{	\
  BOOST_STATIC_CONSTANT(bool, is_specialized = true);	\
  static T value();	\
  static T tolerance();	\
};

#define BOOST_RANDOM_PTR_HELPER_SPEC(T)

#define BOOST_RANGE_ARRAY_REF (&boost_range_array)

#define BOOST_RANGE_DEDUCED_TYPENAME typename

#define BOOST_READONLY_PROPERTY( property_type, friends )	\
class BOOST_JOIN( readonly_property, __LINE__ )	\
: public boost::unit_test::readonly_property<property_type > {	\
    typedef boost::unit_test::readonly_property<property_type > base_prop;	\
    BOOST_PP_SEQ_FOR_EACH( BOOST_READONLY_PROPERTY_DECLARE_FRIEND, ' ', friends )	\
    typedef base_prop::write_param_t  write_param_t;	\
public:	\
                BOOST_JOIN( readonly_property, __LINE__ )() {}	\
    explicit    BOOST_JOIN( readonly_property, __LINE__ )( write_param_t init_v  )	\
    : base_prop( init_v ) {}	\
}	\
/**/

#define BOOST_READONLY_PROPERTY_DECLARE_FRIEND(r, data, elem) friend class elem;

#define BOOST_REF_CONST const

#define BOOST_REGEX_CALL

#define BOOST_REGEX_CCALL

#define BOOST_REGEX_DECL

#define BOOST_REGEX_TRAITS_T ,boost::regex_traits<BOOST_REGEX_CHAR_T>

#define BOOST_REMOTE_CALL(context, stack, n)	\
template<class R BOOST_REMOTE_CALL_CLASS_LIST_ ## n>	\
inline R context ## _remote_call(stack R (*pfnF)(	\
                                      BOOST_REMOTE_CALL_ARGUMENT_LIST_ ## n)	\
                                      BOOST_REMOTE_CALL_COMMA_ ## n	\
                                  BOOST_REMOTE_CALL_ARGUMENT_LIST_ ## n)	\
{	\
    using ::boost::detail::thread::singleton;	\
    using detail::remote_call_manager;	\
    function<R> oFunc(bind(pfnF BOOST_REMOTE_CALL_FUNCTION_ARGUMENT_LIST_ ## n));	\
    remote_call_manager &rManager(singleton<remote_call_manager>::instance());	\
    return(rManager.execute_at_ ## context(oFunc));	\
}

#define BOOST_REMOTE_CALL_CLASS_LIST_0
#define BOOST_REMOTE_CALL_CLASS_LIST_1 BOOST_REMOTE_CALL_CLASS_LIST_0, class A1
#define BOOST_REMOTE_CALL_CLASS_LIST_2 BOOST_REMOTE_CALL_CLASS_LIST_1, class A2
#define BOOST_REMOTE_CALL_CLASS_LIST_3 BOOST_REMOTE_CALL_CLASS_LIST_2, class A3
#define BOOST_REMOTE_CALL_CLASS_LIST_4 BOOST_REMOTE_CALL_CLASS_LIST_3, class A4
#define BOOST_REMOTE_CALL_CLASS_LIST_5 BOOST_REMOTE_CALL_CLASS_LIST_4, class A5
#define BOOST_REMOTE_CALL_CLASS_LIST_6 BOOST_REMOTE_CALL_CLASS_LIST_5, class A6
#define BOOST_REMOTE_CALL_CLASS_LIST_7 BOOST_REMOTE_CALL_CLASS_LIST_6, class A7
#define BOOST_REMOTE_CALL_CLASS_LIST_8 BOOST_REMOTE_CALL_CLASS_LIST_7, class A8
#define BOOST_REMOTE_CALL_CLASS_LIST_9 BOOST_REMOTE_CALL_CLASS_LIST_8, class A9

#define BOOST_REMOTE_CALL_ARGUMENT_LIST_0
#define BOOST_REMOTE_CALL_ARGUMENT_LIST_1 BOOST_REMOTE_CALL_ARGUMENT_LIST_0  A1 oA1
#define BOOST_REMOTE_CALL_ARGUMENT_LIST_2 BOOST_REMOTE_CALL_ARGUMENT_LIST_1, A2 oA2
#define BOOST_REMOTE_CALL_ARGUMENT_LIST_3 BOOST_REMOTE_CALL_ARGUMENT_LIST_2, A3 oA3
#define BOOST_REMOTE_CALL_ARGUMENT_LIST_4 BOOST_REMOTE_CALL_ARGUMENT_LIST_3, A4 oA4
#define BOOST_REMOTE_CALL_ARGUMENT_LIST_5 BOOST_REMOTE_CALL_ARGUMENT_LIST_4, A5 oA5
#define BOOST_REMOTE_CALL_ARGUMENT_LIST_6 BOOST_REMOTE_CALL_ARGUMENT_LIST_5, A6 oA6
#define BOOST_REMOTE_CALL_ARGUMENT_LIST_7 BOOST_REMOTE_CALL_ARGUMENT_LIST_6, A7 oA7
#define BOOST_REMOTE_CALL_ARGUMENT_LIST_8 BOOST_REMOTE_CALL_ARGUMENT_LIST_7, A8 oA8
#define BOOST_REMOTE_CALL_ARGUMENT_LIST_9 BOOST_REMOTE_CALL_ARGUMENT_LIST_8, A9 oA9

#define BOOST_REMOTE_CALL_FUNCTION_ARGUMENT_LIST_0
#define BOOST_REMOTE_CALL_FUNCTION_ARGUMENT_LIST_1 BOOST_REMOTE_CALL_FUNCTION_ARGUMENT_LIST_0, oA1
#define BOOST_REMOTE_CALL_FUNCTION_ARGUMENT_LIST_2 BOOST_REMOTE_CALL_FUNCTION_ARGUMENT_LIST_1, oA2
#define BOOST_REMOTE_CALL_FUNCTION_ARGUMENT_LIST_3 BOOST_REMOTE_CALL_FUNCTION_ARGUMENT_LIST_2, oA3
#define BOOST_REMOTE_CALL_FUNCTION_ARGUMENT_LIST_4 BOOST_REMOTE_CALL_FUNCTION_ARGUMENT_LIST_3, oA4
#define BOOST_REMOTE_CALL_FUNCTION_ARGUMENT_LIST_5 BOOST_REMOTE_CALL_FUNCTION_ARGUMENT_LIST_4, oA5
#define BOOST_REMOTE_CALL_FUNCTION_ARGUMENT_LIST_6 BOOST_REMOTE_CALL_FUNCTION_ARGUMENT_LIST_5, oA6
#define BOOST_REMOTE_CALL_FUNCTION_ARGUMENT_LIST_7 BOOST_REMOTE_CALL_FUNCTION_ARGUMENT_LIST_6, oA7
#define BOOST_REMOTE_CALL_FUNCTION_ARGUMENT_LIST_8 BOOST_REMOTE_CALL_FUNCTION_ARGUMENT_LIST_7, oA8
#define BOOST_REMOTE_CALL_FUNCTION_ARGUMENT_LIST_9 BOOST_REMOTE_CALL_FUNCTION_ARGUMENT_LIST_8, oA9

#define BOOST_REMOTE_CALL_COMMA_0
#define BOOST_REMOTE_CALL_COMMA_1 ,
#define BOOST_REMOTE_CALL_COMMA_2 ,
#define BOOST_REMOTE_CALL_COMMA_3 ,
#define BOOST_REMOTE_CALL_COMMA_4 ,
#define BOOST_REMOTE_CALL_COMMA_5 ,
#define BOOST_REMOTE_CALL_COMMA_6 ,
#define BOOST_REMOTE_CALL_COMMA_7 ,
#define BOOST_REMOTE_CALL_COMMA_8 ,
#define BOOST_REMOTE_CALL_COMMA_9 ,

#define BOOST_RESULT_OF_ARGS void

#define BOOST_RETHROW throw;

#define BOOST_RT_CLA_NAMED_PARAM_GENERATORS( param_type )	\
template<typename T>	\
inline shared_ptr<param_type ## _t<T> >	\
param_type( cstring name = cstring() );	\
	\
inline shared_ptr<param_type ## _t<cstring> >	\
param_type( cstring name = cstring() );	\
/**/

#define BOOST_RT_PARAM_LITERAL(l) l

#define BOOST_RTL(x) ::x

#define BOOST_SELECT_BY_SIZE(type_, name, expr)	\
    BOOST_STATIC_CONSTANT(	\
        unsigned,	\
        BOOST_PP_CAT(boost_select_by_size_temp_, name) = sizeof(expr)	\
    );	\
    BOOST_STATIC_CONSTANT(	\
        type_,	\
        name =	\
            ( ::boost::iostreams::detail::select_by_size<	\
                BOOST_PP_CAT(boost_select_by_size_temp_, name)	\
              >::value )	\
    )	\
    /**/

#define BOOST_SERIALIZATION_BASE_OBJECT_NVP(name)	\
    boost::serialization::make_nvp(	\
        BOOST_PP_STRINGIZE(name),	\
        boost::serialization::base_object<name >(*this)	\
    )
/**/

#define BOOST_SERIALIZATION_COLLECTION_TRAITS(C)	\
    namespace boost { namespace serialization {	\
    BOOST_SERIALIZATION_COLLECTION_TRAITS_HELPER(bool, C)	\
    BOOST_SERIALIZATION_COLLECTION_TRAITS_HELPER(char, C)	\
    BOOST_SERIALIZATION_COLLECTION_TRAITS_HELPER(signed char, C)	\
    BOOST_SERIALIZATION_COLLECTION_TRAITS_HELPER(unsigned char, C)	\
    BOOST_SERIALIZATION_COLLECTION_TRAITS_HELPER(signed int, C)	\
    BOOST_SERIALIZATION_COLLECTION_TRAITS_HELPER(unsigned int, C)	\
    BOOST_SERIALIZATION_COLLECTION_TRAITS_HELPER(signed long, C)	\
    BOOST_SERIALIZATION_COLLECTION_TRAITS_HELPER(unsigned long, C)	\
    BOOST_SERIALIZATION_COLLECTION_TRAITS_HELPER(float, C)	\
    BOOST_SERIALIZATION_COLLECTION_TRAITS_HELPER(double, C)	\
    BOOST_SERIALIZATION_COLLECTION_TRAITS_HELPER(unsigned short, C)	\
    BOOST_SERIALIZATION_COLLECTION_TRAITS_HELPER(signed short, C)	\
    BOOST_SERIALIZATION_COLLECTION_TRAITS_HELPER_INT64(C)	\
    BOOST_SERIALIZATION_COLLECTION_TRAITS_HELPER_WCHAR(C)	\
    } }	\
    /**/

#define BOOST_SERIALIZATION_COLLECTION_TRAITS_HELPER(T, C)	\
template<>	\
struct implementation_level< C < T > > {	\
    typedef mpl::integral_c_tag tag;	\
    typedef mpl::int_<object_serializable> type;	\
    BOOST_STATIC_CONSTANT(int, value = object_serializable);	\
};	\
/**/

#define BOOST_SERIALIZATION_COLLECTION_TRAITS_HELPER_INT64(C)

#define BOOST_SERIALIZATION_COLLECTION_TRAITS_HELPER_WCHAR(C)

#define BOOST_SERIALIZATION_DECL(T) T

#define BOOST_SERIALIZATION_EXTENDED_TYPE_INFO_STUB(T)	\
        extended_type_info_null< T >

#define BOOST_SERIALIZATION_NVP(name)	\
    boost::serialization::make_nvp(BOOST_PP_STRINGIZE(name), name)
/**/

#define BOOST_SERIALIZATION_SHARED_PTR(T)

#define BOOST_SERIALIZATION_SPLIT_FREE(T)	\
namespace boost { namespace serialization {	\
template<class Archive>	\
inline void serialize(	\
        Archive & ar,	\
        T & t,	\
        const unsigned int file_version	\
);	\
}}
/**/

#define BOOST_SERIALIZATION_SPLIT_MEMBER()	\
template<class Archive>	\
void serialize(	\
    Archive &ar,	\
    const unsigned int file_version	\
);	\
/**/

#define BOOST_SHARED_POINTER_EXPORT(T)	\
    BOOST_SHARED_POINTER_EXPORT_GUID(	\
        T,	\
        BOOST_PP_STRINGIZE(T)	\
    )	\
    /**/

#define BOOST_SHARED_POINTER_EXPORT_GUID(T, K)	\
    typedef boost_132::detail::sp_counted_base_impl<	\
        T *,	\
        boost::checked_deleter< T >	\
    > __shared_ptr_ ## T;	\
    BOOST_CLASS_EXPORT_GUID(__shared_ptr_ ## T, "__shared_ptr_" K)	\
    BOOST_CLASS_EXPORT_GUID(T, K)	\
    /**/


#define BOOST_SIGNALS_ARGS_STRUCT BOOST_JOIN(args,BOOST_SIGNALS_NUM_ARGS)

#define BOOST_SIGNALS_ARGS_STRUCT_INST	\
  BOOST_SIGNALS_NAMESPACE::detail::BOOST_SIGNALS_ARGS_STRUCT<BOOST_SIGNALS_TEMPLATE_ARGS>

#define BOOST_SIGNALS_CALL_BOUND BOOST_JOIN(call_bound,BOOST_SIGNALS_NUM_ARGS)

#define BOOST_SIGNALS_DECL

#define BOOST_SIGNALS_FUNCTION BOOST_JOIN(function,BOOST_SIGNALS_NUM_ARGS)

#define BOOST_SIGNALS_NAMESPACE signals

#define BOOST_SIGNALS_SIGNAL BOOST_JOIN(signal,BOOST_SIGNALS_NUM_ARGS)

#define BOOST_SPECIALIZE_PROPERTY_TRAITS_PTR(TYPE)	\
  template <>	\
  struct property_traits<TYPE*> {	\
    typedef TYPE value_type;	\
    typedef value_type& reference;	\
    typedef std::ptrdiff_t key_type;	\
    typedef lvalue_property_map_tag   category;	\
  };	\
  template <>	\
  struct property_traits<const TYPE*> {	\
    typedef TYPE value_type;	\
    typedef const value_type& reference;	\
    typedef std::ptrdiff_t key_type;	\
    typedef lvalue_property_map_tag   category;	\
  }

#define BOOST_SPIRIT_GRAMMARDEF_ENUM_ASSIGN(z, N, _)	\
    using phoenix::tuple_index_names::BOOST_PP_CAT(_, BOOST_PP_INC(N));	\
    t[BOOST_PP_CAT(_, BOOST_PP_INC(N))] = &BOOST_PP_CAT(t, N);	\
    /**/

#define BOOST_SPIRIT_GRAMMARDEF_ENUM_INIT(z, N, _)	\
    impl::init_tuple_member<N>::do_(t);	\
    /**/

#define BOOST_SPIRIT_GRAMMARDEF_ENUM_PARAMS(z, N, _)	\
    BOOST_PP_CAT(TC, N) const &BOOST_PP_CAT(t, N)	\
    /**/

#define BOOST_SPIRIT_GRAMMARDEF_ENUM_START(z, N, _)	\
    template <BOOST_PP_ENUM_PARAMS_Z(z, BOOST_PP_INC(N), typename TC)>	\
    void	\
    start_parsers(BOOST_PP_ENUM_ ## z(BOOST_PP_INC(N),	\
        BOOST_SPIRIT_GRAMMARDEF_ENUM_PARAMS, _) );	\
    /**/

#define BOOST_SPIRIT_GRAMMARDEF_TUPLE_PARAM(z, N, _)	\
    typename impl::make_const_pointer<T, BOOST_PP_CAT(T, N)>::type	\
    /**/

#define BOOST_SPIRIT_IT_NS impl

#define BOOST_SPIRIT_SELECT_PARSER(z, N, _)	\
    template <	\
        BOOST_PP_ENUM_PARAMS_Z(z, BOOST_PP_INC(N), typename ParserT)	\
    >	\
    select_parser<	\
        phoenix::tuple<	\
            BOOST_PP_ENUM_ ## z(BOOST_PP_INC(N),	\
                BOOST_SPIRIT_SELECT_EMBEDDED, _)	\
        >,	\
        BehaviourT,	\
        T	\
    >	\
    operator()(	\
        BOOST_PP_ENUM_BINARY_PARAMS_Z(z, BOOST_PP_INC(N),	\
            ParserT, const &p)	\
    ) const;	\
    /**/

#define BOOST_STATIC_CONSTANT(type, assignment) const type assignment

#define BOOST_STATIC_WARNING(B) BOOST_STATIC_WARNING_IMPL(true)

#define BOOST_STATIC_WARNING_IMPL(B)	\
     struct BOOST_JOIN(STATIC_WARNING, __LINE__) {	\
         ::boost::static_warning_impl<(bool)( B )>::type* p;	\
         void f();	\
     }	\
     /**/

#define BOOST_STD_EXTENSION_NAMESPACE std

#define BOOST_STL_DECLARE_LIMITS_MEMBER(__mem_type, __mem_name, __mem_value)	\
  static const __mem_type __mem_name = __mem_value

#define BOOST_STRING_TYPENAME BOOST_DEDUCED_TYPENAME

#define BOOST_STRINGIZE(X) BOOST_DO_STRINGIZE(X)

#define BOOST_STRONG_TYPEDEF(T, D)	\
struct D	\
    : boost::totally_ordered1< D	\
    , boost::totally_ordered2< D, T	\
    > >	\
{	\
    T t;	\
    explicit D(const T t_) : t(t_) {};	\
    D(){};	\
    D(const D & t_) : t(t_.t){}	\
    D & operator=(const D & rhs);	\
    D & operator=(const T & rhs);	\
    operator const T & () const;	\
    operator T & ();	\
    bool operator==(const D & rhs) const;	\
    bool operator<(const D & rhs) const;	\
};

#define BOOST_TEMPLATE_DECL
#define BOOST_TEMPLATED_STREAM(X, E, T) std::X
#define BOOST_TEMPLATED_STREAM_ALLOC(A) A
#define BOOST_TEMPLATED_STREAM_ARGS(E, T)
#define BOOST_TEMPLATED_STREAM_ARGS_ALLOC(E, T, A)
#define BOOST_TEMPLATED_STREAM_COMMA ,
#define BOOST_TEMPLATED_STREAM_ELEM(E) E
#define BOOST_TEMPLATED_STREAM_TEMPLATE(E, T)
#define BOOST_TEMPLATED_STREAM_TEMPLATE_ALLOC(E, T, A)
#define BOOST_TEMPLATED_STREAM_TRAITS(T) T
#define BOOST_TEMPLATED_STREAM_WITH_ALLOC(X, E, T, A) std::X

#define BOOST_TEST_CALL_DECL

#define BOOST_TEST_CASE_TEMPLATE_FUNCTION( name, type_name )	\
template<typename type_name>	\
void BOOST_JOIN( name, _impl )( boost::type<type_name>* );	\
	\
struct name {	\
    template<typename TestType>	\
    static void run( boost::type<TestType>* frwrd = 0 );	\
};	\
	\
template<typename type_name>	\
void BOOST_JOIN( name, _impl )( boost::type<type_name>* )	\
/**/

#define BOOST_TEST_DONT_PRINT_LOG_VALUE( the_type )	\
namespace boost { namespace test_tools { namespace tt_detail {	\
template<>	\
struct print_log_value<the_type > {	\
    void operator()( std::ostream& ostr, the_type const& t ) {}	\
};	\
}}}	\
/**/

#define BOOST_TEST_FE_ANY ::boost::unit_test::for_each::static_any_t

#define BOOST_TEST_SINGLETON_CONS( type )	\
friend class boost::unit_test::singleton<type>;	\
type() {}	\
/**/

#define BOOST_TEST_SINGLETON_INST( inst )	\
namespace { BOOST_JOIN( inst, _t)& inst = BOOST_JOIN( inst, _t)::instance(); }

#define BOOST_TEST_STRINGIZE(s) BOOST_TEST_L(BOOST_STRINGIZE(s))

#define BOOST_TEST_TOOL_IMPL( func, P, check_descr, TL, CT )	\
    boost::test_tools::tt_detail::func(	\
        P,	\
        boost::wrap_stringstream().ref() << check_descr,	\
        BOOST_TEST_L(__FILE__),	\
        (std::size_t)__LINE__,	\
        boost::test_tools::tt_detail::TL,	\
        boost::test_tools::tt_detail::CT	\
/**/

#define BOOST_THREAD_DECL

#define BOOST_TRIBOOL_THIRD_STATE(Name)	\
inline bool	\
Name(boost::logic::tribool x,	\
     boost::logic::detail::indeterminate_t dummy =	\
       boost::logic::detail::indeterminate_t());

#define BOOST_TRY {try

#define BOOST_TT_ALIGNMENT_BASE_TYPES BOOST_PP_TUPLE_TO_LIST(	\
        12, (	\
        char, short, int, long,  ::boost::long_long_type, float, double, long double	\
        , void*, function_ptr, member_ptr, member_function_ptr))

#define BOOST_TT_ALIGNMENT_STRUCT_TYPES	\
        BOOST_PP_LIST_TRANSFORM(BOOST_TT_HAS_ONE_T,	\
                                X,	\
                                BOOST_TT_ALIGNMENT_BASE_TYPES)

#define BOOST_TT_ALIGNMENT_TYPES	\
        BOOST_PP_LIST_APPEND(BOOST_TT_ALIGNMENT_BASE_TYPES,	\
                             BOOST_TT_ALIGNMENT_STRUCT_TYPES)

#define BOOST_TT_AUX_BOOL_C_BASE(C)

#define BOOST_TT_AUX_BOOL_TRAIT_CV_SPEC1(trait,sp,value)	\
    BOOST_TT_AUX_BOOL_TRAIT_SPEC1(trait,sp,value)	\
    /**/

#define BOOST_TT_AUX_BOOL_TRAIT_DEF1(trait,T,C)	\
template< typename T > struct trait	\
    BOOST_TT_AUX_BOOL_C_BASE(C)	\
{	\
    BOOST_TT_AUX_BOOL_TRAIT_VALUE_DECL(C)	\
    BOOST_MPL_AUX_LAMBDA_SUPPORT(1,trait,(T))	\
};	\
\
BOOST_TT_AUX_TEMPLATE_ARITY_SPEC(1,trait)	\
/**/

#define BOOST_TT_AUX_BOOL_TRAIT_DEF2(trait,T1,T2,C)	\
template< typename T1, typename T2 > struct trait	\
    BOOST_TT_AUX_BOOL_C_BASE(C)	\
{	\
    BOOST_TT_AUX_BOOL_TRAIT_VALUE_DECL(C)	\
    BOOST_MPL_AUX_LAMBDA_SUPPORT(2,trait,(T1,T2))	\
};	\
\
BOOST_TT_AUX_TEMPLATE_ARITY_SPEC(2,trait)	\
/**/

#define BOOST_TT_AUX_BOOL_TRAIT_IMPL_PARTIAL_SPEC2_1(param,trait,sp1,sp2,C)	\
template< param > struct trait##_impl< sp1,sp2 >	\
{	\
    BOOST_STATIC_CONSTANT(bool, value = (C));	\
};	\
/**/

#define BOOST_TT_AUX_BOOL_TRAIT_IMPL_SPEC1(trait,sp,C)	\
template<> struct trait##_impl< sp >	\
{	\
    BOOST_STATIC_CONSTANT(bool, value = (C));	\
};	\
/**/

#define BOOST_TT_AUX_BOOL_TRAIT_IMPL_SPEC2(trait,sp1,sp2,C)	\
template<> struct trait##_impl< sp1,sp2 >	\
{	\
    BOOST_STATIC_CONSTANT(bool, value = (C));	\
};	\
/**/

#define BOOST_TT_AUX_BOOL_TRAIT_PARTIAL_SPEC1_1(param,trait,sp,C)	\
template< param > struct trait< sp >	\
    BOOST_TT_AUX_BOOL_C_BASE(C)	\
{	\
    BOOST_TT_AUX_BOOL_TRAIT_VALUE_DECL(C)	\
};	\
/**/

#define BOOST_TT_AUX_BOOL_TRAIT_PARTIAL_SPEC1_2(param1,param2,trait,sp,C)	\
template< param1, param2 > struct trait< sp >	\
    BOOST_TT_AUX_BOOL_C_BASE(C)	\
{	\
    BOOST_TT_AUX_BOOL_TRAIT_VALUE_DECL(C)	\
};	\
/**/

#define BOOST_TT_AUX_BOOL_TRAIT_PARTIAL_SPEC2_1(param,trait,sp1,sp2,C)	\
template< param > struct trait< sp1,sp2 >	\
    BOOST_TT_AUX_BOOL_C_BASE(C)	\
{	\
    BOOST_TT_AUX_BOOL_TRAIT_VALUE_DECL(C)	\
    BOOST_MPL_AUX_LAMBDA_SUPPORT_SPEC(2,trait,(sp1,sp2))	\
};	\
/**/

#define BOOST_TT_AUX_BOOL_TRAIT_PARTIAL_SPEC2_2(param1,param2,trait,sp1,sp2,C)	\
template< param1, param2 > struct trait< sp1,sp2 >	\
    BOOST_TT_AUX_BOOL_C_BASE(C)	\
{	\
    BOOST_TT_AUX_BOOL_TRAIT_VALUE_DECL(C)	\
};	\
/**/

#define BOOST_TT_AUX_BOOL_TRAIT_SPEC1(trait,sp,C)	\
template<> struct trait< sp >	\
    BOOST_TT_AUX_BOOL_C_BASE(C)	\
{	\
    BOOST_TT_AUX_BOOL_TRAIT_VALUE_DECL(C)	\
    BOOST_MPL_AUX_LAMBDA_SUPPORT_SPEC(1,trait,(sp))	\
};	\
/**/

#define BOOST_TT_AUX_BOOL_TRAIT_SPEC2(trait,sp1,sp2,C)	\
template<> struct trait< sp1,sp2 >	\
    BOOST_TT_AUX_BOOL_C_BASE(C)	\
{	\
    BOOST_TT_AUX_BOOL_TRAIT_VALUE_DECL(C)	\
    BOOST_MPL_AUX_LAMBDA_SUPPORT_SPEC(2,trait,(sp1,sp2))	\
};	\
/**/

#define BOOST_TT_AUX_BOOL_TRAIT_VALUE_DECL(C)

#define BOOST_TT_AUX_BROKEN_TYPE_TRAIT_SPEC1(trait,spec,result)	\
template<> struct trait##_impl<spec>	\
{	\
    typedef result type;	\
};	\
/**/

#define BOOST_TT_AUX_REMOVE_ALL_RANK_1_SPEC(T)	\
    BOOST_TT_AUX_REMOVE_PTR_REF_RANK_2_SPEC(T)	\
    BOOST_TT_AUX_REMOVE_CONST_VOLATILE_RANK1_SPEC(T)	\
    /**/

#define BOOST_TT_AUX_REMOVE_ALL_RANK_2_SPEC(T)	\
    BOOST_TT_AUX_REMOVE_ALL_RANK_1_SPEC(T*)	\
    BOOST_TT_AUX_REMOVE_ALL_RANK_1_SPEC(T const*)	\
    BOOST_TT_AUX_REMOVE_ALL_RANK_1_SPEC(T volatile*)	\
    BOOST_TT_AUX_REMOVE_ALL_RANK_1_SPEC(T const volatile*)	\
    /**/

#define BOOST_TT_AUX_REMOVE_CONST_VOLATILE_RANK1_SPEC(T)	\
    BOOST_TT_AUX_BROKEN_TYPE_TRAIT_SPEC1(remove_const,T const,T)	\
    BOOST_TT_AUX_BROKEN_TYPE_TRAIT_SPEC1(remove_const,T const volatile,T volatile)	\
    BOOST_TT_AUX_BROKEN_TYPE_TRAIT_SPEC1(remove_volatile,T volatile,T)	\
    BOOST_TT_AUX_BROKEN_TYPE_TRAIT_SPEC1(remove_volatile,T const volatile,T const)	\
    /**/

#define BOOST_TT_AUX_REMOVE_PTR_REF_RANK_1_SPEC(T)	\
    BOOST_TT_AUX_BROKEN_TYPE_TRAIT_SPEC1(remove_pointer,T*,T)	\
    BOOST_TT_AUX_BROKEN_TYPE_TRAIT_SPEC1(remove_pointer,T*const,T)	\
    BOOST_TT_AUX_BROKEN_TYPE_TRAIT_SPEC1(remove_pointer,T*volatile,T)	\
    BOOST_TT_AUX_BROKEN_TYPE_TRAIT_SPEC1(remove_pointer,T*const volatile,T)	\
    BOOST_TT_AUX_BROKEN_TYPE_TRAIT_SPEC1(remove_reference,T&,T)	\
    /**/

#define BOOST_TT_AUX_REMOVE_PTR_REF_RANK_2_SPEC(T)	\
    BOOST_TT_AUX_REMOVE_PTR_REF_RANK_1_SPEC(T)	\
    BOOST_TT_AUX_REMOVE_PTR_REF_RANK_1_SPEC(T const)	\
    BOOST_TT_AUX_REMOVE_PTR_REF_RANK_1_SPEC(T volatile)	\
    BOOST_TT_AUX_REMOVE_PTR_REF_RANK_1_SPEC(T const volatile)	\
    /**/

#define BOOST_TT_AUX_SIZE_T_BASE(C) ::boost::mpl::size_t<C>

#define BOOST_TT_AUX_SIZE_T_TRAIT_DEF1(trait,T,C)	\
template< typename T > struct trait	\
    : BOOST_TT_AUX_SIZE_T_BASE(C)	\
{	\
    BOOST_TT_AUX_SIZE_T_TRAIT_VALUE_DECL(C)	\
    BOOST_MPL_AUX_LAMBDA_SUPPORT(1,trait,(T))	\
};	\
\
BOOST_TT_AUX_TEMPLATE_ARITY_SPEC(1,trait)	\
/**/

#define BOOST_TT_AUX_SIZE_T_TRAIT_PARTIAL_SPEC1_1(param,trait,spec,C)	\
template< param > struct trait<spec>	\
    : BOOST_TT_AUX_SIZE_T_BASE(C)	\
{	\
};	\
/**/

#define BOOST_TT_AUX_SIZE_T_TRAIT_SPEC1(trait,spec,C)	\
template<> struct trait<spec>	\
    : BOOST_TT_AUX_SIZE_T_BASE(C)	\
{	\
    BOOST_TT_AUX_SIZE_T_TRAIT_VALUE_DECL(C)	\
    BOOST_MPL_AUX_LAMBDA_SUPPORT_SPEC(1,trait,(spec))	\
};	\
/**/

#define BOOST_TT_AUX_SIZE_T_TRAIT_VALUE_DECL(C)	\
    typedef ::boost::mpl::size_t<C> base_;	\
    using base_::value;	\
    /**/

#define BOOST_TT_AUX_TEMPLATE_ARITY_SPEC(i, name)

#define BOOST_TT_AUX_TYPE_TRAIT_DEF1(trait,T,result)	\
template< typename T > struct trait	\
{	\
    typedef result type;	\
    BOOST_MPL_AUX_LAMBDA_SUPPORT(1,trait,(T))	\
};	\
\
BOOST_TT_AUX_TEMPLATE_ARITY_SPEC(1,trait)	\
/**/

#define BOOST_TT_AUX_TYPE_TRAIT_IMPL_PARTIAL_SPEC1_1(param,trait,spec,result)	\
template< param > struct trait##_impl<spec>	\
{	\
    typedef result type;	\
};	\
/**/

#define BOOST_TT_AUX_TYPE_TRAIT_IMPL_SPEC1(trait,spec,result)	\
template<> struct trait##_impl<spec>	\
{	\
    typedef result type;	\
};	\
/**/

#define BOOST_TT_AUX_TYPE_TRAIT_PARTIAL_SPEC1_1(param,trait,spec,result)	\
template< param > struct trait<spec>	\
{	\
    typedef result type;	\
};	\
/**/

#define BOOST_TT_AUX_TYPE_TRAIT_PARTIAL_SPEC1_2(param1,param2,trait,spec,result)	\
template< param1, param2 > struct trait<spec>	\
{	\
    typedef result;	\
};	\
/**/

#define BOOST_TT_AUX_TYPE_TRAIT_SPEC1(trait,spec,result)	\
template<> struct trait<spec>	\
{	\
    typedef result type;	\
    BOOST_MPL_AUX_LAMBDA_SUPPORT_SPEC(1,trait,(spec))	\
};	\
/**/

#define BOOST_TT_BROKEN_COMPILER_SPEC(T)

#define BOOST_TT_CHOOSE_MIN_ALIGNMENT(R,P,I,T)	\
        typename lower_alignment_helper<	\
          BOOST_PP_CAT(found,I),target,T	\
        >::type BOOST_PP_CAT(t,I);	\
        enum {	\
            BOOST_PP_CAT(found,BOOST_PP_INC(I))	\
              = lower_alignment_helper<BOOST_PP_CAT(found,I),target,T >::value	\
        };

#define BOOST_TT_CHOOSE_T(R, P, I, T) T BOOST_PP_CAT(t,I);

#define BOOST_TT_DECL

#define BOOST_TT_HAS_ONE_T(D,Data,T) boost::detail::has_one_T< T >

#define BOOST_TUPLE_ALGO(algo) algo

#define BOOST_TUPLE_ALGO_RECURSE

#define BOOST_TUPLE_ALGO_TERMINATOR

#define BOOST_UINT64_CAST(src_type)	\
        static inline bool check(src_type x, unsigned __int64);

#define BOOST_USED

#define BOOST_USING_STD_MAX using std::max

#define BOOST_USING_STD_MIN using std::min

#define BOOST_UTF8_BEGIN_NAMESPACE	\
     namespace boost { namespace archive { namespace detail {

#define BOOST_UTF8_DECL

#define BOOST_UTF8_END_NAMESPACE }}}

#define BOOST_VARIANT_AUX_APPLY_VISITOR_NON_CONST_RESULT_TYPE(V)	\
    BOOST_VARIANT_AUX_GENERIC_RESULT_TYPE(typename V::result_type)	\
    /**/

#define BOOST_VARIANT_AUX_APPLY_VISITOR_NON_CONST_RESULT_TYPE(V)	\
    typename enable_if<	\
          mpl::not_< is_const< V > >	\
        , BOOST_VARIANT_AUX_GENERIC_RESULT_TYPE(typename V::result_type)	\
        >::type	\
    /**/

#define BOOST_VARIANT_AUX_APPLY_VISITOR_STEP_TYPEDEF(z, N, _)	\
    typedef typename BOOST_PP_CAT(step,N)::type BOOST_PP_CAT(T,N);	\
    typedef typename BOOST_PP_CAT(step,N)::next	\
        BOOST_PP_CAT(step, BOOST_PP_INC(N));	\
    /**/

#define BOOST_VARIANT_AUX_CONVERT_VOID(z, N,_)	\
        typename convert_void< BOOST_PP_CAT(T,N) >::type

#define BOOST_VARIANT_AUX_DECLARE_PARAMS	\
    BOOST_PP_ENUM(	\
          BOOST_VARIANT_LIMIT_TYPES	\
        , BOOST_VARIANT_AUX_DECLARE_PARAMS_IMPL	\
        , T	\
        )	\
    /**/

#define BOOST_VARIANT_AUX_DECLARE_PARAMS_IMPL(z, N, T)	\
    typename BOOST_PP_CAT(T,N) = BOOST_PP_CAT(detail::variant::void,N)	\
    /**/

#define BOOST_VARIANT_AUX_ECHO(z, N, token) token

#define BOOST_VARIANT_AUX_ENABLE_RECURSIVE_IMPL(T,Dest,Source)	\
    rebind1< T , Dest >	\
    /**/

#define BOOST_VARIANT_AUX_ENABLE_RECURSIVE_IMPL_HANDLE_POINTER(CV_)	\
    template <typename T, typename Dest, typename Source>	\
    struct substitute<	\
          T * CV_	\
        , Dest	\
        , Source	\
          BOOST_MPL_AUX_LAMBDA_ARITY_PARAM(mpl::int_<-1>)	\
        >	\
    {	\
        typedef typename substitute<	\
              T, Dest, Source	\
            >::type * CV_ type;	\
    };	\
    /**/

#define BOOST_VARIANT_AUX_ENABLE_RECURSIVE_IMPL_SUBSTITUTE_TAG(CV_)	\
    template <typename Dest, typename Source>	\
    struct substitute<	\
          CV_ Source	\
        , Dest	\
        , Source	\
          BOOST_MPL_AUX_LAMBDA_ARITY_PARAM(mpl::int_<-1>)	\
        >	\
    {	\
        typedef CV_ Dest type;	\
    };	\
    /**/

    #define BOOST_VARIANT_AUX_ENABLE_RECURSIVE_TYPEDEFS(z,N,_)	\
        typedef typename enable_recursive<	\
              BOOST_PP_CAT(T,N)	\
            , RecursiveVariant	\
            , mpl::true_	\
            >::type BOOST_PP_CAT(wknd_T,N);	\
        /**/

#define BOOST_VARIANT_AUX_GENERIC_RESULT_TYPE(T) T

#define BOOST_VARIANT_AUX_GET_EXPLICIT_TEMPLATE_TYPE(t) ,t * =0

#define BOOST_VARIANT_AUX_INITIALIZER_T( mpl_seq, typename_base )	\
    ::boost::detail::variant::preprocessor_list_initializer<	\
          BOOST_VARIANT_AUX_PP_INITIALIZER_TEMPLATE_ARGS(typename_base)	\
        >	\
    /**/

#define BOOST_VARIANT_AUX_MAKE_REFERENCE_CONTENT_TYPEDEFS(z,N,_)	\
    typedef detail::make_reference_content<	\
          BOOST_PP_CAT(recursive_enabled_T,N)	\
        >::type BOOST_PP_CAT(internal_T,N);	\
    /**/

#define BOOST_VARIANT_AUX_PP_INITIALIZE_FUNCTION(z,N,_)	\
    BOOST_VARIANT_AUX_PP_INITIALIZER_DEFINE_PARAM_T(N)	\
    static int initialize(	\
          void* dest	\
        , BOOST_PP_CAT(param_T,N) operand	\
        );	\
    /**/

#define BOOST_VARIANT_AUX_PP_INITIALIZER_DEFINE_PARAM_T(N)	\
    typedef typename unwrap_recursive<	\
          BOOST_PP_CAT(recursive_enabled_T,N)	\
        >::type BOOST_PP_CAT(public_T,N);	\
    typedef typename call_traits<	\
          BOOST_PP_CAT(public_T,N)	\
        >::param_type BOOST_PP_CAT(param_T,N);	\
/**/

#define BOOST_VARIANT_AUX_PP_INITIALIZER_ENUM_PARAM_TYPE(z,N,T)	\
    ::boost::call_traits<	\
          ::boost::unwrap_recursive<BOOST_PP_CAT(T,N)>::type	\
        >::param_type	\
    /**/

#define BOOST_VARIANT_AUX_PP_INITIALIZER_TEMPLATE_ARGS(typename_base)	\
      BOOST_VARIANT_ENUM_PARAMS(typename_base)	\
    /**/

#define BOOST_VARIANT_AUX_PP_INITIALIZER_TEMPLATE_PARAMS	\
      BOOST_VARIANT_ENUM_PARAMS(typename recursive_enabled_T)	\
/**/

#define BOOST_VARIANT_AUX_SUBSTITUTE_TYPEDEF(z, N, _)	\
    BOOST_VARIANT_AUX_SUBSTITUTE_TYPEDEF_IMPL( BOOST_PP_INC(N) )	\
    /**/

#define BOOST_VARIANT_AUX_SUBSTITUTE_TYPEDEF_IMPL(N)	\
    typedef typename substitute<	\
          BOOST_PP_CAT(U,N), Dest, Source	\
        >::type BOOST_PP_CAT(u,N);	\
    /**/

    #define BOOST_VARIANT_AUX_UNWRAP_RECURSIVE_TYPEDEFS(z,N,_)	\
        typedef typename unwrap_recursive<	\
              BOOST_PP_CAT(recursive_enabled_T,N)	\
            >::type BOOST_PP_CAT(public_T,N);	\
        /**/

#define BOOST_VARIANT_DETAIL_DEFINE_VOID_N(z,N,_)	\
    struct BOOST_PP_CAT(void,N);	\
	\
    template <>	\
    struct convert_void< BOOST_PP_CAT(void,N) >	\
    {	\
        typedef mpl::na type;	\
    };	\
    /**/

#define BOOST_VARIANT_ENUM_PARAMS( param )	\
    BOOST_PP_ENUM_PARAMS(BOOST_VARIANT_LIMIT_TYPES, param)

#define BOOST_VARIANT_ENUM_SHIFTED_PARAMS( param )	\
    BOOST_PP_ENUM_SHIFTED_PARAMS(BOOST_VARIANT_LIMIT_TYPES, param)

#define BOOST_VARIANT_TT_AUX_BOOL_TRAIT_DEF1(trait,T,C)	\
template< typename T > struct trait	\
    BOOST_TT_AUX_BOOL_C_BASE(C)	\
{	\
    BOOST_TT_AUX_BOOL_TRAIT_VALUE_DECL(C)	\
    BOOST_MPL_AUX_LAMBDA_SUPPORT(1,trait,(T))	\
};	\
/**/

#define BOOST_VARIANT_TT_AUX_TRAIT_SUFFIX(arity, name)	\
BOOST_TT_AUX_TEMPLATE_ARITY_SPEC(arity, name)	\
/**/

#define BOOST_WARCHIVE_DECL(T) T

#define BOOST_WAVE_OSSTREAM std::ostrstream

#define BOOST_WAVE_STRINGTYPE std::string

#define BOOST_WAVETEST_OSSTREAM std::ostrstream

#define BOOST_WORKAROUND(symbol, test) 0

/////////////////////////////////////////////////////////////////////////////
// End Boost library
/////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
// Begin GNU C++ Standard library
/////////////////////////////////////////////////////////////////////////////

#define __glibcxx_class_requires(a,b)
#define __glibcxx_class_requires2(a,b,c)
#define __glibcxx_class_requires3(a,b,c,d)
#define __glibcxx_class_requires4(a,b,c,d,e)
#define __glibcxx_function_requires(...)

#define _GLIBCXX_VISIBILITY(V) 
#define _GLIBCXX_VISIBILITY_ATTR(V) 
#define _GLIBCXX_DEPRECATED_ATTR
#define _GLIBCXX_STD_D _GLIBCXX_STD
#define _GLIBCXX_STD_P _GLIBCXX_STD
#define _GLIBCXX_STD std
#define _GLIBCXX_BEGIN_NAMESPACE(X) namespace X {
#define _GLIBCXX_END_NAMESPACE }
#define _GLIBCXX_BEGIN_NAMESPACE_CONTAINER
#define _GLIBCXX_END_NAMESPACE_CONTAINER

#define _GLIBCXX_BEGIN_NESTED_NAMESPACE(X, Y)  namespace X {
#define _GLIBCXX_END_NESTED_NAMESPACE }

#define _GLIBCXX_LDBL_NAMESPACE
#define _GLIBCXX_BEGIN_LDBL_NAMESPACE
#define _GLIBCXX_END_LDBL_NAMESPACE

#undef CPPUNIT_NO_STD_NAMESPACE

/////////////////////////////////////////////////////////////////////////////
// End GNU C++ Standard library
/////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
// Begin Xerces Standard library
/////////////////////////////////////////////////////////////////////////////

#define XERCES_CPP_NAMESPACE_BEGIN
#define XERCES_CPP_NAMESPACE_END
#define XERCES_CPP_NAMESPACE_USE
#define XERCES_CPP_NAMESPACE_QUALIFIER

#define XMLUTIL_EXPORT
#define XMLPARSER_EXPORT
#define SAX_EXPORT
#define SAX2_EXPORT
#define CDOM_EXPORT
#define DEPRECATED_DOM_EXPORT
#define PARSERS_EXPORT
#define VALIDATORS_EXPORT

/////////////////////////////////////////////////////////////////////////////
// End Xerces Standard library
/////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
// CoreFoundation.Framework
/////////////////////////////////////////////////////////////////////////////

#define CF_INLINE static inline
#define CF_EXTERN_C_BEGIN extern "C" {
#define CF_EXTERN_C_END   }
#define CF_EXPORT extern
#define CF_FORMAT_FUNCTION(F,A)
#define CF_FORMAT_ARGUMENT(A)

#define CF_AVAILABLE(_mac, _ios)
#define CF_AVAILABLE_MAC(_mac)
#define CF_AVAILABLE_IOS(_ios)
#define CF_DEPRECATED(_macIntro, _macDep, _iosIntro, _iosDep)
#define CF_DEPRECATED_MAC(_macIntro, _macDep)
#define CF_DEPRECATED_IOS(_iosIntro, _iosDep)

/////////////////////////////////////////////////////////////////////////////
// End CoreFoundation.framework
/////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
// Foundation.framework
/////////////////////////////////////////////////////////////////////////////

#define FOUNDATION_EXTERN extern "C"
#define FOUNDATION_EXPORT
#define FOUNDATION_IMPORT

#define NS_INLINE static inline
#define NS_REQUIRES_NIL_TERMINATION
#define NS_FORMAT_FUNCTION(F,A)
#define NS_FORMAT_ARGUMENT(A)

#define NS_AVAILABLE(_mac, _ios)
#define NS_AVAILABLE_MAC(_mac)
#define NS_AVAILABLE_IOS(_ios)
#define NS_DEPRECATED(_macIntro, _macDep, _iosIntro, _iosDep)
#define NS_DEPRECATED_MAC(_macIntro, _macDep)
#define NS_DEPRECATED_IOS(_iosIntro, _iosDep)

#define NS_CLASS_AVAILABLE(_mac, _ios)

/////////////////////////////////////////////////////////////////////////////
// End Foundation.framework
/////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
// UIKit.framework
/////////////////////////////////////////////////////////////////////////////

#define IBAction void
#define IBOutlet
#define IBOutletCollection(ClassName)

/////////////////////////////////////////////////////////////////////////////
// End UIKit.framework
/////////////////////////////////////////////////////////////////////////////
