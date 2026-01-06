package handlers

import (
	"net/http"
	"strconv"
	"sync"

	"github.com/ahmedabdelrahman-del/task-api/models"
	"github.com/gin-gonic/gin"
)

// In-memory storage for tasks
var (
	tasks   = make(map[string]models.Task)
	taskID  = 1
	taskMux sync.RWMutex
)

// GetTasks returns all tasks
func GetTasks(c *gin.Context) {
	taskMux.RLock()
	defer taskMux.RUnlock()

	taskList := make([]models.Task, 0, len(tasks))
	for _, task := range tasks {
		taskList = append(taskList, task)
	}

	c.JSON(http.StatusOK, taskList)
}

// GetTask returns a single task by ID
func GetTask(c *gin.Context) {
	id := c.Param("id")

	taskMux.RLock()
	task, exists := tasks[id]
	taskMux.RUnlock()

	if !exists {
		c.JSON(http.StatusNotFound, gin.H{"error": "Task not found"})
		return
	}

	c.JSON(http.StatusOK, task)
}

// CreateTask creates a new task
func CreateTask(c *gin.Context) {
	var newTask models.Task

	if err := c.ShouldBindJSON(&newTask); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	taskMux.Lock()
	newTask.ID = strconv.Itoa(taskID)
	taskID++
	tasks[newTask.ID] = newTask
	taskMux.Unlock()

	c.JSON(http.StatusCreated, newTask)
}

// UpdateTask updates an existing task
func UpdateTask(c *gin.Context) {
	id := c.Param("id")

	taskMux.RLock()
	_, exists := tasks[id]
	taskMux.RUnlock()

	if !exists {
		c.JSON(http.StatusNotFound, gin.H{"error": "Task not found"})
		return
	}

	var updatedTask models.Task
	if err := c.ShouldBindJSON(&updatedTask); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	updatedTask.ID = id
	taskMux.Lock()
	tasks[id] = updatedTask
	taskMux.Unlock()

	c.JSON(http.StatusOK, updatedTask)
}

// DeleteTask deletes a task by ID
func DeleteTask(c *gin.Context) {
	id := c.Param("id")

	taskMux.Lock()
	_, exists := tasks[id]
	if !exists {
		taskMux.Unlock()
		c.JSON(http.StatusNotFound, gin.H{"error": "Task not found"})
		return
	}
	delete(tasks, id)
	taskMux.Unlock()

	c.JSON(http.StatusOK, gin.H{"message": "Task deleted successfully"})
}
