var documenterSearchIndex = {"docs":
[{"location":"#HiddenFiles.jl-Documentation","page":"Index","title":"HiddenFiles.jl Documentation","text":"","category":"section"},{"location":"","page":"Index","title":"Index","text":"","category":"page"},{"location":"","page":"Index","title":"Index","text":"CurrentModule = HiddenFiles\nDocTestSetup = quote\n    using HiddenFiles\nend","category":"page"},{"location":"#Adding-HiddenFiles.jl","page":"Index","title":"Adding HiddenFiles.jl","text":"","category":"section"},{"location":"","page":"Index","title":"Index","text":"using Pkg\nPkg.add(\"HiddenFiles\")","category":"page"},{"location":"#Documentation","page":"Index","title":"Documentation","text":"","category":"section"},{"location":"","page":"Index","title":"Index","text":"ishidden","category":"page"},{"location":"#Main.HiddenFiles.ishidden","page":"Index","title":"Main.HiddenFiles.ishidden","text":"ishidden(f::AbstractString)\n\nCheck if a file or directory is hidden.\n\nOn Unix-like systems, a file or directory is hidden if it starts with a full stop/period (U+002e).  On Windows systems, this function will parse file attributes to determine if the given file or directory is hidden.\n\nnote: Note\nDirectory references (i.e., . or ..) are always hidden.  To check if the underlying path is hidden, you should run ishidden on its realpath.\n\nnote: Note\nOn Unix-like systems, in order to correctly determine if the file begins with a full stop, we must first expand the path to its real path.\n\nnote: Note\nOn operating systems deriving from BSD (i.e., *BSD, macOS), this function will also check the st_flags field from stat to check if the UF_HIDDEN flag has been set.\n\nnote: Note\nOn macOS, any file or directory within a package or a bundle will also be considered hidden.\n\nnote: Note\nThere may be some UNIX-specific system directories in macOS that are not yet classified as hidden (#18).\n\nnote: Note\nMount points on ZFS are not yet classified as hidden (#20).\n\n\n\n\n\n","category":"function"}]
}
