//
//  Shaders.metal
//  MetalTest
//
//  Created by Corentin Faucher on 2018-10-12.
//  Copyright © 2018 Corentin Faucher. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    packed_float3 position;
    packed_float2 uv;
    packed_float3 normal;
};

struct VertexOut {
    float4 position [[position]];
    float2 uv;
    float4 color;
};

struct PerInstanceUniforms {
    float4x4 model;
    float4   color;
    float2   tile_ij;
    float    emph;
    int      flags;
};

struct PerTextureUniforms {
    float2 sizes;
    float2 dims;
};

struct PerFrameUniforms {
    float4x4 projection;
    float time;
    float unused1;
    float unused2;
    float unused3;
};

vertex VertexOut vertex_function(const device VertexIn       *vertices [[buffer(0)]],
                                 const device PerInstanceUniforms& piu [[buffer(1)]],
                                 const device PerFrameUniforms&    pfu [[buffer(2)]],
                                 const device PerTextureUniforms&  ptu [[buffer(3)]],
                                 unsigned int vid [[vertex_id]])
{
    VertexIn in = vertices[vid];
    VertexOut out;
    out.color = piu.color;
//    out.uv = in.uv;
    out.uv = (in.uv * (ptu.sizes - ptu.dims) + piu.tile_ij * ptu.sizes) / (ptu.dims * (ptu.sizes - 1));
    out.position =
     pfu.projection *
    piu.model *
    float4(in.position, 1);
    
    return out;
}

fragment float4 fragment_function(VertexOut interpolated [[ stage_in ]],
                                 texture2d<float> tex2D [[ texture(0)]],
                                 sampler sampler2D [[sampler(0)]])
{
//    return float4(0,1,0,0.5);
//    return tex2D[interpolated.textureID].sample(sampler2D, interpolated.uv);
    return tex2D.sample(sampler2D, interpolated.uv) * interpolated.color;
}
    
