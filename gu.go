package main

import (
	"flag"
	"fmt"
	"github.com/fatih/color"
	"io/ioutil"
	"os"
	"runtime"
	"sort"
	"strings"
)

func code(depthList ...int) string {
	var depth int

	if depthList == nil {
		depth = 1
	} else {
		depth = depthList[0]
	}
	pc, _, line, _ := runtime.Caller(depth)
	return fmt.Sprintf("%s - %d", runtime.FuncForPC(pc).Name(), line)
}

func main() {

	ShowFlag := SHOWFLAG_ALL & (^SHOWFLAG_H)

	boolptrShowHide := flag.Bool("showHide", false, "Show hidden files.")
	boolptrShowPath := flag.Bool("showPath", false, "Show hidden files.")

	flag.Parse()

	if *boolptrShowHide {
		ShowFlag = SHOWFLAG_ALL
	}

	topath := flag.Args()

	if *boolptrShowPath {
		if len(topath) > 0 {
			fmt.Printf("%s", topath[0])
		}
		os.Exit(0)
	}

	showCurrentDir(ShowFlag)
}

func printFiles(msg string, fs []string) {
	const (
		maxfiles int = 100
	)

	if len(fs) == 0 {
		return
	}

	fmt.Printf("%s (%d):", msg, len(fs))
	if len(fs) > 1000 {
		fmt.Printf("\n  ")
	} else {
		fmt.Printf(" ")
	}
	for i, f := range fs {
		c := color.New(color.FgWhite)

		if msg == "D" {
			c = color.New(color.FgBlue)
		}

		if msg == "H" {
			c = color.New(color.FgCyan)
		}

		if msg == "E" {
			c = color.New(color.FgGreen)
		}
		c.Printf("%s ", f)

		if i > maxfiles {
			break
		}
	}
	fmt.Println()
}

const (
	SHOWFLAG_H   = 0x1 << 1
	SHOWFLAG_D   = 0x1 << 2
	SHOWFLAG_E   = 0x1 << 3
	SHOWFLAG_N   = 0x1 << 4
	SHOWFLAG_ALL = SHOWFLAG_H | SHOWFLAG_D | SHOWFLAG_E | SHOWFLAG_N
)

func showCurrentDir(bitflag int) {
	var err string
	var hide, dir, execfile, file []string

	for {
		curr, err := os.Getwd()
		if err != nil {
			break
		}

		files, err := ioutil.ReadDir(curr)
		if err != nil {
			break
		}

		for _, f := range files {

			if strings.HasPrefix(f.Name(), ".") {
				hide = append(hide, f.Name())
				continue
			}

			if f.IsDir() {
				dir = append(dir, f.Name()+"/")
				continue
			}

			if (f.Mode() & 0111) != 0 {
				execfile = append(execfile, f.Name())
				continue
			}

			file = append(file, f.Name())
		}

		if (bitflag & SHOWFLAG_H) != 0 {
			fn := func(i, j int) bool {
				return hide[i] < hide[j]
			}

			sort.Slice(hide, fn)
			printFiles("H", hide)
		}
		if (bitflag & SHOWFLAG_D) != 0 {
			fn := func(i, j int) bool {
				return dir[i] < dir[j]
			}

			sort.Slice(dir, fn)
			printFiles("D", dir)
		}
		if (bitflag & SHOWFLAG_E) != 0 {
			fn := func(i, j int) bool {
				return execfile[i] < execfile[j]
			}

			sort.Slice(execfile, fn)
			printFiles("E", execfile)
		}
		if (bitflag & SHOWFLAG_N) != 0 {
			fn := func(i, j int) bool {
				return file[i] < file[j]
			}

			sort.Slice(file, fn)
			printFiles("N", file)
		}

		break
	}
	fmt.Println()

	if err != "" {
		fmt.Fprintf(os.Stderr, "Err: %s\n", err)
	}
}
