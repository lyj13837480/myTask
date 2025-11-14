package model

import "gorm.io/gorm"

type Post struct {
	gorm.Model
	Title    string `gorm:"size:100;not null"`
	Content  string `gorm:"not null"`
	UserID   uint   `gorm:"index;not null"`
	Comments []Comment
}

type PostPageReq struct {
	Page     uint   `json:"page" binding:"min=1"`
	PageSize uint   `json:"pageSize" binding:"min=1"`
	Title    string `json:"title" binding:"required,min=1,max=100"`
}
type PostReq struct {
	Title   string `json:"title" binding:"required,min=1,max=100"`
	Content string `json:"content" binding:"required"`
}
