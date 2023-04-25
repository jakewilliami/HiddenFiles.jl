"""
```julia
_ishidden(f::AbstractString, rp::AbstractString) -> Bool
```

An alias for your system's internal `_ishidden_*` function.

This function also takes an expanded real path, as some internal functions neccesitate a real path.

The reason this is still an internal function is because the main [`ishidden`](@ref) function also checks the validity of the path, so that all internal functions can assume that the path exists.

See also: [`_ishidden_unix`](@ref), [`_ishidden_windows`](@ref), [`_ishidden_macos`](@ref), [`_ishidden_bsd`](@ref), [`_ishidden_zfs`](@ref).
"""
_ishidden

### ZFS ###
"This function is not yet implemented"
iszfs

"This function is not yet implemented"
_ishidden_zfs


### General Unix ###

"""
```julia
_isdotfile(f::AbstractString) -> Bool
```

Determines if a file or directory is hidden from ordinary directory listings by checking if it starts with a full stop/period (`U+002E`).

!!! note
    This function expects the path given to be a normalised/real path, so that the base name of the path can be correctly assessed.
"""
_isdotfile

"""
```julia
_ishidden_unix(f::AbstractString, rp::AbstractString) -> Bool
```

Determines if a file or directory is hidden from ordinary directory listings by checking if it starts with a full stop/period, or if it is a ZFS mount point on operating systems with a Unix-like interface.

See also: [`_isdotfile`](@ref), [`_ishidden_zfs`](@ref).

!!! note
    This function expects the path given to be a normalised/real path, so that the base name of the path can be correctly assessed.
"""
_ishidden_unix


### macOS/BSD ###

"""
```julia
const UF_HIDDEN = 0x00008000
```

The flag on macOS or BSD systems specifying whether the file may be hidden from directory.

See `chflags`:
  - [macOS](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/chflags.2.html)
  - [BSD](https://www.freebsd.org/cgi/man.cgi?query=chflags&sektion=2)
"""
UF_HIDDEN

"""
```julia
const ST_FLAGS_STAT_OFFSET = 0x15
```

In the absence of implementing a custom struct to represent the libuv `stat` struct, we need to keep track of the offset of the `st_flags` field.  This field is at offset 11 in the struct, or 21 as we are storing the results of the struct in a `Vector{UInt32}`.
"""
ST_FLAGS_STAT_OFFSET

"""
```julia
_st_flags(f::AbstractString) -> UInt32
```

Obtain the `st_flags` field from a `stat` call to a specified path.  The `st_flags` are user-defined (Finder) flags for the file or directory.

In the interest of cross-compatibility, we use [libuv's `stat` function](http://docs.libuv.org/en/v1.x/fs.html#c.uv_stat_t), which has a consistent `st_flags` offset across different systems (see [`ST_FLAGS_STAT_OFFSET`](@ref)).

!!! note
    As we are using `stat` rather than `lstat`, this function will not follow symbolic links.
"""
_st_flags

"""
```julia
_isinvisible(f::AbstractString) -> Bool
```

Determines if the specified file or directory is invisible/hidden, as defined by the Finder flags for the path.

See also: [`_st_flags`](@ref), [`UF_HIDDEN`](@ref).

!!! note
    This function expects that the file given to it is its real path.
"""
_isinvisible

"""
```julia
_ishidden_bsd_related(f::AbstractString, rp::AbstractString) -> Bool
```

Determines if a file or directory on a BSD-related system (i.e., macOS or BSD) is hidden from ordinary directory listings, as defined either by the Unix standard, or by user-defined flags.

See also: [`_ishidden_unix`](@ref), [`isinvisible`](@ref).
"""
_ishidden_bsd_related


### macOS ###

"""
Constant value for the string `"kMDItemContentTypeTree"` parsed as a CF String.
"""
K_MDITEM_CONTENT_TYPE_TREE

