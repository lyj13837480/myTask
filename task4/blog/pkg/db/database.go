package db

import (
	"blog/internal/config"
	"fmt"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

var DB *gorm.DB

func InitDB() error {
	cfg := config.GetConfig().Mysql
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%d)/%s?charset=utf8mb4&parseTime=True&loc=Local", cfg.User, cfg.Pass,
		cfg.Host, cfg.Port, cfg.Database)
	// dsn := "my_study:jWmo2yItpMzc9FW6@tcp(mysql2.sqlpub.com:3307)/my_study_demo?charset=utf8mb4&parseTime=True&loc=Local"

	var err error
	DB, err = gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		panic(err)
	}

	sqlDB, _ := DB.DB()
	if pingErr := sqlDB.Ping(); pingErr != nil { //测试数据库连接
		fmt.Errorf("数据库连接失败:%s \n", pingErr)
		return pingErr
	}
	return nil
}
