import boto3
import csv
from flask import Flask, request, redirect, render_template
from werkzeug.utils import secure_filename

ALLOWED_EXTENSIONS = {'csv'}

# Auth with your local aws credentials file
session = boto3.Session(profile_name='playground-test')
s3 = session.resource('s3')
bucket = s3.Bucket('playground-test-processed-files')

# Auth with OIDC
#s3 = boto3.resource('s3')
#bucket = s3.Bucket('playground-test-processed-files')

app = Flask(__name__, static_url_path='/static')
app.config['MAX_CONTENT_LENGTH'] = 10 * 1000 * 1000 # 10mb

def allowed_file(filename):
  return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route("/", methods=['GET', 'POST'])
def upload_file():
  processed_files = [obj.key for obj in bucket.objects.all()]

  if request.method == 'GET':
    return render_template("index.html", files=processed_files)
  
  if request.method == 'POST':
    if 'file' not in request.files:
      return redirect("/")
    
    uploaded_file = request.files['file']

    if uploaded_file.filename == '':
      return redirect("/")
    
    if uploaded_file and allowed_file(uploaded_file.filename):
      filename = secure_filename(uploaded_file.filename)
      content = uploaded_file.stream.read().decode("utf-8").splitlines()
      reader = csv.reader(content)
      parsed_rows = list(reader)
      uploaded_file.stream.seek(0)  # Reset stream for S3 upload
      bucket.upload_fileobj(uploaded_file, filename)
      processed_files = [obj.key for obj in bucket.objects.all()]
      return render_template("index.html", rows=parsed_rows, files=processed_files)
    
    return render_template("index.html", files=processed_files)
  
  return render_template("index.html")
 
#for probes
@app.route("/health", methods=['GET'])
def health():
    return "ok", 200