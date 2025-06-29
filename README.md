# Verilog
Verilog project - FIFO

# 同步FIFO模組設計

# 功能敘述
設計一同步FIFO(先進先出)緩衝器，包含寫入與讀取功能於同一時鐘下實現資料處理，先以資料寬度8bits、深度16筆作為設計需求，此 FIFO 為單時脈同步 FIFO，支援先進先出資料處理邏輯。

# RTL模組設計邏輯
- 資料輸入din
- 寫入write & 讀取read
- 同步更新(posedge clock) & 有重置功能(reset)
- 處理全滿full & 全空empty狀態   //判斷用組合邏輯
- 資料暫存(memory)               //write存入mem，read取出mem
- 寫入&讀取指標(write_p、read_p)
- 資料總數紀錄(count)



# TB測試項目與目標
- 無寫入&讀取信號，是否維持狀態
- reset啟動後，是否為空
- 寫入啟動(未滿)，是否正常寫入資料
- 讀取啟動(未滿)，是否正常讀出資料
- 寫入&讀取都啟動，是否正常寫入&讀出(count不增加)
- 寫入啟動(全滿)，是否不會overflow
- 讀取啟動(全空)，是否不會underflow
- 寫入/讀取到一半時作reset，是否正常reset

使用EDAplayground(Icarus verilog + EPWave)進行模擬與驗證


# 模擬結果
EPWave 波型圖可視化測試結果（見附圖）
![image](https://github.com/user-attachments/assets/ec74eb81-fcb1-403a-b54e-cacf4c5da32f)


# 錯誤修正
- rtl ct位寬錯誤導致reset後full一直處於1高電位，因為要表達0~16需要5bits-> 改成reg [4:0] ct;  assign full = (ct == 5'd16); 
- rtl ct增減邏輯錯誤導致合成錯誤 (原寫法為"只寫"、"只讀") -> 修正ct邏輯合併於寫三個條件("同時讀寫"、"只寫"、"只讀")


# 待處理
- 增加 display 訊息顯示資料狀態
- 增加簡單提示文字（例如 overflow/empty 警告）
- 程式碼轉成 SystemVerilog
- 加入隨機 enable 測試
- 嘗試用 "case" 改寫 RTL
- 警告訊息改用 "assert"
- 補 functional coverage
- 增加 "parameter" 提升彈性
- 增加 "overflow" 訊號
- 嘗試改成非同步 FIFO + 灰碼計數器


# 更版紀錄
1. 初始版本 (Verilog同步FIFO + 基本TB)
