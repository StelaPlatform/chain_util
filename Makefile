TOP_DIR=.
PROJECT_HOME=${TOP_DIR}

# ------------------------------------  General  -----------------------------------------
chain-install:
	@echo "Install software required for this repo..."
	@npm install --save-dev hardhat
	@npm install --save-dev @openzeppelin/contracts
	@npm install --save-dev @nomiclabs/hardhat-ethers ethers

chain-clean:
	@echo "Cleaning the chain..."
	@rm -rf artifacts
	@rm -rf solc_out
	@rm -rf dev_chain

# ------------------------------------  Chain Related  -----------------------------------------
chain:
	@echo "Running Erigon chain..."
	@rm -rf dev_chain
	@erigon \
		--datadir=dev_chain \
		--chain dev \
		--private.api.addr=localhost:9090 \
		--http.api=eth,erigon,web3,net,debug,trace,txpool,trace,parity \
		--mine \
		--dev.period=13

chain-rpc:
	@rpcdaemon \
		--datadir=dev_chain  \
		--private.api.addr=localhost:9090 \
		--http.api=eth,erigon,web3,net,debug,trace,txpool,trace,parity

hdnode:
	@npx hardhat node

hdconsole:
	@npx hardhat console --network localhost

# ------------------------------------  Contracts Related  -----------------------------------------
contracts:
	@echo "Building the contracts..."
	@rm -rf artifacts/contracts
	@npx hardhat compile

contracts-deploy:
	@mix stela.deploy stela

hd-contracts:
	@npx hardhat run --network localhost scripts/deploy.js

contracts-run: contracts contracts-deploy hdconsole

contracts-asm:
	@solc contracts/Stela.sol \
    	--base-path . \
    	--include-path node_modules/ \
    	--asm \
    	-o ./out \
    	--optimize \
    	--optimize-runs=1000

contracts-bin:
	@solc contracts/Stela.sol \
    	--base-path . \
    	--include-path node_modules/ \
    	--bin \
    	-o ./out \
    	--optimize \
    	--optimize-runs=1000

# include .makefiles/*.mk


.PHONY: chain-install chain-clean chain chain-rpc hdnode hdconsole contracts contracts-deploy hd-contracts contracts-run contracts-asm contracts-bin
