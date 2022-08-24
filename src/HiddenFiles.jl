module HiddenFiles

export ishidden

if Sys.isunix()
    if Sys.isapple()
        # https://developer.apple.com/documentation/coreservices/lsiteminfoflags/klsiteminfoisinvisible
        const KLS_ITEM_INFO_IS_INVISIBLE = 0x00000040
        # https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/chflags.2.html
        # https://github.com/python/cpython/blob/16ebae4cd4029205d932751f26c719c6cb8a6e92/Lib/stat.py#L120
        const UF_HIDDEN = 0x00008000
        # https://developer.apple.com/documentation/coreservices/lsiteminfoflags
        # https://opensource.apple.com/source/hfs/hfs-366.1.1/core/hfs_format.h.auto.html
        const SV_FLAGS_STAT_OFFSET = 0x15  # 21, or 11 if we store results in 64-bits
        const STATBUF_SZ = 0x24
        function _sv_flags(f::AbstractString)
            statbuf = Vector{UInt32}(undef, STATBUF_SZ)
            ccall(:jl_lstat, Int32, (Cstring, Ptr{UInt8}), f, statbuf)
            return statbuf[SV_FLAGS_STAT_OFFSET]
        end
        
        # _isinvisible(f::AbstractString) = !iszero(_sv_flags(f) & KLS_ITEM_INFO_IS_INVISIBLE)  # https://stackoverflow.com/a/1140345/12069968
        # _isinvisible(f::AbstractString) = !iszero(_sv_flags(f) | UF_HIDDEN)  # https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/chflags.2.html
        # _isinvisible(f::AbstractString) = !iszero(_sv_flags(f) & ~UF_HIDDEN)  # https://github.com/dotnet/runtime/issues/25989#issuecomment-446783766
        _isinvisible(f::AbstractString) = (_sv_flags(f) & UF_HIDDEN) == UF_HIDDEN  # https://github.com/davidkaya/corefx/blob/4fd3d39f831f3e14f311b0cdc0a33d662e684a9c/src/System.IO.FileSystem/src/System/IO/FileStatus.Unix.cs#L88
        _ishidden(f::AbstractString) = startswith(".", basename(f)) || _isinvisible(f)
    else
        _ishidden(f::AbstractString) = startswith(".", basename(f))
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

