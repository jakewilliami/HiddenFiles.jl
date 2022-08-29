# https://opensource.apple.com/source/CF/CF-635/CFString.h.auto.html
# https://developer.apple.com/documentation/corefoundation/cfstringbuiltinencodings
const K_CFSTRING_ENCODING_MACROMAN = 0x0
const K_CFSTRING_ENCODING_WINDOWSLATIN1 = 0x0500 # ANSI codepage 1252
const K_CFSTRING_ENCODING_ISOLATIN1 = 0x0201     # ISO 8859-1
const K_CFSTRING_ENCODING_NEXTSTEPLATIN = 0x0B01 # NextStep encoding
const K_CFSTRING_ENCODING_ASCII = 0x0600         # 0..127 (in creating CFString, values greater than 0x7F are treated as corresponding Unicode value)
const K_CFSTRING_ENCODING_UNICODE = 0x0100       # kTextEncodingUnicodeDefault  + kTextEncodingDefaultFormat (aka kUnicode16BitFormat)
const K_CFSTRING_ENCODING_UTF8 = 0x08000100      # kTextEncodingUnicodeDefault + kUnicodeUTF8Format
const K_CFSTRING_ENCODING_NONLOSSYASCII = 0x0BFF # 7bit Unicode variants used by Cocoa & Java
const K_CFSTRING_ENCODING_UTF16 = 0x0100         # kTextEncodingUnicodeDefault + kUnicodeUTF16Format (alias of kCFStringEncodingUnicode)
const K_CFSTRING_ENCODING_UTF16BE = 0x10000100   # kTextEncodingUnicodeDefault + kUnicodeUTF16BEFormat
const K_CFSTRING_ENCODING_UTF16LE = 0x14000100   # kTextEncodingUnicodeDefault + kUnicodeUTF16LEFormat
const K_CFSTRING_ENCODING_UTF32 = 0x0c000100     # kTextEncodingUnicodeDefault + kUnicodeUTF32Format
const K_CFSTRING_ENCODING_UTF32BE = 0x18000100   # kTextEncodingUnicodeDefault + kUnicodeUTF32BEFormat
const K_CFSTRING_ENCODING_UTF32LE = 0x1c000100   # kTextEncodingUnicodeDefault + kUnicodeUTF32LEFormat
# https://opensource.apple.com/source/CF/CF-368/String.subproj/CFStringUtilities.c.auto.html
const K_CF_STRING_ENCODING_UTF8 = UInt32(65001)

# https://developer.apple.com/documentation/corefoundation/1542942-cfstringcreatewithcstring        
function _cfstring_create_with_cstring(s::AbstractString, encoding::Unsigned = K_CFSTRING_ENCODING_MACROMAN)
    return ccall(:CFStringCreateWithCString, Cstring, 
                 (Ptr{Cvoid}, Cstring, UInt32),
                 C_NULL, s, encoding)
    # TODO: check if result is null (if so, there was a problem creating the string)
end

# https://developer.apple.com/documentation/coreservices/1426917-mditemcreate
function _mditem_create(cstr_f::Cstring)
    return ccall(:MDItemCreate, Ptr{UInt32}, (Ptr{Cvoid}, Cstring), C_NULL, cstr_f)
end

# https://developer.apple.com/documentation/coreservices/1427080-mditemcopyattribute
function _mditem_copy_attribute(mditem::Ptr{UInt32}, cfstr_attr_name::Cstring)
    return ccall(:MDItemCopyAttribute, Ptr{UInt32}, (Ptr{UInt32}, Cstring), mditem, cfstr_attr_name)
end

# https://developer.apple.com/documentation/corefoundation/1388772-cfarraygetcount
function _cfarray_get_count(cfarr_ptr::Ptr{UInt32})
    return ccall(:CFArrayGetCount, Int32, (Ptr{UInt32},), cfarr_ptr)
end

# https://developer.apple.com/documentation/corefoundation/1388767-cfarraygetvalueatindex
function _cfarray_get_value_at_index(cfarr_ptr::Ptr{UInt32}, idx::T) where {T <: Integer}
    return ccall(:CFArrayGetValueAtIndex, Cstring, (Ptr{UInt32}, Int32), cfarr_ptr, idx)
end

# https://developer.apple.com/documentation/corefoundation/1542853-cfstringgetlength
function _cfstring_get_length(cfstr::Cstring)
    return ccall(:CFStringGetLength, Int32, (Cstring,), cfstr)
end

# https://developer.apple.com/documentation/corefoundation/1542143-cfstringgetmaximumsizeforencodin
function _cfstring_get_maximum_size_for_encoding(strlen::T, encoding::Unsigned = K_CFSTRING_ENCODING_MACROMAN) where {T <: Integer}
    return ccall(:CFStringGetMaximumSizeForEncoding, Int32, (Int32, UInt32), strlen, encoding)
end

# https://developer.apple.com/documentation/corefoundation/1542730-cfstringgetcharacteratindex
function _cfstring_get_character_at_index(cfstr::Cstring, idx::T) where {T <: Integer}
    return Char(ccall(:CFStringGetCharacterAtIndex, UInt8, (Cstring, UInt32), cfstr, idx))
end

# https://github.com/vovkasm/input-source-switcher/blob/c5bab3de716db5e3dae3703ed3b72f2bf1cd51d3/utils.cpp#L9-L18
# https://www.tabnine.com/code/java/methods/org.eclipse.swt.internal.webkit.WebKit_win32/CFStringGetCharactersPtr
function _string_from_cf_string(cfstr::Cstring, encoding::Unsigned = K_CFSTRING_ENCODING_MACROMAN)
    strlen = _cfstring_get_length(cfstr)
    maxsz = _cfstring_get_maximum_size_for_encoding(strlen, encoding)
    cfio = IOBuffer()
    for i in 1:maxsz
        c = _cfstring_get_character_at_index(cfstr, i - 1)
        print(cfio, c)
    end
    return String(take!(cfio))
end

