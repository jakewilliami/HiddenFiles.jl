# https://lists.freebsd.org/pipermail/freebsd-hackers/2018-February/052295.html
const SUN_ZFS_SUPER_MAGIC = 0x1b
const BSD_ZFS_SUPER_MAGIC = 0xde  # Obtained from testing
# https://reviews.freebsd.org/rS320069
const LINUX_ZFS_SUPER_MAGIC = 0x2fc12fc1

const ZFS_SUPER_MAGICS = (SUN_ZFS_SUPER_MAGIC, BSD_ZFS_SUPER_MAGIC, LINUX_ZFS_SUPER_MAGIC)

@static if VERSION ≥ v"1.6"
    @static if VERSION < v"1.8"
        # Adapted from Julia 1.8's diskstat: https://github.com/JuliaLang/julia/pull/42248
        # C calls for UV statfs requires Julia 1.6
        # http://docs.libuv.org/en/v1.x/fs.html#c.uv_fs_statfs
        struct DiskStat
            ftype::UInt64
            bsize::UInt64
            blocks::UInt64
            bfree::UInt64
            bavail::UInt64
            files::UInt64
            ffree::UInt64
            fspare::NTuple{4, UInt64} # reserved
        end
        function statfs(f::AbstractString)
            buf = Vector{UInt8}(undef, ccall(:jl_sizeof_uv_fs_t, Int32, ()))
            i = ccall(:uv_fs_statfs, Cint, (Ptr{Cvoid}, Ptr{Cvoid}, Cstring, Ptr{Cvoid}),
                      C_NULL, buf, f, C_NULL)
            i < 0 && Base.uv_error("statfs($(repr(f)))", i)
            p = ccall(:jl_uv_fs_t_ptr, Ptr{UInt32}, (Ptr{Cvoid},), buf)
            
            return unsafe_load(reinterpret(Ptr{DiskStat}, p))
        end
    else
        statfs = diskstat
    end
    
    function _iszfs(f::AbstractString)
        s = statfs(f)
        return s.ftype ∈ ZFS_SUPER_MAGICS
    end
else
    # If Julia version < 1.6, we have to write our own, not very nice solution
    @static if Sys.isapple()
        # macOS: https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/statfs.2.html
        const SIZEOF_STATFS = 2168
        const F_TYPE_OFFSET = 0x3d
        const F_FSSUBTYPE_OFFSET = 0x45
        
        function _iszfs(f::AbstractString)
            buf = Vector{UInt8}(undef, SIZEOF_STATFS)
            # statfs(const char *path, struct statfs *buf);
            i = ccall(:statfs, Int, (Cstring, Ptr{Cvoid}), f, buf)
            i < 0 && Base.uv_error("statfs($(repr(f)))", i)
            return buf[F_TYPE_OFFSET] ∈ ZFS_SUPER_MAGICS || buf[F_FSSUBTYPE_OFFSET] ∈ ZFS_SUPER_MAGICS
        end
    elseif Sys.isbsd()
        # https://www.freebsd.org/cgi/man.cgi?query=statfs&sektion=2
        const SIZEOF_STATFS = 2344
        const F_TYPE_OFFSET = 0x05
        
        function _iszfs(f::AbstractString)
            buf = Vector{UInt8}(undef, SIZEOF_STATFS)
            # statfs(const char *path, struct statfs *buf);
            i = ccall(:statfs, Int, (Cstring, Ptr{Cvoid}), f, buf)
            i < 0 && Base.uv_error("statfs($(repr(f)))", i)
            return buf[F_TYPE_OFFSET] ∈ ZFS_SUPER_MAGICS
        end
    elseif Sys.isunix()
        # Linux: https://man7.org/linux/man-pages/man2/statfs.2.html
        const SIZEOF_STATFS = error("not yet implemented")
        const F_TYPE_OFFSET = error("not yet implemented")
        
        function _iszfs(f::AbstractString)
            buf = zeros(UInt8, SIZEOF_STATFS)
            # statfs(const char *path, struct statfs *buf);
            i = ccall(:statfs, Int, (Cstring, Ptr{Cvoid}), f, buf)
            i < 0 && Base.uv_error("statfs($(repr(f)))", i)
            return buf[F_TYPE_OFFSET] ∈ ZFS_SUPER_MAGICS
        end
    else
        _iszfs(_f::AbstractString) = error("Cannot call statfs for non-Unix operating systems")
    end
end

