from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List
from DemoMAFIA import MAFIA, generate_frequent_subsets
import json
from itertools import combinations
from collections import Counter

app = FastAPI()

# --- Dữ liệu học cố định nạp lúc start server ---
with open("store_data.json", "r") as f:
    data = json.load(f)
    transactions = data["transactions"]

# Chạy thuật toán MAFIA
mafia_model = MAFIA(transactions, min_support=0.0045)
mafia_model.run()
MFI = mafia_model.MFI
full_FI = generate_frequent_subsets(MFI, mafia_model.vertical_db, mafia_model.min_support, mafia_model.num_transactions)

# --- Sinh luật kết hợp từ full_FI ---
# Mỗi luật lưu dạng dict chứa các frozenset: 'antecedent' và 'consequent'
association_rules = []

def generate_association_rules(full_FI, num_transactions, min_confidence=0.2):
    rules = []
    for itemset, itemset_support in full_FI.items():
        if len(itemset) < 2:
            continue

        for i in range(1, len(itemset)):
            for antecedent in combinations(itemset, i):
                antecedent = frozenset(antecedent)
                consequent = itemset - antecedent
                if not consequent:
                    continue
                antecedent_support = full_FI.get(antecedent)
                if not antecedent_support:
                    continue
                confidence = itemset_support / antecedent_support
                if confidence < min_confidence:
                    continue

                consequent_support = full_FI.get(consequent, 1e-6)
                lift = confidence / (consequent_support / num_transactions)
                rules.append({
                    "antecedent": antecedent,
                    "consequent": consequent,
                    "support": itemset_support,
                    "confidence": confidence,
                    "lift": lift
                })
    return rules

association_rules = generate_association_rules(full_FI, mafia_model.num_transactions, min_confidence=0.2)

class CartRequest(BaseModel):
    cart: List[str]

@app.post("/suggest_rules")
def suggest_from_rules(req: CartRequest):
    if not req.cart:
        raise HTTPException(status_code=400, detail="Cart cannot be empty.")

    cart_set = set(req.cart)
    # Tạm lưu gợi ý tốt nhất cho từng sản phẩm
    best_suggestions = {}
    
    for rule in association_rules:
        if rule["antecedent"].issubset(cart_set):
            new_products = rule["consequent"] - cart_set
            for product in new_products:
                suggestion = {
                    "product": product,
                    "confidence": round(rule["confidence"], 4),
                    "lift": round(rule["lift"], 4),
                    "support": round(rule["support"], 4)
                }
                # Nếu sản phẩm chưa có hoặc có gợi ý tốt hơn thì cập nhật
                if product not in best_suggestions or (
                    suggestion["confidence"], suggestion["lift"]
                ) > (
                    best_suggestions[product]["confidence"], best_suggestions[product]["lift"]
                ):
                    best_suggestions[product] = suggestion
    
    raw_suggestions = list(best_suggestions.values())
        

    if not raw_suggestions:
        return {"suggestions": []}

    raw_suggestions.sort(key=lambda x: (x["confidence"], x["lift"]), reverse=True)
    return {"suggestions": raw_suggestions}


@app.post("/suggest_mfi")
def suggest_from_mfi(req: CartRequest):
    if not req.cart:
        raise HTTPException(status_code=400, detail="Cart cannot be empty.")

    cart_set = set(req.cart)
    suggestions = []

    # Duyệt qua MFI để tìm sản phẩm gợi ý
    for mfi in MFI:
        if cart_set.issubset(mfi):
            suggestion = mfi - cart_set
            if suggestion:
                suggestions.extend(suggestion)
                
    # Đếm tần suất mỗi sản phẩm được gợi ý
    suggestion_counts = Counter(suggestions)

    # Sắp xếp theo tần suất giảm dần và chuẩn bị kết quả
    sorted_suggestions = [{"item": item, "count": count} for item, count in suggestion_counts.most_common()]

    return {"suggestions": sorted_suggestions[:10]}
