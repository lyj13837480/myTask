package main

import (
	"fmt"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

// 题目1：模型定义
// 假设你要开发一个博客系统，有以下几个实体： User （用户）、 Post （文章）、 Comment （评论）。
// 要求 ：
// 使用Gorm定义 User 、 Post 和 Comment 模型，其中 User 与 Post 是一对多关系（一个用户可以发布多篇文章）， Post 与 Comment 也是一对多关系（一篇文章可以有多个评论）。
// 编写Go代码，使用Gorm创建这些模型对应的数据库表。

// 题目2：关联查询
// 基于上述博客系统的模型定义。
// 要求 ：
// 编写Go代码，使用Gorm查询某个用户发布的所有文章及其对应的评论信息。
// 编写Go代码，使用Gorm查询评论数量最多的文章信息。

// 题目3：钩子函数
// 继续使用博客系统的模型。
// 要求 ：
// 为 Post 模型添加一个钩子函数，在文章创建时自动更新用户的文章数量统计字段。
// 为 Comment 模型添加一个钩子函数，在评论删除时检查文章的评论数量，如果评论数量为 0，则更新文章的评论状态为 "无评论"。

type User struct {
	gorm.Model
	Name      string `gorm:"column:name"`
	PostCount int    `gorm:"column:post_count"`
	Posts     []Post
}

type Post struct {
	gorm.Model
	Title         string `gorm:"column:title"`
	Content       string `gorm:"column:content"`
	UserID        uint   `gorm:"column:user_id"`
	CommentCount  int    `gorm:"column:comment_count"`
	CommentStatus string `gorm:"column:comment_status"`
	Comments      []Comment
}

// 题目3：钩子函数
// 为 Post 模型添加一个钩子函数，在文章创建时自动更新用户的文章数量统计字段。
func (p *Post) AfterCreate(tx *gorm.DB) (err error) {

	tx.Debug().Model(&User{Model: gorm.Model{ID: p.ID}}).Update("post_count", gorm.Expr("post_count + 1"))

	return
}

type Comment struct {
	gorm.Model
	Content string `gorm:"column:content"`
	PostID  uint   `gorm:"column:post_id"`
}

// 题目3：钩子函数
// 为 Comment 模型添加一个钩子函数，在评论删除时检查文章的评论数量，如果评论数量为 0，则更新文章的评论状态为 "无评论"。
func (c *Comment) AfterDelete(tx *gorm.DB) (err error) {
	var post Post
	tx.Debug().Find(&post, c.PostID)

	if post.CommentCount-1 < 0 {
		post.CommentCount = 0
	} else {
		post.CommentCount = post.CommentCount - 1
	}
	if post.CommentCount == 0 {
		post.CommentStatus = "无评论"
		tx.Save(&post)
	}
	return
}

func main() {
	fmt.Println("hello world")
	db := connectDB()

	// 2. 造点测试数据
	users := []User{
		{Name: "Geektutu"},
	}
	db.Create(&users)
	posts := []Post{
		{Title: "Go 入门", Content: "Go 基础教程", UserID: 1},
		{Title: "GORM 技巧", Content: "GORM 高级用法", UserID: 1},
		{Title: "面试指南", Content: "常见面试题", UserID: 1},
	}
	db.Create(&posts)

	comments := []Comment{
		{PostID: posts[0].ID, Content: "赞"},
		{PostID: posts[0].ID, Content: "学习了"},
		{PostID: posts[1].ID, Content: "收藏"},
		{PostID: posts[1].ID, Content: "写得好"},
		{PostID: posts[1].ID, Content: "感谢分享"},
		{PostID: posts[2].ID, Content: "马克"},
	}
	db.Create(&comments)

	// 题目1：模型定义
	createTable(db)

	// 题目2：关联查询

	// 编写Go代码，使用Gorm查询某个用户发布的所有文章及其对应的评论信息。
	//fmt.Println(queryUserPostsAndComments(db, 1))
	// 编写Go代码，使用Gorm查询评论数量最多的文章信息。
	//fmt.Println(queryMostCommentsPost(db))

	// 题目3：钩子函数

}

func connectDB() *gorm.DB {
	dsn := "my_study:jWmo2yItpMzc9FW6@tcp(mysql2.sqlpub.com:3307)/my_study_demo?charset=utf8mb4&parseTime=True&loc=Local"
	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		panic(err)
	}
	return db
}

// 题目1：模型定义
// 假设你要开发一个博客系统，有以下几个实体： User （用户）、 Post （文章）、 Comment （评论）。
// 要求 ：
// 使用Gorm定义 User 、 Post 和 Comment 模型，其中 User 与 Post 是一对多关系（一个用户可以发布多篇文章）， Post 与 Comment 也是一对多关系（一篇文章可以有多个评论）。
// 编写Go代码，使用Gorm创建这些模型对应的数据库表。
func createTable(db *gorm.DB) {
	db.AutoMigrate(&User{}, &Post{}, &Comment{})
}

// 题目2：关联查询
// 编写Go代码，使用Gorm查询某个用户发布的所有文章及其对应的评论信息。
func queryUserPostsAndComments(db *gorm.DB, userID uint) ([]Post, error) {
	var posts []Post
	res := db.Debug().Preload("Comments").Where("user_id = ?", userID).Find(&posts)
	return posts, res.Error
}

// 题目2：关联查询
// 编写Go代码，使用Gorm查询评论数量最多的文章信息。
func queryMostCommentsPost(db *gorm.DB) (Post, error) {
	var post Post
	var postID uint
	db.Debug().Model(&Comment{}).Select("post_id").Group("post_id").Order("count(post_id) desc").Limit(1).Find(&postID)
	res := db.Debug().Preload("Comments").Find(&post, postID)
	return post, res.Error
}
