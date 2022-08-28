module HiddenFiles

export ishidden

@static if Sys.isunix()
    _ishidden_unix(f::AbstractString) = startswith(basename(f), '.')
    
    @static if Sys.isapple()
        ### Hidden Files and Directories: Simplifying the User Experience ###
        ### https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/FileSystemOverview/FileSystemOverview.html ###
        
        ## Case 1: Dot directories and files ##
        # Any file or directory whose name starts with a period (`.`) character is hidden automatically.  This convention is taken from UNIX, 
        # which used it to hide system scripts and other special types of files and directories.  Two special directories in this category 
        # are the `.` and `..` directories, which are references to the current and parent directories respectively.  This case is handled by
        # _ishidden_unix
        
        
        ## Case 2: UNIX-specific directories ##
        # The directories in this category are inherited from traditional UNIX installations.  They are an important part of the system’s 
        # BSD layer but are more useful to software developers than end users. Some of the more important directories that are hidden include:
        #   - `/bin`—Contains essential command-line binaries. Typically, you execute these binaries from command-line scripts.
        #   - `/dev`—Contains essential device files, such as mount points for attached hardware.
        #   - `/etc`—Contains host-specific configuration files.
        #   - `/sbin`—Contains essential system binaries.
        #   - `/tmp`—Contains temporary files created by apps and the system.
        #   - `/usr`—Contains non-essential command-line binaries, libraries, header files, and other data.
        #   - `/var`—Contains log files and other files whose content is variable. (Log files are typically viewed using the Console app.)
        
        
        ## Case 3: Explicitly hidden files and directories ##
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
        
        
        ## Case 4: Packages and bundles ##
        # Packages and bundles are directories that the Finder presents to the user as if they were files.  Bundles hide the internal workings 
        # of executables such as apps and just present a single entity that can be moved around the file system easily.  Similarly, packages 
        # allow apps to implement complex document formats consisting of multiple individual files while still presenting what appears to be a 
        # single document to the user.
        
        # http://developer.apple.com/library/mac/#documentation/CoreFoundation/Conceptual/CFBundles/Introduction/Introduction.html/
        
        # https://opensource.apple.com/source/xnu/xnu-1228.0.2/bsd/sys/xattr.h.auto.html
        const XATTR_NOFOLLOW = 0x0001
        
        # https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/getxattr.2.html
        const XATTR_SIZE = 10_000
        function _getxattr(f::AbstractString, value_name::String)
            value = Vector{Char}(undef, XATTR_SIZE)
            value_len = ccall(:getxattr, Cssize_t, (Cstring, Cstring, Ptr{Cvoid}, Csize_t, UInt32), f, value_name, value, XATTR_SIZE, XATTR_NOFOLLOW)
            value_len == -1 && error("Couldn't get value \"$value_name\" from path \"$f\"")
            return value
        end
        
        # https://stackoverflow.com/a/12233785
        # https://developer.apple.com/documentation/coreservices/kmditemcontenttypetree?changes=lat____2&language=objc
        _kmd_item_content_type_tree(f::AbstractString) = _getxattr(f, "com.apple.metadata:_kMDItemContentTypeTree")
        PKG_BUNDLE_TYPES = ("com.apple.package", "com.apple.bundle", "com.apple.application-bundle")
        _ispackage_or_bundle(f::AbstractString) = any(t ∈ PKG_BUNDLE_TYPES for t in _kmd_item_content_type_tree(f))
        
        
        ## All together ##
        _ishidden(f::AbstractString) = any((_ishidden_unix(f), _isinvisible(f), _ispackage_or_bundle(f)))
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

ishidden(f::AbstractString) = ispath(f) && _ishidden(f)

end

