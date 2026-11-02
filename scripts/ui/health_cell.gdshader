shader_type canvas_item;
uniform vec4 region_uv;
void fragment() {
 vec2 local_uv = (UV - region_uv.xy) / region_uv.zw;
 // 单格斜边遮罩，排除原图邻格/框边像素，空格不会残留红色。
 if (local_uv.x < 0.30 * (1.0 - local_uv.y) + 0.02 || local_uv.x > 0.98 - 0.30 * local_uv.y) {
  discard;
 }
}
