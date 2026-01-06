package handlers

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/ahmedabdelrahman-del/task-api/models"
	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
)

func setupRouter() *gin.Engine {
	gin.SetMode(gin.TestMode)
	router := gin.Default()
	
	router.GET("/tasks", GetTasks)
	router.GET("/tasks/:id", GetTask)
	router.POST("/tasks", CreateTask)
	router.PUT("/tasks/:id", UpdateTask)
	router.DELETE("/tasks/:id", DeleteTask)
	
	return router
}

func resetTasks() {
	taskMux.Lock()
	tasks = make(map[string]models.Task)
	taskID = 1
	taskMux.Unlock()
}

func TestGetTasks_Empty(t *testing.T) {
	resetTasks()
	router := setupRouter()

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/tasks", nil)
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	
	var response []models.Task
	json.Unmarshal(w.Body.Bytes(), &response)
	assert.Equal(t, 0, len(response))
}

func TestCreateTask_Success(t *testing.T) {
	resetTasks()
	router := setupRouter()

	task := models.Task{
		Title:       "Test Task",
		Description: "Test Description",
		Completed:   false,
	}
	
	jsonData, _ := json.Marshal(task)
	
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/tasks", bytes.NewBuffer(jsonData))
	req.Header.Set("Content-Type", "application/json")
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusCreated, w.Code)
	
	var response models.Task
	json.Unmarshal(w.Body.Bytes(), &response)
	assert.Equal(t, "1", response.ID)
	assert.Equal(t, "Test Task", response.Title)
	assert.Equal(t, "Test Description", response.Description)
	assert.Equal(t, false, response.Completed)
}

func TestCreateTask_MissingTitle(t *testing.T) {
	resetTasks()
	router := setupRouter()

	task := models.Task{
		Description: "Test Description",
	}
	
	jsonData, _ := json.Marshal(task)
	
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/tasks", bytes.NewBuffer(jsonData))
	req.Header.Set("Content-Type", "application/json")
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusBadRequest, w.Code)
}

func TestGetTask_Success(t *testing.T) {
	resetTasks()
	router := setupRouter()

	// Create a task first
	tasks["1"] = models.Task{
		ID:          "1",
		Title:       "Test Task",
		Description: "Test Description",
		Completed:   false,
	}

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/tasks/1", nil)
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	
	var response models.Task
	json.Unmarshal(w.Body.Bytes(), &response)
	assert.Equal(t, "1", response.ID)
	assert.Equal(t, "Test Task", response.Title)
}

func TestGetTask_NotFound(t *testing.T) {
	resetTasks()
	router := setupRouter()

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/tasks/999", nil)
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusNotFound, w.Code)
}

func TestUpdateTask_Success(t *testing.T) {
	resetTasks()
	router := setupRouter()

	// Create a task first
	tasks["1"] = models.Task{
		ID:          "1",
		Title:       "Original Task",
		Description: "Original Description",
		Completed:   false,
	}

	updatedTask := models.Task{
		Title:       "Updated Task",
		Description: "Updated Description",
		Completed:   true,
	}
	
	jsonData, _ := json.Marshal(updatedTask)
	
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("PUT", "/tasks/1", bytes.NewBuffer(jsonData))
	req.Header.Set("Content-Type", "application/json")
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	
	var response models.Task
	json.Unmarshal(w.Body.Bytes(), &response)
	assert.Equal(t, "1", response.ID)
	assert.Equal(t, "Updated Task", response.Title)
	assert.Equal(t, true, response.Completed)
}

func TestUpdateTask_NotFound(t *testing.T) {
	resetTasks()
	router := setupRouter()

	updatedTask := models.Task{
		Title:       "Updated Task",
		Description: "Updated Description",
	}
	
	jsonData, _ := json.Marshal(updatedTask)
	
	w := httptest.NewRecorder()
	req, _ := http.NewRequest("PUT", "/tasks/999", bytes.NewBuffer(jsonData))
	req.Header.Set("Content-Type", "application/json")
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusNotFound, w.Code)
}

func TestDeleteTask_Success(t *testing.T) {
	resetTasks()
	router := setupRouter()

	// Create a task first
	tasks["1"] = models.Task{
		ID:          "1",
		Title:       "Test Task",
		Description: "Test Description",
		Completed:   false,
	}

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("DELETE", "/tasks/1", nil)
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	
	// Verify task is deleted
	_, exists := tasks["1"]
	assert.False(t, exists)
}

func TestDeleteTask_NotFound(t *testing.T) {
	resetTasks()
	router := setupRouter()

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("DELETE", "/tasks/999", nil)
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusNotFound, w.Code)
}

func TestGetTasks_WithMultipleTasks(t *testing.T) {
	resetTasks()
	router := setupRouter()

	// Create multiple tasks
	tasks["1"] = models.Task{ID: "1", Title: "Task 1", Completed: false}
	tasks["2"] = models.Task{ID: "2", Title: "Task 2", Completed: true}
	tasks["3"] = models.Task{ID: "3", Title: "Task 3", Completed: false}

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/tasks", nil)
	router.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	
	var response []models.Task
	json.Unmarshal(w.Body.Bytes(), &response)
	assert.Equal(t, 3, len(response))
}
