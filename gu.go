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

var formatPretty bool = false

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
	boolptrPretty := flag.Bool("pretty", false, "Show hidden files.")

	flag.Parse()

	if *boolptrShowHide {
		ShowFlag = SHOWFLAG_ALL
	}

	formatPretty = *boolptrPretty

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
		maxfiles    int = 100
		filePerLine int = 5
		lenPerLine  int = 75
	)

	c := color.New(color.FgWhite)
	switch msg {
	case "D":
		c = color.New(color.FgBlue)
	case "H":
		c = color.New(color.FgCyan)
	case "Z":
		c = color.New(color.FgRed)
	case "P":
		c = color.New(color.FgMagenta)
	case "E":
		c = color.New(color.FgGreen)
	default:
	}

	if len(fs) == 0 {
		return
	}

	if formatPretty {
		fmt.Printf("%s (%d):\n", msg, len(fs))
		i := 0
		lenline := 0

		for _, f := range fs {
			i++
			if i > maxfiles {
				break
			}

			c.Printf("%-16s\t", f)
			lenline += len(f)

			if lenline > lenPerLine || (i%filePerLine) == 0 {
				if i < len(fs) {
					c.Println()
				}
				lenline = 0
			}
		}
	} else {
		fmt.Printf("%s (%d):", msg, len(fs))
		if len(fs) > 1000 {
			fmt.Printf("\n  ")
		} else {
			fmt.Printf(" ")
		}

		for i, f := range fs {
			c.Printf("%s ", f)
			if i > maxfiles {
				break
			}
		}
	}

	fmt.Println()
}

const (
	SHOWFLAG_H   = 0x1 << 1
	SHOWFLAG_D   = 0x1 << 2
	SHOWFLAG_E   = 0x1 << 3
	SHOWFLAG_N   = 0x1 << 4
	SHOWFLAG_Z   = 0x1 << 5
	SHOWFLAG_P   = 0x1 << 6
	SHOWFLAG_ALL = SHOWFLAG_H | SHOWFLAG_D | SHOWFLAG_Z | SHOWFLAG_P | SHOWFLAG_E | SHOWFLAG_N
)

func showCurrentDir(bitflag int) {
	var err string
	var hide, dir, zfile, pfile, execfile, file []string

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

			if strings.HasSuffix(f.Name(), ".tar.gz") ||
				strings.HasSuffix(f.Name(), ".tar.bz2") ||
				strings.HasSuffix(f.Name(), ".zip") {
				zfile = append(zfile, f.Name())
				continue
			}

			if strings.HasSuffix(f.Name(), ".png") ||
				strings.HasSuffix(f.Name(), ".jpg") {
				pfile = append(pfile, f.Name())
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

		if (bitflag & SHOWFLAG_Z) != 0 {
			fn := func(i, j int) bool {
				return zfile[i] < zfile[j]
			}

			sort.Slice(zfile, fn)
			printFiles("Z", zfile)
		}

		if (bitflag & SHOWFLAG_P) != 0 {
			fn := func(i, j int) bool {
				return pfile[i] < pfile[j]
			}

			sort.Slice(pfile, fn)
			printFiles("P", pfile)
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
