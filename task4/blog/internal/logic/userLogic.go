package logic

import (
	"blog/internal/model"
	"blog/pkg/auth"
	"blog/pkg/db"

	"golang.org/x/crypto/bcrypt"
)

type userLogic struct{}

var UserLogic = new(userLogic)

// 注册
func (u *userLogic) Register(req *model.User) error {
	bcryptPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return err
	}
	req.Password = string(bcryptPassword)
	return db.DB.Create(req).Error
}

// 登录
func (u *userLogic) Login(req *model.UserLoginReq) (*model.UserLoginResp, error) {
	user := &model.User{}
	if err := db.DB.Where("user_name = ?", req.UserName).First(user).Error; err != nil {
		return nil, err
	}
	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password)); err != nil {
		return nil, err
	}
	token, _ := auth.GenerateToken(*user)
	return &model.UserLoginResp{
		Token: token,
	}, nil
}
