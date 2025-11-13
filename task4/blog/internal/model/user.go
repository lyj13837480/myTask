package model

import "gorm.io/gorm"

type User struct {
	gorm.Model
	UserName string `gorm:"uniqueIndex;not null"`
	Password string `gorm:"not null"`
	Email    string `gorm:"uniqueIndex;not null"`
	Role     string `gorm:"default:user"`
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
