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
		response.Error(c, err, "参数错误")
		return
	}
	if err := logic.UserLogic.Register(&user); err != nil {
		response.Error(c, err, "注册失败")
		return
	}
	response.PutSuccess(c, nil)
}

func Login(c *gin.Context) {
	var user model.UserLoginReq
	if err := c.ShouldBindJSON(&user); err != nil {
		response.Error(c, err, "参数错误")
		return
	}
	token, err := logic.UserLogic.Login(&user)
	if err != nil {
		response.Error(c, err, "登录失败")
		return
	}

	response.Success(c, token)
}
