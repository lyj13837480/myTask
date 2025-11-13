package config

import "testing"

func TestLoadConfig(t *testing.T) {
	loadConfig("../../etc/config.yaml")
}
