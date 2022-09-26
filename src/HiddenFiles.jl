module HiddenFiles


export ishidden


"""
```julia
ishidden(f::AbstractString)
```

Check if a file or directory is hidden.

On Unix-like systems, a file or directory is hidden if it starts with a full stop/period (`U+002e`).  On Windows systems, this function will parse file attributes to determine if the given file or directory is hidden.

!!! note
    On Unix-like systems, in order to correctly determine if the file begins with a full stop, we must first expand the path to its real path.

!!! note
    On operating systems deriving from BSD (i.e., *BSD, macOS), this function will also check the `st_flags` field from `stat` to check if the `UF_HIDDEN` flag has been set.

!!! note
    On macOS, any file or directory within a [package](https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFBundles/DocumentPackages/DocumentPackages.html) or a [bundle](https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFBundles/AboutBundles/AboutBundles.html) will also be considered hidden.
"""
ishidden

include("docs.jl")

@static if Sys.isunix()
    include("utils/zfs.jl")
    if iszfs()  # @static breaks here # ZFS
        error("not yet implemented")
        _ishidden_zfs(f::AbstractString) = error("not yet implemented")
    end
    
    # Trivial Unix check
    _isdotfile(f::AbstractString) = startswith(basename(f), '.')
    # Check dotfiles, but also account for ZFS
    _ishidden_unix(f::AbstractString) = _isdotfile(realpath(f)) || (iszfs() && _ishidden_zfs())
    
    @static if Sys.isbsd()  # BDS-related; this is true for macOS as well
        # https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/chflags.2.html
        # https://opensource.apple.com/source/xnu/xnu-4570.41.2/bsd/sys/stat.h.auto.html
        # https://www.freebsd.org/cgi/man.cgi?query=chflags&sektion=2
        const UF_HIDDEN = 0x00008000
        
        # https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/stat.2.html
        # http://docs.libuv.org/en/v1.x/fs.html#c.uv_stat_t
        const ST_FLAGS_STAT_OFFSET = 0x15
        function _st_flags(f::AbstractString)
            statbuf = Vector{UInt32}(undef, ccall(:jl_sizeof_stat, Int32, ()))
            
            # int stat(const char *restrict path, struct stat *restrict buf);
            # int stat(const char * restrict path, struct stat * restrict sb);
            i = ccall(:jl_stat, Int32, (Cstring, Ptr{Cvoid}), f, statbuf)
            iszero(i) || Base.uv_error("_st_flags($(repr(f)))", i)
            
            # st_flags offset is at index 11, or 21 in 32-bit
            return statbuf[ST_FLAGS_STAT_OFFSET]
        end
        
        # https://github.com/dotnet/runtime/blob/5992145db2cb57956ee444aa0f0c2f3f85ee3673/src/native/libs/System.Native/pal_io.c#L219
        # https://github.com/davidkaya/corefx/blob/4fd3d39f831f3e14f311b0cdc0a33d662e684a9c/src/System.IO.FileSystem/src/System/IO/FileStatus.Unix.cs#L88
        _isinvisible(f::AbstractString) = (_st_flags(f) & UF_HIDDEN) == UF_HIDDEN    
        
        _ishidden_bsd_related(f::AbstractString) = _ishidden_unix(f) || _isinvisible(f)
    end
    
    @static if Sys.isapple()  # macOS/Darwin
        include("utils/darwin.jl")
        
        ###=== Hidden Files and Directories: Simplifying the User Experience ===##
        ##=== https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/FileSystemOverview/FileSystemOverview.html#//apple_ref/doc/uid/TP40010672-CH2-SW7 ===#
        
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
        # TODO
        _issystemfile(f::AbstractString) = false
        
        
        #=== Case 3: Explicitly hidden files and directories ===#
        # The Finder may hide specific files or directories that should not be accessed directly by the user.  The most notable example of 
        # this is the /Volumes directory, which contains a subdirectory for each mounted disk in the local file system from the command line. 
        # (The Finder provides a different user interface for accessing local disks.)  In macOS 10.7 and later, the Finder also hides the
        # `~/Library` directory—that is, the `Library` directory located in the user’s home directory.  This case is handled by `_isinvisible`.
        
        
        #=== Case 4: Packages and bundles ===#
        # Packages and bundles are directories that the Finder presents to the user as if they were files.  Bundles hide the internal workings 
        # of executables such as apps and just present a single entity that can be moved around the file system easily.  Similarly, packages 
        # allow apps to implement complex document formats consisting of multiple individual files while still presenting what appears to be a 
        # single document to the user.
        
        # https://developer.apple.com/documentation/coreservices/kmditemcontenttypetree
        const K_MDITEM_CONTENT_TYPE_TREE = _cfstring_create_with_cstring("kMDItemContentTypeTree")
        
        # https://superuser.com/questions/1739420/
        # https://stackoverflow.com/a/9858910/12069968
        # https://github.com/osquery/osquery/blob/598983db97459f858e7a9cc5c731409ffc089b48/osquery/tables/system/darwin/extended_attributes.cpp#L111-L144
        # https://github.com/objective-see/ProcInfo/blob/ec51090fcf741a9e045dd3e5119cb5cc8750efd3/procInfo/Binary.m#L121-L172
        # NOTE: this function will fail if you give it f as "/"
        function _k_mditem_content_type_tree(f::AbstractString, str_encoding::Unsigned = CF_STRING_ENCODING)
            cfstr = _cfstring_create_with_cstring(f, str_encoding)
            mditem = _mditem_create(cfstr)
            mdattrs = _mditem_copy_attribute(mditem, K_MDITEM_CONTENT_TYPE_TREE)
            # TODO: release/free mditem
            cfarr_len = _cfarray_get_count(mdattrs)
            content_types = String[]
            for i in 0:(cfarr_len - 1)
                attr = _cfarray_get_value_at_index(mdattrs, i)
                if attr != C_NULL #&& !iszero(_cfstring_get_length(attr))
                    push!(content_types, _string_from_cf_string(attr, str_encoding))
                end
            end
            return content_types
            # TODO: release/free mdattrs
        end
        
        # https://stackoverflow.com/a/12233785
        # Bundles: https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFBundles/AboutBundles/AboutBundles.html
        # Packages: https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFBundles/DocumentPackages/DocumentPackages.html
        const PKG_BUNDLE_TYPES = ("com.apple.package", "com.apple.bundle", "com.apple.application-bundle")
        _ispackage_or_bundle(f::AbstractString) = any(t ∈ PKG_BUNDLE_TYPES for t in _k_mditem_content_type_tree(f))
        
        # If a file or directory exists inside a package or bundle, then it is hidden.  Packages or bundles themselves
        # are not necessarily hidden.
        function _exists_inside_package_or_bundle(f::AbstractString)
            # This function necessitates that f has is modified with the realpath function, as if it hasn't,
            # it is possible that f has a trailing slash, meaning its dirname is still itself
            f = dirname(realpath(f))
            
            # We can't check the root directory, as this doesn't have any metadata information, so
            # _k_mditem_content_type_tree will fail.  Otherwise, we start at the parent directory of the
            # given file, and check if any of its parents are packages or bundles.
            while f != "/"
                _ispackage_or_bundle(f) && return true
                f = dirname(f)
            end            
            return false
        end
        
        
        #=== All macOS cases ===#
        _ishidden_macos(f::AbstractString) = _ishidden_bsd_related(f) || _issystemfile(f) || _exists_inside_package_or_bundle(f)
        _ishidden = _ishidden_macos
    elseif Sys.isbsd()  # BSD; this excludes macOS through control flow (as macOS is checked for first)
        _ishidden_bsd(f::AbstractString) = _ishidden_bsd_related(f)
        _ishidden = _ishidden_bsd
    else  # General UNIX
        _ishidden = _ishidden_unix
    end
