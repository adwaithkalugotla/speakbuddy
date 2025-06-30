import openai
import pyaudio
import wave
import os
import simpleaudio as sa
from threading import Thread
from pydub import AudioSegment

# OpenAI API Key
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
if not OPENAI_API_KEY:
    raise ValueError("Missing OpenAI API Key. Set the OPENAI_API_KEY environment variable.")

client = openai.OpenAI(api_key=OPENAI_API_KEY)

# Global variable to manage recording
is_recording = False

def record_audio(file_path):
    """Starts recording audio until stopped manually."""
    global is_recording, audio_frames
    is_recording = True
    audio_frames = []

    CHUNK = 1024
    FORMAT = pyaudio.paInt16
    CHANNELS = 1
    RATE = 44100

    p = pyaudio.PyAudio()
    stream = p.open(format=FORMAT, channels=CHANNELS, rate=RATE, input=True, frames_per_buffer=CHUNK)

    print(f"🔴 Recording started for file: {file_path}")
    while is_recording:
        data = stream.read(CHUNK, exception_on_overflow=False)
        audio_frames.append(data)

    stream.stop_stream()
    stream.close()
    p.terminate()

    # Save to the correct file path
    with wave.open(file_path, 'wb') as wf:
        wf.setnchannels(CHANNELS)
        wf.setsampwidth(p.get_sample_size(FORMAT))
        wf.setframerate(RATE)
        wf.writeframes(b''.join(audio_frames))

    print(f"✅ Recording saved to: {file_path}")

def stop_recording():
    """Stops the ongoing recording."""
    global is_recording
    is_recording = False
    print("Recording stopped.")

def play_audio(file_path):
    """Plays recorded audio."""
    try:
        wave_obj = sa.WaveObject.from_wave_file(file_path)
        play_obj = wave_obj.play()
        play_obj.wait_done()
    except Exception as e:
        print(f"Audio Playback Error: {e}")

def transcribe_audio(file_path):
    """Transcribes recorded audio using OpenAI Whisper API, splitting into chunks if >25 MB."""
    # Whisper’s per-request upload limit is roughly 25 MB
    max_bytes = 25 * 1024 * 1024
    size = os.path.getsize(file_path)

    # Under the limit? Just send it.
    if size <= max_bytes:
        with open(file_path, "rb") as audio_file:
            resp = client.audio.transcriptions.create(
                model="whisper-1",
                file=audio_file
            )
        return resp.text

    # Otherwise split into ~14-minute WAV chunks (safe for 44.1 kHz)
    audio = AudioSegment.from_file(file_path)
    chunk_ms = 14 * 60 * 1000
    transcripts = []

    for i, start in enumerate(range(0, len(audio), chunk_ms)):
        chunk = audio[start:start+chunk_ms]
        chunk_path = f"{file_path}.chunk{i}.wav"
        chunk.export(chunk_path, format="wav")

        with open(chunk_path, "rb") as audio_file:
            resp = client.audio.transcriptions.create(
                model="whisper-1",
                file=audio_file
            )
            transcripts.append(resp.text)

        os.remove(chunk_path)

    # Join with newlines so you can still see where chunks broke
    return "\n".join(transcripts)

