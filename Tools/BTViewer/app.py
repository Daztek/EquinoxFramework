from flask import Flask, render_template, request, jsonify
from flask_socketio import SocketIO

app = Flask(__name__)
socketio = SocketIO(app, cors_allowed_origins="*")

@app.route("/")
def index():
    return render_template("index.html")

@socketio.on("update_dot")
def update_dot_socket(data):
    dot = data.get("dot")
    if dot:
        socketio.emit("render_dot", {"dot": dot})

@app.route("/update", methods=["POST"])
def update_dot_post():
    dot = request.form.get("dot") or (request.json and request.json.get("dot"))
    if not dot:
        return jsonify({"error": "No DOT data provided"}), 400

    def emit_dot():
        socketio.emit("render_dot", {"dot": dot}, namespace='/')

    socketio.start_background_task(emit_dot)
    return jsonify({"status": "ok", "message": "Graph updated"})

@app.route("/test_emit")
def test_emit():
    socketio.emit("render_dot", {"dot": "digraph { X -> Y; Y -> Z; Z -> X }"}, namespace='/')
    return "Emitted test graph!"

if __name__ == "__main__":
    socketio.run(app, debug=True, host='0.0.0.0', port=5000, use_reloader=True)
