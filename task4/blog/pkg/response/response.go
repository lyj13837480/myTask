package response

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

type Response struct {
	Code int         `json:"code"`
	Data interface{} `json:"data"`
	Msg  string      `json:"msg"`
}

func Success(c *gin.Context, data interface{}) {
	c.JSON(http.StatusOK, Response{
		Code: 200,
		Data: data,
		Msg:  "success",
	})
}

func PutSuccess(c *gin.Context, data interface{}) {
	c.JSON(http.StatusCreated, Response{
		Code: 201,
		Data: data,
		Msg:  "success",
	})
}

func SuccessWithMsg(c *gin.Context, data interface{}, msg string) {
	c.JSON(http.StatusOK, Response{
		Code: 200,
		Data: data,
		Msg:  msg,
	})
}

func Fail(c *gin.Context, code int, msg string) {
	c.JSON(http.StatusOK, Response{
		Code: code,
		Data: nil,
		Msg:  msg,
	})
}

func Error(c *gin.Context, err error, msg string) {
	c.JSON(http.StatusOK, Response{
		Code: 500,
		Data: err,
		Msg:  msg,
	})
}

func FailStop(c *gin.Context, code int, msg string) {
	c.AbortWithStatusJSON(http.StatusOK, Response{
		Code: code,
		Msg:  msg,
		Data: nil,
	})
}
