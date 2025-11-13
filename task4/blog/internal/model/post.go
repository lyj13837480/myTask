package model

import "gorm.io/gorm"

type Post struct {
	gorm.Model
	Title   string `gorm:"type:varchar(100);not null" json:"title"`
	Content string
	UserID  uint `gorm:"index;not null" json:"user_id"`
}
