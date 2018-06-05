NAME = bufferapp/mrr-segmenter:0.1.0

all: run

build:
	docker build -t $(NAME) .

run: build
	docker run -it -p 8088:8088 --rm --env-file .env $(NAME)

push: build
	docker push $(NAME)

dev: build
	docker run -v $(PWD):/app -it -p 8088:8088 --rm --env-file .env $(NAME) bash

deploy: push
	kubectl apply -f kubernetes/cronjob.yaml
