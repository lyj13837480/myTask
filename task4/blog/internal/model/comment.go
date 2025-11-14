package model

import (
	"blog/pkg/db"

	"gorm.io/gorm"
)

type Comment struct {
	gorm.Model
	UserID  uint
	PostID  uint
	Content string
}

type CommentCMD struct {
	Content string `json:"content" binding:"required"`
	PostID  uint   `json:"post_id" binding:"required"`
}

type CommentPageReq struct {
	db.QueryParams `json:"query_params"`
	PostID         uint `json:"post_id" binding:"required"`
}
