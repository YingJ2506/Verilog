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
- T=5~15，Reset Test ok
- T=20~40，Write Test ok
- T=45~65，Read Test ok
- T=70~130，Underflow Test ok
- T=135~215，Write & Read Test ok
- T=215~545，Overflow Test ok
- T=550~590，Reset During Active Test ok
- T=600~680，Idle test ok

# 修正心得
- RTL ct位寬錯誤修正: 起初發現reset後full會一直處於1高電位，詢問chatGPT後檢查code是否有寫錯或重複使用、波型有無被干擾或錯誤、陣列宣告條件與full判斷條件，最後透過$display知道設定是4'd16沒錯但顯示是0，而因為assign full = (ct==4'd16)等於ct==4'd0就會是高電位，要表達0~16需要5bits -> 因此改成reg [4:0] ct;  assign full = (ct == 5'd16);即可正常
- RTL ct增減邏輯修正: 因錯誤設定導致合成錯誤，明明是wt_en & rd_en都開啟但ct卻沿著clk 1 > 0 > 1 > 0，才發現code if else設定錯誤且原寫法為"write" 、 "read" -> 修正ct邏輯合併於寫三個條件("write & read"、"write"、"read") 並補上else 避免latch
- 因了解到output為了將輸出資料的時序控制與邏輯分離，能提升模組可讀性與維護性，避免latch，輸出更穩定。因此修正"dout"輸出方式，使用"dout_r"搭配assign，後續修正dout改為純粹的組合輸出（wire）
- 在設定overflow/underflow 的計數時發現，計數會隨著持續高電位而持續增加，為了改成只在轉換時增加新增一個pre_overflow/pre_underflow讓他在now跟pre不相同時計數，成功改善計數邏輯

# 待處理
- 增加 display 訊息顯示資料狀態 -> done
- 增加簡單提示文字（例如 overflow/empty 警告） -> done
- 程式碼轉成 SystemVerilog
- 加入隨機 enable 測試 -> done
- 嘗試用 "case" 改寫 RTL
- 警告訊息改用 "assert" -> done
- 補 functional coverage
- 增加 "parameter" 提升彈性
- 增加 "overflow" 訊號 -> done
- 嘗試改成非同步 FIFO + 灰碼計數器
- 增加overflow/underflow計數 -> done
- 修改整合手動測試與隨機測試 -> done


# 更版紀錄
1. v1.0---初始版本 
- Verilog同步FIFO + 基本Testbench測試
2. v1.1---加入顯示與驗證強化
- TB 增加 $display 顯示
- RTL 內部使用 dout_r + assign dout
- RTL + TB 中新增 assert 驗證，檢查 FIFO 是否滿/空與 ct 合理性
3. v1.2---修正 RTL 架構與豐富測試功能
[RTL]
- 修正將 dout 從 reg 改為 wire
- 修正加入 else 區塊，避免未覆蓋造成 latch 推斷
- 新增 overflow / underflow 訊號輸出
- 增加 overflow / underflow assert 檢查報錯
[Testbench]
- 加入 overflow_count 與 underflow_count 累計次數
- 增加隨機 wt_en / rd_en 控制，模擬真實應用行為
- 整合「手動測試」與「隨機測試」，透過 parameter MODE = 0 控制執行模式：
   -> MODE = 0：固定測資流程（手動 case）
   -> MODE = 1：隨機 enable 測試（自動 case）
   -> 更新原本 # 手動用時序測試改用 cycle 計數搭配 posedge clk 控制

