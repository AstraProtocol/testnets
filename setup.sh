NODE_NAME="my-validator"
NODE_TYPE="VALIDATOR"
fancy_echo() {
  local fmt="$1"; shift

  # shellcheck disable=SC2059
  printf "\\n$fmt\\n" "$@"
}

# Replace the line of the given line number with the given replacement in the given file.
function replace_line() {
    local file=config.toml
    local line_num=18
    local replacement=$1

    # Escape backslash, forward slash and ampersand for use as a sed replacement.
    replacement_escaped=$( echo "$replacement" | sed -e 's/[\/&]/\\&/g' )

    sed -i "${line_num}s/.*/$replacement_escaped/" "$file"
}

setup_golang() {
    snap install go --classic
    echo "export PATH=$PATH:$(go env GOPATH)/bin" >> ~/.profile
    source ~/.profile
    fancy_echo "$(go version)"
}

install_astra() {
    fancy_echo "install astra"
    curl -OL https://github.com/AstraProtocol/astra/releases/download/v3.1.0/astra_3.1.0_Linux_amd64.tar.gz
    tar -C ./ -xvf astra_3.1.0_Linux_amd64.tar.gz
    cp bin/astrad /usr/bin/astrad
    mv bin/astrad ./astrad
}

setup_astra() {
    ./astrad init $NODE_NAME --chain-id astra_11115-1
    cd ~/.astrad/config
    curl https://raw.githubusercontent.com/AstraProtocol/testnets/main/astra_11115-1/genesis.json > genesis.json
    sed -i "s/genesisValidator/$NODE_NAME/" config.toml
    if [[ "$NODE_TYPE" == "RPC" ]];
    then
        fancy_echo "download rpc"
        curl https://raw.githubusercontent.com/AstraProtocol/testnets/main/astra_11115-1/api/app.toml  > app.toml
        curl https://raw.githubusercontent.com/AstraProtocol/testnets/main/astra_11115-1/api/config.toml  > config.toml
    elif [[ "$NODE_TYPE" == "VALIDATOR" ]];
    then
        fancy_echo "download validator"
        curl https://raw.githubusercontent.com/AstraProtocol/testnets/main/astra_11115-1/validators/app.toml  > app.toml
        curl https://raw.githubusercontent.com/AstraProtocol/testnets/main/astra_11115-1/validators/config.toml  > config.toml
   elif [[ "$NODE_TYPE" == "API" ]];
    then
        fancy_echo "download api"
        curl https://raw.githubusercontent.com/AstraProtocol/testnets/main/astra_11115-1/api/app.toml  > app.toml
        curl https://raw.githubusercontent.com/AstraProtocol/testnets/main/astra_11115-1/api/config.toml  > config.toml
    elif [[ "$NODE_TYPE" == "FULLNODE" ]];
    then
        fancy_echo "download fullnode"
        curl https://raw.githubusercontent.com/AstraProtocol/testnets/main/astra_11115-1/fullnode/app.toml  > app.toml
        curl https://raw.githubusercontent.com/AstraProtocol/testnets/main/astra_11115-1/fullnode/config.toml  > config.toml
    fi
}
fancy_echo "setting golang"
RESULT=$(go version)
if (exit $?)
then
    fancy_echo "$(go version)"
else
    fancy_echo "installing golang"
    setup_golang
fi

fancy_echo "setting astra"
fancy_echo "setting astra $NODE_NAME"

RESULT=$(astrad version)
if (exit $?)
then
    fancy_echo "bravo $(astrad version)"
    install_astra
    setup_astra
else
    fancy_echo "installing astra"
    install_astra
    setup_astra
fi

cd ~
source ~/.profile
go install github.com/cosmos/cosmos-sdk/cosmovisor/cmd/cosmovisor@v1.0.0
echo "# Setup Cosmovisor" >> ~/.profile
echo "export DAEMON_NAME=astrad" >> ~/.profile
echo "export DAEMON_HOME=/root/.astrad" >> ~/.profile
echo "export DAEMON_ALLOW_DOWNLOAD_BINARIES=true" >> ~/.profile
echo "export UNSAFE_SKIP_BACKUP=true" >> ~/.profile
source ~/.profile

mkdir -p ~/.astrad/cosmovisor
mkdir -p ~/.astrad/cosmovisor/genesis
mkdir -p ~/.astrad/cosmovisor/genesis/bin
mkdir -p ~/.astrad/cosmovisor/upgrades

cp ~/setup/astrad ~/.astrad/cosmovisor/genesis/bin
fancy_echo "Setup service ----"
curl -s https://raw.githubusercontent.com/AstraProtocol/docs/main/systemd/create-service.sh -o create-service.sh && curl -s https://raw.githubusercontent.com/AstraProtocol/docs/main/systemd/astrad.service.template -o astrad.service.template
chmod +x ./create-service.sh && ./create-service.sh

curl -s https://raw.githubusercontent.com/AstraProtocol/mainnet/main/script > /etc/systemd/system/astrad.service

systemctl daemon-reload
fancy_echo "done !!!"
