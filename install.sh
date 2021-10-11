echo -n "Enter outline access key (ss://abc@1.1.1.1:2222/): "
read ACCESS_KEY

if [ -z $ACCESS_KEY ]
then
	echo "Invalid access key" >&2
	exit 1
fi


echo -n "Enter binding host [127.0.0.1]: "
read BINDING_HOST
BINDING_HOST=${BINDING_HOST:-127.0.0.1}

echo -n "Enter http proxy port [7551]: "
read BINDING_HTTP_PORT
BINDING_HTTP_PORT=${BINDING_HTTP_PORT:-7551}

echo -n "Enter socks5 proxy port [7550]: "
read BINDING_SOCKS_PORT
BINDING_SOCKS_PORT=${BINDING_SOCKS_PORT:-7550}

echo -n "Use proxy for docker pulls [Y/n]: "
read USE_DOCKER
USE_DOCKER=${USE_DOCKER:-Y}

echo -n "Use proxy for apt [Y/n]: "
read USE_APT
USE_APT=${USE_APT:-Y}

echo -n "No Proxies [localhost]: "
read NO_PROXIES
NO_PROXIES=${NO_PROXIES:-localhost}

echo -n "Container name [proxy]: "
read CONTAINER_NAME
CONTAINER_NAME=${CONTAINER_NAME:-proxy}

PRIV_KEY=`echo -n $ACCESS_KEY | sed -E 's/.*ss\:\/\/([^@]+).*/\1/'`
PRIV_KEY_DECODED=`echo $PRIV_KEY==== | fold -w 4 | sed '$ d' | tr -d '\n' | base64 -di`
METHOD=`echo -n $PRIV_KEY_DECODED | cut -d ":" -f 1`
PASSWORD=`echo -n $PRIV_KEY_DECODED | cut -d ":" -f 2`
HOST=`echo -n $ACCESS_KEY | sed -E 's/.*ss\:\/\/[^@]+\@([\d\.]+).*/\1/'`
PORT=`echo -n $ACCESS_KEY | sed -E 's/.*ss\:\/\/[^@]+\@[\d\.]+\:([\d]+).*/\1/'`



if [[ "$(docker images -q payamint/shadowsocks-polipo-docker:latest 2> /dev/null)" == "" ]]; then
	# Download image file
	wget https://github.com/payam-int/shadowsocks-polipo-docker/releases/download/v0.1/shadowsocks-docker-polipo.image

	# Load image file into docker
	docker load < shadowsocks-docker-polipo.image

	# Delete image file
	rm shadowsocks-docker-polipo.image
fi

if [ "$USE_DOCKER" != "n" ]
then
	DOCKER_HTTP_PROXY_FILE="
[Service]\n
Environment=\"HTTP_PROXY=http://127.0.0.1:${BINDING_HTTP_PORT}/\"\n
Environment=\"HTTPS_PROXY=http://127.0.0.1:${BINDING_HTTP_PORT}/\"\n
Environment=\"NO_PROXY=$NO_PROXIES\"
"
	mkdir -p /etc/systemd/system/docker.service.d/
	echo -e $DOCKER_HTTP_PROXY_FILE > /etc/systemd/system/docker.service.d/http-proxy.conf
	systemctl daemon-reload
	systemctl restart docker
fi

docker run -d --restart unless-stopped -p ${BINDING_HOST}:${BINDING_HTTP_PORT}:7551 \
  -p ${BINDING_HOST}:${BINDING_SOCKS_PORT}:7550 -e SERVER_HOST=${HOST} -e SERVER_PORT=${PORT} \
  -e ENCRYPT_METHOD=${METHOD} --name ${CONTAINER_NAME} payamint/shadowsocks-polipo-docker:latest
