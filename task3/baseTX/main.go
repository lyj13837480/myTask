package main

import (
	"fmt"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

// 假设有两个表： accounts 表（包含字段 id 主键， balance 账户余额）和 transactions 表（包含字段 id 主键， from_account_id 转出账户ID， to_account_id 转入账户ID， amount 转账金额）。
// 要求 ：
// 编写一个事务，实现从账户 A 向账户 B 转账 100 元的操作。
// 在事务中，需要先检查账户 A 的余额是否足够，如果足够则从账户 A 扣除 100 元，向账户 B 增加 100 元，并在 transactions 表中记录该笔转账信息。
// 如果余额不足，则回滚事务。

// accounts 表（包含字段 id 主键， balance 账户余额）
type Account struct {
	gorm.Model
	Balance float64
}

// transactions 表（包含字段 id 主键， from_account_id 转出账户ID， to_account_id 转入账户ID， amount 转账金额）。
type Transaction struct {
	gorm.Model
	FromAccountID uint
	ToAccountID   uint
	Amount        float64
}

func main() {
	fmt.Println("Hello, world!")
	db := connectDB()
	db.AutoMigrate(&Account{})
	db.AutoMigrate(&Transaction{})
	var accounts []Account
	//预定义账户
	accounts = append(accounts, Account{Balance: 1000})
	accounts = append(accounts, Account{Balance: 0})

	// 编写一个事务，实现从账户 A 向账户 B 转账 100 元的操作。
	// 在事务中，需要先检查账户 A 的余额是否足够，如果足够则从账户 A 扣除 100 元，向账户 B 增加 100 元，并在 transactions 表中记录该笔转账信息。
	// 如果余额不足，则回滚事务。
	db.Transaction(func(tx *gorm.DB) error {
		//1.初始化账户
		res := tx.Create(&accounts)
		if res.Error != nil {
			return res.Error
		}
		//2.查询账号
		var accountFrom, accountTo Account
		tx.Take(&accountFrom, 1)
		tx.Take(&accountTo, 2)
		if (accountFrom == Account{}) || (accountTo == Account{}) {
			return fmt.Errorf("账户不存在")
		}
		//3.判断余额
		if accountFrom.Balance < 100 {
			return fmt.Errorf("余额不足")
		}
		//4.交易
		accountFrom.Balance -= 100
		accountTo.Balance += 100

		var acc []Account
		acc = append(acc, accountFrom)
		acc = append(acc, accountTo)
		//5.保存
		tx.Save(acc)
		resT := tx.Create(&Transaction{FromAccountID: accountFrom.ID, ToAccountID: accountTo.ID, Amount: 100})
		if resT.Error != nil {
			return resT.Error
		}

		return nil
	})
}

func connectDB() *gorm.DB {
	dsn := "my_study:jWmo2yItpMzc9FW6@tcp(mysql2.sqlpub.com:3307)/my_study_demo?charset=utf8mb4&parseTime=True&loc=Local"
	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})

	if err != nil {
		panic(err)
	}
	return db
}
