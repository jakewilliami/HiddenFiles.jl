# https://opensource.apple.com/source/CF/CF-635/CFString.h.auto.html
# https://developer.apple.com/documentation/corefoundation/cfstringbuiltinencodings
const K_CF_STRING_ENCODING_MAC_ROMAN       = 0x0
const K_CF_STRING_ENCODING_WINDOWS_LATIN_1 = 0x0500      # ANSI codepage 1252
const K_CF_STRING_ENCODING_ISO_LATIN_1     = 0x0201      # ISO 8859-1
const K_CF_STRING_ENCODING_NEXT_STEP_LATIN = 0x0B01      # NextStep encoding
const K_CF_STRING_ENCODING_ASCII           = 0x0600      # 0..127 (in creating CFString, values greater than 0x7F are treated as corresponding Unicode value)
const K_CF_STRING_ENCODING_UNICODE         = 0x0100      # kTextEncodingUnicodeDefault  + kTextEncodingDefaultFormat (aka kUnicode16BitFormat)
const K_CF_STRING_ENCODING_UTF8            = 0x08000100  # kTextEncodingUnicodeDefault + kUnicodeUTF8Format
const K_CF_STRING_ENCODING_NON_LOSSY_ASCII = 0x0BFF      # 7bit Unicode variants used by Cocoa & Java
const K_CF_STRING_ENCODING_UTF16           = 0x0100      # kTextEncodingUnicodeDefault + kUnicodeUTF16Format (alias of kCFStringEncodingUnicode)
const K_CF_STRING_ENCODING_UTF16BE         = 0x10000100  # kTextEncodingUnicodeDefault + kUnicodeUTF16BEFormat
const K_CF_STRING_ENCODING_UTF16LE         = 0x14000100  # kTextEncodingUnicodeDefault + kUnicodeUTF16LEFormat
const K_CF_STRING_ENCODING_UTF32           = 0x0c000100  # kTextEncodingUnicodeDefault + kUnicodeUTF32Format
const K_CF_STRING_ENCODING_UTF32BE         = 0x18000100  # kTextEncodingUnicodeDefault + kUnicodeUTF32BEFormat
const K_CF_STRING_ENCODING_UTF32LE         = 0x1c000100  # kTextEncodingUnicodeDefault + kUnicodeUTF32LEFormat

# This will be out main/default string encoding
"""
```julia
CF_STRING_ENCODING = K_CF_STRING_ENCODING_MAC_ROMAN  # 0x00
```

Default string encoding for working with paths in macOS.

!!! note
    You can reassign this variable so that other Core Foundation string functions implemented in this package uses your non-default string encoding.  See `K_CF_STRING_ENCODING_*` values for more string encoding options.

    [1]: https://developer.apple.com/documentation/corefoundation/cfstringbuiltinencodings
"""
CF_STRING_ENCODING = K_CF_STRING_ENCODING_MAC_ROMAN # K_CF_STRING_ENCODING_UTF8 or UTF16 doesn't seem to work

"""
```julia
_cfstring_create_with_cstring(s::AbstractString, encoding::Unsigned = CF_STRING_ENCODING) -> Cstring
```

Construct a Core Foundation (CF) string from an ordinary string in Julia.  Returns a `Cstring` (i.e., pointer to the CF string).

See also: [`_string_from_cf_string`](@ref).

[1]: https://developer.apple.com/documentation/corefoundation/1542942-cfstringcreatewithcstring
"""
function _cfstring_create_with_cstring(s::AbstractString, encoding::Unsigned = CF_STRING_ENCODING)
    # https://developer.apple.com/documentation/corefoundation/1542942-cfstringcreatewithcstring
    # CFStringRef CFStringCreateWithCString(CFAllocatorRef alloc, const char *cStr, CFStringEncoding encoding);
    cfstr = ccall(:CFStringCreateWithCString, Cstring,
                  (Ptr{Cvoid}, Cstring, UInt32),
                  C_NULL, s, encoding)
    cfstr == C_NULL && error("Cannot create CF String for $(repr(s)) using encoding $(repr(encoding))")
    return cfstr
end

"""
```julia
_mditem_create(cfstr_f::Cstring) -> Ptr{UInt32}
```

Creates a [metadata (MD) item](https://developer.apple.com/documentation/coreservices/file_metadata/mditem) for the specified file path, and returns a reference to the object (as a `Ptr{UInt32}`).

See also: [`mditem_copy_attribute`](@ref), [`_k_mditem_content_type_tree](@ref).

[1]: https://developer.apple.com/documentation/coreservices/1426917-mditemcreate

!!! note
    This function expects a Core Foundation (CF) string.  See [`_cfstring_create_with_cstring`](@ref) for constructing this string.
"""
function _mditem_create(cfstr_f::Cstring)
    # https://developer.apple.com/documentation/coreservices/1426917-mditemcreate
    # MDItemRef MDItemCreate(CFAllocatorRef allocator, CFStringRef path);
    ptr = ccall(:MDItemCreate, Ptr{UInt32}, (Ptr{Cvoid}, Cstring), C_NULL, cfstr_f)
    ptr == C_NULL && error("Cannot create MD Item for CF String $(repr(cfstr_f))")
    return ptr
end

