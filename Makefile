NAME = gcr.io/buffer-data/mrr-segmenter:0.4.0

all: run

build:
	docker build -t $(NAME) .

run: build
	docker run -it -p 3838:3838 --rm --env-file .env $(NAME)

push: build
	docker push $(NAME)

dev: build
	docker run -v $(PWD):/srv/shiny-server -it -p 3838:3838 --rm --env-file .env $(NAME) bash

deploy: push
	kubectl apply -f kubernetes/

delete-deployment:
	kubectl delete -f kubernetes/
