using HiddenFiles
using Test

@testset "HiddenFiles.jl" begin
    @test HiddenFiles._isinvisible("/Volumes")
    @test ishidden("/Volumes")
    @test !HiddenFiles._isinvisible("($(homedir()))/.bashrc")
    @test ishidden("$(homedir())/.bashrc")
    @test !ishidden("$(homedir())/Desktop")
end
