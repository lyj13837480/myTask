package main

import (
	"blog/internal/config"
	"blog/internal/model"
	"blog/pkg/db"
	"blog/pkg/log"
	"fmt"
)

func main() {
	fmt.Println("hello world")
	config.InitConfig("etc/config.yaml")

	db.InitDB()
	logErr := log.InitLogger()
	if logErr != nil {
		panic(logErr)
	}
	log.Logger.Info("项目配置初始化成功")
	log.Logger.Info("项目日志初始化成功")

	db.DB.AutoMigrate(&model.User{}, &model.Post{}, &model.Comment{})
	log.Logger.Info("项目数据库初始化成功")

}
