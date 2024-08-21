from flask import Flask, request, jsonify
from facenet_pytorch import MTCNN, InceptionResnetV1
import torch
from PIL import Image
import io

app = Flask(__name__)

# Initialize MTCNN and Inception Resnet
mtcnn = MTCNN(keep_all=True, device='cpu')  # Change to 'cuda' if you have a GPU
model = InceptionResnetV1(pretrained='vggface2').eval()

def compare_faces(image1_stream, image2_stream):
    try:
        # Convert streams to PIL Images
        img1 = Image.open(image1_stream).convert('RGB')
        img2 = Image.open(image2_stream).convert('RGB')

        # Detect faces
        boxes1, _ = mtcnn.detect(img1)
        boxes2, _ = mtcnn.detect(img2)

        if boxes1 is None or boxes2 is None:
            return {"success": False, "message": "No face detected in one or both images"}

        # Get face embeddings
        embeddings1 = model(mtcnn(img1))
        embeddings2 = model(mtcnn(img2))

        if embeddings1.size(0) == 0 or embeddings2.size(0) == 0:
            return {"success": False, "message": "No face detected in one or both images"}

        # Compare faces
        distances = torch.cdist(embeddings1, embeddings2, p=2)  # Compute Euclidean distance
        match = distances.min().item() < 0.6  # Threshold for face matching

        return {"success": True, "match": match}
    except Exception as e:
        return {"success": False, "message": str(e)}

@app.route('/compare-faces', methods=['POST'])
def compare_faces_api():
    if 'image1' not in request.files or 'image2' not in request.files:
        return jsonify({"success": False, "message": "Images not provided"}), 400

    try:
        image1_stream = io.BytesIO(request.files['image1'].read())
        image2_stream = io.BytesIO(request.files['image2'].read())

        result = compare_faces(image1_stream, image2_stream)
        return jsonify(result)
    except Exception as e:
        return jsonify({"success": False, "message": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
