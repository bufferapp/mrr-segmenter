NAME = bufferapp/mrr-segmenter:0.3.0

all: run

build:
	docker build -t $(NAME) .

run: build
	docker run -it -p 3838:3838 --env-file .env --rm $(NAME)

push: build
	docker push $(NAME)

dev: build
	docker run -v $(PWD):/app --env-file .env -p 3838:3838 -it --rm $(NAME) bash

deploy:
	gcloud builds submit --config cloudbuild.yaml .

delete-deployment:
	kubectl delete -f kubernetes/
