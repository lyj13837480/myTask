package model

import "gorm.io/gorm"

type Comment struct {
	gorm.Model
	UserID  uint
	PostID  uint
	Content string
}
