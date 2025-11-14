package model

import "gorm.io/gorm"

type User struct {
	gorm.Model
	UserName string `gorm:"uniqueIndex;size:10;not null" json:"username" binding:"required,min=3,max=10"`
	Password string `gorm:"size:100;not null" json:"password" binding:"required,min=6,max=20"`
	Email    string `gorm:"index;not null" json:"email" binding:"email"`
	Role     string `gorm:"default:user" json:"role"`
}

type UserLoginReq struct {
	UserName string `json:"username"`
	Password string `json:"password"`
}

type UserLoginResp struct {
	Token string `json:"token"`
}

type UserPageReq struct {
	Page     int `json:"page" binding:"min=1"`
	PageSize int `json:"pageSize" binding:"min=1"`
}
