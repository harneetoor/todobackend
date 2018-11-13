.PHONY: test release clean version login logout publish

export APP_VERSION ?= $(shell git rev-parse --short HEAD)

login:
	$$(aws ecr get-login --no-include-email --profile docker_in_aws)

logout:
	docker logout https://263108955216.dkr.ecr.ap-southeast-1.amazonaws.com

version:
	@ echo '{"Version": "$(APP_VERSION)"}'

test:
	docker-compose build --pull release
	docker-compose build
	docker-compose run test

release:
	docker-compose up --abort-on-container-exit migrate
	docker-compose run app python3 manage.py collectstatic --no-input
	docker-compose up --abort-on-container-exit acceptance
	@ echo App running at http://$$(docker-compose port app 8000 | sed s/0.0.0.0/localhost/g)

publish:
	docker-compose push release app

clean:
	docker-compose down -v
	docker images -q -f dangling=true -f label=application=todobackend | xargs -I ARGS docker rmi -f --no-prune ARGS
