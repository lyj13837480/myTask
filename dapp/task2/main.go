package main

import (
	"context"
	"fmt"
	"log"
	"task2/demo"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
)

func main() {
	fmt.Printf("Hello and welcome, \n")
	client, err := ethclient.Dial("https://sepolia.infura.io/v3/xxxxx")
	if err != nil {
		log.Fatal(err)
	}

	address := common.HexToAddress("xxxxx")

	instance, err := demo.NewDemo(address, client)
	if err != nil {
		log.Fatal(err)
	}
	// 替换原来的调用代码
	privateKey, err := crypto.HexToECDSA("xxxxx") // 请替换为真实私钥
	if err != nil {
		log.Fatal(err)
	}

	chainID, err := client.NetworkID(context.Background())
	if err != nil {
		log.Fatal(err)
	}

	auth, err := bind.NewKeyedTransactorWithChainID(privateKey, chainID)
	if err != nil {
		log.Fatal(err)
	}

	//auth.From = common.HexToAddress("0x1412a729118dd2337ad7f5de97be3876a61e2014")
	tx, err := instance.Add(auth)
	if err != nil {
		log.Fatal(err)
	}

	// 等待交易被挖出并获取回执
	_, err = bind.WaitMined(context.Background(), client, tx)
	if err != nil {
		log.Fatal(err)
	}

	// 打印交易哈希
	fmt.Printf("Transaction hash: %s\n", tx.Hash().Hex())

	// 如果合约有事件触发，可以从receipt.Logs中解析
	// 或者调用相关的view函数获取最新状态
	sumResult, err := instance.Sum(&bind.CallOpts{})
	if err != nil {
		log.Fatal(err)
	}
	fmt.Printf("Sum value: %s\n", sumResult.String())

}
