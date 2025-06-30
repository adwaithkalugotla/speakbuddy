

from flask import Flask, request, jsonify
import os
import threading
from debate_utils import record_audio as start_audio_recording, stop_recording, transcribe_audio, analyze_arguments, translate_text

app = Flask(__name__)

# Global flag for recording
recording_thread = None
is_recording = False

@app.route("/ping", methods=["GET"])
def ping():
    print("🔔 Received ping")      # so we see it in the console
    return "pong", 200

@app.route('/record_audio', methods=['POST'])
def start_recording():
    global recording_thread, is_recording

    if is_recording:
        return jsonify({"message": "Recording is already in progress"}), 400

    if not request.is_json:
        return jsonify({"error": "Request must be JSON"}), 415

    data = request.get_json()
    file_name = data.get("file_name", "debate_audio.wav")  # ✅ Use custom name from frontend
    file_path = os.path.join("recordings", file_name)       # ✅ Save to /recordings

    print(f"📥 Starting recording: {file_path}")

    is_recording = True
    recording_thread = threading.Thread(target=start_audio_recording, args=(file_path,))
    recording_thread.start()

    return jsonify({"message": "Recording started", "file_path": file_path})

@app.route('/stop_recording', methods=['POST'])
def stop_recording_audio():
    global is_recording, recording_thread
    if not is_recording:
        return jsonify({"message": "No recording in progress"}), 400
    
    stop_recording()
    is_recording = False

    if recording_thread:
        recording_thread.join()  # Ensure thread exits before returning response

    return jsonify({"message": "Recording stopped"})

@app.route('/transcribe', methods=['POST'])
def handle_transcribe_audio():
    if not request.is_json:
        return jsonify({"error": "Request must be JSON"}), 415

    data = request.get_json()
    file_name = data.get("file_name", "debate_audio.wav")
    file_path = os.path.join("recordings", file_name)

    if not os.path.exists(file_path):
        return jsonify({"error": f"File not found: {file_path}"}), 404

    transcript = transcribe_audio(file_path)
    return jsonify({"transcript": transcript})


@app.route('/analyze', methods=['POST'])
def handle_analyze_arguments():
    if not request.is_json:
        return jsonify({"error": "Request must be JSON"}), 415

    # ✅ Define this FIRST before anything else
    data = request.get_json()
    debate_type = data.get('debate_type')
    topic = data.get('topic')
    file_name = data.get("file_name", "debate_audio.wav")  # <-- NEW
    file_path = os.path.join("recordings", file_name)
    print(f"📥 Received request to analyze file: {file_name}")
    print(f"📁 Full path: {file_path}")



   

    # ✅ Check if file exists
    if not os.path.exists(file_path):
        return jsonify({"error": f"File not found: {file_path}"}), 404

    # ✅ Transcribe that specific file
    transcript = transcribe_audio(file_path)

    if "Error" in transcript:
        return jsonify({"error": "Audio transcription failed"}), 500

    analysis = analyze_arguments(transcript, debate_type, topic)
    return jsonify({"analysis": analysis})

@app.route('/analyze_text', methods=['POST'])
def handle_analyze_text():
    data = request.get_json(force=True)
    debate_type = data.get('debate_type')
    topic       = data.get('topic')
    transcript  = data.get('transcript', '')

    if not transcript:
        return jsonify({"error": "Missing 'transcript'"}), 400

    # Use the same analyze_arguments logic on the full text
    analysis = analyze_arguments(transcript, debate_type, topic)
    return jsonify({"analysis": analysis})


@app.route('/translate', methods=['POST'])
def handle_translate_text():
    if not request.is_json:
        return jsonify({"error": "Request must be JSON"}), 415

    data = request.get_json()
    text = data.get("text")
    target_language = data.get("target_language", "en")

    if not text:
        return jsonify({"error": "Missing 'text' to translate"}), 400

    try:
        translated = translate_text(text, target_language)
        return jsonify({"translated": translated})
    except Exception as e:
        return jsonify({"error": str(e)}), 500



if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
