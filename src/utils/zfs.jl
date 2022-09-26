@static if Sys.isapple()
    # macOS: https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/statfs.2.html
    
    const SIZEOF_STATFS = 2168
    const SIZEOF_STATFS64 = 2168
    const MACOS_F_OTYPE_OFFSET = 13  # 
    
    function iszfs()
        error("not yet implemented")
        buf = zeros(UInt, 2048); ccall(:statfs, Int, (Cstring, Ptr{Cvoid}), "/", buf)  # buf[0x0d] => 0x00
        buf = zeros(UInt32, 2048); ccall(:statfs64, Int, (Cstring, Ptr{Cvoid}), "/", buf) # buf[0x13] => 0x73667061
    end
elseif Sys.isbsd()
    const SIZEOF_STATFS = 2344
    
    # BSD: https://www.freebsd.org/cgi/man.cgi?query=statfs&sektion=2
    const BSD_F_TYPE_OFFSET = 0x03  # 2 in UInt64, but 3 in UInt32
    
    function iszfs()
        error("not yet implemented")
        buf = zeros(UInt32, 2048); ccall(:statfs, Int, (Cstring, Ptr{Cvoid}), "/", buf)  # buf[0x03] => 0x10001010
    end
elseif Sys.isunix()
    # Linux: https://man7.org/linux/man-pages/man2/statfs.2.html
    function iszfs()
        error("not yet implemented")
        buf = zeros(UInt32, 2048); ccall(:statfs, Int, (Cstring, Ptr{Cvoid}), "/", buf)  # 
    end
else
    iszfs() = error("Cannot call statfs for non-unix operating systems")
end

