package middleware

import (
	error2 "blog/pkg/error"
	"blog/pkg/log"
	"blog/pkg/response"
	"errors"
	"net/http"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

func GlobalErrorHandlerMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Next()
		// 检查是否有错误
		if len(c.Errors) > 0 {
			for _, err := range c.Errors {
				// 处理不同类型的错误
				switch {
				case errors.Is(err.Err, error2.ErrInvalidCredentials):
					response.FailStop(c, error2.ErrInvalidCredentials.Code, error2.ErrInvalidCredentials.Error())
					return
				case errors.Is(err.Err, error2.ErrInvalidParams):
					response.FailStop(c, error2.ErrInvalidParams.Code, error2.ErrInvalidParams.Error())
					return
				case errors.Is(err.Err, error2.ErrUnauthorized):
					response.FailStop(c, error2.ErrUnauthorized.Code, error2.ErrUnauthorized.Error())
					return
				case errors.Is(err.Err, gorm.ErrRecordNotFound):
					response.FailStop(c, http.StatusInternalServerError, "数据不存在")
					return
				default:
					// 默认错误处理
					log.Logger.Error("捕获到错误: " + err.Error())
					response.FailStop(c, error2.ErrSystem.Code, error2.ErrSystem.Message)
					return
				}
			}
		}
	}
}
