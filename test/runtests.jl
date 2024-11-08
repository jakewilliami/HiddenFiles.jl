using HiddenFiles
using Test

@testset "HiddenFiles.jl" begin
    randpath(path_len::Integer = 64) = String(rand(Char, path_len))  # this path shouldn't exist

    @static if Sys.isunix()
        function mk_temp_dot_file(parent::String = tempdir())
            tmp_hidden = joinpath(parent, '.' * basename(tempname()))
            touch(tmp_hidden)
            return tmp_hidden
        end

        p, p′ = mk_temp_dot_file(), mk_temp_dot_file(homedir())

        @testset "HiddenFiles.jl—General UNIX" begin
            @test ishidden(p)
            @test !ishidden(homedir())
            @test_throws Union{Base.IOError, SystemError} HiddenFiles.ishidden("~/$(basename(p′))")
            @test HiddenFiles.ishidden(expanduser("~/$(basename(p′))"))
        end

        @static if Sys.isapple()
            @testset "HiddenFiles.jl—macOS" begin
                # Case 1: Dot directories and files
                @test ishidden(p)
                @test !ishidden(homedir())

                # Case 2: UNIX-specific directories
                # TODO: complete this case
                @test HiddenFiles.ishidden("/bin/")
                @test HiddenFiles.ishidden("/dev/")
                @test HiddenFiles.ishidden("/usr/")
                @test !HiddenFiles.ishidden("/tmp/")

                # Case 3: Explicitly hidden files and directories
                @test HiddenFiles._isinvisible("/Volumes")
                @test ishidden("/Volumes")
                @test !HiddenFiles._isinvisible(p′)

                # Case 4: Packages and bundles
                @test !ishidden("/System/Applications/Utilities/Terminal.app")
                @test ishidden("/System/Applications/Utilities/Terminal.app/Contents")
                @test ishidden("/System/Applications/Utilities/Terminal.app/Contents/../../Terminal.app/Contents")
                @test ishidden("/////System/Applications/Utilities/Terminal.app/Contents/../Contents")
                @test ishidden("/System/Applications/Utilities/Terminal.app/Contents/../Contents///MacOS////../MacOS/../../Contents/MacOS/Terminal///")
                @test !ishidden("/")
                @test ishidden("/System/Applications/Utilities/Terminal.app/Contents/")  # This should be the same as above, as we expand all paths using realpath
                @test !HiddenFiles._ispackage_or_bundle("/System/Applications/Utilities/Terminal.app/Contents/")
                @test HiddenFiles._exists_inside_package_or_bundle("/System/Applications/Utilities/Terminal.app/Contents/")
                @test !HiddenFiles._exists_inside_package_or_bundle("/bin/")
                f = randpath()
                cfstr_nonexistent = HiddenFiles._cfstring_create_with_cstring(f)
                @test_throws Exception HiddenFiles._mditem_create(cfstr_nonexistent)
                encoding_mode_nonexistent = 0x1c000101  # this encoding mode should not exist
                @test_throws Exception HiddenFiles._cfstring_create_with_cstring(
                    "Julia", encoding_mode_nonexistent
                )
                cfstr = HiddenFiles._cfstring_create_with_cstring(@__FILE__)
                mditem = HiddenFiles._mditem_create(cfstr)
                cfattr_nonexistent = HiddenFiles._cfstring_create_with_cstring("kMDItemNonexistentAttributeName")
                @test_throws Exception HiddenFiles._mditem_copy_attribute(
                    mditem, cfattr_nonexistent
                )
            end
        elseif Sys.isbsd()
            # TODO: should we not only support FreeBSD?  Are we testing on other BSD systems?  OpenBSD?
            @testset "HiddenFiles.jl—FreeBSD" begin
                @test ishidden(p)
                @test !HiddenFiles._isinvisible(p)
                @test ishidden(p′)
                @test !HiddenFiles._isinvisible(p′)
                @test !ishidden(homedir())
                @test !ishidden("/bin/")
                @test !ishidden("/dev/")
                @test !ishidden("/usr/")
                @test !ishidden("/mnt/")
                @test !ishidden("/tmp/")
            end
        else
            @testset "HiddenFiles.jl—UNIX excluding macOS" begin
                @test ishidden(p)
                @test ishidden(p′)
                @test !ishidden(homedir())
                @test !ishidden("/bin/")
                @test !ishidden("/dev/")
                @test !ishidden("/usr/")
                @test !ishidden("/mnt/")
                @test !ishidden("/tmp/")
            end
        end

        rm(p)
        rm(p′)
    elseif Sys.iswindows()
        @testset "HiddenFiles.jl—Windows" begin
            @test !ishidden("C:\\Windows\\system32\\")
            @test !ishidden("C:\\Windows\\explorer.exe")
            @test !ishidden("C:\\Windows\\system32\\rundll32.exe")
            @test !ishidden("C:\\Temp\\")
            @test ishidden("C:\\ProgramData")
            @test ishidden("C:\\ProgramData\\Desktop")
            @test !ishidden("C:\\ProgramData\\Package Cache")
        end
    else
        @testset "HiddenFiles.jl—Else branch (invalid OS)" begin
            # TODO
            @test false
        end
    end

    @testset "HiddenFiles.jl—Path Handling (PathStruct)" begin
        @static if Sys.isunix()
            bin_rp = Sys.islinux() ? "/usr/bin" : "/bin"

            @test HiddenFiles.PathStruct("/bin", bin_rp) isa HiddenFiles.PathStruct
            @test HiddenFiles.PathStruct("/../bin", bin_rp) isa HiddenFiles.PathStruct
            @test_throws HiddenFiles.InvalidRealPathError HiddenFiles.PathStruct(
                "/bin", "/../bin"
            )
            @test HiddenFiles.PathStruct("/../bin").realpath == bin_rp
            @test HiddenFiles.PathStruct(".").path == "."

        elseif Sys.iswindows()
            @test HiddenFiles.PathStruct("C:\\", "C:\\") isa HiddenFiles.PathStruct
            @test HiddenFiles.PathStruct("C:\\..\\", "C:\\") isa HiddenFiles.PathStruct
            @test_throws HiddenFiles.InvalidRealPathError HiddenFiles.PathStruct(
                "C:\\", "C:\\..\\"
            )
        else
            # TODO
            @test false
        end

        f = randpath()
        # Julia < 1.3 throws a SystemError when `realpath` fails
        @test_throws Union{Base.IOError, SystemError} HiddenFiles.PathStruct(f)
        @test_throws Union{Base.IOError, SystemError} HiddenFiles.PathStruct(f, "")
        # ishidden calls to PathStruct
        @test_throws Union{Base.IOError, SystemError} ishidden(f)
    end

    @testset "HiddenFiles.jl—Directory references" begin
        d = homedir()
        @test HiddenFiles.ishidden(".")
        @test HiddenFiles.ishidden(joinpath(d, "."))
        @test HiddenFiles.ishidden(joinpath(d, "..", "."))
        @test HiddenFiles.ishidden("..")
        @test HiddenFiles.ishidden(joinpath(d, ".."))
    end
end
