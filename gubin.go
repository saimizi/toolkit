package main

import (
	"bufio"
	"flag"
	"fmt"
	"github.com/fatih/color"
	"github.com/yookoala/realpath"
	"io/ioutil"
	"os"
	"os/exec"
	"runtime"
	"sort"
	"strconv"
	"strings"
)

var formatPretty bool = false
var envFile string = "/home/joukan/.guenv"

type optstr struct {
	before string
	after  string
}

var OptStrings = [...]optstr{
	{"/home/joukan", "~"},
}

type Record struct {
	Weight int
	Path   string
}

func (c Record) optPath() string {

	for _, s := range OptStrings {
		if strings.Contains(c.Path, s.before) {
			return strings.ReplaceAll(c.Path, s.before, s.after)
		}

	}

	return c.Path
}

var records []Record

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

func loadEnv() error {

	f, err := os.Open(envFile)
	if err != nil {
		return err
	}

	if err == nil {
		var record Record

		scanner := bufio.NewScanner(f)
		for scanner.Scan() {
			_, err := fmt.Sscanf(scanner.Text(), "%d,%s", &record.Weight, &record.Path)
			if err != nil {
				continue
			}

			records = append(records, record)
		}

	}

	f.Close()

	return err
}

func saveEnv() error {

	f, err := os.Create(envFile)

	if err == nil {

		fn := func(i, j int) bool {
			return records[i].Path < records[j].Path
		}
		sort.Slice(records, fn)

		for _, r := range records {
			str := fmt.Sprintf("%d,%s\n", r.Weight, r.Path)

			_, err = f.WriteString(str)
			if err != nil {
				continue
			}

		}
	}

	f.Close()

	return err
}

func cleanPathes() {

	var newrecords []Record

	updated := false

	for _, r := range records {
		fi, err := os.Stat(r.Path)
		if err != nil {
			updated = true
			continue
		}

		if !fi.IsDir() {
			updated = true
			continue
		}

		newrecords = append(newrecords, r)
	}

	records = newrecords

	if updated {
		saveEnv()
	}
}

func showPathes() {

	curr, err := os.Getwd()
	if err != nil {
		return
	}

	fmt.Printf("%3d) %s\n", 0, curr)

	for i, p := range records {
		fmt.Printf("%3d) %s (%d)\n", i+1, p.optPath(), p.Weight)
	}
}

func showNextPath(topath string) bool {

	fn := func(i, j int) bool {
		return records[i].Path < records[j].Path
	}
	sort.Slice(records, fn)

	i, err := strconv.Atoi(topath)

	if err == nil {
		j := i - 1

		if j < 0 {
			curr, err := os.Getwd()
			if err == nil {
				fmt.Printf(curr)
			}

			return true
		}

		if j < len(records) {
			fmt.Printf(records[j].Path)
			records[j].Weight++
			return true
		}
	}

	realTopath, err := realpath.Realpath(topath)
	if err == nil {

		for i, r := range records {
			if r.Path == realTopath {
				fmt.Printf(r.Path)
				records[i].Weight++
				return true
			}

			if (r.Path + "/") == realTopath {
				fmt.Printf(r.Path)
				records[i].Weight++
				return true
			}
		}

		fi, err := os.Stat(realTopath)
		if err == nil {
			if fi.IsDir() {
				var newrecord Record

				newrecord.Weight = 1
				newrecord.Path = realTopath

				records = append(records, newrecord)

				fmt.Printf(newrecord.Path)
				return true
			}
		}
	}

	//	fn1 := func(i, j int) bool {
	//		return records[i].Weight > records[j].Weight
	//	}
	//	sort.Slice(records, fn1)

	for i, r := range records {
		if strings.Contains(r.Path+"/", topath) {
			fmt.Printf(r.Path)
			records[i].Weight++
			return true
		}
	}

	return false

}