elseif Sys.iswindows()
    # https://docs.microsoft.com/en-us/windows/win32/fileio/file-attribute-constants
    # https://github.com/SublimeText/Pywin32/blob/753322f9ac4b943c2c04ddd88605e68bc742dbb4/lib/x32/win32/lib/win32con.py#L2128-L2129
    # https://github.com/retep998/winapi-rs/blob/5b1829956ef645f3c2f8236ba18bb198ca4c2468/src/um/winnt.rs#L4081-L4082
    const FILE_ATTRIBUTE_HIDDEN = 0x2
    const FILE_ATTRIBUTE_SYSTEM = 0x4
    
    function _ishidden_windows(f::AbstractString)
        # https://docs.microsoft.com/en-gb/windows/win32/api/fileapi/nf-fileapi-getfileattributesa
        # DWORD GetFileAttributesA([in] LPCSTR lpFileName);
        f_attrs = ccall(:GetFileAttributesA, UInt32, (Cstring,), f)
        
        # https://stackoverflow.com/a/1343643/12069968
        # https://stackoverflow.com/a/14063074/12069968
        return !iszero(f_attrs & (FILE_ATTRIBUTE_HIDDEN | FILE_ATTRIBUTE_SYSTEM))
    end
    _ishidden = _ishidden_windows
else
    _ishidden(f::AbstractString) = error("hidden files for this OS need to be defined")
end


# Each OS branch defines its own _ishidden function.  In the main ishidden function, we check that the path exists, expand
# the real path out, and apply the branch's _ishidden function to that path to get a final result
function ishidden(f::AbstractString)
    ispath(f) || throw(Base.uv_error("ishidden($(repr(f)))", Base.UV_ENOENT))
    return _ishidden(f)
end


end  # end module

