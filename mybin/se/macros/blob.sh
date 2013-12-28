////////////////////////////////////////////////////////////////////////////////////
// $Revision: 38654 $
////////////////////////////////////////////////////////////////////////////////////
// Copyright 2010 SlickEdit Inc. 
// You may modify, copy, and distribute the Slick-C Code (modified or unmodified) 
// only if all of the following conditions are met: 
//   (1) You do not include the Slick-C Code in any product or application 
//       designed to run independently of SlickEdit software programs; 
//   (2) You do not use the SlickEdit name, logos or other SlickEdit 
//       trademarks to market Your application; 
//   (3) You provide a copy of this license with the Slick-C Code; and 
//   (4) You agree to indemnify, hold harmless and defend SlickEdit from and 
//       against any loss, damage, claims or lawsuits, including attorney's fees, 
//       that arise or result from the use or distribution of Your application.
////////////////////////////////////////////////////////////////////////////////////
/**
 * Allocate a blob with initial size of len bytes. This also clears the
 * blob's contents and sets its buffer length and offset to 0.
 *
 * <p>
 * A blob is an internal binary buffer for reading and writing
 * arbitrary data. Use the _Blob* functions
 * to get, set, and manipulate specific types of data.
 * </p>
 *
 * @param iLen Initial size in bytes of the blob.
 *
 * @return Blob handle>=0 on success, <0 error code on error.
 */
extern int _BlobAlloc(int len);

/**
 * Free a blob previously allocated with _BlobAlloc.
 *
 * <p>
 * A blob is an internal binary buffer for reading and writing
 * arbitrary data. Use the _Blob* functions
 * to get, set, and manipulate specific types of data.
 * </p>
 *
 * @param handle Handle to blob returned by _BlobAlloc.
 */
extern void _BlobFree(int handle);

/**
 * Initialize a blob with a buffer length=0 and offset=0, effectively
 * clearing the contents of the blob.
 *
 * @param handle Handle to blob returned by _BlobAlloc.
 */
extern void _BlobInit(int handle);

/**
 * Set the Offset for the blob relative to Origin. The offset is a 0-based
 * index into the blob buffer.
 *
 * <p>
 * A blob is an internal binary buffer for reading and writing
 * arbitrary data. Use the _Blob* functions
 * to get, set, and manipulate specific types of data.
 * </p>
 *
 * @param handle Handle to blob returned by _BlobAlloc.
 * @param Offset Number of bytes from origin.
 * @param Origin Initial position. 0=Beginning of blob, 1=Current position
 *               in blob, 2=End of blob.
 *
 * @return >=0 resulting offset on success, <0 on error.
 */
extern int _BlobSetOffset(int handle,int Offset,int Origin);

/**
 * Get the current offset of the blob. The offset is a 0-based index
 * into the blob buffer.
 *
 * <p>
 * A blob is an internal binary buffer for reading and writing
 * arbitrary data. Use the _Blob* functions
 * to get, set, and manipulate specific types of data.
 * </p>
 *
 * @param handle Handle to blob returned by _BlobAlloc.
 *
 * @return The current blob offset.
 */
extern int _BlobGetOffset(int handle);

/**
 * Get the length of blob. The full length of the blob is returned,
 * not the length relative to the current offset.
 *
 * @param handle Handle to blob returned by _BlobAlloc.
 *
 * @return Length of blob.
 */
extern int _BlobGetLen(int handle);

/**
 * Truncate the blob at Offset. The byte length of the blob is changed
 * accordingly so that a call to _BlobWrite* will only write the
 * contents of the blob up to but not including the new Offset.
 *
 * <p>
 * Note:<br>
 * Truncating at an offset that is greater than the current offset is
 * identical to calling _BlobSetOffset with the same offset.
 * </p>
 *
 * @param handle Handle to blob returned by _BlobAlloc.
 * @param Offset Offset to truncate at.
 *
 * @return 0 on success, <0 on error.
 */
extern int _BlobTruncate(int handle,int Offset);

/**
 * Set ILen bytes starting from Offset in blob to character c.
 *
 * @param handle Handle to blob returned by _BlobAlloc.
 * @param Offset Offset at which to start setting bytes.
 * @param c      Character to set iLen bytes to.
 * @param iLen   Number of bytes to set to c.
 *
 * @return 0 on success, <0 on error.
 */
extern int _BlobSet(int handle,int Offset,int c,int iLen);

/**
 * Create space within blob for len bytes from the current offset.
 * Useful for making space before writing to a blob.
 *
 * @param handle Handle to blob returned by _BlobAlloc.
 * @param len Number of bytes to make space for.
 *
 * @return 0 on success, <0 on error.
 */
