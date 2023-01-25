Shader "Unlit/raymarch_cube"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #define MAX_STEPS 100
            #define MAX_DIST 100
            #define SURF_DIST 0.001

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 ro : TEXCOORD1;
                float3 hitPos : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.ro = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1));
                o.hitPos = v.vertex;
                return o;
            }

            float getDist(float3 p) {
                float distance = length(p) - 0.5;
                distance = length(float2(length(p.xz) - 0.5, p.y)) - 0.1;
                return distance;
            }
            float3 getNormal(float3 p) {
                float2 e = float2(0.01, 0);
                float3 n = getDist(p) - float3(
                    getDist(p - e.xyy),
                    getDist(p - e.yxy),
                    getDist(p - e.yyx)
                    );

                return normalize(n);
            }
            float raymarch(float3 ro, float3 rd) {
                float distance = 0;
                float distance_surface;
                for (int i = 0; i < MAX_STEPS; i++) {
                    float3 p = ro + rd * distance;
                    distance_surface = getDist(p);
                    distance += distance_surface;
                    if (distance_surface < SURF_DIST || distance > MAX_DIST) {
                        break;
                    }
                }
                return distance;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = 0;
                float2 uv = i.uv-0.5;
                float3 ro = i.ro;
                float3 rd = normalize(i.hitPos-ro);
                float d = raymarch(ro,rd);
                if (d < MAX_DIST) {
                    float3 p = ro + rd * d;
                    float3 n = getNormal(p);
                    col.rgb = n;
                }
                else {
                    discard;
                }
                //col.rgb = rd;
                return col;
            }
            ENDCG
        }
    }
}
