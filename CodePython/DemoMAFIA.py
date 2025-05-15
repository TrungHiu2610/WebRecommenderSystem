# -*- coding: utf-8 -*-
"""
Created on Wed Apr  9 11:23:39 2025

@author: Trung Hiu
"""

import json
from itertools import combinations
from collections import defaultdict

class MAFIA:
    def __init__(self, transactions, min_support):
        self.transactions = transactions
        self.min_support = min_support
        self.num_transactions = len(transactions)
        self.vertical_db = self._build_vertical_db()
        self.MFI = []
        self.FI = []    

    def _build_vertical_db(self):   
        vertical_db = defaultdict(set)
        for tid, transaction in enumerate(self.transactions):
            for item in transaction:
                vertical_db[item].add(tid)
        return vertical_db

    def _support(self, itemset):
        if not itemset:
            return set(range(self.num_transactions))  # Nếu itemset rỗng -> tất cả transaction
        common = self.vertical_db[itemset[0]].copy()
        for item in itemset[1:]:
            common &= self.vertical_db[item]
        return common

    def _is_subset_of_mfi(self, itemset):
        for mfi in self.MFI:
            if set(itemset).issubset(mfi):
                return True
        return False

    def _dfs(self, head, tail, head_tids):

        children = []

        # Step 1: Sinh các 1-extension (head nối thêm 1 item ở tail) và lọc theo support
        for item in tail:
            new_itemset = head + [item]
            new_tids = head_tids & self.vertical_db[item]  # giao các giao dịch
            if len(new_tids) / self.num_transactions >= self.min_support:
                children.append((item, new_tids))
                self.FI.append(new_itemset)

        # PEP - Parent Equivalence Pruning
        new_head = head[:]
        new_tail = []
        for item, tids in children:
            if tids == head_tids:
                new_head.append(item)  # nếu support không thay đổi -> merge vào head
            else:
                new_tail.append((item, tids))  # còn lại giữ làm tail tiếp theo

        # HUTMFI pruning
        HUT = set(new_head + [item for item, _ in new_tail])
        if self._is_subset_of_mfi(HUT):
            return  # nếu head U tail đã là tập con của MFI -> bỏ qua nhánh này

        # FHUT pruning
        hut_tids = head_tids
        for item, tids in new_tail:
            hut_tids &= tids
        if len(hut_tids) / self.num_transactions >= self.min_support:
            self.MFI.append(HUT)  # Nếu support đủ -> lưu HUT làm MFI
            return

        # Đệ quy tiếp các nhánh con
        for i, (item, tids) in enumerate(new_tail):
            new_head_branch = new_head + [item]
            new_tail_branch = [it for it, _ in new_tail[i+1:]]
            self._dfs(new_head_branch, new_tail_branch, tids)

        # Nếu tail rỗng và new_head không phải tập con của MFI nào -> lưu new_head
        if not new_tail:
            if not self._is_subset_of_mfi(set(new_head)):
                self.MFI.append(set(new_head))

    def run(self):
        items = sorted(self.vertical_db.keys())
        self._dfs([], items, set(range(self.num_transactions)))

    def get_results(self):
        return {
            "MFI_count": len(self.MFI),
            "MFIs": [sorted(list(mfi)) for mfi in self.MFI],
        }


def load_transactions_from_json(json_path):
    with open(json_path, 'r') as f:
        data = json.load(f)
    return data['transactions']

def generate_frequent_subsets(mfi_list, vertical_db, minsup, num_transactions):
    seen = set()
    fi_complete = dict()  

    for mfi in mfi_list:
        for k in range(1, len(mfi) + 1):
            for subset in combinations(mfi, k):
                subset_frozen = frozenset(subset)
                if subset_frozen in seen:
                    continue
                seen.add(subset_frozen)

                # Tính support của subset
                common = vertical_db[subset[0]].copy()
                for item in subset[1:]:
                    common &= vertical_db[item]
                support = len(common) / num_transactions
                if support >= minsup:
                    fi_complete[subset_frozen] = support  # <- Lưu luôn support

    return fi_complete


def main():
    transactions = load_transactions_from_json('store_data.json')
    min_support = 0.007
    mafia = MAFIA(transactions, min_support)
    mafia.run()
    results = mafia.get_results()

    # Lọc bỏ các MFI chỉ có 1 item
    filtered_mfi = [mfi for mfi in results['MFIs'] if len(mfi) > 1]

    #Sinh thêm tất cả các frequent itemsets từ danh sách MFI đã lọc
    full_fi = generate_frequent_subsets(
        filtered_mfi, mafia.vertical_db, mafia.min_support, mafia.num_transactions
    )

    print(f"Số lượng giao dịch: {len(transactions)}")
    print(f"Minsup: {min_support}")
    print("--- Kết quả thuật toán MAFIA ---")
    # print(f"Tổng số tập FI: {len(full_fi)}")
    
    print("\nCác tập MFI:")
    for mfi in filtered_mfi:
        print(mfi)
    print(f"Tổng số tập MFI: {len(filtered_mfi)}")  # dùng MFI đã lọc

    

    print("\nCác tập FI:")
    print(full_fi)


if __name__ == "__main__":
    main()
