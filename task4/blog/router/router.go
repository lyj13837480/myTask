package router

import (
	"blog/internal/handler"
	"blog/internal/middleware"

	"github.com/gin-gonic/gin"
)

func InitRouter() *gin.Engine {
	gin.SetMode(gin.DebugMode)

	r := gin.New()
	r.Use(gin.Recovery())
	r.Use(middleware.GlobalErrorHandlerMiddleware(), middleware.LoggerMiddleware())

	api := r.Group("/v1")
	{
		api.POST("/register", handler.Register)
	}

	return r
}