"""
```julia
_k_mditem_content_type_tree(f::AbstractString, str_encoding::Unsigned) -> Vector{String}
```

Find a list of the `KMDItemContentTypeTree` metadata of a given file or directory.

This function is the equivalent of running `mdls -name kMDItemContentTypeTree <filename>`.

See also: [`K_MDITEM_CONTENT_TYPE_TREE`](@ref).
"""
_k_mditem_content_type_tree

"""
```julia
const PKG_BUNDLE_TYPES = ("com.apple.package", "com.apple.bundle", "com.apple.application-bundle")
```

A file is considered a package or a bundle on macOS if its `kMDItemContentTypeTree` contains any of the following values:
  - `com.apple.package`
  - `com.apple.bundle`
  - `com.apple.application-bundle`
"""
PKG_BUNDLE_TYPES

"""
```julia
_ispackage_or_bundle(f::AbstractString) -> Bool
```

Determines whether the given path is a package or bundle on macOS.

See also: [`PKG_BUNDLE_TYPES`](@ref).
"""
_ispackage_or_bundle

"""
```julia
_exists_inside_package_or_bundle(f::AbstractString) -> Bool
```

Determines whether the given path exists inside a package or bundle on macOS.  If it does, the path will be considered hidden.

See also: [`_ispackage_or_bundle`](@ref), [`_ishidden_macos`](@ref)

!!! note
    This function necessitates/expects that the file given to it is its real path, as it is possible that the file provided has a trailing slash, meaning the first "parent" this function will check is itself.  This also makes relative paths much simpler to work with.
"""
_exists_inside_package_or_bundle

"""
```julia
_ishidden_macos(f::AbstractString, rp::AbstractString) -> Bool
```

Determines if the specified file or directory on macOS is hidden from ordinary directory listings.  There are a few conditions this function needs to check:
  1. Does the file's name start with a full stop/period?
  2. Is the file a part of the system's BSD layer?
  3. Is the file explicitly hidden by the user, or by Finder?
  4. Does the file exist inside a package or bundle?
  5. Is the file a ZFS mount point?

The file is considered hidden if any of these questions are true.

For more information on hidden files in macOS, please see [this article](https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/FileSystemOverview/FileSystemOverview.html#//apple_ref/doc/uid/TP40010672-CH2-SW7).

See also: [`_ishidden_unix`](@ref), [`_ishidden_bsd_related`](@ref), [`_isinvisible`](@ref), [`_issystemfile`](@ref), [`_exists_inside_package_or_bundle`](@ref), [`_ishidden_zfs`](@ref).
"""
_ishidden_macos


### BSD ###

"""
```julia
_ishidden_bsd(f::AbstractString, rp::AbstractString) -> Bool
```

Determines if the specified file or directory is hidden from ordinary directory listings by checking the following conditions:
  1. Does the file's name start with a full stop/period?
  2. Is the file explicitly hidden by the user, or by Finder?
  3. Is the file a ZFS mount point?

The file is considered hidden if any of these questions are true.

See also: [`_ishidden_unix`](@ref), [`_ishidden_bsd_related`](@ref), [`_isinvisible`](@ref), [`_ishidden_zfs`](@ref).
"""
_ishidden_bsd


### Windows ###

"""
```julia
 const FILE_ATTRIBUTE_HIDDEN = 0x2
```

A file attribute flag present if the file or directory is hidden (i.e., it is not included in an ordinary directory listing).
"""
FILE_ATTRIBUTE_HIDDEN

"""
```julia
const FILE_ATTRIBUTE_SYSTEM = 0x4
```

A file attribute flag present if the file or directory is used partly or exclusively by the operating system.
"""
FILE_ATTRIBUTE_SYSTEM

"""
```julia
_ishidden_windows(f::AbstractString, rp::AbstractString) -> Bool
```

Determine if the specified file or directory is hidden from ordinary directory listings for operating systems that are derivations of Microsoft Windows NT.

!!! note
    This function necessitates/expects that the file given to it is its real path.
"""
_ishidden_windows
