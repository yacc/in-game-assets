# Superpower in-game assets

A set of smart contract for in-game assets.

## Set up you environment

### 1 - Node
Install [node](https://nodejs.org/). Best way on Linux and Mac is to use [nvm](https://github.com/nvm-sh/nvm).
``` 
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
```
The script clones the nvm repository to `~/.nvm`, and attempts to add the source lines from the snippet below to the correct profile file (`~/.bash_profile`, `~/.zshrc`, `~/.profile`, or `~/.bashrc`).

```

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
```

Opening a new terminal, you should be able to access nvm. If not, add the lines abo-e in your profile file, and source it.

When nvm is installed, you can install node with a command like
``` 
nvm install v16
```
The advantage of using nvm is that it does not install it as root (very important for security) and allows you to install many versions of Node and jump between them when you need it.

### 2 - Pnpm, Hardhat and dependencies 
Install the packages. In this repo we use [pnpm](https://pnpm.io/) as favorite package manager, because it is faster than npm, saves lot of spaces reusing packages, manages monorepos, etc. We also want to install [Hardhat](https://hardhat.org/) to manage the smart contracts. 
``` 
npm i -g pnpm
pnpm i -g hardhat
```

Install the dependencies
``` 
pnpm i
```
### 3 - Dev blockchain
You can launch an EVM node with 
``` 
npx hardhat node
```
the problem is that every time you restart it, you reset your environment. This is not optimal. It'd be better to be able to have a local blockchain that maintains contracts, transactions, etc. so that you can evolve your work.
To do so, we prefer to use Ganache.

Go to https://trufflesuite.com/ganache/, download Ganache and install it.

Launch it. Then, configure a server compatible with Hardhat node. To do so, in Workspaces, click on NEW WORKSPACE (Ethereum). In the tab Server, set the port number to 8545 and the network ID to 1337. In the tab Account&Keys, use the standard Hardhat test mnemonic:
```
test test test test test test test test test test test junk
```
When don, run the server. Now, you have a local blockchain ready for the job.

### 4 - Tasks
To compile the smart contracts
```
npx hardhat compile
```
To test:
``` 
npx hardhat test
```
To deploy the nft to Ganache
``` 
bin/deploy.sh nft localhost
```

## Copyright

Author Francesco Sullo <francesco@sullo.co>
(c) 2022, Superpower Labs Inc.

The ERC721 contracts are an evolution of https://github.com/ndujaLabs/everdragons2-core, (c) 2022, NdujaLabs LLC

## License

MIT
