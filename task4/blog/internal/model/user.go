package model

import "gorm.io/gorm"

type User struct {
	gorm.Model
	UserName string `gorm:"index:;size:10;not null" json:"username"`
	Password string `gorm:"not null" json:"password"`
	Email    string `gorm:"index;not null" json:"email"`
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
