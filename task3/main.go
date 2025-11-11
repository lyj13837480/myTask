package main

import (
	"fmt"

	"github.com/google/uuid"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

type strArr []byte

// User 拥有并属于多种 language，`user_languages` 是连接表
// User 拥有并属于多种 language，`user_languages` 是连接表
type User struct {
	gorm.Model
	Languages []*Language `gorm:"many2many:user_languages;"`
}

type Language struct {
	gorm.Model
	Name  string
	Users []*User `gorm:"many2many:user_languages;"`
}

type CreditCard struct {
	ID     uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4()"`
	Number string
	UserID uint
	Skills strArr
}

func main() {
	fmt.Println("hello world")
	db := connectDB()
	// db.AutoMigrate(&User{})
	// db.AutoMigrate(&Language{})
	// res := db.Create(&users)

	// fmt.Println(res.Error, res.RowsAffected)
	// users, _ := GetAll(db)
	// fmt.Println(users)

	// var users []User
	var languages []Language
	err := db.Model(&Language{}).Preload("Users").Find(&languages).Error
	fmt.Println(languages, err)
}

// 检索用户列表并预加载信用卡
func GetAll(db *gorm.DB) ([]User, error) {
	var users []User
	// err := db.Model(&User{}).Preload("CreditCard").Find(&users).Error
	err := db.Model(&User{}).Preload("CreditCard").Find(&users).Error
	return users, err
}

func connectDB() *gorm.DB {
	dsn := "my_study:jWmo2yItpMzc9FW6@tcp(mysql2.sqlpub.com:3307)/my_study_demo?charset=utf8mb4&parseTime=True&loc=Local"
	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		fmt.Println(err)
	}
	return db
}