func removePath(topath string) bool {

	fn := func(i, j int) bool {
		return records[i].Path < records[j].Path
	}
	sort.Slice(records, fn)

	i, err := strconv.Atoi(topath)

	if err == nil {
		j := i - 1

		if j < 0 {
			return false
		}

		if j < (len(records) - 1) {
			records[j] = records[len(records)-1]
			records = records[:len(records)-1]
			return true
		}

		if j == (len(records) - 1) {
			records = records[:len(records)-1]
			return true
		}
	}

	for i, r := range records {
		if r.Path == topath {
			records[i] = records[len(records)-1]
			records = records[:len(records)-1]
			return true
		}

		if (r.Path + "/") == topath {
			records[i] = records[len(records)-1]
			records = records[:len(records)-1]
			return true
		}
	}

	var newrecords []Record
	for _, r := range records {
		if !strings.Contains(r.Path+"/", topath) {
			newrecords = append(newrecords, r)
		}
	}

	records = newrecords

	return true
}

func main() {

	ShowFlag := SHOWFLAG_ALL & (^SHOWFLAG_H)

	boolptrShowHide := flag.Bool("H", false, "Show hidden files.")
	boolptrShowNextPath := flag.Bool("showNextPath", false, "Show next path.")
	boolptrShowPathes := flag.Bool("showPathes", false, "Show all pathes.")
	boolptrShowCurrent := flag.Bool("showCurrent", false, "Show current path.")
	boolptrRemovePath := flag.Bool("removePath", false, "Remove path.")
	boolptrPretty := flag.Bool("p", false, "Enable pretty format.")

	flag.Parse()

	if *boolptrShowHide {
		ShowFlag = SHOWFLAG_ALL
	}

	formatPretty = *boolptrPretty

	topath := flag.Args()

	loadEnv()
	cleanPathes()
	if *boolptrShowNextPath {
		if len(topath) != 0 {
			ret := showNextPath(topath[0])
			if ret {
				saveEnv()
			}
		}
		os.Exit(0)
	}

	if *boolptrRemovePath {
		if len(topath) != 0 {
			ret := removePath(topath[0])
			if ret {
				saveEnv()
			}
		}
		os.Exit(0)
	}

	if *boolptrShowPathes {
		showPathes()
		os.Exit(0)
	}

	if *boolptrShowCurrent {
		showCurrentDir(ShowFlag)
	}
}

func getTerminalSize() (int, int) {

	var rows, cols int

	cmd := exec.Command("stty", "size")
	cmd.Stdin = os.Stdin
	out, err := cmd.Output()
	if err == nil {
		fmt.Sscanf(string(out), "%d %d", &rows, &cols)
	} else {
		rows = 80
		cols = 80
	}
	return rows, cols

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

		_, cols := getTerminalSize()

		fmt.Printf("%s (%d):\n", msg, len(fs))
		i := 0
		lenline := 0

		longestfile := 0
		for _, f := range fs {
			if len(f) > longestfile {
				longestfile = len(f)
			}
		}

		align := 0
		if longestfile < 16 {
			align = 16
		} else if longestfile < 32 {
			align = 32
		} else if longestfile < 64 {
			align = 64
		} else {
			align = 80
		}

		for _, f := range fs {
			i++
			if i > maxfiles {
				break
			}

			nextlen := align
			if len(f) > nextlen {
				nextlen = len(f)
			}
			if (lenline + nextlen) > cols {
				c.Println()
				lenline = 0
			}

			n := 0
			switch align {
			case 16:
				n, _ = c.Printf("%-16s", f)
			case 32:
				n, _ = c.Printf("%-32s", f)
			case 64:
				n, _ = c.Printf("%-64s", f)
			default:
				n, _ = c.Printf("%-80s", f)

			}
			lenline += n

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
				strings.HasSuffix(f.Name(), ".jpg") ||
				strings.HasSuffix(f.Name(), ".svg") {
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
