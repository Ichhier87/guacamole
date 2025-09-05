docker build -t guacamole-arm .
docker run -d -p 8080:8080 -p 4822:4822 guacamole-arm
