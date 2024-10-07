# Used by `image`, `push` & `deploy` targets, override as required
IMAGE_REG ?= $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
IMAGE_REPO ?= django-demoapp
IMAGE_TAG ?= latest

# Used by `deploy` target, sets AWS defaults, override as required
AWS_REGION ?= us-east-1
AWS_ENV ?= django-env
AWS_APP_NAME ?= djangoapp
AWS_EB_BUCKET ?= my-elasticbeanstalk-bucket

# Used by `test-api` target
TEST_HOST ?= localhost:8000

# Don't change
SRC_DIR := src

.PHONY: help lint lint-fix image push run deploy undeploy clean test-api .EXPORT_ALL_VARIABLES
.DEFAULT_GOAL := help

help:  ## 💬 This help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

lint: venv  ## 🔎 Lint & format, will not fix but sets exit code on error 
	. $(SRC_DIR)/.venv/bin/activate \
	&& black --check $(SRC_DIR) \
	&& flake8 src/app/ && flake8 src/manage.py

lint-fix: venv  ## 📜 Lint & format, will try to fix errors and modify code
	. $(SRC_DIR)/.venv/bin/activate \
	&& black $(SRC_DIR)

image:  ## 🔨 Build container image from Dockerfile 
	docker build . --file build/Dockerfile \
	--tag $(IMAGE_REG)/$(IMAGE_REPO):$(IMAGE_TAG)

push:  ## 📤 Push container image to registry 
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(IMAGE_REG)
	docker push $(IMAGE_REG)/$(IMAGE_REPO):$(IMAGE_TAG)

run: venv  ## 🏃 Run the server locally using Python & Django
	. $(SRC_DIR)/.venv/bin/activate \
	&& python src/manage.py runserver 0.0.0.0:8000

deploy:  ## 🚀 Deploy to AWS Elastic Beanstalk
	zip -r $(AWS_APP_NAME).zip .
	aws s3 cp $(AWS_APP_NAME).zip s3://$(AWS_EB_BUCKET)/$(AWS_APP_NAME).zip
	aws elasticbeanstalk create-application-version --application-name $(AWS_APP_NAME) \
	    --version-label $(IMAGE_TAG) --source-bundle S3Bucket=$(AWS_EB_BUCKET),S3Key=$(AWS_APP_NAME).zip
	aws elasticbeanstalk update-environment --environment-name $(AWS_ENV) --version-label $(IMAGE_TAG)
	@echo "### 🚀 Web app deployed to AWS Elastic Beanstalk"

undeploy:  ## 💀 Remove AWS Elastic Beanstalk environment
	aws elasticbeanstalk terminate-environment --environment-name $(AWS_ENV)

test: venv  ## 🎯 Unit tests for Django app
	. $(SRC_DIR)/.venv/bin/activate \
	&& pytest -v

test-report: venv  ## 🎯 Unit tests for Django app (with report output)
	. $(SRC_DIR)/.venv/bin/activate \
	&& pytest -v --junitxml=test-results.xml

test-api: .EXPORT_ALL_VARIABLES  ## 🚦 Run integration API tests, server must be running 
	cd tests \
	&& npm install newman \
	&& ./node_modules/.bin/newman run ./postman_collection.json --env-var apphost=$(TEST_HOST)

clean:  ## 🧹 Clean up project
	rm -rf $(SRC_DIR)/.venv
	rm -rf tests/node_modules
	rm -rf tests/package*
	rm -rf test-results.xml
	rm -rf $(SRC_DIR)/app/__pycache__
	rm -rf $(SRC_DIR)/app/tests/__pycache__
	rm -rf .pytest_cache
	rm -rf $(SRC_DIR)/.pytest_cache

# ============================================================================

venv: $(SRC_DIR)/.venv/touchfile

$(SRC_DIR)/.venv/touchfile: $(SRC_DIR)/requirements.txt
	python3 -m venv $(SRC_DIR)/.venv
	. $(SRC_DIR)/.venv/bin/activate; pip install -Ur $(SRC_DIR)/requirements.txt
	touch $(SRC_DIR)/.venv/touchfile
