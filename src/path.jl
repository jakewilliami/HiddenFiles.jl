struct InvalidRealPathError <: Exception
    msg::String
    expected::AbstractString
    actual::AbstractString
end

function Base.showerror(io::IO, e::InvalidRealPathError)
    print(io, typeof(e), ": ", e.msg, ": ")
    print(io, "Invalid real path: expected ", '"', e.expected, '"', ", ")
    print(io, "found ", '"', e.actual, '"')
end

struct PathStruct
    path::AbstractString
    realpath::AbstractString

    function PathStruct(path::AbstractString, rp::AbstractString)
        ispath(rp) || throw(Base.uv_error("PathStruct($(repr(path)))", Base.UV_ENOENT))
        # TODO: this will fail if path is not valid
        realpath(path) == rp ||
            throw(InvalidRealPathError("PathStruct($(repr(path)))", realpath(path), rp))
        return new(path, rp)
    end

    # Each OS branch defines its own _ishidden functions, some of which require the
    # user-provided path, and some of which require a real path.  To easily maintain
    # both of these, we pass around a PathStruct containing both information.  If
    # PathStruct is constructed with one positional argument, it attempts to construct
    # the real path of the file (and will error with an IOError or SystemError if it fails).
    function PathStruct(path::AbstractString; err_prefix::Symbol = :ishidden)
        # If path does not exist, `realpath` will error™
        local rp::String
        try
            rp = realpath(path)
        catch e
            err_prexif = "$(err_prefix)(PathStruct($(repr(path))))"
            # Julia < 1.3 throws a SystemError when `realpath` fails
            isa(e, SystemError) && throw(SystemError(err_prexif, e.errnum))
            # Julia ≥ 1.3 throws an IOError, constructed from UV Error codes
            isa(e, Base.IOError) && throw(Base.uv_error(err_prexif, e.code))
            # If this fails for some other reason, rethrow
            rethrow()
        end

        # Julia < 1.2 on Windows does not error on `realpath` if path does not exist, so we
        # must do so manually here
        ispath(rp) || throw(Base.uv_error("$(err_prefix)(PathStruct($(repr(path))))", Base.UV_ENOENT))

        # If we got here, the path exists, and we can continue safely construct our PathStruct
        # for our _ishidden tests
        return new(path, rp)
    end
end