"""
```julia
_mditem_copy_attribute(mditem::Ptr{UInt32}, cfstr_attr_name::Cstring) -> Ptr{UInt32}
```

Given a pointer to a metadata (MD) item and an attribute name (as an CF string), return the metadata value of the specified attribute.

See also: [`_mditem_create`](@ref), [`_k_mditem_content_type_tree](@ref).

[1]: https://developer.apple.com/documentation/coreservices/1427080-mditemcopyattribute

!!! note
    [`_mditem_copy_attribute`](@ref) may return a Core Foundation (CF) array (however, it may return a pointer to a CF string or an integer).  See `_cfarray_*` functions for working with these CF arrays.
"""
function _mditem_copy_attribute(mditem::Ptr{UInt32}, cfstr_attr_name::Cstring)
    # https://developer.apple.com/documentation/coreservices/1427080-mditemcopyattribute
    # CFTypeRef MDItemCopyAttribute(MDItemRef item, CFStringRef name);
    ptr = ccall(:MDItemCopyAttribute, Ptr{UInt32}, (Ptr{UInt32}, Cstring), mditem, cfstr_attr_name)
    ptr == C_NULL && error("Cannot copy MD Item attribute $(repr(cfstr_attr_name)); this attribute name might not exist")
    return ptr
end

"""
```julia
_cfarray_get_count(cfarr_ptr::Ptr{UInt32}) -> Int32
```

Given a pointer to a Core Foundation (CF) array, return its length.

[1]: https://developer.apple.com/documentation/corefoundation/1388772-cfarraygetcount

See also: [`_cfarray_get_value_at_index`](@ref).
"""
function _cfarray_get_count(cfarr_ptr::Ptr{UInt32})
    # https://developer.apple.com/documentation/corefoundation/1388772-cfarraygetcount
    # CFIndex CFArrayGetCount(CFArrayRef theArray);
    return ccall(:CFArrayGetCount, Int32, (Ptr{UInt32},), cfarr_ptr)
end

"""
```julia
_cfarray_get_value_at_index(cfarr_ptr::Ptr{UInt32}, idx::Integer) -> Cstring
```

Given a pointer to a Core Foundation (CF) array and an index in that array, return the value of that array.

[1]: https://developer.apple.com/documentation/corefoundation/1388767-cfarraygetvalueatindex

!!! note
    While the array may have different element types, in our case we can assume it is an array of strings, hence the present function will return a pointer to the CF string (as a `Cstring`).  We make a similar observational note in [`_mditem_copy_attribute`](@ref).
"""
function _cfarray_get_value_at_index(cfarr_ptr::Ptr{UInt32}, idx::T) where {T <: Integer}
    # https://developer.apple.com/documentation/corefoundation/1388767-cfarraygetvalueatindex
    # const void * CFArrayGetValueAtIndex(CFArrayRef theArray, CFIndex idx);
    return ccall(:CFArrayGetValueAtIndex, Cstring, (Ptr{UInt32}, Int32), cfarr_ptr, idx)
end

"""
```julia
_cfstring_get_length(cfstr::Cstring) -> Int32
```

Given a Core Foundation (CF) string, return its length.

[1]: https://developer.apple.com/documentation/corefoundation/1542853-cfstringgetlength
"""
function _cfstring_get_length(cfstr::Cstring)
    # https://developer.apple.com/documentation/corefoundation/1542853-cfstringgetlength
    # CFIndex CFStringGetLength(CFStringRef theString);
    return ccall(:CFStringGetLength, Int32, (Cstring,), cfstr)
end

"""
```julia
_cfstring_get_maximum_size_for_encoding(strlen::Integer, encoding::Unsigned = CF_STRING_ENCODING) -> Int32
```

Given the length of a string and its encoding type, return the maximum length of the string.

[1]: https://developer.apple.com/documentation/corefoundation/1542143-cfstringgetmaximumsizeforencodin
"""
function _cfstring_get_maximum_size_for_encoding(strlen::T, encoding::Unsigned = CF_STRING_ENCODING) where {T <: Integer}
    # https://developer.apple.com/documentation/corefoundation/1542143-cfstringgetmaximumsizeforencodin
    # CFIndex CFStringGetMaximumSizeForEncoding(CFIndex length, CFStringEncoding encoding);
    return ccall(:CFStringGetMaximumSizeForEncoding, Int32, (Int32, UInt32), strlen, encoding)
end

"""
```julia
_cfstring_get_character_at_index(cfstr::Cstring, idx::Integer) -> Char
```

Given a Core Foundation (CF) string as a `Cstring` (i.e., a pointer to the CF string) and an index, retun the character of the string at the given index.

[1]: https://developer.apple.com/documentation/corefoundation/1542730-cfstringgetcharacteratindex
"""
function _cfstring_get_character_at_index(cfstr::Cstring, idx::T) where {T <: Integer}
    # https://developer.apple.com/documentation/corefoundation/1542730-cfstringgetcharacteratindex
    # UniChar CFStringGetCharacterAtIndex(CFStringRef theString, CFIndex idx);
    return Char(ccall(:CFStringGetCharacterAtIndex, UInt8, (Cstring, UInt32), cfstr, idx))
end

"""
```julia
_string_from_cf_string(cfstr::Cstring, encoding::Unsigned = CF_STRING_ENCODING) -> String
```

Take a pointer to a Core Foundation (CF) string as a `Cstring` (and an encoding mode) and return the full string.
"""
function _string_from_cf_string(cfstr::Cstring, encoding::Unsigned = CF_STRING_ENCODING)
    # https://github.com/vovkasm/input-source-switcher/blob/c5bab3de716db5e3dae3703ed3b72f2bf1cd51d3/utils.cpp#L9-L18
    # https://www.tabnine.com/code/java/methods/org.eclipse.swt.internal.webkit.WebKit_win32/CFStringGetCharactersPtr
    # TODO: get _cfstring_get_character_at_index to return a UInt and write to buffer here
    strlen = _cfstring_get_length(cfstr)
    maxsz = _cfstring_get_maximum_size_for_encoding(strlen, encoding)
    cfio = IOBuffer()
    for i in 1:maxsz
        c = _cfstring_get_character_at_index(cfstr, i - 1)
        print(cfio, c)
    end
    return String(take!(cfio))
end
