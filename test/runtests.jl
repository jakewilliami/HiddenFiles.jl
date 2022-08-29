using HiddenFiles
using Test
@testset "HiddenFiles.jl" begin
    @static if Sys.isunix()
        @testset "HiddenFiles.jl—General UNIX" begin
            @test ishidden("$(homedir())/.bashrc")
            @test !ishidden("$(homedir())/Desktop")
            @test_throws Base.IOError HiddenFiles.ishidden("~/.bashrc")
            @test HiddenFiles.ishidden(expanduser("~/.bashrc"))
        end
        
        @static if Sys.isapple()
            @testset "HiddenFiles.jl—macOS" begin
                # Case 1: Dot directories and files
                @test ishidden("$(homedir())/.bashrc")
                @test !ishidden("$(homedir())/Desktop")
                
                # Case 2: UNIX-specific directories
                # TODO: complete this case
                @test HiddenFiles.ishidden("/bin/")
                
                # Case 3: Explicitly hidden files and directories
                @test HiddenFiles._isinvisible("/Volumes")
                @test ishidden("/Volumes")
                @test !HiddenFiles._isinvisible("$(homedir())/.bashrc")
                
                # Case 4: Packages and bundles
                @test !ishidden("/System/Applications/Utilities/Terminal.app")
                @test ishidden("/System/Applications/Utilities/Terminal.app/Contents")
                @test ishidden("/System/Applications/Utilities/Terminal.app/Contents/")  # This should be the same as above, as we expand all paths using realpath
                @test !HiddenFiles._ispackage_or_bundle("/System/Applications/Utilities/Terminal.app/Contents/")
                @test HiddenFiles._exists_inside_package_or_bundle("/System/Applications/Utilities/Terminal.app/Contents/")
                @test !HiddenFiles._exists_inside_package_or_bundle("/bin/")
                f = String(rand(Char, 32))  # this path shouldn't exist
                cfstr = HiddenFiles._cfstring_create_with_cstring(f)
                @test_throws Exception HiddenFiles._mditem_create(cfstr)
            end
        else
            @testset "HiddenFiles.jl—UNIX excluding macOS" begin
                # TODO
            end
        end
    elseif Sys.iswindows()
        @testset "HiddenFiles.jl—Windows" begin
            # TODO
        end
    else
        @testset "HiddenFiles.jl—Else branch (invalid OS)" begin
            # TODO
        end
    end
end
