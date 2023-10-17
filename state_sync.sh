#!/bin/bash
set -uxe

curl https://raw.githubusercontent.com/AstraProtocol/testnets/main/astra_11115-1/genesis.json > ~/.astrad/config/genesis.json
INTERVAL=10000
# GET TRUST HASH AND TRUST HEIGHT

LATEST_HEIGHT=$(curl -s http://5.189.177.89:26657/block | jq -r .result.block.header.height);
BLOCK_HEIGHT=$(($LATEST_HEIGHT-$INTERVAL))
TRUST_HASH=$(curl -s "http://5.189.177.89:26657/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)



# TELL USER WHAT WE ARE DOING
echo "TRUST HEIGHT: $BLOCK_HEIGHT"
echo "TRUST HASH: $TRUST_HASH"

sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"http://5.189.177.89:26657,http://5.189.177.89:26657\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"| ; \
s|^(seeds[[:space:]]+=[[:space:]]+).*$|\1\"\"|" $HOME/.astrad/config/config.toml
sed -i.bak -E 's#^(seeds[[:space:]]+=[[:space:]]+).*$#\1"053f5a5f085b8ec1c22be9276724884b9866be43@5.189.177.89:26656,d782f502c1d2512efec433260ce39cff76eb0228@144.91.107.238:26656"#' ~/.astrad/config/config.toml


# astrad start --x-crisis-skip-assert-invariants
