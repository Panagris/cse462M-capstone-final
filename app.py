"""
File: app.py
Authors: B. Ko, C. Okoye, S. Xiao
"""

from flask import Flask, jsonify, request, render_template, redirect, url_for
import base64
import numpy as np
import cv2
from convolver_dma import Application

app = Flask(__name__)
accel_app = Application("full_cnn.bit")


@app.route("/")
def home():
    return render_template("demo_website.html")


def encode_image_tobase64(image):
    # Convert RGB to BGR for OpenCV encoding
    image_bgr = cv2.cvtColor(image, cv2.COLOR_RGB2BGR)
    _, buffer = cv2.imencode(".png", image_bgr)
    img_base64 = base64.b64encode(buffer).decode("utf-8")
    return img_base64


@app.route("/submit", methods=["POST"])
def submit():
    if "image" not in request.files:
        return jsonify({"error": "No image part in the request"}), 400

    file = request.files["image"]
    if file.filename == "":
        return jsonify({"error": "No selected file"}), 400

    try:
        import tempfile

        # Save to disk and load with cv2.imread like testbench
        with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as tmp:
            file.save(tmp.name)
            bgr_img = cv2.imread(tmp.name)

        if bgr_img is None:
            return jsonify({"error": "Invalid image file"}), 400

        print("Parsed Image.")

        # Face detection exactly like testbench
        gray = cv2.cvtColor(bgr_img, cv2.COLOR_BGR2GRAY)
        face_cascade = cv2.CascadeClassifier(
            "/usr/share/opencv4/haarcascades/haarcascade_frontalface_default.xml"   
        )
        faces = face_cascade.detectMultiScale(gray, 1.3, 5)

        if len(faces) == 0:
            return jsonify({"error": "No face detected"}), 400

        # Crop face (first one)
        x, y, w, h = faces[0]
        cropped = bgr_img[y:y+h, x:x+w]

        # Resize to 480×480
        FIXED_IMAGE_SIZE = (480, 480)
        resized = cv2.resize(cropped, FIXED_IMAGE_SIZE)

        # Red channel from BGR
        r_channel = resized[:, :, 2]
        g_channel = resized[:, :, 1]
        b_channel = resized[:, :, 0]

        # FPGA convolution
        accel_app.create_overlay()
        print("Overlay created.")
        accel_app.setup_accelerator_adaptor_core()
        print("Done with acc adaptor core setup.")
        accel_app.convolve_image(b_channel)
        # accel_app.convolve_image_timed(b_channel) # If timing is desired.

        # Stack for visualization
        r_img = np.stack((r_channel, np.zeros_like(r_channel), np.zeros_like(r_channel)), axis=-1)
        g_img = np.stack((np.zeros_like(g_channel), g_channel, np.zeros_like(g_channel)), axis=-1)
        b_img = np.stack((np.zeros_like(b_channel), np.zeros_like(b_channel), b_channel), axis=-1)

        r_base64 = encode_image_tobase64(r_img.astype(np.uint8))
        g_base64 = encode_image_tobase64(g_img.astype(np.uint8))
        b_base64 = encode_image_tobase64(b_img.astype(np.uint8))

        return render_template(
            "number.html",
            r_img=r_base64,
            g_img=g_base64,
            b_img=b_base64
        )

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/number/<filename>")
def show_processed_image(filename):
    return render_template("number.html", filename=filename)


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0")