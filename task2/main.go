package main

import (
	"fmt"
	"sync"
	"sync/atomic"
	"time"
)

type Shape interface {
	Area() float64
	Perimeter() float64
}

type Rectangle struct {
	width  float64
	height float64
}

func (r Rectangle) Area() float64 {
	return r.width * r.height
}

func (r Rectangle) Perimeter() float64 {
	return 2 * (r.width + r.height)
}

type Circle struct {
	radius float64
}

func (c Circle) Area() float64 {
	return 3.14 * c.radius * c.radius
}

func (c Circle) Perimeter() float64 {
	return 2 * 3.14 * c.radius
}

type Person struct {
	name string
	age  int
}

type Employee struct {
	person     Person
	employeeID int
}

func (e Employee) printInfo() {
	fmt.Printf("Name: %s, Age: %d, EmployeeID: %d\n", e.person.name, e.person.age, e.employeeID)
}

type Count struct {
	sum   int
	mutex sync.Mutex
}

func main() {
	fmt.Println("Hello, world!")

	// 指针
	var a int = 5
	changeValue(&a)
	fmt.Println(a)
	b := []int{1, 2, 3, 4, 5}
	changeValues(&b)
	fmt.Println(b)

	//·Goroutine
	goroutine()
	exec()

	//面向对象
	var s Shape
	s = Rectangle{width: 3, height: 4}
	fmt.Printf("area %f perimeter %f \n", s.Area(), s.Perimeter())
	s = Circle{radius: 5}
	fmt.Printf("area %f perimeter %f \n", s.Area(), s.Perimeter())
	e := Employee{
		person: Person{
			name: "Alice",
			age:  30,
		},
		employeeID: 12345,
	}
	e.printInfo()

	//Channel
	c := make(chan int)
	chanInput(c)
	chanOutput(c)
	c1 := make(chan int, 5)
	go chanInputBuffered(c1)
	go chanOutputBuffered(c1)

	//锁机制
	d := Count{sum: 0}
	for i := 0; i < 10; i++ {
		go lockMechanism(&d)
	}

	var d1 int32
	ws := sync.WaitGroup{}
	for i := 0; i < 10; i++ {
		ws.Add(1)
		go func() {
			defer ws.Done()
			for i := 0; i < 1000; i++ {
				atomic.AddInt32(&d1, 1)
			}
		}()
	}
	ws.Wait()

	time.Sleep(3 * time.Second) //等待Goroutine执行完毕
	fmt.Printf("I m lockMechanism %d \n", d.sum)
	fmt.Printf("I m no lockMechanism %d \n", d1)
}

// 指针
func changeValue(x *int) {
	*x = *x + 10
}

func changeValues(x *[]int) {
	for i := range *x {
		(*x)[i] *= 2
	}
}

// Goroutine
func goroutine() {
	go func() {
		for i := 0; i < 10; i++ {
			if i%2 > 0 {
				fmt.Printf("奇数: %d \n", i)
			}
		}
	}()
	go func() {
		for i := 0; i < 10; i++ {
			if i%2 == 0 {
				fmt.Printf("偶数: %d \n", i)
			}
		}
	}()
}

func exec() {
	for i := 0; i < 5; i++ {
		start := time.Now().UnixNano()
		for j := i; j < 5; j++ {
			go func() {
				fmt.Printf("I m goroutine %d exec %d \n", i, j)
			}()
		}
		fmt.Printf("I m goroutine %d use time %d ms \n", i, (time.Now().UnixNano()-start)/1000)
	}
}

// Channel
func chanInput(c chan<- int) {
	go func() {
		for i := 1; i <= 10; i++ {
			c <- i
		}
	}()
}
func chanOutput(c <-chan int) {
	go func() {
		for {
			num := <-c
			fmt.Printf("Received number: %d\n", num)
		}
	}()
}

func chanInputBuffered(c chan<- int) {
	for i := 1; i <= 100; i++ {
		c <- i
	}
	close(c)
}

func chanOutputBuffered(c <-chan int) {
	for num := range c {
		fmt.Printf("chan buffer Received number: %d\n", num)
	}
}

// 锁机制
func lockMechanism(a *Count) {
	a.mutex.Lock()
	defer a.mutex.Unlock()
	for i := 0; i < 1000; i++ {
		a.sum += 1
	}

}
