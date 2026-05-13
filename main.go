package main

import (
	"bufio"
	"embed"
	"fmt"
	"io/fs"
	"os"
	"os/exec"
	"path/filepath"
)

//go:embed lute.exe src/*.luau src/components/*.luau
var embedded embed.FS

func main() {
	dir, err := os.MkdirTemp("", "green_luau")

	// does go have inline if statements like if (x) y?
	if err != nil {
		os.Exit(1)
	}

	// I LOVE WALKING DIRECTORIES
	err = fs.WalkDir(embedded, ".", func(path string, d fs.DirEntry, err error) error {
		if err != nil || path == "." {
			return err
		}

		targetPath := filepath.Join(dir, path)

		if d.IsDir() {
			return os.MkdirAll(targetPath, 0755)
		}

		content, err := embedded.ReadFile(path)
		if err != nil {
			return err
		}

		return os.WriteFile(targetPath, content, 0755)
	})

	if err != nil {
		os.Exit(1)
	}

	lute := filepath.Join(dir, "lute.exe")
	entry := filepath.Join(dir, "src", "main.luau")

	// this syntax is evil for what it acutally does i spent 10 minutes on this
	cmd := exec.Command(lute, append([]string{entry}, os.Args[1:]...)...)
	cmd.Dir = filepath.Join(dir, "src")

	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	err = cmd.Run()
	if err != nil {
		fmt.Println("green luau has errored.")
		bufio.NewReader(os.Stdin).ReadByte()
		os.Exit(1)
	}
}
