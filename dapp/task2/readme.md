执行以下命令

npm install -g solc
go install github.com/ethereum/go-ethereum/cmd/abigen@latest

生成abi文件和go文件
npx solcjs --abi IERC20Metadata.sol
abigen --abi=erc20_sol_ERC20.abi --pkg=token --out=erc20.go

运行结果
```text
Hello and welcome, 
Transaction hash: 0xa52ee04097fc49d12642d102525b86135acd7e5d95a3e0a577d761340a4e9062
Sum value: 2
```