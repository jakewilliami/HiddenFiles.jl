using HiddenFiles
using Test

@static if Sys.isunix()
    @static if Sys.isapple()
        @testset "HiddenFiles.jl—macOS" begin
            # Case 1: Dot directories and files
            @test ishidden("$(homedir())/.bashrc")
            @test !ishidden("$(homedir())/Desktop")
            
            # Case 2: UNIX-specific directories
            # TODO
            
            # Case 3: Explicitly hidden files and directories
            @test HiddenFiles._isinvisible("/Volumes")
            @test ishidden("/Volumes")
            @test !HiddenFiles._isinvisible("($(homedir()))/.bashrc")
            
            # Case 4: Packages and bundles
            @test !ishidden("/System/Applications/Utilities/Terminal.app")
            @test ishidden("/System/Applications/Utilities/Terminal.app/Contents")
            @test ishidden("/System/Applications/Utilities/Terminal.app/Contents/")  # This should be the same as above, as we expand all paths using realpath
            @test !HiddenFiles._ispackage_or_bundle("/System/Applications/Utilities/Terminal.app/Contents/")
            @test HiddenFiles._exists_inside_package_or_bundle("/System/Applications/Utilities/Terminal.app/Contents/")
        end
    else
        @testset "HiddenFiles.jl—General UNIX" begin
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


