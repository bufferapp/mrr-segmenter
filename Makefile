NAME = bufferapp/mrr-segmenter:0.3.0

all: run

build:
	docker build -t $(NAME) .

run: build
	docker run -it -p 3405:3405 --rm --env-file .env $(NAME)

push: build
	docker push $(NAME)

dev: build
	docker run -v $(PWD):/app -it -p 3405:3405 --rm --env-file .env $(NAME) bash

deploy: push
	kubectl apply -f kubernetes/

delete-deployment:
	kubectl delete -f kubernetes/
