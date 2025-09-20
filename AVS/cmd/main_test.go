package main

import (
	"encoding/json"
	"testing"

	performerV1 "github.com/Layr-Labs/protocol-apis/gen/protos/eigenlayer/hourglass/v1/performer"
	"go.uber.org/zap"
)

func Test_RestakeTaskValidation(t *testing.T) {
	logger, err := zap.NewDevelopment()
	if err != nil {
		t.Errorf("Failed to create logger: %v", err)
	}

	taskWorker := NewRestakeLPTaskWorker(logger)

	// Test valid restake task
	restakePayload := TaskPayload{
		Type: TaskTypeRestake,
		Restake: RestakeTaskParams{
			Protocol: "ethereum",
			Amount:   "1000000000000000000", // 1 ETH
			Token:    "0x0000000000000000000000000000000000000000",
			Strategy: "compound",
			MinYield: "500", // 5%
		},
	}

	payloadBytes, _ := json.Marshal(restakePayload)
	taskRequest := &performerV1.TaskRequest{
		TaskId:  []byte("test-restake-task"),
		Payload: payloadBytes,
	}

	err = taskWorker.ValidateTask(taskRequest)
	if err != nil {
		t.Errorf("ValidateTask failed for valid restake task: %v", err)
	}

	resp, err := taskWorker.HandleTask(taskRequest)
	if err != nil {
		t.Errorf("HandleTask failed for restake task: %v", err)
	}

	t.Logf("Restake task response: %v", resp)
}

func Test_LiquidityTaskValidation(t *testing.T) {
	logger, err := zap.NewDevelopment()
	if err != nil {
		t.Errorf("Failed to create logger: %v", err)
	}

	taskWorker := NewRestakeLPTaskWorker(logger)

	// Test valid liquidity task
	liquidityPayload := TaskPayload{
		Type: TaskTypeLiquidity,
		Liquidity: LiquidityTaskParams{
			Protocol:     "uniswap-v3",
			TokenA:       "0xA0b86a33E6441b8c4C8C0e4B8b8c4C8C0e4B8b8c4",
			TokenB:       "0xB0b86a33E6441b8c4C8C0e4B8b8c4C8C0e4B8b8c4",
			AmountA:      "1000000000000000000", // 1 token
			AmountB:      "2000000000000000000", // 2 tokens
			MinLiquidity: "1000000000000000000",
		},
	}

	payloadBytes, _ := json.Marshal(liquidityPayload)
	taskRequest := &performerV1.TaskRequest{
		TaskId:  []byte("test-liquidity-task"),
		Payload: payloadBytes,
	}

	err = taskWorker.ValidateTask(taskRequest)
	if err != nil {
		t.Errorf("ValidateTask failed for valid liquidity task: %v", err)
	}

	resp, err := taskWorker.HandleTask(taskRequest)
	if err != nil {
		t.Errorf("HandleTask failed for liquidity task: %v", err)
	}

	t.Logf("Liquidity task response: %v", resp)
}

func Test_InvalidTaskValidation(t *testing.T) {
	logger, err := zap.NewDevelopment()
	if err != nil {
		t.Errorf("Failed to create logger: %v", err)
	}

	taskWorker := NewRestakeLPTaskWorker(logger)

	// Test invalid task with missing required fields
	invalidPayload := TaskPayload{
		Type: TaskTypeRestake,
		Restake: RestakeTaskParams{
			Protocol: "", // Missing protocol
			Amount:   "1000000000000000000",
			Token:    "0x0000000000000000000000000000000000000000",
		},
	}

	payloadBytes, _ := json.Marshal(invalidPayload)
	taskRequest := &performerV1.TaskRequest{
		TaskId:  []byte("test-invalid-task"),
		Payload: payloadBytes,
	}

	err = taskWorker.ValidateTask(taskRequest)
	if err == nil {
		t.Errorf("ValidateTask should have failed for invalid task")
	}

	t.Logf("Expected validation error: %v", err)
}

func Test_RebalanceTask(t *testing.T) {
	logger, err := zap.NewDevelopment()
	if err != nil {
		t.Errorf("Failed to create logger: %v", err)
	}

	taskWorker := NewRestakeLPTaskWorker(logger)

	// Test rebalance task
	rebalancePayload := TaskPayload{
		Type: TaskTypeRebalance,
	}

	payloadBytes, _ := json.Marshal(rebalancePayload)
	taskRequest := &performerV1.TaskRequest{
		TaskId:  []byte("test-rebalance-task"),
		Payload: payloadBytes,
	}

	err = taskWorker.ValidateTask(taskRequest)
	if err != nil {
		t.Errorf("ValidateTask failed for rebalance task: %v", err)
	}

	resp, err := taskWorker.HandleTask(taskRequest)
	if err != nil {
		t.Errorf("HandleTask failed for rebalance task: %v", err)
	}

	t.Logf("Rebalance task response: %v", resp)
}
