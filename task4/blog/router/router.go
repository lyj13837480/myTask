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
		api.PUT("/register", handler.Register)
		api.POST("/login", handler.Login)
		api.POST("/post_list", handler.PostHandler.GetPostListWithPage)
		api.POST("/comment_list", handler.CommentHandler.GetCommentByPostId)

		api.Use(middleware.AuthMiddleware())

		// 文章
		api.PUT("/post", handler.PostHandler.CreatePost)
		api.POST("/post/:id", handler.PostHandler.UpdatePost)
		api.DELETE("/post/:id", handler.PostHandler.DeletePost)

		// 评论
		api.PUT("/comment", handler.CommentHandler.CreateComment)
	}

	return r
}
