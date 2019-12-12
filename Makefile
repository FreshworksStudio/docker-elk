#!make

app:
	@echo "+\n++ Running application in background...\n+"
	@docker-compose up -d

build:
	@echo "+\n++ Building images...\n+"
	@docker-compose build --parallel

restart: build | app

stop:
	@echo "+\n++ Stopping application ...\n+"
	@docker-compose down -t 2

clean:
	@echo "+\n++ Removing containers, images, volumes etc...\n+"
	@docker-compose down --rmi all --volumes
	@docker-compose rm -f -v -s