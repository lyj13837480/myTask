package handler

import (
	"blog/internal/logic"
	"blog/internal/model"
	"blog/pkg/response"

	"github.com/gin-gonic/gin"
)

func Register(c *gin.Context) {
	var user model.User
	if err := c.ShouldBindJSON(&user); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}
	if err := logic.UserLogic.Register(&user); err != nil {
		c.JSON(400, gin.H{"error": err.Error()})
		return
	}
	response.Success(c, nil, "注册成功")
}
