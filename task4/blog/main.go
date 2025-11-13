package main

import (
	"blog/internal/config"
	"blog/internal/model"
	"blog/pkg/db"
	"blog/pkg/log"
	"blog/router"
	"fmt"
)

func main() {
	fmt.Println("hello world")
	config.InitConfig("task4/blog/etc/config.yaml")

	logErr := log.InitLogger()
	if logErr != nil {
		panic(logErr)
	}
	log.Logger.Info("项目配置初始化成功")
	log.Logger.Info("项目日志初始化成功")

	db.InitDB()
	dbErr := db.DB.AutoMigrate(&model.User{}, &model.Post{}, &model.Comment{})
	if dbErr != nil {
		panic(dbErr)
	}
	log.Logger.Info("项目数据库初始化成功")

	r := router.InitRouter()
	rErr := r.Run(":" + config.GetConfig().Server.Port)
	log.Logger.Info("项目路由启动成功")
	if rErr != nil {
		panic(rErr)
	}

}
