ss-local -s $SERVER_HOST -p $SERVER_PORT -l 7550 -k $PASSWORD -m $ENCRYPT_METHOD -b 0.0.0.0 &
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start shadowsocks: $status"
  exit $status
fi

polipo socksParentProxy=localhost:7550 proxyPort=7551 proxyAddress=0.0.0.0 &
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start polipo: $status"
  exit $status
fi

echo "Proxy is running ..."

while sleep 60; do
  ps aux |grep ss-local |grep -q -v grep
  PROCESS_1_STATUS=$?
  ps aux |grep polipo |grep -q -v grep
  PROCESS_2_STATUS=$?
  # If the greps above find anything, they exit with 0 status
  # If they are not both 0, then something is wrong
  if [ $PROCESS_1_STATUS -ne 0 -o $PROCESS_2_STATUS -ne 0 ]; then
    echo "One of the processes has already exited."
    exit 1
  fi
done
