# Verilog
Verilog project - FIFO

# 同步FIFO模組設計

# 功能敘述
設計一同步FIFO(先進先出)緩衝器，包含寫入與讀取功能於同一時鐘下實現資料處理，先以資料寬度8bits、深度16筆作為設計需求，此 FIFO 為單時脈同步 FIFO，支援先進先出資料處理邏輯。

# RTL模組設計邏輯
- **記憶體陣列：** 內部採用 `reg` 型記憶體陣列 (`memory`) 用於儲存 8 位元資料，深度為 16 筆。
- **寫入/讀取指標：** 實作 `write_pointer` 與 `read_pointer`，分別追蹤下一個寫入位置與下一個讀取位置。指標設計考慮最大值後歸零。
- **計數器：** `count` 暫存器追蹤 FIFO 內當前儲存的資料數量，用於判斷 `full` 或 `empty` 狀態。
- **全滿/全空判斷：** `full` 和 `empty` 狀態訊號透過組合邏輯即時判斷，基於寫入/讀取指標和資料計數。
- **資料路徑控制：** 寫入操作 (`write_enable`) 將 `din` 寫入 `memory`；讀取操作 (`read_enable`) 從 `memory` 讀取資料至 `dout`。
- **時序控制：** 所有內部狀態更新和暫存器操作均在時脈正緣 (`posedge clock`) 觸發。
- **同步 Reset：** 導入同步 Reset 邏輯，將所有內部狀態復位至初始狀態。



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
## EPWave 波型圖可視化測試結果v1.0（見附圖）
![image](https://github.com/user-attachments/assets/ec74eb81-fcb1-403a-b54e-cacf4c5da32f)
- T=5~15，Reset Test ok
- T=20~40，Write Test ok
- T=45~65，Read Test ok
- T=70~130，Underflow Test ok
- T=135~215，Write & Read Test ok
- T=215~545，Overflow Test ok
- T=550~590，Reset During Active Test ok
- T=600~680，Idle test ok

## EPWave 波型圖可視化測試結果v1.3（見附圖）
![image](https://github.com/user-attachments/assets/8ec90db5-d51c-49bc-af86-7b06c41cc75a)


## Python 分析 FIFO 行為
- Verilog FIFO 模擬 → 產生 log.txt → Python 分析 → 印出overflow/underflow 錯誤
- 透過Python檔案(fifo_py1.py) 分析log資料(fifo_log1.txt) 並印出錯誤。
- Python 分析是根據 log 各時脈週期的狀態判定 overflow/underflow，此為軟體層級的分析。


# 修正心得
- RTL ct位寬錯誤修正: 起初發現reset後full會一直處於1高電位，檢查code是否有寫錯或重複使用、波型有無錯誤、陣列宣告條件與full判斷條件，因為full從一開始就在高電位所以特別注意full的邏輯，也透過詢問chatgpt輔助建議可以透過$display確認正確數值，得知設定是4'd16相當於4'd0，原因來自ct實際最大需表示到16，而只用4bits只能表示到15，因此將 ct 位寬從 [3:0] 提升為 [4:0]，並將 full 條件調整為 5'd16 即可正常。
- RTL ct增減邏輯修正: 因錯誤設定導致合成錯誤，當wt_en & rd_en都開啟時ct卻沿著clk 1 > 0 > 1 > 0變化，才發現code if else設定錯誤且原寫法只寫了兩種狀態"write"、"read"，修正ct邏輯合併於寫三個條件("write & read"、"write"、"read") 並補上else 避免latch，ct可正常計數。
- 因了解到output為了將輸出資料的時序控制與邏輯分離，能提升模組可讀性與維護性，避免latch，輸出更穩定也能提高未來模組擴充時的維護彈性。因此修正"dout"輸出方式，多設定一個reg使用"dout_r"並assign給dout，後續修正dout改為純粹的組合輸出。
- TB在設定overflow/underflow 的計數時發現，計數會隨著持續高電位而持續增加，修改新增一個pre_overflow/pre_underflow暫存器儲存前一個overflow/underflow的值，使得可以只在啟動瞬間才計數，成功改善計數邏輯。
- 在RTL使用case語法來修改目前的if else時，回想起早期FSM使用typedef enum 去定義狀態，因此考慮到狀態會有四種(不讀寫、只讀、只寫、同時讀寫)，使用2bits去滿足需求，而在case的區域了解到可以使用兩個邏輯信號連接成一個2位元信號的方法去表示條件，作為判斷狀態的依據，且將IDLE狀態整合到default區域。
- 在TB新增coverage時原本以為是有寫錯一直出現語法錯誤，重複的去查閱是否有地方寫錯，確認covergroup有做初始化設定與寫在always語法中去採點，而後才想到說EDA playgroung的icarus verilog 有可能不支援的問題，詢問chatgpt輔助確認icarus verilog在playground確實不支援covergroup語法，此待後續使用支援軟體驗證如 VCS 或 QuestaSim 等做完整驗證。

# 待優化功能
- 增加 display 訊息顯示資料狀態 -> done
- 增加簡單提示文字（例如 overflow/empty 警告） -> done
- 程式碼轉成 SystemVerilog -> done
- 加入隨機 enable 測試 -> done
- 嘗試用 "case" 改寫 RTL -< done
- 警告訊息改用 "assert" -> done
- 補 functional coverage -> done(wait confirm)
- 增加 "parameter" 提升彈性 -> done
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
- RTL修正將 dout 從 reg 改為 wire
- RTL修正加入 else 區塊，避免未覆蓋造成 latch 推斷
- RTL新增 overflow / underflow 訊號輸出
- RTL增加 overflow / underflow assert 檢查報錯
- TB加入 overflow_count 與 underflow_count 累計次數
- TB增加隨機 wt_en / rd_en 控制，模擬真實應用行為
- TB整合「手動測試」與「隨機測試」，透過 parameter MODE = 0 控制執行模式：
   - MODE = 0：固定測資流程（手動 case）
   - MODE = 1：隨機 enable 測試（自動 case）
4. v1.3---新增功能與改進
- RTL：引入了新的狀態機設計(case)，透過 enum 類型更加清晰地定義 FIFO 的各種狀態（IDLE、READ_ONLY、WRITE_ONLY、WRITE_READ）。
- RTL：修正了 wt_p 和 rd_p 指標的更新邏輯，確保它們能在 FIFO 狀態機中正常運作。
- TB：增加了覆蓋率（coverage）功能，透過 covergroup 來對 FIFO 關鍵狀態進行測試。
- TB：增強了隨機化控制，進一步優化了 rst、wt_en 和 rd_en 的測試策略，使其更符合實際應用中的隨機行為。
5. v1.4---修正coding style
- RTL : 程式碼風格優化 case 敘述，並將 overflow/underflow 邏輯整合至主體，使其成為單一時鐘週期的脈衝。
- RTL : 邏輯調整修正 LOG_WIDTH 參數計算，並將 FIFO 邏輯從「先動作後判斷」改為「先判斷狀態，再執行動作」。

