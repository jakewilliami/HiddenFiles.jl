<h1 align="center">HiddenFiles.jl</h1>

<!-- [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://jakewilliami.github.io/HiddenFiles.jl/stable) -->
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://jakewilliami.github.io/HiddenFiles.jl/dev)
[![CI](https://github.com/jakewilliami/HiddenFiles.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/jakewilliami/HiddenFiles.jl/actions/workflows/CI.yml?query=branch%3Amaster)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)


A simple tool to determine if a file directory is hidden.  Works on any&trade; OS and file system!

This library exports one function: `ishidden`.  Typically, a file or directory is classified as "hidden" if is it hidden from a normal directory listing.  See [the documentation](https://jakewilliami.github.io/HiddenFiles.jl/dev) for notes on the behaviour of `ishidden`.

## Quick Start

```julia
julia> using HiddenFiles

julia> is_hidden("$(homedir())/.bashrc")
true
```

## History

The origin of this project comes from [`julia#38841`](https://github.com/JuliaLang/julia/issues/38841).

## Citation

If your research depends on HiddenFiles.jl, please consider giving us a formal citation: [`citation.bib`](./citation.bib).
