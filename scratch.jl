#=
- (can't subtype, use fn) Make JsonResponse as a subtype of HTTP response
- Create logger
- macro w/in macro => HTTP.@register (working for now)
- Handle route path variables
=#
module Hapi

import HTTP
import URIs
import Sockets
import JSON2
import MsgPack
import Dates

const APP = HTTP.Router()

const GET = :GET
const POST = :POST
const PUT = :PUT
const DELETE = :DELETE

const LOCALHOST = Sockets.localhost

const CONTENT_TYPES = Dict{Symbol,String}(
  :text       => "text/plain",
  :json       => "application/json",
  :msgpack    => "application/x-msgpack",
)


"""
    @trycatch expr
    
Convenience macro which wraps an expression in a `try/catch` block.
If the expression throws an error, it will be printed with the 
`@error` macro.
# Examples
julia> @trycatch 1 + 1
2
julia> @trycatch 1 + "dog"
┌ Error: MethodError(+, (1, "dog"), 0x0000000000006cbc)
└ @ Main REPL[13]:6
"""
macro trycatch(expr)
    quote
        try
            $expr
        catch err
            @error err
        end
    end
end


# Functions for Response Types

function text(data::Any ; status::Int = 200, header::Array{Pair{String,String},1} = Pair{String,String}[])
    HTTP.Response(
        status,
        ["Content-Type" => CONTENT_TYPES[:text], header...];
        body = string(data)
    )
end

function json(data::Any ; status::Int = 200, header::Array{Pair{String,String},1} = Pair{String,String}[])
    HTTP.Response(
        status,
        ["Content-Type" => CONTENT_TYPES[:json], header...];
        body = JSON2.write(data)
    )
end

function msgpack(data::Any ; status::Int = 200, header::Array{Pair{String,String},1} = Pair{String,String}[])
    HTTP.Response(
        status,
        ["Content-Type" => CONTENT_TYPES[:msgpack], header...];
        body = MsgPack.pack(data)
    )
end

# Macros for handling GET, POST, 
# PUT, DELETE requests

macro get(path::String, response)
    HTTP.@register(
        APP,
        :GET,
        path,
        response
    )
end

macro post(path::String, response)
    HTTP.@register(
        APP,
        :POST,
        path,
        response
    )
end

macro put(path::String, response)
    HTTP.@register(
        APP,
        :PUT,
        path,
        response
    )
end

macro delete(path::String, response)
    HTTP.@register(
        APP,
        :DELETE,
        path,
        response
    )
end

# Logger function
function log_request()

end

# Functions to Serve the App

function serve(host=LOCALHOST, port=8081; kw...)
    try
        HTTP.serve(
            APP,
            host,
            port;
            tcpisvalid = sock -> begin

            end,
            kw...
        )
    catch e
        @error e
    end
end

function serve_async(host=LOCALHOST, port=8081; kw...)
    @async HTTP.serve(APP,host,port,kw...)
end

export 
    APP,
    LOCALHOST,
    text, json, msgpack,
    @get, @post, @put, @delete,
    serve, serve_async

end # module

############################################

# using HTTP
# using JSON
using .Hapi

@info "Starting module..."

@get "/" (r::HTTP.Request -> begin
    msgpack(Dict(
        "hello" => "world",
        "dogs" => 3
    ))
end)

serve(LOCALHOST, 8081)

@info "Done."
