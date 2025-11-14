package logic

import (
	"blog/internal/model"
	"blog/pkg/db"
	error2 "blog/pkg/error"

	"gorm.io/gorm"
)

type postLogic struct {
}

var PostLogicInstance = postLogic{}

func (p *postLogic) CreatePost(post *model.Post) error {
	return db.DB.Create(post).Error
}

func (p *postLogic) GetPostListWithPage(post db.QueryParams) (*db.PagedResult, error) {
	return db.Paginate(db.DB, post, &[]model.Post{})
}

func (a *postLogic) GetPostById(id uint) (*model.Post, error) {
	var post model.Post
	return &post, db.DB.First(&post, id).Error
}

func (a *postLogic) GetPostByIdWithCmt(id uint) (*model.Post, error) {
	var post model.Post
	return &post, db.DB.Preload("comments").First(&post, id).Error
}

func (a *postLogic) UpdatePost(post *model.Post) (int64, error) {
	res := db.DB.Model(&model.Post{}).Where("id = ? and user_id = ? ", post.ID, post.UserID).Updates(post)
	return res.RowsAffected, res.Error
}

func (a *postLogic) DeletePost(id uint, userID uint) (int64, error) {
	var res *gorm.DB
	var count int64

	if err := db.DB.Model(&model.Post{}).Where("id = ? and user_id = ?", id, userID).Count(&count); err.Error != nil {
		return 0, err.Error
	}
	if count < 1 {
		return 0, error2.ErrUnauthorized
	}

	// TODO 删除文章 开启事务同步删除评论
	db.DB.Transaction(func(tx *gorm.DB) error {
		if res = db.DB.Model(&model.Post{}).Delete(&model.Post{}, id); res.Error != nil {
			return res.Error
		}
		if res := db.DB.Model(&model.Comment{}).Where("post_id = ?", id).Delete(&model.Comment{}); res.Error != nil {
			return res.Error
		}
		return nil
	})

	return res.RowsAffected, res.Error
}
