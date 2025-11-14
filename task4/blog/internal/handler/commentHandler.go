package handler

import (
	"blog/internal/logic"
	"blog/internal/model"
	"blog/pkg/response"

	"github.com/gin-gonic/gin"
)

type commentHandler struct{}

var CommentHandler = new(commentHandler)

func (a *commentHandler) CreateComment(c *gin.Context) {
	var commentReq model.CommentCMD

	if err := c.ShouldBindJSON(&commentReq); err != nil {
		response.Error(c, err, "参数错误")
		return
	}

	comment := model.Comment{
		UserID:  c.GetUint("userID"),
		PostID:  commentReq.PostID,
		Content: commentReq.Content,
	}
	if err := logic.CommentLogicInstance.CreateComment(&comment); err != nil {
		response.Error(c, err, "创建评论失败")
		return
	}

	response.PutSuccess(c, nil)
}

func (a *commentHandler) GetCommentByPostId(c *gin.Context) {
	var commentReq model.CommentPageReq
	if err := c.ShouldBindJSON(&commentReq); err != nil {
		response.Error(c, err, "参数错误")
		return
	}

	if comments, err := logic.CommentLogicInstance.GetCommentByPostId(&commentReq); err != nil {
		response.Error(c, err, "获取评论失败")
	} else {
		response.Success(c, comments)
	}
}
