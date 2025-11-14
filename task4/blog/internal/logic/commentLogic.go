package logic

import (
	"blog/internal/model"
	"blog/pkg/db"
)

type commentLogic struct {
}

var CommentLogicInstance = new(commentLogic)

func (c *commentLogic) CreateComment(comment *model.Comment) error {
	return db.DB.Create(comment).Error
}

func (c *commentLogic) GetCommentByPostId(comment *model.CommentPageReq) ([]model.Comment, error) {
	var comments []model.Comment
	if res := db.DB.Model(&model.Comment{}).Where("post_id = ? ", comment.PostID).Scopes(db.PaginateTwo(comment.QueryParams.Page, comment.QueryParams.PageSize)).Find(&comments); res.Error != nil {
		return nil, res.Error
	}
	return comments, nil
}
