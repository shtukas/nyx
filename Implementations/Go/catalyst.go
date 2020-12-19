package main

import (
    "bufio"
    "fmt"
    "os"
)

func main() {
    fmt.Println("24 hours presence ratio: 23.41 %, asteroids count: 3942, -3, 3942")
    fmt.Println("")
    fmt.Println("[19] NG12TimeReport [1.00 hours,  24.96 % completed] All asteroid burners")
    fmt.Println("[21] NG12TimeReport [1.00 hours,  39.65 % completed] All asteroid streams")

	reader := bufio.NewReader(os.Stdin)
	fmt.Print("Enter text: ")
	text, _ := reader.ReadString('\n')
	fmt.Println(text)
}
