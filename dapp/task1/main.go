package main

import (
	"context"
	"crypto/ecdsa"
	"fmt"
	"math/big"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
)

func main() {
	fmt.Printf("Hello and welcome\n")
	client, err := ethclient.Dial("https://sepolia.infura.io/v3/xxxx")

	if err != nil {
		fmt.Println(err)
	}
	fmt.Println("Connected to Ethereum")
	//获取最新块号
	blockNumber, err := client.BlockNumber(context.Background())

	if err != nil {
		fmt.Println(err)
	}
	fmt.Println("Current Block Number: ", blockNumber)

	block, err := client.BlockByNumber(context.Background(), big.NewInt(int64(blockNumber)))
	if err != nil {
		fmt.Println(err)
	}
	fmt.Println("Current Block Transactions: ", len(block.Transactions()))
	fmt.Println("Current Block Uncles: ", block.Uncles())
	fmt.Println("Current Block time: ", block.Time())
	fmt.Println("Current Block Difficulty: ", block.Hash().Hex())

	//获取私钥
	privateKey, err := crypto.HexToECDSA("xxxx")
	if err != nil {
		fmt.Println(err)
	}
	//获取公钥
	publicKey := privateKey.Public()
	publicKeyEC, ok := publicKey.(*ecdsa.PublicKey)

	if !ok {
		fmt.Println("cannot assert type: publicKey is not of type *ecdsa.PublicKey")
	}
	fromAddress := crypto.PubkeyToAddress(*publicKeyEC)
	fmt.Println("fromAddress: ", fromAddress.Hex())
	//获取nonce
	nonce, err := client.PendingNonceAt(context.Background(), fromAddress)

	if err != nil {
		fmt.Println(err)
	}
	fmt.Println("Pending Nonce: ", nonce)
	//10^18wei = 1 ether
	value := big.NewInt(10000000000000000)
	//gasLimit,转账默认21000
	gasLimit := uint64(21000)
	//获取gasPrice
	gasPrice, err := client.SuggestGasPrice(context.Background())

	toAddress := common.HexToAddress("xxxx")

	var data []byte
	//交易构造
	tx := types.NewTransaction(nonce, toAddress, value, gasLimit, gasPrice, data)
	//获取chainID
	chainID, err := client.ChainID(context.Background())

	if err != nil {
		fmt.Println(err)
	}
	//签名交易
	signedTx, err := types.SignTx(tx, types.NewEIP155Signer(chainID), privateKey)
	if err != nil {
		fmt.Println(err)
	}
	//发送交易
	err = client.SendTransaction(context.Background(), signedTx)
	if err != nil {
		fmt.Println(err)
	}

	fmt.Println("tx sent: ", signedTx.Hash().Hex())
}
