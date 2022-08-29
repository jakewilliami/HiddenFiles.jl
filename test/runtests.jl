using HiddenFiles
using Test

@static if Sys.isunix()
    @static if Sys.isapple()
        @testset "HiddenFiles.jl—macOS" begin
            @test HiddenFiles._isinvisible("/Volumes")
            @test ishidden("/Volumes")
            @test !HiddenFiles._isinvisible("($(homedir()))/.bashrc")
            @test ishidden("$(homedir())/.bashrc")
            @test !ishidden("$(homedir())/Desktop")
        end
    else
        @testset "HiddenFiles.jl—General UNIX" begin end
    end
elseif Sys.iswindows()
    @testset "HiddenFiles.jl—Windows" begin end
else
    @testset "HiddenFiles.jl—Else branch (invalid OS)" begin end
end


