package config

import (
	"fmt"
	"os"
	"sync"

	"gopkg.in/yaml.v3"
)

var (
	config *Config
	once   sync.Once
)

type Config struct {
	Server struct {
		Port string `yaml:"port"`
		// Host string `yaml:"host"`
		Env  string `yaml:"env"`
		Name string `yaml:"name"`
	} `yaml:"server"`

	Mysql struct {
		Host     string `yaml:"host"`
		Port     uint   `yaml:"port"`
		User     string `yaml:"user"`
		Pass     string `yaml:"password"`
		Database string `yaml:"database"`
	} `yaml:"mysql"`

	Auth struct {
		JwtSecret string `yaml:"jwt_secret"`
		JwtExpire int    `yaml:"jwt_expire"`
	} `yaml:"auth"`

	Log struct {
		Level string `yaml:"level"`
		Path  string `yaml:"path"`
	} `yaml:"log"`
}

func InitConfig(filePath string) {
	once.Do(func() { //单例模式，配置文件只被初始化一次
		config = &Config{}
		loadConfig(filePath)
	})
}

func GetConfig() *Config {
	return config
}

func loadConfig(path string) *Config {
	file, err := os.Open(path)
	if err != nil {
		fmt.Printf("加载文件失败%s \n", path)
		panic(err) //触发崩溃，可以通过recover()捕获处理
	}

	err = yaml.NewDecoder(file).Decode(config)
	if err != nil {
		fmt.Printf("解析文件失败%s \n", path)
		panic(err)
	}

	return config
}
