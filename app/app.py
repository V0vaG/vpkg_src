from flask import Flask, request, render_template, jsonify, send_from_directory
import os
import re
import shutil
import subprocess

app = Flask(__name__)

alias = "vpkg"
# UPLOAD_FOLDER = 'uploads'
HOME_DIR = os.path.expanduser("~")
UPLOAD_FOLDER = os.path.join(HOME_DIR, "script_files", alias)
SCRIPT_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'vpkg_3.3.6.sh')
ARTIFACT_FILE_NAME = 'artifact.sh'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# Route for the Welcome Page
@app.route('/')
def welcome():
    user_ip = request.remote_addr.replace('.', '_')
    user_folder = os.path.join(UPLOAD_FOLDER, user_ip)
    artifact_file = os.path.join(user_folder, ARTIFACT_FILE_NAME)
    files_info = []
    folder_exists = os.path.exists(user_folder)  # Check if the folder exists

    if folder_exists:
        for file_name in os.listdir(user_folder):
            file_path = os.path.join(user_folder, file_name)
            if os.path.isfile(file_path) and file_name != os.path.basename(SCRIPT_PATH):
                info = parse_file_info(file_name)
                if info:
                    files_info.append(info)

    return render_template('welcome.html', files=files_info, 
                           artifact_exists=os.path.exists(artifact_file), 
                           folder_exists=folder_exists)

# Route for File Upload
@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return jsonify({'message': 'No file part in the request'}), 400
    file = request.files['file']
    if file.filename == '':
        return jsonify({'message': 'No file selected'}), 400
    if file:
        if not is_valid_filename(file.filename):
            return jsonify({'message': 'Invalid file name format. Use command_version.type'}), 400
        user_ip = request.remote_addr.replace('.', '_')
        user_folder = os.path.join(UPLOAD_FOLDER, user_ip)
        os.makedirs(user_folder, exist_ok=True)
        file_path = os.path.join(user_folder, file.filename)
        file.save(file_path)
        return jsonify({'message': f'File {file.filename} uploaded successfully'}), 200

# Route to Run the Script
@app.route('/generate', methods=['POST'])
def generate_artifact():
    user_ip = request.remote_addr.replace('.', '_')
    user_folder = os.path.abspath(os.path.join(UPLOAD_FOLDER, user_ip))  # Absolute path to user folder
    artifact_file = os.path.join(user_folder, ARTIFACT_FILE_NAME)

    if not os.path.exists(user_folder):
        return jsonify({'message': 'No files uploaded yet to generate artifact'}), 400

    # Copy the script to the user folder
    local_script_path = os.path.join(user_folder, os.path.basename(SCRIPT_PATH))
    shutil.copy(SCRIPT_PATH, local_script_path)

    # Set execution permissions for the script
    os.chmod(local_script_path, 0o755)

    # Collect all file names (no paths), excluding the script itself
    uploaded_files = [f for f in os.listdir(user_folder) if os.path.isfile(os.path.join(user_folder, f)) and f != os.path.basename(SCRIPT_PATH)]

    if not uploaded_files:
        return jsonify({'message': 'No files found to process'}), 400

    try:
        # Use absolute path for the script
        absolute_script_path = os.path.abspath(local_script_path)
        command = ["bash", absolute_script_path] + uploaded_files
        print(f"Executing command: {' '.join(command)}")  # Debugging output
        
        # Run the script in the user folder
        subprocess.run(command, check=True, cwd=user_folder)
        return jsonify({'message': 'Artifact generated successfully'}), 200
    except subprocess.CalledProcessError as e:
        return jsonify({'message': f'Error running script: {e}'}), 500


# Route to Download the Artifact File
@app.route('/download_artifact', methods=['GET'])
def download_artifact():
    user_ip = request.remote_addr.replace('.', '_')
    user_folder = os.path.abspath(os.path.join(UPLOAD_FOLDER, user_ip))
    artifact_file = os.path.join(user_folder, ARTIFACT_FILE_NAME)
    
    # Debugging output
    print(f"Attempting to download: {artifact_file}")
    print(f"File exists: {os.path.exists(artifact_file)}")
    
    if os.path.exists(artifact_file):
        return send_from_directory(user_folder, ARTIFACT_FILE_NAME, as_attachment=True)
    return jsonify({'message': 'Artifact file not found'}), 404

# Route to Delete User Folder
@app.route('/delete_folder', methods=['POST'])
def delete_folder():
    user_ip = request.remote_addr.replace('.', '_')
    user_folder = os.path.join(UPLOAD_FOLDER, user_ip)
    try:
        if os.path.exists(user_folder):
            shutil.rmtree(user_folder)
            print(f"Deleted user folder: {user_folder}")
            return jsonify({'message': 'User folder deleted successfully'}), 200
        else:
            return jsonify({'message': 'User folder does not exist'}), 404
    except Exception as e:
        return jsonify({'message': f'Error deleting folder: {e}'}), 500


# Utility function to parse file info
def parse_file_info(filename):
    match = re.match(r'(?P<command>.+?)_(?P<version>\d+\.\d+\.\d+)\.(?P<type>\w+)$', filename)
    if match:
        return {
            'file_name': filename,
            'command': match.group('command'),
            'version': match.group('version'),
            'type': get_file_type(match.group('type'))
        }
    return None

# Utility function to check filename validity
def is_valid_filename(filename):
    return re.match(r'^[a-zA-Z0-9_-]+_\d+\.\d+\.\d+\.[a-zA-Z0-9]+$', filename)

# Utility function to get file type
def get_file_type(extension):
    file_types = {
        'sh': 'bash',
        'py': 'python',
        'c': 'c'
        
    }
    return file_types.get(extension, 'unknown')

if __name__ == '__main__':
    app.run(debug=True)