def analyze_arguments(transcript, debate_type, topic=None):
    topic_line = f"The debate topic is: '{topic}'\n\n" if topic else ""
    debate_prompts = {
        "lincoln_douglas": f"""You are a virtual debate judge following the NSDA guidelines for Lincoln-Douglas Debate. Evaluate based on:
1. Clarity and Organization – Did the student structure their argument logically?
2. Argument Quality and Persuasiveness – Were the arguments strong and well-supported?
3. Cross-Examination Effectiveness – How effectively did the student challenge and respond to opponents?
4. Rebuttal and Refutation – Were counterarguments clear and well-articulated?
5. Overall Impact and Presentation – Provide a final score (out of 100) with constructive feedback.

### Final Decision:
- Score Speaker 1 out of 100
- Score Speaker 2 out of 100
- Clearly declare the winner with a decisive justification.

{topic_line}Debate transcript (DO NOT ALTER OR REWRITE):

{transcript}

**IMPORTANT:**
1. Do NOT paraphrase or edit the transcript above.
2. ONLY declare which speaker won, and give a brief justification based solely on that transcript.
""",
        "policy": f"""You are a virtual debate judge following the NSDA Policy Debate guidelines. Evaluate based on:
1. Clarity and Structure – Did the student follow the debate structure?
2. Evidence and Persuasion – Were their arguments factually supported?
3. Rebuttal and Cross-Examination – How well did they challenge their opponent?
4. Adherence to Debate Protocol – Did they follow NSDA rules?
5. Overall Impact – Provide a final score (out of 100) with constructive feedback.

### Final Decision:
- Assign Speaker 1 a score out of 100.
- Assign Speaker 2 a score out of 100.
- Clearly declare the winner with a strong justification.

{topic_line}Debate transcript (DO NOT ALTER OR REWRITE):

{transcript}

**IMPORTANT:**
1. Do NOT paraphrase or edit the transcript above.
2. ONLY declare which speaker won, and give a brief justification based solely on that transcript.
""",
        "public_forum": f"""You are a virtual judge for a Public Forum Debate under NSDA guidelines. Evaluate based on:
1. Clarity and Logical Structure – Was the argument well-organized?
2. Persuasiveness and Use of Evidence – Did they use strong and relevant sources?
3. Crossfire Engagement – How well did they question and respond?
4. Teamwork and Coordination – Did both team members contribute effectively?
5. Final Score and Feedback – Provide a score (out of 100) with feedback.

### Final Decision:
- Give Speaker 1 a score out of 100.
- Give Speaker 2 a score out of 100.
- Clearly declare the winner and explain why.

{topic_line}Debate transcript (DO NOT ALTER OR REWRITE):

{transcript}

**IMPORTANT:**
1. Do NOT paraphrase or edit the transcript above.
2. ONLY declare which speaker won, and give a brief justification based solely on that transcript.
""",
        "casual": f"""You're an AI debate critic in Casual Mode. You don't follow rigid formats — your goal is to decide who did better based on logic, coherence, and persuasiveness.

Evaluate based on:
1. Clarity – Who made their point better?
2. Logic – Who used more convincing logic?
3. Responsiveness – Did anyone ignore or dodge good arguments?
4. Style & Confidence – Who sounded more confident and in control?

Then:
- Assign a score out of 100 to both speakers.
- Declare a clear winner with a blunt reason.

{topic_line}Debate transcript (DO NOT ALTER OR REWRITE):

{transcript}

**IMPORTANT:**
1. Do NOT paraphrase or edit the transcript above.
2. ONLY declare which speaker won, and give a brief justification based solely on that transcript.
"""
    }

    if debate_type not in debate_prompts:
        return "Error: Debate type not recognized."

    prompt_text = debate_prompts[debate_type]

    if not transcript or len(transcript.strip().split()) < 20:
        prompt_text += (
            "\n\n⚠️ The transcript appears to be partial or incomplete. "
            "Still, please do your best to evaluate based on what is available. "
            "Do NOT ask for more information — provide analysis anyway."
        )
    else:
        prompt_text += "\n\nPlease judge based on the content provided."

    response = client.chat.completions.create(
        model="gpt-4",
        messages=[{"role": "system", "content": prompt_text}]
    )

    return response.choices[0].message.content

def analyze_direct_prompt(prompt):
    """Uses GPT to analyze a single round using a raw prompt."""
    response = client.chat.completions.create(
        model="gpt-4",
        messages=[{"role": "system", "content": prompt}],
        temperature=0.7,
        max_tokens=500
    )
    return response.choices[0].message.content.strip()

def translate_text(text, target_language):
    """Translates the given English text into the specified language using OpenAI GPT."""
    prompt = f"Translate the following text to {target_language}:\n\n{text}"
    response = client.chat.completions.create(
        model="gpt-4",
        messages=[{"role": "system", "content": prompt}],
        temperature=0.7,
        max_tokens=1000
    )
    return response.choices[0].message.content.strip()
