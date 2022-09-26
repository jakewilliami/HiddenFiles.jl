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

# https://lists.freebsd.org/pipermail/freebsd-hackers/2018-February/052295.html
const SUN_ZFS_SUPER_MAGIC = 0x1b
const BSD_ZFS_SUPER_MAGIC = 0xde  # Obtained from testing
# https://reviews.freebsd.org/rS320069
const LINUX_ZFS_SUPER_MAGIC = 0x2fc12fc1

const ZFS_SUPER_MAGICS = (SUN_ZFS_SUPER_MAGIC, BSD_ZFS_SUPER_MAGIC, LINUX_ZFS_SUPER_MAGIC)

function iszfs(f::AbstractString)
    s = statfs(f)
    return s.ftype ∈ ZFS_SUPER_MAGICS
end


#=
#include <stdio.h>
#include <stddef.h>
#include <sys/param.h>
#include <sys/mount.h>

int main() {
	struct statfs st;
    printf("offsetof(struct statfs, f_type): 0x%lx\n", offsetof(struct statfs, f_type));
	statfs("/", &st);
	printf("st.f_type: 0x%llx\n", (uint64_t) st.f_type);
    return 0;
}

=#

@static if Sys.isapple()
    # macOS: https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/statfs.2.html

    const SIZEOF_STATFS = 2168
    const SIZEOF_STATFS64 = 2168
    const MACOS_F_OTYPE_OFFSET = 13  # 

    function iszfs()
        # 0x1a <- offset 69 in UInt8 array in statfs, 53 in UInt8 array in statfs64
        # error("not yet implemented")
        buf = zeros(UInt8, SIZEOF_STATFS)  ## 64
        ccall(:statfs, Int, (Cstring, Ptr{Cvoid}), "/", buf)  # buf[0x0d] => 0x00
        # return buf
        
        buf = zeros(UInt8, SIZEOF_STATFS64)  ## 32
        ccall(:statfs64, Int, (Cstring, Ptr{Cvoid}), "/", buf) # buf[0x13] => 0x73667061
        return buf
    end
elseif Sys.isbsd()
    const SIZEOF_STATFS = 2344

    # BSD: https://www.freebsd.org/cgi/man.cgi?query=statfs&sektion=2
    const BSD_F_TYPE_OFFSET = 0x03  # 2 in UInt64, but 3 in UInt32

    function iszfs()
        # 0xde <- offset 5 in UInt8 array
        # error("not yet implemented")
        buf = zeros(UInt8, SIZEOF_STATFS)  ## 32
        ccall(:statfs, Int, (Cstring, Ptr{Cvoid}), "/", buf)  # buf[0x03] => 0x10001010
        return buf
    end
elseif Sys.isunix()
    # Linux: https://man7.org/linux/man-pages/man2/statfs.2.html
    function iszfs()
        error("not yet implemented")
        buf = zeros(UInt8, error("NEED TO TEST sizeof(struct statfs) ON LINUX"))  ## 32
        ccall(:statfs, Int, (Cstring, Ptr{Cvoid}), "/", buf)  # 
        return buf
    end
else
    iszfs() = error("Cannot call statfs for non-unix operating systems")
end

