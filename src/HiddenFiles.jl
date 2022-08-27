module HiddenFiles

export ishidden

@static if Sys.isunix()
    @static if Sys.isapple()
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
        _ishidden(f::AbstractString) = startswith(basename(f), '.') || _isinvisible(f)
    else
        _ishidden(f::AbstractString) = startswith(basename(f), '.')
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

