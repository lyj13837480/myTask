package main

import (
	"fmt"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

// 假设有一个名为 students 的表，包含字段 id （主键，自增）、 name （学生姓名，字符串类型）、 age （学生年龄，整数类型）、 grade （学生年级，字符串类型）。
// 要求 ：
// 编写SQL语句向 students 表中插入一条新记录，学生姓名为 "张三"，年龄为 20，年级为 "三年级"。
// 编写SQL语句查询 students 表中所有年龄大于 18 岁的学生信息。
// 编写SQL语句将 students 表中姓名为 "张三" 的学生年级更新为 "四年级"。
// 编写SQL语句删除 students 表中年龄小于 15 岁的学生记录。

type Student struct {
	ID    uint   //id （主键，自增）
	Name  string //name （学生姓名，字符串类型）
	Age   uint   //age （学生年龄，整数类型）
	Grade string //（学生年级，字符串类型）
}

func main() {
	fmt.Println("Hello, world!")
	db := connectDB()
	db.AutoMigrate(&Student{})

	// 编写SQL语句向 students 表中插入一条新记录，学生姓名为 "张三"，年龄为 20，年级为 "三年级"。
	db.Create(&Student{Name: "张三", Age: 20, Grade: "三年级"})

	// 编写SQL语句查询 students 表中所有年龄大于 18 岁的学生信息。
	var stu []Student
	db.Debug().Where("age > ?", 18).Order("ID DESC").Find(&stu)
	fmt.Println(stu)

	// 编写SQL语句将 students 表中姓名为 "张三" 的学生年级更新为 "四年级"。
	res := db.Debug().Model(&Student{}).Where("name = ?", "张三").Update("Grade", "四年级")
	fmt.Println(res.Error, res.RowsAffected)

	// 编写SQL语句删除 students 表中年龄小于 15 岁的学生记录。
	db.Model(&Student{}).Where("age < ?", 15).Delete(&Student{})

}

func connectDB() *gorm.DB {
	dsn := "my_study:jWmo2yItpMzc9FW6@tcp(mysql2.sqlpub.com:3307)/my_study_demo?charset=utf8mb4&parseTime=True&loc=Local"
	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})

	if err != nil {
		fmt.Println(err)
	}
	return db
}