extern int _BlobMakeSpace(int handle,int len);

/**
 * Check if there is space within blob for len bytes from the
 * current offset. Useful for checking for space before reading
 * from a blob.
 *
 * @param handle Handle to blob returned by _BlobAlloc.
 * @param len Number of bytes to check space for.
 *
 * @return 1 if space available, 0 if no space available, <0 on error.
 */
extern int _BlobHaveSpace(int handle,int len);

/**
 * Retrieve a 64-bit integer starting at the blob's current offset.
 *
 * @param handle Handle to blob returned by _BlobAlloc.
 * @param hvarInt64 Set on return. The 64-bit integer.
 * @param nbo       nbo=1 means that the read bytes be converted from
 *                  network-byte-order.
 *
 * @return 0 on success, <0 on error.
 */
extern int _BlobGetInt64(int handle,typeless &hvarInt64,int nbo);

/**
 * Put a 64-bit integer starting at the blob's current offset.
 *
 * <p>
 * Note:<br>
 * We pass the number in as an ascii-z string to get around limited
 * Slick-C&reg; type support.
 * </p>
 *
 * @param handle Handle to blob returned by _BlobAlloc.
 * @param pszInt64 The 64-bit integer.
 * @param nbo      nbo=1 means that the put bytes are in network-byte-order.
 *
 * @return 0 on success, <0 on error.
 */
extern int _BlobPutInt64(int handle,_str pszInt64,int nbo);

/**
 * Retrieve a 32-bit integer starting at the blob's current offset.
 *
 * @param handle Handle to blob returned by _BlobAlloc.
 * @param hvarInt32 Set on return. The 32-bit integer.
 * @param nbo       nbo=1 means that the read bytes be converted from
 *                  network-byte-order.
 *
 * @return 0 on success, <0 on error.
 */
extern int _BlobGetInt32(int handle,typeless &hvarInt32,int nbo);

/**
 * Put a 32-bit integer starting at the blob's current offset.
 *
 * <p>
 * Note:<br>
 * We pass the number in as an ascii-z string to get around limited
 * Slick-C&reg; type support.
 * </p>
 *
 * @param handle Handle to blob returned by _BlobAlloc.
 * @param pszInt32 The 32-bit integer.
 * @param nbo      nbo=1 means that the put bytes are in network-byte-order.
 *
 * @return 0 on success, <0 on error.
 */
extern int _BlobPutInt32(int handle,_str pszInt32,int nbo);

/**
 * Retrieve a 16-bit integer starting at the blob's current offset.
 *
 * @param handle Handle to blob returned by _BlobAlloc.
 * @param hvarInt16 Set on return. The 16-bit integer.
 * @param nbo       nbo=1 means that the read bytes be converted from
 *                  network-byte-order.
 *
 * @return 0 on success, <0 on error.
 */
extern int _BlobGetInt16(int handle,typeless &hvarInt16,int nbo);

/**
 * Put a 16-bit integer starting at the blob's current offset.
 *
 * @param handle Handle to blob returned by _BlobAlloc.
 * @param i   The 16-bit integer.
 * @param nbo nbo=1 means that the put bytes are in network-byte-order.
 *
 * @return 0 on success, <0 on error.
 */
extern int _BlobPutInt16(int handle,int i,int nbo);

/**
 * Retrieve a character (8-bit integer) starting at the blob's current offset.
 *
 * @param handle Handle to blob returned by _BlobAlloc.
 * @param hvarInt Set on return. The character.
 *
 * @return 0 on success, <0 on error.
 */
extern int _BlobGetChar(int handle,int &hvarInt);

/**
 * Put a character (8-bit integer) starting at the blob's current offset.
 *
 * @param handle Handle to blob returned by _BlobAlloc.
 * @param i The character.
 *
 * @return 0 on success, <0 on error.
 */
extern int _BlobPutChar(int handle,int i);

/**
 * Get an ascii-z character string of length iLen bytes, starting at the
 * blob's current offset. If iLen=-1 then the number of bytes left in
 * the blob from the current offset is retrieved.
 *
 * @param handle Handle to blob returned by _BlobAlloc.
 * @param hvarStr Set on return. The ascii-z character string.
 * @param iLen    Length of character string to retrieve.
 *
 * @return 0 on success, <0 on error.
 */
extern int _BlobGetString(int handle,_str &hvarStr,int iLen);

