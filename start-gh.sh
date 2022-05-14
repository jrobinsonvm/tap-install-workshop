mkdir -p actions-runner && cd actions-runner
curl -o actions-runner-linux-x64-2.291.1.tar.gz -L https://github.com/actions/runner/releases/download/v2.291.1/actions-runner-linux-x64-2.291.1.tar.gz
echo "1bde3f2baf514adda5f8cf2ce531edd2f6be52ed84b9b6733bf43006d36dcd4c  actions-runner-linux-x64-2.291.1.tar.gz" | shasum -a 256 -c
tar xzf ./actions-runner-linux-x64-2.291.1.tar.gz

./config.sh --url https://github.com/jrobinsonvm/gh-actions-tap-demo --token ${TOKEN}
./run.sh
