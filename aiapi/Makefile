install:
	pip install -r requirements.txt

server:
	API_KEY=test python -m gunicorn --bind 0.0.0.0:22008 server:app
