module HiddenFiles


export ishidden


@static if Sys.isunix()
    _ishidden_unix(f::AbstractString) = startswith(basename(f), '.')
    
    
    @static if Sys.isapple()
        ###=== Hidden Files and Directories: Simplifying the User Experience ===##
        ##=== https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/FileSystemOverview/FileSystemOverview.html ===##
        
        #=== Case 1: Dot directories and files ===#
        # Any file or directory whose name starts with a period (`.`) character is hidden automatically.  This convention is taken from UNIX, 
        # which used it to hide system scripts and other special types of files and directories.  Two special directories in this category 
        # are the `.` and `..` directories, which are references to the current and parent directories respectively.  This case is handled by
        # _ishidden_unix
        
        
        #=== Case 2: UNIX-specific directories ===#
        # The directories in this category are inherited from traditional UNIX installations.  They are an important part of the system’s 
        # BSD layer but are more useful to software developers than end users. Some of the more important directories that are hidden include:
        #   - `/bin`—Contains essential command-line binaries. Typically, you execute these binaries from command-line scripts.
        #   - `/dev`—Contains essential device files, such as mount points for attached hardware.
        #   - `/etc`—Contains host-specific configuration files.
        #   - `/sbin`—Contains essential system binaries.
        #   - `/tmp`—Contains temporary files created by apps and the system.
        #   - `/usr`—Contains non-essential command-line binaries, libraries, header files, and other data.
        #   - `/var`—Contains log files and other files whose content is variable. (Log files are typically viewed using the Console app.)
        
        
        #=== Case 3: Explicitly hidden files and directories ===#
        # The Finder may hide specific files or directories that should not be accessed directly by the user.  The most notable example of 
        # this is the /Volumes directory, which contains a subdirectory for each mounted disk in the local file system from the command line. 
        # (The Finder provides a different user interface for accessing local disks.)  In macOS 10.7 and later, the Finder also hides the
        # `~/Library` directory—that is, the `Library` directory located in the user’s home directory.
        
        # https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/chflags.2.html
        # https://opensource.apple.com/source/xnu/xnu-4570.41.2/bsd/sys/stat.h.auto.html
        const UF_HIDDEN = 0x00008000
        
        # https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/fstat.2.html
        # https://opensource.apple.com/source/hfs/hfs-366.1.1/core/hfs_format.h.auto.html
        # http://docs.libuv.org/en/v1.x/fs.html  # st_flags offset is 11, or 21 in 32-bit
        const ST_FLAGS_STAT_OFFSET = 0x15
        function _st_flags(f::AbstractString)
            statbuf = Vector{UInt32}(undef, ccall(:jl_sizeof_stat, Int32, ()))
            ccall(:jl_lstat, Int32, (Cstring, Ptr{UInt8}), f, statbuf)
            return statbuf[ST_FLAGS_STAT_OFFSET]
        end
        
        # https://github.com/dotnet/runtime/blob/5992145db2cb57956ee444aa0f0c2f3f85ee3673/src/native/libs/System.Native/pal_io.c#L219
        # https://github.com/davidkaya/corefx/blob/4fd3d39f831f3e14f311b0cdc0a33d662e684a9c/src/System.IO.FileSystem/src/System/IO/FileStatus.Unix.cs#L88
        _isinvisible(f::AbstractString) = (_st_flags(f) & UF_HIDDEN) == UF_HIDDEN
        
        
        #=== Case 4: Packages and bundles ===#
        # Packages and bundles are directories that the Finder presents to the user as if they were files.  Bundles hide the internal workings 
        # of executables such as apps and just present a single entity that can be moved around the file system easily.  Similarly, packages 
        # allow apps to implement complex document formats consisting of multiple individual files while still presenting what appears to be a 
        # single document to the user.
        
        # https://superuser.com/questions/1739420/
        # https://stackoverflow.com/a/9858910/12069968
        # http://developer.apple.com/library/mac/#documentation/CoreFoundation/Conceptual/CFBundles/Introduction/Introduction.html/
        # https://opensource.apple.com/source/CF/CF-550/CFBase.c.auto.html
        
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
        # https://developer.apple.com/documentation/corefoundation/1542942-cfstringcreatewithcstring
        const K_CF_STRING_ENCODING_UTF8 = UInt32(65001)  # THIS DOES NOT SEEM TO WORK
        function _cfstring_create_with_cstring(s::AbstractString, encoding::Unsigned = K_CFSTRING_ENCODING_MACROMAN)
            return ccall(:CFStringCreateWithCString, Cstring, 
                         (Ptr{Cvoid}, Cstring, UInt32),
                         C_NULL, s, encoding)
            # TODO: check if result is null (if so, there was a problem creating the string)
        end
        
        # https://github.com/osquery/osquery/blob/598983db97459f858e7a9cc5c731409ffc089b48/osquery/tables/system/darwin/extended_attributes.cpp#L111-L144
        # https://github.com/objective-see/ProcInfo/blob/ec51090fcf741a9e045dd3e5119cb5cc8750efd3/procInfo/Binary.m#L121-L172
        function _mditem_create(cstr_f::Cstring)
            return ccall(:MDItemCreate, Ptr{UInt32}, (Ptr{Cvoid}, Cstring), C_NULL, cstr_f)
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
        
        function _cfstring_get_cstring(cfbuf::Vector{Char}, cfstr::Cstring, encoding::Unsigned = K_CFSTRING_ENCODING_MACROMAN)
            ccall(:CFStringGetCString, Bool,
                  (Cstring, Ptr{Cvoid}, Int32, UInt32),
                  cfstr, cfbuf, sizeof(cfbuf), 0) || error("Problem calling CFStringGetCString")
            return cfbuf
        end
        
        # https://developer.apple.com/documentation/corefoundation/1542730-cfstringgetcharacteratindex
        function _cfstring_get_character_at_index(cfstr::Cstring, idx::T) where {T <: Integer}
            return Char(ccall(:CFStringGetCharacterAtIndex, UInt8, (Cstring, UInt32), cfstr, idx))
        end
        
        # https://github.com/vovkasm/input-source-switcher/blob/c5bab3de716db5e3dae3703ed3b72f2bf1cd51d3/utils.cpp#L9-L18
        function _string_from_cf_string(cfstr::Cstring, encoding::Unsigned = K_CFSTRING_ENCODING_MACROMAN)
            strlen = _cfstring_get_length(cfstr)
            maxsz = _cfstring_get_maximum_size_for_encoding(strlen, encoding)
            cfio = IOBuffer()
            for i in 1:maxsz
                c = _cfstring_get_character_at_index(cfstr, i - 1)
                print(cfio, c)
            end
            # _cfstring_get_cstring(cfbuf, cfstr, encoding)  # NOTE: This wasn't working for some reason
            # return String(cfbuf)
            return String(take!(cfio))
        end
        
        # https://developer.apple.com/documentation/coreservices/1427080-mditemcopyattribute
        function _mditem_copy_attribute(mditem::Ptr{UInt32}, cfstr_attr_name::Cstring)
            return ccall(:MDItemCopyAttribute, Ptr{UInt32}, (Ptr{UInt32}, Cstring), mditem, cfstr_attr_name)
        end
        
        const K_MDITEM_CONTENT_TYPE_TREE = _cfstring_create_with_cstring("kMDItemContentTypeTree")
        # NOTE: this function will fail if you give it f as "/"
        function _k_mditem_content_type_tree(f::AbstractString, str_encoding::Unsigned = K_CFSTRING_ENCODING_MACROMAN)
            cfstr = _cfstring_create_with_cstring(f, str_encoding)
            mditem = _mditem_create(cfstr)
            mdattrs = _mditem_copy_attribute(mditem, K_MDITEM_CONTENT_TYPE_TREE)
            # TODO: release/free mditem
            cfarr_len = _cfarray_get_count(mdattrs)
            content_types = String[]
            for i in 0:(cfarr_len - 1)
                attr = _cfarray_get_value_at_index(mdattrs, i)
                if attr != C_NULL #&& !iszero(_cfstring_get_length(attr))
                    push!(content_types, _string_from_cf_string(attr))
                end
            end
            return content_types
            # TODO: release/free mdattrs
        end
        
        # https://stackoverflow.com/a/12233785
        # https://developer.apple.com/documentation/coreservices/kmditemcontenttypetree?changes=lat____2
        PKG_BUNDLE_TYPES = ("com.apple.package", "com.apple.bundle", "com.apple.application-bundle")
        _ispackage_or_bundle(f::AbstractString) = any(t ∈ PKG_BUNDLE_TYPES for t in _k_mditem_content_type_tree(f))
        
        # If a file or directory exists inside a package or bundle, then it is hidden.  Packages or bundles themselves
        # are not necessarily hidden.
        function _exists_inside_package_or_bundle(f::AbstractString)
            # This assumes that f has already been modified with the realpath function, as if it hasn't,
            # it is possible that f has a trailing slash, meaning its dirname is still itself
            f = dirname(f)
            while f != "/"
                _ispackage_or_bundle(f) && return true
                f = dirname(f)
            end            
            return false
        end
        
        
        # TODO: follow every function and ensure I have all correct links
        #=== All cases ===#
        _ishidden(f::AbstractString) = any((_ishidden_unix(f), _isinvisible(f), _exists_inside_package_or_bundle(f)))
    else
        _ishidden = _ishidden_unix
    end
elseif Sys.iswindows()
    # https://docs.microsoft.com/en-us/windows/win32/fileio/file-attribute-constants
    # https://github.com/SublimeText/Pywin32/blob/753322f9ac4b943c2c04ddd88605e68bc742dbb4/lib/x32/win32/lib/win32con.py#L2128-L2129
    const FILE_ATTRIBUTE_HIDDEN = 0x2
    const FILE_ATTRIBUTE_SYSTEM = 0x4
    
    ## https://docs.microsoft.com/en-gb/windows/win32/api/fileapi/nf-fileapi-getfileattributesa
    _ishidden(f::AbstractString) = !iszero(ccall(:GetFileAttributesA, UInt32, (Cstring,), f) & (FILE_ATTRIBUTE_HIDDEN | FILE_ATTRIBUTE_SYSTEM))
else
    _ishidden(f::AbstractString) = error("hidden files for this OS need to be defined")
end


# Each OS branch defines its own _ishidden function.  In the main ishidden function, we check that the path exists, expand
# the real path out, and apply the branch's _ishidden function to that path to get a final result
ishidden(f::AbstractString) = ispath(f) && _ishidden(realpath(f))


end

