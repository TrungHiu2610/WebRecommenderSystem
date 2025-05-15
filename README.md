Hệ Thống Gợi Ý Sản Phẩm Dựa Trên Giỏ Hàng Sử Dụng Thuật Toán MAFIA

Đây là hệ thống đề xuất sản phẩm dựa trên giỏ hàng hiện tại của người dùng, sử dụng **thuật toán MAFIA** (Maximal Frequent Itemset Algorithm) để khai thác **tập phổ biến tối đại**. Hệ thống gồm 2 phần chính:

- Website bán hàng viết bằng **ASP.NET MVC 4**
- Thuật toán gợi ý viết bằng **Python (FastAPI)**

---

## Kiến Trúc Hệ Thống

```text
+-------------------+       HTTP POST        +--------------------------+
| ASP.NET MVC Web   |  ------------------->  |  FastAPI (Python)        |
| - Hiển thị giỏ hàng|                      | - Thuật toán MAFIA       |
| - Gọi API đề xuất |  <-------------------  | - Trả về danh sách gợi ý|
+-------------------+       JSON Response     +--------------------------+

Cách Chạy Project
1. Chạy FastAPI server (Python)
Mở terminal:
  cd tới folder chứa DemoMAFIA.py và API_MAFIA.py
  uvicorn main:app --reload
  API mặc định chạy ở http://127.0.0.1:8000

2. Chạy Web ASP.NET MVC
Mở solution bằng Visual Studio
Build project
Chạy website, cấu hình suggestMethod (suggest_mfi hoặc suggest_rules)
API sẽ được gọi đến FastAPI để lấy gợi ý từ giỏ hàng hiện tại
