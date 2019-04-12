
import numpy as np
import moderngl as mg
import imageio as ii


def get_cs(path):
    with open(path, 'r') as fp:
        return fp.read()

width, height = 512, 512
gx, gy = int(width / 16), int(height / 16)

campos = (0.0, 1.0, -5.0)
look_at = (0.0, 0.0, 0.0)
light = (-2.0, 2.0, -2.0)


def main():
    gl = mg.create_standalone_context()
    cs_rm = gl.compute_shader(get_cs("./gl/rm.glsl"))
    cs_render = gl.compute_shader(get_cs("./gl/render.glsl"))

    if "u_width" in cs_rm:
        cs_rm["u_width"].value = width

    if "u_height" in cs_rm:
        cs_rm["u_height"].value = height

    if "u_width" in cs_render:
        cs_render["u_width"].value = width

    if "u_height" in cs_render:
        cs_render["u_height"].value = height

    if "u_eye" in cs_render:
        cs_render["u_eye"].value = campos

    if "u_lightpos" in cs_render:
        cs_render["u_lightpos"].value = light

    b_color = np.zeros(shape=(width, height, 4), dtype=np.float32)
    b_color = gl.buffer(b_color)
    b_color.bind_to_storage_buffer(0)

    b_normal = np.zeros(shape=(width, height, 4), dtype=np.float32)
    b_normal = gl.buffer(b_normal)
    b_normal.bind_to_storage_buffer(1)

    # raymarch
    cs_rm.run(gx, gy)

    out_buffer = np.zeros(shape=(width, height, 4), dtype=np.float32)
    out_buffer = gl.buffer(out_buffer)
    out_buffer.bind_to_storage_buffer(2)

    # render
    cs_render.run(gx, gy)

    data = out_buffer.read()
    data = np.frombuffer(data, dtype=np.float32)
    data = data.reshape((height, width, 4))
    data = data[::-1]
    data = np.multiply(data, 255.0)
    data = data.astype(np.uint8)
    ii.imwrite("result.png", data)


if __name__ == "__main__":
    main()
