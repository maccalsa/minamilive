## Assumes that the project is already initialized with a virtual environment
## python -m venv venv
## source venv/bin/activate


init:
	cd backend && pip install -r requirements.txt

requirements:
	cd backend && pip freeze > requirements.txt

run-backend:
	uvicorn backend.main:app --reload --port=8000

run-frontend:
	cd frontend && python -m http.server 5500

