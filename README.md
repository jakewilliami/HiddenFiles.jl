<h1 align="center">HiddenFiles.jl</h1>

<!-- [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://jakewilliami.github.io/HiddenFiles.jl/stable) -->
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://jakewilliami.github.io/HiddenFiles.jl/dev)
[![CI](https://github.com/jakewilliami/HiddenFiles.jl/workflows/CI/badge.svg?branch=master)](https://github.com/jakewilliami/HiddenFiles.jl/workflows/CI/badge.svg?branch=master)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)


A simple tool to determine if a file directory is hidden.  Works on any&trade; file system!

## Quick Start

```julia
julia> using HiddenFiles

julia> is_hidden("$(homedir())/.bashrc")
```

## History

The origin of this project comes from [`julia#38841`](https://github.com/JuliaLang/julia/issues/38841).

