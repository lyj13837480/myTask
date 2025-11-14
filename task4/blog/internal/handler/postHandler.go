package handler

import (
	"blog/internal/logic"
	"blog/internal/model"
	"blog/pkg/db"
	"blog/pkg/response"
	"strconv"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type postHandler struct {
}

var PostHandler = new(postHandler)

func (a *postHandler) CreatePost(c *gin.Context) {
	var postReq model.PostReq
	if err := c.ShouldBindJSON(&postReq); err != nil {
		response.Error(c, err, "参数错误")
		return
	}
	post := model.Post{
		Title:   postReq.Title,
		Content: postReq.Content,
		UserID:  c.GetUint("userID"),
	}
	if err := logic.PostLogicInstance.CreatePost(&post); err != nil {
		response.Error(c, err, "创建文章失败")
		return
	}
	response.PutSuccess(c, nil)
}

func (a *postHandler) GetPostListWithPage(c *gin.Context) {
	var postReq db.QueryParams
	if err := c.ShouldBindJSON(&postReq); err != nil {
		response.Error(c, err, "参数错误")
		return
	}
	posts, err := logic.PostLogicInstance.GetPostListWithPage(postReq)
	if err != nil {
		response.Error(c, err, "获取文章列表失败")
	}
	response.Success(c, posts)
}

func (a *postHandler) GetPostById(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		response.Error(c, err, "参数错误")
		return
	}
	post, err := logic.PostLogicInstance.GetPostById(uint(id))
	if err != nil {
		response.Error(c, err, "获取文章失败")
	}
	response.Success(c, post)
}

func (a *postHandler) UpdatePost(c *gin.Context) {
	var postReq model.PostReq
	if err := c.ShouldBindJSON(&postReq); err != nil {
		response.Error(c, err, "参数错误")
		return
	}
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		response.Error(c, err, "参数错误")
		return
	}

	post := model.Post{
		Title:   postReq.Title,
		Content: postReq.Content,
		UserID:  c.GetUint("userID"),
		Model:   gorm.Model{ID: uint(id)},
	}
	if val, err := logic.PostLogicInstance.UpdatePost(&post); err != nil || val < 1 {
		response.Error(c, err, "更新文章失败")
		return
	}
	response.SuccessWithMsg(c, nil, "更新成功")
}

func (a *postHandler) DeletePost(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		response.Error(c, err, "参数错误")
		return
	}
	if val, err := logic.PostLogicInstance.DeletePost(uint(id), c.GetUint("userID")); err != nil || val < 1 {
		response.Error(c, err, "删除文章失败")
		return
	}
	response.SuccessWithMsg(c, nil, "删除成功")
}
