package main

import (
	"fmt"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

// 题目2：实现类型安全映射
// 假设有一个 books 表，包含字段 id 、 title 、 author 、 price 。
// 要求 ：
// 定义一个 Book 结构体，包含与 books 表对应的字段。
// 编写Go代码，使用Sqlx执行一个复杂的查询，例如查询价格大于 50 元的书籍，并将结果映射到 Book 结构体切片中，确保类型安全。

type Book struct {
	ID     uint    `gorm:"column:id;primaryKey"`
	Title  string  `gorm:"column:title"`
	Author string  `gorm:"column:author"`
	Price  float64 `gorm:"column:price"`
}

type Book2 struct {
	ID    uint
	Title string
}

func main() {
	fmt.Println("hello world")

	db := connectDB()
	db.AutoMigrate(&Book{})
	db.Create(&Book{Title: "Go 语言", Author: "Geektutu", Price: 49.9})
	db.Create(&Book{Title: "Go 语言", Author: "Geektutu", Price: 59.9})
	fmt.Println(queryBooks(db))
}

func queryBooks(db *gorm.DB) []Book2 {
	var books []Book2
	db.Model(&Book{}).Where("Price > ?", 50).Find(&books)
	return books
}

func connectDB() *gorm.DB {
	dsn := "my_study:jWmo2yItpMzc9FW6@tcp(mysql2.sqlpub.com:3307)/my_study_demo?charset=utf8mb4&parseTime=True&loc=Local"
	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})

	if err != nil {
		panic(err)
	}
	return db
}
