```bash
# 1.初始化项目 
go mod init blog

# 2.添加gorm组件和mysql数据库依赖包
go get -u gorm.io/gorm
go get -u gorm.io/driver/mysql

# 3.添加gin web框架
go get -u github.com/gin-gonic/gin

# 4.添加yaml文件解析包
go get gopkg.in/yaml.v3
go get sigs.k8s.io/yaml

# 5.添加swagger包
go install github.com/swaggo/swag/cmd/swag@latest

# 6、zap日志库、lumberjack日志拆分库
go get go.uber.org/zap
go get github.com/natefinch/lumberjack

# 7.jwt
 go get github.com/golang-jwt/jwt/v5