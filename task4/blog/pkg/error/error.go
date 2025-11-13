package error

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

type BlogError struct {
	Code    int    `json:"code"`
	ErrCode string `json:"err_code"`
	Message string `json:"message"`
}

var (
	ErrSystem             = &BlogError{http.StatusInternalServerError, "SYSTEM_ERROR", "系统异常,请稍后再试"}
	ErrUserNotFound       = &BlogError{http.StatusNotFound, "USER_NOT_FOUND", "用户不存在"}
	ErrInvalidCredentials = &BlogError{http.StatusUnauthorized, "INVALID_CREDENTIALS", "认证失败"}
	ErrUnauthorized       = &BlogError{http.StatusForbidden, "UNAUTHORIZED", "权限不足"}
	ErrInvalidParams      = &BlogError{http.StatusBadRequest, "INVALID_REQUEST", "请求参数错误"}
	ErrDBConnect          = &BlogError{301001, "ER_DB_CONNECT_FAIL", "数据库连接失败"}
)

func (e *BlogError) Error() string {
	return e.Message
}

// 抛出错误
func ThrowErr(c *gin.Context, appErr *BlogError, message string) {
	if message != "" {
		appErr.Message = message
	}
	c.Error(appErr)
	c.Abort()
}
