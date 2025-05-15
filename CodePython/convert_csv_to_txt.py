import csv
import json

input_csv = 'store_data.csv'
output_json = 'store_data.json'

transactions = []

# Đọc file CSV
with open(input_csv, mode='r', encoding='utf-8') as file:
    reader = csv.reader(file)
    for row in reader:
        # Loại bỏ các giá trị rỗng và khoảng trắng
        cleaned = [item.strip() for item in row if item.strip()]
        if cleaned:
            transactions.append(cleaned)

# Ghi ra file JSON
with open(output_json, mode='w', encoding='utf-8') as json_file:
    json.dump(transactions, json_file, indent=4)

print(f"Đã chuyển {input_csv} → {output_json} thành công!")
