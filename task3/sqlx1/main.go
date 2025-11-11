package main

import (
	"fmt"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

// 题目1：使用SQL扩展库进行查询
// 假设你已经使用Sqlx连接到一个数据库，并且有一个 employees 表，包含字段 id 、 name 、 department 、 salary 。
// 要求 ：
// 编写Go代码，使用Sqlx查询 employees 表中所有部门为 "技术部" 的员工信息，并将结果映射到一个自定义的 Employee 结构体切片中。
// 编写Go代码，使用Sqlx查询 employees 表中工资最高的员工信息，并将结果映射到一个 Employee 结构体中。

type Employee struct {
	ID         int     `gorm:"column:id;primaryKey"`
	Name       string  `gorm:"column:name"`
	Department string  `gorm:"column:department"`
	Salary     float64 `gorm:"column:salary"`
}

func main() {
	fmt.Println("Hello, world!")
	db := connectDB()
	//db.AutoMigrate(&Employee{})
	var employees []Employee
	// 编写Go代码，使用Sqlx查询 employees 表中所有部门为 "技术部" 的员工信息，并将结果映射到一个自定义的 Employee 结构体切片中。
	db.Where("department = ?", "技术部").Find(&employees)
	fmt.Println(employees)
	var employees1 []Employee
	// 编写Go代码，使用Sqlx查询 employees 表中工资最高的员工信息，并将结果映射到一个 Employee 结构体中。
	// 子查询逻辑
	db.Where("salary = (?)", db.Table("employees").Select("max(salary)")).Find(&employees1)
	fmt.Println(employees1)

}

func connectDB() *gorm.DB {
	dsn := "my_study:jWmo2yItpMzc9FW6@tcp(mysql2.sqlpub.com:3307)/my_study_demo?charset=utf8mb4&parseTime=True&loc=Local"
	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})

	if err != nil {
		panic(err)
	}
	return db
}
