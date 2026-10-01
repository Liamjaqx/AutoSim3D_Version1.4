shader_type canvas_item;
uniform float speed = .05;
void vertex() {
	UV.x += TIME * speed;
	UV.y += TIME * speed;
}