/**
 * Get a character buffer of length iLen bytes, starting at the
 * blob's current offset. If iLen=-1 then the number of bytes left in
 * the blob from the current offset is retrieved.
 *
 * <p>
 * Note:<br>
 * This function uses SlickEdit's internal lstr type which
 * is limited to 1024 bytes.
 * </p>
 *
 * <p>
 * Note:<br>
 * This function will always read iLen characters, regardless of
 * terminating null characters. Use _BlobGetString to retrieve
 * an ascii-z string.
 * </p>
 *
 * @param handle   Handle to blob returned by _BlobAlloc.
 * @param hvarLstr Set on return. The character buffer.
 * @param iLen     Length of character buffer to retrieve.
 *
 * @return 0 on success, <0 on error.
 */
extern int _BlobGetLString(int handle,typeless &hvarLstr,int iLen);

/**
 * Put a ascii-z character string starting at the blob's current offset.
 *
 * <p>
 * Note:<br>
 * The terminating null (ascii 0) is not put on the blob. If you need
 * to put the terminating null character on the blob, then make a
 * call to _BlobPutChar after putting the string.
 * </p>
 *
 * @param handle Handle to blob returned by _BlobAlloc.
 * @param pszStr Ascii-z character string to put on blob.
 *
 * @return 0 on success, <0 on error.
 */
extern int _BlobPutString(int handle,_str pszStr);

/**
 * Put a character string of iLen bytes starting at the blob's current offset.
 *
 * <p>
 * Note:<br>
 * This function uses SlickEdit's internal lstr type which
 * is limited to 1024 bytes.
 * </p>
 *
 * <p>
 * Note:<br>
 * This function will always write iLen characters, regardless of
 * terminating null characters. Use _BlobPutString to put
 * an ascii-z string.
 * </p>
 *
 * @param handle   Handle to blob returned by _BlobAlloc.
 * @param hvarLstr Character string to put on blob.
 * @param iLen     Length of character buffer to put.
 *
 * @return 0 on success, <0 on error.
 */
extern int _BlobPutLString(int handle,typeless &hvarLstr,int iLen);

/**
 * Read data from source blob and write in destination blob. The source
 * blob read position starts at current blob offset. The source blob
 * offset is advanced by the number of bytes read. The destination blob
 * write position starts at the current blob offset. The destination blob
 * offset is advanced by the number of bytes written. Use _BlobSetOffset
 * to set a different offset from the beginning of the blob at which
 * to start reading/writing.
 *
 * <p>
 * A blob is an internal binary buffer for reading and writing
 * arbitrary data. Use the _Blob* functions
 * to get, set, and manipulate specific types of data.
 * </p>
 *
 * @param hsrcblob  Handle to source blob returned by _BlobAlloc.
 * @param hdestblob Handle destination blob returned by _BlobAlloc.
 * @param iLen  Number of bytes to copy from source blob to
 *              destination blob. Specify -1 to read up to the end
 *              of the source blob.
 *
 * @return Number of bytes copied on success. <0 on error.
 */
extern int _BlobCopy(int hdestblob,int hsrcblob,int iLen);

/**
 * Read data from file and store in an internal "blob". The blob
 * read position starts at current blob offset. Use _BlobSetOffset
 * to set a different offset from the beginning of the blob at which
 * to start reading. The blob offset is advanced by the number of bytes
 * read.
 *
 * <p>
 * A blob is an internal binary buffer for reading and writing
 * arbitrary data. Use the _Blob* functions
 * to get, set, and manipulate specific types of data.
 * </p>
 *
 * @param hblob Handle to blob returned by _BlobAlloc.
 * @param hfile Handle to open file returned by _FileOpen.
 * @param iLen  Number of bytes to read into blob.
 *
 * @return Number of bytes read into blob on success. <0 on error.
 */
extern int _BlobReadFromFile(int hblob,int hfile,int iLen);

/**
 * Write data from internal "blob" to file. Writing starts from the
 * current blob offset. The current blob offset is not changed.
 *
 * <p>
 * A blob is an internal binary buffer for reading and writing
 * arbitrary data. Use the _Blob* functions
 * to get, set, and manipulate specific types of data.
 * </p>
 *
 * @param hblob Handle to blob returned by _BlobAlloc.
 * @param hfile Handle to open file returned by _FileOpen.
 * @param iLen  Number of bytes to write from blob.
 *              Specify -1 to write from current offset to
 *              end of blob.
 *
 * @return Number of bytes written from blob on success. <0 on error.
 */
extern int _BlobWriteToFile(int hblob,int hfile,int iLen);

